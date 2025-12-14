import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;
import 'package:dnd/views/wiki/background_view.dart';
import 'package:dnd/views/wiki/classes_view.dart';
import 'package:dnd/views/wiki/creatures_view.dart';
import 'package:dnd/views/wiki/feat_view.dart';
import 'package:dnd/views/wiki/races_view.dart';
import 'package:dnd/views/wiki/spellwiki_view.dart';
import 'package:dnd/classes/wiki_parser.dart';
import 'package:dnd/views/wiki/wiki_editor/class_editor_view.dart';
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

  void loadDataFromParser() {
    setState(() {
      classes = widget.wikiParser.classes;
      races = widget.wikiParser.races;
      backgrounds = widget.wikiParser.backgrounds;
      feats = widget.wikiParser.feats;
      spells = widget.wikiParser.spells;
      creatures = widget.wikiParser.creatures;
    });
  }

  Future<void> _deleteXml() async {
    widget.wikiParser.deleteXml();
    widget.wikiParser.classes.clear();
    widget.wikiParser.races.clear();
    widget.wikiParser.backgrounds.clear();
    widget.wikiParser.feats.clear();
    widget.wikiParser.spells.clear();
    widget.wikiParser.creatures.clear();
  }

  Future<void> importXml() async {
    final loc = AppLocalizations.of(context)!;
    String? filePath = await FilePicker.platform
        .pickFiles(
          type: FileType.any,
        )
        .then((result) => result?.files.single.path);

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
        loadDataFromParser();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.importgood)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loc.importbad}: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.importbad)),
        );
      }
    }
  }

  Future<void> exportXml() async {
    final loc = AppLocalizations.of(context)!;
    if (widget.wikiParser.savedXmlFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.noexportfilefound)));
      return;
    }

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
                  onSelected: (value) {
                    if (value == 'import') {
                      importXml();
                    } else if (value == 'export') {
                      exportXml();
                    } else if (value == 'delete') {
                      _deleteXml();
                      loadDataFromParser();
                    } else if (value == 'class') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddClassPage(
                            onSave: (newClass) async {
                              final xmlFilePath = await getDir();
                              final xmlFile = File(xmlFilePath);
                              if (!xmlFile.existsSync()) {
                                throw Exception(
                                    "XML file not found at $xmlFilePath");
                              }
                              final document = xml.XmlDocument.parse(
                                  await xmlFile.readAsString());

                              widget.wikiParser
                                  .addClassToXml(document, newClass);

                              await xmlFile.writeAsString(
                                  document.toXmlString(pretty: true));
                              if (kDebugMode) {
                                print("Class added successfully to XML.");
                              }
                            },
                          ),
                        ),
                      );
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
                      ),
                      // const PopupMenuItem<String>(
                      //   value: 'class',
                      //   child: Text('Klasse hinzufügen'),
                      // ),
                    ];
                  },
                ),
              ]
            : [],
      ),
      body: ListView(
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
                                        importFeat: widget.importFeat);
                                  } else if (item is BackgroundData) {
                                    return BackgroundDetailPage(
                                        backgroundData: item,
                                        importFeat: widget.importFeat);
                                  } else if (item is FeatData) {
                                    return FeatDetailPage(
                                        featData: item,
                                        importFeat: widget.importFeat);
                                  } else if (item is SpellData) {
                                    return SpellDetailPage(spellData: item);
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
                                      importFeat: widget.importFeat);
                                } else if (item is RaceData) {
                                  return RaceDetailPage(
                                      raceData: item,
                                      importFeat: widget.importFeat);
                                } else if (item is BackgroundData) {
                                  return BackgroundDetailPage(
                                      backgroundData: item,
                                      importFeat: widget.importFeat);
                                } else if (item is FeatData) {
                                  return FeatDetailPage(
                                      featData: item,
                                      importFeat: widget.importFeat);
                                } else if (item is SpellData) {
                                  return SpellDetailPage(spellData: item);
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

    return ExpansionTile(
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
                builder: (context) => AllSpellsPage(spells: spells),
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
                          spells: groupedSpells[className]!),
                    ),
                  );
                },
              ),
              if (index < sortedClassNames.length - 1) const Divider(),
            ],
          );
        }),
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
                    builder: (context) =>
                        AllCreaturesPage(creatures: creatures),
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
