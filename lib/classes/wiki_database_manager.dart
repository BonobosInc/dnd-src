import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/classes/wiki_database_schema.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xml/xml.dart' as xml;

class WikiDatabaseManager {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<String> _getPath() async {
    if (Platform.isWindows &&
        bool.fromEnvironment('dart.vm.product') == false) {
      return './temp/wiki.db';
    } else {
      final appSupportDir = await getApplicationSupportDirectory();
      return join(appSupportDir.path, 'wiki.db');
    }
  }

  Future<Database> _initDatabase() async {
    final path = await _getPath();
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    for (String statement in WikiDatabaseSchema.allTableStatements) {
      await db.execute(statement);
    }
    // Initialize version
    await db
        .insert('wiki_version', {'versionNumber': WikiDatabaseSchema.version});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add spellAbility column to wiki_classes table
      await db.execute('ALTER TABLE wiki_classes ADD COLUMN spellAbility TEXT');

      // Populate spellAbility from existing XML data
      await _populateSpellAbilityFromXml(db);
    }
  }

  Future<void> _populateSpellAbilityFromXml(Database db) async {
    try {
      // Find the XML file
      String xmlPath = await _getXmlPath();
      File xmlFile = File(xmlPath);

      if (!await xmlFile.exists()) {
        if (kDebugMode) {
          print('XML file not found at $xmlPath, skipping spellAbility population');
        }
        return;
      }

      // Read and parse XML
      String xmlData = await xmlFile.readAsString();
      final document = xml.XmlDocument.parse(xmlData);
      final classElements = document.findAllElements('class');

      // Update each class with its spellAbility
      for (var classElement in classElements) {
        final name = classElement.findElements('name').isNotEmpty
            ? classElement.findElements('name').first.innerText
            : null;
        final spellAbility = classElement.findElements('spellAbility').isNotEmpty
            ? classElement.findElements('spellAbility').first.innerText
            : '';

        if (name != null) {
          await db.update(
            'wiki_classes',
            {'spellAbility': spellAbility},
            where: 'name = ?',
            whereArgs: [name],
          );
        }
      }

      if (kDebugMode) {
        print('✅ Successfully populated spellAbility for all classes from XML');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error populating spellAbility: $e');
      }
      // Don't throw - migration can continue even if this fails
    }
  }

  Future<String> _getXmlPath() async {
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

  Future<void> clearDatabase() async {
    final db = await database;

    // Delete all wiki-related tables in a single transaction with retries
    const int maxAttempts = 4;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await db.transaction((txn) async {
          // Parent tables
          await txn.delete('wiki_classes');
          await txn.delete('wiki_races');
          await txn.delete('wiki_backgrounds');
          await txn.delete('wiki_feats');
          await txn.delete('wiki_spells');
          await txn.delete('wiki_creatures');

          // Child / related tables
          await txn.delete('wiki_class_autolevels');
          await txn.delete('wiki_class_features');
          await txn.delete('wiki_class_slots');
          await txn.delete('wiki_race_traits');
          await txn.delete('wiki_background_traits');
          await txn.delete('wiki_spell_classes');
          await txn.delete('wiki_creature_traits');
          await txn.delete('wiki_creature_actions');
          await txn.delete('wiki_creature_legendary');
        });
        break;
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('database is locked') && attempt < maxAttempts) {
          final delayMs = 150 * attempt;
          if (kDebugMode) {
            print(
                'clearDatabase locked, retrying in ${delayMs}ms (attempt $attempt)');
          }
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        rethrow;
      }
    }
  }

  // Migration status methods
  Future<Map<String, dynamic>> getMigrationStatus() async {
    final db = await database;
    final results = await db.query('wiki_migration', limit: 1);

    if (results.isEmpty) {
      return {
        'migrated': false,
        'migrationDate': null,
        'sourceFile': null,
      };
    }

    final row = results.first;
    return {
      'migrated': row['migrated'] == 1,
      'migrationDate': row['migrationDate'],
      'sourceFile': row['sourceFile'],
    };
  }

  Future<void> setMigrationStatus({
    required bool migrated,
    String? migrationDate,
    String? sourceFile,
  }) async {
    final db = await database;

    // Delete existing migration records
    await db.delete('wiki_migration');

    // Insert new migration status
    await db.insert('wiki_migration', {
      'migrated': migrated ? 1 : 0,
      'migrationDate': migrationDate,
      'sourceFile': sourceFile,
    });
  }

  // ==================== CLASSES ====================

  // Bulk import method - wraps all operations in a single transaction
  Future<void> bulkImport({
    required List<ClassData> classes,
    required List<RaceData> races,
    required List<BackgroundData> backgrounds,
    required List<FeatData> feats,
    required List<SpellData> spells,
    required List<Creature> creatures,
  }) async {
    final db = await database;

    const int maxAttempts = 5;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await db.transaction((txn) async {
          // Clear all tables first
          await txn.delete('wiki_classes');
          await txn.delete('wiki_races');
          await txn.delete('wiki_backgrounds');
          await txn.delete('wiki_feats');
          await txn.delete('wiki_spells');
          await txn.delete('wiki_creatures');

          // Insert all classes
          for (var classData in classes) {
            await _insertClassWithTxn(txn, classData);
          }

          // Insert all races
          for (var raceData in races) {
            await _insertRaceWithTxn(txn, raceData);
          }

          // Insert all backgrounds
          for (var backgroundData in backgrounds) {
            await _insertBackgroundWithTxn(txn, backgroundData);
          }

          // Insert all feats
          for (var featData in feats) {
            await _insertFeatWithTxn(txn, featData);
          }

          // Insert all spells
          for (var spellData in spells) {
            await _insertSpellWithTxn(txn, spellData);
          }

          // Insert all creatures
          for (var creature in creatures) {
            await _insertCreatureWithTxn(txn, creature);
          }
        });
        break; // success
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('database is locked') && attempt < maxAttempts) {
          // Wait and retry
          final delayMs = 200 * attempt;
          if (kDebugMode) {
            print(
                'Database locked during bulkImport, retrying in ${delayMs}ms (attempt $attempt)');
          }
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        rethrow;
      }
    }
  }

  Future<int> _insertClassWithTxn(Transaction txn, ClassData classData) async {
    final classId = await txn.insert('wiki_classes', {
      'name': classData.name,
      'hd': classData.hd,
      'proficiency': classData.proficiency,
      'spellAbility': classData.spellAbility,
      'numSkills': classData.numSkills,
    });

    for (var autolevel in classData.autolevels) {
      final autolevelId = await txn.insert('wiki_class_autolevels', {
        'classId': classId,
        'level': autolevel.level,
      });

      if (autolevel.features != null) {
        for (var feature in autolevel.features!) {
          await txn.insert('wiki_class_features', {
            'autolevelId': autolevelId,
            'name': feature.name,
            'description': feature.description,
            'type': feature.type,
          });
        }
      }

      if (autolevel.slots != null) {
        final slots = autolevel.slots!.slots;
        await txn.insert('wiki_class_slots', {
          'autolevelId': autolevelId,
          'slot1': slots.length > 0 ? slots[0] : null,
          'slot2': slots.length > 1 ? slots[1] : null,
          'slot3': slots.length > 2 ? slots[2] : null,
          'slot4': slots.length > 3 ? slots[3] : null,
          'slot5': slots.length > 4 ? slots[4] : null,
          'slot6': slots.length > 5 ? slots[5] : null,
          'slot7': slots.length > 6 ? slots[6] : null,
          'slot8': slots.length > 7 ? slots[7] : null,
          'slot9': slots.length > 8 ? slots[8] : null,
        });
      }
    }

    return classId;
  }

  Future<int> _insertRaceWithTxn(Transaction txn, RaceData raceData) async {
    final raceId = await txn.insert('wiki_races', {
      'name': raceData.name,
      'size': raceData.size,
      'speed': raceData.speed,
      'ability': raceData.ability,
      'proficiency': raceData.proficiency,
      'spellAbility': raceData.spellAbility,
    });

    for (var trait in raceData.traits) {
      await txn.insert('wiki_race_traits', {
        'raceId': raceId,
        'name': trait.name,
        'description': trait.description,
      });
    }

    return raceId;
  }

  Future<int> _insertBackgroundWithTxn(
      Transaction txn, BackgroundData backgroundData) async {
    final backgroundId = await txn.insert('wiki_backgrounds', {
      'name': backgroundData.name,
      'proficiency': backgroundData.proficiency,
    });

    for (var trait in backgroundData.traits) {
      await txn.insert('wiki_background_traits', {
        'backgroundId': backgroundId,
        'name': trait.name,
        'description': trait.description,
      });
    }

    return backgroundId;
  }

  Future<int> _insertFeatWithTxn(Transaction txn, FeatData featData) async {
    return await txn.insert('wiki_feats', {
      'name': featData.name,
      'prerequisite': featData.prerequisite,
      'text': featData.text,
      'modifier': featData.modifier,
    });
  }

  Future<int> _insertSpellWithTxn(Transaction txn, SpellData spellData) async {
    final spellId = await txn.insert('wiki_spells', {
      'name': spellData.name,
      'level': spellData.level,
      'school': spellData.school,
      'ritual': spellData.ritual,
      'time': spellData.time,
      'range': spellData.range,
      'components': spellData.components,
      'duration': spellData.duration,
      'text': spellData.text,
    });

    for (var className in spellData.classes) {
      await txn.insert('wiki_spell_classes', {
        'spellId': spellId,
        'className': className,
      });
    }

    return spellId;
  }

  Future<int> _insertCreatureWithTxn(Transaction txn, Creature creature) async {
    final creatureId = await txn.insert('wiki_creatures', {
      'name': creature.name,
      'size': creature.size,
      'type': creature.type,
      'alignment': creature.alignment,
      'ac': creature.ac,
      'maxHP': creature.maxHP,
      'speed': creature.speed,
      'str': creature.str,
      'dex': creature.dex,
      'con': creature.con,
      'int': creature.intScore,
      'wis': creature.wis,
      'cha': creature.cha,
      'saves': creature.saves,
      'skills': creature.skills,
      'resistances': creature.resistances,
      'vulnerabilities': creature.vulnerabilities,
      'immunities': creature.immunities,
      'conditionImmunities': creature.conditionImmunities,
      'senses': creature.senses,
      'passivePerception': creature.passivePerception,
      'languages': creature.languages,
      'cr': creature.cr,
    });

    for (var trait in creature.traits) {
      await txn.insert('wiki_creature_traits', {
        'creatureId': creatureId,
        'name': trait.name,
        'description': trait.description,
      });
    }

    for (var action in creature.actions) {
      await txn.insert('wiki_creature_actions', {
        'creatureId': creatureId,
        'name': action.name,
        'description': action.description,
        'attack': action.attack,
      });
    }

    for (var legendary in creature.legendaryActions) {
      await txn.insert('wiki_creature_legendary', {
        'creatureId': creatureId,
        'name': legendary.name,
        'description': legendary.description,
      });
    }

    return creatureId;
  }

  // ==================== CLASSES ====================

  Future<int> insertClass(ClassData classData) async {
    final db = await database;
    return await db.transaction((txn) async {
      final classId = await txn.insert('wiki_classes', {
        'name': classData.name,
        'hd': classData.hd,
        'proficiency': classData.proficiency,
        'spellAbility': classData.spellAbility,
        'numSkills': classData.numSkills,
      });

      for (var autolevel in classData.autolevels) {
        final autolevelId = await txn.insert('wiki_class_autolevels', {
          'classId': classId,
          'level': autolevel.level,
        });

        if (autolevel.features != null) {
          for (var feature in autolevel.features!) {
            await txn.insert('wiki_class_features', {
              'autolevelId': autolevelId,
              'name': feature.name,
              'description': feature.description,
              'type': feature.type,
            });
          }
        }

        if (autolevel.slots != null) {
          final slots = autolevel.slots!.slots;
          await txn.insert('wiki_class_slots', {
            'autolevelId': autolevelId,
            'slot1': slots.length > 0 ? slots[0] : null,
            'slot2': slots.length > 1 ? slots[1] : null,
            'slot3': slots.length > 2 ? slots[2] : null,
            'slot4': slots.length > 3 ? slots[3] : null,
            'slot5': slots.length > 4 ? slots[4] : null,
            'slot6': slots.length > 5 ? slots[5] : null,
            'slot7': slots.length > 6 ? slots[6] : null,
            'slot8': slots.length > 7 ? slots[7] : null,
            'slot9': slots.length > 8 ? slots[8] : null,
          });
        }
      }

      return classId;
    });
  }

  /// Efficiently checks if the wiki database is empty using COUNT queries.
  /// This is much faster than loading all data with getAllClasses/getAllRaces/getAllCreatures.
  Future<bool> isDatabaseEmpty() async {
    final db = await database;

    // Use a single query with UNION to check all tables at once
    final result = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM wiki_classes) +
        (SELECT COUNT(*) FROM wiki_races) +
        (SELECT COUNT(*) FROM wiki_creatures) AS total_count
    ''');

    final totalCount = result.first['total_count'] as int;
    return totalCount == 0;
  }

  Future<List<ClassData>> getAllClasses() async {
    final db = await database;
    final classMaps = await db.query('wiki_classes', orderBy: 'name ASC');

    if (classMaps.isEmpty) return [];

    final classIds = classMaps.map((m) => m['id'] as int).toList();

    // Fetch autolevels for all classes in one query
    final autolevelsMaps = await db.query(
      'wiki_class_autolevels',
      where: 'classId IN (${List.filled(classIds.length, '?').join(',')})',
      whereArgs: classIds,
      orderBy: 'CAST(level AS INTEGER) ASC',
    );

    final autolevelIds = autolevelsMaps.map((m) => m['id'] as int).toList();

    // Fetch features and slots in bulk
    final featureMaps = autolevelIds.isNotEmpty
        ? await db.query(
            'wiki_class_features',
            where:
                'autolevelId IN (${List.filled(autolevelIds.length, '?').join(',')})',
            whereArgs: autolevelIds,
          )
        : <Map<String, Object?>>[];

    final slotMaps = autolevelIds.isNotEmpty
        ? await db.query(
            'wiki_class_slots',
            where:
                'autolevelId IN (${List.filled(autolevelIds.length, '?').join(',')})',
            whereArgs: autolevelIds,
          )
        : <Map<String, Object?>>[];

    // Group autolevels by classId
    final autolevelsByClass = <int, List<Map<String, Object?>>>{};
    for (var a in autolevelsMaps) {
      final cid = a['classId'] as int;
      autolevelsByClass.putIfAbsent(cid, () => []).add(a);
    }

    // Group features and slots by autolevelId
    final featuresByAutolevel = <int, List<Map<String, Object?>>>{};
    for (var f in featureMaps) {
      final aid = f['autolevelId'] as int;
      featuresByAutolevel.putIfAbsent(aid, () => []).add(f);
    }

    final slotsByAutolevel = <int, Map<String, Object?>>{};
    for (var s in slotMaps) {
      final aid = s['autolevelId'] as int;
      slotsByAutolevel[aid] = s;
    }

    List<ClassData> result = [];
    for (var classMap in classMaps) {
      final classId = classMap['id'] as int;
      final autolevelsForClass = autolevelsByClass[classId] ?? [];

      List<Autolevel> autolevels = [];
      for (var autolevelMap in autolevelsForClass) {
        final autolevelId = autolevelMap['id'] as int;

        final featureList = featuresByAutolevel[autolevelId];
        List<FeatureData>? features =
            featureList != null && featureList.isNotEmpty
                ? featureList
                    .map((f) => FeatureData(
                          name: f['name'] as String? ?? '',
                          description: f['description'] as String? ?? '',
                          type: f['type'] as String?,
                        ))
                    .toList()
                : null;

        Slots? slots;
        final slotMap = slotsByAutolevel[autolevelId];
        if (slotMap != null) {
          List<int> slotList = [];
          for (int i = 1; i <= 9; i++) {
            final value = slotMap['slot$i'];
            if (value != null) slotList.add(value as int);
          }
          if (slotList.isNotEmpty) slots = Slots(slots: slotList);
        }

        autolevels.add(Autolevel(
          level: autolevelMap['level'] as String,
          features: features,
          slots: slots,
        ));
      }

      result.add(ClassData(
        name: classMap['name'] as String,
        hd: classMap['hd'] as String? ?? '',
        proficiency: classMap['proficiency'] as String? ?? '',
        spellAbility: classMap['spellAbility'] as String? ?? '',
        numSkills: classMap['numSkills'] as String? ?? '',
        autolevels: autolevels,
      ));
    }

    return result;
  }

  Future<void> deleteClass(String name) async {
    final db = await database;
    await db.transaction((txn) async {
      final classMaps =
          await txn.query('wiki_classes', where: 'name = ?', whereArgs: [name]);
      if (classMaps.isEmpty) return;

      final classId = classMaps.first['id'] as int;
      final autolevelMaps = await txn.query('wiki_class_autolevels',
          where: 'classId = ?', whereArgs: [classId]);

      for (var autolevelMap in autolevelMaps) {
        final autolevelId = autolevelMap['id'] as int;
        await txn.delete('wiki_class_features',
            where: 'autolevelId = ?', whereArgs: [autolevelId]);
        await txn.delete('wiki_class_slots',
            where: 'autolevelId = ?', whereArgs: [autolevelId]);
      }

      await txn.delete('wiki_class_autolevels',
          where: 'classId = ?', whereArgs: [classId]);
      await txn.delete('wiki_classes', where: 'id = ?', whereArgs: [classId]);
    });
  }

  Future<void> updateClass(String oldName, ClassData newData) async {
    await deleteClass(oldName);
    await insertClass(newData);
  }

  // ==================== RACES ====================

  Future<int> insertRace(RaceData raceData) async {
    final db = await database;
    return await db.transaction((txn) async {
      final raceId = await txn.insert('wiki_races', {
        'name': raceData.name,
        'size': raceData.size,
        'speed': raceData.speed,
        'ability': raceData.ability,
        'proficiency': raceData.proficiency,
        'spellAbility': raceData.spellAbility,
      });

      for (var trait in raceData.traits) {
        await txn.insert('wiki_race_traits', {
          'raceId': raceId,
          'name': trait.name,
          'description': trait.description,
        });
      }

      return raceId;
    });
  }

  Future<List<RaceData>> getAllRaces() async {
    final db = await database;
    final raceMaps = await db.query('wiki_races', orderBy: 'name ASC');

    if (raceMaps.isEmpty) return [];

    final raceIds = raceMaps.map((m) => m['id'] as int).toList();

    // Fetch all traits in one query
    final traitMaps = await db.query(
      'wiki_race_traits',
      where: 'raceId IN (${List.filled(raceIds.length, '?').join(',')})',
      whereArgs: raceIds,
    );

    // Group traits by raceId
    final traitsByRace = <int, List<Map<String, Object?>>>{};
    for (var t in traitMaps) {
      final raceId = t['raceId'] as int;
      traitsByRace.putIfAbsent(raceId, () => []).add(t);
    }

    List<RaceData> result = [];
    for (var raceMap in raceMaps) {
      final raceId = raceMap['id'] as int;
      final traitList = traitsByRace[raceId] ?? [];

      List<FeatureData> traits = traitList
          .map((t) => FeatureData(
                name: t['name'] as String? ?? '',
                description: t['description'] as String? ?? '',
              ))
          .toList();

      result.add(RaceData(
        name: raceMap['name'] as String,
        size: raceMap['size'] as String? ?? '',
        speed: raceMap['speed'] as int? ?? 0,
        ability: raceMap['ability'] as String? ?? '',
        proficiency: raceMap['proficiency'] as String? ?? '',
        spellAbility: raceMap['spellAbility'] as String? ?? '',
        traits: traits,
      ));
    }

    return result;
  }

  Future<void> deleteRace(String name) async {
    final db = await database;
    await db.transaction((txn) async {
      final raceMaps =
          await txn.query('wiki_races', where: 'name = ?', whereArgs: [name]);
      if (raceMaps.isEmpty) return;

      final raceId = raceMaps.first['id'] as int;
      await txn
          .delete('wiki_race_traits', where: 'raceId = ?', whereArgs: [raceId]);
      await txn.delete('wiki_races', where: 'id = ?', whereArgs: [raceId]);
    });
  }

  Future<void> updateRace(String oldName, RaceData newData) async {
    await deleteRace(oldName);
    await insertRace(newData);
  }

  // ==================== BACKGROUNDS ====================

  Future<int> insertBackground(BackgroundData backgroundData) async {
    final db = await database;
    return await db.transaction((txn) async {
      final backgroundId = await txn.insert('wiki_backgrounds', {
        'name': backgroundData.name,
        'proficiency': backgroundData.proficiency,
      });

      for (var trait in backgroundData.traits) {
        await txn.insert('wiki_background_traits', {
          'backgroundId': backgroundId,
          'name': trait.name,
          'description': trait.description,
        });
      }

      return backgroundId;
    });
  }

  Future<List<BackgroundData>> getAllBackgrounds() async {
    final db = await database;
    final backgroundMaps =
        await db.query('wiki_backgrounds', orderBy: 'name ASC');

    if (backgroundMaps.isEmpty) return [];

    final backgroundIds = backgroundMaps.map((m) => m['id'] as int).toList();

    // Fetch all traits in one query
    final traitMaps = await db.query(
      'wiki_background_traits',
      where:
          'backgroundId IN (${List.filled(backgroundIds.length, '?').join(',')})',
      whereArgs: backgroundIds,
    );

    // Group traits by backgroundId
    final traitsByBackground = <int, List<Map<String, Object?>>>{};
    for (var t in traitMaps) {
      final backgroundId = t['backgroundId'] as int;
      traitsByBackground.putIfAbsent(backgroundId, () => []).add(t);
    }

    List<BackgroundData> result = [];
    for (var backgroundMap in backgroundMaps) {
      final backgroundId = backgroundMap['id'] as int;
      final traitList = traitsByBackground[backgroundId] ?? [];

      List<FeatureData> traits = traitList
          .map((t) => FeatureData(
                name: t['name'] as String? ?? '',
                description: t['description'] as String? ?? '',
              ))
          .toList();

      result.add(BackgroundData(
        name: backgroundMap['name'] as String,
        proficiency: backgroundMap['proficiency'] as String? ?? '',
        traits: traits,
      ));
    }

    return result;
  }

  Future<void> deleteBackground(String name) async {
    final db = await database;
    await db.transaction((txn) async {
      final backgroundMaps = await txn
          .query('wiki_backgrounds', where: 'name = ?', whereArgs: [name]);
      if (backgroundMaps.isEmpty) return;

      final backgroundId = backgroundMaps.first['id'] as int;
      await txn.delete('wiki_background_traits',
          where: 'backgroundId = ?', whereArgs: [backgroundId]);
      await txn.delete('wiki_backgrounds',
          where: 'id = ?', whereArgs: [backgroundId]);
    });
  }

  Future<void> updateBackground(String oldName, BackgroundData newData) async {
    await deleteBackground(oldName);
    await insertBackground(newData);
  }

  // ==================== FEATS ====================

  Future<int> insertFeat(FeatData featData) async {
    final db = await database;
    return await db.insert('wiki_feats', {
      'name': featData.name,
      'prerequisite': featData.prerequisite,
      'text': featData.text,
      'modifier': featData.modifier,
    });
  }

  Future<List<FeatData>> getAllFeats() async {
    final db = await database;
    final featMaps = await db.query('wiki_feats', orderBy: 'name ASC');

    return featMaps
        .map((f) => FeatData(
              name: f['name'] as String,
              prerequisite: f['prerequisite'] as String?,
              text: f['text'] as String? ?? '',
              modifier: f['modifier'] as String?,
            ))
        .toList();
  }

  Future<void> deleteFeat(String name) async {
    final db = await database;
    await db.delete('wiki_feats', where: 'name = ?', whereArgs: [name]);
  }

  Future<void> updateFeat(String oldName, FeatData newData) async {
    final db = await database;
    await db.update(
      'wiki_feats',
      {
        'name': newData.name,
        'prerequisite': newData.prerequisite,
        'text': newData.text,
        'modifier': newData.modifier,
      },
      where: 'name = ?',
      whereArgs: [oldName],
    );
  }

  // ==================== SPELLS ====================

  Future<int> insertSpell(SpellData spellData) async {
    final db = await database;
    return await db.transaction((txn) async {
      final spellId = await txn.insert('wiki_spells', {
        'name': spellData.name,
        'level': spellData.level,
        'school': spellData.school,
        'ritual': spellData.ritual,
        'time': spellData.time,
        'range': spellData.range,
        'components': spellData.components,
        'duration': spellData.duration,
        'text': spellData.text,
      });

      for (var className in spellData.classes) {
        await txn.insert('wiki_spell_classes', {
          'spellId': spellId,
          'className': className,
        });
      }

      return spellId;
    });
  }

  Future<List<SpellData>> getAllSpells() async {
    final db = await database;
    final spellMaps = await db.query('wiki_spells', orderBy: 'name ASC');

    if (spellMaps.isEmpty) return [];

    final spellIds = spellMaps.map((m) => m['id'] as int).toList();

    // Fetch all spell classes in one query
    final classMaps = await db.query(
      'wiki_spell_classes',
      where: 'spellId IN (${List.filled(spellIds.length, '?').join(',')})',
      whereArgs: spellIds,
    );

    // Group classes by spellId
    final classesBySpell = <int, List<String>>{};
    for (var c in classMaps) {
      final spellId = c['spellId'] as int;
      classesBySpell
          .putIfAbsent(spellId, () => [])
          .add(c['className'] as String);
    }

    List<SpellData> result = [];
    for (var spellMap in spellMaps) {
      final spellId = spellMap['id'] as int;
      final classes = classesBySpell[spellId] ?? [];

      result.add(SpellData(
        name: spellMap['name'] as String,
        level: spellMap['level'] as String? ?? '',
        school: spellMap['school'] as String? ?? '',
        ritual: spellMap['ritual'] as String? ?? '',
        time: spellMap['time'] as String? ?? '',
        range: spellMap['range'] as String? ?? '',
        components: spellMap['components'] as String? ?? '',
        duration: spellMap['duration'] as String? ?? '',
        text: spellMap['text'] as String? ?? '',
        classes: classes,
      ));
    }

    return result;
  }

  Future<void> deleteSpell(String name) async {
    final db = await database;
    await db.transaction((txn) async {
      final spellMaps =
          await txn.query('wiki_spells', where: 'name = ?', whereArgs: [name]);
      if (spellMaps.isEmpty) return;

      final spellId = spellMaps.first['id'] as int;
      await txn.delete('wiki_spell_classes',
          where: 'spellId = ?', whereArgs: [spellId]);
      await txn.delete('wiki_spells', where: 'id = ?', whereArgs: [spellId]);
    });
  }

  Future<void> updateSpell(String oldName, SpellData newData) async {
    await deleteSpell(oldName);
    await insertSpell(newData);
  }

  // ==================== CREATURES ====================

  Future<int> insertCreature(Creature creature) async {
    final db = await database;
    return await db.transaction((txn) async {
      final creatureId = await txn.insert('wiki_creatures', {
        'name': creature.name,
        'size': creature.size,
        'type': creature.type,
        'alignment': creature.alignment,
        'ac': creature.ac,
        'maxHP': creature.maxHP,
        'speed': creature.speed,
        'str': creature.str,
        'dex': creature.dex,
        'con': creature.con,
        'int': creature.intScore,
        'wis': creature.wis,
        'cha': creature.cha,
        'saves': creature.saves,
        'skills': creature.skills,
        'resistances': creature.resistances,
        'vulnerabilities': creature.vulnerabilities,
        'immunities': creature.immunities,
        'conditionImmunities': creature.conditionImmunities,
        'senses': creature.senses,
        'passivePerception': creature.passivePerception,
        'languages': creature.languages,
        'cr': creature.cr,
      });

      for (var trait in creature.traits) {
        await txn.insert('wiki_creature_traits', {
          'creatureId': creatureId,
          'name': trait.name,
          'description': trait.description,
        });
      }

      for (var action in creature.actions) {
        await txn.insert('wiki_creature_actions', {
          'creatureId': creatureId,
          'name': action.name,
          'description': action.description,
          'attack': action.attack,
        });
      }

      for (var legendary in creature.legendaryActions) {
        await txn.insert('wiki_creature_legendary', {
          'creatureId': creatureId,
          'name': legendary.name,
          'description': legendary.description,
        });
      }

      return creatureId;
    });
  }

  Future<List<Creature>> getAllCreatures() async {
    final db = await database;
    final creatureMaps = await db.query('wiki_creatures', orderBy: 'name ASC');

    if (creatureMaps.isEmpty) return [];

    final creatureIds = creatureMaps.map((m) => m['id'] as int).toList();
    final placeholders = List.filled(creatureIds.length, '?').join(',');

    // Fetch all related data in bulk (3 queries instead of 3N)
    final traitMaps = await db.query(
      'wiki_creature_traits',
      where: 'creatureId IN ($placeholders)',
      whereArgs: creatureIds,
    );

    final actionMaps = await db.query(
      'wiki_creature_actions',
      where: 'creatureId IN ($placeholders)',
      whereArgs: creatureIds,
    );

    final legendaryMaps = await db.query(
      'wiki_creature_legendary',
      where: 'creatureId IN ($placeholders)',
      whereArgs: creatureIds,
    );

    // Group by creatureId
    final traitsByCreature = <int, List<Map<String, Object?>>>{};
    for (var t in traitMaps) {
      final creatureId = t['creatureId'] as int;
      traitsByCreature.putIfAbsent(creatureId, () => []).add(t);
    }

    final actionsByCreature = <int, List<Map<String, Object?>>>{};
    for (var a in actionMaps) {
      final creatureId = a['creatureId'] as int;
      actionsByCreature.putIfAbsent(creatureId, () => []).add(a);
    }

    final legendaryByCreature = <int, List<Map<String, Object?>>>{};
    for (var l in legendaryMaps) {
      final creatureId = l['creatureId'] as int;
      legendaryByCreature.putIfAbsent(creatureId, () => []).add(l);
    }

    List<Creature> result = [];
    for (var creatureMap in creatureMaps) {
      final creatureId = creatureMap['id'] as int;

      List<Trait> traits = (traitsByCreature[creatureId] ?? [])
          .map((t) => Trait(
                name: t['name'] as String? ?? '',
                description: t['description'] as String? ?? '',
              ))
          .toList();

      List<CAction> actions = (actionsByCreature[creatureId] ?? [])
          .map((a) => CAction(
                name: a['name'] as String? ?? '',
                description: a['description'] as String? ?? '',
                attack: a['attack'] as String?,
              ))
          .toList();

      List<Legendary> legendaryActions = (legendaryByCreature[creatureId] ?? [])
          .map((l) => Legendary(
                name: l['name'] as String? ?? '',
                description: l['description'] as String? ?? '',
              ))
          .toList();

      result.add(Creature(
        name: creatureMap['name'] as String,
        size: creatureMap['size'] as String? ?? '',
        type: creatureMap['type'] as String? ?? '',
        alignment: creatureMap['alignment'] as String? ?? '',
        ac: creatureMap['ac'] as int? ?? 0,
        maxHP: creatureMap['maxHP'] as int? ?? 0,
        currentHP: creatureMap['maxHP'] as int? ?? 0,
        speed: creatureMap['speed'] as String? ?? '',
        str: creatureMap['str'] as int? ?? 0,
        dex: creatureMap['dex'] as int? ?? 0,
        con: creatureMap['con'] as int? ?? 0,
        intScore: creatureMap['int'] as int? ?? 0,
        wis: creatureMap['wis'] as int? ?? 0,
        cha: creatureMap['cha'] as int? ?? 0,
        saves: creatureMap['saves'] as String? ?? '',
        skills: creatureMap['skills'] as String? ?? '',
        resistances: creatureMap['resistances'] as String? ?? '',
        vulnerabilities: creatureMap['vulnerabilities'] as String? ?? '',
        immunities: creatureMap['immunities'] as String? ?? '',
        conditionImmunities:
            creatureMap['conditionImmunities'] as String? ?? '',
        senses: creatureMap['senses'] as String? ?? '',
        passivePerception: creatureMap['passivePerception'] as int? ?? 0,
        languages: creatureMap['languages'] as String? ?? '',
        cr: creatureMap['cr'] as String? ?? '',
        traits: traits,
        actions: actions,
        legendaryActions: legendaryActions,
      ));
    }

    return result;
  }

  Future<void> deleteCreature(String name) async {
    final db = await database;
    await db.transaction((txn) async {
      final creatureMaps = await txn
          .query('wiki_creatures', where: 'name = ?', whereArgs: [name]);
      if (creatureMaps.isEmpty) return;

      final creatureId = creatureMaps.first['id'] as int;
      await txn.delete('wiki_creature_traits',
          where: 'creatureId = ?', whereArgs: [creatureId]);
      await txn.delete('wiki_creature_actions',
          where: 'creatureId = ?', whereArgs: [creatureId]);
      await txn.delete('wiki_creature_legendary',
          where: 'creatureId = ?', whereArgs: [creatureId]);
      await txn
          .delete('wiki_creatures', where: 'id = ?', whereArgs: [creatureId]);
    });
  }

  Future<void> updateCreature(String oldName, Creature newData) async {
    await deleteCreature(oldName);
    await insertCreature(newData);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }

  /// Close the database and delete the database files from disk.
  Future<void> deleteDatabaseFiles() async {
    try {
      // Close existing connection if any
      if (_db != null) {
        await _db!.close();
        _db = null;
      }
    } catch (e) {
      // ignore close errors
    }

    try {
      final path = await _getPath();
      final dbFile = File(path);
      final shmFile = File('$path-shm');
      final walFile = File('$path-wal');

      if (await dbFile.exists()) await dbFile.delete();
      if (await shmFile.exists()) await shmFile.delete();
      if (await walFile.exists()) await walFile.delete();
    } catch (e) {
      // ignore delete errors
    }
  }
}
