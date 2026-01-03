import 'package:dnd/classes/profile_manager.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/classes/wiki_parser.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:dnd/views/character_creator/creator_views.dart';
import 'package:flutter/material.dart';

class CharacterCreatorPage extends StatefulWidget {
  final WikiParser wikiParser;
  final ProfileManager profileManager;
  const CharacterCreatorPage(
      {super.key, required this.wikiParser, required this.profileManager});

  @override
  State<CharacterCreatorPage> createState() => _CharacterCreatorPageState();
}

class _CharacterCreatorPageState extends State<CharacterCreatorPage> {
  final TextEditingController _nameController = TextEditingController();

  List<RaceData> races = [];
  List<ClassData> classes = [];
  List<BackgroundData> backgrounds = [];
  List<FeatData> feats = [];
  List<SpellData> spells = [];

  bool raceSelected = false;
  bool classSelected = false;
  bool backgroundSelected = false;
  bool featSelected = false;
  bool skillsSelected = false;
  bool abilityScoresSet = false;
  bool spellsSelected = false;
  bool hpSet = false;

  RaceData? _selectedRace;
  ClassData? _selectedClass;
  BackgroundData? _selectedBackground;
  FeatData? _selectedFeat;
  Map<String, int>? _selectedFinalScores;
  Map<String, bool>? _selectedProficiencies;
  Map<String, bool>? _selectedExpertise;
  List<String>? _selectedSavingThrows;
  List<SpellData> _selectedSpells = [];
  int _selectedLevel = 1;
  int? _selectedHP;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  Future<void> _loadData() async {
    races = await widget.wikiParser.races;
    classes = await widget.wikiParser.classes;
    backgrounds = await widget.wikiParser.backgrounds;
    feats = await widget.wikiParser.feats;
    spells = await widget.wikiParser.spells;
    setState(() {});
  }

  bool _hasSpells() {
    if (_selectedClass == null) return false;
    // Check if class has spellcasting ability defined
    if (_selectedClass!.spellAbility.isNotEmpty) return true;
    // Fallback: check if any autolevel has slots defined
    return _selectedClass!.autolevels.any((al) => al.slots != null && al.slots!.slots.isNotEmpty);
  }

  Future<void> _onCreateCharacter() async {
    final loc = AppLocalizations.of(context)!;
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enternewname)),
      );
      return;
    }

    // Check required steps including spell selection for spellcasting classes
    bool allStepsComplete = raceSelected &&
        classSelected &&
        backgroundSelected &&
        skillsSelected &&
        abilityScoresSet &&
        (_hasSpells() ? spellsSelected : true) &&
        hpSet;

    if (!allStepsComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.completeallsteps)),
      );
      return;
    }

    await widget.profileManager.characterCreator(
        _nameController.text,
        _selectedRace!,
        _selectedClass!,
        _selectedBackground!,
        _selectedFeat,
        _selectedFinalScores!,
        _selectedLevel,
        _selectedHP!,
        _selectedProficiencies,
        _selectedExpertise,
        _selectedSavingThrows);

    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _navigateTo<T>(Widget page, void Function(T? result) onReturn) {
    Navigator.of(context)
        .push<T>(MaterialPageRoute(builder: (_) => page))
        .then((result) {
      onReturn(result);
    });
  }

  Widget _buildStepTile({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool completed,
    required bool enabled,
  }) {
    return Card(
      color: enabled ? AppColors.cardColor : AppColors.appBarColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      child: ListTile(
        enabled: enabled,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: enabled ? AppColors.textColorLight : AppColors.textColorDark,
          ),
        ),
        subtitle: subtitle != null && subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(
                  color: enabled
                      ? AppColors.textColorLight.withOpacity(0.7)
                      : AppColors.textColorDark.withOpacity(0.7),
                ),
              )
            : null,
        trailing: completed
            ? Icon(
                Icons.check_circle,
                color: AppColors.accentTeal,
                size: 24,
              )
            : Icon(
                Icons.arrow_forward_ios,
                color: enabled
                    ? AppColors.textColorLight
                    : AppColors.textColorDark.withOpacity(0.5),
                size: 16,
              ),
        onTap: enabled ? onTap : null,
        tileColor: enabled ? AppColors.cardColor : AppColors.appBarColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _showExitConfirmationDialog(context);
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.characterCreator),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<int>(
                value: _selectedLevel,
                dropdownColor: AppColors.appBarColor,
                underline: Container(),
                icon: Icon(Icons.arrow_drop_down,
                    color: AppColors.textColorLight),
                items: List.generate(20, (index) => index + 1)
                    .map((level) => DropdownMenuItem<int>(
                          value: level,
                          child: Text(
                            'Level $level',
                            style: TextStyle(
                              color: AppColors.textColorLight,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLevel = value;
                    });
                  }
                },
                selectedItemBuilder: (BuildContext context) {
                  return List.generate(20, (index) => index + 1)
                      .map((level) => Center(
                            child: Text(
                              'Lvl $level',
                              style: TextStyle(
                                color: AppColors.textColorLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ))
                      .toList();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _onCreateCharacter,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: AppColors.cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: loc.name,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Race Tile - always enabled
              _buildStepTile(
                title: loc.chooserace,
                subtitle: _selectedRace?.name,
                completed: raceSelected,
                enabled: true,
                onTap: () => _navigateTo<RaceData>(
                  RacePage(races: races),
                  (race) {
                    if (race != null) {
                      setState(() {
                        raceSelected = true;
                        _selectedRace = race;
                      });
                    }
                  },
                ),
              ),

              // Class Tile - enabled if race selected
              _buildStepTile(
                title: loc.chooseclass,
                subtitle: _selectedClass?.name,
                completed: classSelected,
                enabled: raceSelected,
                onTap: () => _navigateTo<ClassData>(
                  ClassPage(classes: classes),
                  (classData) {
                    if (classData != null) {
                      setState(() {
                        classSelected = true;
                        _selectedClass = classData;
                      });
                    }
                  },
                ),
              ),

              // Background Tile - enabled if class selected
              _buildStepTile(
                title: loc.choosebackground,
                subtitle: _selectedBackground?.name,
                completed: backgroundSelected,
                enabled: classSelected,
                onTap: () => _navigateTo<BackgroundData>(
                  BackgroundPage(backgrounds: backgrounds),
                  (background) {
                    if (background != null) {
                      setState(() {
                        backgroundSelected = true;
                        _selectedBackground = background;
                      });
                    }
                  },
                ),
              ),

              // Feat Tile - enabled if background selected
              _buildStepTile(
                title: loc.choosefeat,
                subtitle: _selectedFeat != null
                    ? '${_selectedFeat!.name}${_selectedFeat!.modifier != null && _selectedFeat!.modifier!.isNotEmpty ? ' (${_selectedFeat!.modifier})' : ''}'
                    : null,
                completed: featSelected,
                enabled: classSelected,
                onTap: () => _navigateTo<FeatData>(
                  FeatPage(feats: feats),
                  (feat) {
                    if (feat != null) {
                      setState(() {
                        featSelected = true;
                        _selectedFeat = feat;
                      });
                    }
                  },
                ),
              ),

              // Skill Selection Tile - enabled if class selected
              _buildStepTile(
                title: loc.chooseskills,
                subtitle: skillsSelected
                    ? '${_selectedProficiencies?.values.where((v) => v).length ?? 0} proficiencies'
                    : null,
                completed: skillsSelected,
                enabled: classSelected,
                onTap: () => _navigateTo<Map<String, dynamic>>(
                  SkillSelectionPage(
                    classData: _selectedClass!,
                    featData: _selectedFeat,
                    backgroundData: _selectedBackground,
                    raceData: _selectedRace,
                  ),
                  (result) {
                    if (result != null) {
                      setState(() {
                        skillsSelected = true;
                        _selectedProficiencies =
                            result['proficiencies'] as Map<String, bool>?;
                        _selectedExpertise =
                            result['expertise'] as Map<String, bool>?;
                        _selectedSavingThrows =
                            result['savingThrows'] as List<String>?;
                      });
                    }
                  },
                ),
              ),

              // Ability Scores Tile - enabled if skills selected
              _buildStepTile(
                title: loc.setabilityscores,
                completed: abilityScoresSet,
                enabled: skillsSelected,
                onTap: () => _navigateTo<Map<String, int>>(
                  AbilityScoresPage(bonusInput: _selectedRace?.ability ?? ""),
                  (finalScores) {
                    if (finalScores != null) {
                      setState(() {
                        abilityScoresSet = true;
                        _selectedFinalScores = finalScores;
                      });
                    }
                  },
                ),
              ),

              // Spells Tile - enabled if ability scores set (only for spellcasting classes)
              if (_hasSpells())
                _buildStepTile(
                  title: loc.choosespells,
                  subtitle: _selectedSpells.isNotEmpty
                      ? '${_selectedSpells.length} ${loc.spells.toLowerCase()}'
                      : null,
                  completed: spellsSelected,
                  enabled: abilityScoresSet && classSelected,
                  onTap: () => _navigateTo<List<SpellData>>(
                    SpellSelectionPage(
                      allSpells: spells,
                      classData: _selectedClass!,
                      characterLevel: _selectedLevel,
                      initialSelection: _selectedSpells,
                    ),
                    (selectedSpells) {
                      if (selectedSpells != null) {
                        setState(() {
                          spellsSelected = true;
                          _selectedSpells = selectedSpells;
                        });
                      }
                    },
                  ),
                ),

              // HP Tile - enabled if ability scores set (and spells if applicable)
              _buildStepTile(
                title: loc.setHitPoints,
                subtitle: _selectedHP != null ? loc.hpDisplay(_selectedHP!) : null,
                completed: hpSet,
                enabled: (_hasSpells() ? spellsSelected : abilityScoresSet) && classSelected,
                onTap: () => _navigateTo<int>(
                  HPSelectionPage(
                    classData: _selectedClass!,
                    level: _selectedLevel,
                    constitutionModifier: _selectedFinalScores != null
                        ? ((_selectedFinalScores!['CON'] ?? 10) - 10) ~/ 2
                        : 0,
                  ),
                  (hp) {
                    if (hp != null) {
                      setState(() {
                        hpSet = true;
                        _selectedHP = hp;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(loc.exitCharacterCreator),
            content: Text(loc.exitConfirmationMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(loc.no),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(loc.yes),
              ),
            ],
          ),
        ) ??
        false;
  }
}
