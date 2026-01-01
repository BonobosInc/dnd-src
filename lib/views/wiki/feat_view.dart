import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';

class FeatDetailPage extends StatelessWidget {
  final FeatData featData;
  final bool importFeat;
  final Function(FeatData)? onEdit;
  final Function(String)? onDelete;

  const FeatDetailPage({
    super.key,
    required this.featData,
    this.importFeat = false,
    this.onEdit,
    this.onDelete,
  });

  FeatureData _convertToFeatureData(FeatData feat, loc) {
    return FeatureData(
      name: feat.name,
      description: feat.text,
      type: loc.abilities,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(featData.name),
        actions: importFeat
            ? [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context)
                        .pop(_convertToFeatureData(featData, loc));
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    if (onEdit != null) {
                      Navigator.of(context).pop();
                      onEdit!(featData);
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
                        content: Text('${loc.delete} "${featData.name}"?'),
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
                      onDelete!(featData.name);
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
              featData.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (featData.prerequisite != null &&
                featData.prerequisite!.isNotEmpty)
              Text('${loc.requirement}: ${featData.prerequisite}'),
            const SizedBox(height: 10),
            Text(
              loc.description,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(featData.text),
            const SizedBox(height: 10),
            if (featData.modifier != null && featData.modifier!.isNotEmpty)
              Text('${loc.modifier}: ${featData.modifier}'),
          ],
        ),
      ),
    );
  }
}
