import 'package:dnd/configs/colours.dart';
import 'package:dnd/configs/defines.dart';
import 'package:dnd/views/spell_editing_view.dart';
import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';

class SpellDetailPage extends StatelessWidget {
  final SpellData spellData;
  final bool importspell;
  final Function(SpellData)? onEdit;
  final Function(String)? onDelete;

  const SpellDetailPage({
    super.key,
    required this.spellData,
    this.importspell = false,
    this.onEdit,
    this.onDelete,
  });

  String getSchoolFullName(String abbreviation, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (abbreviation) {
      case 'T':
        return loc.schoolTransmutation;
      case 'D':
        return loc.schoolDivination;
      case 'EV':
        return loc.schoolEvocation;
      case 'EN':
        return loc.schoolEnchantment;
      case 'C':
        return loc.schoolConjuration;
      case 'A':
        return loc.schoolAbjuration;
      case 'I':
        return loc.schoolIllusion;
      case 'N':
        return loc.schoolNecromancy;
      default:
        return loc.schoolNone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final uniqueClasses = spellData.classes.toSet().toList();
    final classesString = uniqueClasses.join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(spellData.name),
        actions: importspell
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    if (onEdit != null) {
                      Navigator.of(context).pop();
                      onEdit!(spellData);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(loc.confirmdelete),
                        content: Text('${loc.delete} "${spellData.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(loc.abort),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(loc.delete),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && onDelete != null) {
                      Navigator.of(context).pop();
                      onDelete!(spellData.name);
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
            Text(
              spellData.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('${loc.level}: ${spellData.level}'),
            Text(
                '${loc.school}: ${getSchoolFullName(spellData.school, context)}'),
            Text('${loc.castingtime}: ${spellData.time}'),
            Text('${loc.range}: ${spellData.range}'),
            Text('${loc.duration}: ${spellData.duration}'),
            Text('${loc.ritual}: ${spellData.ritual}'),
            Text('${loc.components}: ${spellData.components}'),
            const SizedBox(height: 10),
            Text(
              '${loc.classesKey}: $classesString',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${loc.description}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(spellData.text),
          ],
        ),
      ),
      floatingActionButton: importspell
          ? FloatingActionButton(
              onPressed: () async {
                final newSpell = await _showAddSpellDialog(context, spellData);
                if (newSpell != null && context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(newSpell);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class ClassSpellsPage extends StatefulWidget {
  final String className;
  final List<SpellData> spells;
  final bool importspell;
  final Function(SpellData)? onEdit;
  final Function(String)? onDelete;

  const ClassSpellsPage({
    super.key,
    required this.className,
    required this.spells,
    this.importspell = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  ClassSpellsPageState createState() => ClassSpellsPageState();
}

class ClassSpellsPageState extends State<ClassSpellsPage> {
  final Set<SpellData> _selectedSpells = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool isSearchVisible = false;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSpellSelected(SpellData spell, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedSpells.add(spell);
      } else {
        _selectedSpells.remove(spell);
      }
    });
  }

  List<SpellData> _filterSpells(List<SpellData> spells) {
    if (_searchText.isEmpty) {
      return spells;
    }
    return spells
        .where((spell) => spell.name.toLowerCase().contains(_searchText))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: isSearchVisible
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: '${loc.search}...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
              )
            : Text('${widget.className} ${loc.spell}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                isSearchVisible = !isSearchVisible;
                if (isSearchVisible) {
                  _searchFocusNode.requestFocus();
                } else {
                  _searchText = '';
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                }
              });
            },
          ),
          if (widget.importspell)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(_selectedSpells.toList());
              },
            ),
        ],
      ),
      body: buildSpellCollapsibleSections(
        _filterSpells(widget.spells),
        context,
        widget.importspell,
        _selectedSpells,
        _onSpellSelected,
        widget.onEdit,
        widget.onDelete,
      ),
    );
  }
}

class AllSpellsPage extends StatefulWidget {
  final List<SpellData> spells;
  final bool importspell;
  final Function(SpellData)? onEdit;
  final Function(String)? onDelete;

  const AllSpellsPage({
    super.key,
    required this.spells,
    this.importspell = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  AllSpellsPageState createState() => AllSpellsPageState();
}

class AllSpellsPageState extends State<AllSpellsPage> {
  final Set<SpellData> _selectedSpells = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool isSearchVisible = false;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSpellSelected(SpellData spell, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedSpells.add(spell);
      } else {
        _selectedSpells.remove(spell);
      }
    });
  }

  List<SpellData> _filterSpells(List<SpellData> spells) {
    if (_searchText.isEmpty) {
      return spells;
    }
    return spells
        .where((spell) => spell.name.toLowerCase().contains(_searchText))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: isSearchVisible
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: '${loc.search}...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
              )
            : Text(loc.allspells),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                isSearchVisible = !isSearchVisible;
                if (isSearchVisible) {
                  _searchFocusNode.requestFocus();
                } else {
                  _searchText = '';
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                }
              });
            },
          ),
          if (widget.importspell)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(_selectedSpells.toList());
              },
            ),
        ],
      ),
      body: buildSpellCollapsibleSections(
        _filterSpells(widget.spells),
        context,
        widget.importspell,
        _selectedSpells,
        _onSpellSelected,
        widget.onEdit,
        widget.onDelete,
      ),
    );
  }
}

Widget buildSpellCollapsibleSections(
  List<SpellData> spells,
  BuildContext context,
  bool importSpell,
  Set<SpellData> selectedSpells,
  void Function(SpellData spell, bool isSelected) onSpellSelected,
  Function(SpellData)? onEdit,
  Function(String)? onDelete,
) {
  final groupedSpells = <String, List<SpellData>>{};

  for (var spell in spells) {
    final levelKey = spell.level == "0" ? "Zaubertrick" : spell.level;

    if (!groupedSpells.containsKey(levelKey)) {
      groupedSpells[levelKey] = [];
    }
    groupedSpells[levelKey]!.add(spell);
  }

  final sortedLevels = <String>[];
  if (groupedSpells.containsKey("Zaubertrick")) {
    sortedLevels.add("Zaubertrick");
  }

  final otherLevels = groupedSpells.keys
      .where((level) => level != "Zaubertrick")
      .toList()
    ..sort();
  sortedLevels.addAll(otherLevels);

  return ListView(
    padding: const EdgeInsets.all(16.0),
    children: sortedLevels.map((level) {
      return buildCollapsibleSectionForSpells(
        level,
        groupedSpells[level]!,
        context,
        importSpell,
        selectedSpells,
        onSpellSelected,
        onEdit,
        onDelete,
      );
    }).toList(),
  );
}

Widget buildCollapsibleSectionForSpells(
  String level,
  List<SpellData> spells,
  BuildContext context,
  bool importSpell,
  Set<SpellData> selectedSpells,
  void Function(SpellData spell, bool isSelected) onSpellSelected,
  Function(SpellData)? onEdit,
  Function(String)? onDelete,
) {
  final loc = AppLocalizations.of(context)!;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExpansionTile(
        shape: const Border(),
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            level == "Zaubertrick" ? loc.cantrip : '${loc.level} $level',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        children: spells.asMap().entries.map((entry) {
          int index = entry.key;
          SpellData spell = entry.value;

          return Column(
            children: [
              if (index == 0) const Divider(),
              ListTile(
                title: Text(spell.name),
                leading: importSpell
                    ? Checkbox(
                        value: selectedSpells.contains(spell),
                        onChanged: (isSelected) {
                          onSpellSelected(spell, isSelected ?? false);
                        },
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpellDetailPage(
                        spellData: spell,
                        importspell: importSpell,
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
                    ),
                  );
                },
              ),
              if (index < spells.length - 1) const Divider(),
            ],
          );
        }).toList(),
      ),
      const Divider(),
    ],
  );
}

class ClassSelectionPage extends StatelessWidget {
  final List<SpellData> spells;

  const ClassSelectionPage({super.key, required this.spells});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final groupedSpells = <String, List<SpellData>>{};

    for (var spell in spells) {
      for (var className in spell.classes) {
        if (className.isNotEmpty) {
          groupedSpells.putIfAbsent(className, () => []).add(spell);
        }
      }
    }

    final sortedClassNames =
        groupedSpells.keys.where((name) => name.isNotEmpty).toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.chooseclass),
        backgroundColor: AppColors.appBarColor,
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(loc.allspells),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AllSpellsPage(spells: spells, importspell: true),
                ),
              );
            },
          ),
          ...sortedClassNames.map((className) {
            return ListTile(
              title: Text(className),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassSpellsPage(
                      className: className,
                      spells: groupedSpells[className]!,
                      importspell: true,
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Spell? newSpell = await _showAddSpellDialog(context, null);
          if (newSpell != null && context.mounted) {
            Navigator.of(context).pop(newSpell);
          }
        },
        tooltip: 'Add Spell',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

Future<Spell?> _showAddSpellDialog(
    BuildContext context, SpellData? spellData) async {
  const bool isNewSpell = true;

  String name = spellData?.name ?? '';
  String description = spellData?.text ?? '';
  String? reach = spellData?.range;
  String? duration = spellData?.duration;

  int level = Defines.spellZero;
  if (spellData?.level is String) {
    try {
      level = int.parse(spellData!.level);
    } catch (e) {
      level = Defines.spellZero;
    }
  } else if (spellData?.level is int) {
    level = spellData!.level as int;
  }

  return await _showSpellDialog(
    context,
    Spell(
      name: name,
      description: description,
      status: Defines.spellKnown,
      level: level,
      reach: reach,
      duration: duration,
    ),
    isNewSpell,
  );
}

Future<Spell?> _showSpellDialog(
    BuildContext context, Spell spell, bool isNewSpell) {
  final loc = AppLocalizations.of(context)!;
  final TextEditingController descriptionController =
      TextEditingController(text: spell.description);

  final TextEditingController reachController =
      TextEditingController(text: spell.reach);
  final TextEditingController durationController =
      TextEditingController(text: spell.duration);

  return showDialog<Spell>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(loc.editSpell),
        content: SingleChildScrollView(
          child: _buildSpellDetailForm(spell, descriptionController,
              reachController, durationController, loc),
        ),
        actions: [
          SizedBox(
            height: 36,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.abort),
            ),
          ),
          SizedBox(
            height: 36,
            child: TextButton(
              onPressed: () {
                spell.description = descriptionController.text;
                Navigator.of(context).pop(spell);
              },
              child: Text(loc.save),
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildSpellDetailForm(
    Spell spell,
    TextEditingController descriptionController,
    TextEditingController reach,
    TextEditingController duration,
    AppLocalizations loc) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildTextField(
        label: loc.spellname,
        controller: TextEditingController(text: spell.name),
        onChanged: (value) => spell.name = value,
      ),
      const SizedBox(height: 16),
      _buildDescriptionTextField(descriptionController, loc.description, 4),
      const SizedBox(height: 16),
      _buildDescriptionTextField(reach, loc.reach, 1),
      const SizedBox(height: 16),
      _buildDescriptionTextField(duration, loc.duration, 1),
      const SizedBox(height: 16),
      _buildLevelDropdown(spell, loc),
      const SizedBox(height: 16),
      _buildStatusDropdown(spell, loc),
    ],
  );
}

Widget _buildStatusDropdown(Spell spell, AppLocalizations loc) {
  const List<String> statuses = [Defines.spellPrep, Defines.spellKnown];

  return DropdownButtonFormField<String>(
    value: spell.status,
    decoration: InputDecoration(
      labelText: loc.status,
      border: const OutlineInputBorder(),
    ),
    items: statuses.map((String status) {
      return DropdownMenuItem<String>(
        value: status,
        child: Text(_getStatus(status)),
      );
    }).toList(),
    onChanged: (value) {
      if (value != null) {
        spell.status = value;
      }
    },
  );
}

Widget _buildLevelDropdown(Spell spell, AppLocalizations loc) {
  return DropdownButtonFormField<int>(
    value: spell.level,
    decoration: InputDecoration(
      labelText: loc.level,
      border: const OutlineInputBorder(),
    ),
    items: List.generate(10, (index) => index).map((int level) {
      return DropdownMenuItem<int>(
        value: level,
        child: Text(level == 0 ? loc.cantrip : '${loc.level} $level'),
      );
    }).toList(),
    onChanged: (value) {
      if (value != null) {
        spell.level = value;
      }
    },
  );
}

Widget _buildDescriptionTextField(
    TextEditingController controller, String label, int maxLines) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
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

String _getStatus(String status) {
  return status == Defines.spellPrep
      ? 'vorbereiteter Zauber'
      : 'bekannter Zauber';
}
