import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:dnd/configs/colours.dart';

class AddCreaturePage extends StatefulWidget {
  final Future<void> Function(Creature) onSave;
  final Creature? existingCreature;

  const AddCreaturePage({super.key, required this.onSave, this.existingCreature});

  @override
  AddCreaturePageState createState() => AddCreaturePageState();
}

class AddCreaturePageState extends State<AddCreaturePage> {
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController();
  final _typeController = TextEditingController();
  final _alignmentController = TextEditingController();
  final _acController = TextEditingController();
  final _hpController = TextEditingController();
  final _speedController = TextEditingController();
  final _strController = TextEditingController();
  final _dexController = TextEditingController();
  final _conController = TextEditingController();
  final _intController = TextEditingController();
  final _wisController = TextEditingController();
  final _chaController = TextEditingController();
  final _savesController = TextEditingController();
  final _skillsController = TextEditingController();
  final _resistancesController = TextEditingController();
  final _vulnerabilitiesController = TextEditingController();
  final _immunitiesController = TextEditingController();
  final _conditionImmunitiesController = TextEditingController();
  final _sensesController = TextEditingController();
  final _languagesController = TextEditingController();
  final _crController = TextEditingController();

  final List<Trait> _traits = [];
  final List<CAction> _actions = [];
  final List<Legendary> _legendaryActions = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingCreature != null) {
      _loadExistingCreature();
    }
  }

  void _loadExistingCreature() {
    final creature = widget.existingCreature!;
    _nameController.text = creature.name;
    _sizeController.text = creature.size;
    _typeController.text = creature.type;
    _alignmentController.text = creature.alignment;
    _acController.text = creature.ac.toString();
    _hpController.text = creature.maxHP.toString();
    _speedController.text = creature.speed;
    _strController.text = creature.str.toString();
    _dexController.text = creature.dex.toString();
    _conController.text = creature.con.toString();
    _intController.text = creature.intScore.toString();
    _wisController.text = creature.wis.toString();
    _chaController.text = creature.cha.toString();
    _savesController.text = creature.saves;
    _skillsController.text = creature.skills;
    _resistancesController.text = creature.resistances;
    _vulnerabilitiesController.text = creature.vulnerabilities;
    _immunitiesController.text = creature.immunities;
    _conditionImmunitiesController.text = creature.conditionImmunities;
    _sensesController.text = creature.senses;
    _languagesController.text = creature.languages;
    _crController.text = creature.cr;
    _traits.addAll(creature.traits);
    _actions.addAll(creature.actions);
    _legendaryActions.addAll(creature.legendaryActions);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _typeController.dispose();
    _alignmentController.dispose();
    _acController.dispose();
    _hpController.dispose();
    _speedController.dispose();
    _strController.dispose();
    _dexController.dispose();
    _conController.dispose();
    _intController.dispose();
    _wisController.dispose();
    _chaController.dispose();
    _savesController.dispose();
    _skillsController.dispose();
    _resistancesController.dispose();
    _vulnerabilitiesController.dispose();
    _immunitiesController.dispose();
    _conditionImmunitiesController.dispose();
    _sensesController.dispose();
    _languagesController.dispose();
    _crController.dispose();
    super.dispose();
  }

  void _addTrait() async {
    final trait = await showDialog<Trait>(
      context: context,
      builder: (context) => TraitDialog(),
    );
    if (trait != null) {
      setState(() => _traits.add(trait));
    }
  }

  void _addAction() async {
    final action = await showDialog<CAction>(
      context: context,
      builder: (context) => ActionDialog(),
    );
    if (action != null) {
      setState(() => _actions.add(action));
    }
  }

  void _addLegendaryAction() async {
    final legendary = await showDialog<Legendary>(
      context: context,
      builder: (context) => LegendaryDialog(),
    );
    if (legendary != null) {
      setState(() => _legendaryActions.add(legendary));
    }
  }

  Future<void> _saveCreature() async {
    final creature = Creature(
      name: _nameController.text.trim(),
      size: _sizeController.text.trim(),
      type: _typeController.text.trim(),
      alignment: _alignmentController.text.trim(),
      ac: int.tryParse(_acController.text.trim()) ?? 0,
      maxHP: int.tryParse(_hpController.text.trim()) ?? 0,
      currentHP: int.tryParse(_hpController.text.trim()) ?? 0,
      speed: _speedController.text.trim(),
      str: int.tryParse(_strController.text.trim()) ?? 10,
      dex: int.tryParse(_dexController.text.trim()) ?? 10,
      con: int.tryParse(_conController.text.trim()) ?? 10,
      intScore: int.tryParse(_intController.text.trim()) ?? 10,
      wis: int.tryParse(_wisController.text.trim()) ?? 10,
      cha: int.tryParse(_chaController.text.trim()) ?? 10,
      saves: _savesController.text.trim(),
      skills: _skillsController.text.trim(),
      resistances: _resistancesController.text.trim(),
      vulnerabilities: _vulnerabilitiesController.text.trim(),
      immunities: _immunitiesController.text.trim(),
      conditionImmunities: _conditionImmunitiesController.text.trim(),
      senses: _sensesController.text.trim(),
      passivePerception: 10,
      languages: _languagesController.text.trim(),
      cr: _crController.text.trim(),
      traits: _traits,
      actions: _actions,
      legendaryActions: _legendaryActions,
    );

    await widget.onSave(creature);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addMonster),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveCreature,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.basicInfo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorLight,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.name,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sizeController,
                            decoration: InputDecoration(
                              labelText: loc.size,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _typeController,
                            decoration: InputDecoration(
                              labelText: loc.type,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _alignmentController,
                      decoration: InputDecoration(
                        labelText: loc.alignment,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.combatStats,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorLight,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _acController,
                            decoration: InputDecoration(
                              labelText: loc.ac,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _hpController,
                            decoration: InputDecoration(
                              labelText: loc.hp,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _crController,
                            decoration: InputDecoration(
                              labelText: loc.cr,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _speedController,
                      decoration: InputDecoration(
                        labelText: loc.speed,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.abilityScores,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorLight,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _strController,
                            decoration: InputDecoration(
                              labelText: loc.str,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _dexController,
                            decoration: InputDecoration(
                              labelText: loc.dex,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _conController,
                            decoration: InputDecoration(
                              labelText: loc.con,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _intController,
                            decoration: InputDecoration(
                              labelText: loc.int,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _wisController,
                            decoration: InputDecoration(
                              labelText: loc.wis,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _chaController,
                            decoration: InputDecoration(
                              labelText: loc.cha,
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppColors.primaryColor,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.otherStats,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorLight,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _savesController,
                      decoration: InputDecoration(
                        labelText: loc.savesOptional,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _skillsController,
                      decoration: InputDecoration(
                        labelText: loc.skillsOptional,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _resistancesController,
                      decoration: InputDecoration(
                        labelText: loc.resistancesOptional,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _vulnerabilitiesController,
                      decoration: InputDecoration(
                        labelText: loc.vulnerabilitiesOptional,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _immunitiesController,
                      decoration: InputDecoration(
                        labelText: loc.immunitiesOptional,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _conditionImmunitiesController,
                      decoration: InputDecoration(
                        labelText: loc.conditionImmunitiesOptional,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _sensesController,
                      decoration: InputDecoration(
                        labelText: loc.sensesOptional,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _languagesController,
                      decoration: InputDecoration(
                        labelText: loc.languagesOptional,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildListSection(loc.traits, _traits.length, _addTrait, () {
              return _traits
                  .map((t) => ListTile(
                        title: Text(t.name),
                        subtitle: Text(t.description, maxLines: 2),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => setState(() => _traits.remove(t)),
                        ),
                      ))
                  .toList();
            }, loc),
            SizedBox(height: 20),
            _buildListSection(loc.actions, _actions.length, _addAction, () {
              return _actions
                  .map((a) => ListTile(
                        title: Text(a.name),
                        subtitle: Text(a.description, maxLines: 2),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => setState(() => _actions.remove(a)),
                        ),
                      ))
                  .toList();
            }, loc),
            SizedBox(height: 20),
            _buildListSection(loc.legendaryActions, _legendaryActions.length,
                _addLegendaryAction, () {
              return _legendaryActions
                  .map((l) => ListTile(
                        title: Text(l.name),
                        subtitle: Text(l.description, maxLines: 2),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () =>
                              setState(() => _legendaryActions.remove(l)),
                        ),
                      ))
                  .toList();
            }, loc),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(String title, int count, VoidCallback onAdd,
      List<Widget> Function() buildItems, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$title ($count)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                foregroundColor: Colors.white,
              ),
              icon: Icon(Icons.add),
              label: Text(loc.add),
            ),
          ],
        ),
        SizedBox(height: 10),
        ...buildItems(),
      ],
    );
  }
}

class TraitDialog extends StatefulWidget {
  const TraitDialog({super.key});

  @override
  State<TraitDialog> createState() => _TraitDialogState();
}

class _TraitDialogState extends State<TraitDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.addTrait),
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
            controller: _descController,
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
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textColorDark),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty &&
                _descController.text.trim().isNotEmpty) {
              Navigator.pop(
                context,
                Trait(
                  name: _nameController.text.trim(),
                  description: _descController.text.trim(),
                ),
              );
            }
          },
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

class ActionDialog extends StatefulWidget {
  const ActionDialog({super.key});

  @override
  State<ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<ActionDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _attackController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _attackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.addaction),
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
              controller: _descController,
              decoration: InputDecoration(
                labelText: loc.description,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _attackController,
              decoration: InputDecoration(
                labelText: loc.attack,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textColorDark),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty &&
                _descController.text.trim().isNotEmpty) {
              Navigator.pop(
                context,
                CAction(
                  name: _nameController.text.trim(),
                  description: _descController.text.trim(),
                  attack: _attackController.text.trim(),
                ),
              );
            }
          },
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

class LegendaryDialog extends StatefulWidget {
  const LegendaryDialog({super.key});

  @override
  State<LegendaryDialog> createState() => _LegendaryDialogState();
}

class _LegendaryDialogState extends State<LegendaryDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.addlegendaryaction),
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
            controller: _descController,
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
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textColorDark),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty &&
                _descController.text.trim().isNotEmpty) {
              Navigator.pop(
                context,
                Legendary(
                  name: _nameController.text.trim(),
                  description: _descController.text.trim(),
                ),
              );
            }
          },
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
