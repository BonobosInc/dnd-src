import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @darkMode.
  ///
  /// In de, this message translates to:
  /// **'Dunkelmodus'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @close.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get close;

  /// No description provided for @bonodnd.
  ///
  /// In de, this message translates to:
  /// **'Für Bonobos, von Bonobos'**
  String get bonodnd;

  /// No description provided for @equipments.
  ///
  /// In de, this message translates to:
  /// **'Gegenstände/Ausrüstung'**
  String get equipments;

  /// No description provided for @additem.
  ///
  /// In de, this message translates to:
  /// **'Gegenstand hinzufügen'**
  String get additem;

  /// No description provided for @edititem.
  ///
  /// In de, this message translates to:
  /// **'Gegenstand bearbeiten'**
  String get edititem;

  /// No description provided for @importitem.
  ///
  /// In de, this message translates to:
  /// **'Aus Wiki importieren'**
  String get importitem;

  /// No description provided for @item.
  ///
  /// In de, this message translates to:
  /// **'Gegenstand'**
  String get item;

  /// No description provided for @equipment.
  ///
  /// In de, this message translates to:
  /// **'Ausrüstung'**
  String get equipment;

  /// No description provided for @other.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get other;

  /// No description provided for @gold.
  ///
  /// In de, this message translates to:
  /// **'GM'**
  String get gold;

  /// No description provided for @silver.
  ///
  /// In de, this message translates to:
  /// **'SM'**
  String get silver;

  /// No description provided for @copper.
  ///
  /// In de, this message translates to:
  /// **'KM'**
  String get copper;

  /// No description provided for @platinum.
  ///
  /// In de, this message translates to:
  /// **'PM'**
  String get platinum;

  /// No description provided for @electrum.
  ///
  /// In de, this message translates to:
  /// **'EM'**
  String get electrum;

  /// No description provided for @amount.
  ///
  /// In de, this message translates to:
  /// **'Menge'**
  String get amount;

  /// No description provided for @abort.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get abort;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @nodescription.
  ///
  /// In de, this message translates to:
  /// **'Keine Beschreibung vorhanden'**
  String get nodescription;

  /// No description provided for @description.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get description;

  /// No description provided for @name.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @confirmdelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen bestätigen'**
  String get confirmdelete;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// Confirmation message for deleting an item.
  ///
  /// In de, this message translates to:
  /// **'Bist du sicher, dass du \"{itemName}\" löschen möchtest?'**
  String confirmItemDelete(Object itemName);

  /// No description provided for @type.
  ///
  /// In de, this message translates to:
  /// **'Typ'**
  String get type;

  /// No description provided for @itemdetails.
  ///
  /// In de, this message translates to:
  /// **'Gegenstandsdetails'**
  String get itemdetails;

  /// No description provided for @allitems.
  ///
  /// In de, this message translates to:
  /// **'Alle Gegenstände'**
  String get allitems;

  /// No description provided for @items.
  ///
  /// In de, this message translates to:
  /// **'Gegenstände'**
  String get items;

  /// No description provided for @sortbytype.
  ///
  /// In de, this message translates to:
  /// **'Nach Typ sortieren'**
  String get sortbytype;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeite'**
  String get edit;

  /// No description provided for @itemTypeCurrency.
  ///
  /// In de, this message translates to:
  /// **'Währung'**
  String get itemTypeCurrency;

  /// No description provided for @itemTypeAmmunition.
  ///
  /// In de, this message translates to:
  /// **'Munition'**
  String get itemTypeAmmunition;

  /// No description provided for @itemTypeLightArmor.
  ///
  /// In de, this message translates to:
  /// **'Leichte Rüstung'**
  String get itemTypeLightArmor;

  /// No description provided for @itemTypeMediumArmor.
  ///
  /// In de, this message translates to:
  /// **'Mittlere Rüstung'**
  String get itemTypeMediumArmor;

  /// No description provided for @itemTypeHeavyArmor.
  ///
  /// In de, this message translates to:
  /// **'Schwere Rüstung'**
  String get itemTypeHeavyArmor;

  /// No description provided for @itemTypeMeleeWeapon.
  ///
  /// In de, this message translates to:
  /// **'Nahkampfwaffe'**
  String get itemTypeMeleeWeapon;

  /// No description provided for @itemTypePotion.
  ///
  /// In de, this message translates to:
  /// **'Trank'**
  String get itemTypePotion;

  /// No description provided for @itemTypeRangedWeapon.
  ///
  /// In de, this message translates to:
  /// **'Fernkampfwaffe'**
  String get itemTypeRangedWeapon;

  /// No description provided for @itemTypeRod.
  ///
  /// In de, this message translates to:
  /// **'Stab'**
  String get itemTypeRod;

  /// No description provided for @itemTypeRing.
  ///
  /// In de, this message translates to:
  /// **'Ring'**
  String get itemTypeRing;

  /// No description provided for @itemTypeScroll.
  ///
  /// In de, this message translates to:
  /// **'Schriftrolle'**
  String get itemTypeScroll;

  /// No description provided for @itemTypeShield.
  ///
  /// In de, this message translates to:
  /// **'Schild'**
  String get itemTypeShield;

  /// No description provided for @itemTypeWondrousItem.
  ///
  /// In de, this message translates to:
  /// **'Wundersamer Gegenstand'**
  String get itemTypeWondrousItem;

  /// No description provided for @itemTypeAdventuringGear.
  ///
  /// In de, this message translates to:
  /// **'Abenteuerausrüstung'**
  String get itemTypeAdventuringGear;

  /// No description provided for @itemTypeTools.
  ///
  /// In de, this message translates to:
  /// **'Werkzeuge'**
  String get itemTypeTools;

  /// No description provided for @itemTypeArtisanFocus.
  ///
  /// In de, this message translates to:
  /// **'Handwerkerfokus'**
  String get itemTypeArtisanFocus;

  /// No description provided for @itemTypeTradeGoods.
  ///
  /// In de, this message translates to:
  /// **'Handelswaren'**
  String get itemTypeTradeGoods;

  /// No description provided for @manageItemTypes.
  ///
  /// In de, this message translates to:
  /// **'Gegenstands-Typen verwalten'**
  String get manageItemTypes;

  /// No description provided for @newTypeName.
  ///
  /// In de, this message translates to:
  /// **'Neuer Typname'**
  String get newTypeName;

  /// No description provided for @defaultType.
  ///
  /// In de, this message translates to:
  /// **'Standard'**
  String get defaultType;

  /// No description provided for @customType.
  ///
  /// In de, this message translates to:
  /// **'Benutzerdefiniert'**
  String get customType;

  /// No description provided for @addType.
  ///
  /// In de, this message translates to:
  /// **'Typ hinzufügen'**
  String get addType;

  /// No description provided for @deleteType.
  ///
  /// In de, this message translates to:
  /// **'Typ löschen'**
  String get deleteType;

  /// No description provided for @unknownchar.
  ///
  /// In de, this message translates to:
  /// **'Unbekannter Charakter'**
  String get unknownchar;

  /// No description provided for @createnewchar.
  ///
  /// In de, this message translates to:
  /// **'Neuen Charakter erstellen'**
  String get createnewchar;

  /// No description provided for @importchar.
  ///
  /// In de, this message translates to:
  /// **'Charakter aus Datei importieren'**
  String get importchar;

  /// No description provided for @newchar.
  ///
  /// In de, this message translates to:
  /// **'Neuer Charakter'**
  String get newchar;

  /// No description provided for @entercharactername.
  ///
  /// In de, this message translates to:
  /// **'Charakternamen eingeben'**
  String get entercharactername;

  /// No description provided for @changeName.
  ///
  /// In de, this message translates to:
  /// **'Charakter umbenennen'**
  String get changeName;

  /// No description provided for @enternewname.
  ///
  /// In de, this message translates to:
  /// **'Neuen Charakternamen eingeben'**
  String get enternewname;

  /// No description provided for @deletechar.
  ///
  /// In de, this message translates to:
  /// **'Charakter löschen'**
  String get deletechar;

  /// Confirmation message for deleting a character.
  ///
  /// In de, this message translates to:
  /// **'Bist du sicher, dass du den Charakter \"{profileName}\" löschen möchtest?'**
  String deletecharconfirm(Object profileName);

  /// No description provided for @rename.
  ///
  /// In de, this message translates to:
  /// **'Umbenennen'**
  String get rename;

  /// No description provided for @saveto.
  ///
  /// In de, this message translates to:
  /// **'Speichern unter'**
  String get saveto;

  /// Error message shown when a character name already exists.
  ///
  /// In de, this message translates to:
  /// **'Der Charakter \"{profileName}\" existiert bereits. Bitte wähle einen anderen Namen.'**
  String characterExists(Object profileName);

  /// No description provided for @create.
  ///
  /// In de, this message translates to:
  /// **'Erstellen'**
  String get create;

  /// No description provided for @level.
  ///
  /// In de, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @xp.
  ///
  /// In de, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @enterxpamount.
  ///
  /// In de, this message translates to:
  /// **'Gib die Anzahl deiner XP ein'**
  String get enterxpamount;

  /// No description provided for @longrest.
  ///
  /// In de, this message translates to:
  /// **'Lange Rast'**
  String get longrest;

  /// No description provided for @shortrest.
  ///
  /// In de, this message translates to:
  /// **'Kurze Rast'**
  String get shortrest;

  /// No description provided for @never.
  ///
  /// In de, this message translates to:
  /// **'Niemals'**
  String get never;

  /// No description provided for @longrestconfirm.
  ///
  /// In de, this message translates to:
  /// **'Bist du sicher, dass du eine lange Rast machen möchtest?'**
  String get longrestconfirm;

  /// No description provided for @shortrestconfirm.
  ///
  /// In de, this message translates to:
  /// **'Bist du sicher, dass du eine kurze Rast machen möchtest?'**
  String get shortrestconfirm;

  /// No description provided for @yes.
  ///
  /// In de, this message translates to:
  /// **'Ja'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In de, this message translates to:
  /// **'Nein'**
  String get no;

  /// No description provided for @addimage.
  ///
  /// In de, this message translates to:
  /// **'Bild hinzufügen'**
  String get addimage;

  /// No description provided for @deleteimage.
  ///
  /// In de, this message translates to:
  /// **'Bild entfernen'**
  String get deleteimage;

  /// No description provided for @deleteimageconfirm.
  ///
  /// In de, this message translates to:
  /// **'Bist du sicher, dass du das Bild entfernen möchtest?'**
  String get deleteimageconfirm;

  /// No description provided for @spells.
  ///
  /// In de, this message translates to:
  /// **'Zauber'**
  String get spells;

  /// No description provided for @weapons.
  ///
  /// In de, this message translates to:
  /// **'Waffen'**
  String get weapons;

  /// No description provided for @notes.
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get notes;

  /// No description provided for @wiki.
  ///
  /// In de, this message translates to:
  /// **'Wiki'**
  String get wiki;

  /// No description provided for @newFeat.
  ///
  /// In de, this message translates to:
  /// **'neues Merkmal'**
  String get newFeat;

  /// No description provided for @importfeatfromwiki.
  ///
  /// In de, this message translates to:
  /// **'Merkmal aus Wiki importieren'**
  String get importfeatfromwiki;

  /// No description provided for @editFeat.
  ///
  /// In de, this message translates to:
  /// **'Merkmal bearbeiten'**
  String get editFeat;

  /// No description provided for @deleteFeat.
  ///
  /// In de, this message translates to:
  /// **'Merkmal löschen'**
  String get deleteFeat;

  /// No description provided for @feats.
  ///
  /// In de, this message translates to:
  /// **'Merkmale'**
  String get feats;

  /// No description provided for @feat.
  ///
  /// In de, this message translates to:
  /// **'Merkmal'**
  String get feat;

  /// No description provided for @classKey.
  ///
  /// In de, this message translates to:
  /// **'Klasse'**
  String get classKey;

  /// No description provided for @classesKey.
  ///
  /// In de, this message translates to:
  /// **'Klassen'**
  String get classesKey;

  /// No description provided for @race.
  ///
  /// In de, this message translates to:
  /// **'Rasse'**
  String get race;

  /// No description provided for @races.
  ///
  /// In de, this message translates to:
  /// **'Rassen'**
  String get races;

  /// No description provided for @background.
  ///
  /// In de, this message translates to:
  /// **'Hintergrund'**
  String get background;

  /// No description provided for @backgrounds.
  ///
  /// In de, this message translates to:
  /// **'Hintergründe'**
  String get backgrounds;

  /// No description provided for @abilities.
  ///
  /// In de, this message translates to:
  /// **'Fähigkeiten'**
  String get abilities;

  /// No description provided for @ability.
  ///
  /// In de, this message translates to:
  /// **'Fähigkeit'**
  String get ability;

  /// No description provided for @talents.
  ///
  /// In de, this message translates to:
  /// **'Talente'**
  String get talents;

  /// No description provided for @monster.
  ///
  /// In de, this message translates to:
  /// **'Monster'**
  String get monster;

  /// No description provided for @folk.
  ///
  /// In de, this message translates to:
  /// **'Volk'**
  String get folk;

  /// No description provided for @origin.
  ///
  /// In de, this message translates to:
  /// **'Herkunft'**
  String get origin;

  /// No description provided for @age.
  ///
  /// In de, this message translates to:
  /// **'Alter'**
  String get age;

  /// No description provided for @sex.
  ///
  /// In de, this message translates to:
  /// **'Geschlecht'**
  String get sex;

  /// No description provided for @height.
  ///
  /// In de, this message translates to:
  /// **'Größe'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get weight;

  /// No description provided for @eyecolor.
  ///
  /// In de, this message translates to:
  /// **'Augenfarbe'**
  String get eyecolor;

  /// No description provided for @haircolor.
  ///
  /// In de, this message translates to:
  /// **'Haarfarbe'**
  String get haircolor;

  /// No description provided for @skincolor.
  ///
  /// In de, this message translates to:
  /// **'Hautfarbe'**
  String get skincolor;

  /// No description provided for @faith.
  ///
  /// In de, this message translates to:
  /// **'Glaube/Gottheit'**
  String get faith;

  /// No description provided for @sizecat.
  ///
  /// In de, this message translates to:
  /// **'Größenkategorie'**
  String get sizecat;

  /// No description provided for @size.
  ///
  /// In de, this message translates to:
  /// **'Größe'**
  String get size;

  /// No description provided for @alignment.
  ///
  /// In de, this message translates to:
  /// **'Gesinnung'**
  String get alignment;

  /// No description provided for @look.
  ///
  /// In de, this message translates to:
  /// **'Aussehen'**
  String get look;

  /// No description provided for @personalitytraits.
  ///
  /// In de, this message translates to:
  /// **'Persönlichkeitsmerkmale'**
  String get personalitytraits;

  /// No description provided for @ideals.
  ///
  /// In de, this message translates to:
  /// **'Ideale'**
  String get ideals;

  /// No description provided for @bonds.
  ///
  /// In de, this message translates to:
  /// **'Bindungen'**
  String get bonds;

  /// No description provided for @flaws.
  ///
  /// In de, this message translates to:
  /// **'Makel'**
  String get flaws;

  /// No description provided for @backstory.
  ///
  /// In de, this message translates to:
  /// **'Hintergrundgeschichte'**
  String get backstory;

  /// No description provided for @otherNotes.
  ///
  /// In de, this message translates to:
  /// **'Sonstige Notizen'**
  String get otherNotes;

  /// No description provided for @armors.
  ///
  /// In de, this message translates to:
  /// **'Rüstungen'**
  String get armors;

  /// No description provided for @tools.
  ///
  /// In de, this message translates to:
  /// **'Werkzeuge'**
  String get tools;

  /// No description provided for @languages.
  ///
  /// In de, this message translates to:
  /// **'Sprachen'**
  String get languages;

  /// No description provided for @cleardatabase.
  ///
  /// In de, this message translates to:
  /// **'Datenbank leeren'**
  String get cleardatabase;

  /// No description provided for @cleardatabaseconfirm.
  ///
  /// In de, this message translates to:
  /// **'Bist du sicher, dass du die Datenbank leeren möchtest? Alle Charaktere und Einstellungen gehen verloren.'**
  String get cleardatabaseconfirm;

  /// No description provided for @exportgood.
  ///
  /// In de, this message translates to:
  /// **'Export erfolgreich'**
  String get exportgood;

  /// No description provided for @exportbad.
  ///
  /// In de, this message translates to:
  /// **'Export fehlgeschlagen'**
  String get exportbad;

  /// No description provided for @nosavelocation.
  ///
  /// In de, this message translates to:
  /// **'Keine Speicherorte ausgewählt'**
  String get nosavelocation;

  /// No description provided for @exportedto.
  ///
  /// In de, this message translates to:
  /// **'Exportiert nach'**
  String get exportedto;

  /// No description provided for @exportformat.
  ///
  /// In de, this message translates to:
  /// **'Exportformat'**
  String get exportformat;

  /// No description provided for @noexportfilefound.
  ///
  /// In de, this message translates to:
  /// **'Keine XML-Datei wurde zum Exportieren geladen.'**
  String get noexportfilefound;

  /// No description provided for @onlyxmlallowed.
  ///
  /// In de, this message translates to:
  /// **'Nur XML-Dateien sind erlaubt'**
  String get onlyxmlallowed;

  /// No description provided for @importgood.
  ///
  /// In de, this message translates to:
  /// **'Import erfolgreich'**
  String get importgood;

  /// No description provided for @importbad.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen'**
  String get importbad;

  /// No description provided for @noimportfiles.
  ///
  /// In de, this message translates to:
  /// **'Keine Datei zum importieren ausgewählt.'**
  String get noimportfiles;

  /// No description provided for @export.
  ///
  /// In de, this message translates to:
  /// **'Exportieren'**
  String get export;

  /// No description provided for @nocharfound.
  ///
  /// In de, this message translates to:
  /// **'Kein Charakter vorhanden.'**
  String get nocharfound;

  /// No description provided for @knownSpell.
  ///
  /// In de, this message translates to:
  /// **'bekannter Zauber'**
  String get knownSpell;

  /// No description provided for @preparedSpell.
  ///
  /// In de, this message translates to:
  /// **'vorbereiteter Zauber'**
  String get preparedSpell;

  /// No description provided for @unknown.
  ///
  /// In de, this message translates to:
  /// **'nicht bekannt'**
  String get unknown;

  /// No description provided for @editspells.
  ///
  /// In de, this message translates to:
  /// **'Zauber bearbeiten'**
  String get editspells;

  /// No description provided for @editSpell.
  ///
  /// In de, this message translates to:
  /// **'Zauber bearbeiten'**
  String get editSpell;

  /// No description provided for @deleteSpell.
  ///
  /// In de, this message translates to:
  /// **'Zauber löschen'**
  String get deleteSpell;

  /// No description provided for @addSpell.
  ///
  /// In de, this message translates to:
  /// **'Zauber hinzufügen'**
  String get addSpell;

  /// No description provided for @cantrip.
  ///
  /// In de, this message translates to:
  /// **'Zaubertrick'**
  String get cantrip;

  /// No description provided for @reach.
  ///
  /// In de, this message translates to:
  /// **'Reichweite'**
  String get reach;

  /// No description provided for @duration.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get duration;

  /// No description provided for @spellname.
  ///
  /// In de, this message translates to:
  /// **'Zaubername'**
  String get spellname;

  /// No description provided for @status.
  ///
  /// In de, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @spell.
  ///
  /// In de, this message translates to:
  /// **'Zauber'**
  String get spell;

  /// No description provided for @spellattack.
  ///
  /// In de, this message translates to:
  /// **'Zauberangriff'**
  String get spellattack;

  /// No description provided for @spelldc.
  ///
  /// In de, this message translates to:
  /// **'Zauberrettungswurf-SG'**
  String get spelldc;

  /// No description provided for @spellclass.
  ///
  /// In de, this message translates to:
  /// **'Zauberwirkende Klasse'**
  String get spellclass;

  /// No description provided for @spellcastingability.
  ///
  /// In de, this message translates to:
  /// **'Zauberattrribut'**
  String get spellcastingability;

  /// No description provided for @spellslotsforlevel.
  ///
  /// In de, this message translates to:
  /// **'Zauberplätze für Stufe'**
  String get spellslotsforlevel;

  /// No description provided for @total.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get total;

  /// No description provided for @current.
  ///
  /// In de, this message translates to:
  /// **'Aktuell'**
  String get current;

  /// No description provided for @addweapon.
  ///
  /// In de, this message translates to:
  /// **'Waffe hinzufügen'**
  String get addweapon;

  /// No description provided for @editweapon.
  ///
  /// In de, this message translates to:
  /// **'Waffe bearbeiten'**
  String get editweapon;

  /// No description provided for @weapon.
  ///
  /// In de, this message translates to:
  /// **'Waffe'**
  String get weapon;

  /// No description provided for @damagetype.
  ///
  /// In de, this message translates to:
  /// **'Schadenstyp'**
  String get damagetype;

  /// No description provided for @damage.
  ///
  /// In de, this message translates to:
  /// **'Schaden'**
  String get damage;

  /// No description provided for @bonus.
  ///
  /// In de, this message translates to:
  /// **'Bonus'**
  String get bonus;

  /// No description provided for @attribute.
  ///
  /// In de, this message translates to:
  /// **'Attribut'**
  String get attribute;

  /// No description provided for @search.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get search;

  /// No description provided for @importwiki.
  ///
  /// In de, this message translates to:
  /// **'Wiki importieren'**
  String get importwiki;

  /// No description provided for @exportwiki.
  ///
  /// In de, this message translates to:
  /// **'Wiki exportieren'**
  String get exportwiki;

  /// No description provided for @deletewiki.
  ///
  /// In de, this message translates to:
  /// **'Wiki löschen'**
  String get deletewiki;

  /// No description provided for @noresultfound.
  ///
  /// In de, this message translates to:
  /// **'Keine Ergebnisse gefunden'**
  String get noresultfound;

  /// No description provided for @allspells.
  ///
  /// In de, this message translates to:
  /// **'Alle Zauber'**
  String get allspells;

  /// No description provided for @allmonster.
  ///
  /// In de, this message translates to:
  /// **'Alle Monster'**
  String get allmonster;

  /// No description provided for @hitdice.
  ///
  /// In de, this message translates to:
  /// **'Trefferwürfel'**
  String get hitdice;

  /// No description provided for @currenthitdice.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Trefferwürfel'**
  String get currenthitdice;

  /// No description provided for @maxhitdice.
  ///
  /// In de, this message translates to:
  /// **'Maximale Trefferwürfel'**
  String get maxhitdice;

  /// No description provided for @healfactor.
  ///
  /// In de, this message translates to:
  /// **'Heilfaktor'**
  String get healfactor;

  /// No description provided for @numskills.
  ///
  /// In de, this message translates to:
  /// **'Anzahl Skills'**
  String get numskills;

  /// No description provided for @spellslots.
  ///
  /// In de, this message translates to:
  /// **'Zauberplätze'**
  String get spellslots;

  /// No description provided for @sortbycr.
  ///
  /// In de, this message translates to:
  /// **'Nach CR sortieren'**
  String get sortbycr;

  /// No description provided for @sortbyname.
  ///
  /// In de, this message translates to:
  /// **'Nach Name sortieren'**
  String get sortbyname;

  /// No description provided for @filterandsort.
  ///
  /// In de, this message translates to:
  /// **'Filtern und Sortieren'**
  String get filterandsort;

  /// No description provided for @importselectedcompanion.
  ///
  /// In de, this message translates to:
  /// **'Ausgewählten Begleiter importieren'**
  String get importselectedcompanion;

  /// No description provided for @createnewcompanion.
  ///
  /// In de, this message translates to:
  /// **'Neuen Begleiter erstellen'**
  String get createnewcompanion;

  /// No description provided for @editcompanion.
  ///
  /// In de, this message translates to:
  /// **'Begleiter bearbeiten'**
  String get editcompanion;

  /// No description provided for @addcompanion.
  ///
  /// In de, this message translates to:
  /// **'Begleiter hinzufügen'**
  String get addcompanion;

  /// Add Companion
  ///
  /// In de, this message translates to:
  /// **'Möchtest du \"{creatureName}\" hinzufügen?'**
  String addcompanionConfirmation(Object creatureName);

  /// No description provided for @deletecompanion.
  ///
  /// In de, this message translates to:
  /// **'Begleiter löschen'**
  String get deletecompanion;

  /// No description provided for @companion.
  ///
  /// In de, this message translates to:
  /// **'Begleiter'**
  String get companion;

  /// No description provided for @ac.
  ///
  /// In de, this message translates to:
  /// **'Rüstungsklasse'**
  String get ac;

  /// No description provided for @hp.
  ///
  /// In de, this message translates to:
  /// **'Trefferpunkte'**
  String get hp;

  /// No description provided for @movement.
  ///
  /// In de, this message translates to:
  /// **'Bewegungsrate'**
  String get movement;

  /// No description provided for @cr.
  ///
  /// In de, this message translates to:
  /// **'Herausforderungsgrad'**
  String get cr;

  /// No description provided for @strength.
  ///
  /// In de, this message translates to:
  /// **'Stärke'**
  String get strength;

  /// No description provided for @dexterity.
  ///
  /// In de, this message translates to:
  /// **'Geschicklichkeit'**
  String get dexterity;

  /// No description provided for @constitution.
  ///
  /// In de, this message translates to:
  /// **'Konstitution'**
  String get constitution;

  /// No description provided for @intelligence.
  ///
  /// In de, this message translates to:
  /// **'Intelligenz'**
  String get intelligence;

  /// No description provided for @wisdom.
  ///
  /// In de, this message translates to:
  /// **'Weisheit'**
  String get wisdom;

  /// No description provided for @charisma.
  ///
  /// In de, this message translates to:
  /// **'Charisma'**
  String get charisma;

  /// No description provided for @strengthShort.
  ///
  /// In de, this message translates to:
  /// **'STÄ'**
  String get strengthShort;

  /// No description provided for @dexterityShort.
  ///
  /// In de, this message translates to:
  /// **'GES'**
  String get dexterityShort;

  /// No description provided for @constitutionShort.
  ///
  /// In de, this message translates to:
  /// **'KON'**
  String get constitutionShort;

  /// No description provided for @intelligenceShort.
  ///
  /// In de, this message translates to:
  /// **'INT'**
  String get intelligenceShort;

  /// No description provided for @wisdomShort.
  ///
  /// In de, this message translates to:
  /// **'WEI'**
  String get wisdomShort;

  /// No description provided for @charismaShort.
  ///
  /// In de, this message translates to:
  /// **'CHA'**
  String get charismaShort;

  /// No description provided for @initiative.
  ///
  /// In de, this message translates to:
  /// **'Initiative'**
  String get initiative;

  /// No description provided for @proficiencyBonus.
  ///
  /// In de, this message translates to:
  /// **'ÜbungsBonus'**
  String get proficiencyBonus;

  /// No description provided for @savingThrows.
  ///
  /// In de, this message translates to:
  /// **'Rettungswürfe'**
  String get savingThrows;

  /// No description provided for @savingThrow.
  ///
  /// In de, this message translates to:
  /// **'Rettungswurf'**
  String get savingThrow;

  /// No description provided for @savingThrowfor.
  ///
  /// In de, this message translates to:
  /// **'Rettungswurf für'**
  String get savingThrowfor;

  /// No description provided for @skills.
  ///
  /// In de, this message translates to:
  /// **'Fertigkeiten'**
  String get skills;

  /// No description provided for @skill.
  ///
  /// In de, this message translates to:
  /// **'Fertigkeit'**
  String get skill;

  /// No description provided for @editskillfor.
  ///
  /// In de, this message translates to:
  /// **'Bearbeite Fertigkeit für'**
  String get editskillfor;

  /// No description provided for @resistances.
  ///
  /// In de, this message translates to:
  /// **'Resistenzen'**
  String get resistances;

  /// No description provided for @vulnerabilities.
  ///
  /// In de, this message translates to:
  /// **'Verwundbarkeiten'**
  String get vulnerabilities;

  /// No description provided for @immunities.
  ///
  /// In de, this message translates to:
  /// **'Immunitäten'**
  String get immunities;

  /// No description provided for @conditionImmunities.
  ///
  /// In de, this message translates to:
  /// **'Zustandsimmunitäten'**
  String get conditionImmunities;

  /// No description provided for @senses.
  ///
  /// In de, this message translates to:
  /// **'Sinneswahrnehmungen'**
  String get senses;

  /// No description provided for @passivePerception.
  ///
  /// In de, this message translates to:
  /// **'Passive Wahrnehmung'**
  String get passivePerception;

  /// No description provided for @addtraits.
  ///
  /// In de, this message translates to:
  /// **'Merkmale hinzufügen'**
  String get addtraits;

  /// No description provided for @action.
  ///
  /// In de, this message translates to:
  /// **'Aktion'**
  String get action;

  /// No description provided for @actions.
  ///
  /// In de, this message translates to:
  /// **'Aktionen'**
  String get actions;

  /// No description provided for @addaction.
  ///
  /// In de, this message translates to:
  /// **'Aktion hinzufügen'**
  String get addaction;

  /// No description provided for @legendaryaction.
  ///
  /// In de, this message translates to:
  /// **'Legendäre Aktion'**
  String get legendaryaction;

  /// No description provided for @legendaryActions.
  ///
  /// In de, this message translates to:
  /// **'Legendäre Aktionen'**
  String get legendaryActions;

  /// No description provided for @addlegendaryaction.
  ///
  /// In de, this message translates to:
  /// **'Legendäre Aktion hinzufügen'**
  String get addlegendaryaction;

  /// No description provided for @editlegendaryaction.
  ///
  /// In de, this message translates to:
  /// **'Legendäre Aktion bearbeiten'**
  String get editlegendaryaction;

  /// No description provided for @editattack.
  ///
  /// In de, this message translates to:
  /// **'Angriff bearbeiten'**
  String get editattack;

  /// No description provided for @attack.
  ///
  /// In de, this message translates to:
  /// **'Angriff'**
  String get attack;

  /// No description provided for @attackvalue.
  ///
  /// In de, this message translates to:
  /// **'Angriffswert'**
  String get attackvalue;

  /// No description provided for @requirement.
  ///
  /// In de, this message translates to:
  /// **'Voraussetzung'**
  String get requirement;

  /// No description provided for @modifier.
  ///
  /// In de, this message translates to:
  /// **'Modifikator'**
  String get modifier;

  /// No description provided for @abilityscoreincrease.
  ///
  /// In de, this message translates to:
  /// **'Fähigkeitspunktsteigerung'**
  String get abilityscoreincrease;

  /// Add Trait
  ///
  /// In de, this message translates to:
  /// **'Merkmal \"{traitName}\" erfolgreich hinzugefügt'**
  String addTraitDialog(Object traitName);

  /// No description provided for @schoolTransmutation.
  ///
  /// In de, this message translates to:
  /// **'Verwandlungszauber'**
  String get schoolTransmutation;

  /// No description provided for @schoolDivination.
  ///
  /// In de, this message translates to:
  /// **'Weissagung'**
  String get schoolDivination;

  /// No description provided for @schoolEvocation.
  ///
  /// In de, this message translates to:
  /// **'Hervorrufungszauber'**
  String get schoolEvocation;

  /// No description provided for @schoolEnchantment.
  ///
  /// In de, this message translates to:
  /// **'Verzauberungen'**
  String get schoolEnchantment;

  /// No description provided for @schoolConjuration.
  ///
  /// In de, this message translates to:
  /// **'Beschwörung'**
  String get schoolConjuration;

  /// No description provided for @schoolAbjuration.
  ///
  /// In de, this message translates to:
  /// **'Bannmagie'**
  String get schoolAbjuration;

  /// No description provided for @schoolIllusion.
  ///
  /// In de, this message translates to:
  /// **'Illusion'**
  String get schoolIllusion;

  /// No description provided for @schoolNecromancy.
  ///
  /// In de, this message translates to:
  /// **'Nekromantiezauber'**
  String get schoolNecromancy;

  /// No description provided for @schoolNone.
  ///
  /// In de, this message translates to:
  /// **'Keine Schule'**
  String get schoolNone;

  /// No description provided for @school.
  ///
  /// In de, this message translates to:
  /// **'Schule'**
  String get school;

  /// No description provided for @castingtime.
  ///
  /// In de, this message translates to:
  /// **'Zauberzeit'**
  String get castingtime;

  /// No description provided for @range.
  ///
  /// In de, this message translates to:
  /// **'Reichweite'**
  String get range;

  /// No description provided for @components.
  ///
  /// In de, this message translates to:
  /// **'Komponenten'**
  String get components;

  /// No description provided for @ritual.
  ///
  /// In de, this message translates to:
  /// **'Ritual'**
  String get ritual;

  /// No description provided for @chooseclass.
  ///
  /// In de, this message translates to:
  /// **'Klasse auswählen'**
  String get chooseclass;

  /// No description provided for @conditionBlind.
  ///
  /// In de, this message translates to:
  /// **'Blind'**
  String get conditionBlind;

  /// No description provided for @conditionRestrained.
  ///
  /// In de, this message translates to:
  /// **'Festgesetzt'**
  String get conditionRestrained;

  /// No description provided for @conditionStunned.
  ///
  /// In de, this message translates to:
  /// **'Betäubt'**
  String get conditionStunned;

  /// No description provided for @conditionParalyzed.
  ///
  /// In de, this message translates to:
  /// **'Gelähmt'**
  String get conditionParalyzed;

  /// No description provided for @conditionExhaustion.
  ///
  /// In de, this message translates to:
  /// **'Erschöpfung'**
  String get conditionExhaustion;

  /// No description provided for @conditionPoisoned.
  ///
  /// In de, this message translates to:
  /// **'Vergiftet'**
  String get conditionPoisoned;

  /// No description provided for @conditionFrightened.
  ///
  /// In de, this message translates to:
  /// **'Verängstigt'**
  String get conditionFrightened;

  /// No description provided for @conditionGrappled.
  ///
  /// In de, this message translates to:
  /// **'Gepackt'**
  String get conditionGrappled;

  /// No description provided for @conditionPetrified.
  ///
  /// In de, this message translates to:
  /// **'Versteinert'**
  String get conditionPetrified;

  /// No description provided for @conditionCharmed.
  ///
  /// In de, this message translates to:
  /// **'Bezaubert'**
  String get conditionCharmed;

  /// No description provided for @conditionDeafened.
  ///
  /// In de, this message translates to:
  /// **'Taub'**
  String get conditionDeafened;

  /// No description provided for @conditionUnconscious.
  ///
  /// In de, this message translates to:
  /// **'Bewusstlos'**
  String get conditionUnconscious;

  /// No description provided for @conditionProne.
  ///
  /// In de, this message translates to:
  /// **'Liegend'**
  String get conditionProne;

  /// No description provided for @conditionIncapacitated.
  ///
  /// In de, this message translates to:
  /// **'Kampfunfähig'**
  String get conditionIncapacitated;

  /// No description provided for @conditionInvisible.
  ///
  /// In de, this message translates to:
  /// **'Unsichtbar'**
  String get conditionInvisible;

  /// No description provided for @value.
  ///
  /// In de, this message translates to:
  /// **'Wert'**
  String get value;

  /// No description provided for @hpfor.
  ///
  /// In de, this message translates to:
  /// **'HP für'**
  String get hpfor;

  /// No description provided for @currenthp.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle HP'**
  String get currenthp;

  /// No description provided for @maxhp.
  ///
  /// In de, this message translates to:
  /// **'Maximale HP'**
  String get maxhp;

  /// No description provided for @temphp.
  ///
  /// In de, this message translates to:
  /// **'Temporäre HP'**
  String get temphp;

  /// No description provided for @addtracker.
  ///
  /// In de, this message translates to:
  /// **'Neuen Tracker erstellen'**
  String get addtracker;

  /// No description provided for @edittracker.
  ///
  /// In de, this message translates to:
  /// **'Tracker bearbeiten'**
  String get edittracker;

  /// No description provided for @tracker.
  ///
  /// In de, this message translates to:
  /// **'Tracker'**
  String get tracker;

  /// No description provided for @trackers.
  ///
  /// In de, this message translates to:
  /// **'Trackers'**
  String get trackers;

  /// No description provided for @deletetracker.
  ///
  /// In de, this message translates to:
  /// **'Tracker löschen'**
  String get deletetracker;

  /// No description provided for @reset.
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get reset;

  /// No description provided for @maximumvalue.
  ///
  /// In de, this message translates to:
  /// **'Maximaler Wert'**
  String get maximumvalue;

  /// No description provided for @currentvalue.
  ///
  /// In de, this message translates to:
  /// **'Aktueller Wert'**
  String get currentvalue;

  /// No description provided for @entertrackername.
  ///
  /// In de, this message translates to:
  /// **'Trackername eingeben'**
  String get entertrackername;

  /// No description provided for @trackername.
  ///
  /// In de, this message translates to:
  /// **'Trackername'**
  String get trackername;

  /// No description provided for @addcondition.
  ///
  /// In de, this message translates to:
  /// **'Zustand hinzufügen'**
  String get addcondition;

  /// No description provided for @choosecondition.
  ///
  /// In de, this message translates to:
  /// **'Zustand auswählen'**
  String get choosecondition;

  /// No description provided for @editcondition.
  ///
  /// In de, this message translates to:
  /// **'Zustand bearbeiten'**
  String get editcondition;

  /// No description provided for @statistic.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get statistic;

  /// No description provided for @inspiration.
  ///
  /// In de, this message translates to:
  /// **'Inspiration'**
  String get inspiration;

  /// No description provided for @statuseffects.
  ///
  /// In de, this message translates to:
  /// **'Status-Effekte'**
  String get statuseffects;

  /// No description provided for @deletestatuseffect.
  ///
  /// In de, this message translates to:
  /// **'Status-Effekt löschen'**
  String get deletestatuseffect;

  /// No description provided for @add.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get add;

  /// No description provided for @trait.
  ///
  /// In de, this message translates to:
  /// **'Merkmal'**
  String get trait;

  /// No description provided for @traits.
  ///
  /// In de, this message translates to:
  /// **'Merkmale'**
  String get traits;

  /// No description provided for @editTrait.
  ///
  /// In de, this message translates to:
  /// **'Merkmal bearbeiten'**
  String get editTrait;

  /// No description provided for @addTrait.
  ///
  /// In de, this message translates to:
  /// **'Merkmal hinzufügen'**
  String get addTrait;

  /// No description provided for @feature.
  ///
  /// In de, this message translates to:
  /// **'Klassenmerkmal'**
  String get feature;

  /// No description provided for @addFeature.
  ///
  /// In de, this message translates to:
  /// **'Klassenmerkmal hinzufügen'**
  String get addFeature;

  /// No description provided for @editFeature.
  ///
  /// In de, this message translates to:
  /// **'Klassenmerkmal bearbeiten'**
  String get editFeature;

  /// No description provided for @proficiency.
  ///
  /// In de, this message translates to:
  /// **'Übung'**
  String get proficiency;

  /// No description provided for @expertise.
  ///
  /// In de, this message translates to:
  /// **'Expertise'**
  String get expertise;

  /// No description provided for @jack.
  ///
  /// In de, this message translates to:
  /// **'Alleskönner'**
  String get jack;

  /// No description provided for @skillAcrobatics.
  ///
  /// In de, this message translates to:
  /// **'Akrobatik'**
  String get skillAcrobatics;

  /// No description provided for @skillArcana.
  ///
  /// In de, this message translates to:
  /// **'Arkane Kenntnis'**
  String get skillArcana;

  /// No description provided for @skillAthletics.
  ///
  /// In de, this message translates to:
  /// **'Athletik'**
  String get skillAthletics;

  /// No description provided for @skillPerformance.
  ///
  /// In de, this message translates to:
  /// **'Auftreten'**
  String get skillPerformance;

  /// No description provided for @skillIntimidation.
  ///
  /// In de, this message translates to:
  /// **'Einschüchtern'**
  String get skillIntimidation;

  /// No description provided for @skillSleightOfHand.
  ///
  /// In de, this message translates to:
  /// **'Fingerfertigkeit'**
  String get skillSleightOfHand;

  /// No description provided for @skillHistory.
  ///
  /// In de, this message translates to:
  /// **'Geschichte'**
  String get skillHistory;

  /// No description provided for @skillMedicine.
  ///
  /// In de, this message translates to:
  /// **'Heilkunde'**
  String get skillMedicine;

  /// No description provided for @skillStealth.
  ///
  /// In de, this message translates to:
  /// **'Heimlichkeit'**
  String get skillStealth;

  /// No description provided for @skillAnimalHandling.
  ///
  /// In de, this message translates to:
  /// **'Mit Tieren umgehen'**
  String get skillAnimalHandling;

  /// No description provided for @skillInsight.
  ///
  /// In de, this message translates to:
  /// **'Motiv erkennen'**
  String get skillInsight;

  /// No description provided for @skillInvestigation.
  ///
  /// In de, this message translates to:
  /// **'Nachforschung'**
  String get skillInvestigation;

  /// No description provided for @skillNature.
  ///
  /// In de, this message translates to:
  /// **'Naturkunde'**
  String get skillNature;

  /// No description provided for @skillReligion.
  ///
  /// In de, this message translates to:
  /// **'Religion'**
  String get skillReligion;

  /// No description provided for @skillDeception.
  ///
  /// In de, this message translates to:
  /// **'Täuschen'**
  String get skillDeception;

  /// No description provided for @skillSurvival.
  ///
  /// In de, this message translates to:
  /// **'Überlebenskunst'**
  String get skillSurvival;

  /// No description provided for @skillPersuasion.
  ///
  /// In de, this message translates to:
  /// **'Überzeugen'**
  String get skillPersuasion;

  /// No description provided for @skillPerception.
  ///
  /// In de, this message translates to:
  /// **'Wahrnehmung'**
  String get skillPerception;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Aktualisierung verfügbar'**
  String get updateAvailableTitle;

  /// VersionCheck
  ///
  /// In de, this message translates to:
  /// **'Eine neue Version ({latestVersion}) ist erhältlich. Du verwendest Version {currentVersion}.'**
  String updateAvailableContent(Object latestVersion, Object currentVersion);

  /// No description provided for @skip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get skip;

  /// No description provided for @update.
  ///
  /// In de, this message translates to:
  /// **'Aktualisieren'**
  String get update;

  /// No description provided for @downloadingTitle.
  ///
  /// In de, this message translates to:
  /// **'Herunterladen...'**
  String get downloadingTitle;

  /// No description provided for @downloadingContent.
  ///
  /// In de, this message translates to:
  /// **'Bitte warten, die neue Version wird heruntergeladen.'**
  String get downloadingContent;

  /// No description provided for @installPermissionTitle.
  ///
  /// In de, this message translates to:
  /// **'Installation nicht erlaubt'**
  String get installPermissionTitle;

  /// No description provided for @installPermissionContent.
  ///
  /// In de, this message translates to:
  /// **'Bitte erlaube dieser App die Installation von unbekannten Quellen in den Systemeinstellungen.'**
  String get installPermissionContent;

  /// No description provided for @openSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get openSettings;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @updateFailedTitle.
  ///
  /// In de, this message translates to:
  /// **'Aktualisierung fehlgeschlagen'**
  String get updateFailedTitle;

  /// No description provided for @updateFailedContent.
  ///
  /// In de, this message translates to:
  /// **'Die Aktualisierung konnte nicht heruntergeladen oder installiert werden. Bitte versuche es später erneut.'**
  String get updateFailedContent;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @attunement.
  ///
  /// In de, this message translates to:
  /// **'Einstimmung'**
  String get attunement;

  /// No description provided for @attunementLimit.
  ///
  /// In de, this message translates to:
  /// **'Du kannst dich nur auf maximal 3 Gegenstände einstimmen.'**
  String get attunementLimit;

  /// No description provided for @attunementlimitReached.
  ///
  /// In de, this message translates to:
  /// **'Einstimmungsgrenze erreicht.'**
  String get attunementlimitReached;

  /// No description provided for @skillAcrobaticsDescription.
  ///
  /// In de, this message translates to:
  /// **'Führe agile Stunts und Manöver aus und behalte dabei Gleichgewicht und Koordination.'**
  String get skillAcrobaticsDescription;

  /// No description provided for @skillAnimalHandlingDescription.
  ///
  /// In de, this message translates to:
  /// **'Beruhige, kontrolliere oder verstehe intuitiv das Verhalten von Tieren, um sie zu führen oder zu beeinflussen.'**
  String get skillAnimalHandlingDescription;

  /// No description provided for @skillArcanaDescription.
  ///
  /// In de, this message translates to:
  /// **'Erinnere dich an und wende Wissen über Magie, mystische Traditionen und alte Überlieferungen an.'**
  String get skillArcanaDescription;

  /// No description provided for @skillAthleticsDescription.
  ///
  /// In de, this message translates to:
  /// **'Führe körperliche Leistungen wie Klettern, Schwimmen, Springen und andere Kraft- und Ausdauerleistungen aus.'**
  String get skillAthleticsDescription;

  /// No description provided for @skillDeceptionDescription.
  ///
  /// In de, this message translates to:
  /// **'Täusche andere überzeugend, indem du lügst, irreführst oder manipulativ handelst.'**
  String get skillDeceptionDescription;

  /// No description provided for @skillHistoryDescription.
  ///
  /// In de, this message translates to:
  /// **'Erinnere dich an und interpretiere bedeutende historische Ereignisse, Kulturen und Legenden.'**
  String get skillHistoryDescription;

  /// No description provided for @skillInsightDescription.
  ///
  /// In de, this message translates to:
  /// **'Erkenne die wahren Absichten, Emotionen oder Motive anderer durch das Lesen ihrer Körpersprache und Sprache.'**
  String get skillInsightDescription;

  /// No description provided for @skillIntimidationDescription.
  ///
  /// In de, this message translates to:
  /// **'Setze Drohungen, Gewalt oder eine einschüchternde Präsenz ein, um andere zu beeinflussen oder zu zwingen.'**
  String get skillIntimidationDescription;

  /// No description provided for @skillInvestigationDescription.
  ///
  /// In de, this message translates to:
  /// **'Suche nach, analysiere und füge Hinweise zusammen, um Geheimnisse oder Rätsel zu lösen.'**
  String get skillInvestigationDescription;

  /// No description provided for @skillMedicineDescription.
  ///
  /// In de, this message translates to:
  /// **'Diagnostiziere Krankheiten, behandle Wunden und leiste grundlegende medizinische Versorgung zur Stabilisierung Verletzter.'**
  String get skillMedicineDescription;

  /// No description provided for @skillNatureDescription.
  ///
  /// In de, this message translates to:
  /// **'Verstehe Pflanzen, Tiere, natürliche Zyklen und Überlebenstaktiken in der Wildnis.'**
  String get skillNatureDescription;

  /// No description provided for @skillPerceptionDescription.
  ///
  /// In de, this message translates to:
  /// **'Erkenne versteckte Details, leise Geräusche oder Bewegungen, die anderen entgehen könnten.'**
  String get skillPerceptionDescription;

  /// No description provided for @skillPerformanceDescription.
  ///
  /// In de, this message translates to:
  /// **'Unterhalte oder fessle ein Publikum durch Musik, Tanz, Schauspiel oder andere Ausdrucksformen.'**
  String get skillPerformanceDescription;

  /// No description provided for @skillPersuasionDescription.
  ///
  /// In de, this message translates to:
  /// **'Überzeuge oder beeinflusse andere durch Vernunft, Charme oder ehrliche Appelle.'**
  String get skillPersuasionDescription;

  /// No description provided for @skillReligionDescription.
  ///
  /// In de, this message translates to:
  /// **'Besitze Wissen über Götter, heilige Rituale, religiöse Bräuche und spirituelle Überlieferungen.'**
  String get skillReligionDescription;

  /// No description provided for @skillSleightOfHandDescription.
  ///
  /// In de, this message translates to:
  /// **'Führe schnelle, präzise oder verdeckte manuelle Tricks aus, wie Taschendiebstahl oder Zauberkunststücke.'**
  String get skillSleightOfHandDescription;

  /// No description provided for @skillStealthDescription.
  ///
  /// In de, this message translates to:
  /// **'Bewege dich lautlos und bleibe ungesehen, um einer Entdeckung zu entgehen.'**
  String get skillStealthDescription;

  /// No description provided for @skillSurvivalDescription.
  ///
  /// In de, this message translates to:
  /// **'Spüre Kreaturen auf, jage nach Nahrung, finde Unterschlupf und navigiere in rauer Natur.'**
  String get skillSurvivalDescription;

  /// No description provided for @chooseCreationMethod.
  ///
  /// In de, this message translates to:
  /// **'Wähle, wie du deinen Charakter erstellen möchtest:'**
  String get chooseCreationMethod;

  /// No description provided for @blankCharacter.
  ///
  /// In de, this message translates to:
  /// **'Leerer Charakterbogen'**
  String get blankCharacter;

  /// No description provided for @characterCreator.
  ///
  /// In de, this message translates to:
  /// **'Charaktererstellung'**
  String get characterCreator;

  /// No description provided for @confirmTooltip.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get confirmTooltip;

  /// No description provided for @selectMethodHint.
  ///
  /// In de, this message translates to:
  /// **'Methode auswählen'**
  String get selectMethodHint;

  /// No description provided for @standardArray.
  ///
  /// In de, this message translates to:
  /// **'Standardwerte'**
  String get standardArray;

  /// No description provided for @pointBuy.
  ///
  /// In de, this message translates to:
  /// **'Punktekauf'**
  String get pointBuy;

  /// No description provided for @roll4d6.
  ///
  /// In de, this message translates to:
  /// **'4d6 würfeln, niedrigsten verwerfen'**
  String get roll4d6;

  /// No description provided for @custom.
  ///
  /// In de, this message translates to:
  /// **'Benutzerdefiniert'**
  String get custom;

  /// No description provided for @assignRacialBonuses.
  ///
  /// In de, this message translates to:
  /// **'Volksbonus zuweisen:'**
  String get assignRacialBonuses;

  /// No description provided for @assignBonusHint.
  ///
  /// In de, this message translates to:
  /// **'Bonus zuweisen'**
  String get assignBonusHint;

  /// No description provided for @selectValue.
  ///
  /// In de, this message translates to:
  /// **'Wert auswählen'**
  String get selectValue;

  /// No description provided for @selectRoll.
  ///
  /// In de, this message translates to:
  /// **'Wurf auswählen'**
  String get selectRoll;

  /// No description provided for @roll.
  ///
  /// In de, this message translates to:
  /// **'Wurf'**
  String get roll;

  /// No description provided for @pointsUsed.
  ///
  /// In de, this message translates to:
  /// **'Punkte verwendet: {used} / {pool}'**
  String pointsUsed(Object pool, Object used);

  /// No description provided for @pleaseAssignAll.
  ///
  /// In de, this message translates to:
  /// **'Bitte weisen Sie alle sechs Fähigkeitswerte zu.'**
  String get pleaseAssignAll;

  /// No description provided for @rolledValuesLabel.
  ///
  /// In de, this message translates to:
  /// **'Gewürfelte Werte: {values}'**
  String rolledValuesLabel(Object values);

  /// No description provided for @assignRolledValues.
  ///
  /// In de, this message translates to:
  /// **'Gewürfelte Werte den Fähigkeiten zuweisen:'**
  String get assignRolledValues;

  /// No description provided for @rollAllTooltip.
  ///
  /// In de, this message translates to:
  /// **'Alle würfeln'**
  String get rollAllTooltip;

  /// No description provided for @chooserace.
  ///
  /// In de, this message translates to:
  /// **'Volk auswählen'**
  String get chooserace;

  /// No description provided for @choosebackground.
  ///
  /// In de, this message translates to:
  /// **'Hintergrund auswählen'**
  String get choosebackground;

  /// No description provided for @completeallsteps.
  ///
  /// In de, this message translates to:
  /// **'Bitte schließe alle Schritte ab, bevor du den Charakter erstellst.'**
  String get completeallsteps;

  /// No description provided for @choosefeat.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Fertigkeit'**
  String get choosefeat;

  /// No description provided for @chooseskills.
  ///
  /// In de, this message translates to:
  /// **'Wähle Fertigkeiten'**
  String get chooseskills;

  /// No description provided for @setabilityscores.
  ///
  /// In de, this message translates to:
  /// **'Attributswerte festlegen'**
  String get setabilityscores;

  /// No description provided for @selectSkillProficiencies.
  ///
  /// In de, this message translates to:
  /// **'Wähle Fertigkeitsübungen'**
  String get selectSkillProficiencies;

  /// No description provided for @selectSkillExpertise.
  ///
  /// In de, this message translates to:
  /// **'Wähle Fertigkeitsexpertisen'**
  String get selectSkillExpertise;

  /// Available skill choices remaining
  ///
  /// In de, this message translates to:
  /// **'Verfügbare Fertigkeitsauswahlen: {count}'**
  String availableSkillChoices(Object count);

  /// Select up to X skills
  ///
  /// In de, this message translates to:
  /// **'Wähle bis zu {count} Fertigkeiten'**
  String selectUpToSkills(Object count);

  /// No description provided for @fromBackground.
  ///
  /// In de, this message translates to:
  /// **'Vom Hintergrund'**
  String get fromBackground;

  /// No description provided for @fromRace.
  ///
  /// In de, this message translates to:
  /// **'Vom Volk'**
  String get fromRace;

  /// No description provided for @choosespells.
  ///
  /// In de, this message translates to:
  /// **'Zauber wählen'**
  String get choosespells;

  /// No description provided for @maximumspelllevel.
  ///
  /// In de, this message translates to:
  /// **'Maximales Zauberstufe'**
  String get maximumspelllevel;

  /// No description provided for @nospellsavailable.
  ///
  /// In de, this message translates to:
  /// **'Keine Zauber für diese Klasse und Stufe verfügbar.'**
  String get nospellsavailable;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get done;

  /// Used points
  ///
  /// In de, this message translates to:
  /// **'Verwendete Punkte: {used} / {pool}'**
  String usedpoints(Object used, Object pool);

  /// Rolled values
  ///
  /// In de, this message translates to:
  /// **'Gewürfelte Werte: {values}'**
  String rolledstats(Object values);

  /// No description provided for @notrolledyet.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht gewürfelt'**
  String get notrolledyet;

  /// No description provided for @exitConfirmationMessage.
  ///
  /// In de, this message translates to:
  /// **'Bist du sicher, dass du abbrechen möchtest? Dein Fortschritt geht verloren.'**
  String get exitConfirmationMessage;

  /// No description provided for @exitCharacterCreator.
  ///
  /// In de, this message translates to:
  /// **'Charaktererstellung beenden'**
  String get exitCharacterCreator;

  /// No description provided for @session.
  ///
  /// In de, this message translates to:
  /// **'Sitzung'**
  String get session;

  /// No description provided for @hostSession.
  ///
  /// In de, this message translates to:
  /// **'Sitzung hosten'**
  String get hostSession;

  /// No description provided for @joinedSession.
  ///
  /// In de, this message translates to:
  /// **'Beigetretene Sitzung'**
  String get joinedSession;

  /// No description provided for @sessionSettings.
  ///
  /// In de, this message translates to:
  /// **'Sitzungseinstellungen'**
  String get sessionSettings;

  /// No description provided for @showPlayerHP.
  ///
  /// In de, this message translates to:
  /// **'Spieler HP für Clients anzeigen'**
  String get showPlayerHP;

  /// No description provided for @showPlayerAC.
  ///
  /// In de, this message translates to:
  /// **'Spieler AC für Clients anzeigen'**
  String get showPlayerAC;

  /// No description provided for @unnamedSession.
  ///
  /// In de, this message translates to:
  /// **'Unbenannte Sitzung'**
  String get unnamedSession;

  /// No description provided for @hostingSessionMessage.
  ///
  /// In de, this message translates to:
  /// **'Hoste \"{sessionName}\"'**
  String hostingSessionMessage(Object sessionName);

  /// No description provided for @chooseCharacter.
  ///
  /// In de, this message translates to:
  /// **'Charakter wählen'**
  String get chooseCharacter;

  /// No description provided for @noCharactersFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Charaktere gefunden. Bitte erstelle zuerst einen.'**
  String get noCharactersFound;

  /// No description provided for @selectYourCharacter.
  ///
  /// In de, this message translates to:
  /// **'Wähle deinen Charakter'**
  String get selectYourCharacter;

  /// No description provided for @pleaseSelectCharacter.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle einen Charakter!'**
  String get pleaseSelectCharacter;

  /// No description provided for @join.
  ///
  /// In de, this message translates to:
  /// **'Beitreten'**
  String get join;

  /// No description provided for @enterSessionNameHint.
  ///
  /// In de, this message translates to:
  /// **'Sitzungsname eingeben...'**
  String get enterSessionNameHint;

  /// No description provided for @serverRunning.
  ///
  /// In de, this message translates to:
  /// **'Server läuft...'**
  String get serverRunning;

  /// No description provided for @startHosting.
  ///
  /// In de, this message translates to:
  /// **'Hosting starten'**
  String get startHosting;

  /// No description provided for @searchingForSessions.
  ///
  /// In de, this message translates to:
  /// **'Suche nach Sitzungen...'**
  String get searchingForSessions;

  /// No description provided for @unknownSession.
  ///
  /// In de, this message translates to:
  /// **'Unbekannte Sitzung'**
  String get unknownSession;

  /// No description provided for @hostGame.
  ///
  /// In de, this message translates to:
  /// **'Spiel hosten'**
  String get hostGame;

  /// No description provided for @joinGame.
  ///
  /// In de, this message translates to:
  /// **'Spiel beitreten'**
  String get joinGame;

  /// No description provided for @sessionLobby.
  ///
  /// In de, this message translates to:
  /// **'D&D Sitzungslobby'**
  String get sessionLobby;

  /// No description provided for @confirmStopHosting.
  ///
  /// In de, this message translates to:
  /// **'Hosting beenden bestätigen'**
  String get confirmStopHosting;

  /// No description provided for @stopHostingWarning.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du das Hosting dieser Sitzung wirklich beenden? Alle Spieler werden getrennt.'**
  String get stopHostingWarning;

  /// No description provided for @stopHosting.
  ///
  /// In de, this message translates to:
  /// **'Hosting beenden'**
  String get stopHosting;

  /// No description provided for @setInitiativeFor.
  ///
  /// In de, this message translates to:
  /// **'Initiative festlegen für {playerName}'**
  String setInitiativeFor(Object playerName);

  /// No description provided for @hostingSessionTitle.
  ///
  /// In de, this message translates to:
  /// **'Hosting: {sessionName}'**
  String hostingSessionTitle(Object sessionName);

  /// No description provided for @sessionInfo.
  ///
  /// In de, this message translates to:
  /// **'Sitzungsinformationen'**
  String get sessionInfo;

  /// No description provided for @connectedPlayers.
  ///
  /// In de, this message translates to:
  /// **'Verbundene Spieler:'**
  String get connectedPlayers;

  /// No description provided for @nextTurn.
  ///
  /// In de, this message translates to:
  /// **'Nächster Zug'**
  String get nextTurn;

  /// No description provided for @noPlayersConnected.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Spieler verbunden.'**
  String get noPlayersConnected;

  /// No description provided for @initiativeLabel.
  ///
  /// In de, this message translates to:
  /// **'Initiative: '**
  String get initiativeLabel;

  /// No description provided for @addMonsterNpc.
  ///
  /// In de, this message translates to:
  /// **'Monster/NPC hinzufügen'**
  String get addMonsterNpc;

  /// No description provided for @viewFullDetails.
  ///
  /// In de, this message translates to:
  /// **'Alle Details anzeigen'**
  String get viewFullDetails;

  /// No description provided for @editName.
  ///
  /// In de, this message translates to:
  /// **'Name bearbeiten'**
  String get editName;

  /// No description provided for @editHp.
  ///
  /// In de, this message translates to:
  /// **'HP bearbeiten'**
  String get editHp;

  /// No description provided for @editAc.
  ///
  /// In de, this message translates to:
  /// **'AC bearbeiten'**
  String get editAc;

  /// No description provided for @editNameFor.
  ///
  /// In de, this message translates to:
  /// **'Name bearbeiten für {name}'**
  String editNameFor(Object name);

  /// No description provided for @editHpFor.
  ///
  /// In de, this message translates to:
  /// **'HP bearbeiten für {name}'**
  String editHpFor(Object name);

  /// No description provided for @editAcFor.
  ///
  /// In de, this message translates to:
  /// **'AC bearbeiten für {name}'**
  String editAcFor(Object name);

  /// No description provided for @armorClass.
  ///
  /// In de, this message translates to:
  /// **'Rüstungsklasse'**
  String get armorClass;

  /// No description provided for @sessionTitle.
  ///
  /// In de, this message translates to:
  /// **'Sitzung: {sessionName}'**
  String sessionTitle(Object sessionName);

  /// No description provided for @loading.
  ///
  /// In de, this message translates to:
  /// **'Lädt...'**
  String get loading;

  /// No description provided for @quitSession.
  ///
  /// In de, this message translates to:
  /// **'Sitzung verlassen'**
  String get quitSession;

  /// No description provided for @playersAndInitiative.
  ///
  /// In de, this message translates to:
  /// **'Spieler & Initiative:'**
  String get playersAndInitiative;

  /// No description provided for @you.
  ///
  /// In de, this message translates to:
  /// **'Du'**
  String get you;

  /// No description provided for @monsterNpc.
  ///
  /// In de, this message translates to:
  /// **'Monster/NPC'**
  String get monsterNpc;

  /// No description provided for @player.
  ///
  /// In de, this message translates to:
  /// **'Spieler'**
  String get player;

  /// No description provided for @basicInfo.
  ///
  /// In de, this message translates to:
  /// **'Grundinformationen'**
  String get basicInfo;

  /// No description provided for @combatStats.
  ///
  /// In de, this message translates to:
  /// **'Kampfwerte'**
  String get combatStats;

  /// No description provided for @abilityScores.
  ///
  /// In de, this message translates to:
  /// **'Attributswerte'**
  String get abilityScores;

  /// No description provided for @otherStats.
  ///
  /// In de, this message translates to:
  /// **'Weitere Werte'**
  String get otherStats;

  /// No description provided for @str.
  ///
  /// In de, this message translates to:
  /// **'STÄ'**
  String get str;

  /// No description provided for @dex.
  ///
  /// In de, this message translates to:
  /// **'GES'**
  String get dex;

  /// No description provided for @con.
  ///
  /// In de, this message translates to:
  /// **'KON'**
  String get con;

  /// No description provided for @int.
  ///
  /// In de, this message translates to:
  /// **'INT'**
  String get int;

  /// No description provided for @wis.
  ///
  /// In de, this message translates to:
  /// **'WEI'**
  String get wis;

  /// No description provided for @cha.
  ///
  /// In de, this message translates to:
  /// **'CHA'**
  String get cha;

  /// No description provided for @savesOptional.
  ///
  /// In de, this message translates to:
  /// **'Rettungswürfe (optional)'**
  String get savesOptional;

  /// No description provided for @skillsOptional.
  ///
  /// In de, this message translates to:
  /// **'Fertigkeiten (optional)'**
  String get skillsOptional;

  /// No description provided for @resistancesOptional.
  ///
  /// In de, this message translates to:
  /// **'Resistenzen (optional)'**
  String get resistancesOptional;

  /// No description provided for @vulnerabilitiesOptional.
  ///
  /// In de, this message translates to:
  /// **'Anfälligkeiten (optional)'**
  String get vulnerabilitiesOptional;

  /// No description provided for @immunitiesOptional.
  ///
  /// In de, this message translates to:
  /// **'Immunitäten (optional)'**
  String get immunitiesOptional;

  /// No description provided for @conditionImmunitiesOptional.
  ///
  /// In de, this message translates to:
  /// **'Zustandsimmunitäten (optional)'**
  String get conditionImmunitiesOptional;

  /// No description provided for @sensesOptional.
  ///
  /// In de, this message translates to:
  /// **'Sinne (optional)'**
  String get sensesOptional;

  /// No description provided for @languagesOptional.
  ///
  /// In de, this message translates to:
  /// **'Sprachen (optional)'**
  String get languagesOptional;

  /// No description provided for @speed.
  ///
  /// In de, this message translates to:
  /// **'Bewegung'**
  String get speed;

  /// No description provided for @addMonster.
  ///
  /// In de, this message translates to:
  /// **'Monster hinzufügen'**
  String get addMonster;

  /// No description provided for @addRace.
  ///
  /// In de, this message translates to:
  /// **'Rasse hinzufügen'**
  String get addRace;

  /// No description provided for @addBackground.
  ///
  /// In de, this message translates to:
  /// **'Hintergrund hinzufügen'**
  String get addBackground;

  /// No description provided for @addClass.
  ///
  /// In de, this message translates to:
  /// **'Klasse hinzufügen'**
  String get addClass;

  /// No description provided for @addSpellWiki.
  ///
  /// In de, this message translates to:
  /// **'Zauber hinzufügen'**
  String get addSpellWiki;

  /// No description provided for @addTalent.
  ///
  /// In de, this message translates to:
  /// **'Talent hinzufügen'**
  String get addTalent;

  /// No description provided for @setHitPoints.
  ///
  /// In de, this message translates to:
  /// **'Trefferpunkte festlegen'**
  String get setHitPoints;

  /// No description provided for @hitPoints.
  ///
  /// In de, this message translates to:
  /// **'Trefferpunkte'**
  String get hitPoints;

  /// No description provided for @hpMethod.
  ///
  /// In de, this message translates to:
  /// **'TP-Methode'**
  String get hpMethod;

  /// No description provided for @rollHp.
  ///
  /// In de, this message translates to:
  /// **'Würfeln'**
  String get rollHp;

  /// No description provided for @medianHp.
  ///
  /// In de, this message translates to:
  /// **'Median'**
  String get medianHp;

  /// No description provided for @customHp.
  ///
  /// In de, this message translates to:
  /// **'Benutzerdefiniert'**
  String get customHp;

  /// No description provided for @hitDie.
  ///
  /// In de, this message translates to:
  /// **'Trefferwürfel'**
  String get hitDie;

  /// No description provided for @constitutionModifier.
  ///
  /// In de, this message translates to:
  /// **'Konstitutionsmodifikator'**
  String get constitutionModifier;

  /// No description provided for @reroll.
  ///
  /// In de, this message translates to:
  /// **'Neu würfeln'**
  String get reroll;

  /// TP für eine bestimmte Stufe
  ///
  /// In de, this message translates to:
  /// **'Stufe {level}: {hp} TP'**
  String levelHp(Object level, Object hp);

  /// No description provided for @maxLevel.
  ///
  /// In de, this message translates to:
  /// **'(Max)'**
  String get maxLevel;

  /// No description provided for @totalHp.
  ///
  /// In de, this message translates to:
  /// **'Gesamt-TP'**
  String get totalHp;

  /// Gesamt-TP Anzeige
  ///
  /// In de, this message translates to:
  /// **'Gesamt-TP: {hp}'**
  String totalHpValue(Object hp);

  /// No description provided for @pleaseSetValidHp.
  ///
  /// In de, this message translates to:
  /// **'Bitte gültige TP festlegen'**
  String get pleaseSetValidHp;

  /// TP Anzeige im Charakterersteller
  ///
  /// In de, this message translates to:
  /// **'TP: {hp}'**
  String hpDisplay(Object hp);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
