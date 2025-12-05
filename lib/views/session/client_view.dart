import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/classes/client.dart';
import 'package:dnd/l10n/app_localizations.dart';

class ClientPage extends StatefulWidget {
  final DnDClient client;
  final String playerName;
  final bool isFromLobby;
  final int? playerHP;
  final int? playerMaxHP;
  final int? playerTempHP;
  final int? playerAC;

  const ClientPage({
    super.key,
    required this.client,
    required this.playerName,
    required this.isFromLobby,
    this.playerHP,
    this.playerMaxHP,
    this.playerTempHP,
    this.playerAC,
  });

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  late StreamSubscription _messageSub;
  List<Map<String, dynamic>> _players = [];
  int _currentTurnIndex = 0;

  @override
  void initState() {
    super.initState();

    // Initialize with data already stored in the client
    _players = [
      ...widget.client.playersData,
      ...widget.client.monstersData,
    ];

    // Send player stats to server if available
    if (widget.playerHP != null && widget.playerAC != null) {
      print(
          '🎯 ClientView: Sending initial stats - HP: ${widget.playerHP}/${widget.playerMaxHP}, TempHP: ${widget.playerTempHP}, AC: ${widget.playerAC}');
      widget.client.sendStats({
        'HP': widget.playerHP,
        'maxHP': widget.playerMaxHP,
        'tempHP': widget.playerTempHP ?? 0,
        'AC': widget.playerAC,
      });
    } else {
      print(
          '⚠️ ClientView: Stats not available - HP: ${widget.playerHP}, AC: ${widget.playerAC}');
    }

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

  @override
  void dispose() {
    _messageSub.cancel();
    widget.client.disconnect();
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
                children: [
                  Text(
                    'Session: ${widget.client.sessionName ?? 'Loading...'}',
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                ],
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
                              ? AppColors.currentHealth.withOpacity(0.3)
                              : isCurrentPlayer
                                  ? AppColors.cardColor.withOpacity(0.8)
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
                                  p['isMonster'] == true
                                      ? 'HP: ${p['hp']}/${p['maxHp']} | AC: ${p['ac']}'
                                      : isCurrentPlayer
                                          ? 'HP: ${p['HP'] ?? widget.playerHP ?? '?'}${p['maxHP'] != null || widget.playerMaxHP != null ? '/${p['maxHP'] ?? widget.playerMaxHP}' : ''}${(p['tempHP'] ?? widget.playerTempHP ?? 0) > 0 ? ' (+${p['tempHP'] ?? widget.playerTempHP})' : ''} | AC: ${p['AC'] ?? widget.playerAC ?? '?'}'
                                          : 'HP: ${p['HP'] ?? '?'}${p['maxHP'] != null ? '/${p['maxHP']}' : ''}${(p['tempHP'] ?? 0) > 0 ? ' (+${p['tempHP']})' : ''} | AC: ${p['AC'] ?? '?'}',
                                  style: TextStyle(
                                    color: AppColors.textColorDark,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              'Init: $initiative',
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
