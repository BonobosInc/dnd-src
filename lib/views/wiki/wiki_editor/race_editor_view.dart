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

  Future<void> _saveRace() async {
    final raceData = RaceData(
      name: _nameController.text.trim(),
      size: _sizeController.text.trim(),
      speed: int.tryParse(_speedController.text.trim()) ?? 30,
      ability: _abilityController.text.trim(),
      proficiency: _proficiencyController.text.trim(),
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
                    TextField(
                      controller: _abilityController,
                      decoration: InputDecoration(
                        labelText: loc.abilityscoreincrease,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _proficiencyController,
                      decoration: InputDecoration(
                        labelText: loc.abilities,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
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
