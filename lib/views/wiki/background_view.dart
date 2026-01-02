import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';

class BackgroundDetailPage extends StatefulWidget {
  final BackgroundData backgroundData;
  final bool importFeat;
  final Function(BackgroundData)? onEdit;
  final Function(String)? onDelete;

  const BackgroundDetailPage({
    super.key,
    required this.backgroundData,
    this.importFeat = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  BackgroundDetailPageState createState() => BackgroundDetailPageState();
}

class BackgroundDetailPageState extends State<BackgroundDetailPage> {
  final Set<FeatureData> selectedFeatures = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.backgroundData.name),
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
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    if (widget.onEdit != null) {
                      Navigator.of(context).pop();
                      widget.onEdit!(widget.backgroundData);
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
                        content: Text('${loc.delete} "${widget.backgroundData.name}"?'),
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
                      widget.onDelete!(widget.backgroundData.name);
                    }
                  },
                ),
              ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildBackgroundInfo(),
          _buildTraitsSection(context),
        ],
      ),
    );
  }

  Widget _buildBackgroundInfo() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.backgroundData.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text('${loc.abilities}: ${widget.backgroundData.proficiency}'),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTraitsSection(BuildContext context) {
    return Column(
      children: [

        ...widget.backgroundData.traits.map((trait) {
          return ListTile(
            title: Text(
              trait.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: widget.importFeat
                ? Checkbox(
                    value: selectedFeatures.contains(trait),
                    onChanged: (isSelected) {
                      onFeatureSelected(trait, isSelected ?? false);
                    },
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FeatureDetailPage(
                    featureData: trait,
                    importFeat: widget.importFeat,
                  ),
                ),
              );
            },
          );
        })
      ],
    );
  }

  void onFeatureSelected(FeatureData feat, bool isSelected) {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      if (isSelected) {
        feat.type = loc.background;
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
              style: TextStyle(fontWeight: FontWeight.bold),
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
                  newFeature.type = loc.background;
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
