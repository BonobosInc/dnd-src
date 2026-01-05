# D&D Session Server

A Python-based WebSocket server for managing D&D game sessions remotely.

## Features

- **6-Part Session Codes**: Easy-to-share session codes (e.g., `ABC-DEF-GHI-JKL-MNO-PQR`)
- **Real-time Updates**: WebSocket-based communication for instant updates
- **DM Authentication**: Secure tokens allow DMs to reconnect and maintain admin status
- **Player Management**: Track HP, AC, initiative, and other stats
- **Combat Tracking**: Manage turn order and monster encounters
- **24-Hour Persistence**: Sessions remain active for 24 hours from last activity
- **Docker Support**: Easy deployment with Docker and Docker Compose

## Quick Start

### Using Docker Compose (Recommended)

1. Navigate to the server directory:
```bash
cd server
```

2. Build and start the container:
```bash
docker-compose up -d
```

3. Check logs:
```bash
docker-compose logs -f
```

4. Stop the server:
```bash
docker-compose down
```

### Using Docker Directly

Build the image:
```bash
docker build -t dnd-server .
```

Run the container:
```bash
docker run -d -p 31333:31333 --name dnd-server dnd-server
```

### Running Without Docker

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the server:
```bash
python main.py
```

Server will start on `http://0.0.0.0:31333`

## API Endpoints

### HTTP Endpoints

- `GET /health` - Health check endpoint
- `POST /session/create` - Create a new session
  ```json
  {
    "sessionName": "My Campaign",
    "dmName": "DM Name"
  }
  ```
- `GET /session/{code}` - Get session information

### WebSocket Endpoint

- `WS /ws/{code}` - Connect to a session

## WebSocket Messages

### Client → Server

**Join Session:**
```json
{
  "type": "join",
  "name": "Player Name",
  "isDM": false,
  "dmToken": "optional-token-for-dm-reconnection"
}
```

**Update Stats:**
```json
{
  "type": "stats_update",
  "stats": {
    "HP": 45,
    "maxHP": 50,
    "tempHP": 5,
    "AC": 16
  }
}
```

**Update Initiative:**
```json
{
  "type": "initiative_update",
  "initiative": 18
}
```

**Add Monster (DM only):**
```json
{
  "type": "add_monster",
  "monster": {
    "name": "Goblin",
    "HP": 7,
    "maxHP": 7,
    "AC": 15,
    "initiative": 12
  }
}
```

**Next Turn (DM only):**
```json
{
  "type": "next_turn"
}
```

### Server → Client

**Welcome Message:**
```json
{
  "type": "welcome",
  "players": [...],
  "monsters": [...],
  "currentTurnIndex": 0,
  "settings": {...},
  "isDM": true
}
```

**Player Joined:**
```json
{
  "type": "player_joined",
  "name": "Player Name",
  "players": [...],
  "monsters": [...],
  "currentTurnIndex": 0
}
```

## Configuration

The server runs on port 31333 by default. To change this:

**Docker Compose**: Edit `docker-compose.yml`
```yaml
ports:
  - "YOUR_PORT:31333"
environment:
  - SERVER_PORT=31333
```

**Direct Python**: Set environment variable
```bash
SERVER_PORT=8080 python main.py
```

## Port Forwarding

To make your server accessible from the internet:

1. Configure your router to forward **TCP port 31333** to your server's local IP
2. Use a dynamic DNS service (e.g., DuckDNS: bonodnd.duckdns.org)
3. Consider using a reverse proxy (nginx) with SSL for production

## Security Considerations

- Sessions use random 6-part codes for access control
- Consider adding authentication for production use
- Use SSL/TLS for connections over the internet
- Implement rate limiting for production deployments

## Session Cleanup

Sessions are automatically removed after 24 hours of inactivity (no players connected and no recent activity). DMs can reconnect anytime within this period using their saved token.
