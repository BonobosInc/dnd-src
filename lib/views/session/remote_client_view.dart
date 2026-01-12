import 'package:dnd/classes/profile_manager.dart';
import 'package:dnd/classes/remote_client.dart';
import 'package:dnd/classes/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/l10n/app_localizations.dart';

class RemoteClientView extends StatefulWidget {
  final RemoteClient client;
  final String playerName;
  final bool isDM;
  final ProfileManager profileManager;

  const RemoteClientView({
    super.key,
    required this.client,
    required this.playerName,
    required this.isDM,
    required this.profileManager,
  });

  @override
  State<RemoteClientView> createState() => _RemoteClientViewState();
}

class _RemoteClientViewState extends State<RemoteClientView> {
  List<Map<String, dynamic>> _combatants = [];
  int _currentTurnIndex = 0;
  int? _playerHP;
  int? _playerMaxHP;
  int? _playerTempHP;
  int? _playerAC;

  @override
  void initState() {
    super.initState();

    // Load player stats from database if not DM
    if (!widget.isDM) {
      _loadAndSendStats();
    }

    // Initialize with existing data
    _updateCombatants();

    // Listen to stream for updates
    widget.client.playerListStream.listen((players) {
      _updateCombatants();
    });
  }

  void _updateCombatants() {
    setState(() {
      _combatants = List<Map<String, dynamic>>.from(widget.client.playersData);
      _combatants.addAll(widget.client.monstersData);
      _combatants.sort((a, b) =>
        (b['initiative'] as int? ?? 0).compareTo(a['initiative'] as int? ?? 0)
      );
    });
  }

  Future<void> _loadAndSendStats() async {
    try {
      // Ensure the correct profile is selected
      final matchingProfile = widget.profileManager.profiles.firstWhere(
        (profile) => profile.name == widget.playerName,
        orElse: () => widget.profileManager.profiles.isNotEmpty
            ? widget.profileManager.profiles.first
            : throw Exception('No profiles available'),
      );

      await widget.profileManager.selectProfile(matchingProfile);

      final stats = await widget.profileManager.getStats();
      if (stats.isNotEmpty && mounted) {
        setState(() {
          // Use lowercase column names from the database
          _playerHP = stats.first['currenthp'] as int?;
          _playerMaxHP = stats.first['maxhp'] as int?;
          _playerTempHP = stats.first['temphp'] as int?;
          _playerAC = stats.first['armor'] as int?;
        });

        if (_playerHP != null && _playerAC != null) {
          await widget.client.sendStats({
            'HP': _playerHP,
            'maxHP': _playerMaxHP,
            'tempHP': _playerTempHP ?? 0,
            'AC': _playerAC,
          });
        }
      }
    } catch (e) {
      print('Error loading and sending stats: $e');
    }
  }

  Future<void> _showInitiativeDialog(String playerName, int currentInitiative) async {
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentInitiative.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: Text(
            loc.setInitiativeFor(playerName),
            style: TextStyle(color: AppColors.textColorLight),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(color: AppColors.textColorLight),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.primaryColor,
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.cancel, style: TextStyle(color: AppColors.textColorLight)),
            ),
            ElevatedButton(
              onPressed: () async {
                final value = int.tryParse(controller.text) ?? currentInitiative;
                await widget.client.updateInitiative(playerName, value);
                Navigator.of(context).pop();
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDisconnect() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: Text(
          widget.isDM ? loc.confirmStopHosting : loc.quitSession,
          style: TextStyle(color: AppColors.textColorLight),
        ),
        content: Text(
          widget.isDM ? loc.stopHostingWarning : 'Are you sure you want to leave this session?',
          style: TextStyle(color: AppColors.textColorLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel, style: TextStyle(color: AppColors.textColorLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.isDM ? loc.stopHosting : loc.quitSession),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SessionManager().stopRemoteClient();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isDM ? 'Hosting: ${widget.client.sessionName ?? "Session"}' : widget.client.sessionName ?? 'Session',
              style: TextStyle(color: AppColors.textColorLight),
            ),
            Text(
              'Code: ${widget.client.sessionCode ?? ""}',
              style: TextStyle(
                color: AppColors.textColorLight.withValues(alpha: 0.7),
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textColorLight,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: widget.isDM ? [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textColorLight),
            color: AppColors.cardColor,
            onSelected: (value) async {
              if (value == 'quit') {
                await _confirmDisconnect();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'quit',
                child: Text(loc.stopHosting,
                    style: TextStyle(color: AppColors.warningColor)),
              ),
            ],
          ),
        ] : [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textColorLight),
            color: AppColors.cardColor,
            onSelected: (value) async {
              if (value == 'quit') {
                await _confirmDisconnect();
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
            Text(
              loc.playersAndInitiative,
              style: TextStyle(
                color: AppColors.textColorLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.isDM && _combatants.isNotEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await widget.client.nextTurn();
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(loc.nextTurn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.currentHealth,
                  ),
                ),
              ),
            if (widget.isDM && _combatants.isNotEmpty)
              const SizedBox(height: 12),
            Expanded(
              child: _combatants.isEmpty
                  ? Center(
                      child: Text(
                        loc.noPlayersConnected,
                        style: TextStyle(color: AppColors.textColorDark),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _combatants.length,
                      itemBuilder: (context, index) {
                        final p = _combatants[index];
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
                                  (widget.isDM || isCurrentPlayer)
                                      ? 'HP: ${p['HP'] ?? (isCurrentPlayer ? _playerHP : null) ?? '?'}${p['maxHP'] != null || (isCurrentPlayer && _playerMaxHP != null) ? '/${p['maxHP'] ?? (isCurrentPlayer ? _playerMaxHP : null) ?? '?'}' : ''}${(p['tempHP'] ?? (isCurrentPlayer ? _playerTempHP : 0) ?? 0) > 0 ? ' (+${p['tempHP'] ?? (isCurrentPlayer ? _playerTempHP : 0)})' : ''} | AC: ${p['AC'] ?? (isCurrentPlayer ? _playerAC : null) ?? '?'}'
                                      : '', // Hide HP/AC for other players (not DM or self)
                                  style: TextStyle(
                                    color: AppColors.textColorDark,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            trailing: widget.isDM
                                ? GestureDetector(
                                    onTap: () => _showInitiativeDialog(p['name'], initiative),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.appBarColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            initiative.toString(),
                                            style: TextStyle(
                                              color: AppColors.textColorLight,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.edit,
                                            color: AppColors.textColorDark,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Text(
                                    '${loc.initiativeLabel}$initiative',
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
