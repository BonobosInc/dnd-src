import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';

class FeatDetailPage extends StatelessWidget {
  final FeatData featData;
  final bool importFeat;

  const FeatDetailPage({super.key, required this.featData, this.importFeat = false});

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
                    Navigator.of(context).pop(_convertToFeatureData(featData, loc));
                  },
                ),
              ]
            : null,
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
            if (featData.prerequisite != null && featData.prerequisite!.isNotEmpty)
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
