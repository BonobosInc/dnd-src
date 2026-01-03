class WikiDatabaseSchema {
  static const String version = '1.0.0';

  // Version table
  static const Map<String, String> versionTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'versionNumber': 'TEXT',
  };

  // Migration tracking table
  static const Map<String, String> migrationTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'migrated': 'INTEGER DEFAULT 0',
    'migrationDate': 'TEXT',
    'sourceFile': 'TEXT',
  };

  // Classes tables
  static const Map<String, String> classesTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'name': 'TEXT NOT NULL',
    'hd': 'TEXT',
    'proficiency': 'TEXT',
    'spellAbility': 'TEXT',
    'numSkills': 'TEXT',
  };

  static const Map<String, String> classAutolevelsTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'classId': 'INTEGER NOT NULL',
    'level': 'TEXT',
  };

  static const Map<String, String> classFeaturesTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'autolevelId': 'INTEGER NOT NULL',
    'name': 'TEXT',
    'description': 'TEXT',
    'type': 'TEXT',
  };

  static const Map<String, String> classSlotsTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'autolevelId': 'INTEGER NOT NULL',
    'slot1': 'INTEGER',
    'slot2': 'INTEGER',
    'slot3': 'INTEGER',
    'slot4': 'INTEGER',
    'slot5': 'INTEGER',
    'slot6': 'INTEGER',
    'slot7': 'INTEGER',
    'slot8': 'INTEGER',
    'slot9': 'INTEGER',
  };

  // Races table
  static const Map<String, String> racesTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'name': 'TEXT NOT NULL',
    'size': 'TEXT',
    'speed': 'INTEGER',
    'ability': 'TEXT',
    'proficiency': 'TEXT',
    'spellAbility': 'TEXT',
  };

  static const Map<String, String> raceTraitsTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'raceId': 'INTEGER NOT NULL',
    'name': 'TEXT',
    'description': 'TEXT',
  };

  // Backgrounds table
  static const Map<String, String> backgroundsTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'name': 'TEXT NOT NULL',
    'proficiency': 'TEXT',
  };

  static const Map<String, String> backgroundTraitsTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'backgroundId': 'INTEGER NOT NULL',
    'name': 'TEXT',
    'description': 'TEXT',
  };

  // Feats table
  static const Map<String, String> featsTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'name': 'TEXT NOT NULL',
    'prerequisite': 'TEXT',
    'text': 'TEXT',
    'modifier': 'TEXT',
  };

  // Spells table
  static const Map<String, String> spellsTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'name': 'TEXT NOT NULL',
    'level': 'TEXT',
    'school': 'TEXT',
    'ritual': 'TEXT',
    'time': 'TEXT',
    'range': 'TEXT',
    'components': 'TEXT',
    'duration': 'TEXT',
    'text': 'TEXT',
  };

  static const Map<String, String> spellClassesTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'spellId': 'INTEGER NOT NULL',
    'className': 'TEXT',
  };

  // Creatures table
  static const Map<String, String> creaturesTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'name': 'TEXT NOT NULL',
    'size': 'TEXT',
    'type': 'TEXT',
    'alignment': 'TEXT',
    'ac': 'INTEGER',
    'maxHP': 'INTEGER',
    'speed': 'TEXT',
    'str': 'INTEGER',
    'dex': 'INTEGER',
    'con': 'INTEGER',
    'int': 'INTEGER',
    'wis': 'INTEGER',
    'cha': 'INTEGER',
    'saves': 'TEXT',
    'skills': 'TEXT',
    'resistances': 'TEXT',
    'vulnerabilities': 'TEXT',
    'immunities': 'TEXT',
    'conditionImmunities': 'TEXT',
    'senses': 'TEXT',
    'passivePerception': 'INTEGER',
    'languages': 'TEXT',
    'cr': 'TEXT',
  };

  static const Map<String, String> creatureTraitsTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'creatureId': 'INTEGER NOT NULL',
    'name': 'TEXT',
    'description': 'TEXT',
  };

  static const Map<String, String> creatureActionsTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'creatureId': 'INTEGER NOT NULL',
    'name': 'TEXT',
    'description': 'TEXT',
    'attack': 'TEXT',
  };

  static const Map<String, String> creatureLegendaryTable = {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'creatureId': 'INTEGER NOT NULL',
    'name': 'TEXT',
    'description': 'TEXT',
  };

  // Helper methods to generate CREATE TABLE statements
  static String _createTableSql(String tableName, Map<String, String> columns) {
    final columnDefinitions =
        columns.entries.map((e) => '${e.key} ${e.value}').join(', ');
    return 'CREATE TABLE IF NOT EXISTS $tableName ($columnDefinitions)';
  }

  static String createVersionTable() =>
      _createTableSql('wiki_version', versionTable);
  static String createMigrationTable() =>
      _createTableSql('wiki_migration', migrationTable);
  static String createClassesTable() =>
      _createTableSql('wiki_classes', classesTable);
  static String createClassAutolevelsTable() =>
      _createTableSql('wiki_class_autolevels', classAutolevelsTable);
  static String createClassFeaturesTable() =>
      _createTableSql('wiki_class_features', classFeaturesTable);
  static String createClassSlotsTable() =>
      _createTableSql('wiki_class_slots', classSlotsTable);
  static String createRacesTable() => _createTableSql('wiki_races', racesTable);
  static String createRaceTraitsTable() =>
      _createTableSql('wiki_race_traits', raceTraitsTable);
  static String createBackgroundsTable() =>
      _createTableSql('wiki_backgrounds', backgroundsTable);
  static String createBackgroundTraitsTable() =>
      _createTableSql('wiki_background_traits', backgroundTraitsTable);
  static String createFeatsTable() => _createTableSql('wiki_feats', featsTable);
  static String createSpellsTable() =>
      _createTableSql('wiki_spells', spellsTable);
  static String createSpellClassesTable() =>
      _createTableSql('wiki_spell_classes', spellClassesTable);
  static String createCreaturesTable() =>
      _createTableSql('wiki_creatures', creaturesTable);
  static String createCreatureTraitsTable() =>
      _createTableSql('wiki_creature_traits', creatureTraitsTable);
  static String createCreatureActionsTable() =>
      _createTableSql('wiki_creature_actions', creatureActionsTable);
  static String createCreatureLegendaryTable() =>
      _createTableSql('wiki_creature_legendary', creatureLegendaryTable);

  // Get all table creation statements
  static List<String> get allTableStatements => [
        createVersionTable(),
        createMigrationTable(),
        createClassesTable(),
        createClassAutolevelsTable(),
        createClassFeaturesTable(),
        createClassSlotsTable(),
        createRacesTable(),
        createRaceTraitsTable(),
        createBackgroundsTable(),
        createBackgroundTraitsTable(),
        createFeatsTable(),
        createSpellsTable(),
        createSpellClassesTable(),
        createCreaturesTable(),
        createCreatureTraitsTable(),
        createCreatureActionsTable(),
        createCreatureLegendaryTable(),
      ];
}
