import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;
import 'package:dnd/views/wiki/background_view.dart';
import 'package:dnd/views/wiki/classes_view.dart';
import 'package:dnd/views/wiki/creatures_view.dart';
import 'package:dnd/views/wiki/feat_view.dart';
import 'package:dnd/views/wiki/races_view.dart';
import 'package:dnd/views/wiki/spellwiki_view.dart';
import 'package:dnd/views/wiki/items_view.dart';
import 'package:dnd/classes/wiki_parser.dart';
import 'package:dnd/views/wiki/wiki_editor/class_editor_view.dart';
import 'package:dnd/views/wiki/wiki_editor/race_editor_view.dart';
import 'package:dnd/views/wiki/wiki_editor/background_editor_view.dart';
import 'package:dnd/views/wiki/wiki_editor/feat_editor_view.dart';
import 'package:dnd/views/wiki/wiki_editor/spell_editor_view.dart';
import 'package:dnd/views/wiki/wiki_editor/creature_editor_view.dart';
import 'package:dnd/views/wiki/wiki_editor/item_editor_view.dart';
import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:dnd/configs/colours.dart';

class WikiPage extends StatefulWidget {
  final WikiParser wikiParser;
  final bool importFeat;

  const WikiPage(
      {super.key, required this.wikiParser, this.importFeat = false});

  @override
  WikiPageState createState() => WikiPageState();
}

class WikiPageState extends State<WikiPage> {
  List<ClassData> classes = [];
  List<RaceData> races = [];
  List<BackgroundData> backgrounds = [];
  List<FeatData> feats = [];
  List<SpellData> spells = [];
  List<Creature> creatures = [];
  List<ItemData> items = [];

  bool isLoading = true;
  String searchQuery = '';
  bool isSearchVisible = false;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    loadDataFromParser();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  Future<String> getDir() async {
    String savedFilePath;
    if (Platform.isWindows) {
      bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;

      if (isDebugMode) {
        savedFilePath = './temp/wiki.xml';
      } else {
        Directory appSupportDir = await getApplicationSupportDirectory();
        savedFilePath = '${appSupportDir.path}/wiki.xml';
      }
    } else {
      Directory appSupportDir = await getApplicationSupportDirectory();
      savedFilePath = '${appSupportDir.path}/wiki.xml';
    }
    return savedFilePath;
  }

  Future<void> loadDataFromParser() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final classesData = await widget.wikiParser.classes;
      final racesData = await widget.wikiParser.races;
      final backgroundsData = await widget.wikiParser.backgrounds;
      final featsData = await widget.wikiParser.feats;
      final spellsData = await widget.wikiParser.spells;
      final creaturesData = await widget.wikiParser.creatures;
      final itemsData = await widget.wikiParser.items;

      if (!mounted) return;

      setState(() {
        classes = classesData;
        races = racesData;
        backgrounds = backgroundsData;
        feats = featsData;
        spells = spellsData;
        creatures = creaturesData;
        items = itemsData;
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading wiki data: $e');
      }
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteXml() async {
    await widget.wikiParser.deleteXml();
    await loadDataFromParser();
  }

  Future<void> _saveToXml<T>(T data, Future<void> Function(T) addToDb) async {
    await addToDb(data);
    await loadDataFromParser();
    if (kDebugMode) {
      print("${T.toString()} added successfully to database.");
    }
  }

  Future<void> _deleteFromXml<T>(String name,
      Future<void> Function(xml.XmlDocument, String) deleteFromXml) async {
    await deleteFromXml(xml.XmlDocument(), name);
    await loadDataFromParser();
  }

  Future<void> _updateInXml<T>(String oldName, T data,
      Future<void> Function(xml.XmlDocument, String, T) updateInXml) async {
    await updateInXml(xml.XmlDocument(), oldName, data);
    await loadDataFromParser();
  }

  void _addclass() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddClassPage(
          onSave: (newClass) async {
            await _saveToXml(newClass, widget.wikiParser.addClass);
          },
        ),
      ),
    );
    // Reload after returning from the add page
    await loadDataFromParser();
  }

  void _addRace() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRacePage(
          onSave: (newRace) async {
            await _saveToXml(newRace, widget.wikiParser.addRace);
          },
        ),
      ),
    );
    // Reload after returning from the add page
    await loadDataFromParser();
  }

  void _addBackground() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBackgroundPage(
          onSave: (newBackground) async {
            await _saveToXml(newBackground, widget.wikiParser.addBackground);
          },
        ),
      ),
    );
    // Reload after returning from the add page
    await loadDataFromParser();
  }

  void _addFeat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFeatPage(
          onSave: (newFeat) async {
            await _saveToXml(newFeat, widget.wikiParser.addFeat);
          },
        ),
      ),
    );
    // Reload after returning from the add page
    await loadDataFromParser();
  }

  void _addSpell() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSpellPage(
          onSave: (newSpell) async {
            await _saveToXml(newSpell, widget.wikiParser.addSpell);
          },
        ),
      ),
    );
    // Reload after returning from the add page
    await loadDataFromParser();
  }

  void _addCreature() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCreaturePage(
          onSave: (newCreature) async {
            await _saveToXml(newCreature, widget.wikiParser.addCreature);
          },
        ),
      ),
    );
    // Reload after returning from the add page
    await loadDataFromParser();
  }

  void _addItem() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemPage(
          onSave: (newItem) async {
            await _saveToXml(newItem, widget.wikiParser.addItem);
          },
        ),
      ),
    );
    // Reload after returning from the add page
    await loadDataFromParser();
  }

  void _editClass(ClassData classData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddClassPage(
          existingClass: classData,
          onSave: (updatedClass) async {
            await _updateInXml(classData.name, updatedClass,
                widget.wikiParser.updateClassInXml);
          },
        ),
      ),
    );
    // Reload after returning from the edit page
    await loadDataFromParser();
  }

  void _editRace(RaceData raceData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRacePage(
          existingRace: raceData,
          onSave: (updatedRace) async {
            await _updateInXml(
                raceData.name, updatedRace, widget.wikiParser.updateRaceInXml);
          },
        ),
      ),
    );
    // Reload after returning from the edit page
    await loadDataFromParser();
  }

  void _editBackground(BackgroundData backgroundData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBackgroundPage(
          existingBackground: backgroundData,
          onSave: (updatedBackground) async {
            await _updateInXml(backgroundData.name, updatedBackground,
                widget.wikiParser.updateBackgroundInXml);
          },
        ),
      ),
    );
    // Reload after returning from the edit page
    await loadDataFromParser();
  }

  void _editFeat(FeatData featData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFeatPage(
          existingFeat: featData,
          onSave: (updatedFeat) async {
            await _updateInXml(
                featData.name, updatedFeat, widget.wikiParser.updateFeatInXml);
          },
        ),
      ),
    );
    // Reload after returning from the edit page
    await loadDataFromParser();
  }

  void _editSpell(SpellData spellData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSpellPage(
          existingSpell: spellData,
          onSave: (updatedSpell) async {
            await _updateInXml(spellData.name, updatedSpell,
                widget.wikiParser.updateSpellInXml);
          },
        ),
      ),
    );
    // Reload after returning from the edit page
    await loadDataFromParser();
  }

  void _editCreature(Creature creature) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCreaturePage(
          existingCreature: creature,
          onSave: (updatedCreature) async {
            await _updateInXml(creature.name, updatedCreature,
                widget.wikiParser.updateCreatureInXml);
          },
        ),
      ),
    );
    // Reload after returning from the edit page
    await loadDataFromParser();
  }

  void _editItem(ItemData item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemPage(
          existingItem: item,
          onSave: (updatedItem) async {
            await _updateInXml(item.name, updatedItem,
                widget.wikiParser.updateItemInXml);
          },
        ),
      ),
    );
    // Reload after returning from the edit page
    await loadDataFromParser();
  }

  void _showAddMenu() {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.school, color: AppColors.accentTeal),
              title: Text(loc.classesKey),
              onTap: () {
                Navigator.pop(context);
                _addclass();
              },
            ),
            ListTile(
              leading: Icon(Icons.people, color: AppColors.accentPurple),
              title: Text(loc.races),
              onTap: () {
                Navigator.pop(context);
                _addRace();
              },
            ),
            ListTile(
              leading: Icon(Icons.book, color: AppColors.accentTeal),
              title: Text(loc.backgrounds),
              onTap: () {
                Navigator.pop(context);
                _addBackground();
              },
            ),
            ListTile(
              leading: Icon(Icons.star, color: AppColors.accentPurple),
              title: Text(loc.talents),
              onTap: () {
                Navigator.pop(context);
                _addFeat();
              },
            ),
            ListTile(
              leading: Icon(Icons.auto_fix_high, color: AppColors.accentTeal),
              title: Text(loc.spells),
              onTap: () {
                Navigator.pop(context);
                _addSpell();
              },
            ),
            ListTile(
              leading: Icon(Icons.pets, color: AppColors.accentPurple),
              title: Text(loc.monster),
              onTap: () {
                Navigator.pop(context);
                _addCreature();
              },
            ),
            ListTile(
              leading: Icon(Icons.inventory, color: AppColors.accentTeal),
              title: const Text('Item'),
              onTap: () {
                Navigator.pop(context);
                _addItem();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> importXml() async {
    final loc = AppLocalizations.of(context)!;

    if (kDebugMode) {
      print('📂 Opening file picker for wiki import...');
    }

    String? filePath = await FilePicker.platform
        .pickFiles(
          type: FileType.any,
        )
        .then((result) => result?.files.single.path);

    if (kDebugMode) {
      print('Selected file: $filePath');
    }

    if (filePath != null) {
      if (!filePath.endsWith('.xml')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.onlyxmlallowed)),
          );
        }
        return;
      }

      try {
        await widget.wikiParser.importXml(filePath);
        await loadDataFromParser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.importgood)),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Import error: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loc.importbad}: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.importbad)),
        );
      }
    }
  }

  Future<void> exportXml() async {
    final loc = AppLocalizations.of(context)!;

    try {
      await widget.wikiParser.exportXml();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.exportgood)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${loc.exportbad}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    List<dynamic> filteredItems = [];
    if (searchQuery.isNotEmpty) {
      filteredItems.addAll(classes.where((item) =>
          item.name.toLowerCase().contains(searchQuery.toLowerCase())));
      filteredItems.addAll(races.where((item) =>
          item.name.toLowerCase().contains(searchQuery.toLowerCase())));
      filteredItems.addAll(backgrounds.where((item) =>
          item.name.toLowerCase().contains(searchQuery.toLowerCase())));
      filteredItems.addAll(feats.where((item) =>
          item.name.toLowerCase().contains(searchQuery.toLowerCase())));
      filteredItems.addAll(spells.where((item) =>
          item.name.toLowerCase().contains(searchQuery.toLowerCase())));
      filteredItems.addAll(items.where((item) =>
          item.name.toLowerCase().contains(searchQuery.toLowerCase())));
    }

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
                    searchQuery = value.toLowerCase();
                  });
                },
              )
            : Text(loc.wiki),
        actions: widget.importFeat == false
            ? [
                IconButton(
                  icon: Icon(Icons.search, color: AppColors.accentTeal),
                  onPressed: () {
                    setState(() {
                      isSearchVisible = !isSearchVisible;
                      if (isSearchVisible) {
                        searchFocusNode.requestFocus();
                      } else {
                        searchQuery = '';
                        searchController.clear();
                        searchFocusNode.unfocus();
                      }
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.accentPurple),
                  onSelected: (value) async {
                    if (value == 'import') {
                      await importXml();
                    } else if (value == 'export') {
                      await exportXml();
                    } else if (value == 'delete') {
                      await _deleteXml();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'import',
                        child: Text(loc.importwiki),
                      ),
                      PopupMenuItem<String>(
                        value: 'export',
                        child: Text(loc.exportwiki),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(loc.deletewiki),
                      )
                    ];
                  },
                ),
              ]
            : [],
      ),
      floatingActionButton: widget.importFeat == false
          ? FloatingActionButton(
              onPressed: _showAddMenu,
              backgroundColor: AppColors.accentTeal,
              child: const Icon(Icons.add),
            )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: searchQuery.isNotEmpty
                  ? (filteredItems.isEmpty
                      ? [ListTile(title: Text(loc.noresultfound))]
                      : filteredItems.map((item) {
                          return Column(
                            children: [
                              ListTile(
                                title: Text(item.name),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        if (item is ClassData) {
                                          return ClassDetailPage(
                                              classData: item,
                                              importFeat: widget.importFeat);
                                        } else if (item is RaceData) {
                                          return RaceDetailPage(
                                              raceData: item,
                                              importFeat: widget.importFeat,
                                              onEdit: _editRace,
                                              onDelete: (name) async {
                                                await _deleteFromXml(
                                                    name,
                                                    widget.wikiParser
                                                        .deleteRaceFromXml);
                                              });
                                        } else if (item is BackgroundData) {
                                          return BackgroundDetailPage(
                                              backgroundData: item,
                                              importFeat: widget.importFeat,
                                              onEdit: _editBackground,
                                              onDelete: (name) async {
                                                await _deleteFromXml(
                                                    name,
                                                    widget.wikiParser
                                                        .deleteBackgroundFromXml);
                                              });
                                        } else if (item is FeatData) {
                                          return FeatDetailPage(
                                              featData: item,
                                              importFeat: widget.importFeat,
                                              onEdit: _editFeat,
                                              onDelete: (name) async {
                                                await _deleteFromXml(
                                                    name,
                                                    widget.wikiParser
                                                        .deleteFeatFromXml);
                                              });
                                        } else if (item is SpellData) {
                                          return SpellDetailPage(
                                              spellData: item,
                                              onEdit: _editSpell,
                                              onDelete: (name) async {
                                                await _deleteFromXml(
                                                    name,
                                                    widget.wikiParser
                                                        .deleteSpellFromXml);
                                              });
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                            ],
                          );
                        }).toList())
                  : [
                      buildCollapsibleSection(loc.races, races),
                      buildCollapsibleSection(loc.classesKey, classes),
                      buildCollapsibleSection(loc.backgrounds, backgrounds),
                      buildCollapsibleSection(loc.talents, feats),
                      buildCreatureCollapsibleSection(loc.monster, creatures),
                      if (widget.importFeat == false)
                        buildSpellCollapsibleSection(loc.spells, spells),
                      if (widget.importFeat == false)
                        buildItemCollapsibleSection(loc.items, items),
                    ],
            ),
    );
  }

  Widget buildCollapsibleSection<T extends Nameable>(
      String title, List<T> items) {
    final loc = AppLocalizations.of(context)!;
    List<T> filteredItems = items.where((item) {
      return item.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    filteredItems
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          shape: const Border(),
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          children: filteredItems.isEmpty
              ? [ListTile(title: Text(loc.noresultfound))]
              : filteredItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  T item = entry.value;

                  return Column(
                    children: [
                      if (index == 0) const Divider(),
                      ListTile(
                        title: Text(item.name),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                if (item is ClassData) {
                                  return ClassDetailPage(
                                    classData: item,
                                    importFeat: widget.importFeat,
                                    onEdit: _editClass,
                                    onDelete: (name) async {
                                      await _deleteFromXml(name,
                                          widget.wikiParser.deleteClassFromXml);
                                    },
                                  );
                                } else if (item is RaceData) {
                                  return RaceDetailPage(
                                      raceData: item,
                                      importFeat: widget.importFeat,
                                      onEdit: _editRace,
                                      onDelete: (name) async {
                                        await _deleteFromXml(
                                            name,
                                            widget
                                                .wikiParser.deleteRaceFromXml);
                                      });
                                } else if (item is BackgroundData) {
                                  return BackgroundDetailPage(
                                      backgroundData: item,
                                      importFeat: widget.importFeat,
                                      onEdit: _editBackground,
                                      onDelete: (name) async {
                                        await _deleteFromXml(
                                            name,
                                            widget.wikiParser
                                                .deleteBackgroundFromXml);
                                      });
                                } else if (item is FeatData) {
                                  return FeatDetailPage(
                                      featData: item,
                                      importFeat: widget.importFeat,
                                      onEdit: _editFeat,
                                      onDelete: (name) async {
                                        await _deleteFromXml(
                                            name,
                                            widget
                                                .wikiParser.deleteFeatFromXml);
                                      });
                                } else if (item is SpellData) {
                                  return SpellDetailPage(
                                      spellData: item,
                                      onEdit: _editSpell,
                                      onDelete: (name) async {
                                        await _deleteFromXml(
                                            name,
                                            widget
                                                .wikiParser.deleteSpellFromXml);
                                      });
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          );
                        },
                      ),
                      if (index < filteredItems.length - 1) const Divider(),
                    ],
                  );
                }).toList(),
        ),
        const Divider(),
      ],
    );
  }

  Widget buildSpellCollapsibleSection(String title, List<SpellData> spells) {
    final loc = AppLocalizations.of(context)!;
    final groupedSpells = <String, List<SpellData>>{};

    for (var spell in spells) {
      for (var className in spell.classes) {
        if (className.isNotEmpty) {
          if (!groupedSpells.containsKey(className)) {
            groupedSpells[className] = [];
          }
          groupedSpells[className]!.add(spell);
        }
      }
    }

    final sortedClassNames =
        groupedSpells.keys.where((name) => name.isNotEmpty).toList()..sort();

    return Column(
      children: [
        ExpansionTile(
          shape: const Border(),
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          children: [
            const Divider(),
            ListTile(
              title: Text(loc.allspells),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllSpellsPage(
                      spells: spells,
                      onEdit: _editSpell,
                      onDelete: (name) async {
                        await _deleteFromXml(
                            name, widget.wikiParser.deleteSpellFromXml);
                      },
                    ),
                  ),
                );
              },
            ),
            ...sortedClassNames.asMap().entries.map((entry) {
              int index = entry.key;
              String className = entry.value;

              return Column(
                children: [
                  if (index == 0) const Divider(),
                  ListTile(
                    title: Text(className),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassSpellsPage(
                            className: className,
                            spells: groupedSpells[className]!,
                            onEdit: _editSpell,
                            onDelete: (name) async {
                              await _deleteFromXml(
                                  name, widget.wikiParser.deleteSpellFromXml);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  if (index < sortedClassNames.length - 1) const Divider(),
                ],
              );
            }),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Widget buildCreatureCollapsibleSection(
      String title, List<Creature> creatures) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          shape: const Border(),
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          children: [
            const Divider(),
            ListTile(
              title: Text(loc.allmonster),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllCreaturesPage(
                      creatures: creatures,
                      onEdit: _editCreature,
                      onDelete: (creature) async {
                        await _deleteFromXml(creature.name,
                            widget.wikiParser.deleteCreatureFromXml);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Widget buildItemCollapsibleSection(String title, List<ItemData> items) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        ExpansionTile(
          shape: const Border(),
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          children: [
            const Divider(),
            ListTile(
              title: Text(loc.allitems),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllItemsPage(
                      items: items,
                      onEdit: _editItem,
                      onDelete: (item) async {
                        await _deleteFromXml(item.name,
                            widget.wikiParser.deleteItemFromXml);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}
