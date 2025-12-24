import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/classes/wiki_parser.dart';
import 'package:dnd/views/wiki_view.dart';
import 'package:flutter/material.dart';
import 'package:dnd/classes/profile_manager.dart';
import 'package:dnd/configs/defines.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/l10n/app_localizations.dart';

class Feat {
  String name;
  String description;
  int? uuid;
  String? type;

  Feat({
    required this.name,
    required this.description,
    this.uuid,
    required this.type,
  });
}

class NotesPage extends StatefulWidget {
  final ProfileManager profileManager;
  final WikiParser wikiParser;

  const NotesPage({
    super.key,
    required this.profileManager,
    required this.wikiParser,
  });

  @override
  NotesPageState createState() => NotesPageState();
}

class NotesPageState extends State<NotesPage> {
  final TextEditingController raceController = TextEditingController();
  final TextEditingController classController = TextEditingController();
  final TextEditingController originController = TextEditingController();
  final TextEditingController backgroundController = TextEditingController();
  final TextEditingController personalityTraitsController =
      TextEditingController();
  final TextEditingController idealsController = TextEditingController();
  final TextEditingController bondsController = TextEditingController();
  final TextEditingController flawsController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController godController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController sexController = TextEditingController();
  final TextEditingController alignmentController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController eyeColourController = TextEditingController();
  final TextEditingController hairColourController = TextEditingController();
  final TextEditingController skinColourController = TextEditingController();
  final TextEditingController appearanceController = TextEditingController();
  final TextEditingController backStoryController = TextEditingController();
  final TextEditingController otherNotesController = TextEditingController();

  final TextEditingController armorProfController = TextEditingController();
  final TextEditingController weaponProfController = TextEditingController();
  final TextEditingController toolsProfController = TextEditingController();
  final TextEditingController languageProfController = TextEditingController();

  String? selectedSize;

  List<FeatData> featsData = [];

  final List<String> sizeOptions = [
    '',
    'Winzig',
    'Klein',
    'Mittelgroß',
    'Groß',
    'Riesig',
    'Gigantisch'
  ];

  final ScrollController _scrollController = ScrollController();

  final List<Feat> feats = [];

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
    _fetchFeats();
    featsData = widget.wikiParser.feats;
  }

  Future<void> _fetchFeats() async {
    List<Map<String, dynamic>> fetchedFeats =
        await widget.profileManager.getFeats();

    setState(() {
      feats.clear();
      for (var feat in fetchedFeats) {
        feats.add(Feat(
          name: feat['featname'],
          description: feat['description'] ?? '',
          uuid: feat['ID'],
          type: feat['type'],
        ));
      }
      feats.sort((a, b) => a.uuid!.compareTo(b.uuid as num));
    });
  }

  Future<void> _loadCharacterData() async {
    List<Map<String, dynamic>> result =
        await widget.profileManager.getProfileInfo();

    List<Map<String, dynamic>> profs =
        await widget.profileManager.getProficiencies();

    if (result.isNotEmpty) {
      Map<String, dynamic> characterData = result.first;
      setState(() {
        raceController.text = characterData[Defines.infoRace] ?? '';
        classController.text = characterData[Defines.infoClass] ?? '';
        originController.text = characterData[Defines.infoOrigin] ?? '';
        backgroundController.text = characterData[Defines.infoBackground] ?? '';
        personalityTraitsController.text =
            characterData[Defines.infoPersonalityTraits] ?? '';
        idealsController.text = characterData[Defines.infoIdeals] ?? '';
        bondsController.text = characterData[Defines.infoBonds] ?? '';
        flawsController.text = characterData[Defines.infoFlaws] ?? '';
        ageController.text = characterData[Defines.infoAge] ?? '';
        godController.text = characterData[Defines.infoGod] ?? '';

        selectedSize = sizeOptions.contains(characterData[Defines.infoSize])
            ? characterData[Defines.infoSize]
            : sizeOptions[0];

        heightController.text = characterData[Defines.infoHeight] ?? '';
        weightController.text = characterData[Defines.infoWeight] ?? '';
        sexController.text = characterData[Defines.infoSex] ?? '';
        alignmentController.text = characterData[Defines.infoAlignment] ?? '';
        eyeColourController.text = characterData[Defines.infoEyeColour] ?? '';
        hairColourController.text = characterData[Defines.infoHairColour] ?? '';
        skinColourController.text = characterData[Defines.infoSkinColour] ?? '';
        appearanceController.text = characterData[Defines.infoAppearance] ?? '';
        backStoryController.text =
            characterData[Defines.infoBackstory] ?? '';
        otherNotesController.text = characterData[Defines.infoNotes] ?? '';
        sizeController.text = characterData[Defines.infoSize] ?? '';
      });
    } else {
      selectedSize = sizeOptions[0];
    }
    if (profs.isNotEmpty) {
      Map<String, dynamic> characterData = profs.first;
      setState(() {
        armorProfController.text = characterData[Defines.profArmor] ?? '';
        weaponProfController.text = characterData[Defines.profWeaponList] ?? '';
        toolsProfController.text = characterData[Defines.profTools] ?? '';
        languageProfController.text =
            characterData[Defines.profLanguages] ?? '';
      });
    }
  }

  void _onFieldChanged(String field, String value) {
    widget.profileManager.updateProfileInfo(field: field, value: value);
  }

  void _onFieldChangedProfs(String field, String value) {
    widget.profileManager.updateProficiencies(field: field, value: value);
  }

  @override
  void dispose() {
    raceController.dispose();
    classController.dispose();
    originController.dispose();
    backgroundController.dispose();
    personalityTraitsController.dispose();
    idealsController.dispose();
    bondsController.dispose();
    flawsController.dispose();
    ageController.dispose();
    godController.dispose();
    heightController.dispose();
    weightController.dispose();
    sexController.dispose();
    alignmentController.dispose();
    eyeColourController.dispose();
    hairColourController.dispose();
    skinColourController.dispose();
    appearanceController.dispose();
    armorProfController.dispose();
    weaponProfController.dispose();
    toolsProfController.dispose();
    languageProfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(
          title: Text(loc.notes),
          backgroundColor: AppColors.appBarColor,
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.add, color: AppColors.accentCyan),
              onSelected: (String value) {
                if (value == 'addFeat') {
                  _showAddFeatDialog();
                } else if (value == 'navigateToWiki') {
                  _navigateToWiki();
                }
              },
              itemBuilder: (BuildContext context) {
                return featsData.isEmpty
                    ? [
                        PopupMenuItem<String>(
                          value: 'addFeat',
                          child: Text(loc.newFeat),
                        )
                      ]
                    : [
                        PopupMenuItem<String>(
                          value: 'addFeat',
                          child: Text(loc.newFeat),
                        ),
                        PopupMenuItem<String>(
                          value: 'navigateToWiki',
                          child: Text(loc.importfeatfromwiki),
                        ),
                      ];
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Divider(),
              ExpansionTile(
                shape: const Border(),
                title: Text(
                  loc.notes,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                children: [
                  const SizedBox(height: 16),
                  ..._buildNotesFields(),
                ],
              ),
              const Divider(),
              _buildFeatsExpansionTiles(),
              const Divider(),
            ],
          ),
        ));
  }

  void _navigateToWiki() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WikiPage(wikiParser: widget.wikiParser, importFeat: true),
      ),
    );

    if (result != null) {
      if (result is List<FeatureData>) {
        for (var featData in result) {
          final feat = _convertFeatDataToFeat(featData);
          _addFeat(feat, feat.description);
        }
      } else if (result is FeatureData) {
        final feat = _convertFeatDataToFeat(result);
        _addFeat(feat, feat.description);
      } else if (result is Feat) {
        _addFeat(result, result.description);
      }
    }
  }

  Feat _convertFeatDataToFeat(FeatureData featData) {
    String name = featData.name;
    String description = featData.description;

    return Feat(
      name: name,
      description: description,
      type: featData.type ?? "Sonstige",
    );
  }

  void _showAddFeatDialog() {
    var newFeat = true;
    _showFeatDialog(
        Feat(
          name: '',
          description: '',
          type: 'Sonstige',
        ),
        newFeat);
  }

  void _showFeatDetails(Feat feat) {
    var newFeat = false;
    _showFeatDialog(feat, newFeat);
  }

  void _showFeatDialog(Feat feat, bool newFeat) {
    final loc = AppLocalizations.of(context)!;
    TextEditingController descriptionController =
        TextEditingController(text: feat.description);

    String? selectedType = feat.type;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.editFeat),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildFeatDetailForm(feat, descriptionController),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: [
                    DropdownMenuItem(value: 'Klasse', child: Text(loc.classKey)),
                    DropdownMenuItem(value: 'Rasse', child: Text(loc.race)),
                    DropdownMenuItem(
                        value: 'Hintergrund', child: Text(loc.background)),
                    DropdownMenuItem(
                        value: 'Fähigkeiten', child: Text(loc.abilities)),
                    DropdownMenuItem(
                        value: 'Sonstige', child: Text(loc.other)),
                  ],
                  decoration: InputDecoration(
                    labelText: loc.type,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    selectedType = value;
                    feat.type = selectedType;
                  },
                ),
              ],
            ),
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
                  if (newFeat) {
                    _addFeat(feat, descriptionController.text);
                  } else {
                    _updateFeat(feat, descriptionController.text);
                  }
                  Navigator.of(context).pop(true);
                },
                child: Text(loc.save),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateFeat(Feat feat, String description) {
    final loc = AppLocalizations.of(context)!;
    final finalDescription =
        description.isEmpty ? loc.nodescription : description;

    widget.profileManager
        .updateFeat(
      featName: feat.name,
      description: finalDescription,
      uuid: feat.uuid,
      type: feat.type,
    )
        .then((_) {
      _fetchFeats();
    });
  }

  void _addFeat(Feat feat, String description) {
    final loc = AppLocalizations.of(context)!;
    final finalDescription =
        description.isEmpty ? loc.nodescription : description;

    widget.profileManager
        .addFeat(
            featName: feat.name, description: finalDescription, type: feat.type)
        .then((_) {
      _fetchFeats();
    });
  }

  void _deleteFeat(int uuid) async {
    await widget.profileManager.removeFeat(uuid);
    _fetchFeats();
  }

  Widget _buildFeatDetailForm(
      Feat feat, TextEditingController descriptionController) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFeatTextField(
          label: loc.name,
          controller: TextEditingController(text: feat.name),
          onChanged: (value) => feat.name = value,
        ),
        const SizedBox(height: 16),
        _buildDescriptionTextField(descriptionController),
      ],
    );
  }

  Widget _buildFeatTextField({
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

  Widget _buildDescriptionTextField(TextEditingController controller) {
    final loc = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      maxLines: 15,
      decoration: InputDecoration(
        labelText: loc.description,
        border: OutlineInputBorder(),
      ),
    );
  }

  List<Widget> _buildNotesFields() {
    final loc = AppLocalizations.of(context)!;
    return [
      Row(
        children: [
          Expanded(
              child: _buildTextField(loc.folk, raceController, Defines.infoRace)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildTextField(
                  loc.origin, originController, Defines.infoOrigin)),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
              child: _buildTextField(
                  loc.classKey, classController, Defines.infoClass)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildTextField(
                  loc.background, backgroundController, Defines.infoBackground)),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
              child: _buildTextField(loc.age, ageController, Defines.infoAge)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildTextField(
                  loc.sex, sexController, Defines.infoSex)),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
              child: _buildTextField(
                  loc.height, heightController, Defines.infoHeight)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildTextField(
                  loc.weight, weightController, Defines.infoWeight)),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
              child: _buildTextField(
                  loc.eyecolor, eyeColourController, Defines.infoEyeColour)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildTextField(
                  loc.haircolor, hairColourController, Defines.infoHairColour)),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
              child: _buildTextField(
                  loc.skincolor, skinColourController, Defines.infoSkinColour)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildTextField(
                  loc.faith, godController, Defines.infoGod)),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
              child: _buildTextField(
                  loc.sizecat, sizeController, Defines.infoSize)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildTextField(
                  loc.alignment, alignmentController, Defines.infoAlignment)),
        ],
      ),
      const SizedBox(height: 16),
      _buildLargeTextField(
          loc.look, appearanceController, Defines.infoAppearance, 3),
      const SizedBox(height: 16),
      _buildLargeTextField(loc.personalitytraits,
          personalityTraitsController, Defines.infoPersonalityTraits, 3),
      const SizedBox(height: 16),
      _buildLargeTextField(loc.ideals, idealsController, Defines.infoIdeals, 3),
      const SizedBox(height: 16),
      _buildLargeTextField(loc.bonds, bondsController, Defines.infoBonds, 3),
      const SizedBox(height: 16),
      _buildLargeTextField(loc.flaws, flawsController, Defines.infoFlaws, 3),
      const SizedBox(height: 16),
      _buildLargeTextField(loc.backstory, backStoryController,
          Defines.infoBackstory, 15),
      const SizedBox(height: 16),
      _buildLargeTextField(
          loc.otherNotes, otherNotesController, Defines.infoNotes, 15),
      const SizedBox(height: 16),
      _buildLargeTextFieldProfs(
          loc.armors, armorProfController, Defines.profArmor, 3),
      const SizedBox(height: 16),
      _buildLargeTextFieldProfs(
          loc.weapons, weaponProfController, Defines.profWeaponList, 3),
      const SizedBox(height: 16),
      _buildLargeTextFieldProfs(
          loc.tools, toolsProfController, Defines.profTools, 3),
      const SizedBox(height: 16),
      _buildLargeTextFieldProfs(
          loc.languages, languageProfController, Defines.profLanguages, 3),
    ];
  }

  Widget _buildFeatsExpansionTiles() {
    final loc = AppLocalizations.of(context)!;
    feats.sort((a, b) => a.uuid!.compareTo(b.uuid!));

    String className =
        classController.text.isEmpty ? loc.classKey : classController.text;
    String raceName =
        raceController.text.isEmpty ? loc.folk : raceController.text;
    String backgroundName = backgroundController.text.isEmpty
        ? loc.background
        : backgroundController.text;

    Map<String, List<Feat>> groupedFeats = {
      className: [],
      raceName: [],
      backgroundName: [],
      loc.abilities: [],
      loc.other: []
    };

    for (var feat in feats) {
      String groupKey;
      switch (feat.type) {
        case 'Klasse':
          groupKey = className;
          break;
        case 'Rasse':
          groupKey = raceName;
          break;
        case 'Hintergrund':
          groupKey = backgroundName;
          break;
        case 'Fähigkeiten':
          groupKey = loc.abilities;
          break;
        default:
          groupKey = loc.other;
          break;
      }

      groupedFeats[groupKey]!.add(feat);
    }

    return ExpansionTile(
      shape: const Border(),
      title: Text(
        loc.feats,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      children: groupedFeats.entries.map((entry) {
        String type = entry.key;
        List<Feat> featsOfType = entry.value;

        if (featsOfType.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            const SizedBox(height: 10),
            ExpansionTile(
              shape: const Border(),
              title: Text(
                type,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              children: featsOfType.map((feat) {
                return Card(
                  color: AppColors.cardColor,
                  elevation: 4.0,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(
                      feat.name,
                      style: TextStyle(color: AppColors.textColorLight),
                    ),
                    onTap: () => _showFeatDetails(feat),
                    trailing: SizedBox(
                      width: 35,
                      height: 35,
                      child: IconButton(
                        icon: Icon(Icons.close,
                            color: AppColors.warningColor),
                        iconSize: 20.0,
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          _showDeleteConfirmationDialog(feat);
                        },
                      ),
                    ),
                    tileColor: AppColors.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showDeleteConfirmationDialog(Feat feat) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.confirmdelete),
          content: Text(loc.confirmItemDelete(feat.name)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(loc.abort),
            ),
            TextButton(
              onPressed: () {
                _deleteFeat(feat.uuid!);
                Navigator.of(context).pop(true);
              },
              child: Text(loc.delete),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String field) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => _onFieldChanged(field, value),
    );
  }

  Widget _buildLargeTextField(String label, TextEditingController controller,
      String field, int maxLines) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      onChanged: (value) => _onFieldChanged(field, value),
    );
  }

  Widget _buildLargeTextFieldProfs(String label,
      TextEditingController controller, String field, int maxLines) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      onChanged: (value) => _onFieldChangedProfs(field, value),
    );
  }
}
