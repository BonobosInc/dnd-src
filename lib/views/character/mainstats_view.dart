import 'dart:async';

import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/classes/wiki_parser.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/views/wiki/creatures_view.dart';
import 'package:flutter/material.dart';
import 'package:dnd/classes/profile_manager.dart';
import 'package:dnd/configs/defines.dart';
import 'package:dnd/l10n/app_localizations.dart';

class MainStatsPage extends StatefulWidget {
  final ProfileManager profileManager;
  final WikiParser wikiParser;
  final VoidCallback? onStatsChanged;

  const MainStatsPage(
      {super.key, required this.profileManager, required this.wikiParser, this.onStatsChanged});

  @override
  MainStatsPageState createState() => MainStatsPageState();
}

class MainStatsPageState extends State<MainStatsPage> {
  int currentHP = 0;
  int maxHP = 0;
  int tempHP = 0;

  int currentHitDice = 0;
  int maxHitDice = 0;
  String healFactor = '';

  int armor = 0;
  int inspiration = 0;
  int proficiencyBonus = 0;
  int initiative = 0;
  int initiative_bonus = 0;
  String movement = '0m';

  Timer? _timer;

  List<Tracker> trackers = [];

  List<Creature> creatures = [];

  List<Condition> statusEffects = [];
  List<String> getConditionOptions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      loc.conditionBlind,
      loc.conditionRestrained,
      loc.conditionStunned,
      loc.conditionParalyzed,
      loc.conditionExhaustion,
      loc.conditionPoisoned,
      loc.conditionFrightened,
      loc.conditionGrappled,
      loc.conditionPetrified,
      loc.conditionCharmed,
      loc.conditionDeafened,
      loc.conditionUnconscious,
      loc.conditionProne,
      loc.conditionIncapacitated,
      loc.conditionInvisible,
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
    _loadTrackers();
    _loadConditions();
    _fetchCreatures();
  }

  Future<void> _loadCharacterData() async {
    List<Map<String, dynamic>> result = await widget.profileManager.getStats();

    if (result.isNotEmpty) {
      Map<String, dynamic> characterData = result.first;
      setState(() {
        currentHP = characterData[Defines.statCurrentHP];
        maxHP = characterData[Defines.statMaxHP];
        tempHP = characterData[Defines.statTempHP];
        armor = characterData[Defines.statArmor];
        inspiration = characterData[Defines.statInspiration];
        proficiencyBonus = _calculateProficiencyBonus(
            int.tryParse(characterData[Defines.statLevel].toString()) ?? 1);
        initiative = (((characterData[Defines.statDEX] is int
                        ? characterData[Defines.statDEX]
                        : int.tryParse(
                                characterData[Defines.statDEX].toString()) ??
                            10) -
                    10) /
                2)
            .floor();
        initiative_bonus = characterData[Defines.statInitiativeBonus] ?? 0;
        movement = characterData[Defines.statMovement].toString();
        currentHitDice = characterData[Defines.statCurrentHitDice];
        maxHitDice = characterData[Defines.statMaxHitDice];
        healFactor = characterData[Defines.statHitDiceFactor];
      });
    }
    await widget.profileManager.updateStats(
        field: Defines.statProficiencyBonus, value: proficiencyBonus);
    await widget.profileManager
        .updateStats(field: Defines.statInitiative, value: initiative);
  }

  void refreshContent() {
    _loadCharacterData();
    _loadTrackers();
    _loadConditions();
    _fetchCreatures();
  }

  int _calculateProficiencyBonus(int level) {
    if (level >= 17) return 6;
    if (level >= 13) return 5;
    if (level >= 9) return 4;
    if (level >= 5) return 3;
    return 2;
  }

  Future<void> _loadConditions() async {
    List<Map<String, dynamic>> result =
        await widget.profileManager.getConditions();
    setState(() {
      statusEffects.clear();
      for (var item in result) {
        statusEffects
            .add(Condition(condition: item['condition'], uuid: item['ID']));
      }
    });
  }

  Future<void> _loadTrackers() async {
    List<Map<String, dynamic>> result =
        await widget.profileManager.getTracker();
    setState(() {
      trackers.clear();
      for (var item in result) {
        trackers.add(Tracker(
            tracker: item['trackername'],
            uuid: item['ID'],
            value: item['value'],
            max: item['max'],
            type: item['type'] ?? 'Option 1'));
      }
    });
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      keyboardType: keyboardType,
    );
  }

  void _startIncrementing() {
    _incrementHP();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _incrementHP();
    });
  }

  void _startDecrementing() {
    _decrementHP();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _decrementHP();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _incrementHP() {
    setState(() {
      if (tempHP > 0) {
        currentHP = (currentHP + 1).clamp(0, maxHP);
        _updateStat(Defines.statCurrentHP, currentHP);
      } else {
        if (currentHP < maxHP) {
          currentHP = (currentHP + 1).clamp(0, maxHP);
          _updateStat(Defines.statCurrentHP, currentHP);
        }
      }
    });
    widget.onStatsChanged?.call();
  }

  void _decrementHP() {
    setState(() {
      if (tempHP > 0) {
        tempHP = (tempHP - 1).clamp(0, maxHP);
        _updateStat(Defines.statTempHP, tempHP);
      } else {
        currentHP = (currentHP - 1).clamp(0, maxHP);
        _updateStat(Defines.statCurrentHP, currentHP);
      }
    });
    widget.onStatsChanged?.call();
  }

  void _startIncrementingC(int index) {
    _incrementCreatureHP(index);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _incrementCreatureHP(index);
    });
  }

  void _startDecrementingC(int index) {
    _decrementCreatureHP(index);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _decrementCreatureHP(index);
    });
  }

  void _incrementCreatureHP(int index) {
    setState(() {
      if (creatures[index].currentHP < creatures[index].maxHP) {
        creatures[index].currentHP =
            (creatures[index].currentHP + 1).clamp(0, creatures[index].maxHP);
        _updateCreatureHP(index);
      }
    });
  }

  void _decrementCreatureHP(int index) {
    setState(() {
      if (creatures[index].currentHP > 0) {
        creatures[index].currentHP =
            (creatures[index].currentHP - 1).clamp(0, creatures[index].maxHP);
        _updateCreatureHP(index);
      }
    });
  }

  Future<void> _updateCreatureHP(int index) async {
    await widget.profileManager.updateCreature(creatures[index]);
  }

  Future<void> _updateStat(String field, dynamic value) async {
    await widget.profileManager.updateStats(field: field, value: value);
  }

  Future<void> _showEditStatDialog(
      String statName, String field, dynamic currentValue,
      {bool isCount = false}) async {
    final loc = AppLocalizations.of(context)!;
    dynamic newValue = currentValue;

    TextEditingController controller =
        TextEditingController(text: currentValue.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(statName),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isCount
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(field == Defines.statInitiativeBonus
                                ? '${loc.bonus}:'
                                : '${loc.value}:'),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      newValue--;
                                    });
                                  },
                                ),
                                Text('$newValue'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      newValue++;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        )
                      : _buildTextField(
                          label: "",
                          controller: controller,
                          onChanged: (value) {
                            newValue = value;
                          },
                          keyboardType: field == Defines.statMovement
                              ? TextInputType.text
                              : TextInputType.number,
                        ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.abort),
                ),
                TextButton(
                  onPressed: () async {
                    await _updateStat(field, newValue);

                    setState(() {
                      if (field == Defines.statArmor) {
                        armor = int.tryParse(newValue.toString())!;
                      }
                      if (field == Defines.statInspiration) {
                        inspiration = int.tryParse(newValue.toString())!;
                      }
                      if (field == Defines.statProficiencyBonus) {
                        proficiencyBonus = int.tryParse(newValue.toString())!;
                      }
                      if (field == Defines.statInitiativeBonus) {
                        initiative_bonus = int.tryParse(newValue.toString())!;
                      }
                      if (field == Defines.statMovement) {
                        movement = newValue;
                      }
                    });

                    await _loadCharacterData();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(loc.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCreatureHPDialog(int index) {
    final loc = AppLocalizations.of(context)!;
    TextEditingController hpController = TextEditingController(
      text: creatures[index].currentHP.toString(),
    );
    TextEditingController maxHpController = TextEditingController(
      text: creatures[index].maxHP.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("${loc.hpfor} ${creatures[index].name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                label: loc.currenthp,
                controller: hpController,
                onChanged: (value) {},
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                label: loc.maxhp,
                controller: maxHpController,
                onChanged: (value) {},
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.abort),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  int newHP = int.tryParse(hpController.text) ??
                      creatures[index].currentHP;
                  int newMaxHP = int.tryParse(maxHpController.text) ??
                      creatures[index].maxHP;

                  creatures[index].currentHP = newHP.clamp(0, newMaxHP);
                  creatures[index].maxHP = newMaxHP.clamp(0, 9999);

                  _updateCreatureHP(index);
                });
                Navigator.of(context).pop();
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditHpDialog() async {
    final loc = AppLocalizations.of(context)!;
    int newCurrentHP = currentHP;
    int newMaxHP = maxHP;
    int newTempHP = tempHP;

    TextEditingController currentHpController =
        TextEditingController(text: currentHP.toString());
    TextEditingController maxHpController =
        TextEditingController(text: maxHP.toString());
    TextEditingController tempHpController =
        TextEditingController(text: tempHP.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("HP"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                  label: loc.currenthp,
                  controller: currentHpController,
                  onChanged: (value) {
                    newCurrentHP = int.tryParse(value) ?? currentHP;
                  },
                  keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              _buildTextField(
                  label: loc.maxhp,
                  controller: maxHpController,
                  onChanged: (value) {
                    newMaxHP = int.tryParse(value) ?? maxHP;
                  },
                  keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              _buildTextField(
                  label: loc.temphp,
                  controller: tempHpController,
                  onChanged: (value) {
                    newTempHP = int.tryParse(value) ?? tempHP;
                  },
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.abort),
            ),
            TextButton(
              onPressed: () async {
                newCurrentHP = newCurrentHP.clamp(0, newMaxHP);
                newTempHP = newTempHP.clamp(0, newMaxHP);

                await _updateStat(Defines.statCurrentHP, newCurrentHP);
                await _updateStat(Defines.statMaxHP, newMaxHP);
                await _updateStat(Defines.statTempHP, newTempHP);

                setState(() {
                  currentHP = newCurrentHP;
                  maxHP = newMaxHP;
                  tempHP = newTempHP;
                });

                widget.onStatsChanged?.call();

                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNewTracker() async {
    final loc = AppLocalizations.of(context)!;
    String newTrackerName = '';
    int newTrackerValue = 0;
    int newTrackerMaxValue = 0;
    String newTrackerType = 'never';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(loc.addtracker),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    label: loc.tracker,
                    controller: TextEditingController(text: newTrackerName),
                    onChanged: (value) {
                      newTrackerName = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: newTrackerType,
                    items: [
                      DropdownMenuItem(value: 'never', child: Text(loc.never)),
                      DropdownMenuItem(
                          value: 'long', child: Text(loc.longrest)),
                      DropdownMenuItem(
                          value: 'short', child: Text(loc.shortrest)),
                    ],
                    decoration: InputDecoration(
                      labelText: loc.reset,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        newTrackerType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${loc.currentvalue}:'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (newTrackerValue > 0) {
                                  newTrackerValue--;
                                }
                              });
                            },
                          ),
                          Text('$newTrackerValue'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                newTrackerValue++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${loc.maximumvalue}:'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (newTrackerMaxValue > 0) {
                                  newTrackerMaxValue--;
                                }
                              });
                            },
                          ),
                          Text('$newTrackerMaxValue'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                newTrackerMaxValue++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.abort),
                ),
                TextButton(
                  onPressed: () async {
                    if (newTrackerName.isNotEmpty) {
                      await widget.profileManager.addTracker(
                        tracker: newTrackerName,
                        value: newTrackerValue,
                        max: newTrackerMaxValue,
                        type: newTrackerType,
                      );
                      _loadTrackers();
                      if (context.mounted) Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(loc.entertrackername)),
                      );
                    }
                  },
                  child: Text(loc.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editTracker(Tracker tracker) async {
    final loc = AppLocalizations.of(context)!;
    String editedTrackerName = tracker.tracker;
    int editedValue = tracker.value ?? 0;
    int editedMaxValue = tracker.max ?? 0;
    String editedTrackerType = ['never', 'long', 'short'].contains(tracker.type)
        ? tracker.type!
        : 'never';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(tracker.tracker),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    label: loc.trackername,
                    controller: TextEditingController(text: editedTrackerName),
                    onChanged: (value) {
                      editedTrackerName = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: editedTrackerType,
                    items: [
                      DropdownMenuItem(value: 'never', child: Text(loc.never)),
                      DropdownMenuItem(value: 'long', child: Text(loc.longrest)),
                      DropdownMenuItem(value: 'short', child: Text(loc.shortrest)),
                    ],
                    decoration: InputDecoration(
                      labelText: loc.reset,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        editedTrackerType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${loc.currentvalue}:'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (editedValue > 0) editedValue--;
                              });
                            },
                          ),
                          Text('$editedValue'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                editedValue++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${loc.maximumvalue}:'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (editedMaxValue > 0) editedMaxValue--;
                              });
                            },
                          ),
                          Text('$editedMaxValue'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                editedMaxValue++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.abort),
                ),
                TextButton(
                  onPressed: () async {
                    await widget.profileManager.updateTracker(
                      uuid: tracker.uuid,
                      tracker: editedTrackerName,
                      value: editedValue,
                      max: editedMaxValue,
                      type: editedTrackerType,
                    );
                    _loadTrackers();

                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(loc.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addCondition() async {
    final loc = AppLocalizations.of(context)!;
    String? selectedCondition;
    int? newConditionUUID;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(loc.addcondition),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCondition,
                    items: getConditionOptions(context).map((condition) {
                      return DropdownMenuItem<String>(
                        value: condition,
                        child: Text(condition),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: loc.addcondition,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedCondition = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.abort),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedCondition != null &&
                        selectedCondition!.isNotEmpty) {
                      Condition newCondition = Condition(
                        condition: selectedCondition!,
                        uuid: newConditionUUID,
                      );
                      await widget.profileManager
                          .addCondition(condition: newCondition.condition);
                      _loadConditions();
                      if (context.mounted) Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(loc.choosecondition)),
                      );
                    }
                  },
                  child: Text(loc.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editCondition(Condition condition) async {
    final loc = AppLocalizations.of(context)!;
    String? selectedCondition = condition.condition;
    int? conditionUUID = condition.uuid;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(loc.editcondition),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCondition,
                    items: getConditionOptions(context).map((condition) {
                      return DropdownMenuItem<String>(
                        value: condition,
                        child: Text(condition),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: loc.editcondition,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedCondition = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.abort),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedCondition != null &&
                        selectedCondition!.isNotEmpty) {
                      Condition updatedCondition = Condition(
                        condition: selectedCondition!,
                        uuid: conditionUUID,
                      );
                      await widget.profileManager.updateCondition(
                        uuid: conditionUUID,
                        condition: updatedCondition.condition,
                      );
                      _loadConditions();
                      if (context.mounted) Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.choosecondition),
                        ),
                      );
                    }
                  },
                  child: Text(loc.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _removeCondition(int? conditionID) async {
    await widget.profileManager.removeCondition(conditionID!);
    _loadConditions();
  }

  void _addCreature() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllCreaturesPage(
          importCreature: true,
          creatures: widget.wikiParser.creatures,
        ),
      ),
    );

    if (result != null) {
      if (result is Creature) {
        _addCreatureToList(result);
      } else if (result is List<Creature>) {
        for (var creature in result) {
          _addCreatureToList(creature);
        }
      }
    }
  }

  void _editCreature(Creature creature) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatureDetailPage(
          creature: creature,
          statsMenu: true,
        ),
      ),
    );

    if (result != null) {
      if (result is Creature) {
        _updateCreatureToList(result);
      } else if (result is List<Creature>) {
        for (var creature in result) {
          _updateCreatureToList(creature);
        }
      }
    }
  }

  void _updateCreatureToList(Creature creature) {
    widget.profileManager.updateCreature(creature).then((_) {
      _fetchCreatures();
    });
  }

  void _addCreatureToList(Creature creature) {
    widget.profileManager.addCreature(creature).then((_) {
      _fetchCreatures();
    });
  }

  Future<void> _fetchCreatures() async {
    List<Creature> fetchedCreatures =
        await widget.profileManager.getCreatures();

    setState(() {
      creatures.clear();
      for (var creature in fetchedCreatures) {
        creatures.add(creature);
      }

      creatures.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<void> _showEditHitDiceDialog() async {
    final loc = AppLocalizations.of(context)!;
    int newCurrentHitDice = currentHitDice;
    int newMaxHitDice = maxHitDice;
    String newHealFactor = healFactor;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(loc.hitdice),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    label: loc.healfactor,
                    controller: TextEditingController(text: healFactor),
                    onChanged: (value) {
                      newHealFactor = value;
                    },
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${loc.currenthitdice}:'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (newCurrentHitDice > 0) newCurrentHitDice--;
                              });
                            },
                          ),
                          Text('$newCurrentHitDice'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                if (newCurrentHitDice < newMaxHitDice) {
                                  newCurrentHitDice++;
                                } else {
                                  newCurrentHitDice = newMaxHitDice;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${loc.maxhitdice}:'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (newMaxHitDice > 0) newMaxHitDice--;
                              });
                            },
                          ),
                          Text('$newMaxHitDice'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                newMaxHitDice++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.abort),
                ),
                TextButton(
                  onPressed: () async {
                    newCurrentHitDice =
                        newCurrentHitDice.clamp(0, newMaxHitDice);

                    await _updateStat(
                        Defines.statCurrentHitDice, newCurrentHitDice);
                    await _updateStat(Defines.statMaxHitDice, newMaxHitDice);
                    await _updateStat(Defines.statHitDiceFactor, newHealFactor);

                    setState(() {
                      currentHitDice = newCurrentHitDice;
                      maxHitDice = newMaxHitDice;
                      healFactor = newHealFactor;
                      _loadCharacterData();
                    });

                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(loc.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _removeTracker(int? trackerID) async {
    await widget.profileManager.removeTracker(trackerID!);
    _loadTrackers();
  }

  Future<void> _removeCreature(int? creatureID) async {
    await widget.profileManager.removeCreature(creatureID!);
    _fetchCreatures();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: LayoutBuilder(builder: (context, constraints) {
      final loc = AppLocalizations.of(context)!;
      final double screenWidth = constraints.maxWidth;

      final double healthBarWidth = screenWidth - 32;
      final double currentHPWidth =
          maxHP > 0 ? (currentHP / maxHP) * healthBarWidth : 0;
      final double tempHPWidth =
          maxHP > 0 ? (tempHP / maxHP) * healthBarWidth : 0;

      int itemsPerRow;
      double itemWidth;

      if (screenWidth >= 800) {
        itemsPerRow = 5;
        itemWidth = (screenWidth - 64) / itemsPerRow;
      } else if (screenWidth >= 600) {
        itemsPerRow = 4;
        itemWidth = (screenWidth - 64) / itemsPerRow;
      } else if (screenWidth >= 400) {
        itemsPerRow = 3;
        itemWidth = (screenWidth - 32) / itemsPerRow;
      } else {
        itemsPerRow = 2;
        itemWidth = (screenWidth - 32) / itemsPerRow;
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.hp,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Divider(color: AppColors.textColorLight, thickness: 1.5),
            Row(
              children: [
                GestureDetector(
                  onTap: _showEditHpDialog,
                  child: Text(
                    tempHP > 0
                        ? '$currentHP/$maxHP + $tempHP Temp'
                        : '$currentHP/$maxHP',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onLongPressStart: (_) => _startDecrementing(),
                  onLongPressEnd: (_) => _stopTimer(),
                  child: IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _decrementHP,
                  ),
                ),
                GestureDetector(
                  onLongPressStart: (_) => _startIncrementing(),
                  onLongPressEnd: (_) => _stopTimer(),
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _incrementHP,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showEditHpDialog,
              child: Stack(
                children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.missingHealth,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    child: Container(
                      height: 20,
                      width: currentHPWidth,
                      decoration: BoxDecoration(
                        color: AppColors.currentHealth,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(5),
                          bottomLeft: const Radius.circular(5),
                          topRight: (currentHP == maxHP)
                              ? const Radius.circular(5)
                              : Radius.zero,
                          bottomRight: (currentHP == maxHP)
                              ? const Radius.circular(5)
                              : Radius.zero,
                        ),
                      ),
                    ),
                  ),
                  if (tempHP > 0)
                    Positioned(
                      left: 0,
                      child: Container(
                        height: 20,
                        width: tempHPWidth,
                        decoration: BoxDecoration(
                          color: AppColors.tempHealth,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(5),
                            bottomLeft: const Radius.circular(5),
                            topRight: (tempHP == maxHP)
                                ? const Radius.circular(5)
                                : Radius.zero,
                            bottomRight: (tempHP == maxHP)
                                ? const Radius.circular(5)
                                : Radius.zero,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Stats Section
            Text(
              loc.statistic,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Divider(color: AppColors.textColorLight, thickness: 1.5),
            const SizedBox(height: 8),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(loc.ac, armor, Defines.statArmor,
                        isCount: true),
                    _buildStatCard(
                        loc.inspiration, inspiration, Defines.statInspiration,
                        isCount: true),
                    _buildStatCard(loc.proficiencyBonus, proficiencyBonus,
                        Defines.statProficiencyBonus,
                        isCount: true, isClickable: false),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                        loc.initiative, (initiative + initiative_bonus), Defines.statInitiativeBonus,
                        isCount: true),
                    _buildStatCard(
                        loc.movement, movement, Defines.statMovement),
                    _buildEditHitDiceCard(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Status Effects Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.statuseffects,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addCondition,
                ),
              ],
            ),
            Divider(color: AppColors.textColorLight, thickness: 1.5),
            Column(
              children: [
                for (int i = 0; i < statusEffects.length; i += itemsPerRow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (int j = i;
                              j < i + itemsPerRow && j < statusEffects.length;
                              j++)
                            SizedBox(
                              width: itemWidth,
                              child: GestureDetector(
                                onTap: () {
                                  _editCondition(statusEffects[j]);
                                },
                                onLongPress: () {
                                  _showDeleteConfirmationDialogCondition(
                                      statusEffects[j]);
                                },
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 50,
                                      child: Card(
                                        color: AppColors.cardColor,
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                            child: Text(
                                              statusEffects[j].condition,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 25),

            // Trackers Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.tracker,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addNewTracker,
                ),
              ],
            ),
            Divider(color: AppColors.textColorLight, thickness: 1.5),
            Column(
              children: [
                for (int i = 0; i < trackers.length; i += itemsPerRow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (int j = i;
                              j < i + itemsPerRow && j < trackers.length;
                              j++)
                            SizedBox(
                              width: itemWidth,
                              child: GestureDetector(
                                onTap: () {
                                  _editTracker(trackers[j]);
                                },
                                onLongPress: () {
                                  _showDeleteConfirmationDialog(trackers[j]);
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      trackers[j].tracker,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(
                                      width: itemWidth,
                                      child: Card(
                                        color: AppColors.cardColor,
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                trackers[j].value.toString(),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Creatures Section
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.companion,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addCreature,
                ),
              ],
            ),
            Divider(color: AppColors.textColorLight, thickness: 1.5),
            Column(
              children: [
                for (int i = 0; i < creatures.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: GestureDetector(
                      onLongPress: () {
                        _showDeleteConfirmationDialogC(creatures[i]);
                      },
                      onTap: () {
                        _editCreature(creatures[i]);
                      },
                      child: Card(
                        color: AppColors.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${creatures[i].name} ${creatures[i].currentHP} / ${creatures[i].maxHP}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onLongPressStart: (_) =>
                                            _startDecrementingC(i),
                                        onLongPressEnd: (_) => _stopTimer(),
                                        child: IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            _decrementCreatureHP(i);
                                          },
                                        ),
                                      ),
                                      GestureDetector(
                                        onLongPressStart: (_) =>
                                            _startIncrementingC(i),
                                        onLongPressEnd: (_) => _stopTimer(),
                                        child: IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            _incrementCreatureHP(i);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  _showEditCreatureHPDialog(i);
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    double cardWidth = constraints.maxWidth;
                                    double greenBarWidth = 0;

                                    if (creatures[i].maxHP > 0) {
                                      greenBarWidth = (creatures[i].currentHP /
                                              creatures[i].maxHP) *
                                          cardWidth;
                                      greenBarWidth =
                                          greenBarWidth.clamp(0.0, cardWidth);
                                    }

                                    return Stack(
                                      children: [
                                        Container(
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF581B10),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          child: Container(
                                            height: 20,
                                            width: greenBarWidth,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1B6533),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      );
    }));
  }

  Widget _buildStatCard(
    String name,
    dynamic value,
    dynamic statType, {
    bool isCount = false,
    bool isClickable = true,
  }) {
    Widget cardContent = Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          height: 50,
          child: Card(
            color: AppColors.cardColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Center(
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Expanded(
      child: isClickable
          ? GestureDetector(
              onTap: () {
                if (statType == Defines.statInitiativeBonus) value = initiative_bonus;
                _showEditStatDialog(name, statType, value, isCount: isCount);
              },
              child: cardContent,
            )
          : cardContent,
    );
  }

  Widget _buildEditHitDiceCard() {
    final loc = AppLocalizations.of(context)!;
    return Expanded(
      child: GestureDetector(
        onTap: _showEditHitDiceDialog,
        child: Column(
          children: [
            Text(
              '${loc.hitdice} $healFactor',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 50,
              child: Card(
                color: AppColors.cardColor,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$currentHitDice / $maxHitDice',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Tracker tracker) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.deletetracker),
          content: Text(
            loc.confirmItemDelete(tracker.tracker)),
          actions: [
            TextButton(
              child: Text(loc.abort),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(loc.delete),
              onPressed: () {
                _removeTracker(tracker.uuid);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialogCondition(Condition condition) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.deletestatuseffect),
          content: Text(
              loc.confirmItemDelete(condition.condition)),
          actions: [
            TextButton(
              child: Text(loc.abort),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(loc.delete),
              onPressed: () {
                _removeCondition(condition.uuid);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialogC(Creature creature) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.deletecompanion),
          content: Text(
              loc.confirmItemDelete(creature.name)),
          actions: [
            TextButton(
              child: Text(loc.abort),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(loc.delete),
              onPressed: () {
                _removeCreature(creature.uuid);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class Tracker {
  String tracker;
  int? uuid;
  int? value;
  int? max;
  String? type;

  Tracker({
    required this.tracker,
    this.uuid,
    required this.value,
    required this.max,
    required this.type,
  });
}

class Condition {
  String condition;
  int? uuid;

  Condition({
    required this.condition,
    this.uuid,
  });
}
