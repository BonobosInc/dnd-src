import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dnd/classes/profile_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DnDClient {
  final String multicastGroup = '239.255.255.250';
  final int multicastPort = 4210;

  String? connectedIp;
  int? connectedPort;
  String? playerName;
  String? sessionName;
  bool get isConnected => connectedIp != null && connectedPort != null;

  final Map<String, Map<String, dynamic>> discoveredSessions = {};
  WebSocket? _socket;
  RawDatagramSocket? _multicastSocket;
  StreamSubscription<RawSocketEvent>? _multicastSubscription;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  final List<String> players = [];
  final List<Map<String, dynamic>> playersData = [];
  final List<Map<String, dynamic>> monstersData = [];
  Map<String, dynamic>? sessionSettings;

  final StreamController<List<String>> _playerListController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get playerListStream => _playerListController.stream;

  Future<void> listenForServers() async {
    // Don't start listening if already connected
    if (isConnected) {
      if (kDebugMode)
        print('⚠️ Already connected to a session, not listening for servers.');
      return;
    }

    _multicastSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      multicastPort,
      reuseAddress: true,
    );
    _multicastSocket!.joinMulticast(InternetAddress(multicastGroup));

    if (kDebugMode) print('🎧 Listening for DM broadcasts...');

    _multicastSubscription = _multicastSocket!.listen((RawSocketEvent e) async {
      if (e == RawSocketEvent.read) {
        final datagram = _multicastSocket?.receive();
        if (datagram == null) return;

        try {
          final msg = utf8.decode(datagram.data);
          final json = jsonDecode(msg);

          if (json['type'] == 'server_announce') {
            final key = '${json['ip']}:${json['port']}';
            discoveredSessions[key] = json;
            _printDiscoveredSessions();
          }
        } catch (err) {
          if (kDebugMode) print('⚠️ Invalid multicast packet: $err');
        }
      }
    });
  }

  void stopListeningForServers() {
    _multicastSubscription?.cancel();
    _multicastSubscription = null;
    _multicastSocket?.close();
    _multicastSocket = null;
    if (kDebugMode) print('🔇 Stopped listening for DM broadcasts.');
  }

  void _printDiscoveredSessions() {
    if (kDebugMode) print('📜 Discovered sessions:');
    for (var entry in discoveredSessions.entries) {
      final s = entry.value;
      if (kDebugMode) {
        print(' - ${s['sessionName']} '
            '(${s['players']}/${s['maxPlayers']}) '
            '[${s['ip']}:${s['port']}]');
      }
    }
  }

  Future<void> joinSession(String ip, int port, Character player) async {
    final uri = Uri.parse('http://$ip:$port/join');
    final res = await http.post(
      uri,
      body: jsonEncode({'name': player.name}),
      headers: {'Content-Type': 'application/json'},
    );

    connectedIp = ip;
    connectedPort = port;
    playerName = player.name;
    sessionName =
        discoveredSessions['$ip:$port']?['sessionName'] ?? 'Unknown Session';

    if (res.statusCode == 200) {
      if (kDebugMode) print('✅ Joined session: ${res.body}');
      stopListeningForServers(); // Stop polling for servers once connected
      await connectToWebSocket(ip, port);
    } else {
      if (kDebugMode) print('❌ Failed to join session');
    }
  }

  Future<void> connectToWebSocket(String ip, int port) async {
    final uri = Uri.parse('ws://$ip:$port/ws');

    try {
      _socket = await WebSocket.connect(uri.toString());
      if (kDebugMode) print('🔗 Connected to $ip:$port WebSocket');

      _socket!.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (!_messageController.isClosed) {
              _messageController.add(data);
            }

            switch (data['type']) {
              case 'welcome':
                if (data['players'] is List) {
                  players
                    ..clear()
                    ..addAll(List<String>.from(
                      data['players'].map((p) => p['name']),
                    ));
                  if (!_playerListController.isClosed) {
                    _playerListController.add(List.from(players));
                  }

                  playersData
                    ..clear()
                    ..addAll(List<Map<String, dynamic>>.from(data['players']));
                }
                if (data['monsters'] is List) {
                  monstersData
                    ..clear()
                    ..addAll(List<Map<String, dynamic>>.from(data['monsters']));
                }
                if (data['settings'] != null) {
                  sessionSettings = data['settings'];
                }
                if (kDebugMode) {
                  print('👋 Session: ${data['settings']?['sessionName']}');
                  print('Players: $players');
                }
                break;

              case 'player_joined':
                if (data['players'] is List) {
                  players
                    ..clear()
                    ..addAll(List<String>.from(
                      data['players'].map((p) => p['name']),
                    ));
                  if (!_playerListController.isClosed) {
                    _playerListController.add(List.from(players));
                  }

                  playersData
                    ..clear()
                    ..addAll(List<Map<String, dynamic>>.from(data['players']));
                }
                if (data['monsters'] is List) {
                  monstersData
                    ..clear()
                    ..addAll(List<Map<String, dynamic>>.from(data['monsters']));
                }
                if (kDebugMode) print('🎲 Player joined: $players');
                break;

              case 'player_left':
                if (data['players'] is List) {
                  players
                    ..clear()
                    ..addAll(List<String>.from(
                      data['players'].map((p) => p['name']),
                    ));
                  if (!_playerListController.isClosed) {
                    _playerListController.add(List.from(players));
                  }

                  playersData
                    ..clear()
                    ..addAll(List<Map<String, dynamic>>.from(data['players']));
                }
                if (data['monsters'] is List) {
                  monstersData
                    ..clear()
                    ..addAll(List<Map<String, dynamic>>.from(data['monsters']));
                }
                if (kDebugMode) print('🚪 Player left: $players');
                break;

              case 'initiative_updated':
              case 'combatants_updated':
                if (data['players'] is List) {
                  players
                    ..clear()
                    ..addAll(List<String>.from(
                      data['players'].map((p) => p['name']),
                    ));
                  if (!_playerListController.isClosed) {
                    _playerListController.add(List.from(players));
                  }

                  playersData
                    ..clear()
                    ..addAll(List<Map<String, dynamic>>.from(data['players']));
                }
                if (data['monsters'] is List) {
                  monstersData
                    ..clear()
                    ..addAll(List<Map<String, dynamic>>.from(data['monsters']));
                }
                if (kDebugMode) print('🎲 Initiative/combatants updated');
                break;

              case 'settings_updated':
                if (data['settings'] != null) {
                  sessionSettings = data['settings'];
                  if (kDebugMode) {
                    print('⚙️ Settings updated in client');
                    print(
                        '  - showPlayerHP: ${sessionSettings?['showPlayerHP']}');
                    print(
                        '  - showPlayerAC: ${sessionSettings?['showPlayerAC']}');
                  }
                }
                break;

              default:
                if (kDebugMode) print('📩 Unknown WS message: $data');
            }
          } catch (err) {
            if (kDebugMode) print('⚠️ Invalid WS message: $err');
          }
        },
        onDone: () {
          if (kDebugMode) print('🔌 WebSocket closed.');
        },
        onError: (err) {
          if (kDebugMode) print('❗ WebSocket error: $err');
        },
      );
    } catch (err) {
      if (kDebugMode) print('❌ Failed to connect WebSocket: $err');
    }
  }

  // i need a function to get data from the /allstats endpoint
  Future<Map<String, dynamic>?> fetchAllStats() async {
    if (!isConnected) {
      if (kDebugMode) print('❌ Not connected to any session.');
      return null;
    }

    final uri = Uri.parse('http://$connectedIp:$connectedPort/allstats');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (kDebugMode) print('📊 Fetched all stats: $data');
        return data;
      } else {
        if (kDebugMode) print('❌ Failed to fetch stats: ${res.statusCode}');
        return null;
      }
    } catch (err) {
      if (kDebugMode) print('❌ Error fetching stats: $err');
      return null;
    }
  }

  Future<bool> sendStats(Map<String, dynamic> stats) async {
    if (!isConnected || playerName == null) {
      if (kDebugMode) print('❌ Not connected to any session.');
      return false;
    }

    final uri = Uri.parse('http://$connectedIp:$connectedPort/stats');
    final body = {
      'name': playerName,
      ...stats,
    };

    if (kDebugMode) print('📤 Sending stats for $playerName: HP=${stats['HP']}, AC=${stats['AC']}');

    try {
      final res = await http.post(
        uri,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        if (kDebugMode) print('✅ Stats sent successfully.');
        return true;
      } else {
        if (kDebugMode) print('❌ Failed to send stats: ${res.statusCode}');
        return false;
      }
    } catch (err) {
      if (kDebugMode) print('❌ Error sending stats: $err');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchSettings() async {
    if (!isConnected) {
      if (kDebugMode) print('❌ Not connected to any session.');
      return null;
    }

    final uri = Uri.parse('http://$connectedIp:$connectedPort/settings');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (kDebugMode) print('⚙️ Fetched settings: $data');
        return data;
      } else {
        if (kDebugMode) print('❌ Failed to fetch settings: ${res.statusCode}');
        return null;
      }
    } catch (err) {
      if (kDebugMode) print('❌ Error fetching settings: $err');
      return null;
    }
  }

  Future<void> disconnect({bool restartListening = false}) async {
    if (!isConnected) {
      if (kDebugMode) print('⚠️ Already disconnected');
      return;
    }

    try {
      // Save connection info before clearing
      final ip = connectedIp;
      final port = connectedPort;
      final name = playerName;

      // Clear connection state first
      _socket?.close();
      _socket = null;
      connectedIp = null;
      connectedPort = null;
      playerName = null;
      sessionName = null;
      players.clear();
      playersData.clear();
      monstersData.clear();
      sessionSettings = null;

      // Notify listeners with empty data if controllers are still open
      if (!_playerListController.isClosed) {
        _playerListController.add(List.from(players));
      }

      // Send disconnect notification to server
      if (ip != null && port != null && name != null) {
        try {
          final uri = Uri.parse('http://$ip:$port/disconnect');
          await http.post(uri, body: jsonEncode({'name': name}));
        } catch (e) {
          if (kDebugMode) print('⚠️ Failed to notify server of disconnect: $e');
        }
      }

      if (kDebugMode) print('🔕 Disconnected from session.');

      // Optionally restart listening for servers after disconnect
      if (restartListening) {
        await listenForServers();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Disconnect error: $e');
    }
  }
}
