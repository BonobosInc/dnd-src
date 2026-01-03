import 'package:dnd/configs/colours.dart';
import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:dnd/views/wiki/wiki_editor/race_editor_view.dart';

class AddBackgroundPage extends StatefulWidget {
  final Future<void> Function(BackgroundData) onSave;
  final BackgroundData? existingBackground;

  const AddBackgroundPage({super.key, required this.onSave, this.existingBackground});

  @override
  AddBackgroundPageState createState() => AddBackgroundPageState();
}

class AddBackgroundPageState extends State<AddBackgroundPage> {
  final _nameController = TextEditingController();
  final _proficiencyController = TextEditingController();
  final List<FeatureData> _traits = [];

  final List<String> _allSkills = [
    'Acrobatics', 'Animal Handling', 'Arcana', 'Athletics', 'Deception',
    'History', 'Insight', 'Intimidation', 'Investigation', 'Medicine',
    'Nature', 'Perception', 'Performance', 'Persuasion', 'Religion',
    'Sleight of Hand', 'Stealth', 'Survival'
  ];
  Set<String> _selectedProficiencies = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingBackground != null) {
      _loadExistingBackground();
    }
  }

  void _loadExistingBackground() {
    final bg = widget.existingBackground!;
    _nameController.text = bg.name;
    _proficiencyController.text = bg.proficiency;
    _traits.addAll(bg.traits);

    // Parse proficiencies
    if (bg.proficiency.isNotEmpty) {
      _selectedProficiencies = bg.proficiency
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _proficiencyController.dispose();
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

  Future<void> _saveBackground() async {
    final backgroundData = BackgroundData(
      name: _nameController.text.trim(),
      proficiency: _selectedProficiencies.join(', '),
      traits: _traits,
    );

    await widget.onSave(backgroundData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addBackground),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveBackground,
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
                      loc.backgrounds,
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
