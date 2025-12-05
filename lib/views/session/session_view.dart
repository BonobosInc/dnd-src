import 'dart:async';
import 'package:dnd/classes/profile_manager.dart';
import 'package:dnd/classes/wiki_parser.dart';
import 'package:dnd/views/session/client_view.dart';
import 'package:dnd/views/session/host.dart';
import 'package:flutter/material.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/classes/server.dart';
import 'package:dnd/classes/client.dart';

class LobbyPage extends StatefulWidget {
  DnDMulticastServer? _server;
  DnDClient? _client;
  List<Character>? profiles;
  final ProfileManager profileManager;
  final WikiParser? wikiParser;

  LobbyPage({
    super.key,
    required DnDMulticastServer server,
    required DnDClient client,
    required this.profiles,
    required this.profileManager,
    this.wikiParser,
  })  : _server = server,
        _client = client;

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  bool isHosting = false;
  bool isPlayer = false;
  bool serverRunning = false;
  bool _isListeningForServers = false;

  final TextEditingController _sessionNameController = TextEditingController();

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
    if (_isListeningForServers) {
      widget._client?.stopListeningForServers();
    }
    super.dispose();
  }

  Future<void> _startServer() async {
    final name = _sessionNameController.text.trim().isEmpty
        ? 'Unnamed Session'
        : _sessionNameController.text.trim();

    widget._server = DnDMulticastServer();
    widget._server?.name = name;
    await widget._server!.start();

    setState(() => serverRunning = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🧙 Hosting "$name"')),
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HostPage(
            server: widget._server!,
            sessionName: name,
            wikiParser: widget.wikiParser,
          ),
        ),
      );
    }
  }

  void _promptJoinServer(String ip, int port) async {
    if (widget._client?.isConnected == true &&
        widget._client?.connectedIp == ip &&
        widget._client?.connectedPort == port) {
      // Load character stats for already connected player
      List<Map<String, dynamic>> stats = await widget.profileManager.getStats();
      int? hp;
      int? maxHp;
      int? tempHp;
      int? ac;
      if (stats.isNotEmpty) {
        hp = stats.first['HP'] as int?;
        maxHp = stats.first['maxHP'] as int?;
        tempHp = stats.first['temphp'] as int?;
        ac = stats.first['AC'] as int?;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClientPage(
              client: widget._client!,
              playerName: widget._client!.playerName ?? 'Unknown Player',
              isFromLobby: true,
              playerHP: hp,
              playerMaxHP: maxHp,
              playerTempHP: tempHp,
              playerAC: ac),
        ),
      );
      return;
    }

    Character? selectedCharacter;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: Text(
            'Choose Character',
            style: TextStyle(color: AppColors.textColorLight),
          ),
          content: widget.profiles == null || widget.profiles!.isEmpty
              ? Text(
                  'No characters found. Please create one first.',
                  style: TextStyle(color: AppColors.textColorDark),
                )
              : StatefulBuilder(
                  builder: (context, setState) {
                    return DropdownButtonFormField<Character>(
                      dropdownColor: AppColors.cardColor,
                      initialValue: selectedCharacter,
                      items: widget.profiles!
                          .map(
                            (character) => DropdownMenuItem<Character>(
                              value: character,
                              child: Text(
                                character.name,
                                style:
                                    TextStyle(color: AppColors.textColorLight),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedCharacter = value),
                      decoration: InputDecoration(
                        labelText: 'Select your character',
                        labelStyle: TextStyle(color: AppColors.textColorDark),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.borderColor),
                        ),
                      ),
                    );
                  },
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
                if (selectedCharacter == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a character!')),
                  );
                  return;
                }

                // Load character stats
                await widget.profileManager.selectProfile(selectedCharacter!);
                List<Map<String, dynamic>> stats =
                    await widget.profileManager.getStats();
                int? hp;
                int? maxHp;
                int? tempHp;
                int? ac;
                if (stats.isNotEmpty) {
                  hp = stats.first['HP'] as int?;
                  maxHp = stats.first['maxHP'] as int?;
                  tempHp = stats.first['temphp'] as int?;
                  ac = stats.first['AC'] as int?;
                  print(
                      '📊 Loaded character stats - HP: $hp/$maxHp (+${tempHp ?? 0}), AC: $ac');
                } else {
                  print('⚠️ No stats found for character');
                }

                await widget._client!.joinSession(ip, port, selectedCharacter!);

                if (!mounted) return;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientPage(
                        client: widget._client!,
                        playerName: selectedCharacter!.name,
                        isFromLobby: true,
                        playerHP: hp,
                        playerMaxHP: maxHp,
                        playerTempHP: tempHp,
                        playerAC: ac),
                  ),
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
          onPressed: () async {
            if (serverRunning && widget._server != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HostPage(
                    server: widget._server!,
                    sessionName: widget._server!.name,
                    wikiParser: widget.wikiParser,
                  ),
                ),
              );
            } else {
              await _startServer();
            }
          },
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
    if (widget._client == null) {
      widget._client = DnDClient();
    }

    // Only start listening once
    if (!_isListeningForServers) {
      widget._client!.listenForServers();
      _isListeningForServers = true;
    }

    final sessions = widget._client?.discoveredSessions.values.toList() ?? [];

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
                onPressed: () {
                  if (isPlayer && _isListeningForServers) {
                    widget._client?.stopListeningForServers();
                    _isListeningForServers = false;
                  }
                  setState(() {
                    isHosting = false;
                    isPlayer = false;
                  });
                },
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
