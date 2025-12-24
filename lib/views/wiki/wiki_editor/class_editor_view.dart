<<<<<<< HEAD
=======
import 'package:dnd/classes/wiki_classes.dart';
>>>>>>> 31b1db7b19c2173dacb5692f5645304edae5dc1d
import 'package:dnd/configs/colours.dart';
import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';

class AddClassPage extends StatefulWidget {
  final void Function(ClassData) onSave;

  const AddClassPage({super.key, required this.onSave});

  @override
  AddClassPageState createState() => AddClassPageState();
}

class AddClassPageState extends State<AddClassPage> {
  final _nameController = TextEditingController();
  final _hdController = TextEditingController();
  final _proficiencyController = TextEditingController();
  final _numSkillsController = TextEditingController();
  final Map<int, List<FeatureData>> _featuresByLevel = {};
  final Map<int, Slots> _slotsByLevel = {};

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

  void _saveClass() {
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
      proficiency: _proficiencyController.text,
      numSkills: _numSkillsController.text,
      autolevels: autolevels,
    );

    widget.onSave(classData);
    Navigator.pop(context);
  }

  Widget _buildLevels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
<<<<<<< HEAD
      children: List.generate(20, (index) {
        final level = index + 1;
        return Card(
          color: AppColors.cardColor,
          elevation: 4.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            title: Text(
              'Level $level',
              style: TextStyle(
                color: AppColors.textColorLight,
=======
      children: [
        Row(
          children: [
            const Text(
              'Autolevels',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              onPressed: _addAutolevel,
              icon: const Icon(Icons.add),
              tooltip: 'Add Autolevel',
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var autolevel in _autolevels) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Card(
              color: AppColors.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level: ${autolevel.level}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (autolevel.slots != null)
                            Text('Slots: ${autolevel.slots!.slots.join(', ')}'),
                          for (var feature in autolevel.features)
                            Text('- ${feature.name}'),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteAutolevel(autolevel),
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete Autolevel',
                    ),
                  ],
                ),
>>>>>>> 31b1db7b19c2173dacb5692f5645304edae5dc1d
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
            onTap: () => _editLevel(level),
            trailing: SizedBox(
              width: 35,
              height: 35,
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Class'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveClass,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _hdController,
              decoration: InputDecoration(labelText: 'HD'),
            ),
            TextField(
              controller: _proficiencyController,
              decoration: InputDecoration(labelText: 'Proficiency'),
            ),
            TextField(
              controller: _numSkillsController,
              decoration: InputDecoration(labelText: 'Number of Skills'),
            ),
            const SizedBox(height: 20),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Level ${widget.level}'),
        actions: [
          IconButton(
            onPressed: _saveLevel,
            icon: Icon(Icons.save),
            tooltip: 'Save Level',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Zauberplätze',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              itemCount: 10,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 5,
                mainAxisSpacing: 1,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                return TextField(
                  controller: _slotControllers[index],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: (index == 0) ? 'Zaubertrick' : '$index',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _editFeature(),
              child: Text('Add Feature'),
            ),
            ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: _features.map((feature) {
                return Card(
                  color: AppColors.cardColor,
                  elevation: 4.0,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(
                      feature.name,
                      style: TextStyle(color: AppColors.textColorLight),
                    ),
                    subtitle: Text(
                      feature.description,
                      style: TextStyle(
                          color: AppColors.textColorLight.withOpacity(0.7)),
                    ),
                    onTap: () => _editFeature(feature: feature),
                    trailing: SizedBox(
                      width: 35,
                      height: 35,
                      child: IconButton(
                        icon: Icon(Icons.close, color: AppColors.textColorDark),
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
    return AlertDialog(
      title: Text(widget.feature == null ? 'Add Feature' : 'Edit Feature'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveFeature,
          child: Text('Save'),
        ),
      ],
    );
  }
}
