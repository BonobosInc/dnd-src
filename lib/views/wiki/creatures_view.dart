import 'package:dnd/configs/colours.dart';
import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';

class AllCreaturesPage extends StatefulWidget {
  final List<Creature> creatures;
  final bool importCreature;

  const AllCreaturesPage({
    super.key,
    required this.creatures,
    this.importCreature = false,
  });

  @override
  AllCreaturesPageState createState() => AllCreaturesPageState();
}

class AllCreaturesPageState extends State<AllCreaturesPage> {
  final Set<Creature> _selectedCreatures = {};
  String _searchText = '';
  bool _sortByCr = true;
  String? _selectedCr;
  late List<Creature> _filteredCreaturesCache;
  late List<String> _uniqueCRs;

  bool isSearchVisible = false;
  late String _activeFilter;
  FocusNode searchFocusNode = FocusNode();
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCreaturesCache = _computeFilteredCreatures();
    _uniqueCRs = _getUniqueCRs();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = AppLocalizations.of(context)!;

      setState(() {
        _activeFilter = loc.sortbycr;
      });
    });
  }

  @override
  void dispose() {
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AllCreaturesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.creatures != widget.creatures ||
        _searchText != _searchText ||
        _sortByCr != _sortByCr ||
        _selectedCr != _selectedCr) {
      _filteredCreaturesCache = _computeFilteredCreatures();
    }
  }

  List<String> _getUniqueCRs() {
    Set<String> crSet = {};
    for (var creature in widget.creatures) {
      crSet.add(creature.cr);
    }

    List<String> crList = crSet.toList();
    crList.sort((a, b) {
      return parseCr(a).compareTo(parseCr(b));
    });

    return crList;
  }

  double parseCr(String cr) {
    try {
      if (cr.contains('/')) {
        var parts = cr.split('/');
        return double.parse(parts[0]) / double.parse(parts[1]);
      } else {
        return double.parse(cr);
      }
    } catch (e) {
      return double.infinity;
    }
  }

  List<Creature> _computeFilteredCreatures() {
    List<Creature> filteredList = widget.creatures
        .where((creature) =>
            creature.name.toLowerCase().contains(_searchText.toLowerCase()) &&
            (_selectedCr == null || creature.cr == _selectedCr))
        .toList();

    if (_sortByCr) {
      filteredList.sort((a, b) {
        return parseCr(a.cr).compareTo(parseCr(b.cr));
      });
    } else {
      filteredList.sort((a, b) => a.name.compareTo(b.name));
    }

    return filteredList;
  }

  void _onCreatureSelected(Creature creature, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedCreatures.add(creature);
      } else {
        _selectedCreatures.remove(creature);
      }
    });
  }

  void _navigateToCreatureDetail(Creature creature) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatureDetailPage(
          creature: creature,
          importCreature: widget.importCreature,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: isSearchVisible
            ? TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                decoration: InputDecoration(
                  hintText: '${loc.search}...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                    _filteredCreaturesCache = _computeFilteredCreatures();
                  });
                },
              )
            : Text(loc.allmonster),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                isSearchVisible = !isSearchVisible;
                if (isSearchVisible) {
                  searchFocusNode.requestFocus();
                } else {
                  _searchText = '';
                  searchController.clear();
                  searchFocusNode.unfocus();
                  _filteredCreaturesCache = _computeFilteredCreatures();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: loc.filterandsort,
            onSelected: (value) {
              setState(() {
                _activeFilter = value;
                if (_activeFilter == loc.sortbycr) {
                  _sortByCr = true;
                  _selectedCr = null;
                } else if (_activeFilter == loc.sortbyname) {
                  _sortByCr = false;
                  _selectedCr = null;
                } else {
                  _sortByCr = true;
                  _selectedCr = _activeFilter;
                }
                _filteredCreaturesCache = _computeFilteredCreatures();
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: loc.sortbycr,
                child: Row(
                  children: [
                    if (_activeFilter == loc.sortbycr)
                      const Icon(Icons.check, size: 18, color: Colors.blue),
                    Text(loc.sortbycr),
                  ],
                ),
              ),
              PopupMenuItem(
                value: loc.sortbyname,
                child: Row(
                  children: [
                    if (_activeFilter == loc.sortbyname)
                      const Icon(Icons.check, size: 18, color: Colors.blue),
                    Text(loc.sortbyname),
                  ],
                ),
              ),
              ..._uniqueCRs.map(
                (cr) => PopupMenuItem(
                  value: cr,
                  child: Row(
                    children: [
                      if (_activeFilter == cr)
                        const Icon(Icons.check, size: 18, color: Colors.blue),
                      Text('CR: $cr'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (widget.importCreature)
            IconButton(
              tooltip: loc.importselectedcompanion,
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop(_selectedCreatures.toList());
              },
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCreaturesCache.length,
              itemBuilder: (context, index) {
                final creature = _filteredCreaturesCache[index];
                return ListTile(
                  title: Text(creature.name),
                  subtitle: Text('CR: ${creature.cr}'),
                  trailing: widget.importCreature
                      ? GestureDetector(
                          onTap: () {
                            _navigateToCreatureDetail(creature);
                          },
                          child: Checkbox(
                            value: _selectedCreatures.contains(creature),
                            onChanged: (isSelected) {
                              _onCreatureSelected(creature, isSelected!);
                            },
                          ),
                        )
                      : null,
                  onTap: () {
                    _navigateToCreatureDetail(creature);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.importCreature
          ? FloatingActionButton(
              tooltip: loc.createnewcompanion,
              onPressed: () async {
                final newCreature = await _showAddCreatureDialog(context);
                if (newCreature != null && context.mounted) {
                  Navigator.of(context).pop(newCreature);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<Creature?> _showAddCreatureDialog(BuildContext context) async {
    return await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateCreaturePage(),
      ),
    );
  }
}

class CreateCreaturePage extends StatefulWidget {
  final Creature? creature;
  final bool statsMenu;

  const CreateCreaturePage({super.key, this.creature, this.statsMenu = false});

  @override
  CreateCreaturePageState createState() => CreateCreaturePageState();
}

class CreateCreaturePageState extends State<CreateCreaturePage> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.creature?.name ?? '');
  late final TextEditingController _sizeController =
      TextEditingController(text: widget.creature?.size ?? '');
  late final TextEditingController _typeController =
      TextEditingController(text: widget.creature?.type ?? '');
  late final TextEditingController _alignmentController =
      TextEditingController(text: widget.creature?.alignment ?? '');
  late final TextEditingController _acController =
      TextEditingController(text: widget.creature?.ac.toString() ?? '');
  late final TextEditingController _hpController =
      TextEditingController(text: widget.creature?.maxHP.toString() ?? '');
  late final TextEditingController _speedController =
      TextEditingController(text: widget.creature?.speed ?? '');
  late final TextEditingController _crController =
      TextEditingController(text: widget.creature?.cr ?? '');
  late final TextEditingController _strController =
      TextEditingController(text: widget.creature?.str.toString() ?? '');
  late final TextEditingController _dexController =
      TextEditingController(text: widget.creature?.dex.toString() ?? '');
  late final TextEditingController _conController =
      TextEditingController(text: widget.creature?.con.toString() ?? '');
  late final TextEditingController _intController =
      TextEditingController(text: widget.creature?.intScore.toString() ?? '');
  late final TextEditingController _wisController =
      TextEditingController(text: widget.creature?.wis.toString() ?? '');
  late final TextEditingController _chaController =
      TextEditingController(text: widget.creature?.cha.toString() ?? '');
  late final TextEditingController _savesController =
      TextEditingController(text: widget.creature?.saves ?? '');
  late final TextEditingController _skillsController =
      TextEditingController(text: widget.creature?.skills ?? '');
  late final TextEditingController _resistancesController =
      TextEditingController(text: widget.creature?.resistances ?? '');
  late final TextEditingController _vulnerabilitiesController =
      TextEditingController(text: widget.creature?.vulnerabilities ?? '');
  late final TextEditingController _immunitiesController =
      TextEditingController(text: widget.creature?.immunities ?? '');
  late final TextEditingController _conditionImmunitiesController =
      TextEditingController(text: widget.creature?.conditionImmunities ?? '');
  late final TextEditingController _sensesController =
      TextEditingController(text: widget.creature?.senses ?? '');
  late final TextEditingController _passivePerceptionController =
      TextEditingController(
          text: widget.creature?.passivePerception.toString() ?? '');
  late final TextEditingController _languagesController =
      TextEditingController(text: widget.creature?.languages ?? '');

  late List<Trait> _traits;
  late List<CAction> _actions;
  late List<Legendary> _legendaryActions;

  @override
  void initState() {
    super.initState();

    _traits = widget.creature?.traits ?? [];
    _actions = widget.creature?.actions ?? [];
    _legendaryActions = widget.creature?.legendaryActions ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.editcompanion),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              final newCreature = Creature(
                name: _nameController.text,
                size: _sizeController.text,
                type: _typeController.text,
                alignment: _alignmentController.text,
                ac: int.tryParse(_acController.text) ?? 0,
                maxHP: int.tryParse(_hpController.text) ?? 0,
                currentHP: (widget.creature?.currentHP ?? 0) == 0
                    ? int.tryParse(_hpController.text) ?? 0
                    : widget.creature?.currentHP ?? 0,
                speed: _speedController.text,
                str: int.tryParse(_strController.text) ?? 0,
                dex: int.tryParse(_dexController.text) ?? 0,
                con: int.tryParse(_conController.text) ?? 0,
                intScore: int.tryParse(_intController.text) ?? 0,
                wis: int.tryParse(_wisController.text) ?? 0,
                cha: int.tryParse(_chaController.text) ?? 0,
                saves: _savesController.text,
                skills: _skillsController.text,
                resistances: _resistancesController.text,
                vulnerabilities: _vulnerabilitiesController.text,
                immunities: _immunitiesController.text,
                conditionImmunities: _conditionImmunitiesController.text,
                senses: _sensesController.text,
                passivePerception:
                    int.tryParse(_passivePerceptionController.text) ?? 0,
                languages: _languagesController.text,
                cr: _crController.text,
                traits: _traits,
                actions: _actions,
                legendaryActions: _legendaryActions,
                uuid: widget.statsMenu ? (widget.creature?.uuid ?? 0) : 0,
              );

              Navigator.of(context).pop(newCreature);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: loc.name),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _sizeController,
                      decoration: InputDecoration(labelText: loc.size),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _typeController,
                      decoration: InputDecoration(labelText: loc.type),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _alignmentController,
                      decoration: InputDecoration(labelText: loc.alignment),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _acController,
                      decoration: InputDecoration(
                          labelText: loc.ac),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _hpController,
                      decoration:
                          InputDecoration(labelText: loc.hp),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _speedController,
                      decoration:
                          InputDecoration(labelText: loc.movement),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _crController,
                      decoration: InputDecoration(
                          labelText: loc.cr),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _strController,
                      decoration: InputDecoration(labelText: loc.strength),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _dexController,
                      decoration: InputDecoration(labelText: loc.dexterity),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _conController,
                      decoration: InputDecoration(labelText: loc.constitution),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _intController,
                      decoration: InputDecoration(labelText: loc.intelligence),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _wisController,
                      decoration: InputDecoration(labelText: loc.wisdom),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _chaController,
                      decoration: InputDecoration(labelText: loc.charisma),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _savesController,
                      decoration: InputDecoration(labelText: loc.savingThrows),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _skillsController,
                      decoration: InputDecoration(labelText: loc.skills),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _resistancesController,
                      decoration: InputDecoration(labelText: loc.resistances),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _vulnerabilitiesController,
                      decoration: InputDecoration(labelText: loc.vulnerabilities),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _immunitiesController,
                      decoration: InputDecoration(labelText: loc.immunities),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _conditionImmunitiesController,
                      decoration: InputDecoration(
                          labelText: loc.conditionImmunities),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sensesController,
                      decoration: InputDecoration(labelText: loc.senses),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _passivePerceptionController,
                      decoration: InputDecoration(
                          labelText: loc.passivePerception),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _languagesController,
                      decoration: InputDecoration(labelText: loc.languages),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTraitSection(),
              const Divider(color: Colors.grey, thickness: 1.5),
              const SizedBox(height: 10),
              _buildCActionSection(),
              const Divider(color: Colors.grey, thickness: 1.5),
              const SizedBox(height: 10),
              _buildLegendaryActionSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTraitSection() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              loc.feats,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                _showTraitDialog(context);
              },
              icon: const Icon(Icons.add),
              tooltip: loc.addtraits,
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var trait in _traits) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GestureDetector(
              onTap: () {
                _showEditDialog(context, trait, 'trait');
              },
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
                              trait.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _showDeleteConfirmationDialog(trait, 'trait');
                        },
                        icon: const Icon(Icons.delete),
                        tooltip: loc.delete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCActionSection() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              loc.action,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                _showCActionDialog(context);
              },
              icon: const Icon(Icons.add),
              tooltip: loc.addaction,
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var action in _actions) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GestureDetector(
              onTap: () {
                _showEditDialog(context, action, 'action');
              },
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
                              action.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _showDeleteConfirmationDialog(action, 'action');
                        },
                        icon: const Icon(Icons.delete),
                        tooltip: loc.delete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegendaryActionSection() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              loc.legendaryaction,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                _showLegendaryActionDialog(context);
              },
              icon: const Icon(Icons.add),
              tooltip: loc.addlegendaryaction,
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var legendary in _legendaryActions) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GestureDetector(
              onTap: () {
                _showEditDialog(context, legendary, 'legendary');
              },
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
                              legendary.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _showDeleteConfirmationDialog(legendary, 'legendary');
                        },
                        icon: const Icon(Icons.delete),
                        tooltip: loc.delete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildDescriptionTextField(TextEditingController controller) {
    final loc = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: loc.description,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _showTraitDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final traitNameController = TextEditingController();
    final traitDescriptionController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.editFeat),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildTextField(
                  label: loc.feat,
                  controller: traitNameController,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                _buildDescriptionTextField(traitDescriptionController),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.delete),
            ),
            TextButton(
              onPressed: () {
                if (traitNameController.text.isNotEmpty &&
                    traitDescriptionController.text.isNotEmpty) {
                  setState(() {
                    _traits.add(Trait(
                      name: traitNameController.text,
                      description: traitDescriptionController.text,
                    ));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCActionDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final cActionNameController = TextEditingController();
    final cActionDescriptionController = TextEditingController();
    final cActionAttackController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.editattack),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildTextField(
                  label: loc.attack,
                  controller: cActionNameController,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                _buildDescriptionTextField(cActionDescriptionController),
                const SizedBox(height: 16),
                _buildTextField(
                  label: loc.attackvalue,
                  controller: cActionAttackController,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.abort),
            ),
            TextButton(
              onPressed: () {
                if (cActionNameController.text.isNotEmpty &&
                    cActionDescriptionController.text.isNotEmpty) {
                  setState(() {
                    _actions.add(CAction(
                      name: cActionNameController.text,
                      description: cActionDescriptionController.text,
                      attack: cActionAttackController.text.isNotEmpty
                          ? cActionAttackController.text
                          : null,
                    ));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLegendaryActionDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final legendaryActionNameController = TextEditingController();
    final legendaryActionDescriptionController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.editlegendaryaction),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildTextField(
                  label: loc.legendaryaction,
                  controller: legendaryActionNameController,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                _buildDescriptionTextField(
                    legendaryActionDescriptionController),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.abort),
            ),
            TextButton(
              onPressed: () {
                if (legendaryActionNameController.text.isNotEmpty &&
                    legendaryActionDescriptionController.text.isNotEmpty) {
                  setState(() {
                    _legendaryActions.add(Legendary(
                      name: legendaryActionNameController.text,
                      description: legendaryActionDescriptionController.text,
                    ));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(dynamic item, String type) async {
    final loc = AppLocalizations.of(context)!;
    final String itemName = item is Trait
        ? item.name
        : item is CAction
            ? item.name
            : (item as Legendary).name;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${loc.delete} $type'),
          content: Text(loc.confirmItemDelete(itemName)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.abort),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (type == 'trait') {
                    _traits.remove(item);
                  } else if (type == 'action') {
                    _actions.remove(item);
                  } else {
                    _legendaryActions.remove(item);
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text(loc.delete),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, dynamic item, String type) async {
    final loc = AppLocalizations.of(context)!;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String attackControllerText = '';

    if (item is Trait) {
      nameController.text = item.name;
      descriptionController.text = item.description;
    } else if (item is CAction) {
      nameController.text = item.name;
      descriptionController.text = item.description;
      attackControllerText = item.attack ?? '';
    } else if (item is Legendary) {
      nameController.text = item.name;
      descriptionController.text = item.description;
    }

    String dialogTitle = '';
    String nameLabel = '';
    String attackLabel = '';

    if (type == 'trait') {
      dialogTitle = loc.editFeat;
      nameLabel = loc.feat;
    } else if (type == 'action') {
      dialogTitle = loc.editattack;
      nameLabel = loc.attack;
      attackLabel = loc.attackvalue;
    } else if (type == 'legendary') {
      dialogTitle = loc.editlegendaryaction;
      nameLabel = loc.legendaryaction;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildTextField(
                  label: nameLabel,
                  controller: nameController,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                _buildDescriptionTextField(descriptionController),
                const SizedBox(height: 16),
                if (type == 'action')
                  _buildTextField(
                    label: attackLabel,
                    controller:
                        TextEditingController(text: attackControllerText),
                    onChanged: (value) {
                      attackControllerText = value;
                    },
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.abort),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  setState(() {
                    if (type == 'trait') {
                      item.name = nameController.text;
                      item.description = descriptionController.text;
                    } else if (type == 'action') {
                      item.name = nameController.text;
                      item.description = descriptionController.text;
                      item.attack = attackControllerText.isNotEmpty
                          ? attackControllerText
                          : null;
                    } else if (type == 'legendary') {
                      item.name = nameController.text;
                      item.description = descriptionController.text;
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }
}

class CreatureDetailPage extends StatelessWidget {
  final Creature creature;
  final bool importCreature;
  final bool statsMenu;

  const CreatureDetailPage({
    super.key,
    required this.creature,
    this.importCreature = false,
    this.statsMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(creature.name),
        actions: [
          if (statsMenu)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updatedCreature = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateCreaturePage(
                      creature: creature,
                      statsMenu: statsMenu,
                    ),
                  ),
                );

                if (updatedCreature != null && context.mounted) {
                  Navigator.of(context).pop(updatedCreature);
                }
              },
            ),
          if (importCreature)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final newCreature =
                    await _showAddCreatureDialog(context, creature);
                if (newCreature != null && context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(newCreature);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSizeAlignmentSection(loc),
            const Divider(),
            _buildArmorHitpointsSpeedSection(loc),
            const Divider(),
            _buildStatsSection(loc),
            const Divider(),
            _buildSavingThrowsSection(loc),
            const Divider(),
            _buildSensesLanguagesCrSection(loc),
            const Divider(),
            _buildTraitsSection(loc),
            const Divider(),
            _buildActionsSection(loc),
            const Divider(),
            _buildLegendaryActionsSection(loc),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeAlignmentSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${loc.size}: ${creature.size}'),
        Text('${loc.type}: ${creature.type}'),
        Text('${loc.alignment}: ${creature.alignment}'),
      ],
    );
  }

  Widget _buildArmorHitpointsSpeedSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${loc.ac}: ${creature.ac}'),
        Text('${loc.hp}: ${creature.maxHP}'),
        Text('${loc.movement}: ${creature.speed}'),
      ],
    );
  }

  Widget _buildStatsSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatRow('STR', creature.str),
        _buildStatRow('DEX', creature.dex),
        _buildStatRow('CON', creature.con),
        _buildStatRow('INT', creature.intScore),
        _buildStatRow('WIS', creature.wis),
        _buildStatRow('CHA', creature.cha),
      ],
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value.toString()),
      ],
    );
  }

  Widget _buildSavingThrowsSection(AppLocalizations loc) {
    return Text(
        '${loc.savingThrows}: ${creature.saves.isNotEmpty ? creature.saves : 'None'}');
  }

  Widget _buildSensesLanguagesCrSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${loc.senses}: ${creature.senses.isNotEmpty ? creature.senses : 'None'}'),
        Text(
            '${loc.languages}: ${creature.languages.isNotEmpty ? creature.languages : 'None'}'),
        Text(
            '${loc.cr}: ${creature.cr.isNotEmpty ? creature.cr : 'N/A'}'),
      ],
    );
  }

  Widget _buildTraitsSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.feats,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (creature.traits.isEmpty) const Text('None'),
        ...creature.traits.map((trait) => _buildTrait(trait)),
      ],
    );
  }

  Widget _buildTrait(Trait trait) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trait.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(trait.description),
        ],
      ),
    );
  }

  Widget _buildActionsSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${loc.actions}:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (creature.actions.isEmpty) const Text('None'),
        ...creature.actions.map((action) => _buildAction(action)),
      ],
    );
  }

  Widget _buildAction(CAction action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            action.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(action.description),
          if (action.attack != null && action.attack!.isNotEmpty)
            Text('Angriff: ${action.attack}'),
        ],
      ),
    );
  }

  Widget _buildLegendaryActionsSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.legendaryaction,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (creature.legendaryActions.isEmpty) const Text('None'),
        ...creature.legendaryActions
            .map((legendary) => _buildLegendaryAction(legendary)),
      ],
    );
  }

  Widget _buildLegendaryAction(Legendary legendary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(legendary.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(legendary.description),
        ],
      ),
    );
  }

  Future<Creature?> _showAddCreatureDialog(
      BuildContext context, Creature creature) async {
    final loc = AppLocalizations.of(context)!;
    return showDialog<Creature?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.addcompanion),
          content: Text(loc.addcompanionConfirmation(creature.name)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.no),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(creature);
              },
              child: Text(loc.yes),
            ),
          ],
        );
      },
    );
  }
}
