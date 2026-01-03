import 'package:dnd/configs/colours.dart';
import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';

class AddClassPage extends StatefulWidget {
  final Future<void> Function(ClassData) onSave;
  final ClassData? existingClass;

  const AddClassPage({super.key, required this.onSave, this.existingClass});

  @override
  AddClassPageState createState() => AddClassPageState();
}

class AddClassPageState extends State<AddClassPage> {
  final _nameController = TextEditingController();
  final _hdController = TextEditingController();
  final _proficiencyController = TextEditingController();
  final _spellAbilityController = TextEditingController();
  final _numSkillsController = TextEditingController();
  final Map<int, List<FeatureData>> _featuresByLevel = {};
  final Map<int, Slots> _slotsByLevel = {};

  final List<String> _savingThrows = [
    'Strength', 'Dexterity', 'Constitution', 'Intelligence', 'Wisdom', 'Charisma'
  ];
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
    if (widget.existingClass != null) {
      _loadExistingClass();
    }
  }

  void _loadExistingClass() {
    final classData = widget.existingClass!;
    _nameController.text = classData.name;
    _hdController.text = classData.hd;
    _proficiencyController.text = classData.proficiency;
    _spellAbilityController.text = classData.spellAbility;
    _numSkillsController.text = classData.numSkills;

    // Parse proficiencies
    if (classData.proficiency.isNotEmpty) {
      _selectedProficiencies = classData.proficiency
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    }

    for (final autolevel in classData.autolevels) {
      final level = int.tryParse(autolevel.level) ?? 1;
      if (autolevel.slots != null) {
        _slotsByLevel[level] = autolevel.slots!;
      }
      if (autolevel.features != null && autolevel.features!.isNotEmpty) {
        _featuresByLevel[level] = autolevel.features!;
      }
    }
  }

  void _editLevel(int level) async {
    final updatedLevel = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditLevelPage(
          level: level,
          existingFeatures: _featuresByLevel[level] ?? [],
          existingSlots: _slotsByLevel[level],
        ),
      ),
    );

    if (updatedLevel != null) {
      setState(() {
        _featuresByLevel[level] = updatedLevel['features'];
        _slotsByLevel[level] = updatedLevel['slots'];
      });
    }
  }

  void _showProficiencySelector() async {
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => ClassProficiencySelector(
        savingThrows: _savingThrows,
        allSkills: _allSkills,
        selectedProficiencies: Set.from(_selectedProficiencies),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedProficiencies = selected;
      });
    }
  }

  Future<void> _saveClass() async {
    final List<Autolevel> autolevels = [];

    for (int level = 1; level <= 20; level++) {
      if (_slotsByLevel[level] == null) {
        _slotsByLevel[level] = Slots(slots: List.filled(10, 0));
      }
      autolevels.add(
        Autolevel(level: level.toString(), slots: _slotsByLevel[level]),
      );

      final features = _featuresByLevel[level];
      if (features != null) {
        for (var feature in features) {
          autolevels.add(
            Autolevel(level: level.toString(), features: [feature]),
          );
        }
      }
    }

    final classData = ClassData(
      name: _nameController.text,
      hd: _hdController.text,
      proficiency: _selectedProficiencies.join(', '),
      spellAbility: _spellAbilityController.text,
      numSkills: _numSkillsController.text,
      autolevels: autolevels,
    );

    await widget.onSave(classData);
    Navigator.pop(context);
  }

  Widget _buildLevels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(20, (index) {
        final level = index + 1;
        final features = _featuresByLevel[level];
        final hasFeatures = features != null && features.isNotEmpty;
        final hasSlots =
            _slotsByLevel[level]?.slots.any((slot) => slot > 0) ?? false;

        return Card(
          color: AppColors.cardColor,
          elevation: 4.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            title: Text(
              'Level $level',
              style: TextStyle(
                color: AppColors.textColorLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: hasFeatures || hasSlots
                ? Text(
                    '${hasFeatures ? '${features.length} feature${features.length > 1 ? 's' : ''}' : ''}${hasFeatures && hasSlots ? ', ' : ''}${hasSlots ? 'Has spell slots' : ''}',
                    style: TextStyle(
                      color: AppColors.textColorLight.withOpacity(0.7),
                    ),
                  )
                : null,
            onTap: () => _editLevel(level),
            trailing: Icon(
              Icons.edit,
              color: AppColors.textColorLight,
            ),
            tileColor: AppColors.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addClass),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveClass,
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
                      loc.classesKey,
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
                            controller: _hdController,
                            decoration: InputDecoration(
                              labelText: 'HD',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _spellAbilityController,
                            decoration: InputDecoration(
                              labelText: 'Spell Ability',
                              hintText: 'e.g., Charisma, Intelligence',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _numSkillsController,
                            decoration: InputDecoration(
                              labelText: loc.numskills,
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
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
                              ? 'Select saving throws and skills...'
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
            Text(
              '${loc.level}s',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColorLight,
              ),
            ),
            const SizedBox(height: 12),
            _buildLevels(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class EditLevelPage extends StatefulWidget {
  final int level;
  final List<FeatureData> existingFeatures;
  final Slots? existingSlots;

  const EditLevelPage({
    super.key,
    required this.level,
    required this.existingFeatures,
    this.existingSlots,
  });

  @override
  EditLevelPageState createState() => EditLevelPageState();
}

class EditLevelPageState extends State<EditLevelPage> {
  final List<FeatureData> _features = [];
  final List<TextEditingController> _slotControllers = List.generate(
    10,
    (_) => TextEditingController(text: '0'),
  );

  @override
  void initState() {
    super.initState();
    _features.addAll(widget.existingFeatures);
    if (widget.existingSlots != null) {
      final slots = widget.existingSlots!.slots;
      for (int i = 0; i < slots.length; i++) {
        _slotControllers[i].text = slots[i].toString();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _slotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _editFeature({FeatureData? feature}) async {
    final updatedFeature = await showDialog<FeatureData>(
      context: context,
      builder: (BuildContext context) {
        return FeatureEditDialog(feature: feature);
      },
    );

    if (updatedFeature != null) {
      setState(() {
        if (feature != null) {
          // Update existing feature
          final index = _features.indexOf(feature);
          if (index != -1) {
            _features[index] = updatedFeature;
          }
        } else {
          // Add new feature
          _features.add(updatedFeature);
        }
      });
    }
  }

  void _saveLevel() {
    final slots = _slotControllers.map((controller) {
      final text = controller.text.trim();
      return text.isEmpty ? 0 : int.parse(text);
    }).toList();

    Navigator.pop(context, {
      'features': _features,
      'slots': Slots(slots: slots),
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${loc.level} ${widget.level}'),
        actions: [
          IconButton(
            onPressed: _saveLevel,
            icon: Icon(Icons.save),
            tooltip: loc.save,
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
                      loc.spellslots,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 10,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.2,
                      ),
                      itemBuilder: (context, index) {
                        return TextField(
                          controller: _slotControllers[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: (index == 0) ? loc.cantrip : '$index',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: AppColors.primaryColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                        );
                      },
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
                          loc.feats,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorLight,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _editFeature(),
                          icon: Icon(Icons.add, color: AppColors.accentTeal),
                          tooltip: loc.addFeature,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _features.map((feature) {
                        return Card(
                          color: AppColors.cardColor,
                          elevation: 4.0,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 0),
                          child: ListTile(
                            title: Text(
                              feature.name,
                              style: TextStyle(color: AppColors.textColorLight),
                            ),
                            subtitle: Text(
                              feature.description,
                              style: TextStyle(
                                  color: AppColors.textColorLight
                                      .withOpacity(0.7)),
                            ),
                            onTap: () => _editFeature(feature: feature),
                            trailing: SizedBox(
                              width: 35,
                              height: 35,
                              child: IconButton(
                                icon: Icon(Icons.close,
                                    color: AppColors.textColorDark),
                                iconSize: 20.0,
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    _features.remove(feature);
                                  });
                                },
                              ),
                            ),
                            tileColor: AppColors.cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        );
                      }).toList(),
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

class FeatureEditDialog extends StatefulWidget {
  final FeatureData? feature;

  const FeatureEditDialog({super.key, this.feature});

  @override
  State<FeatureEditDialog> createState() => _FeatureEditDialogState();
}

class _FeatureEditDialogState extends State<FeatureEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.feature?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.feature?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveFeature() {
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
      title: Text(widget.feature == null ? loc.addFeature : loc.editFeature),
      content: Column(
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
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.textColorDark),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _saveFeature,
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

class ClassProficiencySelector extends StatefulWidget {
  final List<String> savingThrows;
  final List<String> allSkills;
  final Set<String> selectedProficiencies;

  const ClassProficiencySelector({
    super.key,
    required this.savingThrows,
    required this.allSkills,
    required this.selectedProficiencies,
  });

  @override
  State<ClassProficiencySelector> createState() => _ClassProficiencySelectorState();
}

class _ClassProficiencySelectorState extends State<ClassProficiencySelector> {
  late Set<String> selected;

  @override
  void initState() {
    super.initState();
    selected = Set.from(widget.selectedProficiencies);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: const Text('Select Saving Throws & Skills'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: ListView(
          children: [
            Text(
              'Saving Throws',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.accentTeal,
              ),
            ),
            ...widget.savingThrows.map((savingThrow) {
              return CheckboxListTile(
                title: Text(savingThrow),
                value: selected.contains(savingThrow),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      selected.add(savingThrow);
                    } else {
                      selected.remove(savingThrow);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 16),
            Text(
              'Skills',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.accentTeal,
              ),
            ),
            ...widget.allSkills.map((skill) {
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
            }),
          ],
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
