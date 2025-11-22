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
  final Map<String, dynamic> _sessionSettings = {
    'sessionName': "Unnamed Session",
  };

  final List<Map<String, dynamic>> _playerStats = [];

  bool get serverStarted => _server != null;

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
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
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

        _players.add({
          'name': data['name'],
          'joinedAt': DateTime.now().toIso8601String()
        });
        _playerStreamController.add(List.from(_players));

        _broadcastToClients({
          'type': 'player_joined',
          'players': _players,
          'settings': _sessionSettings,
        });

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
          _playerStreamController.add(List.from(_players));

          _broadcastToClients({
            'type': 'player_left',
            'players': _players,
          });

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

        _playerStats.add({
          'name': data['name'],
          'stats': {
            'AC': data['AC'],
            'HP': data['HP'],
          }
        });

        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..close();
        print('📊 Stats updated for: ${data['name']}');
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

    socket.listen((message) {
      final data = jsonDecode(message);
      print('📩 From client: $data');
    }, onDone: () {
      _connectedClients.remove(socket);
      print('❌ Client disconnected');
    });

    socket.add(jsonEncode({
      'type': 'welcome',
      'players': _players,
      'settings': _sessionSettings,
    }));
  }

  void _broadcastToClients(Map<String, dynamic> data) {
    final jsonData = jsonEncode(data);
    for (final client in List<WebSocket>.from(_connectedClients)) {
      try {
        client.add(jsonData);
      } catch (e) {
        print('⚠️ Failed to send to client: $e');
      }
    }
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

  Future<void> stop() async {
    await _server?.close();
    multicastTimer?.cancel();
    multicastSocket?.close();
    for (final client in _connectedClients) {
      client.close();
    }
    await _playerStreamController.close();
    print('🛑 Server stopped.');
  }
}

void main() async {
  final server = DnDMulticastServer(port: 4040);
  await server.start();
}
