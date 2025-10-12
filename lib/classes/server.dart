import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DnDMulticastServer {
  final int port;
  HttpServer? _server;
  RawDatagramSocket? multicastSocket;
  Timer? multicastTimer;

  // store session data
  final List<Map<String, dynamic>> _players = [];
  final Map<String, dynamic> _sessionSettings = {
    'sessionName': 'Dungeon of Doom',
    'difficulty': 'Hard',
    'maxPlayers': 6,
    'rules': 'Standard 5e',
  };

  // StreamController for broadcasting player updates
  final StreamController<List<Map<String, dynamic>>> _playerStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get playerStream =>
      _playerStreamController.stream;

  // For host info
  String? localIp;
  final String multicastGroup = "239.255.255.250";
  final int multicastPort = 4210;

  DnDMulticastServer({this.port = 4040});

  Future<void> start() async {
    // 1️⃣ Start HTTP server
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    localIp = await _getLocalIp();
    print('🧙 DM REST API running at $localIp:$port');

    // 2️⃣ Start multicast broadcasting for discovery
    await _startMulticastBroadcast();

    // 3️⃣ Handle REST endpoints
    _server!.listen((HttpRequest req) async {
      if (req.method == 'POST' && req.uri.path == '/stats') {
        final body = await utf8.decoder.bind(req).join();
        final data = jsonDecode(body);
        print('📥 Received stats: $data');

        _players.add(data);
        _playerStreamController.add(List.from(_players)); // 🚀 Emit update

        req.response
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'status': 'received', 'count': _players.length}))
          ..close();
      } else if (req.method == 'GET' && req.uri.path == '/settings') {
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(_sessionSettings))
          ..close();
      } else if (req.method == 'GET' && req.uri.path == '/state') {
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'players': _players,
            'settings': _sessionSettings,
          }))
          ..close();
      } else {
        req.response
          ..statusCode = HttpStatus.notFound
          ..write('404 Not Found')
          ..close();
      }
    });
  }

  Future<void> _startMulticastBroadcast() async {
    multicastSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    multicastTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final ip = await _getLocalIp();
      final announce = jsonEncode({
        'type': 'server_announce',
        'sessionName': _sessionSettings['sessionName'],
        'players': _players.length,
        'maxPlayers': _sessionSettings['maxPlayers'],
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
        type: InternetAddressType.IPv4,
        includeLoopback: false);
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
    await _playerStreamController.close();
    print('🛑 Server stopped.');
  }
}
