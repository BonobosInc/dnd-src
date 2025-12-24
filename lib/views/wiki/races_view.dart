import 'package:flutter/material.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/l10n/app_localizations.dart';

class RaceDetailPage extends StatefulWidget {
  final RaceData raceData;
  final bool importFeat;

  const RaceDetailPage({super.key, required this.raceData, this.importFeat = false});

  @override
  RaceDetailPageState createState() => RaceDetailPageState();
}

class RaceDetailPageState extends State<RaceDetailPage> {
  final Set<FeatureData> selectedTraits = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.raceData.name),
        actions: widget.importFeat
            ? [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(selectedTraits.toList());
                  },
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildRaceInfo(),
          _buildTraitsSection(context),
        ],
      ),
    );
  }

  Widget _buildRaceInfo() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.raceData.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text('${loc.size}: ${widget.raceData.size}'),
        Text('${loc.movement}: ${widget.raceData.speed} ft'),
        Text('${loc.abilityscoreincrease}: ${widget.raceData.ability}'),
        Text('${loc.skills}: ${widget.raceData.proficiency}'),
        Text('${loc.spellcastingability}: ${widget.raceData.spellAbility}'),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTraitsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.raceData.traits.map((trait) {
        return ListTile(
          title: Text(
            trait.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: widget.importFeat
              ? Checkbox(
                  value: selectedTraits.contains(trait),
                  onChanged: (isSelected) {
                    onTraitSelected(trait, isSelected ?? false);
                  },
                )
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TraitDetailPage(
                  traitData: trait,
                  importFeat: widget.importFeat,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  void onTraitSelected(FeatureData trait, bool isSelected) {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      if (isSelected) {
        trait.type = loc.race;
        selectedTraits.add(trait);
      } else {
        selectedTraits.remove(trait);
      }
    });
  }
}

class TraitDetailPage extends StatelessWidget {
  final FeatureData traitData;
  final bool importFeat;

  const TraitDetailPage({
    super.key,
    required this.traitData,
    this.importFeat = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(traitData.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              traitData.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('${loc.description}:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(traitData.description),
          ],
        ),
      ),
      floatingActionButton: importFeat
          ? FloatingActionButton(
              onPressed: () async {
                final newTrait = await _showAddTraitDialog(context, traitData);
                if (newTrait != null && context.mounted) {
                  newTrait.type = loc.race;
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(newTrait);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<FeatureData?> _showAddTraitDialog(
      BuildContext context, FeatureData traitData) async {
    final loc = AppLocalizations.of(context)!;
    return showDialog<FeatureData?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${loc.addtraits}:'),
          content: Text(loc.addTraitDialog(traitData.name)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(traitData);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
