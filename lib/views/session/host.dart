import 'package:flutter/material.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/classes/server.dart';
import 'package:dnd/classes/wiki_parser.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/views/wiki/creatures_view.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'dart:async';

class HostPage extends StatefulWidget {
  final DnDMulticastServer server;
  final String sessionName;
  final WikiParser? wikiParser;

  const HostPage({
    super.key,
    required this.server,
    required this.sessionName,
    this.wikiParser,
  });

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  bool _stopping = false;
  int _currentTurnIndex = 0;
  Timer? _hpAdjustmentTimer;
  String? _adjustingMonsterName;
  int? _adjustingMonsterHP;
  int _adjustmentAmount = 0;

  @override
  void dispose() {
    _stopContinuousHPAdjustment();
    super.dispose();
  }

  Future<void> _stopHosting() async {
    if (_stopping) return;
    final shouldStop = await _showStopConfirmationDialog();
    if (shouldStop != true) return;
    setState(() => _stopping = true);
    await widget.server.stop();
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pop(context);
  }

  Future<bool?> _showStopConfirmationDialog() {
    final loc = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.confirmStopHosting),
          content: Text(loc.stopHostingWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(loc.stopHosting),
            ),
          ],
        );
      },
    );
  }

  void _showInitiativeDialog(String playerName, int currentInitiative) {
    final loc = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(
      text: currentInitiative.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.setInitiativeFor(playerName)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: loc.initiative,
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () {
                final value =
                    int.tryParse(controller.text) ?? currentInitiative;
                widget.server.updateInitiative(playerName, value);
                Navigator.of(context).pop();
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
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
              loc.hostingSessionTitle(widget.sessionName),
              style: TextStyle(color: AppColors.textColorLight),
            ),
            Text(
              '${widget.server.localIp ?? loc.unknown}:${widget.server.port}',
              style: TextStyle(
                color: AppColors.textColorLight.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textColorLight,
          onPressed: _stopHosting,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.playersAndInitiative,
                style: TextStyle(
                    color: AppColors.textColorLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.server.playerStream,
              builder: (context, snapshot) {
                final totalCombatants = snapshot.data?.length ?? 0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: totalCombatants > 0
                          ? () {
                              widget.server.nextTurn();
                              setState(() {
                                _currentTurnIndex =
                                    (_currentTurnIndex + 1) % totalCombatants;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(loc.nextTurn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.currentHealth,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.server.playerStream,
                builder: (context, snapshot) {
                  var players = snapshot.data ?? [];
                  if (players.isEmpty) {
                    return Center(
                      child: Text(
                        loc.noPlayersConnected,
                        style: TextStyle(color: AppColors.textColorDark),
                      ),
                    );
                  }
                  // Players are already sorted by the server
                  return ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final p = players[index];
                      final currentInitiative = p['initiative'] ?? 0;
                      final isCurrentTurn = index == _currentTurnIndex;
                      return Card(
                        color: isCurrentTurn
                            ? AppColors.currentHealth.withValues(alpha: 0.2)
                            : AppColors.cardColor,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: isCurrentTurn
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: AppColors.currentHealth,
                                  width: 3,
                                ),
                              )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      if (p['isMonster'] == true)
                                        Icon(
                                          Icons.pets,
                                          color: AppColors.warningColor,
                                          size: 18,
                                        )
                                      else
                                        Icon(
                                          Icons.person,
                                          color: AppColors.currentHealth,
                                          size: 18,
                                        ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: p['isMonster'] == true
                                            ? () => _showMonsterDetails(p)
                                            : null,
                                        child: Text(
                                          p['name'] ?? 'Unknown',
                                          style: TextStyle(
                                            color: AppColors.textColorLight,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            decoration: p['isMonster'] == true
                                                ? TextDecoration.underline
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (p['isMonster'] == true)
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: AppColors.warningColor,
                                          iconSize: 20,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            widget.server
                                                .removeMonster(p['name']);
                                          },
                                        ),
                                      if (p['isMonster'] == true)
                                        const SizedBox(width: 8),
                                      Text(
                                        loc.initiativeLabel,
                                        style: TextStyle(
                                          color: AppColors.textColorDark,
                                          fontSize: 14,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          _showInitiativeDialog(
                                              p['name'], currentInitiative);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.appBarColor,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                currentInitiative.toString(),
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textColorLight,
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
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Builder(builder: (context) {
                                if (p['isMonster'] != true) {
                                  print(
                                      '🏥 Host displaying player ${p['name']}: HP=${p['HP']}, maxHP=${p['maxHP']}, tempHP=${p['tempHP']}, AC=${p['AC']}');
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['isMonster'] == true
                                          ? 'HP: ${p['hp']}/${p['maxHp']} | AC: ${p['ac']}'
                                          : 'HP: ${p['HP'] ?? '?'}${p['maxHP'] != null ? '/${p['maxHP']}' : ''}${(p['tempHP'] ?? 0) > 0 ? ' (+${p['tempHP']})' : ''} | AC: ${p['AC'] ?? '?'}',
                                      style: TextStyle(
                                          color: AppColors.textColorDark,
                                          fontSize: 12),
                                    ),
                                    if (p['isMonster'] == true) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildHPButton(
                                            icon: Icons.remove,
                                            onPressed: () => _adjustMonsterHP(p['name'], p['hp'], p['maxHp'], -1),
                                            onLongPressStart: (_) => _startContinuousHPAdjustment(p['name'], p['hp'], p['maxHp'], -1),
                                            onLongPressEnd: (_) => _stopContinuousHPAdjustment(),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildHPButton(
                                            icon: Icons.add,
                                            onPressed: () => _adjustMonsterHP(p['name'], p['hp'], p['maxHp'], 1),
                                            onLongPressStart: (_) => _startContinuousHPAdjustment(p['name'], p['hp'], p['maxHp'], 1),
                                            onLongPressEnd: (_) => _stopContinuousHPAdjustment(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.wikiParser != null
          ? FloatingActionButton(
              onPressed: _addMonster,
              tooltip: loc.addMonsterNpc,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _addMonster() async {
    if (widget.wikiParser == null) return;

    final creatures = await widget.wikiParser!.creatures;
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllCreaturesPage(
          creatures: creatures,
          importCreature: true,
        ),
      ),
    );

    if (result != null) {
      if (result is Creature) {
        // Single new creature
        _addCreatureToInitiative(result);
      } else if (result is List<Creature>) {
        // Multiple selected creatures
        for (final creature in result) {
          _addCreatureToInitiative(creature);
        }
      }
    }
  }

  void _addCreatureToInitiative(Creature creature) {
    widget.server.addMonster({
      'name': creature.name,
      'initiative': 0,
      'isMonster': true,
      'hp': creature.currentHP,
      'maxHp': creature.maxHP,
      'ac': creature.ac,
      // Store full creature data for later viewing
      'size': creature.size,
      'type': creature.type,
      'alignment': creature.alignment,
      'speed': creature.speed,
      'str': creature.str,
      'dex': creature.dex,
      'con': creature.con,
      'int': creature.intScore,
      'wis': creature.wis,
      'cha': creature.cha,
      'saves': creature.saves,
      'skills': creature.skills,
      'resistances': creature.resistances,
      'vulnerabilities': creature.vulnerabilities,
      'immunities': creature.immunities,
      'conditionImmunities': creature.conditionImmunities,
      'senses': creature.senses,
      'languages': creature.languages,
      'cr': creature.cr,
      'traits': creature.traits.map((t) => {'name': t.name, 'text': t.description}).toList(),
      'actions': creature.actions.map((a) => {'name': a.name, 'text': a.description}).toList(),
      'legendaryActions': creature.legendaryActions.map((l) => {'name': l.name, 'text': l.description}).toList(),
    });
  }

  void _showMonsterDetails(Map<String, dynamic> monster) {
    // Convert monster map back to Creature object
    final creature = Creature(
      name: monster['name'] ?? 'Unknown',
      size: monster['size'] ?? '',
      type: monster['type'] ?? '',
      alignment: monster['alignment'] ?? '',
      ac: monster['ac'] ?? 0,
      currentHP: monster['hp'] ?? 0,
      maxHP: monster['maxHp'] ?? 0,
      speed: monster['speed'] ?? '',
      str: monster['str'] ?? 0,
      dex: monster['dex'] ?? 0,
      con: monster['con'] ?? 0,
      intScore: monster['int'] ?? 0,
      wis: monster['wis'] ?? 0,
      cha: monster['cha'] ?? 0,
      saves: monster['saves'] ?? '',
      skills: monster['skills'] ?? '',
      resistances: monster['resistances'] ?? '',
      vulnerabilities: monster['vulnerabilities'] ?? '',
      immunities: monster['immunities'] ?? '',
      conditionImmunities: monster['conditionImmunities'] ?? '',
      senses: monster['senses'] ?? '',
      languages: monster['languages'] ?? '',
      cr: monster['cr'] ?? '',
      traits: (monster['traits'] as List?)?.map((t) => Trait(name: t['name'] ?? '', description: t['text'] ?? '')).toList() ?? [],
      actions: (monster['actions'] as List?)?.map((a) => CAction(name: a['name'] ?? '', description: a['text'] ?? '')).toList() ?? [],
      legendaryActions: (monster['legendaryActions'] as List?)?.map((l) => Legendary(name: l['name'] ?? '', description: l['text'] ?? '')).toList() ?? [],
    );

    // Show custom dialog with edit options
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: Row(
            children: [
              Icon(Icons.dangerous, color: AppColors.warningColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  monster['name'] ?? 'Unknown',
                  style: TextStyle(color: AppColors.textColorLight),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: Text(loc.viewFullDetails),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatureDetailPage(
                        creature: creature,
                        importCreature: false,
                        statsMenu: false,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text('${loc.editName} (${monster['name']})'),
                onTap: () {
                  Navigator.pop(context);
                  _editMonsterName(monster);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: Text('${loc.editHp} (${monster['hp']}/${monster['maxHp']})'),
                onTap: () {
                  Navigator.pop(context);
                  _editMonsterHP(monster);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shield),
                title: Text('${loc.editAc} (${monster['ac']})'),
                onTap: () {
                  Navigator.pop(context);
                  _editMonsterAC(monster);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.close),
            ),
          ],
        );
      },
    );
  }

  void _editMonsterName(Map<String, dynamic> monster) {
    final loc = AppLocalizations.of(context)!;
    final TextEditingController nameController = TextEditingController(
      text: monster['name'],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.editNameFor(monster['name'])),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: loc.name,
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != monster['name']) {
                  widget.server.updateMonsterName(monster['name'], newName);
                  Navigator.pop(context);
                  setState(() {});
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  void _editMonsterHP(Map<String, dynamic> monster) {
    final loc = AppLocalizations.of(context)!;
    final TextEditingController hpController = TextEditingController(
      text: monster['hp'].toString(),
    );
    final TextEditingController maxHpController = TextEditingController(
      text: monster['maxHp'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.editHpFor(monster['name'])),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.currenthp,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxHpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.maxhp,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () {
                final hp = int.tryParse(hpController.text) ?? monster['hp'];
                final maxHp = int.tryParse(maxHpController.text) ?? monster['maxHp'];
                widget.server.updateMonsterStats(monster['name'], hp: hp, maxHp: maxHp);
                Navigator.pop(context);
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  void _editMonsterAC(Map<String, dynamic> monster) {
    final loc = AppLocalizations.of(context)!;
    final TextEditingController acController = TextEditingController(
      text: monster['ac'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.editAcFor(monster['name'])),
          content: TextField(
            controller: acController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: loc.armorClass,
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () {
                final ac = int.tryParse(acController.text) ?? monster['ac'];
                widget.server.updateMonsterStats(monster['name'], ac: ac);
                Navigator.pop(context);
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHPButton({
    required IconData icon,
    required VoidCallback onPressed,
    required void Function(LongPressStartDetails) onLongPressStart,
    required void Function(LongPressEndDetails) onLongPressEnd,
  }) {
    return GestureDetector(
      onTap: onPressed,
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.appBarColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: AppColors.textColorLight,
          size: 18,
        ),
      ),
    );
  }

  void _adjustMonsterHP(String monsterName, int currentHP, int maxHP, int adjustment) {
    final newHP = (currentHP + adjustment).clamp(0, maxHP);
    widget.server.updateMonsterStats(monsterName, hp: newHP);
  }

  void _startContinuousHPAdjustment(String monsterName, int currentHP, int maxHP, int adjustment) {
    _adjustingMonsterName = monsterName;
    _adjustingMonsterHP = currentHP;
    _adjustmentAmount = adjustment;

    // Initial adjustment
    _adjustMonsterHP(monsterName, currentHP, maxHP, adjustment);

    // Start continuous adjustment after a delay
    _hpAdjustmentTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_adjustingMonsterHP != null) {
        _adjustingMonsterHP = _adjustingMonsterHP! + _adjustmentAmount;
        _adjustMonsterHP(_adjustingMonsterName!, _adjustingMonsterHP!, maxHP, 0);
      }
    });
  }

  void _stopContinuousHPAdjustment() {
    _hpAdjustmentTimer?.cancel();
    _hpAdjustmentTimer = null;
    _adjustingMonsterName = null;
    _adjustingMonsterHP = null;
    _adjustmentAmount = 0;
  }
}

