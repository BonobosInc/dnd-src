import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';

class ClassDetailPage extends StatefulWidget {
  final ClassData classData;
  final bool importFeat;
  final bool characterCreator;
  final Function(ClassData)? onEdit;
  final Function(String)? onDelete;

  const ClassDetailPage({
    super.key,
    required this.classData,
    this.importFeat = false,
    this.characterCreator = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  ClassDetailPageState createState() => ClassDetailPageState();
}

class ClassDetailPageState extends State<ClassDetailPage> {
  final Map<String, GlobalKey> _tileKeys = {};
  final GlobalKey _firstExpansionTileKey = GlobalKey();
  final Set<FeatureData> selectedFeatures = {};
  Map<String, List<FeatureData>> featuresByLevel = {};

  @override
  void initState() {
    super.initState();
    _fetchFeatures();
  }

  void _fetchFeatures() {
    featuresByLevel.clear();
    _groupFeaturesByLevel();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool hasNonZeroSlots = _hasNonZeroSlots();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData.name),
        actions: widget.importFeat
            ? [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(selectedFeatures.toList());
                  },
                ),
              ]
            : widget.characterCreator
                ? [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(widget.classData);
                      },
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        if (widget.onEdit != null) {
                          Navigator.of(context).pop();
                          widget.onEdit!(widget.classData);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final loc = AppLocalizations.of(context)!;
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(loc.confirmdelete),
                            content:
                                Text('${loc.delete} "${widget.classData.name}"?'),
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
                        if (confirmed == true && widget.onDelete != null) {
                          Navigator.of(context).pop();
                          widget.onDelete!(widget.classData.name);
                        }
                      },
                    ),
                  ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildClassInfo(),
          if (hasNonZeroSlots) _buildSpellSlotsTable(),
          buildFeatureCollapsibleSections(
              context, widget.importFeat, selectedFeatures, onFeatureSelected),
        ],
      ),
    );
  }

  void _groupFeaturesByLevel() {
    featuresByLevel = {};

    for (var autolevel in widget.classData.autolevels) {
      final level = autolevel.level;
      final features = autolevel.features;

      featuresByLevel.putIfAbsent(level, () => []);
      _tileKeys.putIfAbsent(level, () => GlobalKey());

      if (features != null) {
        final existingFeatures = featuresByLevel[level]!.toSet();

        for (var feature in features) {
          if (!existingFeatures.contains(feature)) {
            featuresByLevel[level]!.add(feature);
            existingFeatures.add(feature);
          }
        }
      }
    }
  }

  bool _hasNonZeroSlots() {
    return widget.classData.autolevels.any(
      (autolevel) =>
          autolevel.slots?.slots != null &&
          autolevel.slots!.slots.any((slot) => slot > 0),
    );
  }

  Widget _buildClassInfo() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.classData.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text('${loc.hitdice}: ${widget.classData.hd}'),
        Text('${loc.abilities}: ${widget.classData.proficiency}'),
        Text('${loc.numskills}: ${widget.classData.numSkills}'),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSpellSlotsTable() {
    final loc = AppLocalizations.of(context)!;
    return ExpansionTile(
      shape: const Border(),
      key: _firstExpansionTileKey,
      title: Text(loc.spellslots),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: Colors.grey),
            children: [
              TableRow(
                children: [
                  const TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Text('Lvl',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  ...List.generate(10, (index) {
                    return TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          '${index.toString()}  ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              ...List.generate(20, (level) {
                String levelString = (level + 1).toString();
                Autolevel? autolevel = widget.classData.autolevels.firstWhere(
                  (auto) => auto.level == levelString,
                  orElse: () => Autolevel(
                    level: levelString,
                    features: [],
                    slots: Slots(slots: List.filled(10, 0)),
                  ),
                );

                List<String> slots = autolevel.slots?.slots
                        .map((slot) => slot.toString())
                        .toList() ??
                    List.filled(10, '-');

                while (slots.length < 10) {
                  slots.add('-');
                }

                return TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          'Lvl ${level + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ...List.generate(10, (slotIndex) {
                      return TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            slots[slotIndex],
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildFeatureCollapsibleSections(
    BuildContext context,
    bool importFeat,
    Set<FeatureData> selectedFeatures,
    void Function(FeatureData feature, bool isSelected) onFeatureSelected,
  ) {
    final sortedLevels =
        featuresByLevel.keys.map((level) => int.parse(level)).toList()..sort();

    final sortedLevelStrings =
        sortedLevels.map((level) => level.toString()).toList();

    return Column(
      children: sortedLevelStrings.map((level) {
        return buildCollapsibleSectionForFeatures(
          level,
          featuresByLevel[level]!,
          context,
          importFeat,
          selectedFeatures,
          onFeatureSelected,
        );
      }).toList(),
    );
  }

  Widget buildCollapsibleSectionForFeatures(
    String level,
    List<FeatureData> features,
    BuildContext context,
    bool importFeat,
    Set<FeatureData> selectedFeatures,
    void Function(FeatureData feature, bool isSelected) onFeatureSelected,
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
              '${loc.level} $level',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          children: features.asMap().entries.map((entry) {
            int index = entry.key;
            FeatureData feature = entry.value;

            return Column(
              children: [
                if (index == 0) const Divider(),
                ListTile(
                  title: Text(
                    feature.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  leading: importFeat
                      ? Checkbox(
                          value: selectedFeatures.contains(feature),
                          onChanged: (isSelected) {
                            onFeatureSelected(feature, isSelected ?? false);
                          },
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FeatureDetailPage(
                          featureData: feature,
                          importFeat: importFeat,
                        ),
                      ),
                    );
                  },
                ),
                if (index < features.length - 1) const Divider(),
              ],
            );
          }).toList(),
        ),
        const Divider(),
      ],
    );
  }

  Future<void> onFeatureSelected(FeatureData feat, bool isSelected) async {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      if (isSelected) {
        feat.type = loc.classKey;
        selectedFeatures.add(feat);
      } else {
        selectedFeatures.remove(feat);
      }
    });
  }
}

class FeatureDetailPage extends StatelessWidget {
  final FeatureData featureData;
  final bool importFeat;

  const FeatureDetailPage({
    super.key,
    required this.featureData,
    this.importFeat = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(featureData.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              featureData.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${loc.description}:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(featureData.description),
          ],
        ),
      ),
      floatingActionButton: importFeat
          ? FloatingActionButton(
              onPressed: () async {
                final newFeature =
                    await _showAddFeatureDialog(context, featureData);
                if (newFeature != null && context.mounted) {
                  newFeature.type = loc.classKey;
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(newFeature);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<FeatureData?> _showAddFeatureDialog(
      BuildContext context, FeatureData featureData) async {
    return showDialog<FeatureData?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Feature hinzufügen'),
          content: Text('Feature ${featureData.name} erfolgreich hinzugefügt!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(featureData);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
