import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';

class FeatDetailPage extends StatefulWidget {
  final FeatData featData;
  final bool importFeat;
  final bool characterCreator;

  const FeatDetailPage({
    super.key,
    required this.featData,
    this.importFeat = false,
    this.characterCreator = false,
  });

  @override
  FeatDetailPageState createState() => FeatDetailPageState();
}

class FeatDetailPageState extends State<FeatDetailPage> {
  FeatureData _convertToFeatureData(AppLocalizations loc) {
    return FeatureData(
      name: widget.featData.name,
      description: widget.featData.text,
      type: loc.abilities,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final feat = widget.featData;

    return Scaffold(
      appBar: AppBar(
        title: Text(feat.name),
        actions: [
          if (widget.importFeat)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(_convertToFeatureData(loc));
              },
            ),
          if (widget.characterCreator && !widget.importFeat)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(feat);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feat.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (feat.prerequisite != null && feat.prerequisite!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${loc.requirement}: ${feat.prerequisite}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            Text(
              loc.description,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(feat.text, style: const TextStyle(fontSize: 16)),
            if (feat.modifier != null && feat.modifier!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${loc.modifier}: ${feat.modifier}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
