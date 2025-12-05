// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get close => 'Close';

  @override
  String get bonodnd => 'For Bonobos, from Bonobos';

  @override
  String get equipments => 'Equipment/Items';

  @override
  String get additem => 'Add Item';

  @override
  String get edititem => 'Edit Item';

  @override
  String get item => 'Item';

  @override
  String get equipment => 'Equipment';

  @override
  String get other => 'Other';

  @override
  String get gold => 'GP';

  @override
  String get silver => 'SP';

  @override
  String get copper => 'CP';

  @override
  String get platinum => 'PP';

  @override
  String get electrum => 'EP';

  @override
  String get amount => 'Amount';

  @override
  String get abort => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get nodescription => 'No description available';

  @override
  String get description => 'Description';

  @override
  String get name => 'Name';

  @override
  String get confirmdelete => 'Confirm Deletion';

  @override
  String get delete => 'Delete';

  @override
  String confirmItemDelete(Object itemName) {
    return 'Are you sure you want to delete \"$itemName\"?';
  }

  @override
  String get type => 'Type';

  @override
  String get unknownchar => 'Unknown Character';

  @override
  String get createnewchar => 'Create New Character';

  @override
  String get importchar => 'Import Character from File';

  @override
  String get newchar => 'New Character';

  @override
  String get entercharactername => 'Enter Character Name';

  @override
  String get changeName => 'Rename Character';

  @override
  String get enternewname => 'Enter New Character Name';

  @override
  String get deletechar => 'Delete Character';

  @override
  String deletecharconfirm(Object profileName) {
    return 'Are you sure you want to delete the character \"$profileName\"?';
  }

  @override
  String get rename => 'Rename';

  @override
  String get saveto => 'Save to';

  @override
  String characterExists(Object profileName) {
    return 'The character \"$profileName\" already exists. Please choose a different name.';
  }

  @override
  String get create => 'Create';

  @override
  String get level => 'Level';

  @override
  String get xp => 'XP';

  @override
  String get enterxpamount => 'Enter your XP amount';

  @override
  String get longrest => 'Long Rest';

  @override
  String get shortrest => 'Short Rest';

  @override
  String get never => 'Never';

  @override
  String get longrestconfirm => 'Are you sure you want to take a long rest?';

  @override
  String get shortrestconfirm => 'Are you sure you want to take a short rest?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get addimage => 'Add Image';

  @override
  String get deleteimage => 'Remove Image';

  @override
  String get deleteimageconfirm => 'Are you sure you want to remove the image?';

  @override
  String get spells => 'Spells';

  @override
  String get weapons => 'Weapons';

  @override
  String get notes => 'Notes';

  @override
  String get wiki => 'Wiki';

  @override
  String get newFeat => 'New Feature';

  @override
  String get importfeatfromwiki => 'Import Feature from Wiki';

  @override
  String get editFeat => 'Edit Feature';

  @override
  String get deleteFeat => 'Delete Feature';

  @override
  String get feats => 'Feats';

  @override
  String get feat => 'Feat';

  @override
  String get classKey => 'Class';

  @override
  String get classesKey => 'Classes';

  @override
  String get race => 'Race';

  @override
  String get races => 'Races';

  @override
  String get background => 'Background';

  @override
  String get backgrounds => 'Backgrounds';

  @override
  String get abilities => 'Abilities';

  @override
  String get ability => 'Ability';

  @override
  String get talents => 'Talents';

  @override
  String get monster => 'Monster';

  @override
  String get folk => 'Folk';

  @override
  String get origin => 'Origin';

  @override
  String get age => 'Age';

  @override
  String get sex => 'Sex';

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get eyecolor => 'Eye Color';

  @override
  String get haircolor => 'Hair Color';

  @override
  String get skincolor => 'Skin Color';

  @override
  String get faith => 'Faith/Deity';

  @override
  String get sizecat => 'Size Category';

  @override
  String get size => 'Size';

  @override
  String get alignment => 'Alignment';

  @override
  String get look => 'Appearance';

  @override
  String get personalitytraits => 'Personality Traits';

  @override
  String get ideals => 'Ideals';

  @override
  String get bonds => 'Bonds';

  @override
  String get flaws => 'Flaws';

  @override
  String get backstory => 'Backstory';

  @override
  String get otherNotes => 'Other Notes';

  @override
  String get armors => 'Armors';

  @override
  String get tools => 'Tools';

  @override
  String get languages => 'Languages';

  @override
  String get cleardatabase => 'Clear Database';

  @override
  String get cleardatabaseconfirm =>
      'Are you sure you want to clear the database? This action cannot be undone.';

  @override
  String get exportgood => 'Export successful';

  @override
  String get exportbad => 'Export failed';

  @override
  String get nosavelocation => 'No save locations selected';

  @override
  String get exportedto => 'Exported to';

  @override
  String get exportformat => 'Export Format';

  @override
  String get noexportfilefound => 'No XML file has been loaded to export.';

  @override
  String get onlyxmlallowed => 'Only XML files are allowed';

  @override
  String get importgood => 'Import successful';

  @override
  String get importbad => 'Import failed';

  @override
  String get noimportfiles => 'No file selected for import.';

  @override
  String get export => 'Export';

  @override
  String get nocharfound => 'No character found';

  @override
  String get knownSpell => 'Known Spell';

  @override
  String get preparedSpell => 'Prepared Spell';

  @override
  String get unknown => 'Unknown';

  @override
  String get editspells => 'Edit Spells';

  @override
  String get editSpell => 'Edit Spell';

  @override
  String get deleteSpell => 'Delete Spell';

  @override
  String get addSpell => 'Add Spell';

  @override
  String get cantrip => 'Cantrip';

  @override
  String get reach => 'Reach';

  @override
  String get duration => 'Duration';

  @override
  String get spellname => 'Spell Name';

  @override
  String get status => 'Status';

  @override
  String get spell => 'Spell';

  @override
  String get spellattack => 'Spell Attack';

  @override
  String get spelldc => 'Spell Save DC';

  @override
  String get spellclass => 'Spellcasting Class';

  @override
  String get spellcastingability => 'Spellcasting Ability';

  @override
  String get spellslotsforlevel => 'Spell Slots for Level';

  @override
  String get total => 'Total';

  @override
  String get current => 'Current';

  @override
  String get addweapon => 'Add Weapon';

  @override
  String get editweapon => 'Edit Weapon';

  @override
  String get weapon => 'Weapon';

  @override
  String get damagetype => 'Damage Type';

  @override
  String get damage => 'Damage';

  @override
  String get bonus => 'Bonus';

  @override
  String get attribute => 'Attribute';

  @override
  String get search => 'Search';

  @override
  String get importwiki => 'Import Wiki';

  @override
  String get exportwiki => 'Export Wiki';

  @override
  String get deletewiki => 'Delete Wiki';

  @override
  String get noresultfound => 'No results found';

  @override
  String get allspells => 'All Spells';

  @override
  String get allmonster => 'All Monsters';

  @override
  String get hitdice => 'Hit Dice';

  @override
  String get currenthitdice => 'Current Hit Dice';

  @override
  String get maxhitdice => 'Max Hit Dice';

  @override
  String get healfactor => 'Healing Factor';

  @override
  String get numskills => 'Skill Count';

  @override
  String get spellslots => 'Spell Slots';

  @override
  String get sortbycr => 'Sort by CR';

  @override
  String get sortbyname => 'Sort by Name';

  @override
  String get filterandsort => 'Filter and Sort';

  @override
  String get importselectedcompanion => 'Import Selected Companion';

  @override
  String get createnewcompanion => 'Create New Companion';

  @override
  String get editcompanion => 'Edit Companion';

  @override
  String get addcompanion => 'Add Companion';

  @override
  String addcompanionConfirmation(Object creatureName) {
    return 'Do you want to add \"$creatureName\"?';
  }

  @override
  String get deletecompanion => 'Delete Companion';

  @override
  String get companion => 'Companion';

  @override
  String get ac => 'Armor Class';

  @override
  String get hp => 'Hit Points';

  @override
  String get movement => 'Movement';

  @override
  String get cr => 'Challenge Rating';

  @override
  String get strength => 'Strength';

  @override
  String get dexterity => 'Dexterity';

  @override
  String get constitution => 'Constitution';

  @override
  String get intelligence => 'Intelligence';

  @override
  String get wisdom => 'Wisdom';

  @override
  String get charisma => 'Charisma';

  @override
  String get strengthShort => 'STR';

  @override
  String get dexterityShort => 'DEX';

  @override
  String get constitutionShort => 'CON';

  @override
  String get intelligenceShort => 'INT';

  @override
  String get wisdomShort => 'WIS';

  @override
  String get charismaShort => 'CHA';

  @override
  String get initiative => 'Initiative';

  @override
  String get proficiencyBonus => 'Proficiency Bonus';

  @override
  String get savingThrows => 'Saving Throws';

  @override
  String get savingThrow => 'Saving Throw';

  @override
  String get savingThrowfor => 'Saving Throw für';

  @override
  String get skills => 'Skills';

  @override
  String get skill => 'Skill';

  @override
  String get editskillfor => 'Edit Skill for';

  @override
  String get resistances => 'Resistances';

  @override
  String get vulnerabilities => 'Vulnerabilities';

  @override
  String get immunities => 'Immunities';

  @override
  String get conditionImmunities => 'Condition Immunities';

  @override
  String get senses => 'Senses';

  @override
  String get passivePerception => 'Passive Perception';

  @override
  String get addtraits => 'Add Traits';

  @override
  String get action => 'Action';

  @override
  String get actions => 'Actions';

  @override
  String get addaction => 'Add Action';

  @override
  String get legendaryaction => 'Legendary Action';

  @override
  String get addlegendaryaction => 'Add Legendary Action';

  @override
  String get editlegendaryaction => 'Edit Legendary Action';

  @override
  String get editattack => 'Edit Attack';

  @override
  String get attack => 'Attack';

  @override
  String get attackvalue => 'Attack Value';

  @override
  String get requirement => 'Requirement';

  @override
  String get modifier => 'Modifier';

  @override
  String get abilityscoreincrease => 'Ability Score Increase';

  @override
  String addTraitDialog(Object traitName) {
    return 'Trait \"$traitName\" added successfully';
  }

  @override
  String get schoolTransmutation => 'Transmutation';

  @override
  String get schoolDivination => 'Divination';

  @override
  String get schoolEvocation => 'Evocation';

  @override
  String get schoolEnchantment => 'Enchantment';

  @override
  String get schoolConjuration => 'Conjuration';

  @override
  String get schoolAbjuration => 'Abjuration';

  @override
  String get schoolIllusion => 'Illusion';

  @override
  String get schoolNecromancy => 'Necromancy';

  @override
  String get schoolNone => 'No School';

  @override
  String get school => 'School';

  @override
  String get castingtime => 'Casting Time';

  @override
  String get range => 'Range';

  @override
  String get components => 'Components';

  @override
  String get ritual => 'Ritual';

  @override
  String get chooseclass => 'Choose Class';

  @override
  String get conditionBlind => 'Blinded';

  @override
  String get conditionRestrained => 'Restrained';

  @override
  String get conditionStunned => 'Stunned';

  @override
  String get conditionParalyzed => 'Paralyzed';

  @override
  String get conditionExhaustion => 'Exhaustion';

  @override
  String get conditionPoisoned => 'Poisoned';

  @override
  String get conditionFrightened => 'Frightened';

  @override
  String get conditionGrappled => 'Grappled';

  @override
  String get conditionPetrified => 'Petrified';

  @override
  String get conditionCharmed => 'Charmed';

  @override
  String get conditionDeafened => 'Deafened';

  @override
  String get conditionUnconscious => 'Unconscious';

  @override
  String get conditionProne => 'Prone';

  @override
  String get conditionIncapacitated => 'Incapacitated';

  @override
  String get conditionInvisible => 'Invisible';

  @override
  String get value => 'Value';

  @override
  String get hpfor => 'HP for';

  @override
  String get currenthp => 'Current HP';

  @override
  String get maxhp => 'Max HP';

  @override
  String get temphp => 'Temporary HP';

  @override
  String get addtracker => 'Add New Tracker';

  @override
  String get edittracker => 'Edit Tracker';

  @override
  String get tracker => 'Tracker';

  @override
  String get trackers => 'Trackers';

  @override
  String get deletetracker => 'Delete Tracker';

  @override
  String get reset => 'Reset';

  @override
  String get maximumvalue => 'Maximum Value';

  @override
  String get currentvalue => 'Current Value';

  @override
  String get entertrackername => 'Enter Tracker Name';

  @override
  String get trackername => 'Tracker Name';

  @override
  String get addcondition => 'Add Condition';

  @override
  String get choosecondition => 'Choose Condition';

  @override
  String get editcondition => 'Edit Condition';

  @override
  String get statistic => 'Statistic';

  @override
  String get inspiration => 'Inspiration';

  @override
  String get statuseffects => 'Status Effects';

  @override
  String get deletestatuseffect => 'Delete Status Effect';

  @override
  String get edit => 'Edit';

  @override
  String get proficiency => 'Proficiency';

  @override
  String get expertise => 'Expertise';

  @override
  String get jack => 'Jack of all Trades';

  @override
  String get skillAcrobatics => 'Acrobatics';

  @override
  String get skillArcana => 'Arcana';

  @override
  String get skillAthletics => 'Athletics';

  @override
  String get skillPerformance => 'Performance';

  @override
  String get skillIntimidation => 'Intimidation';

  @override
  String get skillSleightOfHand => 'Sleight of Hand';

  @override
  String get skillHistory => 'History';

  @override
  String get skillMedicine => 'Medicine';

  @override
  String get skillStealth => 'Stealth';

  @override
  String get skillAnimalHandling => 'Animal Handling';

  @override
  String get skillInsight => 'Insight';

  @override
  String get skillInvestigation => 'Investigation';

  @override
  String get skillNature => 'Nature';

  @override
  String get skillReligion => 'Religion';

  @override
  String get skillDeception => 'Deception';

  @override
  String get skillSurvival => 'Survival';

  @override
  String get skillPersuasion => 'Persuasion';

  @override
  String get skillPerception => 'Perception';

  @override
  String get updateAvailableTitle => 'Update Available';

  @override
  String updateAvailableContent(Object latestVersion, Object currentVersion) {
    return 'A new version ($latestVersion) is available. You are using version $currentVersion.';
  }

  @override
  String get skip => 'Skip';

  @override
  String get update => 'Update';

  @override
  String get downloadingTitle => 'Downloading...';

  @override
  String get downloadingContent =>
      'Please wait while the new version is being downloaded.';

  @override
  String get installPermissionTitle => 'Installation Not Allowed';

  @override
  String get installPermissionContent =>
      'Please allow this app to install unknown sources in system settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get updateFailedTitle => 'Update Failed';

  @override
  String get updateFailedContent =>
      'The update could not be downloaded or installed. Please try again later.';

  @override
  String get ok => 'OK';

  @override
  String get attunement => 'Attunement';

  @override
  String get attunementLimit => 'You can only attune to a maximum of 3 items.';

  @override
  String get attunementlimitReached => 'Attunement limit reached.';

  @override
  String get skillAcrobaticsDescription =>
      'Execute agile stunts and maneuvers while maintaining balance and coordination.';

  @override
  String get skillAnimalHandlingDescription =>
      'Calm, control, or intuitively understand animal behavior to guide or influence creatures.';

  @override
  String get skillArcanaDescription =>
      'Recall and apply knowledge about magic, mystical traditions, and ancient lore.';

  @override
  String get skillAthleticsDescription =>
      'Perform physical feats such as climbing, swimming, jumping, and other exertions of strength and endurance.';

  @override
  String get skillDeceptionDescription =>
      'Convincingly lie, mislead, or manipulate others through falsehoods or trickery.';

  @override
  String get skillHistoryDescription =>
      'Remember and interpret significant historical events, cultures, and legends.';

  @override
  String get skillInsightDescription =>
      'Discern others’ true intentions, emotions, or motives by reading their body language and speech.';

  @override
  String get skillIntimidationDescription =>
      'Use threats, force, or a commanding presence to influence or coerce others.';

  @override
  String get skillInvestigationDescription =>
      'Search for, analyze, and piece together clues to solve mysteries or puzzles.';

  @override
  String get skillMedicineDescription =>
      'Diagnose illnesses, treat wounds, and provide basic medical care to stabilize the injured.';

  @override
  String get skillNatureDescription =>
      'Understand flora, fauna, natural cycles, and survival tactics within the wilderness.';

  @override
  String get skillPerceptionDescription =>
      'Detect hidden details, subtle sounds, or movements others might miss.';

  @override
  String get skillPerformanceDescription =>
      'Entertain or captivate an audience through music, dance, acting, or other expressive arts.';

  @override
  String get skillPersuasionDescription =>
      'Convince or influence others through reason, charm, or heartfelt appeals.';

  @override
  String get skillReligionDescription =>
      'Possess knowledge of deities, sacred rites, religious customs, and spiritual lore.';

  @override
  String get skillSleightOfHandDescription =>
      'Perform quick, precise, or concealed manual tricks, such as picking pockets or performing magic.';

  @override
  String get skillStealthDescription =>
      'Move silently and remain unseen to avoid detection.';

  @override
  String get skillSurvivalDescription =>
      'Track creatures, hunt for food, find shelter, and navigate harsh natural environments.';

  @override
  String get session => 'Session';

  @override
  String get hostSession => 'Host Session';

  @override
  String get joinedSession => 'Joined Session';

  @override
  String get sessionSettings => 'Session Settings';

  @override
  String get showPlayerHP => 'Show Player HP to Clients';

  @override
  String get showPlayerAC => 'Show Player AC to Clients';

  @override
  String get unnamedSession => 'Unnamed Session';

  @override
  String hostingSessionMessage(Object sessionName) {
    return 'Hosting \"$sessionName\"';
  }

  @override
  String get chooseCharacter => 'Choose Character';

  @override
  String get noCharactersFound =>
      'No characters found. Please create one first.';

  @override
  String get selectYourCharacter => 'Select your character';

  @override
  String get pleaseSelectCharacter => 'Please select a character!';

  @override
  String get join => 'Join';

  @override
  String get enterSessionNameHint => 'Enter session name...';

  @override
  String get serverRunning => 'Server Running...';

  @override
  String get startHosting => 'Start Hosting';

  @override
  String get searchingForSessions => 'Searching for sessions...';

  @override
  String get unknownSession => 'Unknown Session';

  @override
  String get hostGame => 'Host Game';

  @override
  String get joinGame => 'Join Game';

  @override
  String get sessionLobby => 'D&D Session Lobby';

  @override
  String get confirmStopHosting => 'Confirm Stop Hosting';

  @override
  String get stopHostingWarning =>
      'Are you sure you want to stop hosting this session? All players will be disconnected.';

  @override
  String get stopHosting => 'Stop Hosting';

  @override
  String setInitiativeFor(Object playerName) {
    return 'Set Initiative for $playerName';
  }

  @override
  String hostingSessionTitle(Object sessionName) {
    return 'Hosting: $sessionName';
  }

  @override
  String get sessionInfo => 'Session Info';

  @override
  String get connectedPlayers => 'Connected Players:';

  @override
  String get nextTurn => 'Next Turn';

  @override
  String get noPlayersConnected => 'No players connected yet.';

  @override
  String get initiativeLabel => 'Initiative: ';

  @override
  String get addMonsterNpc => 'Add Monster/NPC';

  @override
  String get viewFullDetails => 'View Full Details';

  @override
  String get editName => 'Edit Name';

  @override
  String get editHp => 'Edit HP';

  @override
  String get editAc => 'Edit AC';

  @override
  String editNameFor(Object name) {
    return 'Edit Name for $name';
  }

  @override
  String editHpFor(Object name) {
    return 'Edit HP for $name';
  }

  @override
  String editAcFor(Object name) {
    return 'Edit AC for $name';
  }

  @override
  String get armorClass => 'Armor Class';

  @override
  String sessionTitle(Object sessionName) {
    return 'Session: $sessionName';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get quitSession => 'Quit Session';

  @override
  String get playersAndInitiative => 'Players & Initiative:';

  @override
  String get you => 'You';

  @override
  String get monsterNpc => 'Monster/NPC';

  @override
  String get player => 'Player';
}
