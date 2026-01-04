import 'dart:io';
import 'package:dnd/classes/database_schema.dart';
import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/configs/version.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xml/xml.dart';
import 'package:dnd/configs/defines.dart';
import 'package:dnd/classes/pdf_editor.dart';

class Character {
  final int id;
  final String name;

  Character({required this.id, required this.name});
}

class ProfileManager {
  List<Character> profiles = [];
  String? selectedProfile;
  int? selectedID;
  Database? currentDb;

  Future<void> initialize() async {
    await loadProfiles();
    await initializeAppDatabase();
  }

  Future<void> initializeAppDatabase() async {
    final dbPath = await _getPath();
    final db = await openDatabase(dbPath, version: 1);

    if (profiles.isNotEmpty) {
      await updateDatabaseIfOutdated(db);
    }

    if (kDebugMode) {
      print('Database initialization completed.');
    }
  }

  Future<String> _getPath() async {
    if (Platform.isAndroid ||
        (Platform.isWindows &&
            bool.fromEnvironment('dart.vm.product') == false)) {
      final databasesPath = await getDatabasesPath();
      return join(databasesPath, 'characters.db');
    } else {
      final appSupportDir = await getApplicationSupportDirectory();
      return join(appSupportDir.path, 'characters.db');
    }
  }

  Future<void> loadProfiles() async {
    final dbPath = await _getPath();

    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      if (kDebugMode) {
        print("Database doesn't exist yet.");
      }
      return;
    }

    // Use currentDb if it's already open, otherwise open a temporary connection
    final bool useCurrentDb = currentDb != null && currentDb!.isOpen;
    final db = useCurrentDb ? currentDb! : await openDatabase(dbPath);

    try {
      final List<Map<String, dynamic>> results = await db.query('info');

      profiles.clear();

      for (var result in results) {
        Character character = Character(
          id: result['charId'],
          name: result['name'],
        );

        profiles.add(character);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error querying the database: $e");
      }
    } finally {
      // Only close the database if we opened a temporary connection
      if (!useCurrentDb) {
        await db.close();
      }
    }
  }

  Future<bool> isDatabaseVersionOutdated(Database db) async {
    try {
      final versionResult =
          await db.rawQuery('SELECT versionNumber FROM version WHERE ID = 1');

      if (versionResult.isNotEmpty) {
        final dbVersion = versionResult.first['versionNumber'] as String;

        if (_compareVersions(appVersion, dbVersion) > 0) {
          return true;
        }
      } else {
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking database version: $e');
      }
      return true;
    }

    return false;
  }

  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    for (int i = 0; i < v1Parts.length; i++) {
      final v1Part = v1Parts[i];
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1Part > v2Part) return 1;
      if (v1Part < v2Part) return -1;
    }

    return 0;
  }

  Future<void> updateDatabaseIfOutdated(Database db) async {
    await db.execute(DatabaseSchema.versionTable());

    final versionCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM version'));
    if (versionCount == 0) {
      await db.insert('version', {'versionNumber': 0});
    }

    final isOutdated = await isDatabaseVersionOutdated(db);

    if (!isOutdated) {
      if (kDebugMode) {
        print('Database is up-to-date.');
      }
      return;
    }

    // First, check for missing tables and create them
    var columns = DatabaseSchema.getAllColumns();

    for (String tableName in columns.keys) {
      final tableExists = await _tableExists(db, tableName);

      if (!tableExists) {
        // Create the entire table
        final createTableQuery = DatabaseSchema.createTable(tableName);
        if (createTableQuery.isNotEmpty) {
          await db.execute(createTableQuery);
          if (kDebugMode) {
            print('Created missing table: $tableName');
          }
        }
      }
    }

    // Then, check for missing columns in existing tables
    for (String table in columns.keys) {
      final tableColumns = columns[table]!;

      final existingColumns = await db.rawQuery('PRAGMA table_info($table)');

      final existingColumnNames =
          existingColumns.map((col) => col['name'] as String).toList();

      final missingColumns = tableColumns
          .where((col) => !existingColumnNames.contains(col['name']))
          .toList();

      for (var column in missingColumns) {
        await _addColumn(db, table, column);
      }
    }

    await db.rawUpdate(
        'UPDATE version SET versionNumber = ? WHERE ID = 1', [appVersion]);

    if (kDebugMode) {
      print('Database schema updated to appVersion: $appVersion');
    }
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<void> _addColumn(
      Database db, String table, Map<String, String> column) async {
    final columnName = column['name'];
    final columnType = column['type'];

    final result = await db.rawQuery('PRAGMA table_info($table);');

    bool columnExists = false;
    for (var row in result) {
      if (row['name'] == columnName) {
        columnExists = true;
        break;
      }
    }

    if (!columnExists) {
      String sql = 'ALTER TABLE $table ADD COLUMN $columnName $columnType';
      await db.execute(sql);

      if (kDebugMode) {
        print('Added missing column $columnName ($columnType) to table $table');
      }
    } else {
      if (kDebugMode) {
        print('Column $columnName already exists in table $table');
      }
    }
  }

  Future<void> initializeDatabase(Database db, String profileName) async {
    var initialInfo = {
      Defines.infoName: profileName,
      Defines.infoRace: '',
      Defines.infoClass: '',
      Defines.infoOrigin: '',
      Defines.infoBackground: '',
      Defines.infoPersonalityTraits: '',
      Defines.infoIdeals: '',
      Defines.infoBonds: '',
      Defines.infoFlaws: '',
      Defines.infoAge: '',
      Defines.infoGod: '',
      Defines.infoSize: '',
      Defines.infoHeight: '',
      Defines.infoWeight: '',
      Defines.infoSex: '',
      Defines.infoAlignment: '',
      Defines.infoEyeColour: '',
      Defines.infoHairColour: '',
      Defines.infoSkinColour: '',
      Defines.infoAppearance: '',
      Defines.infoSpellcastingClass: '',
      Defines.infoSpellcastingAbility: '',
    };

    await db.transaction((txn) async {
      int insertedCharId = await txn.insert('info', initialInfo);

      var initialSave = {
        'charId': insertedCharId,
        Defines.saveStr: 0,
        Defines.saveDex: 0,
        Defines.saveCon: 0,
        Defines.saveInt: 0,
        Defines.saveWis: 0,
        Defines.saveCha: 0,
      };
      await txn.insert('savingthrow', initialSave);

      var initialSkills = [
        {
          'charId': insertedCharId,
          'skill': Defines.skillAcrobatics,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillAnimalHandling,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillArcana,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillAthletics,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillDeception,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillHistory,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillInsight,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillIntimidation,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillInvestigation,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillMedicine,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillNature,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillPerception,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillPerformance,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillPersuasion,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillReligion,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillSleightOfHand,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillStealth,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillSurvival,
          'proficiency': 0,
          'expertise': 0
        },
        {
          'charId': insertedCharId,
          'skill': Defines.skillJackofAllTrades,
          'proficiency': 0
        },
      ];

      Batch batchSkills = txn.batch();
      for (var skill in initialSkills) {
        batchSkills.insert('skills', skill);
      }
      await batchSkills.commit(noResult: true);

      var initialStats = {
        'charId': insertedCharId,
        Defines.statArmor: 10,
        Defines.statLevel: 1,
        Defines.statXP: 0,
        Defines.statInspiration: 0,
        Defines.statProficiencyBonus: 0,
        Defines.statInitiative: 0,
        Defines.statMovement: "0m",
        Defines.statMaxHP: 0,
        Defines.statCurrentHP: 0,
        Defines.statTempHP: 0,
        Defines.statCurrentHitDice: 0,
        Defines.statMaxHitDice: 0,
        Defines.statHitDiceFactor: "",
        Defines.statSTR: 10,
        Defines.statDEX: 10,
        Defines.statCON: 10,
        Defines.statINT: 10,
        Defines.statWIS: 10,
        Defines.statCHA: 10,
        Defines.statSpellSaveDC: 0,
        Defines.statSpellAttackBonus: 0,
      };
      await txn.insert('stats', initialStats);

      var initialProfs = {
        'charId': insertedCharId,
        Defines.profLightArmor: '',
        Defines.profMediumArmor: '',
        Defines.profHeavyArmor: '',
        Defines.profShield: '',
        Defines.profSimpleWeapon: '',
        Defines.profMartialWeapon: '',
        Defines.profOtherWeapon: '',
        Defines.profWeaponList: '',
        Defines.profLanguages: '',
        Defines.profTools: '',
      };
      await txn.insert('proficiencies', initialProfs);

      var initialBag = {
        'charId': insertedCharId,
        Defines.bagPlatin: 0,
        Defines.bagGold: 0,
        Defines.bagElectrum: 0,
        Defines.bagSilver: 0,
        Defines.bagCopper: 0,
      };
      await txn.insert('bag', initialBag);

      var initialSpellSlots = [
        {
          'charId': insertedCharId,
          'spellslot': Defines.slotZero,
          'total': 0,
          'spent': 0
        },
        {
          'charId': insertedCharId,
          'spellslot': Defines.slotOne,
          'total': 0,
          'spent': 0
        },
        {
          'charId': insertedCharId,
          'spellslot': Defines.slotTwo,
          'total': 0,
          'spent': 0
        },
        {
          'charId': insertedCharId,
          'spellslot': Defines.slotThree,
          'total': 0,
          'spent': 0
        },
        {
          'charId': insertedCharId,
          'spellslot': Defines.slotFour,
          'total': 0,
          'spent': 0
        },
        {
          'charId': insertedCharId,
          'spellslot': Defines.slotFive,
          'total': 0,
          'spent': 0
        },
        {
          'charId': insertedCharId,
          'spellslot': Defines.slotSix,
          'total': 0,
          'spent': 0
        },
        {
          'charId': insertedCharId,
          'spellslot': Defines.slotSeven,
          'total': 0,
          'spent': 0
        },
        {
          'charId': insertedCharId,
          'spellslot': Defines.slotEight,
          'total': 0,
          'spent': 0
        },
        {
          'charId': insertedCharId,
          'spellslot': Defines.slotNine,
          'total': 0,
          'spent': 0
        },
      ];

      Batch batchSpellSlots = txn.batch();
      for (var slot in initialSpellSlots) {
        batchSpellSlots.insert('spellslots', slot);
      }
      await batchSpellSlots.commit(noResult: true);
    });
  }

  Future<void> createProfile(String profileName) async {
    final profileDbPath = await _getPath();

    currentDb = await openDatabase(profileDbPath, version: 1);

    await currentDb!.execute(
        'CREATE TABLE IF NOT EXISTS version (ID INTEGER PRIMARY KEY, versionNumber TEXT)');

    for (String query in DatabaseSchema.allTables) {
      await currentDb!.execute(query);
    }

    await updateDatabaseIfOutdated(currentDb!);

    await initializeDatabase(currentDb!, profileName);
    await loadProfiles();
  }

  Future<void> selectProfile(Character profile) async {
    final profileDbPath = await _getPath();

    if (kDebugMode) {
      print('Selecting profile: ${profile.name}');
    }

    currentDb = await openDatabase(profileDbPath);
    selectedProfile = profile.name;
    selectedID = profile.id;

    // Initialize default item types if they don't exist
    await initializeDefaultItemTypes();
  }

  Future<void> characterCreator(
    String name,
    RaceData race,
    ClassData classData,
    BackgroundData background,
    FeatData? feat,
    Map<String, int> abilityScores,
    int level,
    int hp,
    Map<String, bool>? skillProficiencies,
    Map<String, bool>? skillExpertise,
    List<String>? savingThrowProficiencies,
    List<SpellData>? selectedSpells,
    List<ItemData>? selectedItems,
  ) async {
    final profileDbPath = await _getPath();

    await createProfile(name);

    final newest = profiles.isNotEmpty
        ? profiles.reduce((a, b) => a.id > b.id ? a : b)
        : null;

    if (newest != null && newest.name == name) {
      selectedProfile = newest.name;
      selectedID = newest.id;
    }

    // Step 3: Open database and update basic info
    currentDb = await openDatabase(profileDbPath);

    updateProfileInfo(field: Defines.infoName, value: name);
    updateProfileInfo(field: Defines.infoRace, value: race.name);
    updateProfileInfo(field: Defines.infoClass, value: classData.name);
    updateProfileInfo(field: Defines.infoBackground, value: background.name);
    updateProfileInfo(field: Defines.infoSize, value: race.size);
    updateStats(field: Defines.statLevel, value: level);
    updateStats(field: Defines.statMaxHP, value: hp);
    updateStats(field: Defines.statCurrentHP, value: hp);

    // Set hit dice
    updateStats(field: Defines.statMaxHitDice, value: level);
    updateStats(field: Defines.statCurrentHitDice, value: level);
    updateStats(field: Defines.statHitDiceFactor, value: 'd${classData.hd}');

    // Set speed from race
    updateStats(field: Defines.statMovement, value: race.speed.toString());

    // Collect languages from race and background
    List<String> languages = [];
    if (race.proficiency.isNotEmpty) {
      final raceProficiencies = race.proficiency.split(',').map((s) => s.trim()).toList();
      // Filter for languages (Common, Elvish, etc.) - assume anything not a skill is a language
      languages.addAll(raceProficiencies.where((p) => !p.contains('Handling') && !p.contains('Acrobatics') && !p.contains('Animal') && !p.contains('Arcana') && !p.contains('Athletics') && !p.contains('Deception') && !p.contains('History') && !p.contains('Insight') && !p.contains('Intimidation') && !p.contains('Investigation') && !p.contains('Medicine') && !p.contains('Nature') && !p.contains('Perception') && !p.contains('Performance') && !p.contains('Persuasion') && !p.contains('Religion') && !p.contains('Sleight') && !p.contains('Stealth') && !p.contains('Survival')));
    }
    if (background.proficiency.isNotEmpty) {
      final bgProficiencies = background.proficiency.split(',').map((s) => s.trim()).toList();
      languages.addAll(bgProficiencies.where((p) => !p.contains('Handling') && !p.contains('Acrobatics') && !p.contains('Animal') && !p.contains('Arcana') && !p.contains('Athletics') && !p.contains('Deception') && !p.contains('History') && !p.contains('Insight') && !p.contains('Intimidation') && !p.contains('Investigation') && !p.contains('Medicine') && !p.contains('Nature') && !p.contains('Perception') && !p.contains('Performance') && !p.contains('Persuasion') && !p.contains('Religion') && !p.contains('Sleight') && !p.contains('Stealth') && !p.contains('Survival')));
    }

    // Build notes with class proficiencies and languages
    final List<String> noteParts = [];
    if (classData.proficiency.isNotEmpty) {
      noteParts.add('Class Proficiencies:\n${classData.proficiency}');
    }
    if (languages.isNotEmpty) {
      noteParts.add('\nLanguages:\n${languages.join(', ')}');
    }
    if (noteParts.isNotEmpty) {
      updateProfileInfo(field: Defines.infoNotes, value: noteParts.join('\n'));
    }

    // Apply ability scores
    Map<String, int> finalAbilityScores = Map.from(abilityScores);

    // Apply feat ability score modifiers
    if (feat != null && feat.modifier != null && feat.modifier!.isNotEmpty) {
      final modifiers = _parseFeatModifier(feat.modifier!);
      for (final entry in modifiers.entries) {
        final currentValue = finalAbilityScores[entry.key] ?? 10;
        finalAbilityScores[entry.key] = (currentValue + entry.value).toInt();
      }
    }

    for (final entry in finalAbilityScores.entries) {
      final abilityKey = entry.key;
      final value = entry.value;
      String statField;

      switch (abilityKey) {
        case 'STR':
          statField = Defines.statSTR;
          break;
        case 'DEX':
          statField = Defines.statDEX;
          break;
        case 'CON':
          statField = Defines.statCON;
          break;
        case 'INT':
          statField = Defines.statINT;
          break;
        case 'WIS':
          statField = Defines.statWIS;
          break;
        case 'CHA':
          statField = Defines.statCHA;
          break;
        default:
          continue;
      }

      updateStats(field: statField, value: value);
    }

    // Calculate and set AC and Initiative
    final dexScore = finalAbilityScores['DEX'] ?? 10;
    final conScore = finalAbilityScores['CON'] ?? 10;
    final dexModifier = ((dexScore - 10) / 2).floor();
    final conModifier = ((conScore - 10) / 2).floor();

    int armorClass;
    if (classData.name == 'Barbarian') {
      // Barbarian unarmored defense: 10 + DEX + CON
      armorClass = 10 + dexModifier + conModifier;
    } else {
      // Standard AC: 10 + DEX
      armorClass = 10 + dexModifier;
    }
    updateStats(field: Defines.statArmor, value: armorClass);

    // Set initiative to DEX modifier
    updateStats(field: Defines.statInitiative, value: dexModifier);

    // Apply skill proficiencies and expertise
    if (skillProficiencies != null) {
      for (final entry in skillProficiencies.entries) {
        final skillDefine = entry.key;
        final isProficient = entry.value;

        if (isProficient) {
          final hasExpertise = skillExpertise?[skillDefine] ?? false;
          updateSkills(
            skill: _mapSkillDefineToConstant(skillDefine),
            proficiency: 1,
            expertise: hasExpertise ? 1 : 0,
          );
        }
      }
    }

    // Apply saving throw proficiencies
    if (savingThrowProficiencies != null) {
      for (final savingThrow in savingThrowProficiencies) {
        String saveField;

        switch (savingThrow) {
          case 'Strength':
            saveField = Defines.saveStr;
            break;
          case 'Dexterity':
            saveField = Defines.saveDex;
            break;
          case 'Constitution':
            saveField = Defines.saveCon;
            break;
          case 'Intelligence':
            saveField = Defines.saveInt;
            break;
          case 'Wisdom':
            saveField = Defines.saveWis;
            break;
          case 'Charisma':
            saveField = Defines.saveCha;
            break;
          default:
            continue;
        }

        updateSavingThrows(field: saveField, value: 1);
      }
    }

    // Apply background skill proficiencies
    final backgroundProficiencies = background.proficiency;
    if (backgroundProficiencies.isNotEmpty) {
      final skills = backgroundProficiencies
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      for (final skillName in skills) {
        // Map skill name to define constant
        String? skillDefine;

        switch (skillName) {
          case 'Acrobatics':
            skillDefine = Defines.skillAcrobatics;
            break;
          case 'Animal Handling':
            skillDefine = Defines.skillAnimalHandling;
            break;
          case 'Arcana':
            skillDefine = Defines.skillArcana;
            break;
          case 'Athletics':
            skillDefine = Defines.skillAthletics;
            break;
          case 'Deception':
            skillDefine = Defines.skillDeception;
            break;
          case 'History':
            skillDefine = Defines.skillHistory;
            break;
          case 'Insight':
            skillDefine = Defines.skillInsight;
            break;
          case 'Intimidation':
            skillDefine = Defines.skillIntimidation;
            break;
          case 'Investigation':
            skillDefine = Defines.skillInvestigation;
            break;
          case 'Medicine':
            skillDefine = Defines.skillMedicine;
            break;
          case 'Nature':
            skillDefine = Defines.skillNature;
            break;
          case 'Perception':
            skillDefine = Defines.skillPerception;
            break;
          case 'Performance':
            skillDefine = Defines.skillPerformance;
            break;
          case 'Persuasion':
            skillDefine = Defines.skillPersuasion;
            break;
          case 'Religion':
            skillDefine = Defines.skillReligion;
            break;
          case 'Sleight of Hand':
            skillDefine = Defines.skillSleightOfHand;
            break;
          case 'Stealth':
            skillDefine = Defines.skillStealth;
            break;
          case 'Survival':
            skillDefine = Defines.skillSurvival;
            break;
        }

        if (skillDefine != null) {
          updateSkills(
            skill: skillDefine,
            proficiency: 1,
            expertise: 0,
          );
        }
      }
    }

    // Apply race skill proficiencies
    final raceProficiencies = race.proficiency;
    if (raceProficiencies.isNotEmpty) {
      final skills = raceProficiencies
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      for (final skillName in skills) {
        // Map skill name to define constant
        String? skillDefine;

        switch (skillName) {
          case 'Acrobatics':
            skillDefine = Defines.skillAcrobatics;
            break;
          case 'Animal Handling':
            skillDefine = Defines.skillAnimalHandling;
            break;
          case 'Arcana':
            skillDefine = Defines.skillArcana;
            break;
          case 'Athletics':
            skillDefine = Defines.skillAthletics;
            break;
          case 'Deception':
            skillDefine = Defines.skillDeception;
            break;
          case 'History':
            skillDefine = Defines.skillHistory;
            break;
          case 'Insight':
            skillDefine = Defines.skillInsight;
            break;
          case 'Intimidation':
            skillDefine = Defines.skillIntimidation;
            break;
          case 'Investigation':
            skillDefine = Defines.skillInvestigation;
            break;
          case 'Medicine':
            skillDefine = Defines.skillMedicine;
            break;
          case 'Nature':
            skillDefine = Defines.skillNature;
            break;
          case 'Perception':
            skillDefine = Defines.skillPerception;
            break;
          case 'Performance':
            skillDefine = Defines.skillPerformance;
            break;
          case 'Persuasion':
            skillDefine = Defines.skillPersuasion;
            break;
          case 'Religion':
            skillDefine = Defines.skillReligion;
            break;
          case 'Sleight of Hand':
            skillDefine = Defines.skillSleightOfHand;
            break;
          case 'Stealth':
            skillDefine = Defines.skillStealth;
            break;
          case 'Survival':
            skillDefine = Defines.skillSurvival;
            break;
        }

        if (skillDefine != null) {
          updateSkills(
            skill: skillDefine,
            proficiency: 1,
            expertise: 0,
          );
        }
      }
    }

    // Set spellcasting info if class has spellcasting
    print('DEBUG: Class: ${classData.name}, spellAbility: "${classData.spellAbility}"');
    if (classData.spellAbility.isNotEmpty) {
      print('DEBUG: Setting spell info for ${classData.name}');
      await updateProfileInfo(
        field: Defines.infoSpellcastingAbility,
        value: classData.spellAbility,
      );
      await updateProfileInfo(
        field: Defines.infoSpellcastingClass,
        value: classData.name,
      );

      // Calculate spell attack and spell save DC
      final proficiencyBonus = _calculateProficiencyBonus(level);
      final spellAbilityModifier = _getAbilityModifier(
        classData.spellAbility,
        finalAbilityScores,
      );

      final spellAttack = proficiencyBonus + spellAbilityModifier;
      final spellSaveDC = 8 + proficiencyBonus + spellAbilityModifier;

      await updateStats(field: Defines.statSpellAttackBonus, value: spellAttack);
      await updateStats(field: Defines.statSpellSaveDC, value: spellSaveDC);

      // Set spell slots based on character level
      final autolevel = classData.autolevels.firstWhere(
        (al) => int.parse(al.level) == level && al.slots != null,
        orElse: () => classData.autolevels.firstWhere(
          (al) => al.slots != null,
          orElse: () => classData.autolevels.first,
        ),
      );

      if (autolevel.slots != null && autolevel.slots!.slots.isNotEmpty) {
        final slots = autolevel.slots!.slots;
        final slotFields = [
          Defines.slotZero,
          Defines.slotOne,
          Defines.slotTwo,
          Defines.slotThree,
          Defines.slotFour,
          Defines.slotFive,
          Defines.slotSix,
          Defines.slotSeven,
          Defines.slotEight,
          Defines.slotNine,
        ];

        for (int i = 0; i < slots.length && i < slotFields.length; i++) {
          await updateSpellSlots(
            spellslot: slotFields[i],
            total: slots[i],
            spent: slots[i],
          );
        }
      }
    }

    // Add selected feat
    if (feat != null) {
      addFeat(
        featName: feat.name,
        description: feat.text,
        type: "Talent",
      );
    }

    for (final trait in race.traits) {
      addFeat(
        featName: trait.name,
        description: trait.description,
        type: "Rasse",
      );
    }

    // Apply features and spell slots for all levels up to selected level
    for (int currentLevel = 1; currentLevel <= level; currentLevel++) {
      final levelData = classData.autolevels.where(
        (entry) => int.tryParse(entry.level) == currentLevel,
      );

      for (final autolevel in levelData) {
        // Add features for this level
        if (autolevel.features != null) {
          for (final feature in autolevel.features!) {
            addFeat(
              featName: feature.name,
              description: feature.description,
              type: "Klasse",
            );
          }
        }

        // Update spell slots (only the last level's slots are kept)
        if (currentLevel == level && autolevel.slots != null) {
          final slots = autolevel.slots!.slots;
          for (int i = 0; i < slots.length; i++) {
            if (slots[i] > 0) {
              updateSpellSlots(spellslot: i.toString(), total: slots[i]);
            }
          }
        }
      }
    }

    parseRaceProficiencies(race.proficiency);

    // Add selected spells to character
    if (selectedSpells != null && selectedSpells.isNotEmpty) {
      for (final spell in selectedSpells) {
        await addSpell(
          spellName: spell.name,
          status: Defines.spellKnown,
          level: int.tryParse(spell.level) ?? 0,
          description: spell.text,
          reach: spell.range,
          duration: spell.duration,
        );
      }
    }

    // Add selected items to character
    if (selectedItems != null && selectedItems.isNotEmpty) {
      for (final item in selectedItems) {
        // Add the item to the character's inventory
        await addItem(
          itemname: item.name,
          type: item.type,
          description: item.text,
          amount: 1,
        );
      }
    }
  }

  String _mapSkillDefineToConstant(String skillDefine) {
    switch (skillDefine) {
      case 'acrobatics':
        return Defines.skillAcrobatics;
      case 'animal_handling':
        return Defines.skillAnimalHandling;
      case 'arcana':
        return Defines.skillArcana;
      case 'athletics':
        return Defines.skillAthletics;
      case 'deception':
        return Defines.skillDeception;
      case 'history':
        return Defines.skillHistory;
      case 'insight':
        return Defines.skillInsight;
      case 'intimidation':
        return Defines.skillIntimidation;
      case 'investigation':
        return Defines.skillInvestigation;
      case 'medicine':
        return Defines.skillMedicine;
      case 'nature':
        return Defines.skillNature;
      case 'perception':
        return Defines.skillPerception;
      case 'performance':
        return Defines.skillPerformance;
      case 'persuasion':
        return Defines.skillPersuasion;
      case 'religion':
        return Defines.skillReligion;
      case 'sleight_of_hand':
        return Defines.skillSleightOfHand;
      case 'stealth':
        return Defines.skillStealth;
      case 'survival':
        return Defines.skillSurvival;
      default:
        return skillDefine;
    }
  }

  int _calculateProficiencyBonus(int level) {
    if (level >= 17) return 6;
    if (level >= 13) return 5;
    if (level >= 9) return 4;
    if (level >= 5) return 3;
    return 2;
  }

  int _getAbilityModifier(String abilityName, Map<String, int> abilityScores) {
    String abilityKey;
    switch (abilityName.toLowerCase()) {
      case 'strength':
        abilityKey = 'STR';
        break;
      case 'dexterity':
        abilityKey = 'DEX';
        break;
      case 'constitution':
        abilityKey = 'CON';
        break;
      case 'intelligence':
        abilityKey = 'INT';
        break;
      case 'wisdom':
        abilityKey = 'WIS';
        break;
      case 'charisma':
        abilityKey = 'CHA';
        break;
      default:
        return 0;
    }

    final abilityScore = abilityScores[abilityKey] ?? 10;
    return ((abilityScore - 10) / 2).floor();
  }

  Map<String, int> _parseFeatModifier(String modifierString) {
    // Parse modifier string like "Dexterity +1" or "Constitution +1"
    final Map<String, int> modifiers = {};

    // Handle case-insensitive matching
    final lowerModifier = modifierString.toLowerCase();

    if (lowerModifier.contains('strength')) {
      final match = RegExp(r'([+-]?\d+)').firstMatch(modifierString);
      if (match != null) {
        modifiers['STR'] = int.parse(match.group(1)!);
      }
    }
    if (lowerModifier.contains('dexterity')) {
      final match = RegExp(r'([+-]?\d+)').firstMatch(modifierString);
      if (match != null) {
        modifiers['DEX'] = int.parse(match.group(1)!);
      }
    }
    if (lowerModifier.contains('constitution')) {
      final match = RegExp(r'([+-]?\d+)').firstMatch(modifierString);
      if (match != null) {
        modifiers['CON'] = int.parse(match.group(1)!);
      }
    }
    if (lowerModifier.contains('intelligence')) {
      final match = RegExp(r'([+-]?\d+)').firstMatch(modifierString);
      if (match != null) {
        modifiers['INT'] = int.parse(match.group(1)!);
      }
    }
    if (lowerModifier.contains('wisdom')) {
      final match = RegExp(r'([+-]?\d+)').firstMatch(modifierString);
      if (match != null) {
        modifiers['WIS'] = int.parse(match.group(1)!);
      }
    }
    if (lowerModifier.contains('charisma')) {
      final match = RegExp(r'([+-]?\d+)').firstMatch(modifierString);
      if (match != null) {
        modifiers['CHA'] = int.parse(match.group(1)!);
      }
    }

    return modifiers;
  }

  Map<String, int> parseRaceProficiencies(String? proficiencyString) {
    const skillNameMap = {
      "Acrobatics": Defines.skillAcrobatics,
      "Animal Handling": Defines.skillAnimalHandling,
      "Arcana": Defines.skillArcana,
      "Athletics": Defines.skillAthletics,
      "Deception": Defines.skillDeception,
      "History": Defines.skillHistory,
      "Insight": Defines.skillInsight,
      "Intimidation": Defines.skillIntimidation,
      "Investigation": Defines.skillInvestigation,
      "Medicine": Defines.skillMedicine,
      "Nature": Defines.skillNature,
      "Perception": Defines.skillPerception,
      "Performance": Defines.skillPerformance,
      "Persuasion": Defines.skillPersuasion,
      "Religion": Defines.skillReligion,
      "Sleight of Hand": Defines.skillSleightOfHand,
      "Stealth": Defines.skillStealth,
      "Survival": Defines.skillSurvival,
    };

    final parsed = (proficiencyString?.isNotEmpty ?? false)
        ? proficiencyString!
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
        : <String>{};

    final result = <String, int>{};
    for (final entry in skillNameMap.entries) {
      result[entry.value] = parsed.contains(entry.key) ? 1 : 0;
    }

    return result;
  }

  Future<void> deleteProfile(Character profile) async {
    selectedID = null;
    selectedProfile = null;

    final profileDbPath = await _getPath();

    currentDb = await openDatabase(profileDbPath);

    int charId = profile.id;

    await currentDb!.delete('info', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!.delete('Stats', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!
        .delete('savingthrow', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!
        .delete('proficiencies', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!.delete('skills', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!
        .delete('spellslots', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!.delete('bag', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!.delete('spells', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!
        .delete('weapons', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!.delete('feats', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!.delete('items', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!
        .delete('item_types', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!
        .delete('tracker', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!
        .delete('conditions', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!
        .delete('creatures', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!
        .delete('creature_traits', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!
        .delete('creature_actions', where: 'charId = ?', whereArgs: [charId]);
    await currentDb!.delete('creature_legendary_actions',
        where: 'charId = ?', whereArgs: [charId]);

    await loadProfiles();
  }

  Future<void> renameProfile(String oldName, String newName) async {
    final profileDbPath = await _getPath();

    if (profiles.any((profile) => profile.name == newName)) {
      throw Exception(
          'Ein Charakter mit dem Namen "$newName" existiert bereits.');
    }

    currentDb = await openDatabase(profileDbPath);
    final index = profiles.indexWhere((profile) => profile.name == oldName);

    if (index != -1) {
      profiles[index] = Character(id: profiles[index].id, name: newName);
      if (selectedProfile == oldName) {
        selectedProfile = newName;
        selectedID = profiles[index].id;
      }

      await currentDb!.execute(
          'INSERT OR REPLACE INTO info (charId, ${Defines.infoName}) VALUES (?, ?)',
          [profiles[index].id, newName]);
    }

    await loadProfiles();

    if (kDebugMode) {
      print('Renamed profile from $oldName to $newName');
    }
  }

  Future<void> clearDatabase() async {
    final profileDbPath = await _getPath();

    if (currentDb != null) {
      await currentDb!.close();
      currentDb = null;
    }

    try {
      await deleteDatabase(profileDbPath);
      if (kDebugMode) {
        print('Database deleted successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting database: $e');
      }
    }
  }

  Future<void> updateStats({
    required String field,
    required dynamic value,
  }) async {
    if (currentDb == null) return;

    final Map<String, dynamic> updates = {
      field: value,
    };

    await currentDb!.update(
      'stats',
      updates,
      where: 'charId = ?',
      whereArgs: [selectedID],
    );
  }

  Future<void> updateSavingThrows({
    required String field,
    required dynamic value,
  }) async {
    if (currentDb == null) return;

    final Map<String, dynamic> updates = {
      field: value,
    };

    await currentDb!.update(
      'savingthrow',
      updates,
      where: 'charId = ?',
      whereArgs: [selectedID],
    );
  }

  Future<void> updateSkills({
    required String skill,
    int? proficiency,
    int? expertise,
  }) async {
    if (currentDb == null) return;

    final List<Map<String, dynamic>> existingSkillList = await currentDb!.query(
      'skills',
      where: 'charId = ? AND skill = ?',
      whereArgs: [selectedID, skill],
    );

    Map<String, dynamic>? existingSkill;
    if (existingSkillList.isNotEmpty) {
      existingSkill = existingSkillList.first;
    }

    final Map<String, dynamic> updates = {
      'proficiency': proficiency ?? existingSkill?['proficiency'],
      'expertise': expertise ?? existingSkill?['expertise'],
    };

    await currentDb!.update(
      'skills',
      updates,
      where: 'charId = ? AND skill = ?',
      whereArgs: [selectedID, skill],
    );
  }

  Future<void> updateBag({
    required String field,
    required dynamic value,
  }) async {
    if (currentDb == null) return;

    final Map<String, dynamic> updates = {
      field: value,
    };

    await currentDb!.update(
      'bag',
      updates,
      where: 'charId = ?',
      whereArgs: [selectedID],
    );
  }

  Future<void> updateProfileInfo({
    required String field,
    required dynamic value,
  }) async {
    if (currentDb == null) return;

    final Map<String, dynamic> updates = {
      field: value,
    };

    await currentDb!.update(
      'info',
      updates,
      where: 'charId = ?',
      whereArgs: [selectedID],
    );
  }

  Future<void> updateProficiencies({
    required String field,
    required dynamic value,
  }) async {
    if (currentDb == null) return;

    final Map<String, dynamic> updates = {
      field: value,
    };

    await currentDb!.update(
      'proficiencies',
      updates,
      where: 'charId = ?',
      whereArgs: [selectedID],
    );
  }

  Future<void> updateSpellSlots({
    required String spellslot,
    int? total,
    int? spent,
  }) async {
    if (currentDb == null) return;

    final List<Map<String, dynamic>> existingSkillList = await currentDb!.query(
      'spellslots',
      where: 'charId = ? AND spellslot = ?',
      whereArgs: [selectedID, spellslot],
    );

    Map<String, dynamic>? existingSkill;
    if (existingSkillList.isNotEmpty) {
      existingSkill = existingSkillList.first;
    }

    final Map<String, dynamic> updates = {
      'total': total ?? existingSkill?['total'],
      'spent': spent ?? existingSkill?['spent'],
    };

    await currentDb!.update(
      'spellslots',
      updates,
      where: 'charId = ? AND spellslot = ?',
      whereArgs: [selectedID, spellslot],
    );
  }

  Future<void> updateWeapons({
    required uuid,
    String? weapon,
    String? attribute,
    String? reach,
    String? bonus,
    String? damage,
    String? damagetype,
    String? description,
    int? attunement,
  }) async {
    if (currentDb == null) return;

    final List<Map<String, dynamic>> existingWeaponList =
        await currentDb!.query(
      'weapons',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );

    final Map<String, dynamic> updates = {
      'weapon': weapon,
      'attribute': attribute,
      'reach': reach,
      'bonus': bonus,
      'damage': damage,
      'damagetype': damagetype,
      'description': description,
      'attunement': attunement ?? 0,
    };

    if (existingWeaponList.isNotEmpty) {
      final Map<String, dynamic> existingWeapon = existingWeaponList.first;
      updates.forEach((key, value) {
        if (value == null) {
          updates[key] = existingWeapon[key];
        }
      });
      await currentDb!.update(
        'weapons',
        updates,
        where: 'charId = ? AND ID = ?',
        whereArgs: [selectedID, uuid],
      );
    } else {
      await currentDb!.insert(
        'weapons',
        updates,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> addWeapon({
    required String weapon,
    String? attribute,
    String? reach,
    String? bonus,
    String? damage,
    String? damagetype,
    String? description,
    int? attunement,
  }) async {
    if (currentDb == null) return;

    final Map<String, dynamic> weapondata = {
      'weapon': weapon,
      'charId': selectedID,
      'attribute': attribute,
      'reach': reach,
      'bonus': bonus,
      'damage': damage,
      'damagetype': damagetype,
      'description': description,
      'attunement': attunement ?? 0,
    };

    try {
      await currentDb!.insert(
        'weapons',
        weapondata,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error adding weapon: $e');
      }
    }
  }

  Future<void> removeweapon(int uuid) async {
    if (currentDb == null) return;

    await currentDb!.delete(
      'weapons',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );
  }

  Future<void> updateSpell({
    required uuid,
    String? spellName,
    String? status,
    int? level,
    String? description,
    String? reach,
    String? duration,
  }) async {
    if (currentDb == null) return;

    final List<Map<String, dynamic>> existingSpellList = await currentDb!.query(
      'spells',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );

    final Map<String, dynamic> updates = {
      'spellname': spellName,
      'status': status,
      'level': level,
      'description': description,
      'reach': reach,
      'duration': duration,
    };

    if (existingSpellList.isNotEmpty) {
      final Map<String, dynamic> existingSpell = existingSpellList.first;
      updates.forEach((key, value) {
        if (value == null) {
          updates[key] = existingSpell[key];
        }
      });
      await currentDb!.update(
        'spells',
        updates,
        where: 'charId = ? AND ID = ?',
        whereArgs: [selectedID, uuid],
      );
    } else {
      await currentDb!.insert(
        'spells',
        updates,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> addSpell({
    required String spellName,
    String? status,
    int? level,
    String? description,
    String? reach,
    String? duration,
  }) async {
    if (currentDb == null) return;

    final Map<String, dynamic> spellData = {
      'charId': selectedID,
      'spellname': spellName,
      'status': status,
      'level': level,
      'description': description,
      'reach': reach,
      'duration': duration,
    };

    try {
      await currentDb!.insert(
        'spells',
        spellData,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error adding spell: $e');
      }
    }
  }

  Future<void> removeSpell(int uuid) async {
    if (currentDb == null) return;

    await currentDb!.delete(
      'spells',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );
  }

  Future<void> updateFeat({
    required uuid,
    String? featName,
    String? description,
    String? type,
  }) async {
    if (currentDb == null) return;

    final List<Map<String, dynamic>> existingFeatList = await currentDb!.query(
      'feats',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );

    final Map<String, dynamic> updates = {
      'featname': featName,
      'description': description,
      'type': type,
    };

    if (existingFeatList.isNotEmpty) {
      final Map<String, dynamic> existingFeat = existingFeatList.first;
      updates.forEach((key, value) {
        if (value == null) {
          updates[key] = existingFeat[key];
        }
      });
      await currentDb!.update(
        'feats',
        updates,
        where: 'charId = ? AND ID = ?',
        whereArgs: [selectedID, uuid],
      );
    } else {
      await currentDb!.insert(
        'feats',
        updates,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> addFeat({
    required String featName,
    String? description,
    String? type,
  }) async {
    if (currentDb == null) return;

    final Map<String, dynamic> spellData = {
      'charId': selectedID,
      'featname': featName,
      'description': description,
      'type': type,
    };

    try {
      await currentDb!.insert(
        'feats',
        spellData,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error adding feat: $e');
      }
    }
  }

  Future<void> removeFeat(int uuid) async {
    if (currentDb == null) return;

    await currentDb!.delete(
      'feats',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );
  }

  Future<void> updateItem({
    required uuid,
    String? itemname,
    String? description,
    String? type,
    int? amount,
    int? attunement,
  }) async {
    if (currentDb == null) return;

    final List<Map<String, dynamic>> existingItemList = await currentDb!.query(
      'items',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );

    final Map<String, dynamic> updates = {
      'itemname': itemname,
      'description': description,
      'type': type,
      'amount': amount,
      'attunement': attunement ?? 0,
    };

    if (existingItemList.isNotEmpty) {
      final Map<String, dynamic> existingItem = existingItemList.first;
      updates.forEach((key, value) {
        if (value == null) {
          updates[key] = existingItem[key];
        }
      });
      await currentDb!.update(
        'items',
        updates,
        where: 'charId = ? AND ID = ?',
        whereArgs: [selectedID, uuid],
      );
    } else {
      await currentDb!.insert(
        'items',
        updates,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> addItem({
    required String itemname,
    String? description,
    String? type,
    int? amount,
    int? attunement,
  }) async {
    if (currentDb == null) return;

    final itemAmount = amount ?? 1;

    final Map<String, dynamic> itemData = {
      'charId': selectedID,
      'itemname': itemname,
      'description': description,
      'type': type,
      'amount': itemAmount,
      'attunement': attunement ?? 0,
    };

    try {
      await currentDb!.insert(
        'items',
        itemData,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error adding item: $e');
      }
    }
  }

  Future<void> removeItem(int uuid) async {
    if (currentDb == null) return;

    await currentDb!.delete(
      'items',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );
  }

  // Custom Item Types Management
  Future<void> addItemType({required String typeName}) async {
    if (currentDb == null) return;

    final Map<String, dynamic> typeData = {
      'charId': selectedID,
      'type_name': typeName,
      'is_default': 0,
    };

    try {
      await currentDb!.insert(
        'item_types',
        typeData,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error adding item type: $e');
      }
    }
  }

  Future<void> removeItemType(int typeId) async {
    if (currentDb == null) return;

    await currentDb!.delete(
      'item_types',
      where: 'charId = ? AND ID = ? AND is_default = 0',
      whereArgs: [selectedID, typeId],
    );
  }

  Future<List<Map<String, dynamic>>> getItemTypes() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'item_types',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<void> initializeDefaultItemTypes() async {
    if (currentDb == null) return;

    // Check if default types already exist
    final existingTypes = await currentDb!.query(
      'item_types',
      where: 'charId = ? AND is_default = 1',
      whereArgs: [selectedID],
    );

    if (existingTypes.isEmpty) {
      final defaultTypes = ['Gegenstände', 'Ausrüstung', 'Sonstige'];

      for (String type in defaultTypes) {
        await currentDb!.insert(
          'item_types',
          {
            'charId': selectedID,
            'type_name': type,
            'is_default': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Future<void> updateTracker({
    required uuid,
    String? tracker,
    int? value,
    int? max,
    String? type,
  }) async {
    if (currentDb == null) return;

    final List<Map<String, dynamic>> existingTrackerList =
        await currentDb!.query(
      'tracker',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );

    final Map<String, dynamic> updates = {
      'trackername': tracker,
      'value': value,
      'max': max,
      'type': type,
    };

    if (existingTrackerList.isNotEmpty) {
      final Map<String, dynamic> existingTracker = existingTrackerList.first;
      updates.forEach((key, value) {
        if (value == null) {
          updates[key] = existingTracker[key];
        }
      });
      await currentDb!.update(
        'tracker',
        updates,
        where: 'charId = ? AND ID = ?',
        whereArgs: [selectedID, uuid],
      );
    } else {
      await currentDb!.insert(
        'tracker',
        updates,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> addTracker({
    required String tracker,
    int? value,
    int? max,
    String? type,
  }) async {
    if (currentDb == null) return;

    final Map<String, dynamic> trackerData = {
      'charId': selectedID,
      'trackername': tracker,
      'value': value,
      'max': max,
      'type': type
    };

    try {
      await currentDb!.insert(
        'tracker',
        trackerData,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error adding item: $e');
      }
    }
  }

  Future<void> removeTracker(int uuid) async {
    if (currentDb == null) return;

    await currentDb!.delete(
      'tracker',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );
  }

  Future<void> updateCondition({
    required uuid,
    String? condition,
  }) async {
    if (currentDb == null) return;

    final List<Map<String, dynamic>> existingConditionList =
        await currentDb!.query(
      'conditions',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );

    final Map<String, dynamic> updates = {
      'condition': condition,
    };

    if (existingConditionList.isNotEmpty) {
      final Map<String, dynamic> existingCondition =
          existingConditionList.first;
      updates.forEach((key, value) {
        if (value == null) {
          updates[key] = existingCondition[key];
        }
      });
      await currentDb!.update(
        'conditions',
        updates,
        where: 'charId = ? AND ID = ?',
        whereArgs: [selectedID, uuid],
      );
    } else {
      await currentDb!.insert(
        'conditions',
        updates,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> addCondition({
    required String condition,
  }) async {
    if (currentDb == null) return;

    final Map<String, dynamic> conditionData = {
      'charId': selectedID,
      'condition': condition,
    };

    try {
      await currentDb!.insert(
        'conditions',
        conditionData,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error adding item: $e');
      }
    }
  }

  Future<void> removeCondition(int uuid) async {
    if (currentDb == null) return;

    await currentDb!.delete(
      'conditions',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );
  }

  Future<void> addCreature(Creature creature) async {
    if (currentDb == null) return;

    final Map<String, dynamic> creatureData = {
      'charId': selectedID,
      'name': creature.name,
      'size': creature.size,
      'type': creature.type,
      'alignment': creature.alignment,
      'ac': creature.ac,
      'currentHP': creature.currentHP,
      'maxHP': creature.maxHP,
      'speed': creature.speed,
      'str': creature.str,
      'dex': creature.dex,
      'con': creature.con,
      'intScore': creature.intScore,
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
    };

    try {
      final int creatureId = await currentDb!.insert(
        'creatures',
        creatureData,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      for (var trait in creature.traits) {
        await currentDb!.insert(
          'creature_traits',
          {
            'charId': selectedID,
            'creature_id': creatureId,
            'trait_name': trait.name,
            'trait_description': trait.description,
          },
        );
      }

      for (var action in creature.actions) {
        await currentDb!.insert(
          'creature_actions',
          {
            'charId': selectedID,
            'creature_id': creatureId,
            'action_name': action.name,
            'action': action.attack,
            'action_description': action.description,
          },
        );
      }

      for (var legendary in creature.legendaryActions) {
        await currentDb!.insert(
          'creature_legendary_actions',
          {
            'charId': selectedID,
            'creature_id': creatureId,
            'legendary_action_name': legendary.name,
            'legendary_action_description': legendary.description,
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding creature: $e');
      }
    }
  }

  Future<void> updateCreature(
    Creature creature,
  ) async {
    if (currentDb == null) return;

    final List<Map<String, dynamic>> existingCreatureList =
        await currentDb!.query(
      'creatures',
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, creature.uuid],
    );

    final Map<String, dynamic> updates = {
      'name': creature.name,
      'size': creature.size,
      'type': creature.type,
      'alignment': creature.alignment,
      'ac': creature.ac,
      'maxHP': creature.maxHP,
      'currentHP': creature.currentHP,
      'speed': creature.speed,
      'str': creature.str,
      'dex': creature.dex,
      'con': creature.con,
      'intScore': creature.intScore,
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
    };

    if (existingCreatureList.isNotEmpty) {
      await currentDb!.update(
        'creatures',
        updates,
        where: 'charId = ? AND ID = ?',
        whereArgs: [selectedID, creature.uuid],
      );

      await currentDb!.delete('creature_traits',
          where: 'charId = ? AND creature_id = ?',
          whereArgs: [selectedID, creature.uuid]);
      await currentDb!.delete('creature_actions',
          where: 'charId = ? AND creature_id = ?',
          whereArgs: [selectedID, creature.uuid]);
      await currentDb!.delete('creature_legendary_actions',
          where: 'charId = ? AND creature_id = ?',
          whereArgs: [selectedID, creature.uuid]);

      for (var trait in creature.traits) {
        await currentDb!.insert(
          'creature_traits',
          {
            'charId': selectedID,
            'creature_id': creature.uuid,
            'trait_name': trait.name,
            'trait_description': trait.description,
          },
        );
      }

      for (var action in creature.actions) {
        await currentDb!.insert(
          'creature_actions',
          {
            'charId': selectedID,
            'creature_id': creature.uuid,
            'action_name': action.name,
            'action': action.attack,
            'action_description': action.description,
          },
        );
      }

      for (var legendary in creature.legendaryActions) {
        await currentDb!.insert(
          'creature_legendary_actions',
          {
            'charId': selectedID,
            'creature_id': creature.uuid,
            'legendary_action_name': legendary.name,
            'legendary_action_description': legendary.description,
          },
        );
      }
    } else {
      await addCreature(creature);
    }
  }

  Future<void> removeCreature(int uuid) async {
    if (currentDb == null) return;

    try {
      await currentDb!.delete(
        'creature_traits',
        where: 'charId = ? AND creature_id = ?',
        whereArgs: [selectedID, uuid],
      );
      await currentDb!.delete(
        'creature_actions',
        where: 'charId = ? AND creature_id = ?',
        whereArgs: [selectedID, uuid],
      );
      await currentDb!.delete(
        'creature_legendary_actions',
        where: 'charId = ? AND creature_id = ?',
        whereArgs: [selectedID, uuid],
      );
      await currentDb!.delete(
        'creatures',
        where: 'charId = ? AND ID = ?',
        whereArgs: [selectedID, uuid],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error removing creature: $e');
      }
    }
  }

  Future<List<Creature>> getCreatures() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'creatures',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    List<Creature> creatures = [];

    for (var creatureData in result) {
      final int creatureId = creatureData['ID'];

      final List<Map<String, dynamic>> traitsData = await currentDb!.query(
        'creature_traits',
        where: 'charId = ? AND creature_id = ?',
        whereArgs: [selectedID, creatureId],
      );
      List<Trait> traits = traitsData
          .map((trait) => Trait(
                name: trait['trait_name'],
                description: trait['trait_description'],
              ))
          .toList();

      final List<Map<String, dynamic>> actionsData = await currentDb!.query(
        'creature_actions',
        where: 'charId = ? AND creature_id = ?',
        whereArgs: [selectedID, creatureId],
      );
      List<CAction> actions = actionsData
          .map((action) => CAction(
                name: action['action_name'],
                description: action['action_description'],
                attack: action['action'],
              ))
          .toList();

      final List<Map<String, dynamic>> legendaryActionsData =
          await currentDb!.query(
        'creature_legendary_actions',
        where: 'charId = ? AND creature_id = ?',
        whereArgs: [selectedID, creatureId],
      );
      List<Legendary> legendaryActions = legendaryActionsData
          .map((legendary) => Legendary(
                name: legendary['legendary_action_name'],
                description: legendary['legendary_action_description'],
              ))
          .toList();

      creatures.add(Creature(
        uuid: creatureId,
        name: creatureData['name'],
        size: creatureData['size'],
        type: creatureData['type'],
        alignment: creatureData['alignment'],
        ac: creatureData['ac'],
        currentHP: creatureData['currentHP'],
        maxHP: creatureData['maxHP'],
        speed: creatureData['speed'],
        str: creatureData['str'],
        dex: creatureData['dex'],
        con: creatureData['con'],
        intScore: creatureData['intScore'],
        wis: creatureData['wis'],
        cha: creatureData['cha'],
        saves: creatureData['saves'],
        skills: creatureData['skills'],
        resistances: creatureData['resistances'],
        vulnerabilities: creatureData['vulnerabilities'],
        immunities: creatureData['immunities'],
        conditionImmunities: creatureData['conditionImmunities'],
        senses: creatureData['senses'],
        passivePerception: creatureData['passivePerception'],
        languages: creatureData['languages'],
        cr: creatureData['cr'],
        traits: traits,
        actions: actions,
        legendaryActions: legendaryActions,
      ));
    }

    return creatures;
  }

  Future<List<Map<String, dynamic>>> getTracker() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'tracker',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getConditions() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'conditions',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getStats() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'stats',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getProfileInfo() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'info',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getWeapons() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'weapons',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getProficiencies() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'proficiencies',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getSkills() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'skills',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getSpellSlots() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'spellslots',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getBagItems() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'bag',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'items',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getFeats() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'feats',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getSavingThrows() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'savingthrow',
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getAllSpells() async {
    if (currentDb == null) return [];

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'spells',
      columns: [
        'spellname',
        'level',
        'status',
        'description',
        'ID',
        'reach',
        'duration'
      ],
      where: 'charId = ?',
      whereArgs: [selectedID],
    );

    return result;
  }

  Future<Map<String, dynamic>> getSpell(int uuid) async {
    if (currentDb == null) {
      return {'description': 'keine Beschreibung', 'reach': '', 'duration': ''};
    }

    final List<Map<String, dynamic>> result = await currentDb!.query(
      'spells',
      columns: ['description', 'reach', 'duration'],
      where: 'charId = ? AND ID = ?',
      whereArgs: [selectedID, uuid],
    );

    return result.isNotEmpty
        ? {
            'description': result.first['description'] ?? 'keine Beschreibung',
            'reach': result.first['reach'] ?? '',
            'duration': result.first['duration'] ?? ''
          }
        : {'description': 'keine Beschreibung', 'reach': '', 'duration': ''};
  }

  bool hasProfiles() {
    return profiles.isNotEmpty;
  }

  List<Character> getProfiles() {
    return profiles;
  }

  Future<void> closeDB() async {
    if (currentDb != null) {
      await currentDb!.close();
      if (kDebugMode) {
        print('Closing profile database');
      }
    }
  }

  List<FeatureData> parseFeatureData(String xmlString, int characterLevel) {
    final document = XmlDocument.parse(xmlString);
    List<FeatureData> features = [];

    void parseFeats(Iterable<XmlElement> featElements, [String? defaultType]) {
      for (final feat in featElements) {
        final name = feat.findElements('name').first.innerText;
        final description = feat.findElements('text').isNotEmpty
            ? feat.findElements('text').first.innerText
            : feat.findElements('description').first.innerText;
        final type = feat.findElements('type').isNotEmpty
            ? feat.findElements('type').first.innerText
            : (defaultType ?? 'Sonstige');

        features.add(FeatureData(
          name: name,
          description: description,
          type: type,
        ));
      }
    }

    final characterFeats = document
        .findAllElements('character')
        .expand((e) => e.findAllElements('feat'));
    parseFeats(characterFeats, 'Sonstige');

    parseFeats(
      document.findAllElements('race').expand((e) => e.findAllElements('feat')),
      'Rasse',
    );

    parseFeats(
      document
          .findAllElements('background')
          .expand((e) => e.findAllElements('feat')),
      'Hintergrund',
    );

    final classElements = document.findAllElements('class');
    for (final classElement in classElements) {
      final autolevels = classElement.findAllElements('autolevel');
      for (final autolevel in autolevels) {
        final levelElements = autolevel.findElements('level');
        final level = levelElements.isNotEmpty
            ? int.parse(levelElements.first.innerText)
            : null;

        if (level == null || level <= characterLevel) {
          parseFeats(autolevel.findAllElements('feat'), 'Klasse');
        }
      }
    }

    final allFeatElements = document.findAllElements('feat');
    final knownFeatElements = {
      ...document
          .findAllElements('race')
          .expand((e) => e.findAllElements('feat')),
      ...document
          .findAllElements('background')
          .expand((e) => e.findAllElements('feat')),
      ...document
          .findAllElements('character')
          .expand((e) => e.findAllElements('feat')),
      ...classElements.expand((e) => e.findAllElements('feat')),
    };

    for (final feat in allFeatElements) {
      if (!knownFeatElements.contains(feat)) {
        final name = feat.findElements('name').first.innerText;
        final description = feat.findElements('description').first.innerText;
        final type = feat.findElements('type').isNotEmpty
            ? feat.findElements('type').first.innerText
            : 'Sonstige';

        features.add(FeatureData(
          name: name,
          description: description,
          type: type,
        ));
      }
    }

    return features;
  }

  dynamic parseStatsData(String xmlString) {
    final document = XmlDocument.parse(xmlString);

    final abilitiesString =
        document.findAllElements('abilities').first.innerText;
    final abilitiesList = abilitiesString
        .split(',')
        .where((value) => value.trim().isNotEmpty)
        .map((value) => int.parse(value.trim()))
        .toList();

    final abilities = {
      Defines.statSTR: abilitiesList[0],
      Defines.statDEX: abilitiesList[1],
      Defines.statCON: abilitiesList[2],
      Defines.statINT: abilitiesList[3],
      Defines.statWIS: abilitiesList[4],
      Defines.statCHA: abilitiesList[5],
    };

    int? parseIntStat(String tagName) {
      final elements = document.findAllElements(tagName);
      return elements.isNotEmpty ? int.parse(elements.first.innerText) : 0;
    }

    final additionalStats = {
      Defines.statMaxHP: parseIntStat('hpMax'),
      Defines.statCurrentHP: parseIntStat('hpCurrent'),
      Defines.statTempHP: parseIntStat('hpTemp'),
      Defines.statXP: parseIntStat('xp'),
      Defines.statArmor: parseIntStat('armorclass'),
      Defines.statInspiration: parseIntStat('inspiration'),
      Defines.statProficiencyBonus: parseIntStat('proficiencyBonus'),
      Defines.statInitiative: parseIntStat('initiative'),
      Defines.statSpellSaveDC: parseIntStat('spellSaveDC'),
      Defines.statSpellAttackBonus: parseIntStat('spellAttackBonus'),
      Defines.statMovement: document.findAllElements('movement').isNotEmpty
          ? document.findAllElements('movement').first.innerText
          : "",
      Defines.statAttunmentCount: parseIntStat('attunementCount'),
    };

    int getLevelFromDocument(XmlDocument document) {
      int level = 0;

      final statsElements = document.findAllElements('stats').toList();
      if (statsElements.isNotEmpty) {
        final statsElement = statsElements.first;
        level = statsElement.findElements('level').isNotEmpty
            ? int.parse(statsElement.findElements('level').first.innerText)
            : 0;
      }

      if (level == 0) {
        final classElements = document.findAllElements('class').toList();
        if (classElements.isNotEmpty) {
          final classElement = classElements.first;
          level = classElement.findElements('level').isNotEmpty
              ? int.parse(classElement.findElements('level').first.innerText)
              : 0;
        }
      }

      return level;
    }

    final level = getLevelFromDocument(document);

    final hdCurrent = parseIntStat('hdCurrent');
    final hd = parseIntStat('hd');

    return {
      ...abilities,
      ...additionalStats,
      Defines.statLevel: level,
      Defines.statMaxHitDice: hd,
      Defines.statCurrentHitDice: hdCurrent,
    };
  }

  dynamic parseProficiencies(String xmlString) {
    final document = XmlDocument.parse(xmlString);

    if (document.findAllElements('proficiencies').isNotEmpty) {
      final proficienciesElement =
          document.findAllElements('proficiencies').first;
      final armor = proficienciesElement.findElements('armor').isNotEmpty
          ? proficienciesElement.findElements('armor').first.innerText
          : '';
      final weapons = proficienciesElement.findElements('weapons').isNotEmpty
          ? proficienciesElement.findElements('weapons').first.innerText
          : '';
      final tools = proficienciesElement.findElements('tools').isNotEmpty
          ? proficienciesElement.findElements('tools').first.innerText
          : '';
      final language = proficienciesElement.findElements('language').isNotEmpty
          ? proficienciesElement.findElements('language').first.innerText
          : '';

      return {
        Defines.profArmor: armor,
        Defines.profWeaponList: weapons,
        Defines.profTools: tools,
        Defines.profLanguages: language,
      };
    }

    if (document.findAllElements('class').isNotEmpty) {
      final classElement = document.findAllElements('class').first;
      final armor = classElement.findElements('armor').first.innerText;
      final weapons = classElement.findElements('weapons').first.innerText;
      final tools = classElement.findElements('tools').first.innerText;

      return {
        Defines.profArmor: armor,
        Defines.profWeaponList: weapons,
        Defines.profTools: tools,
      };
    }

    return {
      Defines.profArmor: '',
      Defines.profWeaponList: '',
      Defines.profTools: '',
    };
  }

  dynamic parseInfos(String xmlString) {
    final document = XmlDocument.parse(xmlString);

    String getText(String parentTag, String childTag) {
      final parent = document.findAllElements(parentTag);
      if (parent.isNotEmpty) {
        final child = parent.first.findElements(childTag);
        return child.isNotEmpty ? child.first.innerText.trim() : "";
      }
      return "";
    }

    String getTextFromInfoOrFallback(String tagName) {
      String infoText = getText('info', tagName);
      if (infoText.isNotEmpty) {
        return infoText;
      } else {
        switch (tagName) {
          case 'name':
            return getText('character', 'name');
          case 'race':
            return getText('race', 'name');
          case 'background':
            return getText('background', 'name');
          case 'class':
            return getText('class', 'name');
          default:
            return "";
        }
      }
    }

    return {
      Defines.infoName: getTextFromInfoOrFallback('name'),
      Defines.infoRace: getTextFromInfoOrFallback('race'),
      Defines.infoClass: getTextFromInfoOrFallback('class'),
      Defines.infoBackground: getTextFromInfoOrFallback('background'),
      Defines.infoOrigin: getText('info', Defines.infoOrigin),
      Defines.infoPersonalityTraits:
          getText('info', Defines.infoPersonalityTraits),
      Defines.infoIdeals: getText('info', Defines.infoIdeals),
      Defines.infoBonds: getText('info', Defines.infoBonds),
      Defines.infoFlaws: getText('info', Defines.infoFlaws),
      Defines.infoAge: getText('info', Defines.infoAge),
      Defines.infoGod: getText('info', Defines.infoGod),
      Defines.infoSize: getText('info', Defines.infoSize),
      Defines.infoHeight: getText('info', Defines.infoHeight),
      Defines.infoWeight: getText('info', Defines.infoWeight),
      Defines.infoSex: getText('info', Defines.infoSex),
      Defines.infoAlignment: getText('info', Defines.infoAlignment),
      Defines.infoEyeColour: getText('info', Defines.infoEyeColour),
      Defines.infoHairColour: getText('info', Defines.infoHairColour),
      Defines.infoSkinColour: getText('info', Defines.infoSkinColour),
      Defines.infoAppearance: getText('info', Defines.infoAppearance),
      Defines.infoBackstory: getText('info', Defines.infoBackstory),
      Defines.infoNotes: getText('info', Defines.infoNotes),
      Defines.infoSpellcastingClass: getText('info', "spellcastingClass"),
      Defines.infoSpellcastingAbility: getText('info', "spellcastingAbility"),
    };
  }

  List<Map<String, dynamic>> parseSpells(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    List<Map<String, dynamic>> spells = [];

    final spellElements = document.findAllElements('spell');
    for (final spellElement in spellElements) {
      final name = spellElement.findElements('name').first.innerText;

      final description = spellElement.findElements('text').isNotEmpty
          ? spellElement.findElements('text').first.innerText
          : spellElement.findElements('description').isNotEmpty
              ? spellElement.findElements('description').first.innerText
              : "";

      final levelElement = spellElement.findElements('level').isNotEmpty
          ? int.parse(spellElement.findElements('level').first.innerText)
          : 0;

      final status = spellElement.findElements('status').isNotEmpty
          ? spellElement.findElements('status').first.innerText
          : Defines.spellKnown;

      final reach = spellElement.findElements('reach').isNotEmpty
          ? spellElement.findElements('reach').first.innerText
          : "";

      final duration = spellElement.findElements('duration').isNotEmpty
          ? spellElement.findElements('duration').first.innerText
          : "";

      spells.add({
        'name': name,
        'description': description,
        'status': status,
        'level': levelElement,
        'reach': reach,
        'duration': duration,
      });
    }

    return spells;
  }

  List<Map<String, dynamic>> parseTrackers(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    List<Map<String, dynamic>> trackers = [];

    final trackerElements = document.findAllElements('tracker');
    for (final trackerElement in trackerElements) {
      final name = trackerElement.findElements('label').isNotEmpty
          ? trackerElement.findElements('label').first.innerText
          : 'Kein Name';

      final value = trackerElement.findElements('value').isNotEmpty
          ? int.parse(trackerElement.findElements('value').first.innerText)
          : 0;

      final maxElement = trackerElement.findElements('formula').isNotEmpty
          ? trackerElement.findElements('formula').first
          : trackerElement.findElements('max').isNotEmpty
              ? trackerElement.findElements('max').first
              : null;

      final max = maxElement != null ? int.parse(maxElement.innerText) : 0;

      final type = trackerElement.findElements('type').isNotEmpty
          ? trackerElement.findElements('type').first.innerText
          : 'never';

      trackers.add({
        'name': name,
        'value': value,
        'max': max,
        'type': type,
      });
    }

    return trackers;
  }

  Map<String, Map<String, int>> parseSpellSlots(String xmlString) {
    final document = XmlDocument.parse(xmlString);

    final spellSlotsElements = document.findAllElements('spellSlots').toList();

    String slotsString = '';
    String slotsCurrentString = '';

    if (spellSlotsElements.isNotEmpty) {
      final spellSlotsElement = spellSlotsElements.first;
      slotsString = spellSlotsElement.findElements('slots').isNotEmpty
          ? spellSlotsElement.findElements('slots').first.innerText
          : '';
      slotsCurrentString =
          spellSlotsElement.findElements('slotsCurrent').isNotEmpty
              ? spellSlotsElement.findElements('slotsCurrent').first.innerText
              : '';
    } else if (document.findAllElements('character').isNotEmpty) {
      final characterElement = document.findAllElements('character').first;
      slotsString = characterElement.findElements('slots').isNotEmpty
          ? characterElement.findElements('slots').first.innerText
          : '';
      slotsCurrentString =
          characterElement.findElements('slotsCurrent').isNotEmpty
              ? characterElement.findElements('slotsCurrent').first.innerText
              : '';
    } else {
      slotsString = document.findElements('slots').isNotEmpty
          ? document.findElements('slots').first.innerText
          : '';
      slotsCurrentString = document.findElements('slotsCurrent').isNotEmpty
          ? document.findElements('slotsCurrent').first.innerText
          : '';
    }

    final slotsList = slotsString.isNotEmpty
        ? slotsString
            .split(',')
            .where((value) => value.trim().isNotEmpty)
            .map((value) => int.parse(value.trim()))
            .toList()
        : List.generate(10, (index) => 0);

    final slotsCurrentList = slotsCurrentString.isNotEmpty
        ? slotsCurrentString
            .split(',')
            .where((value) => value.trim().isNotEmpty)
            .map((value) => int.parse(value.trim()))
            .toList()
        : List.generate(10, (index) => 0);

    if (slotsList.length != slotsCurrentList.length) {
      throw Exception(
          'Mismatch between total spell slots and current spell slots.');
    }

    Map<String, Map<String, int>> spellSlotsMap = {};

    for (int i = 0; i < slotsList.length; i++) {
      String slotName;
      switch (i) {
        case 0:
          slotName = Defines.slotZero;
          break;
        case 1:
          slotName = Defines.slotOne;
          break;
        case 2:
          slotName = Defines.slotTwo;
          break;
        case 3:
          slotName = Defines.slotThree;
          break;
        case 4:
          slotName = Defines.slotFour;
          break;
        case 5:
          slotName = Defines.slotFive;
          break;
        case 6:
          slotName = Defines.slotSix;
          break;
        case 7:
          slotName = Defines.slotSeven;
          break;
        case 8:
          slotName = Defines.slotEight;
          break;
        case 9:
          slotName = Defines.slotNine;
          break;
        default:
          continue;
      }

      spellSlotsMap[slotName] = {
        'total': slotsList[i],
        'spent': slotsCurrentList[i],
      };
    }

    return spellSlotsMap;
  }

  List<Map<String, String>> parseWeapons(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    List<Map<String, String>> attacks = [];

    final weaponsElements = document.findAllElements('weapons');

    for (final weaponsElement in weaponsElements) {
      bool isInsideClassTag = false;

      var parent = weaponsElement.parent;
      while (parent != null) {
        if (parent is XmlElement && parent.name.local == 'class') {
          isInsideClassTag = true;
          break;
        }
        parent = parent.parent;
      }

      if (!isInsideClassTag) {
        final weaponElements = weaponsElement.findAllElements('weapon');
        for (final weaponElement in weaponElements) {
          final name = weaponElement.getElement('name')?.innerText ?? '';
          final attribute =
              weaponElement.getElement('attribute')?.innerText ?? '';
          final reach = weaponElement.getElement('reach')?.innerText ?? '';
          final bonus =
              weaponElement.getElement('attackBonus')?.innerText ?? '';
          final damage = weaponElement.getElement('damage')?.innerText ?? '';
          final damageType =
              weaponElement.getElement('damageType')?.innerText ?? '';
          final description =
              weaponElement.getElement('description')?.innerText ?? '';
          final attunement =
              weaponElement.getElement('attunement')?.innerText ?? '';

          attacks.add({
            'name': name,
            'attribute': attribute,
            'reach': reach,
            'bonus': bonus,
            'damage': damage,
            'damageType': damageType,
            'description': description,
            'attunement': attunement,
          });
        }
      }
    }

    final attackElements = document.findAllElements('attack');
    for (final attackElement in attackElements) {
      final name = attackElement.findElements('name').isNotEmpty
          ? attackElement.findElements('name').first.innerText
          : '';
      final attackBonus = attackElement.findElements('attackBonus').isNotEmpty
          ? attackElement.findElements('attackBonus').first.innerText
          : '';
      final damage = attackElement.findElements('damage').isNotEmpty
          ? attackElement.findElements('damage').first.innerText
          : '';
      final damageType = attackElement.findElements('damageType').isNotEmpty
          ? attackElement.findElements('damageType').first.innerText
          : '';
      final attunement = attackElement.findElements('attunement').isNotEmpty
          ? attackElement.findElements('attunement').first.innerText
          : '';

      attacks.add({
        'name': name,
        'attackBonus': attackBonus,
        'damage': damage,
        'damageType': damageType,
        'attunement': attunement,
      });
    }

    return attacks;
  }

  List<Map<String, String>> parseItemTypes(String xmlString) {
    final document = XmlDocument.parse(xmlString);

    Iterable<XmlElement> itemTypeElements;

    if (document.findAllElements('itemTypes').isNotEmpty) {
      itemTypeElements = document
          .findAllElements('itemTypes')
          .first
          .findAllElements('itemType');
    } else {
      return [];
    }

    List<Map<String, String>> itemTypes = [];

    for (final typeElement in itemTypeElements) {
      final name = typeElement.findElements('name').first.innerText;
      final isDefault = typeElement.findElements('isDefault').isNotEmpty
          ? typeElement.findElements('isDefault').first.innerText
          : '0';

      itemTypes.add({
        'name': name,
        'isDefault': isDefault,
      });
    }

    return itemTypes;
  }

  List<Map<String, String>> parseItems(String xmlString) {
    final document = XmlDocument.parse(xmlString);

    Iterable<XmlElement> itemElements;

    if (document.findAllElements('items').isNotEmpty) {
      itemElements =
          document.findAllElements('items').first.findAllElements('item');
    } else if (document.findAllElements('character').isNotEmpty) {
      itemElements =
          document.findAllElements('character').first.findAllElements('item');
    } else {
      itemElements = document.findAllElements('item');
    }

    List<Map<String, String>> items = [];

    for (final itemElement in itemElements) {
      final name = itemElement.findElements('name').first.innerText;

      final detailElement = itemElement.findElements('detail').isNotEmpty
          ? itemElement.findElements('detail').first.innerText
          : null;

      String typeElement = itemElement.findElements('type').isNotEmpty
          ? itemElement.findElements('type').first.innerText
          : "Sonstige";

      if (int.tryParse(typeElement) != null) {
        typeElement = "Sonstige";
      }

      final amountElement = itemElement.findElements('quantity').isNotEmpty
          ? itemElement.findElements('quantity').first.innerText
          : '1';

      final attunementElement =
          itemElement.findElements('attunement').isNotEmpty
              ? itemElement.findElements('attunement').first.innerText
              : '';

      items.add({
        'name': name,
        if (detailElement != null) 'detail': detailElement,
        'type': typeElement,
        'amount': amountElement,
        'attunement': attunementElement,
      });
    }

    return items;
  }

  Map<String, int> parseSavingThrows(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final Map<String, int> savingThrows = {};
    final savingthrowsElement =
        document.findAllElements('savingthrows').isNotEmpty
            ? document.findAllElements('savingthrows').first
            : null;

    final saveKeys = [
      Defines.saveStr,
      Defines.saveDex,
      Defines.saveCon,
      Defines.saveInt,
      Defines.saveWis,
      Defines.saveCha,
    ];

    for (final key in saveKeys) {
      final value =
          savingthrowsElement?.findElements(key).firstOrNull?.innerText;
      savingThrows[key] = int.tryParse(value ?? '0') ?? 0;
    }

    return savingThrows;
  }

  List<Map<String, dynamic>> parseBagItems(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    List<Map<String, dynamic>> bagItems = [];

    final bagElement = document.findAllElements('bag').isNotEmpty
        ? document.findAllElements('bag').first
        : null;

    if (bagElement == null) {
      bagItems.add({
        'platin': 0,
        'gold': 0,
        'electrum': 0,
        'silver': 0,
        'copper': 0,
      });
    } else {
      final platin = bagElement.findAllElements(Defines.bagPlatin).isNotEmpty
          ? int.parse(
              bagElement.findAllElements(Defines.bagPlatin).first.innerText)
          : 0;
      final gold = bagElement.findAllElements(Defines.bagGold).isNotEmpty
          ? int.parse(
              bagElement.findAllElements(Defines.bagGold).first.innerText)
          : 0;
      final electrum = bagElement
              .findAllElements(Defines.bagElectrum)
              .isNotEmpty
          ? int.parse(
              bagElement.findAllElements(Defines.bagElectrum).first.innerText)
          : 0;
      final silver = bagElement.findAllElements(Defines.bagSilver).isNotEmpty
          ? int.parse(
              bagElement.findAllElements(Defines.bagSilver).first.innerText)
          : 0;
      final copper = bagElement.findAllElements(Defines.bagCopper).isNotEmpty
          ? int.parse(
              bagElement.findAllElements(Defines.bagCopper).first.innerText)
          : 0;

      bagItems.add({
        'platin': platin,
        'gold': gold,
        'electrum': electrum,
        'silver': silver,
        'copper': copper,
      });
    }

    return bagItems;
  }

  List<Map<String, dynamic>> parseSkills(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    List<Map<String, dynamic>> skills = [];

    int safeParseInt(String text) {
      try {
        return int.parse(text);
      } catch (e) {
        return 0;
      }
    }

    final skillsElement = document.findAllElements('skills').isNotEmpty
        ? document.findAllElements('skills').first
        : null;

    if (skillsElement == null) {
      return skills;
    }

    for (final skillElement in skillsElement.findAllElements('skill')) {
      final skillName = skillElement.findAllElements('name').isNotEmpty
          ? skillElement.findAllElements('name').first.innerText
          : 'Kein Name';

      final proficiency = skillElement.findAllElements('proficiency').isNotEmpty
          ? int.parse(
              skillElement.findAllElements('proficiency').first.innerText)
          : 0;

      final expertise = skillElement.findAllElements('expertise').isNotEmpty
          ? safeParseInt(
              skillElement.findAllElements('expertise').first.innerText)
          : 0;

      skills.add({
        'skill': skillName,
        'proficiency': proficiency,
        'expertise': expertise,
      });
    }

    return skills;
  }

  List<Creature> parseCreatures(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    List<Creature> creatures = [];

    int safeParseInt(String text) {
      try {
        return int.parse(text);
      } catch (e) {
        return 0;
      }
    }

    String extractTextFromElement(XmlElement element, String tag) {
      return element.findElements(tag).isNotEmpty
          ? element.findElements(tag).first.innerText
          : '';
    }

    final creaturesElement = document.findAllElements('creature');

    for (final creatureElement in creaturesElement) {
      String extractText(String tag) =>
          creatureElement.findElements(tag).isNotEmpty
              ? creatureElement.findElements(tag).first.innerText
              : '';

      int extractInt(String tag) => safeParseInt(extractText(tag));

      List<Trait> parseTraits(XmlElement traitsElement) {
        return traitsElement.findAllElements('trait').map((traitElement) {
          return Trait(
            name: extractTextFromElement(traitElement, 'name'),
            description: extractTextFromElement(traitElement, 'description'),
          );
        }).toList();
      }

      List<CAction> parseActions(XmlElement actionsElement) {
        return actionsElement.findAllElements('action').map((actionElement) {
          return CAction(
            name: extractTextFromElement(actionElement, 'name'),
            description: extractTextFromElement(actionElement, 'description'),
            attack: extractTextFromElement(actionElement, 'actionDetails'),
          );
        }).toList();
      }

      List<Legendary> parseLegendaryActions(
          XmlElement legendaryActionsElement) {
        return legendaryActionsElement
            .findAllElements('legendaryAction')
            .map((legendaryElement) {
          return Legendary(
            name: extractTextFromElement(legendaryElement, 'name'),
            description:
                extractTextFromElement(legendaryElement, 'description'),
          );
        }).toList();
      }

      Creature creature = Creature(
        name: extractText('name'),
        size: extractText('size'),
        type: extractText('type'),
        alignment: extractText('alignment'),
        ac: extractInt('ac'),
        currentHP: extractInt('currentHP'),
        maxHP: extractInt('maxHP'),
        speed: extractText('speed'),
        str: extractInt('str'),
        dex: extractInt('dex'),
        con: extractInt('con'),
        intScore: extractInt('intScore'),
        wis: extractInt('wis'),
        cha: extractInt('cha'),
        saves: extractText('saves'),
        skills: extractText('skills'),
        resistances: extractText('resistances'),
        vulnerabilities: extractText('vulnerabilities'),
        immunities: extractText('immunities'),
        conditionImmunities: extractText('conditionImmunities'),
        senses: extractText('senses'),
        passivePerception: extractInt('passivePerception'),
        languages: extractText('languages'),
        cr: extractText('cr'),
        traits: creatureElement.findElements('traits').isNotEmpty
            ? parseTraits(creatureElement.findElements('traits').first)
            : [],
        actions: creatureElement.findElements('actions').isNotEmpty
            ? parseActions(creatureElement.findElements('actions').first)
            : [],
        legendaryActions:
            creatureElement.findElements('legendaryActions').isNotEmpty
                ? parseLegendaryActions(
                    creatureElement.findElements('legendaryActions').first)
                : [],
      );

      creatures.add(creature);
    }

    return creatures;
  }

  Future<void> createProfileFromXmlFile(File file) async {
    String xmlString = await file.readAsString();

    final parsedStats = parseStatsData(xmlString);
    final parsedInfos = parseInfos(xmlString);
    final parsedProf = parseProficiencies(xmlString);
    final parsedFeats =
        parseFeatureData(xmlString, parsedStats[Defines.statLevel]);
    final parsedSpells = parseSpells(xmlString);
    final parsedSlots = parseSpellSlots(xmlString);
    final parsedWeapons = parseWeapons(xmlString);
    final parsedTrackers = parseTrackers(xmlString);
    final parsedItems = parseItems(xmlString);
    final parsedItemTypes = parseItemTypes(xmlString);
    final parsedSavingThrows = parseSavingThrows(xmlString);
    final parsedBagItems = parseBagItems(xmlString);
    final parsedSkills = parseSkills(xmlString);
    final parsedCreatures = parseCreatures(xmlString);

    String characterName = parsedInfos[Defines.infoName];
    String uniqueName = await _getUniqueName(characterName);

    await createProfile(uniqueName);
    Character profile = profiles.firstWhere((p) => p.name == uniqueName);
    await selectProfile(profile);

    await _importStats(parsedStats);
    await _importProfileInfo(parsedInfos);
    await _importProfs(parsedProf);
    await _importSpells(parsedSpells);
    await _importFeats(parsedFeats);
    await _importWeapons(parsedWeapons);
    await _importTrackers(parsedTrackers);
    await _importItemTypes(parsedItemTypes);
    await _importItems(parsedItems);
    await _importSavingThrows(parsedSavingThrows);
    await _importBagItems(parsedBagItems);
    await _importSkills(parsedSkills);
    await _importSpellSlots(parsedSlots);
    await _importCreatures(parsedCreatures);

    await closeDB();

    if (kDebugMode) {
      print('Profile created and selected successfully from XML file!');
    }
  }

  Future<String> _getUniqueName(String characterName) async {
    String uniqueName = characterName;
    int counter = 1;
    while (profiles.any((p) => p.name == uniqueName)) {
      uniqueName = '$characterName ($counter)';
      counter++;
    }
    return uniqueName;
  }

  Future<void> _importStats(Map<String, dynamic> parsedStats) async {
    await updateStats(
        field: Defines.statSTR, value: parsedStats[Defines.statSTR]);
    await updateStats(
        field: Defines.statDEX, value: parsedStats[Defines.statDEX]);
    await updateStats(
        field: Defines.statCON, value: parsedStats[Defines.statCON]);
    await updateStats(
        field: Defines.statINT, value: parsedStats[Defines.statINT]);
    await updateStats(
        field: Defines.statWIS, value: parsedStats[Defines.statWIS]);
    await updateStats(
        field: Defines.statCHA, value: parsedStats[Defines.statCHA]);

    await updateStats(
        field: Defines.statMaxHP, value: parsedStats[Defines.statMaxHP]);
    await updateStats(
        field: Defines.statCurrentHP,
        value: parsedStats[Defines.statCurrentHP]);
    await updateStats(
        field: Defines.statTempHP, value: parsedStats[Defines.statTempHP]);
    await updateStats(
        field: Defines.statXP, value: parsedStats[Defines.statXP]);
    await updateStats(
        field: Defines.statArmor, value: parsedStats[Defines.statArmor]);
    await updateStats(
        field: Defines.statInspiration,
        value: parsedStats[Defines.statInspiration]);
    await updateStats(
        field: Defines.statProficiencyBonus,
        value: parsedStats[Defines.statProficiencyBonus]);
    await updateStats(
        field: Defines.statInitiative,
        value: parsedStats[Defines.statInitiative]);
    await updateStats(
        field: Defines.statSpellSaveDC,
        value: parsedStats[Defines.statSpellSaveDC]);
    await updateStats(
        field: Defines.statSpellAttackBonus,
        value: parsedStats[Defines.statSpellAttackBonus]);

    await updateStats(
        field: Defines.statLevel, value: parsedStats[Defines.statLevel]);
    await updateStats(
        field: Defines.statMaxHitDice,
        value: parsedStats[Defines.statMaxHitDice]);
    await updateStats(
        field: Defines.statCurrentHitDice,
        value: parsedStats[Defines.statCurrentHitDice]);
    await updateStats(
        field: Defines.statMovement, value: parsedStats[Defines.statMovement]);
    await updateStats(
        field: Defines.statAttunmentCount,
        value: parsedStats[Defines.statAttunmentCount] ?? 0);
  }

  Future<void> _importProfileInfo(Map<String, dynamic> parsedInfos) async {
    await updateProfileInfo(
        field: Defines.infoRace, value: parsedInfos[Defines.infoRace]);
    await updateProfileInfo(
        field: Defines.infoClass, value: parsedInfos[Defines.infoClass]);
    await updateProfileInfo(
        field: Defines.infoBackground,
        value: parsedInfos[Defines.infoBackground]);
    await updateProfileInfo(
        field: Defines.infoOrigin, value: parsedInfos[Defines.infoOrigin]);
    await updateProfileInfo(
        field: Defines.infoPersonalityTraits,
        value: parsedInfos[Defines.infoPersonalityTraits]);
    await updateProfileInfo(
        field: Defines.infoIdeals, value: parsedInfos[Defines.infoIdeals]);
    await updateProfileInfo(
        field: Defines.infoBonds, value: parsedInfos[Defines.infoBonds]);
    await updateProfileInfo(
        field: Defines.infoFlaws, value: parsedInfos[Defines.infoFlaws]);
    await updateProfileInfo(
        field: Defines.infoAge, value: parsedInfos[Defines.infoAge]);
    await updateProfileInfo(
        field: Defines.infoGod, value: parsedInfos[Defines.infoGod]);
    await updateProfileInfo(
        field: Defines.infoSize, value: parsedInfos[Defines.infoSize]);
    await updateProfileInfo(
        field: Defines.infoHeight, value: parsedInfos[Defines.infoHeight]);
    await updateProfileInfo(
        field: Defines.infoWeight, value: parsedInfos[Defines.infoWeight]);
    await updateProfileInfo(
        field: Defines.infoSex, value: parsedInfos[Defines.infoSex]);
    await updateProfileInfo(
        field: Defines.infoAlignment,
        value: parsedInfos[Defines.infoAlignment]);
    await updateProfileInfo(
        field: Defines.infoEyeColour,
        value: parsedInfos[Defines.infoEyeColour]);
    await updateProfileInfo(
        field: Defines.infoHairColour,
        value: parsedInfos[Defines.infoHairColour]);
    await updateProfileInfo(
        field: Defines.infoSkinColour,
        value: parsedInfos[Defines.infoSkinColour]);
    await updateProfileInfo(
        field: Defines.infoAppearance,
        value: parsedInfos[Defines.infoAppearance]);
    await updateProfileInfo(
        field: Defines.infoBackstory,
        value: parsedInfos[Defines.infoBackstory]);
    await updateProfileInfo(
        field: Defines.infoNotes, value: parsedInfos[Defines.infoNotes]);
    await updateProfileInfo(
        field: Defines.infoSpellcastingClass,
        value: parsedInfos[Defines.infoSpellcastingClass]);
    await updateProfileInfo(
        field: Defines.infoSpellcastingAbility,
        value: parsedInfos[Defines.infoSpellcastingAbility]);
  }

  Future<void> _importProfs(Map<String, dynamic> parsedProfs) async {
    await updateProficiencies(
        field: Defines.profArmor, value: parsedProfs[Defines.profArmor]);
    await updateProficiencies(
        field: Defines.profWeaponList,
        value: parsedProfs[Defines.profWeaponList]);
    await updateProficiencies(
        field: Defines.profTools, value: parsedProfs[Defines.profTools]);
    await updateProficiencies(
        field: Defines.profLanguages,
        value: parsedProfs[Defines.profLanguages]);
  }

  Future<void> _importSpells(List<Map<String, dynamic>> parsedSpells) async {
    for (final spell in parsedSpells) {
      await addSpell(
        spellName: spell['name'],
        status: spell['status'],
        level: spell['level'],
        description: spell['description'],
        reach: spell['reach'],
        duration: spell['duration'],
      );
    }
  }

  Future<void> _importFeats(List<FeatureData> parsedFeats) async {
    for (final feat in parsedFeats) {
      await addFeat(
        featName: feat.name,
        description: feat.description,
        type: feat.type,
      );
    }
  }

  Future<void> _importWeapons(List<Map<String, dynamic>> parsedWeapons) async {
    for (final weapon in parsedWeapons) {
      await addWeapon(
        weapon: weapon['name']!,
        bonus: weapon['bonus'],
        damage: weapon['damage'],
        reach: weapon['reach'],
        attribute: weapon['attribute'],
        damagetype: weapon['damageType'],
        description: weapon['description'],
        attunement: weapon['attunement'] != null
            ? int.tryParse(weapon['attunement'].toString()) ?? 0
            : 0,
      );
    }
  }

  Future<void> _importTrackers(
      List<Map<String, dynamic>> parsedTrackers) async {
    for (final tracker in parsedTrackers) {
      await addTracker(
        tracker: tracker['name']!,
        value: tracker['value'],
        max: tracker['max'],
        type: tracker['type'],
      );
    }
  }

  Future<void> _importItemTypes(
      List<Map<String, dynamic>> parsedItemTypes) async {
    for (final itemType in parsedItemTypes) {
      final isDefault = itemType['isDefault'] != null
          ? int.tryParse(itemType['isDefault'].toString()) ?? 0
          : 0;

      // Only import custom types (non-default), as defaults are auto-created
      if (isDefault == 0) {
        await addItemType(typeName: itemType['name']!);
      }
    }
  }

  Future<void> _importItems(List<Map<String, dynamic>> parsedItems) async {
    for (final item in parsedItems) {
      final amount = item['amount'] != null
          ? int.tryParse(item['amount'].toString()) ?? 1
          : 1;

      await addItem(
        itemname: item['name']!,
        description: item['detail'],
        type: item['type'],
        amount: amount,
        attunement: item['attunement'] != null
            ? int.tryParse(item['attunement'].toString()) ?? 0
            : 0,
      );
    }
  }

  Future<void> _importSavingThrows(
      Map<String, dynamic> parsedSavingThrows) async {
    await updateSavingThrows(
        field: Defines.saveStr, value: parsedSavingThrows[Defines.saveStr]);
    await updateSavingThrows(
        field: Defines.saveDex, value: parsedSavingThrows[Defines.saveDex]);
    await updateSavingThrows(
        field: Defines.saveCon, value: parsedSavingThrows[Defines.saveCon]);
    await updateSavingThrows(
        field: Defines.saveInt, value: parsedSavingThrows[Defines.saveInt]);
    await updateSavingThrows(
        field: Defines.saveWis, value: parsedSavingThrows[Defines.saveWis]);
    await updateSavingThrows(
        field: Defines.saveCha, value: parsedSavingThrows[Defines.saveCha]);
  }

  Future<void> _importBagItems(
      List<Map<String, dynamic>> parsedBagItems) async {
    await updateBag(
        field: Defines.bagPlatin, value: parsedBagItems[0]['platin']);
    await updateBag(field: Defines.bagGold, value: parsedBagItems[0]['gold']);
    await updateBag(
        field: Defines.bagElectrum, value: parsedBagItems[0]['electrum']);
    await updateBag(
        field: Defines.bagSilver, value: parsedBagItems[0]['silver']);
    await updateBag(
        field: Defines.bagCopper, value: parsedBagItems[0]['copper']);
  }

  Future<void> _importSkills(List<Map<String, dynamic>> parsedSkills) async {
    for (final skill in parsedSkills) {
      int? expertise = skill['expertise'];

      if (skill['skill'] == Defines.skillJackofAllTrades) {
        expertise = null;
      }

      await updateSkills(
        skill: skill['skill'],
        proficiency: skill['proficiency'],
        expertise: expertise,
      );
    }
  }

  Future<void> _importSpellSlots(
      Map<String, Map<String, int>> parsedSpellSlots) async {
    for (final entry in parsedSpellSlots.entries) {
      final spellslot = entry.key;
      final total = entry.value['total'];
      final spent = entry.value['spent'];

      await updateSpellSlots(
        spellslot: spellslot,
        total: total,
        spent: spent,
      );
    }
  }

  Future<void> _importCreatures(List<Creature> parsedCreatures) async {
    for (final entry in parsedCreatures) {
      await addCreature(entry);
    }
  }

  Future<String> exportFeatsToXml(Character profile) async {
    await selectProfile(profile);

    final feats = await getFeats();
    final statsList = await getStats();
    final proficienciesList = await getProficiencies();
    final profileInfoList = await getProfileInfo();
    final spells = await getAllSpells();
    final trackers = await getTracker();
    final spellSlots = await getSpellSlots();
    final weapons = await getWeapons();
    final items = await getItems();
    final itemTypes = await getItemTypes();
    final savingThrows = await getSavingThrows();
    final bagItems = await getBagItems();
    final skills = await getSkills();
    final creatures = await getCreatures();

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('character', nest: () {
      builder.element('feats', nest: () {
        for (final feat in feats) {
          builder.element('feat', nest: () {
            builder.element('name', nest: feat['featname']);
            builder.element('description', nest: feat['description']);
            builder.element('type', nest: feat['type']);
          });
        }
      });

      builder.element('stats', nest: () {
        if (statsList.isNotEmpty) {
          final stats = statsList.first;
          void addStatElement(String tagName, dynamic value) {
            if (value != null) {
              builder.element(tagName, nest: value.toString());
            }
          }

          addStatElement(
              'abilities',
              [
                stats[Defines.statSTR],
                stats[Defines.statDEX],
                stats[Defines.statCON],
                stats[Defines.statINT],
                stats[Defines.statWIS],
                stats[Defines.statCHA]
              ].join(", "));

          addStatElement('hpMax', stats[Defines.statMaxHP]);
          addStatElement('hpCurrent', stats[Defines.statCurrentHP]);
          addStatElement('hpTemp', stats[Defines.statTempHP]);
          addStatElement('xp', stats[Defines.statXP]);
          addStatElement('armorclass', stats[Defines.statArmor]);
          addStatElement('inspiration', stats[Defines.statInspiration]);
          addStatElement(
              'proficiencyBonus', stats[Defines.statProficiencyBonus]);
          addStatElement('initiative', stats[Defines.statInitiative]);
          addStatElement('spellSaveDC', stats[Defines.statSpellSaveDC]);
          addStatElement(
              'spellAttackBonus', stats[Defines.statSpellAttackBonus]);
          addStatElement('level', stats[Defines.statLevel]);
          addStatElement('hdCurrent', stats[Defines.statCurrentHitDice]);
          addStatElement('hd', stats[Defines.statMaxHitDice]);
          addStatElement('movement', stats[Defines.statMovement]);
          addStatElement('attunementCount', stats[Defines.statAttunmentCount]);
        }
      });

      builder.element('proficiencies', nest: () {
        if (proficienciesList.isNotEmpty) {
          final proficiencies = proficienciesList.first;

          void addProficiencyElement(String tagName, dynamic value) {
            if (value != null) {
              builder.element(tagName, nest: value.toString());
            }
          }

          addProficiencyElement('armor', proficiencies[Defines.profArmor]);
          addProficiencyElement(
              'weapons', proficiencies[Defines.profWeaponList]);
          addProficiencyElement('tools', proficiencies[Defines.profTools]);
          addProficiencyElement(
              'language', proficiencies[Defines.profLanguages]);
        }
      });

      builder.element('info', nest: () {
        if (profileInfoList.isNotEmpty) {
          final profileInfo = profileInfoList.first;

          void addInfoElement(String tagName, dynamic value) {
            if (value != null && value.toString().isNotEmpty) {
              builder.element(tagName, nest: value.toString());
            }
          }

          addInfoElement('name', profileInfo[Defines.infoName]);
          addInfoElement('race', profileInfo[Defines.infoRace]);
          addInfoElement('class', profileInfo[Defines.infoClass]);
          addInfoElement('background', profileInfo[Defines.infoBackground]);
          addInfoElement('origin', profileInfo[Defines.infoOrigin]);
          addInfoElement(
              'personalityTraits', profileInfo[Defines.infoPersonalityTraits]);
          addInfoElement('ideals', profileInfo[Defines.infoIdeals]);
          addInfoElement('bonds', profileInfo[Defines.infoBonds]);
          addInfoElement('flaws', profileInfo[Defines.infoFlaws]);
          addInfoElement('age', profileInfo[Defines.infoAge]);
          addInfoElement('god', profileInfo[Defines.infoGod]);
          addInfoElement('size', profileInfo[Defines.infoSize]);
          addInfoElement('height', profileInfo[Defines.infoHeight]);
          addInfoElement('weight', profileInfo[Defines.infoWeight]);
          addInfoElement('sex', profileInfo[Defines.infoSex]);
          addInfoElement('alignment', profileInfo[Defines.infoAlignment]);
          addInfoElement('eyeColour', profileInfo[Defines.infoEyeColour]);
          addInfoElement('hairColour', profileInfo[Defines.infoHairColour]);
          addInfoElement('skinColour', profileInfo[Defines.infoSkinColour]);
          addInfoElement('appearance', profileInfo[Defines.infoAppearance]);
          addInfoElement('backstory', profileInfo[Defines.infoBackstory]);
          addInfoElement('notes', profileInfo[Defines.infoNotes]);
          addInfoElement(
              'spellcastingClass', profileInfo[Defines.infoSpellcastingClass]);
          addInfoElement('spellcastingAbility',
              profileInfo[Defines.infoSpellcastingAbility]);
        }
      });

      builder.element('spells', nest: () {
        for (final spell in spells) {
          builder.element('spell', nest: () {
            builder.element('name', nest: spell['spellname']);
            builder.element('description', nest: spell['description']);
            builder.element('level', nest: spell['level'].toString());
            builder.element('status', nest: spell['status']);
            builder.element('reach', nest: spell['reach']);
            builder.element('duration', nest: spell['duration']);
          });
        }
      });

      builder.element('trackers', nest: () {
        for (final tracker in trackers) {
          builder.element('tracker', nest: () {
            builder.element('label', nest: tracker['trackername']);
            builder.element('value', nest: tracker['value'].toString());
            builder.element('max', nest: tracker['max'].toString());
            builder.element('type',
                nest: tracker['type']?.toString().isNotEmpty == true
                    ? tracker['type'].toString()
                    : 'never');
          });
        }
      });

      builder.element('spellSlots', nest: () {
        final slotsList = [];
        final slotsCurrentList = [];

        for (int i = 0; i < spellSlots.length; i++) {
          slotsList.add(spellSlots[i]['total'].toString());
          slotsCurrentList.add(spellSlots[i]['spent'].toString());
        }

        builder.element('slots', nest: '${slotsList.join(',')},');
        builder.element('slotsCurrent', nest: '${slotsCurrentList.join(',')},');
      });

      builder.element('weapons', nest: () {
        for (final weapon in weapons) {
          builder.element('weapon', nest: () {
            builder.element('name', nest: weapon['weapon']);
            if (weapon['attribute'] != null &&
                weapon['attribute']!.isNotEmpty) {
              builder.element('attribute', nest: weapon['attribute']);
            }
            if (weapon['reach'] != null && weapon['reach']!.isNotEmpty) {
              builder.element('reach', nest: weapon['reach']);
            }
            if (weapon['bonus'] != null && weapon['bonus']!.isNotEmpty) {
              builder.element('attackBonus', nest: weapon['bonus']);
            }
            if (weapon['damage'] != null && weapon['damage']!.isNotEmpty) {
              builder.element('damage', nest: weapon['damage']);
            }
            if (weapon['damagetype'] != null &&
                weapon['damagetype']!.isNotEmpty) {
              builder.element('damageType', nest: weapon['damagetype']);
            }
            if (weapon['description'] != null &&
                weapon['description']!.isNotEmpty) {
              builder.element('description', nest: weapon['description']);
            }
            if (weapon['attunement'] != null) {
              builder.element('attunement', nest: weapon['attunement']);
            }
          });
        }
      });

      builder.element('items', nest: () {
        for (final item in items) {
          builder.element('item', nest: () {
            builder.element('name', nest: item['itemname']);

            if (item['description'] != null &&
                item['description']!.isNotEmpty) {
              builder.element('detail', nest: item['description']);
            }

            String type = item['type'] ?? '';
            if (type.isNotEmpty && int.tryParse(type) != null) {
              type = 'Sonstige';
            }

            if (type.isNotEmpty) {
              builder.element('type', nest: type);
            }

            final amount = item['amount'] ?? 1;
            builder.element('quantity', nest: amount.toString());

            final attunement = item['attunement'] ?? '';
            if (attunement != null) {
              builder.element('attunement', nest: attunement);
            } else {
              builder.element('attunement', nest: 0);
            }
          });
        }
      });

      builder.element('itemTypes', nest: () {
        for (final itemType in itemTypes) {
          builder.element('itemType', nest: () {
            builder.element('name', nest: itemType['type_name']);
            builder.element('isDefault', nest: itemType['is_default']);
          });
        }
      });

      builder.element('savingthrows', nest: () {
        final allowedKeys = ['STR', 'DEX', 'CON', 'INT', 'WIS', 'CHA'];

        for (final entry in savingThrows.first.entries) {
          final key = entry.key;
          final value = entry.value;

          if (allowedKeys.contains(key) && value != null) {
            builder.element(key, nest: value.toString());
          }
        }
      });

      builder.element('bag', nest: () {
        for (final item in bagItems) {
          if (item['platin'] != null) {
            builder.element(Defines.bagPlatin, nest: item['platin'].toString());
          }
          if (item['gold'] != null) {
            builder.element(Defines.bagGold, nest: item['gold'].toString());
          }
          if (item['electrum'] != null) {
            builder.element(Defines.bagElectrum,
                nest: item['electrum'].toString());
          }
          if (item['silver'] != null) {
            builder.element(Defines.bagSilver, nest: item['silver'].toString());
          }
          if (item['copper'] != null) {
            builder.element(Defines.bagCopper, nest: item['copper'].toString());
          }
        }
      });

      builder.element('skills', nest: () {
        for (final skill in skills) {
          builder.element('skill', nest: () {
            builder.element('name', nest: skill['skill']);
            builder.element('proficiency',
                nest: skill['proficiency'].toString());
            builder.element('expertise', nest: skill['expertise'].toString());
          });
        }
      });

      builder.element('creatures', nest: () {
        for (final creature in creatures) {
          builder.element('creature', nest: () {
            builder.element('name', nest: creature.name);
            builder.element('size', nest: creature.size);
            builder.element('type', nest: creature.type);
            builder.element('alignment', nest: creature.alignment);
            builder.element('ac', nest: creature.ac.toString());
            builder.element('currentHP', nest: creature.currentHP.toString());
            builder.element('maxHP', nest: creature.maxHP.toString());
            builder.element('speed', nest: creature.speed);
            builder.element('str', nest: creature.str.toString());
            builder.element('dex', nest: creature.dex.toString());
            builder.element('con', nest: creature.con.toString());
            builder.element('intScore', nest: creature.intScore.toString());
            builder.element('wis', nest: creature.wis.toString());
            builder.element('cha', nest: creature.cha.toString());
            builder.element('saves', nest: creature.saves);
            builder.element('skills', nest: creature.skills);
            builder.element('resistances', nest: creature.resistances);
            builder.element('vulnerabilities', nest: creature.vulnerabilities);
            builder.element('immunities', nest: creature.immunities);
            builder.element('conditionImmunities',
                nest: creature.conditionImmunities);
            builder.element('senses', nest: creature.senses);
            builder.element('passivePerception',
                nest: creature.passivePerception.toString());
            builder.element('languages', nest: creature.languages);
            builder.element('cr', nest: creature.cr);

            builder.element('traits', nest: () {
              for (final trait in creature.traits) {
                builder.element('trait', nest: () {
                  builder.element('name', nest: trait.name);
                  builder.element('description', nest: trait.description);
                });
              }
            });

            builder.element('actions', nest: () {
              for (final action in creature.actions) {
                builder.element('action', nest: () {
                  builder.element('name', nest: action.name);
                  builder.element('description', nest: action.description);
                  builder.element('actionDetails', nest: action.attack);
                });
              }
            });

            builder.element('legendaryActions', nest: () {
              for (final legendary in creature.legendaryActions) {
                builder.element('legendaryAction', nest: () {
                  builder.element('name', nest: legendary.name);
                  builder.element('description', nest: legendary.description);
                });
              }
            });
          });
        }
      });
    });

    final document = builder.buildDocument();
    return document.toXmlString(pretty: true, indent: '  ');
  }

  Future<bool> exportToPDF(Character profile) async {
    try {
      await selectProfile(profile);
      final PDFBuilder pdfbuilder = PDFBuilder();
      Map<String, String> filledValues = {};

      final infos = await getProfileInfo();
      final stats = await getStats();
      final saves = await getSavingThrows();
      final skills = await getSkills();
      final weapons = await getWeapons();
      final profs = await getProficiencies();
      final spellslots = await getSpellSlots();
      final spells = await getAllSpells();
      final bag = await getBagItems();
      final items = await getItems();
      final feats = await getFeats();

      if (infos.isNotEmpty && stats.isNotEmpty) {
        int proficiencyBonus =
            int.parse(stats.first[Defines.statProficiencyBonus].toString());

        _updateInfoValues(filledValues, stats, infos);

        _updateStatValues(filledValues, stats);

        _updateWeaponValues(filledValues, weapons);

        _updateProfValues(filledValues, profs);

        _updateSavesValues(saves, filledValues, stats, proficiencyBonus);

        _updateSkillValues(skills, filledValues, stats.first, proficiencyBonus);

        _updateSpellValues(
            filledValues, spellslots, spells, stats.first, infos.first);

        _updateBagItemsValues(filledValues, bag, items);

        _updateFeatValues(filledValues, feats);
      }

      await pdfbuilder.fillAndSavePdf(filledValues);
      await closeDB();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting to PDF: $e');
      }
      return false;
    }
  }

  void _updateStatValues(
      Map<String, String> filledValues, List<Map<String, dynamic>> stats) {
    /* Stats */
    int strAbilityModifier = ((stats.first[Defines.statSTR] - 10) / 2).floor();
    int dexAbilityModifier = ((stats.first[Defines.statDEX] - 10) / 2).floor();
    int conAbilityModifier = ((stats.first[Defines.statCON] - 10) / 2).floor();
    int intAbilityModifier = ((stats.first[Defines.statINT] - 10) / 2).floor();
    int wisAbilityModifier = ((stats.first[Defines.statWIS] - 10) / 2).floor();
    int chaAbilityModifier = ((stats.first[Defines.statCHA] - 10) / 2).floor();

    filledValues["Str"] = stats.first[Defines.statSTR].toString();
    filledValues["StrMod"] = strAbilityModifier.toString();

    filledValues["Ges"] = stats.first[Defines.statDEX].toString();
    filledValues["GesMod"] = dexAbilityModifier.toString();

    filledValues["Kon"] = stats.first[Defines.statCON].toString();
    filledValues["KonMod"] = conAbilityModifier.toString();

    filledValues["Int"] = stats.first[Defines.statINT].toString();
    filledValues["IntMod"] = intAbilityModifier.toString();

    filledValues["Wei"] = stats.first[Defines.statWIS].toString();
    filledValues["WeiMod"] = wisAbilityModifier.toString();

    filledValues["Cha"] = stats.first[Defines.statCHA].toString();
    filledValues["ChaMod"] = chaAbilityModifier.toString();
  }

  void _updateInfoValues(Map<String, String> filledValues,
      List<Map<String, dynamic>> stats, List<Map<String, dynamic>> infos) {
    /* Infos */
    filledValues["Charaktername_page1"] = infos.first[Defines.infoName];
    filledValues["Charaktername_page2"] = infos.first[Defines.infoName];
    filledValues["KlasseUndStufe"] =
        "${infos.first[Defines.infoClass]} ${stats.first[Defines.statLevel]}";
    filledValues["Hintergrund"] = infos.first[Defines.infoBackground];
    filledValues["Volk"] = infos.first[Defines.infoRace];
    filledValues["Erfahrungspunkte"] = stats.first[Defines.statXP].toString();
    filledValues["Inspiration"] =
        stats.first[Defines.statInspiration] <= 1 ? "true" : "false";
    filledValues["Übungsbonus"] =
        stats.first[Defines.statProficiencyBonus].toString();
    filledValues["Rüstungsklasse"] = stats.first[Defines.statArmor].toString();
    filledValues["Initiative"] = stats.first[Defines.statInitiative].toString();
    filledValues["Bewegungsrate"] =
        stats.first[Defines.statMovement].toString();
    filledValues["TrefferpunkteMaximum"] =
        stats.first[Defines.statMaxHP].toString();
    filledValues["AktTrefferpunkte"] =
        stats.first[Defines.statCurrentHP].toString();
    filledValues["TempTrefferpunkte"] =
        stats.first[Defines.statTempHP].toString();
    filledValues["GesamtTW"] = stats.first[Defines.statMaxHitDice].toString() +
        stats.first[Defines.statHitDiceFactor].toString();
    filledValues["Trefferwürfel"] =
        stats.first[Defines.statCurrentHitDice].toString();
    filledValues["Alter"] = infos.first[Defines.infoAge].toString();
    filledValues["Glaube"] = infos.first[Defines.infoGod].toString();
    filledValues["Körpergrösse"] = infos.first[Defines.infoSize].toString();
    filledValues["Gewicht"] = infos.first[Defines.infoWeight].toString();
    filledValues["Geschlecht"] = infos.first[Defines.infoSex].toString();
    filledValues["Gesinnung"] = infos.first[Defines.infoAlignment].toString();
    filledValues["Augenfarbe"] = infos.first[Defines.infoEyeColour].toString();
    filledValues["Haarfarbe"] = infos.first[Defines.infoHairColour].toString();
    filledValues["Hautfarbe"] = infos.first[Defines.infoSkinColour].toString();
    filledValues["Persönlichkeitsmerkmale"] =
        infos.first[Defines.infoPersonalityTraits].toString();
    filledValues["Ideale"] = infos.first[Defines.infoIdeals].toString();
    filledValues["Bindungen"] = infos.first[Defines.infoBonds].toString();
    filledValues["Makel"] = infos.first[Defines.infoFlaws].toString();
    filledValues["Hintergrundgeschichte1"] =
        infos.first[Defines.infoBackstory].toString();
    filledValues["Aussehen"] = infos.first[Defines.infoAppearance].toString();
  }

  void _updateSavesValues(
      List<Map<String, dynamic>> saves,
      Map<String, String> filledValues,
      List<Map<String, dynamic>> stats,
      int proficiencyBonus) {
    int strAbilityModifier = ((stats.first[Defines.statSTR] - 10) / 2).floor();
    int dexAbilityModifier = ((stats.first[Defines.statDEX] - 10) / 2).floor();
    int conAbilityModifier = ((stats.first[Defines.statCON] - 10) / 2).floor();
    int intAbilityModifier = ((stats.first[Defines.statINT] - 10) / 2).floor();
    int wisAbilityModifier = ((stats.first[Defines.statWIS] - 10) / 2).floor();
    int chaAbilityModifier = ((stats.first[Defines.statCHA] - 10) / 2).floor();
    final abilities = [
      {
        "save": Defines.saveStr,
        "profKey": "StrProf",
        "rwKey": "StrRW",
        "modKey": strAbilityModifier
      },
      {
        "save": Defines.saveDex,
        "profKey": "GesProf",
        "rwKey": "GesRW",
        "modKey": dexAbilityModifier
      },
      {
        "save": Defines.saveCon,
        "profKey": "KonProf",
        "rwKey": "KonRW",
        "modKey": conAbilityModifier
      },
      {
        "save": Defines.saveInt,
        "profKey": "IntProf",
        "rwKey": "IntRW",
        "modKey": intAbilityModifier
      },
      {
        "save": Defines.saveWis,
        "profKey": "WeiProf",
        "rwKey": "WeiRW",
        "modKey": wisAbilityModifier
      },
      {
        "save": Defines.saveCha,
        "profKey": "ChaProf",
        "rwKey": "ChaRW",
        "modKey": chaAbilityModifier
      },
    ];

    if (saves.isNotEmpty) {
      var saveData = saves.first;

      for (var ability in abilities) {
        final isProficient = saveData[ability['save']] == 1;
        filledValues[ability['profKey'] as String] =
            isProficient ? "true" : "false";

        filledValues[ability['rwKey'] as String] = isProficient
            ? ((ability['modKey'] as int? ?? 0) + proficiencyBonus).toString()
            : ability['modKey'].toString();
      }
    }
  }

  int _calculateSkillValue(Map<String, dynamic> skill, String skillName,
      int abilityModifier, int proficiencyBonus, bool jack) {
    int skillValue = abilityModifier;

    if (skill['proficiency'] == 1) {
      skillValue += proficiencyBonus;
    }

    if (skill['expertise'] == 1) {
      skillValue += proficiencyBonus;
    }

    if (jack &&
        skill['proficiency'] != 1 &&
        skill['expertise'] != 1 &&
        skillName != Defines.skillJackofAllTrades) {
      skillValue += 1;
    }

    return skillValue;
  }

  void _updateSkillValues(
      List<Map<String, dynamic>> skills,
      Map<String, String> filledValues,
      Map<String, dynamic> stats,
      int proficiencyBonus) {
    if (skills.isNotEmpty) {
      final jack = skills.firstWhere(
                  (element) => element['skill'] == Defines.skillJackofAllTrades,
                  orElse: () => {})["proficiency"] ==
              1
          ? true
          : false;
      final dexAbilityModifier = ((stats[Defines.statDEX] - 10) / 2).floor();
      final strAbilityModifier = ((stats[Defines.statSTR] - 10) / 2).floor();
      final intAbilityModifier = ((stats[Defines.statINT] - 10) / 2).floor();
      final wisAbilityModifier = ((stats[Defines.statWIS] - 10) / 2).floor();
      final chaAbilityModifier = ((stats[Defines.statCHA] - 10) / 2).floor();

      for (var skill in skills) {
        final skillType = skill['skill'];

        switch (skillType) {
          case Defines.skillAcrobatics:
            filledValues["AkrobatikProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["AkrobatikExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["AkrobatikGes"] = _calculateSkillValue(
                    skill,
                    Defines.skillAcrobatics,
                    dexAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillArcana:
            filledValues["ArkaneKundeProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["ArkaneKundeExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["ArkaneKundeInt"] = _calculateSkillValue(
                    skill,
                    Defines.skillArcana,
                    intAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillAthletics:
            filledValues["AthletikProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["AthletikExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["AthletikStr"] = _calculateSkillValue(
                    skill,
                    Defines.skillAthletics,
                    strAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillPerformance:
            filledValues["AuftretenProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["AuftretenExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["AuftretenCha"] = _calculateSkillValue(
                    skill,
                    Defines.skillPerformance,
                    chaAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillIntimidation:
            filledValues["EinschüchternProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["EinschüchternExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["EinschüchternCha"] = _calculateSkillValue(
                    skill,
                    Defines.skillIntimidation,
                    chaAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillSleightOfHand:
            filledValues["FingerfertigkeitProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["FingerfertigkeitExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["FingerfertigkeitGes"] = _calculateSkillValue(
                    skill,
                    Defines.skillSleightOfHand,
                    dexAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillHistory:
            filledValues["GeschichteProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["GeschichteExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["GeschichteInt"] = _calculateSkillValue(
                    skill,
                    Defines.skillHistory,
                    intAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillMedicine:
            filledValues["HeilkundeProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["HeilkundeExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["HeilkundeWei"] = _calculateSkillValue(
                    skill,
                    Defines.skillMedicine,
                    wisAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillStealth:
            filledValues["HeimlichkeitProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["HeimlichkeitExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["HeimlichkeitGes"] = _calculateSkillValue(
                    skill,
                    Defines.skillStealth,
                    dexAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillAnimalHandling:
            filledValues["MitTierenUmgehenProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["MitTierenUmgehenExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["MitTierenUmgehenWei"] = _calculateSkillValue(
                    skill,
                    Defines.skillAnimalHandling,
                    wisAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillInsight:
            filledValues["MotivErkennenProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["MotivErkennenExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["MotivErkennenWei"] = _calculateSkillValue(
                    skill,
                    Defines.skillInsight,
                    wisAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillInvestigation:
            filledValues["NachforschungenProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["NachforschungenExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["NachforschungenInt"] = _calculateSkillValue(
                    skill,
                    Defines.skillInvestigation,
                    intAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillNature:
            filledValues["NaturkundeProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["NaturkundeExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["NaturkundeInt"] = _calculateSkillValue(
                    skill,
                    Defines.skillNature,
                    intAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillReligion:
            filledValues["ReligionProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["ReligionExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["ReligionInt"] = _calculateSkillValue(
                    skill,
                    Defines.skillReligion,
                    intAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillDeception:
            filledValues["TäuschenProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["TäuschenExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["TäuschenCha"] = _calculateSkillValue(
                    skill,
                    Defines.skillDeception,
                    chaAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillSurvival:
            filledValues["ÜberlebenskunstProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["ÜberlebenskunstExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["ÜberlebenskunstWei"] = _calculateSkillValue(
                    skill,
                    Defines.skillDeception,
                    chaAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillPersuasion:
            filledValues["ÜberzeugenProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["ÜberzeugenExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["ÜberzeugenCha"] = _calculateSkillValue(
                    skill,
                    Defines.skillPersuasion,
                    chaAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillPerception:
            filledValues["WahrnehmungProf"] =
                skill['proficiency'] == 1 ? "true" : "false";
            filledValues["WahrnehmungExp"] =
                skill['expertise'] == 1 ? "true" : "false";
            filledValues["WahrnehmungWei"] = _calculateSkillValue(
                    skill,
                    Defines.skillPerception,
                    wisAbilityModifier,
                    proficiencyBonus,
                    jack)
                .toString();
            break;

          case Defines.skillJackofAllTrades:
            filledValues["Alleskoenner"] =
                skill['proficiency'] == 1 ? "true" : "false";
            break;
        }
      }
    }
  }

  void _updateWeaponValues(
      Map<String, String> filledValues, List<Map<String, dynamic>> weapons) {
    int i = 0;
    if (weapons.isNotEmpty) {
      for (var weapon in weapons) {
        if (weapon['weapon'] != null && weapon['weapon']!.isNotEmpty) {
          i++;
          filledValues["Angriff$i"] = weapon['weapon'] ?? '';
          filledValues["Bonus$i"] = weapon['bonus'] ?? '';
          filledValues["Schaden$i"] = weapon['damage'] ?? '';
          filledValues["Reichweite$i"] = weapon['reach'] ?? '';
          filledValues["Beschreibung$i"] = weapon['description'] ?? '';
          filledValues["Schadentyp$i"] = weapon['damagetype'] ?? '';
        }
      }
    }
  }

  void _updateProfValues(
      Map<String, String> filledValues, List<Map<String, dynamic>> profs) {
    if (profs.isNotEmpty) {
      filledValues["SonstigeWaffen"] =
          profs.first[Defines.profWeaponList] ?? "";

      if (profs.first.containsKey(Defines.profLanguages)) {
        String languages = profs.first[Defines.profLanguages] ?? "";

        List<String> languageList = languages
            .split(RegExp(r'[,\s]+'))
            .where((lang) => lang.isNotEmpty)
            .toList();

        for (int i = 0; i < languageList.length; i++) {
          filledValues["Sprache${i + 1}"] = languageList[i];
        }
      }

      if (profs.first.containsKey(Defines.profTools)) {
        String tools = profs.first[Defines.profTools] ?? "";

        List<String> toolList = tools
            .split(',')
            .map((tool) => tool.trim())
            .where((tool) => tool.isNotEmpty)
            .toList();

        for (int i = 0; i < toolList.length; i++) {
          filledValues["WerkzeugUndAndere${i + 1}"] = toolList[i];
        }
      }
    }
  }

  void _updateSpellValues(
      Map<String, String> filledValues,
      List<Map<String, dynamic>> spellslots,
      List<Map<String, dynamic>> spells,
      Map<String, dynamic> stats,
      Map<String, dynamic> infos) {
    if (infos.isNotEmpty) {
      filledValues["Zauberklasse"] = infos[Defines.infoSpellcastingClass];
      filledValues["AttributZauberwirken"] =
          infos[Defines.infoSpellcastingAbility];
    }
    if (stats.isNotEmpty) {
      filledValues["ZauberRettungswurfSG"] =
          stats[Defines.statSpellSaveDC].toString();
      filledValues["ZauberAngriffsbonus"] =
          stats[Defines.statSpellAttackBonus].toString();
    }
    if (spellslots.isNotEmpty) {
      for (var spellslot in spellslots) {
        switch (spellslot["spellslot"]) {
          case Defines.slotOne:
            filledValues["ZauberplätzeGesamt1"] = spellslot["total"].toString();
            filledValues["ZauberplätzeVerbraucht1"] =
                spellslot["spent"].toString();
            break;
          case Defines.slotTwo:
            filledValues["ZauberplätzeGesamt2"] = spellslot["total"].toString();
            filledValues["ZauberplätzeVerbraucht2"] =
                spellslot["spent"].toString();
            break;
          case Defines.slotThree:
            filledValues["ZauberplätzeGesamt3"] = spellslot["total"].toString();
            filledValues["ZauberplätzeVerbraucht3"] =
                spellslot["spent"].toString();
            break;
          case Defines.slotFour:
            filledValues["ZauberplätzeGesamt4"] = spellslot["total"].toString();
            filledValues["ZauberplätzeVerbraucht4"] =
                spellslot["spent"].toString();
            break;
          case Defines.slotFive:
            filledValues["ZauberplätzeGesamt5"] = spellslot["total"].toString();
            filledValues["ZauberplätzeVerbraucht5"] =
                spellslot["spent"].toString();
            break;
          case Defines.slotSix:
            filledValues["ZauberplätzeGesamt6"] = spellslot["total"].toString();
            filledValues["ZauberplätzeVerbraucht6"] =
                spellslot["spent"].toString();
            break;
          case Defines.slotSeven:
            filledValues["ZauberplätzeGesamt7"] = spellslot["total"].toString();
            filledValues["ZauberplätzeVerbraucht7"] =
                spellslot["spent"].toString();
            break;
          case Defines.slotEight:
            filledValues["ZauberplätzeGesamt8"] = spellslot["total"].toString();
            filledValues["ZauberplätzeVerbraucht8"] =
                spellslot["spent"].toString();
            break;
          case Defines.slotNine:
            filledValues["ZauberplätzeGesamt9"] = spellslot["total"].toString();
            filledValues["ZauberplätzeVerbraucht9"] =
                spellslot["spent"].toString();
            break;
        }
      }
    }

    int zaubertrick = 0;
    Map<int, int> levelCounters = {for (int i = 1; i <= 9; i++) i: 0};

    if (spells.isNotEmpty) {
      for (var spell in spells) {
        int level = spell["level"];
        if (level == 0) {
          zaubertrick++;
          filledValues["Zaubertrick$zaubertrick"] = spell["spellname"];
        } else if (levelCounters.containsKey(level)) {
          levelCounters[level] = levelCounters[level]! + 1;
          int count = levelCounters[level]!;
          filledValues["ZauberActive${level}_$count"] =
              spell['status'] == Defines.spellPrep ? "true" : "false";
          filledValues["Zauber${level}_$count"] = spell["spellname"];
        }
      }
    }
  }

  void _updateBagItemsValues(
    Map<String, String> filledValues,
    List<Map<String, dynamic>> bag,
    List<Map<String, dynamic>> items,
  ) {
    if (bag.isNotEmpty) {
      filledValues["PM"] = (bag.first[Defines.bagPlatin] ?? 0).toString();
      filledValues["GM"] = (bag.first[Defines.bagGold] ?? 0).toString();
      filledValues["SM"] = (bag.first[Defines.bagSilver] ?? 0).toString();
      filledValues["KM"] = (bag.first[Defines.bagCopper] ?? 0).toString();
      filledValues["EM"] = (bag.first[Defines.bagElectrum] ?? 0).toString();
    }
    if (items.isNotEmpty) {
      int i = 0;
      for (var item in items) {
        if (item['itemname'] != null && item['itemname']!.isNotEmpty) {
          i++;
          filledValues["Inventar$i"] = item['itemname'].toString();
          filledValues["InventarAnz$i"] = item['amount'].toString();
        }
      }
    }
  }

  void _updateFeatValues(
      Map<String, String> filledValues, List<Map<String, dynamic>> feats) {
    if (feats.isNotEmpty) {
      StringBuffer classFeatures = StringBuffer();
      StringBuffer raceFeatures = StringBuffer();
      StringBuffer backgroundFeatures = StringBuffer();
      StringBuffer abilitiesFeatures = StringBuffer();
      StringBuffer otherFeatures = StringBuffer();

      bool hasClassFeats = false;
      bool hasRaceFeats = false;
      bool hasBackgroundFeats = false;
      bool hasAbilitiesFeats = false;
      bool hasOtherFeats = false;

      for (var feat in feats) {
        switch (feat["type"]) {
          case "Klasse":
            if (!hasClassFeats) {
              classFeatures.writeln("Klasse\n");
              hasClassFeats = true;
            }
            classFeatures.writeln(feat["featname"]);
            break;
          case "Rasse":
            if (!hasRaceFeats) {
              raceFeatures.writeln("");
              raceFeatures.writeln("Rasse\n");
              hasRaceFeats = true;
            }
            raceFeatures.writeln(feat["featname"]);
            break;
          case "Hintergrund":
            if (!hasBackgroundFeats) {
              backgroundFeatures.writeln("");
              backgroundFeatures.writeln("Hintergrund\n");
              hasBackgroundFeats = true;
            }
            backgroundFeatures.writeln(feat["featname"]);
            break;
          case "Fähigkeiten":
            if (!hasAbilitiesFeats) {
              abilitiesFeatures.writeln("");
              abilitiesFeatures.writeln("Fähigkeiten\n");
              hasAbilitiesFeats = true;
            }
            abilitiesFeatures.writeln(feat["featname"]);
            break;
          case "Sonstige":
            if (!hasOtherFeats) {
              otherFeatures.writeln("");
              otherFeatures.writeln("Sonstige\n");
              hasOtherFeats = true;
            }
            otherFeatures.writeln(feat["featname"]);
            break;
        }
      }

      StringBuffer allFeatures1 = StringBuffer();
      if (classFeatures.isNotEmpty) {
        allFeatures1.writeln(classFeatures.toString().trim());
      }
      if (raceFeatures.isNotEmpty) {
        allFeatures1.writeln(raceFeatures.toString().trim());
      }
      if (allFeatures1.isNotEmpty) {
        filledValues["Klassenmerkmale1"] = allFeatures1.toString().trim();
      }

      StringBuffer allFeatures2 = StringBuffer();
      if (backgroundFeatures.isNotEmpty) {
        allFeatures2.writeln(backgroundFeatures.toString().trim());
      }
      if (abilitiesFeatures.isNotEmpty) {
        allFeatures2.writeln(abilitiesFeatures.toString().trim());
      }
      if (otherFeatures.isNotEmpty) {
        allFeatures2.writeln(otherFeatures.toString().trim());
      }
      if (allFeatures2.isNotEmpty) {
        filledValues["Klassenmerkmale2"] = allFeatures2.toString().trim();
      }
    }
  }
}
