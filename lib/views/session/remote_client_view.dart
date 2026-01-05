import 'package:dnd/classes/profile_manager.dart';
import 'package:dnd/classes/remote_client.dart';
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

  @override
  void initState() {
    super.initState();
    widget.client.playerListStream.listen((players) {
      setState(() {
        _combatants = List<Map<String, dynamic>>.from(players);
        _combatants.addAll(widget.client.monstersData);
        _combatants.sort((a, b) =>
          (b['initiative'] as int? ?? 0).compareTo(a['initiative'] as int? ?? 0)
        );
      });
    });
  }

  Future<void> _disconnect() async {
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
      await widget.client.disconnect();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
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
          onPressed: _disconnect,
        ),
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
                        final combatant = _combatants[index];
                        final name = combatant['name'] ?? 'Unknown';
                        final hp = combatant['HP'] ?? 0;
                        final maxHp = combatant['maxHP'] ?? 0;
                        final ac = combatant['AC'] ?? 0;
                        final initiative = combatant['initiative'] ?? 0;
                        final isDM = combatant['isDM'] == true;

                        return Card(
                          color: AppColors.cardColor,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDM ? AppColors.accentPink : AppColors.currentHealth,
                              child: Text(
                                '$initiative',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                color: AppColors.textColorLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'HP: $hp/$maxHp | AC: $ac',
                              style: TextStyle(color: AppColors.textColorDark),
                            ),
                            trailing: isDM
                                ? Icon(Icons.shield, color: AppColors.accentPink)
                                : null,
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
