import 'package:dnd/configs/defines.dart';

class DatabaseSchema {
  static const Map<String, Map<String, String>> tablesColumns = {
    'version': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'versionNumber': 'TEXT',
    },
    'info': {
      'charId': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      Defines.infoName: 'TEXT',
      Defines.infoRace: 'TEXT',
      Defines.infoClass: 'TEXT',
      Defines.infoOrigin: 'TEXT',
      Defines.infoBackground: 'TEXT',
      Defines.infoPersonalityTraits: 'TEXT',
      Defines.infoIdeals: 'TEXT',
      Defines.infoBonds: 'TEXT',
      Defines.infoFlaws: 'TEXT',
      Defines.infoAge: 'TEXT',
      Defines.infoGod: 'TEXT',
      Defines.infoSize: 'TEXT',
      Defines.infoHeight: 'TEXT',
      Defines.infoWeight: 'TEXT',
      Defines.infoSex: 'TEXT',
      Defines.infoAlignment: 'TEXT',
      Defines.infoEyeColour: 'TEXT',
      Defines.infoHairColour: 'TEXT',
      Defines.infoSkinColour: 'TEXT',
      Defines.infoAppearance: 'TEXT',
      Defines.infoBackstory: 'TEXT',
      Defines.infoNotes: 'TEXT',
      Defines.infoSpellcastingClass: 'TEXT',
      Defines.infoSpellcastingAbility: 'TEXT',
    },
    'stats': {
      'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'charId': 'INTEGER',
      Defines.statArmor: 'INTEGER',
      Defines.statLevel: 'INTEGER',
      Defines.statXP: 'INTEGER',
      Defines.statInspiration: 'INTEGER',
      Defines.statProficiencyBonus: 'INTEGER',
      Defines.statInitiative: 'INTEGER',
      Defines.statInitiativeBonus: 'INTEGER',
      Defines.statMovement: 'TEXT',
      Defines.statMaxHP: 'INTEGER',
      Defines.statCurrentHP: 'INTEGER',
      Defines.statTempHP: 'INTEGER',
      Defines.statCurrentHitDice: 'INTEGER',
      Defines.statMaxHitDice: 'INTEGER',
      Defines.statHitDiceFactor: 'TEXT',
      Defines.statSTR: 'INTEGER',
      Defines.statDEX: 'INTEGER',
      Defines.statCON: 'INTEGER',
      Defines.statINT: 'INTEGER',
      Defines.statWIS: 'INTEGER',
      Defines.statCHA: 'INTEGER',
      Defines.statSpellSaveDC: 'INTEGER',
      Defines.statSpellAttackBonus: 'INTEGER',
      Defines.statAttunmentCount: 'INTEGER',
    },
    'savingthrow': {
      'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'charId': 'INTEGER',
      Defines.saveStr: 'INTEGER',
      Defines.saveDex: 'INTEGER',
      Defines.saveCon: 'INTEGER',
      Defines.saveInt: 'INTEGER',
      Defines.saveWis: 'INTEGER',
      Defines.saveCha: 'INTEGER',
    },
    'proficiencies': {
      'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'charId': 'INTEGER',
      Defines.profArmor: 'TEXT',
      Defines.profLightArmor: 'TEXT',
      Defines.profMediumArmor: 'TEXT',
      Defines.profHeavyArmor: 'TEXT',
      Defines.profShield: 'TEXT',
      Defines.profSimpleWeapon: 'TEXT',
      Defines.profMartialWeapon: 'TEXT',
      Defines.profOtherWeapon: 'TEXT',
      Defines.profWeaponList: 'TEXT',
      Defines.profLanguages: 'TEXT',
      Defines.profTools: 'TEXT',
    },
    'bag': {
      'ID': 'INTEGER PRIMARY KEY',
      'charId': 'INTEGER',
      Defines.bagPlatin: 'INTEGER',
      Defines.bagGold: 'INTEGER',
      Defines.bagElectrum: 'INTEGER',
      Defines.bagSilver: 'INTEGER',
      Defines.bagCopper: 'INTEGER',
    },
    'skills': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'skill': 'TEXT',
      'charId': 'INTEGER',
      'proficiency': 'INTEGER',
      'expertise': 'INTEGER',
    },
    'spellslots': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'charId': 'INTEGER',
      'spellslot': 'TEXT',
      'total': 'INTEGER',
      'spent': 'INTEGER',
    },
    'spells': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'spellname': 'TEXT',
      'charId': 'INTEGER',
      'status': 'TEXT',
      'level': 'INTEGER',
      'description': 'TEXT',
      'reach': 'TEXT',
      'duration': 'TEXT',
    },
    'weapons': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'weapon': 'TEXT',
      'charId': 'INTEGER',
      'attribute': 'TEXT',
      'reach': 'TEXT',
      'bonus': 'TEXT',
      'damage': 'TEXT',
      'damagetype': 'TEXT',
      'description': 'TEXT',
      'attunement': 'INTEGER',
    },
    'feats': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'featname': 'TEXT',
      'charId': 'INTEGER',
      'description': 'TEXT',
      'type': 'TEXT',
    },
    'items': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'itemname': 'TEXT',
      'charId': 'INTEGER',
      'description': 'TEXT',
      'type': 'TEXT',
      'amount': 'INTEGER',
      'attunement': 'INTEGER',
    },
    'tracker': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'trackername': 'TEXT',
      'charId': 'INTEGER',
      'value': 'INTEGER',
      'max': 'INTEGER',
      'type': 'TEXT',
    },
    'conditions': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'condition': 'TEXT',
      'charId': 'INTEGER',
    },
    'creatures': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'charId': 'INTEGER',
      'name': 'TEXT',
      'size': 'TEXT',
      'type': 'TEXT',
      'alignment': 'TEXT',
      'ac': 'INTEGER',
      'currentHP': 'INTEGER',
      'maxHP': 'INTEGER',
      'speed': 'TEXT',
      'str': 'INTEGER',
      'dex': 'INTEGER',
      'con': 'INTEGER',
      'intScore': 'INTEGER',
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
    },
    'creature_traits': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'charId': 'INTEGER',
      'creature_id': 'INTEGER',
      'trait_name': 'TEXT',
      'trait_description': 'TEXT',
    },
    'creature_actions': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'charId': 'INTEGER',
      'creature_id': 'INTEGER',
      'action_name': 'TEXT',
      'action_description': 'TEXT',
      'action': 'TEXT',
    },
    'creature_legendary_actions': {
      'ID': 'INTEGER PRIMARY KEY AUTOINCREMENT',
      'charId': 'INTEGER',
      'creature_id': 'INTEGER',
      'legendary_action_name': 'TEXT',
      'legendary_action_description': 'TEXT',
    },
  };

  static String createTable(String tableName) {
    if (!tablesColumns.containsKey(tableName)) return '';

    Map<String, String> columns = tablesColumns[tableName]!;
    List<String> columnDefinitions = [];

    columns.forEach((columnName, columnType) {
      columnDefinitions.add('$columnName $columnType');
    });

    if (tableName != 'version' &&
        tableName != 'info' &&
        tableName != 'creature_traits' &&
        tableName != 'creature_actions' &&
        tableName != 'creature_legendary_actions') {
      columnDefinitions.add(
          'FOREIGN KEY (charId) REFERENCES info(charId) ON DELETE CASCADE');
    }

    if (tableName == 'creature_traits' ||
        tableName == 'creature_actions' ||
        tableName == 'creature_legendary_actions') {
      columnDefinitions.add(
          'FOREIGN KEY (creature_id) REFERENCES creatures(ID) ON DELETE CASCADE');
    }

    return '''
    CREATE TABLE IF NOT EXISTS $tableName (
      ${columnDefinitions.join(', ')}
    );
    ''';
  }

  static List<String> get allTables =>
      tablesColumns.keys.map(createTable).toList();

  static Map<String, List<Map<String, String>>> getAllColumns() {
    Map<String, List<Map<String, String>>> allColumns = {};

    tablesColumns.forEach((tableName, columns) {
      List<Map<String, String>> columnList = [];

      columns.forEach((columnName, columnType) {
        columnList.add({
          'name': columnName,
          'type': columnType,
        });
      });

      allColumns[tableName] = columnList;
    });

    return allColumns;
  }

  static String versionTable() {

    String columnDefinitions = '';

    tablesColumns["version"]!.forEach((key, value) {
      columnDefinitions += '$key $value';
      if (key != tablesColumns["version"]!.keys.last) {
        columnDefinitions += ', ';
      }
    });

    return 'CREATE TABLE IF NOT EXISTS version ($columnDefinitions);';
  }
}
