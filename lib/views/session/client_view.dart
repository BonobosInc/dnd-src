import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/classes/client.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:dnd/classes/session_manager.dart';
import 'package:dnd/classes/profile_manager.dart';

class ClientPage extends StatefulWidget {
  final DnDClient client;
  final String playerName;
  final bool isFromLobby;
  final ProfileManager profileManager;

  const ClientPage({
    super.key,
    required this.client,
    required this.playerName,
    required this.isFromLobby,
    required this.profileManager,
  });

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  late StreamSubscription _messageSub;
  List<Map<String, dynamic>> _players = [];
  int _currentTurnIndex = 0;
  int? _playerHP;
  int? _playerMaxHP;
  int? _playerTempHP;
  int? _playerAC;

  @override
  void initState() {
    super.initState();

    // Initialize with data already stored in the client
    _players = [
      ...widget.client.playersData,
      ...widget.client.monstersData,
    ];

    // Load and send player stats from database
    _loadAndSendStats();

    _messageSub = widget.client.messages.listen((data) {
      if (!mounted) return;

      print('📨 [ClientPage] Message received: ${data['type']}');

      switch (data['type']) {
        case 'welcome':
          setState(() {
            final players =
                List<Map<String, dynamic>>.from(data['players'] ?? []);
            final monsters =
                List<Map<String, dynamic>>.from(data['monsters'] ?? []);
            _players = [...players, ...monsters];
            // Sort by initiative (highest to lowest)
            _players.sort((a, b) {
              final aInit = a['initiative'] ?? 0;
              final bInit = b['initiative'] ?? 0;
              return bInit.compareTo(aInit);
            });
            _currentTurnIndex = data['currentTurnIndex'] ?? 0;
          });
          print('👋 Welcome update received.');
          break;

        case 'player_joined':
          setState(() {
            final players =
                List<Map<String, dynamic>>.from(data['players'] ?? []);
            final monsters =
                List<Map<String, dynamic>>.from(data['monsters'] ?? []);
            _players = [...players, ...monsters];
            // Sort by initiative (highest to lowest)
            _players.sort((a, b) {
              final aInit = a['initiative'] ?? 0;
              final bInit = b['initiative'] ?? 0;
              return bInit.compareTo(aInit);
            });
            _currentTurnIndex = data['currentTurnIndex'] ?? 0;
          });
          print('🎲 Player joined update.');
          break;

        case 'player_left':
          setState(() {
            final players =
                List<Map<String, dynamic>>.from(data['players'] ?? []);
            final monsters =
                List<Map<String, dynamic>>.from(data['monsters'] ?? []);
            _players = [...players, ...monsters];
            // Sort by initiative (highest to lowest)
            _players.sort((a, b) {
              final aInit = a['initiative'] ?? 0;
              final bInit = b['initiative'] ?? 0;
              return bInit.compareTo(aInit);
            });
            _currentTurnIndex = data['currentTurnIndex'] ?? 0;
          });
          print('👋 Player left update.');
          break;

        case 'initiative_updated':
        case 'combatants_updated':
          setState(() {
            final players =
                List<Map<String, dynamic>>.from(data['players'] ?? []);
            final monsters =
                List<Map<String, dynamic>>.from(data['monsters'] ?? []);
            print(
                '🔄 Client received: ${players.length} players, ${monsters.length} monsters');
            _players = [...players, ...monsters];
            // Sort by initiative (highest to lowest)
            _players.sort((a, b) {
              final aInit = a['initiative'] ?? 0;
              final bInit = b['initiative'] ?? 0;
              return bInit.compareTo(aInit);
            });
            _currentTurnIndex = data['currentTurnIndex'] ?? 0;
            print('🔄 Client now has ${_players.length} total combatants');
          });
          print('🎲 Initiative updated.');
          break;

        default:
          print('📩 Unknown WS message: $data');
      }
    });
  }

  Future<void> _loadAndSendStats() async {
    try {
      print('🔍 ClientView: Loading stats for player ${widget.playerName}');

      // Ensure the correct profile is selected
      final matchingProfile = widget.profileManager.profiles.firstWhere(
        (profile) => profile.name == widget.playerName,
        orElse: () => widget.profileManager.profiles.isNotEmpty
            ? widget.profileManager.profiles.first
            : throw Exception('No profiles available'),
      );

      await widget.profileManager.selectProfile(matchingProfile);
      print('🔍 ClientView: Selected profile: ${matchingProfile.name}');

      final stats = await widget.profileManager.getStats();
      print('🔍 ClientView: Stats query returned ${stats.length} rows');
      if (stats.isNotEmpty) {
        print('🔍 ClientView: First stat row: ${stats.first}');
        setState(() {
          // Use lowercase column names from the database
          _playerHP = stats.first['currenthp'] as int?;
          _playerMaxHP = stats.first['maxhp'] as int?;
          _playerTempHP = stats.first['temphp'] as int?;
          _playerAC = stats.first['armor'] as int?;
        });

        print('🎯 ClientView: Parsed stats - HP: $_playerHP/$_playerMaxHP, TempHP: $_playerTempHP, AC: $_playerAC');

        if (_playerHP != null && _playerAC != null) {
          print('📤 ClientView: Sending stats to server');
          await widget.client.sendStats({
            'HP': _playerHP,
            'maxHP': _playerMaxHP,
            'tempHP': _playerTempHP ?? 0,
            'AC': _playerAC,
          });
        } else {
          print('⚠️ ClientView: HP or AC is null, not sending to server');
        }
      } else {
        print('⚠️ ClientView: No stats found in database');
      }
    } catch (e) {
      print('❌ ClientView: Error loading stats: $e');
    }
  }

  @override
  void dispose() {
    _messageSub.cancel();
    // Don't disconnect here - disconnection is handled at app level in main.dart
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        title: Text(
          loc.sessionTitle(widget.client.sessionName ?? loc.loading),
          style: TextStyle(color: AppColors.textColorLight),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textColorLight,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textColorLight),
            color: AppColors.cardColor,
            onSelected: (value) async {
              if (value == 'quit') {
                await SessionManager().stopClient();
                if (!mounted) return;
                goBacktoHomescreen();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'quit',
                child: Text(loc.quitSession,
                    style: TextStyle(color: AppColors.warningColor)),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
              ),
            ),
            Text(
              loc.playersAndInitiative,
              style: TextStyle(
                color: AppColors.textColorLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _players.isEmpty
                  ? Center(
                      child: Text(
                        loc.noPlayersConnected,
                        style: TextStyle(color: AppColors.textColorDark),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _players.length,
                      itemBuilder: (context, index) {
                        final p = _players[index];
                        final initiative = p['initiative'] ?? 0;
                        final isCurrentPlayer = p['name'] == widget.playerName;
                        final isCurrentTurn = index == _currentTurnIndex;
                        return Card(
                          color: isCurrentTurn
                              ? AppColors.currentHealth.withValues(alpha: 0.3)
                              : isCurrentPlayer
                                  ? AppColors.cardColor.withValues(alpha: 0.8)
                                  : AppColors.cardColor,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: isCurrentTurn
                              ? RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: AppColors.currentHealth,
                                    width: 2,
                                  ),
                                )
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.appBarColor,
                              child: Text(
                                initiative.toString(),
                                style: TextStyle(
                                  color: AppColors.textColorLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                if (p['isMonster'] == true)
                                  Icon(
                                    Icons.pets,
                                    color: AppColors.warningColor,
                                    size: 16,
                                  )
                                else
                                  Icon(
                                    Icons.person,
                                    color: AppColors.currentHealth,
                                    size: 16,
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  p['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: AppColors.textColorLight,
                                    fontWeight: isCurrentPlayer
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCurrentPlayer
                                      ? loc.you
                                      : p['isMonster'] == true
                                          ? loc.monsterNpc
                                          : loc.player,
                                  style: TextStyle(
                                    color: AppColors.textColorDark,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isCurrentPlayer
                                      ? 'HP: ${p['HP'] ?? _playerHP ?? '?'}${p['maxHP'] != null || _playerMaxHP != null ? '/${p['maxHP'] ?? _playerMaxHP}' : ''}${(p['tempHP'] ?? _playerTempHP ?? 0) > 0 ? ' (+${p['tempHP'] ?? _playerTempHP})' : ''} | AC: ${p['AC'] ?? _playerAC ?? '?'}'
                                      : '', // Hide HP/AC for other players and monsters
                                  style: TextStyle(
                                    color: AppColors.textColorDark,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '${loc.initiativeLabel}: $initiative',
                              style: TextStyle(
                                color: AppColors.textColorDark,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
