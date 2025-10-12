import 'dart:async';
import 'package:dnd/views/session/host.dart';
import 'package:flutter/material.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/classes/server.dart';
import 'package:dnd/classes/client.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  bool isHosting = false;
  bool isPlayer = false;
  bool serverRunning = false;

  final TextEditingController _sessionNameController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();

  DnDMulticastServer? _server;
  DnDClient? _client;

  Timer? _uiRefreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshUi();
  }

  void _refreshUi() {
    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    _server?.stop();
    super.dispose();
  }

  Future<void> _startServer() async {
    final name = _sessionNameController.text.trim().isEmpty
        ? 'Unnamed Session'
        : _sessionNameController.text.trim();

    _server = DnDMulticastServer();
    await _server!.start();

    setState(() => serverRunning = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🧙 Hosting "$name"')),
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HostPage(server: _server!, sessionName: name),
        ),
      );
    }
  }

  void _promptJoinServer(String ip, int port) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: Text('Join Session',
              style: TextStyle(color: AppColors.textColorLight)),
          content: TextField(
            controller: _playerNameController,
            decoration: InputDecoration(
              labelText: 'Enter your name',
              labelStyle: TextStyle(color: AppColors.textColorDark),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
            ),
            style: TextStyle(color: AppColors.textColorLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.warningColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.currentHealth,
              ),
              onPressed: () async {
                final name = _playerNameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(context);
                await _client!.joinSession(ip, port, name);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('🎲 Joined as $name')),
                );
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHostView() {
    return Column(
      children: [
        const SizedBox(height: 20),
        TextField(
          controller: _sessionNameController,
          decoration: InputDecoration(
            hintText: 'Enter session name...',
            hintStyle: TextStyle(color: AppColors.textColorDark),
            filled: true,
            fillColor: AppColors.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
          ),
          style: TextStyle(color: AppColors.textColorLight),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: serverRunning
                ? AppColors.dividerColor
                : AppColors.currentHealth,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: serverRunning ? null : _startServer,
          child: Text(
            serverRunning ? 'Server Running...' : 'Start Hosting',
            style: TextStyle(
              color: AppColors.textColorLight,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerView() {
    if (_client == null) {
      _client = DnDClient();
      _client!.listenForServers();
    }

    final sessions = _client?.discoveredSessions.values.toList() ?? [];

    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Searching for sessions...',
                        style: TextStyle(color: AppColors.textColorDark),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    return Card(
                      color: AppColors.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.borderColor),
                      ),
                      child: ListTile(
                        title: Text(
                          s['sessionName'] ?? 'Unknown Session',
                          style: TextStyle(color: AppColors.textColorLight),
                        ),
                        subtitle: Text(
                          'Players: ${s['players']}/${s['maxPlayers']} | ${s['ip']}:${s['port']}',
                          style: TextStyle(color: AppColors.textColorDark),
                        ),
                        onTap: () => _promptJoinServer(s['ip'], s['port']),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildModeSelection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.currentHealth,
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(Icons.shield, size: 28),
            label: const Text('Host Game', style: TextStyle(fontSize: 18)),
            onPressed: () => setState(() => isHosting = true),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tempHealth,
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(Icons.person_search, size: 28),
            label: const Text('Join Game', style: TextStyle(fontSize: 18)),
            onPressed: () => setState(() => isPlayer = true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        title: Text('D&D Session Lobby',
            style: TextStyle(color: AppColors.textColorLight)),
        centerTitle: true,
        leading: (isHosting || isPlayer)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                color: AppColors.textColorLight,
                onPressed: () => setState(() {
                  isHosting = false;
                  isPlayer = false;
                }),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: isHosting
              ? _buildHostView()
              : isPlayer
                  ? _buildPlayerView()
                  : _buildModeSelection(),
        ),
      ),
    );
  }
}
