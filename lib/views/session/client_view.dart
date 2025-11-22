import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/classes/client.dart';

class ClientPage extends StatefulWidget {
  final DnDClient client;
  final String playerName;
  final bool isFromLobby;

  const ClientPage({
    super.key,
    required this.client,
    required this.playerName,
    required this.isFromLobby,
  });

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  late StreamSubscription _messageSub;
  List<Map<String, dynamic>> _players = [];
  Map<String, dynamic>? _settings;

  @override
  void initState() {
    super.initState();

    _messageSub = widget.client.messages.listen((data) {
      if (!mounted) return;

      switch (data['type']) {
        case 'welcome':
          setState(() {
            _players = List<Map<String, dynamic>>.from(data['players'] ?? []);
            _settings = data['settings'];
          });
          print('👋 Welcome update received.');
          break;

        case 'player_joined':
          setState(() {
            _players = List<Map<String, dynamic>>.from(data['players'] ?? []);
          });
          print('🎲 Player joined update.');
          break;

        case 'player_left':
          setState(() {
            _players = List<Map<String, dynamic>>.from(data['players'] ?? []);
          });
          print('👋 Player left update.');
          break;

        default:
          print('📩 Unknown WS message: $data');
      }
    });
  }

  @override
  void dispose() {
    _messageSub.cancel();
    super.dispose();
  }

  void goBacktoHomescreen() {
    if (!mounted) return;
    Navigator.pop(context);
    if (widget.isFromLobby) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        title: Text(
          'Session: ${widget.client.sessionName ?? 'Loading...'}',
          style: TextStyle(color: AppColors.textColorLight),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textColorLight,
          onPressed: () => goBacktoHomescreen(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textColorLight),
            color: AppColors.cardColor,
            onSelected: (value) async {
              if (value == 'quit') {
                await widget.client.disconnect();
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'quit',
                child: Text('Quit Session',
                    style: TextStyle(color: AppColors.warningColor)),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🧙 Session: ${_settings?['sessionName'] ?? 'Loading...'}',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'Players connected:',
              style: TextStyle(color: AppColors.textColorDark),
            ),
            const SizedBox(height: 8),
            ..._players.map((p) => Text(
                  '• ${p['name']}',
                  style: const TextStyle(color: Colors.white70),
                )),
          ],
        ),
      ),
    );
  }
}
