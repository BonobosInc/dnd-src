#!/usr/bin/env python3
"""
D&D Session Server
A Python-based WebSocket server for managing D&D game sessions
"""
import asyncio
import json
import random
import string
import secrets
from datetime import datetime, timedelta
from typing import Dict, List, Set, Optional
from aiohttp import web, WSMsgType
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class SessionCode:
    """Generate and validate 6-part session codes (e.g., ABC-DEF-GHI-JKL-MNO-PQR)"""

    @staticmethod
    def generate() -> str:
        """Generate a random 6-part code"""
        parts = []
        for _ in range(6):
            part = ''.join(random.choices(string.ascii_uppercase, k=3))
            parts.append(part)
        return '-'.join(parts)

    @staticmethod
    def validate(code: str) -> bool:
        """Validate a 6-part code format"""
        if not code:
            return False
        parts = code.split('-')
        if len(parts) != 6:
            return False
        return all(len(part) == 3 and part.isalpha() and part.isupper() for part in parts)


class Player:
    """Represents a connected player"""

    def __init__(self, name: str, ws: web.WebSocketResponse):
        self.name = name
        self.ws = ws
        self.hp = 0
        self.max_hp = 0
        self.temp_hp = 0
        self.ac = 0
        self.initiative = 0
        self.is_dm = False

    def to_dict(self) -> dict:
        """Convert player to dictionary for JSON serialization"""
        return {
            'name': self.name,
            'HP': self.hp,
            'maxHP': self.max_hp,
            'tempHP': self.temp_hp,
            'AC': self.ac,
            'initiative': self.initiative,
            'isDM': self.is_dm
        }


class GameSession:
    """Manages a single game session"""

    def __init__(self, session_code: str, session_name: str, dm_name: str):
        self.code = session_code
        self.name = session_name
        self.dm_name = dm_name
        self.dm_token = secrets.token_urlsafe(32)  # Secure token for DM
        self.created_at = datetime.now()
        self.last_activity = datetime.now()
        self.players: Dict[str, Player] = {}
        self.monsters: List[dict] = []
        self.current_turn_index = 0
        self.settings = {
            'sessionName': session_name,
            'showPlayerHP': True,
            'showPlayerAC': True
        }

    def update_activity(self):
        """Update last activity timestamp"""
        self.last_activity = datetime.now()

    def is_expired(self, max_age_hours: int = 24) -> bool:
        """Check if session has expired (default 24 hours)"""
        age = datetime.now() - self.last_activity
        return age > timedelta(hours=max_age_hours)

    async def add_player(self, player: Player):
        """Add a player to the session"""
        self.players[player.name] = player
        self.update_activity()
        await self.broadcast({
            'type': 'player_joined',
            'name': player.name,
            'players': self.get_players_list(),
            'monsters': self.monsters,
            'currentTurnIndex': self.current_turn_index
        })

    async def remove_player(self, player_name: str):
        """Remove a player from the session"""
        if player_name in self.players:
            del self.players[player_name]
            self.update_activity()
            await self.broadcast({
                'type': 'player_left',
                'name': player_name,
                'players': self.get_players_list(),
                'monsters': self.monsters,
                'currentTurnIndex': self.current_turn_index
            })

    def get_players_list(self) -> List[dict]:
        """Get list of all players as dictionaries"""
        return [player.to_dict() for player in self.players.values()]

    def get_combatants(self) -> List[dict]:
        """Get combined list of players and monsters for combat"""
        combatants = self.get_players_list() + self.monsters
        # Sort by initiative (descending)
        combatants.sort(key=lambda x: x.get('initiative', 0), reverse=True)
        return combatants

    async def broadcast(self, message: dict, exclude: str = None):
        """Broadcast a message to all connected players"""
        disconnected = []
        for player_name, player in self.players.items():
            if exclude and player_name == exclude:
                continue
            try:
                await player.ws.send_json(message)
            except Exception as e:
                logger.error(f"Failed to send to {player_name}: {e}")
                disconnected.append(player_name)

        # Clean up disconnected players
        for player_name in disconnected:
            await self.remove_player(player_name)

    async def update_stats(self, player_name: str, stats: dict):
        """Update player stats"""
        if player_name in self.players:
            player = self.players[player_name]
            player.hp = stats.get('HP', player.hp)
            player.max_hp = stats.get('maxHP', player.max_hp)
            player.temp_hp = stats.get('tempHP', player.temp_hp)
            player.ac = stats.get('AC', player.ac)

            self.update_activity()
            await self.broadcast({
                'type': 'stats_update',
                'name': player_name,
                'stats': stats,
                'players': self.get_players_list()
            })

    async def update_initiative(self, player_name: str, initiative: int):
        """Update player initiative"""
        if player_name in self.players:
            self.players[player_name].initiative = initiative
            self.update_activity()
            await self.broadcast({
                'type': 'initiative_update',
                'name': player_name,
                'initiative': initiative,
                'combatants': self.get_combatants()
            })

    async def add_monster(self, monster_data: dict):
        """Add a monster to the session"""
        self.monsters.append(monster_data)
        self.update_activity()
        await self.broadcast({
            'type': 'monster_added',
            'monster': monster_data,
            'combatants': self.get_combatants()
        })

    async def remove_monster(self, monster_name: str):
        """Remove a monster from the session"""
        self.monsters = [m for m in self.monsters if m.get('name') != monster_name]
        self.update_activity()
        await self.broadcast({
            'type': 'monster_removed',
            'name': monster_name,
            'combatants': self.get_combatants()
        })

    async def next_turn(self):
        """Advance to the next turn"""
        combatants = self.get_combatants()
        if combatants:
            self.current_turn_index = (self.current_turn_index + 1) % len(combatants)
            self.update_activity()
            await self.broadcast({
                'type': 'turn_update',
                'currentTurnIndex': self.current_turn_index,
                'combatants': combatants
            })


class DnDServer:
    """Main server class"""

    def __init__(self):
        self.sessions: Dict[str, GameSession] = {}
        self.app = web.Application()
        self.setup_routes()

    def setup_routes(self):
        """Setup HTTP and WebSocket routes"""
        self.app.router.add_get('/health', self.health_check)
        self.app.router.add_post('/session/create', self.create_session)
        self.app.router.add_get('/session/{code}', self.get_session_info)
        self.app.router.add_get('/ws/{code}', self.websocket_handler)

    async def health_check(self, request):
        """Health check endpoint"""
        return web.json_response({
            'status': 'healthy',
            'sessions': len(self.sessions),
            'timestamp': datetime.now().isoformat()
        })

    async def create_session(self, request):
        """Create a new game session"""
        try:
            data = await request.json()
            session_name = data.get('sessionName', 'Unnamed Session')
            dm_name = data.get('dmName', 'DM')

            # Generate unique session code
            session_code = SessionCode.generate()
            while session_code in self.sessions:
                session_code = SessionCode.generate()

            # Create new session
            session = GameSession(session_code, session_name, dm_name)
            self.sessions[session_code] = session

            logger.info(f"Created session {session_code}: {session_name}")

            return web.json_response({
                'sessionCode': session_code,
                'sessionName': session_name,
                'dmToken': session.dm_token,  # Return token to DM for reconnection
                'createdAt': session.created_at.isoformat()
            })

        except Exception as e:
            logger.error(f"Error creating session: {e}")
            return web.json_response({'error': str(e)}, status=500)

    async def get_session_info(self, request):
        """Get information about a session"""
        session_code = request.match_info['code'].upper()

        if not SessionCode.validate(session_code):
            return web.json_response({'error': 'Invalid session code'}, status=400)

        if session_code not in self.sessions:
            return web.json_response({'error': 'Session not found'}, status=404)

        session = self.sessions[session_code]
        return web.json_response({
            'sessionCode': session.code,
            'sessionName': session.name,
            'dmName': session.dm_name,
            'playerCount': len(session.players),
            'createdAt': session.created_at.isoformat(),
            'lastActivity': session.last_activity.isoformat()
        })

    async def websocket_handler(self, request):
        """Handle WebSocket connections"""
        session_code = request.match_info['code'].upper()

        if not SessionCode.validate(session_code):
            return web.json_response({'error': 'Invalid session code'}, status=400)

        if session_code not in self.sessions:
            return web.json_response({'error': 'Session not found'}, status=404)

        session = self.sessions[session_code]
        ws = web.WebSocketResponse()
        await ws.prepare(request)

        player_name = None
        player = None

        try:
            async for msg in ws:
                if msg.type == WSMsgType.TEXT:
                    try:
                        data = json.loads(msg.data)
                        msg_type = data.get('type')

                        # Handle join
                        if msg_type == 'join':
                            player_name = data.get('name', 'Unknown Player')
                            is_dm = data.get('isDM', False)
                            dm_token = data.get('dmToken')  # Token for DM reconnection

                            # Verify DM token if claiming to be DM
                            if is_dm and dm_token:
                                if dm_token != session.dm_token:
                                    await ws.send_json({
                                        'type': 'error',
                                        'message': 'Invalid DM credentials'
                                    })
                                    return ws
                            elif is_dm and not dm_token:
                                # First time DM join (creating session)
                                pass

                            player = Player(player_name, ws)
                            player.is_dm = is_dm

                            await session.add_player(player)

                            # Send welcome message
                            await ws.send_json({
                                'type': 'welcome',
                                'players': session.get_players_list(),
                                'monsters': session.monsters,
                                'currentTurnIndex': session.current_turn_index,
                                'settings': session.settings,
                                'isDM': is_dm
                            })

                            logger.info(f"Player {player_name} {'(DM)' if is_dm else ''} joined session {session_code}")

                        # Handle stats update
                        elif msg_type == 'stats_update' and player_name:
                            stats = data.get('stats', {})
                            await session.update_stats(player_name, stats)

                        # Handle initiative update
                        elif msg_type == 'initiative_update' and player_name:
                            initiative = data.get('initiative', 0)
                            await session.update_initiative(player_name, initiative)

                        # Handle add monster (DM only)
                        elif msg_type == 'add_monster' and player and player.is_dm:
                            monster_data = data.get('monster', {})
                            await session.add_monster(monster_data)

                        # Handle remove monster (DM only)
                        elif msg_type == 'remove_monster' and player and player.is_dm:
                            monster_name = data.get('name')
                            await session.remove_monster(monster_name)

                        # Handle next turn (DM only)
                        elif msg_type == 'next_turn' and player and player.is_dm:
                            await session.next_turn()

                        # Handle update settings (DM only)
                        elif msg_type == 'update_settings' and player and player.is_dm:
                            settings = data.get('settings', {})
                            session.settings.update(settings)
                            await session.broadcast({
                                'type': 'settings_update',
                                'settings': session.settings
                            })

                    except json.JSONDecodeError:
                        logger.error(f"Invalid JSON from {player_name}")
                    except Exception as e:
                        logger.error(f"Error processing message from {player_name}: {e}")

                elif msg.type == WSMsgType.ERROR:
                    logger.error(f'WebSocket error: {ws.exception()}')

        finally:
            # Clean up on disconnect
            if player_name:
                await session.remove_player(player_name)
                logger.info(f"Player {player_name} left session {session_code}")

            # Remove expired sessions (1 day old with no players)
            if len(session.players) == 0 and session.is_expired(24):
                del self.sessions[session_code]
                logger.info(f"Removed expired session {session_code}")

        return ws

    def run(self, host='0.0.0.0', port=9000):
        """Start the server"""
        logger.info(f"Starting D&D Session Server on {host}:{port}")
        web.run_app(self.app, host=host, port=port)


if __name__ == '__main__':
    import os
    server = DnDServer()
    port = int(os.environ.get('SERVER_PORT', 9000))
    server.run(port=port)
