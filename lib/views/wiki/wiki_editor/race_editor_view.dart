import 'package:dnd/configs/colours.dart';
import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';

class AddRacePage extends StatefulWidget {
  final Future<void> Function(RaceData) onSave;
  final RaceData? existingRace;

  const AddRacePage({super.key, required this.onSave, this.existingRace});

  @override
  AddRacePageState createState() => AddRacePageState();
}

class AddRacePageState extends State<AddRacePage> {
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController();
  final _speedController = TextEditingController();
  final _abilityController = TextEditingController();
  final _proficiencyController = TextEditingController();
  final _spellAbilityController = TextEditingController();
  final List<FeatureData> _traits = [];

  final List<String> _allSkills = [
    'Acrobatics', 'Animal Handling', 'Arcana', 'Athletics', 'Deception',
    'History', 'Insight', 'Intimidation', 'Investigation', 'Medicine',
    'Nature', 'Perception', 'Performance', 'Persuasion', 'Religion',
    'Sleight of Hand', 'Stealth', 'Survival'
  ];
  Set<String> _selectedProficiencies = {};

  final List<Map<String, String>> _abilities = [
    {'full': 'Strength', 'abbr': 'Str'},
    {'full': 'Dexterity', 'abbr': 'Dex'},
    {'full': 'Constitution', 'abbr': 'Con'},
    {'full': 'Intelligence', 'abbr': 'Int'},
    {'full': 'Wisdom', 'abbr': 'Wis'},
    {'full': 'Charisma', 'abbr': 'Cha'},
  ];
  Map<String, int> _abilityModifiers = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingRace != null) {
      _loadExistingRace();
    }
  }

  void _loadExistingRace() {
    final race = widget.existingRace!;
    _nameController.text = race.name;
    _sizeController.text = race.size;
    _speedController.text = race.speed.toString();
    _abilityController.text = race.ability;
    _proficiencyController.text = race.proficiency;
    _spellAbilityController.text = race.spellAbility;
    _traits.addAll(race.traits);

    // Parse proficiencies
    if (race.proficiency.isNotEmpty) {
      _selectedProficiencies = race.proficiency
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    }

    // Parse ability modifiers (e.g., "Str 2, Cha 1" or "Strength +2, Charisma +1")
    if (race.ability.isNotEmpty) {
      final modifiers = race.ability.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
      for (final modifier in modifiers) {
        final parts = modifier.split(' ');
        if (parts.length == 2) {
          final abilityStr = parts[0];
          final value = int.tryParse(parts[1].replaceAll('+', ''));
          if (value != null) {
            // Find the ability by abbreviation or full name
            final ability = _abilities.firstWhere(
              (a) => a['abbr'] == abilityStr || a['full'] == abilityStr,
              orElse: () => {'full': '', 'abbr': ''},
            );
            if (ability['abbr']!.isNotEmpty) {
              _abilityModifiers[ability['abbr']!] = value;
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _speedController.dispose();
    _abilityController.dispose();
    _proficiencyController.dispose();
    _spellAbilityController.dispose();
    super.dispose();
  }

  void _editTrait({FeatureData? trait}) async {
    final updatedTrait = await showDialog<FeatureData>(
      context: context,
      builder: (BuildContext context) {
        return TraitEditDialog(trait: trait);
      },
    );

    if (updatedTrait != null) {
      setState(() {
        if (trait != null) {
          final index = _traits.indexOf(trait);
          if (index != -1) {
            _traits[index] = updatedTrait;
          }
        } else {
          _traits.add(updatedTrait);
        }
      });
    }
  }

  void _showProficiencySelector() async {
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => ProficiencySelector(
        allSkills: _allSkills,
        selectedSkills: Set.from(_selectedProficiencies),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedProficiencies = selected;
      });
    }
  }

  void _showAbilityModifierSelector() async {
    final modifiers = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AbilityModifierSelector(
        abilities: _abilities,
        currentModifiers: Map.from(_abilityModifiers),
      ),
    );

    if (modifiers != null) {
      setState(() {
        _abilityModifiers = modifiers;
      });
    }
  }

  Future<void> _saveRace() async {
    // Build ability string from modifiers (e.g., "Str 2, Cha 1")
    final abilityString = _abilityModifiers.entries
        .map((e) => '${e.key} ${e.value}')
        .join(', ');

    final raceData = RaceData(
      name: _nameController.text.trim(),
      size: _sizeController.text.trim(),
      speed: int.tryParse(_speedController.text.trim()) ?? 30,
      ability: abilityString,
      proficiency: _selectedProficiencies.join(', '),
      spellAbility: _spellAbilityController.text.trim(),
      traits: _traits,
    );

    await widget.onSave(raceData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addRace),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveRace,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loc.races} ${loc.description}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.name,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sizeController,
                            decoration: InputDecoration(
                              labelText: loc.size,
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _speedController,
                            decoration: InputDecoration(
                              labelText: loc.movement,
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _showAbilityModifierSelector(),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: loc.abilityscoreincrease,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.primaryColor,
                        ),
                        child: Text(
                          _abilityModifiers.isEmpty
                              ? 'Select ability score increases...'
                              : _abilityModifiers.entries
                                  .map((e) => '${e.key} ${e.value}')
                                  .join(', '),
                          style: TextStyle(
                            color: _abilityModifiers.isEmpty
                                ? AppColors.textColorDark
                                : AppColors.textColorLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _showProficiencySelector(),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: loc.abilities,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.primaryColor,
                        ),
                        child: Text(
                          _selectedProficiencies.isEmpty
                              ? 'Select proficiencies...'
                              : _selectedProficiencies.join(', '),
                          style: TextStyle(
                            color: _selectedProficiencies.isEmpty
                                ? AppColors.textColorDark
                                : AppColors.textColorLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _spellAbilityController,
                      decoration: InputDecoration(
                        labelText: loc.spellcastingability,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: AppColors.cardColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.traits,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorLight,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _editTrait(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(loc.addTrait),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _traits.length,
                      itemBuilder: (context, index) {
                        final trait = _traits[index];
                        return Card(
                          color: AppColors.cardColor,
                          elevation: 4.0,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 0),
                          child: ListTile(
                            title: Text(
                              trait.name,
                              style: TextStyle(color: AppColors.textColorLight),
                            ),
                            subtitle: Text(
                              trait.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppColors.textColorLight
                                      .withOpacity(0.7)),
                            ),
                            onTap: () => _editTrait(trait: trait),
                            trailing: IconButton(
                              icon: Icon(Icons.delete,
                                  color: AppColors.textColorDark),
                              onPressed: () {
                                setState(() {
                                  _traits.remove(trait);
                                });
                              },
                            ),
                            tileColor: AppColors.cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProficiencySelector extends StatefulWidget {
  final List<String> allSkills;
  final Set<String> selectedSkills;

  const ProficiencySelector({
    super.key,
    required this.allSkills,
    required this.selectedSkills,
  });

  @override
  State<ProficiencySelector> createState() => _ProficiencySelectorState();
}

class _ProficiencySelectorState extends State<ProficiencySelector> {
  late Set<String> selected;

  @override
  void initState() {
    super.initState();
    selected = Set.from(widget.selectedSkills);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text('Select ${loc.abilities}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.allSkills.length,
          itemBuilder: (context, index) {
            final skill = widget.allSkills[index];
            return CheckboxListTile(
              title: Text(skill),
              value: selected.contains(skill),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    selected.add(skill);
                  } else {
                    selected.remove(skill);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.abort),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selected),
          child: Text(loc.save),
        ),
      ],
    );
  }
}

class TraitEditDialog extends StatefulWidget {
  final FeatureData? trait;

  const TraitEditDialog({super.key, this.trait});

  @override
  State<TraitEditDialog> createState() => _TraitEditDialogState();
}

class _TraitEditDialogState extends State<TraitEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trait?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.trait?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTrait() {
    if (_nameController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty) {
      Navigator.of(context).pop(
        FeatureData(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.trait == null ? loc.addTrait : loc.editTrait),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: loc.name,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: loc.description,
                border: const OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.textColorDark),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _saveTrait,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentTeal,
            foregroundColor: Colors.white,
          ),
          child: Text(loc.save),
        ),
      ],
    );
  }
}

class AbilityModifierSelector extends StatefulWidget {
  final List<Map<String, String>> abilities;
  final Map<String, int> currentModifiers;

  const AbilityModifierSelector({
    super.key,
    required this.abilities,
    required this.currentModifiers,
  });

  @override
  State<AbilityModifierSelector> createState() => _AbilityModifierSelectorState();
}

class _AbilityModifierSelectorState extends State<AbilityModifierSelector> {
  late Map<String, int> modifiers;

  @override
  void initState() {
    super.initState();
    modifiers = Map.from(widget.currentModifiers);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: const Text('Select Ability Score Increases'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.abilities.length,
          itemBuilder: (context, index) {
            final ability = widget.abilities[index];
            final abbr = ability['abbr']!;
            final fullName = ability['full']!;
            final currentValue = modifiers[abbr];

            return Card(
              color: AppColors.cardColor,
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$fullName ($abbr)',
                        style: TextStyle(
                          color: AppColors.textColorLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DropdownButton<int?>(
                      value: currentValue,
                      hint: const Text('None'),
                      dropdownColor: AppColors.cardColor,
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('None', style: TextStyle(color: AppColors.textColorLight)),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('1', style: TextStyle(color: AppColors.textColorLight)),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('2', style: TextStyle(color: AppColors.textColorLight)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          if (value == null) {
                            modifiers.remove(abbr);
                          } else {
                            modifiers[abbr] = value;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.abort),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, modifiers),
          child: Text(loc.save),
        ),
      ],
    );
  }
}
