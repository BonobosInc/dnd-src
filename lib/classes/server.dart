import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DnDMulticastServer {
  final int port;
  HttpServer? _server;
  RawDatagramSocket? multicastSocket;
  Timer? multicastTimer;
  String name = "Unnamed Session";

  final List<Map<String, dynamic>> _players = [];
  final List<Map<String, dynamic>> _monsters = [];
  final Map<String, dynamic> _sessionSettings = {
    'sessionName': "Unnamed Session",
  };

  int _currentTurnIndex = 0;

  bool get serverStarted => _server != null;
  Map<String, dynamic> get sessionSettings => _sessionSettings;

  final List<WebSocket> _connectedClients = [];

  final StreamController<List<Map<String, dynamic>>> _playerStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get playerStream =>
      _playerStreamController.stream;

  String? localIp;
  final String multicastGroup = "239.255.255.250";
  final int multicastPort = 4210;

  DnDMulticastServer({this.port = 4040});

  Future<void> start() async {
    // Don't start if already running
    if (_server != null) {
      print('⚠️ Server already running on port $port');
      return;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } catch (e) {
      print('⚠️ Failed to bind to port $port: $e');
      print('💡 Try stopping any existing servers first');
      rethrow;
    }
    localIp = await _getLocalIp();
    print('🧙 DM REST API running at $localIp:$port');
    _sessionSettings['sessionName'] = name;

    await _startMulticastBroadcast();

    _server!.listen((HttpRequest req) async {
      if (req.uri.path == '/ws') {
        if (WebSocketTransformer.isUpgradeRequest(req)) {
          final socket = await WebSocketTransformer.upgrade(req);
          _handleWebSocket(socket);
        } else {
          req.response
            ..statusCode = HttpStatus.badRequest
            ..write('Expected WebSocket upgrade')
            ..close();
        }
      } else if (req.method == 'POST' && req.uri.path == '/join') {
        final body = await utf8.decoder.bind(req).join();
        final data = jsonDecode(body);

        // Check if player already exists (rejoining)
        final existingPlayerIndex = _players.indexWhere((p) => p['name'] == data['name']);
        if (existingPlayerIndex == -1) {
          // New player
          _players.add({
            'name': data['name'],
            'joinedAt': DateTime.now().toIso8601String(),
            'initiative': 0,
            'HP': null,
            'maxHP': null,
            'tempHP': null,
            'AC': null,
          });
        }
        // If player exists, don't add duplicate but still broadcast

        _broadcastCombatants();

        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'status': 'joined', 'player': data['name']}))
          ..close();

        print('🎲 Player joined: ${data['name']}');
      } else if (req.method == 'GET' && req.uri.path == '/settings') {
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(_sessionSettings))
          ..close();
      } else if (req.method == 'POST' && req.uri.path == '/disconnect') {
        final body = await utf8.decoder.bind(req).join();
        final data = jsonDecode(body);

        final name = data['name'];
        if (name != null) {
          _players.removeWhere((p) => p['name'] == name);
          _broadcastCombatants();

          print('👋 Player left: $name');
        }

        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'status': 'disconnected', 'player': name}))
          ..close();
      } else if (req.method == 'GET' && req.uri.path == '/allstats') {
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'players': _players,
            'settings': _sessionSettings,
          }))
          ..close();
      } else if (req.method == 'POST' && req.uri.path == '/stats') {
        final body = await utf8.decoder.bind(req).join();
        final data = jsonDecode(body);

        final playerName = data['name'];
        final playerIndex = _players.indexWhere((p) => p['name'] == playerName);

        if (playerIndex != -1) {
          // Update existing player stats - create a new map to trigger stream updates
          _players[playerIndex] = {
            ..._players[playerIndex],
            'HP': data['HP'],
            'maxHP': data['maxHP'],
            'tempHP': data['tempHP'],
            'AC': data['AC'],
          };

          // Broadcast update to all clients
          _broadcastCombatants();

          print(
              '📊 Stats updated for: $playerName (HP: ${data['HP']}/${data['maxHP']} (+${data['tempHP']}), AC: ${data['AC']})');
        } else {
          print('⚠️ Player $playerName not found in players list');
        }

        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..close();
      } else if (req.method == 'POST' && req.uri.path == '/initiative') {
        final body = await utf8.decoder.bind(req).join();
        final data = jsonDecode(body);

        final playerName = data['name'];
        final initiative = data['initiative'];

        final playerIndex = _players.indexWhere((p) => p['name'] == playerName);
        if (playerIndex != -1) {
          _players[playerIndex]['initiative'] = initiative;
          _broadcastCombatants();

          req.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'status': 'updated'}))
            ..close();
          print('🎲 Initiative updated for ${playerName}: $initiative');
        } else {
          req.response
            ..statusCode = HttpStatus.notFound
            ..write('Player not found')
            ..close();
        }
      } else {
        req.response
          ..statusCode = HttpStatus.notFound
          ..write('404 Not Found')
          ..close();
      }
    });
  }

  void _handleWebSocket(WebSocket socket) {
    _connectedClients.add(socket);
    print('🔗 Client connected (${_connectedClients.length})');

    String? playerName;

    socket.listen((message) {
      final data = jsonDecode(message);
      print('📩 From client: $data');

      // Track which player this socket belongs to
      if (data['type'] == 'join' && data['name'] != null) {
        playerName = data['name'];
      }
    }, onDone: () {
      _connectedClients.remove(socket);
      print('❌ Client disconnected');

      // Remove the player from the session if we know their name
      if (playerName != null) {
        _players.removeWhere((p) => p['name'] == playerName);
        print('👋 Player $playerName removed from session');
        _broadcastCombatants();
        _broadcastToClients({
          'type': 'player_left',
          'name': playerName,
          'players': _players,
          'monsters': _monsters,
          'currentTurnIndex': _currentTurnIndex,
        });
      }
    });

    socket.add(jsonEncode({
      'type': 'welcome',
      'players': _players,
      'monsters': _monsters,
      'currentTurnIndex': _currentTurnIndex,
      'settings': _sessionSettings,
    }));
  }

  void _broadcastToClients(Map<String, dynamic> data) {
    final jsonData = jsonEncode(data);
    print(
        '📡 [Server] Broadcasting ${data['type']} to ${_connectedClients.length} clients');
    print('📡 [Server] Message: $jsonData');
    int sent = 0;
    for (final client in List<WebSocket>.from(_connectedClients)) {
      try {
        client.add(jsonData);
        sent++;
      } catch (e) {
        print('⚠️ Failed to send to client: $e');
      }
    }
    print('📡 [Server] Successfully sent to $sent clients');
  }

  Future<void> _startMulticastBroadcast() async {
    multicastSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    multicastTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final ip = await _getLocalIp();
      final announce = jsonEncode({
        'type': 'server_announce',
        'sessionName': _sessionSettings['sessionName'],
        'ip': ip,
        'port': port,
      });
      multicastSocket!.send(
        utf8.encode(announce),
        InternetAddress(multicastGroup),
        multicastPort,
      );
      print("📡 Broadcasting server: $ip:$port");
    });
  }

  Future<String> _getLocalIp() async {
    final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4, includeLoopback: false);
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return '127.0.0.1';
  }

  void addMonster(Map<String, dynamic> monster) {
    _monsters.add(monster);
    _broadcastCombatants();
    print('👾 Monster added: ${monster['name']}');
  }

  void removeMonster(String monsterName) {
    _monsters.removeWhere((m) => m['name'] == monsterName);
    _broadcastCombatants();
  }

  void updateMonsterStats(String monsterName, {int? hp, int? maxHp, int? ac}) {
    final monsterIndex = _monsters.indexWhere((m) => m['name'] == monsterName);
    if (monsterIndex != -1) {
      // Create a new map to trigger stream updates
      _monsters[monsterIndex] = {
        ..._monsters[monsterIndex],
        if (hp != null) 'hp': hp,
        if (maxHp != null) 'maxHp': maxHp,
        if (ac != null) 'ac': ac,
      };
      _broadcastCombatants();
      print('📊 Monster stats updated for: $monsterName (HP: ${_monsters[monsterIndex]['hp']}/${_monsters[monsterIndex]['maxHp']}, AC: ${_monsters[monsterIndex]['ac']})');
    }
  }

  void updateMonsterName(String oldName, String newName) {
    final monsterIndex = _monsters.indexWhere((m) => m['name'] == oldName);
    if (monsterIndex != -1) {
      _monsters[monsterIndex]['name'] = newName;
      _broadcastCombatants();
      print('📝 Monster name updated: $oldName -> $newName');
    }
  }

  void nextTurn() {
    final totalCombatants = _players.length + _monsters.length;
    if (totalCombatants > 0) {
      _currentTurnIndex = (_currentTurnIndex + 1) % totalCombatants;
      _broadcastCombatants();
      print('➡️ Turn advanced to index: $_currentTurnIndex');
    }
  }

  void _broadcastCombatants() {
    // Combine and sort by initiative (highest to lowest)
    final allCombatants = [..._players, ..._monsters];
    allCombatants.sort((a, b) {
      final aInit = a['initiative'] ?? 0;
      final bInit = b['initiative'] ?? 0;
      return bInit.compareTo(aInit); // Descending order
    });

    // Ensure turn index is valid
    if (_currentTurnIndex >= allCombatants.length) {
      _currentTurnIndex = 0;
    }

    print(
        '📊 Broadcasting combatants: ${_players.length} players, ${_monsters.length} monsters');

    _playerStreamController.add(allCombatants);
    _broadcastToClients({
      'type': 'combatants_updated',
      'players': _players,
      'monsters': _monsters,
      'currentTurnIndex': _currentTurnIndex,
    });
  }

  Future<void> updateInitiative(String name, int initiative) async {
    // Try to find in players first
    final playerIndex = _players.indexWhere((p) => p['name'] == name);
    if (playerIndex != -1) {
      _players[playerIndex]['initiative'] = initiative;
      _broadcastCombatants();
      print('🎲 Initiative updated for player $name: $initiative');
      return;
    }

    // Try to find in monsters
    final monsterIndex = _monsters.indexWhere((m) => m['name'] == name);
    if (monsterIndex != -1) {
      _monsters[monsterIndex]['initiative'] = initiative;
      _broadcastCombatants();
      print('🎲 Initiative updated for monster $name: $initiative');
      return;
    }

    print('⚠️ Combatant $name not found for initiative update');
  }

  Future<void> stop() async {
    multicastTimer?.cancel();
    multicastSocket?.close();
    for (final client in _connectedClients) {
      try {
        client.close();
      } catch (e) {
        print('Error closing client: $e');
      }
    }
    _connectedClients.clear();
    try {
      await _server?.close(force: true);
    } catch (e) {
      print('Error closing server: $e');
    }
    _server = null;
    if (!_playerStreamController.isClosed) {
      await _playerStreamController.close();
    }
    print('🛑 Server stopped.');
  }
}

void main() async {
  final server = DnDMulticastServer(port: 4040);
  await server.start();
}
