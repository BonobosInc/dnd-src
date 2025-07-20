import 'package:dnd/classes/profile_manager.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/classes/wiki_parser.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:dnd/views/character_creator/creator_views.dart';
import 'package:flutter/material.dart';

class CharacterCreatorPage extends StatefulWidget {
  final WikiParser wikiParser;
  final ProfileManager profileManager;
  const CharacterCreatorPage({super.key, required this.wikiParser, required this.profileManager});

  @override
  State<CharacterCreatorPage> createState() => _CharacterCreatorPageState();
}

class _CharacterCreatorPageState extends State<CharacterCreatorPage> {
  final TextEditingController _nameController = TextEditingController();

  List<RaceData> races = [];
  List<ClassData> classes = [];
  List<BackgroundData> backgrounds = [];
  List<FeatData> feats = [];

  bool raceSelected = false;
  bool classSelected = false;
  bool backgroundSelected = false;
  bool featSelected = false;
  bool abilityScoresSet = false;

  RaceData? _selectedRace;
  ClassData? _selectedClass;
  BackgroundData? _selectedBackground;
  FeatData? _selectedFeat;
  Map<String, int>? _selectedFinalScores;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    races = widget.wikiParser.races;
    classes = widget.wikiParser.classes;
    backgrounds = widget.wikiParser.backgrounds;
    feats = widget.wikiParser.feats;
    super.initState();
  }

  void _onCreateCharacter() {
    final loc = AppLocalizations.of(context)!;
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enternewname)),
      );
      return;
    }

    if (!(raceSelected && classSelected && backgroundSelected && abilityScoresSet)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.completeallsteps)),
      );
      return;
    }

    widget.profileManager.characterCreator(
      _nameController.text,
      _selectedRace!,
      _selectedClass!,
      _selectedBackground!,
      _selectedFeat,
      _selectedFinalScores!

    );

    Navigator.of(context).pop();
  }

  void _navigateTo<T>(Widget page, void Function(T? result) onReturn) {
    Navigator.of(context)
        .push<T>(MaterialPageRoute(builder: (_) => page))
        .then((result) {
      onReturn(result);
    });
  }

  Widget _buildStepTile({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool completed,
    required bool enabled,
  }) {
    return Card(
      color: enabled ? AppColors.cardColor : AppColors.appBarColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        enabled: enabled,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textColorDark
          ),
        ),
        subtitle: subtitle != null && subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(color: AppColors.textColorDark),
              )
            : null,
        trailing: completed
            ? Container(
                width: 12,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : null,
        onTap: enabled ? onTap : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _showExitConfirmationDialog(context);
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _onCreateCharacter,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.name,
                ),
              ),
              const SizedBox(height: 24),

              // Race Tile - always enabled
              _buildStepTile(
                title: loc.chooserace,
                subtitle: _selectedRace?.name,
                completed: raceSelected,
                enabled: true,
                onTap: () => _navigateTo<RaceData>(
                  RacePage(races: races),
                  (race) {
                    if (race != null) {
                      setState(() {
                        raceSelected = true;
                        _selectedRace = race;
                      });
                    }
                  },
                ),
              ),

              // Class Tile - enabled if race selected
              _buildStepTile(
                title: loc.chooseclass,
                subtitle: _selectedClass?.name,
                completed: classSelected,
                enabled: raceSelected,
                onTap: () => _navigateTo<ClassData>(
                  ClassPage(classes: classes),
                  (classData) {
                    if (classData != null) {
                      setState(() {
                        classSelected = true;
                        _selectedClass = classData;
                      });
                    }
                  },
                ),
              ),

              // Background Tile - enabled if class selected
              _buildStepTile(
                title: loc.choosebackground,
                subtitle: _selectedBackground?.name,
                completed: backgroundSelected,
                enabled: classSelected,
                onTap: () => _navigateTo<BackgroundData>(
                  BackgroundPage(backgrounds: backgrounds),
                  (background) {
                    if (background != null) {
                      setState(() {
                        backgroundSelected = true;
                        _selectedBackground = background;
                      });
                    }
                  },
                ),
              ),

              // Feat Tile - enabled if background selected
              _buildStepTile(
                title: loc.choosefeat,
                subtitle: _selectedFeat?.name,
                completed: featSelected,
                enabled: classSelected,
                onTap: () => _navigateTo<FeatData>(
                  FeatPage(feats: feats),
                  (feat) {
                    if (feat != null) {
                      setState(() {
                        featSelected = true;
                        _selectedFeat = feat;
                      });
                    }
                  },
                ),
              ),

              // Ability Scores Tile - enabled if feat selected
              _buildStepTile(
                title: loc.setabilityscores,
                completed: abilityScoresSet,
                enabled: classSelected,
                onTap: () => _navigateTo<Map<String, int>>(
                  AbilityScoresPage(bonusInput: _selectedRace?.ability ?? ""),
                  (finalScores) {
                    if (finalScores != null) {
                      setState(() {
                        abilityScoresSet = true;
                        _selectedFinalScores = finalScores;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.exitCharacterCreator),
        content: Text(loc.exitConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.yes),
          ),
        ],
      ),
    ) ?? false;
  }
}
