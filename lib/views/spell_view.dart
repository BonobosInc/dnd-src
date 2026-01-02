import 'package:dnd/classes/wiki_parser.dart';
import 'package:dnd/configs/defines.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/classes/profile_manager.dart';
import 'spell_editing_view.dart';
import 'package:dnd/l10n/app_localizations.dart';

class SpellManagementPage extends StatefulWidget {
  final ProfileManager profileManager;

  final WikiParser wikiParser;

  const SpellManagementPage({
    super.key,
    required this.profileManager,
    required this.wikiParser,
  });

  @override
  SpellManagementPageState createState() => SpellManagementPageState();
}

class SpellManagementPageState extends State<SpellManagementPage> {
  final TextEditingController _spellAttackController = TextEditingController();
  final TextEditingController _spellDcController = TextEditingController();
  final TextEditingController _spellcastingClassController =
      TextEditingController();
  final TextEditingController _spellcastingAbilityController =
      TextEditingController();

  List<List<Spell>> spellLevels = List.generate(10, (index) => []);

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _fetchSpells();
  }

  Future<void> _initializeFields() async {
    var initialStats = await widget.profileManager.getStats();
    var initialInfo = await widget.profileManager.getProfileInfo();

    int spellAttackBonus = initialStats[0][Defines.statSpellAttackBonus] ?? 0;
    int spellSaveDC = initialStats[0][Defines.statSpellSaveDC] ?? 0;
    String spellcastingClass =
        initialInfo[0][Defines.infoSpellcastingClass] ?? "";
    String spellcastingAbility =
        initialInfo[0][Defines.infoSpellcastingAbility] ?? "";

    _spellAttackController.text = spellAttackBonus.toString();

    _spellDcController.text = spellSaveDC.toString();

    _spellcastingClassController.text = spellcastingClass;

    _spellcastingAbilityController.text = spellcastingAbility;
  }

  Future<void> _fetchSpells() async {
    spellLevels = List.generate(10, (index) => []);

    List<Map<String, dynamic>> spellsWithLevels =
        await widget.profileManager.getAllSpells();

    for (var spell in spellsWithLevels) {
      if (spell['status'] == Defines.spellPrep && spell['level'] != null) {
        int level;

        if (spell['level'] is String) {
          level = int.tryParse(spell['level']) ?? 0;
        } else if (spell['level'] is int) {
          level = spell['level'];
        } else {
          continue;
        }

        Spell spellObj = Spell(
          name: spell['spellname'] ?? '',
          description: spell['description'] ?? '',
          status: spell['status'] ?? '',
          level: level,
          reach: spell['reach'] ?? '',
          duration: spell['duration'] ?? '',
          uuid: spell['ID'],
        );

        if (level >= 0 && level < spellLevels.length) {
          spellLevels[level].add(spellObj);
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.spell),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.accentPurple),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SpellEditingPage(
                          profileManager: widget.profileManager,
                          wikiParser: widget.wikiParser,
                        )),
              );
              await _fetchSpells();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSpellcastingFields(),
            Expanded(child: _buildSpellLevelFields()),
          ],
        ),
      ),
    );
  }

  Widget _buildSpellcastingFields() {
    final loc = AppLocalizations.of(context)!;
    return SizedBox(
      width: 300,
      height: 200,
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          _buildTextField(
            controller: _spellAttackController,
            label: loc.spellattack,
            hint: '',
            onChanged: (value) =>
                _updateField(Defines.statSpellAttackBonus, value),
            isIntegerField: true,
          ),
          _buildTextField(
            controller: _spellDcController,
            label: loc.spelldc,
            hint: '',
            onChanged: (value) => _updateField(Defines.statSpellSaveDC, value),
            isIntegerField: true,
          ),
          _buildTextField(
            controller: _spellcastingClassController,
            label: loc.spellclass,
            hint: '',
            onChanged: (value) =>
                _updateField(Defines.infoSpellcastingClass, value),
          ),
          _buildTextField(
            controller: _spellcastingAbilityController,
            label: loc.spellcastingability,
            hint: '',
            onChanged: (value) =>
                _updateField(Defines.infoSpellcastingAbility, value),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Function(String) onChanged,
    bool isIntegerField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textColorLight,
                fontSize: 16,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 100,
          height: 60,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType:
                isIntegerField ? TextInputType.number : TextInputType.text,
            inputFormatters: isIntegerField
                ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
                : [],
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textColorDark),
            ),
            onChanged: (value) {
              if (isIntegerField) {
                if (value.isEmpty || int.tryParse(value) != null) {
                  onChanged(value);
                } else {
                  controller.clear();
                }
              } else {
                onChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _updateField(String field, String value) async {
    if (field == Defines.statSpellAttackBonus ||
        field == Defines.statSpellSaveDC) {
      await widget.profileManager.updateStats(field: field, value: value);
    } else {
      await widget.profileManager.updateProfileInfo(field: field, value: value);
    }
  }

  Widget _buildSpellLevelFields() {
    final loc = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine columns based on screen width
    int crossAxisCount;
    if (screenWidth > 1200) {
      crossAxisCount = 3; // Large tablets/desktop - 3 columns
    } else if (screenWidth > 600) {
      crossAxisCount = 2; // Tablets/foldables - 2 columns
    } else {
      crossAxisCount = 1; // Phones - 1 column
    }

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.center,
            children: [
              for (int levelIndex = 0;
                  levelIndex < spellLevels.length;
                  levelIndex++)
                SizedBox(
                  width: (constraints.maxWidth / crossAxisCount) - (16.0 * (crossAxisCount - 1) / crossAxisCount),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (levelIndex > 0) {
                            _editSpellSlots(levelIndex);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (levelIndex > 0) ...[
                              _buildDecrementButton(levelIndex),
                            ],
                            Flexible(
                              child: Text(
                                levelIndex == 0
                                    ? loc.cantrip
                                    : '${loc.level} $levelIndex ',
                                style: TextStyle(
                                  color: AppColors.textColorLight,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (levelIndex > 0) ...[
                              _buildSpellSlotControls(levelIndex),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ..._buildSpellNames(levelIndex),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDecrementButton(int levelIndex) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.profileManager.getSpellSlots(),
      builder: (context, snapshot) {
        int totalSlots = 0;
        int currentSlots = 0;
        if (snapshot.hasData) {
          String spellSlotKey = _getSpellSlotKey(levelIndex);

          for (var slot in snapshot.data!) {
            if (slot['spellslot'] == spellSlotKey) {
              totalSlots = slot['total'] ?? 0;
              currentSlots = slot['spent'] ?? 0;
            }
          }
        }

        return IconButton(
          icon: Icon(Icons.remove, color: AppColors.warningColor),
          onPressed: () {
            if (currentSlots > 0) {
              setState(() {
                currentSlots--;
              });
              _updateCurrentSlots(levelIndex, currentSlots, totalSlots);
            }
          },
        );
      },
    );
  }

  Widget _buildSpellSlotControls(int levelIndex) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.profileManager.getSpellSlots(),
      builder: (context, snapshot) {
        int totalSlots = 0;
        int currentSlots = 0;

        if (snapshot.hasData) {
          String spellSlotKey = _getSpellSlotKey(levelIndex);

          for (var slot in snapshot.data!) {
            if (slot['spellslot'] == spellSlotKey) {
              totalSlots = slot['total'] ?? 0;
              currentSlots = slot['spent'] ?? 0;
            }
          }
        }

        return Row(
          children: [
            Text(
              '($currentSlots/$totalSlots)',
              style: TextStyle(
                color: AppColors.textColorLight,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, color: AppColors.currentHealth),
              onPressed: () {
                if (currentSlots < totalSlots) {
                  setState(() {
                    currentSlots++;
                  });
                  _updateCurrentSlots(levelIndex, currentSlots, totalSlots);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _updateCurrentSlots(
      int levelIndex, int currentSlots, int totalSlots) async {
    String spellSlotKey = _getSpellSlotKey(levelIndex);

    await widget.profileManager.updateSpellSlots(
      spellslot: spellSlotKey,
      total: totalSlots,
      spent: currentSlots,
    );

    if (mounted) {
      setState(() {
        _fetchAndUpdateSlots();
      });
    }
  }

  List<Widget> _buildSpellNames(int levelIndex) {
    List<Widget> fields = [];
    for (var spell in spellLevels[levelIndex]) {
      fields.add(
        GestureDetector(
          onTap: () async {
            Map<String, dynamic> spelldata =
                await widget.profileManager.getSpell(spell.uuid!);
            _showSpellDescription(spell.name, spelldata);
          },
          child: SizedBox(
            width: 150,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              margin: const EdgeInsets.only(bottom: 8.0, right: 8.0),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: [
                    AppColors.textColorDark,
                    AppColors.accentPurple,
                    AppColors.accentOrange,
                    AppColors.accentTeal,
                    AppColors.accentPink,
                    AppColors.accentCyan,
                    AppColors.accentYellow,
                    AppColors.currentHealth,
                    AppColors.tempHealth,
                    AppColors.warningColor,
                  ][levelIndex % 10],
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.2 * 255).toInt()),
                    offset: const Offset(2, 2),
                    blurRadius: 4.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  spell.name.isNotEmpty ? spell.name : '',
                  style: TextStyle(
                    color: AppColors.textColorDark,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return [
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.0,
        runSpacing: 8.0,
        children: fields,
      ),
    ];
  }

  void _showSpellDescription(String spellName, Map<String, dynamic> spellData) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(spellName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${loc.reach}: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(spellData['reach'] ?? loc.unknown),
                SizedBox(height: 8.0),
                Text("${loc.duration}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(spellData['duration'] ?? loc.unknown),
                SizedBox(height: 8.0),
                Text("${loc.description}: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    spellData['description'] ?? loc.nodescription),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.close),
            ),
          ],
        );
      },
    );
  }

  void _editSpellSlots(int levelIndex) async {
    final loc = AppLocalizations.of(context)!;
    int totalSlots = 0;
    int currentSlots = 0;

    String spellSlotKey = _getSpellSlotKey(levelIndex);

    var slots = await widget.profileManager.getSpellSlots();

    for (var slot in slots) {
      if (slot['spellslot'] == spellSlotKey) {
        totalSlots = slot['total'] ?? 0;
        currentSlots = slot['spent'] ?? 0;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        int newTotal = totalSlots;
        int newCurrent = currentSlots;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                '${loc.spellslotsforlevel} ${levelIndex == 0 ? loc.cantrip : levelIndex}',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${loc.total}:'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (newTotal > 0) newTotal--;
                              });
                            },
                          ),
                          Text('$newTotal'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                newTotal++;
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
                      Text('${loc.current}:'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (newCurrent > 0) newCurrent--;
                              });
                            },
                          ),
                          Text('$newCurrent'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                if (newCurrent < newTotal) newCurrent++;
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
                    await widget.profileManager.updateSpellSlots(
                      spellslot: spellSlotKey,
                      total: newTotal,
                      spent: newCurrent,
                    );

                    if (mounted) {
                      setState(() {
                        _fetchAndUpdateSlots();
                      });
                    }
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

  void _fetchAndUpdateSlots() {
    widget.profileManager.getSpellSlots().then((slots) {
      setState(() {});
    });
  }

  String _getSpellSlotKey(int levelIndex) {
    switch (levelIndex) {
      case 0:
        return Defines.slotZero;
      case 1:
        return Defines.slotOne;
      case 2:
        return Defines.slotTwo;
      case 3:
        return Defines.slotThree;
      case 4:
        return Defines.slotFour;
      case 5:
        return Defines.slotFive;
      case 6:
        return Defines.slotSix;
      case 7:
        return Defines.slotSeven;
      case 8:
        return Defines.slotEight;
      case 9:
        return Defines.slotNine;
      default:
        return Defines.slotZero;
    }
  }
}
