import 'dart:isolate';
import 'package:dnd/classes/wiki_database_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart' as xml;
import 'package:dnd/classes/wiki_classes.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class WikiParser {
  final WikiDatabaseManager _dbManager = WikiDatabaseManager();

  // Data is now loaded from database on-demand
  Future<List<ClassData>> get classes async => _dbManager.getAllClasses();
  Future<List<RaceData>> get races async => _dbManager.getAllRaces();
  Future<List<BackgroundData>> get backgrounds async =>
      _dbManager.getAllBackgrounds();
  Future<List<FeatData>> get feats async => _dbManager.getAllFeats();
  Future<List<SpellData>> get spells async => _dbManager.getAllSpells();
  Future<List<Creature>> get creatures async => _dbManager.getAllCreatures();
  Future<List<ItemData>> get items async => _dbManager.getAllItems();

  WikiParser();

  Future<bool> isEmpty() async {
    final classesList = await classes;
    final racesList = await races;
    final backgroundsList = await backgrounds;
    return classesList.isEmpty ||
        racesList.isEmpty ||
        backgroundsList.isEmpty;
  }

  Future<void> loadXml() async {
    // Initialize database
    await _dbManager.database;

    // Perform automatic migration from legacy XML if needed
    await _performAutoMigration();
  }

  Future<void> _performAutoMigration() async {
    try {
      // Check if migration has already been done
      final migrationStatus = await _dbManager.getMigrationStatus();

      if (migrationStatus['migrated'] == true) {
        if (kDebugMode) {
          print('Wiki database already migrated.');
        }
        return;
      }

      // Check if database is empty (first time setup or fresh install)
      // Use efficient COUNT query instead of loading all data
      final isDatabaseEmpty = await _dbManager.isDatabaseEmpty();

      if (!isDatabaseEmpty) {
        // Database has data but migration flag not set, mark as migrated
        await _dbManager.setMigrationStatus(migrated: true);
        return;
      }

      // Try to find and import legacy XML file
      String savedFilePath = await _getLegacyXmlPath();
      File file = File(savedFilePath);

      if (await file.exists()) {
        if (kDebugMode) {
          print('🔄 Found legacy XML file at: $savedFilePath');
          print('🔄 Starting automatic migration to database...');
        }

        // Read and parse XML
        String xmlData = await file.readAsString();

        // Create backup of XML file before migration
        await _createBackup(file);

        // Import data into database
        await importXmlData(xmlData);

        // Mark migration as complete
        await _dbManager.setMigrationStatus(
          migrated: true,
          migrationDate: DateTime.now().toIso8601String(),
          sourceFile: savedFilePath,
        );

        if (kDebugMode) {
          print('✅ Migration completed successfully!');
          print('   - Legacy XML backed up');
          print('   - Data imported to database');
          print('   - Original XML preserved at: $savedFilePath');
        }
      } else {
        if (kDebugMode) {
          print('No legacy XML file found. Starting with empty database.');
        }

        // Mark as migrated even if no XML found (fresh install)
        await _dbManager.setMigrationStatus(
          migrated: true,
          migrationDate: DateTime.now().toIso8601String(),
          sourceFile: 'none',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during automatic migration: $e');
      }
      // Don't throw - allow app to continue with empty database
    }
  }

  Future<void> _createBackup(File originalFile) async {
    try {
      final backupPath = '${originalFile.path}.backup';
      final backupFile = File(backupPath);

      // Only create backup if it doesn't exist
      if (!await backupFile.exists()) {
        await originalFile.copy(backupPath);
        if (kDebugMode) {
          print('📦 Created backup at: $backupPath');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  Failed to create backup: $e');
      }
      // Continue even if backup fails
    }
  }

  Future<String> _getLegacyXmlPath() async {
    if (Platform.isWindows) {
      bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
      if (isDebugMode) {
        return './temp/wiki.xml';
      } else {
        Directory appSupportDir = await getApplicationSupportDirectory();
        return '${appSupportDir.path}/wiki.xml';
      }
    } else {
      Directory appSupportDir = await getApplicationSupportDirectory();
      return '${appSupportDir.path}/wiki.xml';
    }
  }

  Future<void> deleteXml() async {
    // Close DB, delete files, then recreate a fresh database
    // Clear all wiki data but keep the DB file itself.
    await _dbManager.clearDatabase();
    await _dbManager.database; // reinitialize
  }

  Future<void> importXml(String sourceFilePath) async {
    final sourceFile = File(sourceFilePath);
    final xmlData = await sourceFile.readAsString();
    await importXmlData(xmlData);
  }

  Future<void> importXmlData(String xmlData) async {
    if (kDebugMode) {
      print('📥 Starting XML import...');
      print('   XML data length: ${xmlData.length} characters');
    }

    final parsedData = await _parseXmlInIsolate(xmlData);

    if (kDebugMode) {
      print('   Parsed data:');
      print('   - Classes: ${(parsedData['classes'] as List).length}');
      print('   - Races: ${(parsedData['races'] as List).length}');
      print('   - Backgrounds: ${(parsedData['backgrounds'] as List).length}');
      print('   - Feats: ${(parsedData['feats'] as List).length}');
      print('   - Spells: ${(parsedData['spells'] as List).length}');
      print('   - Creatures: ${(parsedData['creatures'] as List).length}');
      print('   Importing all data in single transaction...');
    }

    // Use bulk import to handle everything in a single transaction
    await _dbManager.bulkImport(
      classes: parsedData['classes'] as List<ClassData>,
      races: parsedData['races'] as List<RaceData>,
      backgrounds: parsedData['backgrounds'] as List<BackgroundData>,
      feats: parsedData['feats'] as List<FeatData>,
      spells: parsedData['spells'] as List<SpellData>,
      creatures: parsedData['creatures'] as List<Creature>,
      items: parsedData['items'] as List<ItemData>,
    );

    if (kDebugMode) {
      print('✅ Imported XML data to database successfully');
    }
  }

  Future<void> exportXml() async {
    try {
      // Get all data from database
      final classesData = await _dbManager.getAllClasses();
      final racesData = await _dbManager.getAllRaces();
      final backgroundsData = await _dbManager.getAllBackgrounds();
      final featsData = await _dbManager.getAllFeats();
      final spellsData = await _dbManager.getAllSpells();
      final creaturesData = await _dbManager.getAllCreatures();

      // Build XML document
      final builder = xml.XmlBuilder();
      builder.processing('xml', 'version="1.0" encoding="UTF-8"');
      builder.element('compendium', attributes: {
        'version': '5',
        'auto_indent': 'NO',
      }, nest: () {
        builder.comment(' Items ');
        builder.comment(' Races ');
        for (var race in racesData) {
          _buildRaceXml(builder, race);
        }
        builder.comment(' Classes ');
        for (var classData in classesData) {
          _buildClassXml(builder, classData);
        }
        builder.comment(' Feats ');
        for (var feat in featsData) {
          _buildFeatXml(builder, feat);
        }
        builder.comment(' Backgrounds ');
        for (var background in backgroundsData) {
          _buildBackgroundXml(builder, background);
        }
        builder.comment(' Spells ');
        for (var spell in spellsData) {
          _buildSpellXml(builder, spell);
        }
        builder.comment(' Monsters ');
        for (var creature in creaturesData) {
          _buildCreatureXml(builder, creature);
        }
      });

      final xmlDocument = builder.buildDocument();
      final xmlString = xmlDocument.toXmlString(pretty: true, indent: '  ');

      // Export file
      if (Platform.isAndroid || Platform.isIOS) {
        // Create temp file for sharing
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/wiki_export.xml');
        await tempFile.writeAsString(xmlString);

        final shareFile = XFile(tempFile.path);
        await Share.shareXFiles([shareFile], text: 'Exported Wiki');

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
          await destinationFile.writeAsString(xmlString);
          if (kDebugMode) {
            print("XML file saved at: $destinationPath");
          }
        } else {
          throw Exception("Export abgebrochen.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error exporting XML: $e");
      }
      rethrow;
    }
  }

  void _buildClassXml(xml.XmlBuilder builder, ClassData classData) {
    builder.element('class', nest: () {
      builder.element('name', nest: classData.name);
      builder.element('hd', nest: classData.hd);
      builder.element('proficiency', nest: classData.proficiency);
      builder.element('numSkills', nest: classData.numSkills);

      for (final autolevel in classData.autolevels) {
        builder.element('autolevel', attributes: {'level': autolevel.level},
            nest: () {
          for (final feature in autolevel.features ?? []) {
            builder.element('feature', nest: () {
              builder.element('name', nest: feature.name);
              builder.element('text', nest: feature.description);
            });
          }
          if (autolevel.slots != null) {
            builder.element('slots', nest: autolevel.slots!.slots.join(','));
          }
        });
      }
    });
  }

  void _buildRaceXml(xml.XmlBuilder builder, RaceData raceData) {
    builder.element('race', nest: () {
      builder.element('name', nest: raceData.name);
      builder.element('size', nest: raceData.size);
      builder.element('speed', nest: raceData.speed.toString());
      builder.element('ability', nest: raceData.ability);
      builder.element('proficiency', nest: raceData.proficiency);
      builder.element('spellAbility', nest: raceData.spellAbility);

      for (final trait in raceData.traits) {
        builder.element('trait', nest: () {
          builder.element('name', nest: trait.name);
          builder.element('text', nest: trait.description);
        });
      }
    });
  }

  void _buildBackgroundXml(
      xml.XmlBuilder builder, BackgroundData backgroundData) {
    builder.element('background', nest: () {
      builder.element('name', nest: backgroundData.name);
      builder.element('proficiency', nest: backgroundData.proficiency);

      for (final trait in backgroundData.traits) {
        builder.element('trait', nest: () {
          builder.element('name', nest: trait.name);
          builder.element('text', nest: trait.description);
        });
      }
    });
  }

  void _buildFeatXml(xml.XmlBuilder builder, FeatData featData) {
    builder.element('feat', nest: () {
      builder.element('name', nest: featData.name);
      if (featData.prerequisite != null && featData.prerequisite!.isNotEmpty) {
        builder.element('prerequisite', nest: featData.prerequisite);
      }
      builder.element('text', nest: featData.text);
      if (featData.modifier != null && featData.modifier!.isNotEmpty) {
        builder.element('modifier', nest: featData.modifier);
      }
    });
  }

  void _buildSpellXml(xml.XmlBuilder builder, SpellData spellData) {
    builder.element('spell', nest: () {
      builder.element('name', nest: spellData.name);
      builder.element('level', nest: spellData.level);
      builder.element('school', nest: spellData.school);
      builder.element('ritual', nest: spellData.ritual);
      builder.element('time', nest: spellData.time);
      builder.element('range', nest: spellData.range);
      builder.element('components', nest: spellData.components);
      builder.element('duration', nest: spellData.duration);
      builder.element('classes', nest: spellData.classes.join(', '));
      builder.element('text', nest: spellData.text);
    });
  }

  void _buildCreatureXml(xml.XmlBuilder builder, Creature creature) {
    builder.element('monster', nest: () {
      builder.element('name', nest: creature.name);
      builder.element('size', nest: creature.size);
      builder.element('type', nest: creature.type);
      builder.element('alignment', nest: creature.alignment);
      builder.element('ac', nest: creature.ac.toString());
      builder.element('hp', nest: creature.maxHP.toString());
      builder.element('speed', nest: creature.speed);
      builder.element('str', nest: creature.str.toString());
      builder.element('dex', nest: creature.dex.toString());
      builder.element('con', nest: creature.con.toString());
      builder.element('int', nest: creature.intScore.toString());
      builder.element('wis', nest: creature.wis.toString());
      builder.element('cha', nest: creature.cha.toString());

      if (creature.saves.isNotEmpty)
        builder.element('save', nest: creature.saves);
      if (creature.skills.isNotEmpty)
        builder.element('skill', nest: creature.skills);
      if (creature.resistances.isNotEmpty)
        builder.element('resist', nest: creature.resistances);
      if (creature.vulnerabilities.isNotEmpty)
        builder.element('vulnerable', nest: creature.vulnerabilities);
      if (creature.immunities.isNotEmpty)
        builder.element('immune', nest: creature.immunities);
      if (creature.conditionImmunities.isNotEmpty)
        builder.element('conditionImmune', nest: creature.conditionImmunities);
      if (creature.senses.isNotEmpty)
        builder.element('senses', nest: creature.senses);
      builder.element('passive', nest: creature.passivePerception.toString());
      if (creature.languages.isNotEmpty)
        builder.element('languages', nest: creature.languages);
      builder.element('cr', nest: creature.cr);

      for (final trait in creature.traits) {
        builder.element('trait', nest: () {
          builder.element('name', nest: trait.name);
          builder.element('text', nest: trait.description);
        });
      }

      for (final action in creature.actions) {
        builder.element('action', nest: () {
          builder.element('name', nest: action.name);
          builder.element('text', nest: action.description);
          if (action.attack != null && action.attack!.isNotEmpty) {
            builder.element('attack', nest: action.attack);
          }
        });
      }

      for (final legendary in creature.legendaryActions) {
        builder.element('legendary', nest: () {
          builder.element('name', nest: legendary.name);
          builder.element('text', nest: legendary.description);
        });
      }
    });
  }

  Future<Map<String, List<dynamic>>> _parseXmlInIsolate(String xmlData) async {
    final response = ReceivePort();
    await Isolate.spawn(_parseXml, response.sendPort);

    final sendPort = await response.first as SendPort;
    final result = ReceivePort();
    sendPort.send([xmlData, result.sendPort]);

    return await result.first as Map<String, List<dynamic>>;
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
    List<ItemData> items = parseItems(document);

    return {
      'classes': classes,
      'races': races,
      'backgrounds': backgrounds,
      'feats': feats,
      'spells': spells,
      'creatures': creatures,
      'items': items,
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
      final spellAbility = classElement.findElements('spellAbility').isNotEmpty
          ? classElement.findElements('spellAbility').first.innerText
          : '';
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
        spellAbility: spellAbility,
        numSkills: numSkills,
        autolevels: autolevels,
      );
    }).toList();
  }
  static List<ItemData> parseItems(xml.XmlDocument document) {
    final itemElements = document.findAllElements('item');

    return itemElements.map((itemElement) {
      final name = itemElement.findElements('name').isNotEmpty
          ? itemElement.findElements('name').first.innerText
          : 'N/A';
      final type = itemElement.findElements('type').isNotEmpty
          ? itemElement.findElements('type').first.innerText
          : '';
      final weight = itemElement.findElements('weight').isNotEmpty
          ? itemElement.findElements('weight').first.innerText
          : '0';
      final value = itemElement.findElements('value').isNotEmpty
          ? itemElement.findElements('value').first.innerText
          : '0';
      final text = itemElement
          .findAllElements('text')
          .map((textElement) => textElement.innerText)
          .join('\n');

      return ItemData(
        name: name,
        type: type,
        weight: weight,
        value: value,
        text: text,
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

  // CRUD operations - now using database
  Future<void> addClass(ClassData classData) async {
    await _dbManager.insertClass(classData);
  }

  Future<void> deleteClassFromXml(
      xml.XmlDocument document, String className) async {
    await _dbManager.deleteClass(className);
  }

  Future<void> updateClassInXml(
      xml.XmlDocument document, String oldName, ClassData classData) async {
    await _dbManager.updateClass(oldName, classData);
  }

  Future<void> addRace(RaceData raceData) async {
    await _dbManager.insertRace(raceData);
  }

  Future<void> deleteRaceFromXml(
      xml.XmlDocument document, String raceName) async {
    await _dbManager.deleteRace(raceName);
  }

  Future<void> updateRaceInXml(
      xml.XmlDocument document, String oldName, RaceData raceData) async {
    await _dbManager.updateRace(oldName, raceData);
  }

  Future<void> addBackground(BackgroundData backgroundData) async {
    await _dbManager.insertBackground(backgroundData);
  }

  Future<void> deleteBackgroundFromXml(
      xml.XmlDocument document, String backgroundName) async {
    await _dbManager.deleteBackground(backgroundName);
  }

  Future<void> updateBackgroundInXml(xml.XmlDocument document, String oldName,
      BackgroundData backgroundData) async {
    await _dbManager.updateBackground(oldName, backgroundData);
  }

  Future<void> addFeat(FeatData featData) async {
    await _dbManager.insertFeat(featData);
  }

  Future<void> deleteFeatFromXml(
      xml.XmlDocument document, String featName) async {
    await _dbManager.deleteFeat(featName);
  }

  Future<void> updateFeatInXml(
      xml.XmlDocument document, String oldName, FeatData featData) async {
    await _dbManager.updateFeat(oldName, featData);
  }

  Future<void> addSpell(SpellData spellData) async {
    await _dbManager.insertSpell(spellData);
  }

  Future<void> deleteSpellFromXml(
      xml.XmlDocument document, String spellName) async {
    await _dbManager.deleteSpell(spellName);
  }

  Future<void> updateSpellInXml(
      xml.XmlDocument document, String oldName, SpellData spellData) async {
    await _dbManager.updateSpell(oldName, spellData);
  }

  Future<void> addCreature(Creature creature) async {
    await _dbManager.insertCreature(creature);
  }

  Future<void> deleteCreatureFromXml(
      xml.XmlDocument document, String creatureName) async {
    await _dbManager.deleteCreature(creatureName);
  }

  Future<void> updateCreatureInXml(
      xml.XmlDocument document, String oldName, Creature creature) async {
    await _dbManager.updateCreature(oldName, creature);
  }

  Future<void> addItem(ItemData item) async {
    await _dbManager.insertItem(item);
  }

  Future<void> deleteItemFromXml(
      xml.XmlDocument document, String itemName) async {
    await _dbManager.deleteItem(itemName);
  }

  Future<void> updateItemInXml(
      xml.XmlDocument document, String oldName, ItemData item) async {
    await _dbManager.updateItem(oldName, item);
  }
}
