import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:dnd/configs/colours.dart';

class AddSpellPage extends StatefulWidget {
  final Future<void> Function(SpellData) onSave;
  final SpellData? existingSpell;

  const AddSpellPage({super.key, required this.onSave, this.existingSpell});

  @override
  AddSpellPageState createState() => AddSpellPageState();
}

class AddSpellPageState extends State<AddSpellPage> {
  final _nameController = TextEditingController();
  final _levelController = TextEditingController();
  final _schoolController = TextEditingController();
  final _ritualController = TextEditingController();
  final _timeController = TextEditingController();
  final _rangeController = TextEditingController();
  final _componentsController = TextEditingController();
  final _durationController = TextEditingController();
  final _textController = TextEditingController();
  final List<String> _classes = [];
  final _classInputController = TextEditingController();

  String _selectedLevel = '0';

  @override
  void initState() {
    super.initState();
    if (widget.existingSpell != null) {
      _loadExistingSpell();
    }
  }

  void _loadExistingSpell() {
    final spell = widget.existingSpell!;
    _nameController.text = spell.name;
    _levelController.text = spell.level;
    _selectedLevel = spell.level;
    _schoolController.text = spell.school;
    _ritualController.text = spell.ritual;
    _timeController.text = spell.time;
    _rangeController.text = spell.range;
    _componentsController.text = spell.components;
    _durationController.text = spell.duration;
    _textController.text = spell.text;
    _classes.addAll(spell.classes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _levelController.dispose();
    _schoolController.dispose();
    _ritualController.dispose();
    _timeController.dispose();
    _rangeController.dispose();
    _componentsController.dispose();
    _durationController.dispose();
    _textController.dispose();
    _classInputController.dispose();
    super.dispose();
  }

  void _addClass() {
    final className = _classInputController.text.trim();
    if (className.isNotEmpty && !_classes.contains(className)) {
      setState(() {
        _classes.add(className);
        _classInputController.clear();
      });
    }
  }

  Future<void> _saveSpell() async {
    final spellData = SpellData(
      name: _nameController.text.trim(),
      classes: _classes,
      level: _selectedLevel,
      school: _schoolController.text.trim(),
      ritual: _ritualController.text.trim(),
      time: _timeController.text.trim(),
      range: _rangeController.text.trim(),
      components: _componentsController.text.trim(),
      duration: _durationController.text.trim(),
      text: _textController.text.trim(),
    );

    await widget.onSave(spellData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addSpellWiki),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSpell,
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
                      loc.spells,
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
                          child: DropdownButtonFormField<String>(
                            value: _selectedLevel,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: loc.level,
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                            items: [
                              DropdownMenuItem(value: '0', child: Text('0 (${loc.cantrip})')),
                              DropdownMenuItem(value: '1', child: Text('1')),
                              DropdownMenuItem(value: '2', child: Text('2')),
                              DropdownMenuItem(value: '3', child: Text('3')),
                              DropdownMenuItem(value: '4', child: Text('4')),
                              DropdownMenuItem(value: '5', child: Text('5')),
                              DropdownMenuItem(value: '6', child: Text('6')),
                              DropdownMenuItem(value: '7', child: Text('7')),
                              DropdownMenuItem(value: '8', child: Text('8')),
                              DropdownMenuItem(value: '9', child: Text('9')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedLevel = value ?? '0';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _schoolController,
                            decoration: InputDecoration(
                              labelText: loc.school,
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
                            controller: _ritualController,
                            decoration: InputDecoration(
                              labelText: loc.ritual,
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _timeController,
                            decoration: InputDecoration(
                              labelText: loc.castingtime,
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
                            controller: _rangeController,
                            decoration: InputDecoration(
                              labelText: loc.range,
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _componentsController,
                            decoration: InputDecoration(
                              labelText: loc.components,
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _durationController,
                      decoration: InputDecoration(
                        labelText: loc.duration,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: loc.description,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                      maxLines: 8,
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
                    Text(
                      loc.classesKey,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _classInputController,
                            decoration: InputDecoration(
                              labelText: loc.classesKey,
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.add, color: AppColors.accentTeal),
                          onPressed: _addClass,
                          tooltip: loc.add,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      children: _classes.map((className) {
                        return Chip(
                          label: Text(className),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () {
                            setState(() {
                              _classes.remove(className);
                            });
                          },
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
