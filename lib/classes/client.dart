import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DnDClient {
  final String multicastGroup = '239.255.255.250';
  final int multicastPort = 4446;

  final Map<String, Map<String, dynamic>> discoveredSessions = {};

  Future<void> listenForServers() async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      multicastPort,
      reuseAddress: true,
    );
    socket.joinMulticast(InternetAddress(multicastGroup));

    if (kDebugMode) {
      print('🎧 Listening for DM broadcasts...');
    }

    socket.listen((RawSocketEvent e) async {
      if (e == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram == null) return;

        final msg = utf8.decode(datagram.data);
        final json = jsonDecode(msg);

        if (json['type'] == 'server_announce') {
          final key = '${json['ip']}:${json['port']}';
          discoveredSessions[key] = json;
          _printDiscoveredSessions();
        }
      }
    });
  }

  void _printDiscoveredSessions() {
    if (kDebugMode) {
      print('📜 Discovered sessions:');
    }
    for (var entry in discoveredSessions.entries) {
      final s = entry.value;
      if (kDebugMode) {
        print(' - ${s['sessionName']} '
          '(${s['players']}/${s['maxPlayers']}) '
          '[${s['ip']}:${s['port']}]');
      }
    }
  }

  Future<void> joinSession(String ip, int port, String playerName) async {
    final uri = Uri.parse('http://$ip:$port/join');
    final res = await http.post(uri, body: jsonEncode({'name': playerName}), headers: {
      'Content-Type': 'application/json',
    });

    if (res.statusCode == 200) {
      if (kDebugMode) {
        print('✅ Joined session: ${res.body}');
      }
    } else {
      if (kDebugMode) {
        print('❌ Failed to join session');
      }
    }
  }
}
