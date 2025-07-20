import 'dart:isolate';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart' as xml;
import 'package:dnd/classes/wiki_classes.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class WikiParser {
  List<ClassData> classes = [];
  List<RaceData> races = [];
  List<BackgroundData> backgrounds = [];
  List<FeatData> feats = [];
  List<SpellData> spells = [];
  List<Creature> creatures = [];
  String? savedXmlFilePath;

  WikiParser();

  bool isEmpty() {
    return classes.isEmpty ||
        races.isEmpty ||
        backgrounds.isEmpty;
  }

  Future<void> loadXml() async {
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

    File file = File(savedFilePath);

    if (await file.exists()) {
      savedXmlFilePath = savedFilePath;
      String xmlData = await file.readAsString();
      await parseXmlInIsolate(xmlData);
    } else {
      String initialXmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
<compendium version="5" auto_indent="NO">
    <!-- Items -->
    <!-- Races -->
    <!-- Classes -->
    <!-- Feats -->
    <!-- Backgrounds -->
    <!-- Spells -->
    <!-- Monsters -->
</compendium>''';
      await file.writeAsString(initialXmlContent);
      savedXmlFilePath = savedFilePath;
      await parseXmlInIsolate(initialXmlContent);
    }
  }

  Future<void> deleteXml() async {
    String filePath;

    if (Platform.isWindows) {
      bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;

      if (isDebugMode) {
        filePath = './temp/wiki.xml';
      } else {
        Directory appSupportDir = await getApplicationSupportDirectory();
        filePath = '${appSupportDir.path}/wiki.xml';
      }
    } else {
      Directory appSupportDir = await getApplicationSupportDirectory();
      filePath = '${appSupportDir.path}/wiki.xml';
    }

    File file = File(filePath);

    String initialXmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
<compendium version="5" auto_indent="NO">
    <!-- Items -->
    <!-- Races -->
    <!-- Classes -->
    <!-- Feats -->
    <!-- Backgrounds -->
    <!-- Spells -->
    <!-- Monsters -->
</compendium>''';

    await file.writeAsString(initialXmlContent);
    savedXmlFilePath = filePath;
    await parseXmlInIsolate(initialXmlContent);

    classes.clear();
    races.clear();
    backgrounds.clear();
    feats.clear();
    spells.clear();
    creatures.clear();
  }

  Future<void> importXml(String sourceFilePath) async {
    String destinationFilePath;

    if (Platform.isWindows) {
      bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;

      if (isDebugMode) {
        destinationFilePath = './temp/wiki.xml';
      } else {
        Directory appSupportDir = await getApplicationSupportDirectory();
        destinationFilePath = '${appSupportDir.path}/wiki.xml';
      }
    } else {
      Directory appSupportDir = await getApplicationSupportDirectory();
      destinationFilePath = '${appSupportDir.path}/wiki.xml';
    }

    final sourceFile = File(sourceFilePath);
    final destinationFile = File(destinationFilePath);
    await destinationFile.writeAsBytes(await sourceFile.readAsBytes());
    await loadXml();
  }

  Future<void> exportXml() async {
    if (savedXmlFilePath == null) {
      throw Exception("No XML file has been loaded to export.");
    }

    try {
      final sourceFile = File(savedXmlFilePath!);

      if (Platform.isAndroid || Platform.isIOS) {
        final shareFile = XFile(sourceFile.path);
        await Share.shareXFiles([shareFile],
            text: 'Hier ist der exportierte Wiki: wiki_export.xml');

        if (kDebugMode) {
          print("XML file shared.");
        }
      } else {
        final destinationPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Wiki speichern',
          fileName: 'wiki_export.xml',
        );

        if (destinationPath != null) {
          final destinationFile = File(destinationPath);
          await destinationFile.writeAsBytes(await sourceFile.readAsBytes());
          if (kDebugMode) {
            print("XML file saved at: $destinationPath");
          }
        } else {
          throw Exception("Export abgebrochen.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }
  }

  Future<void> parseXmlInIsolate(String xmlData) async {
    final response = ReceivePort();
    await Isolate.spawn(_parseXml, response.sendPort);

    final sendPort = await response.first as SendPort;
    final result = ReceivePort();
    sendPort.send([xmlData, result.sendPort]);

    final parsedData = await result.first as Map<String, List<dynamic>>;

    classes = (parsedData['classes'] as List<ClassData>? ?? []);
    races = (parsedData['races'] as List<RaceData>? ?? []);
    backgrounds = (parsedData['backgrounds'] as List<BackgroundData>? ?? []);
    feats = (parsedData['feats'] as List<FeatData>? ?? []);
    spells = (parsedData['spells'] as List<SpellData>? ?? []);
    creatures = (parsedData['creatures'] as List<Creature>? ?? []);
  }

  static void _parseXml(SendPort sendPort) {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    port.listen((message) {
      final xmlData = message[0] as String;
      final replyPort = message[1] as SendPort;

      final result = WikiParser.parseXmlData(xmlData);
      replyPort.send(result);
    });
  }

  static Map<String, List<dynamic>> parseXmlData(String xmlData) {
    final document = xml.XmlDocument.parse(xmlData);

    List<ClassData> classes = parseClasses(document);
    List<RaceData> races = parseRaces(document);
    List<BackgroundData> backgrounds = parseBackgrounds(document);
    List<FeatData> feats = parseFeats(document);
    List<SpellData> spells = parseSpells(document);
    List<Creature> creatures = parseCreatures(document);

    return {
      'classes': classes,
      'races': races,
      'backgrounds': backgrounds,
      'feats': feats,
      'spells': spells,
      'creatures': creatures,
    };
  }

  static List<ClassData> parseClasses(xml.XmlDocument document) {
    final classElements = document.findAllElements('class');

    return classElements.map((classElement) {
      final name = classElement.findElements('name').isNotEmpty
          ? classElement.findElements('name').first.innerText
          : 'N/A';
      final hd = classElement.findElements('hd').isNotEmpty
          ? classElement.findElements('hd').first.innerText
          : 'N/A';
      final proficiency = classElement.findElements('proficiency').isNotEmpty
          ? classElement.findElements('proficiency').first.innerText
          : 'N/A';
      final numSkills = classElement.findElements('numSkills').isNotEmpty
          ? classElement.findElements('numSkills').first.innerText
          : 'N/A';

      final autolevels =
          classElement.findAllElements('autolevel').map((levelElement) {
        final level = levelElement.getAttribute('level') ?? 'N/A';

        final features =
            levelElement.findAllElements('feature').map((featureElement) {
          final featureName = featureElement.findElements('name').isNotEmpty
              ? featureElement.findElements('name').first.innerText
              : 'N/A';
          final featureText = featureElement
              .findAllElements('text')
              .map((textElement) => textElement.innerText)
              .join('\n');
          return FeatureData(name: featureName, description: featureText);
        }).toList();

        Slots? slots;
        if (levelElement.findElements('slots').isNotEmpty) {
          final slotsText = levelElement.findElements('slots').first.innerText;
          final slotsList = slotsText
              .split(',')
              .map((slot) => int.tryParse(slot.trim()) ?? 0)
              .toList();
          slots = Slots(slots: slotsList);
        }

        return Autolevel(level: level, features: features, slots: slots);
      }).toList();

      return ClassData(
        name: name,
        hd: hd,
        proficiency: proficiency,
        numSkills: numSkills,
        autolevels: autolevels,
      );
    }).toList();
  }

  static List<RaceData> parseRaces(xml.XmlDocument document) {
    final raceElements = document.findAllElements('race');

    return raceElements.map((raceElement) {
      final name = raceElement.findElements('name').isNotEmpty
          ? raceElement.findElements('name').first.innerText
          : 'N/A';

      final size = raceElement.findElements('size').isNotEmpty
          ? raceElement.findElements('size').first.innerText
          : 'N/A';

      final speed = raceElement.findElements('speed').isNotEmpty
          ? int.tryParse(raceElement.findElements('speed').first.innerText) ?? 0
          : 0;

      final ability = raceElement.findElements('ability').isNotEmpty
          ? raceElement.findElements('ability').first.innerText
          : 'N/A';

      final proficiency = raceElement.findElements('proficiency').isNotEmpty
          ? raceElement.findElements('proficiency').first.innerText
          : 'Keine';

      final spellAbility = raceElement.findElements('spellAbility').isNotEmpty
          ? raceElement.findElements('spellAbility').first.innerText
          : 'Keine';

      final traits = raceElement.findAllElements('trait').map((traitElement) {
        final traitName = traitElement.findElements('name').isNotEmpty
            ? traitElement.findElements('name').first.innerText
            : 'N/A';
        final traitDescription = traitElement.findElements('text').isNotEmpty
            ? traitElement.findElements('text').first.innerText
            : 'Keine Beschreibung vorhanden.';
        return FeatureData(name: traitName, description: traitDescription);
      }).toList();

      return RaceData(
        name: name,
        size: size,
        speed: speed,
        ability: ability,
        proficiency: proficiency,
        spellAbility: spellAbility,
        traits: traits,
      );
    }).toList();
  }

  static List<FeatData> parseFeats(xml.XmlDocument document) {
    final featElements = document.findAllElements('feat');

    return featElements.map((featElement) {
      final name = featElement.findElements('name').isNotEmpty
          ? featElement.findElements('name').first.innerText
          : 'N/A';
      final prerequisite = featElement.findElements('prerequisite').isNotEmpty
          ? featElement.findElements('prerequisite').first.innerText
          : null;
      final text = featElement.findElements('text').isNotEmpty
          ? featElement.findElements('text').first.innerText
          : 'Keine Beschreibung vorhanden.';
      final modifier = featElement.findElements('modifier').isNotEmpty
          ? featElement.findElements('modifier').first.innerText
          : null;

      return FeatData(
        name: name,
        prerequisite: prerequisite,
        text: text,
        modifier: modifier,
      );
    }).toList();
  }

  static List<BackgroundData> parseBackgrounds(xml.XmlDocument document) {
    final backgroundElements = document.findAllElements('background');

    return backgroundElements.map((backgroundElement) {
      final name = backgroundElement.findElements('name').isNotEmpty
          ? backgroundElement.findElements('name').first.innerText
          : 'N/A';
      final proficiency =
          backgroundElement.findElements('proficiency').isNotEmpty
              ? backgroundElement.findElements('proficiency').first.innerText
              : 'N/A';

      final traits =
          backgroundElement.findAllElements('trait').map((traitElement) {
        final traitName = traitElement.findElements('name').isNotEmpty
            ? traitElement.findElements('name').first.innerText
            : 'N/A';
        final traitDescription = traitElement.findElements('text').isNotEmpty
            ? traitElement.findElements('text').first.innerText
            : 'Keine Beschreibung vorhanden.';
        return FeatureData(name: traitName, description: traitDescription);
      }).toList();

      return BackgroundData(
        name: name,
        proficiency: proficiency,
        traits: traits,
      );
    }).toList();
  }

  static List<SpellData> parseSpells(xml.XmlDocument document) {
    final spellElements = document.findAllElements('spell');

    return spellElements.map((spellElement) {
      final name = spellElement.findElements('name').isNotEmpty
          ? spellElement
              .findElements('name')
              .first
              .innerText
              .replaceAll('*', '')
          : 'N/A';

      final spellclasses = spellElement.findElements('classes').isNotEmpty
          ? spellElement
              .findElements('classes')
              .first
              .innerText
              .split(', ')
              .map((className) => className.trim())
              .toList()
          : <String>[];

      final level = spellElement.findElements('level').isNotEmpty
          ? spellElement.findElements('level').first.innerText
          : 'Zaubertrick';
      final school = spellElement.findElements('school').isNotEmpty
          ? spellElement.findElements('school').first.innerText
          : 'N/A';
      final ritual = spellElement.findElements('ritual').isNotEmpty
          ? spellElement.findElements('ritual').first.innerText
          : 'N/A';
      final time = spellElement.findElements('time').isNotEmpty
          ? spellElement.findElements('time').first.innerText
          : 'N/A';
      final range = spellElement.findElements('range').isNotEmpty
          ? spellElement.findElements('range').first.innerText
          : 'N/A';
      final components = spellElement.findElements('components').isNotEmpty
          ? spellElement.findElements('components').first.innerText
          : 'N/A';
      final duration = spellElement.findElements('duration').isNotEmpty
          ? spellElement.findElements('duration').first.innerText
          : 'N/A';
      final text = spellElement.findElements('text').isNotEmpty
          ? spellElement.findElements('text').first.innerText
          : 'Keine Beschreibung vorhanden.';

      return SpellData(
        name: name,
        classes: spellclasses,
        level: level,
        school: school,
        ritual: ritual,
        time: time,
        range: range,
        components: components,
        duration: duration,
        text: text,
      );
    }).toList();
  }

  static List<Creature> parseCreatures(xml.XmlDocument document) {
    final monsterElements = document.findAllElements('monster');

    return monsterElements.map((monsterElement) {
      final name = monsterElement.findElements('name').isNotEmpty
          ? monsterElement.findElements('name').first.innerText
          : 'N/A';

      final size = monsterElement.findElements('size').isNotEmpty
          ? monsterElement.findElements('size').first.innerText
          : 'N/A';

      final type = monsterElement.findElements('type').isNotEmpty
          ? monsterElement.findElements('type').first.innerText
          : 'N/A';

      final alignment = monsterElement.findElements('alignment').isNotEmpty
          ? monsterElement.findElements('alignment').first.innerText
          : 'N/A';

      final ac = monsterElement.findElements('ac').isNotEmpty
          ? int.tryParse(monsterElement.findElements('ac').first.innerText) ?? 0
          : 0;

      // Parse hp and set maxHP and currentHP
      final hp = monsterElement.findElements('hp').isNotEmpty
          ? monsterElement.findElements('hp').first.innerText
          : 'N/A';

      int maxHP = 0;
      int currentHP = 0;

      // Check if hp contains a numeric value before the space (e.g., '135' in '135 (18d10 + 36)')
      final hpParts = hp.split(' ');
      if (hpParts.isNotEmpty) {
        maxHP = int.tryParse(hpParts[0]) ?? 0;
        currentHP = maxHP; // Initially set currentHP to maxHP
      }

      final speed = monsterElement.findElements('speed').isNotEmpty
          ? monsterElement.findElements('speed').first.innerText
          : 'N/A';

      final str =
          int.tryParse(monsterElement.findElements('str').first.innerText) ?? 0;
      final dex =
          int.tryParse(monsterElement.findElements('dex').first.innerText) ?? 0;
      final con =
          int.tryParse(monsterElement.findElements('con').first.innerText) ?? 0;
      final intScore =
          int.tryParse(monsterElement.findElements('int').first.innerText) ?? 0;
      final wis =
          int.tryParse(monsterElement.findElements('wis').first.innerText) ?? 0;
      final cha =
          int.tryParse(monsterElement.findElements('cha').first.innerText) ?? 0;

      final saves = monsterElement.findElements('save').isNotEmpty
          ? monsterElement.findElements('save').first.innerText
          : '';

      final skills = monsterElement.findElements('skill').isNotEmpty
          ? monsterElement.findElements('skill').first.innerText
          : '';

      final immunities = monsterElement.findElements('immune').isNotEmpty
          ? monsterElement.findElements('immune').first.innerText
          : '';

      final conditionImmunities =
          monsterElement.findElements('conditionImmune').isNotEmpty
              ? monsterElement.findElements('conditionImmune').first.innerText
              : '';

      final senses = monsterElement.findElements('senses').isNotEmpty
          ? monsterElement.findElements('senses').first.innerText
          : '';

      final passivePerception =
          monsterElement.findElements('passive').isNotEmpty
              ? int.tryParse(
                      monsterElement.findElements('passive').first.innerText) ??
                  0
              : 0;

      final languages = monsterElement.findElements('languages').isNotEmpty
          ? monsterElement.findElements('languages').first.innerText
          : '';

      final cr = monsterElement.findElements('cr').isNotEmpty
          ? monsterElement.findElements('cr').first.innerText
          : '';

      // Parse traits
      final traits =
          monsterElement.findAllElements('trait').map((traitElement) {
        final traitName = traitElement.findElements('name').isNotEmpty
            ? traitElement.findElements('name').first.innerText
            : 'N/A';
        final traitDescription = traitElement.findElements('text').isNotEmpty
            ? traitElement.findElements('text').first.innerText
            : '';
        return Trait(name: traitName, description: traitDescription);
      }).toList();

      // Parse actions
      final actions =
          monsterElement.findAllElements('action').map((actionElement) {
        final actionName = actionElement.findElements('name').isNotEmpty
            ? actionElement.findElements('name').first.innerText
            : 'N/A';
        final actionDescription = actionElement.findElements('text').isNotEmpty
            ? actionElement.findElements('text').first.innerText
            : '';
        final attack = actionElement.findElements('attack').isNotEmpty
            ? actionElement.findElements('attack').first.innerText
            : null;
        return CAction(
            name: actionName, description: actionDescription, attack: attack);
      }).toList();

      // Parse legendary actions
      final legendaryActions =
          monsterElement.findAllElements('legendary').map((legendaryElement) {
        final legendaryName = legendaryElement.findElements('name').isNotEmpty
            ? legendaryElement.findElements('name').first.innerText
            : 'N/A';
        final legendaryDescription =
            legendaryElement.findElements('text').isNotEmpty
                ? legendaryElement.findElements('text').first.innerText
                : '';
        return Legendary(
            name: legendaryName, description: legendaryDescription);
      }).toList();

      return Creature(
        name: name,
        size: size,
        type: type,
        alignment: alignment,
        ac: ac,
        maxHP: maxHP,
        currentHP: currentHP,
        speed: speed,
        str: str,
        dex: dex,
        con: con,
        intScore: intScore,
        wis: wis,
        cha: cha,
        saves: saves,
        skills: skills,
        resistances: '',
        vulnerabilities: '',
        immunities: immunities,
        conditionImmunities: conditionImmunities,
        senses: senses,
        passivePerception: passivePerception,
        languages: languages,
        cr: cr,
        traits: traits,
        actions: actions,
        legendaryActions: legendaryActions,
      );
    }).toList();
  }

  void addClassToXml(xml.XmlDocument document, ClassData classData) {
    final builder = xml.XmlBuilder();

    builder.element('class', nest: () {
      builder.element('name', nest: classData.name);
      builder.element('hd', nest: classData.hd);
      builder.element('proficiency', nest: classData.proficiency);
      builder.element('numSkills', nest: classData.numSkills);

      builder.element('autolevels', nest: () {
        for (final autolevel in classData.autolevels) {
          builder.element('autolevel', attributes: {'level': autolevel.level},
              nest: () {
            for (final feature in autolevel.features) {
              builder.element('feature', nest: () {
                builder.element('name', nest: feature.name);
                builder.element('text', nest: feature.description);
              });
            }
            if (autolevel.slots != null) {
              builder.element('slots', nest: autolevel.slots!.slots.join(', '));
            }
          });
        }
      });
    });

    document.rootElement.children.add(builder.buildFragment());
  }
}
