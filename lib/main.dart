import 'dart:io';
import 'package:dnd/classes/wiki_parser.dart';
import 'package:dnd/configs/auto_updater.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'views/profile_home_screen.dart';
import 'configs/colours.dart';
import 'package:flutter/services.dart';
import 'package:window_size/window_size.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

ValueNotifier<bool> isDarkMode = ValueNotifier(true);
ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('de'));
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await cleanupPendingApk();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('BonoDND');
    setWindowMinSize(const Size(400, 700));
  }

  await AppColors.loadThemePreference();
  isDarkMode.value = AppColors.isDarkMode;

  await _loadSavedLocale();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  WikiParser wikiParser = WikiParser();
  await wikiParser.loadXml();

  runApp(DNDApp(wikiParser: wikiParser));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = navigatorKey.currentContext!;
    final deviceType = getDeviceType(context);
    if (deviceType == 'phone') {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    checkForUpdate(context);
  });
}

Future<void> _loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final langCode = prefs.getString('locale') ?? 'de';
  appLocale.value = Locale(langCode);
}

Future<void> saveLocale(Locale locale) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('locale', locale.languageCode);
}

String getDeviceType(BuildContext context) {
  final data = MediaQuery.of(context);
  return data.size.shortestSide < 600 ? 'phone' : 'tablet';
}

class DNDApp extends StatelessWidget {
  final WikiParser wikiParser;

  const DNDApp({super.key, required this.wikiParser});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, isDark, child) {
        AppColors.toggleTheme(isDark);

        return ValueListenableBuilder<Locale>(
          valueListenable: appLocale,
          builder: (context, locale, _) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'DND App',
              locale: locale,
              theme: ThemeData(
                brightness: isDark ? Brightness.dark : Brightness.light,
                primaryColor: AppColors.primaryColor,
                scaffoldBackgroundColor: AppColors.primaryColor,
                appBarTheme: AppBarTheme(
                  backgroundColor: AppColors.appBarColor,
                ),
                splashColor: Colors.transparent,
                cardColor: AppColors.cardColor,
                dividerColor: AppColors.dividerColor,
                textTheme: TextTheme(
                  bodyLarge: TextStyle(color: AppColors.textColorLight),
                  bodyMedium: TextStyle(color: AppColors.textColorDark),
                  displayLarge:
                    TextStyle(color: AppColors.textColorLight, fontSize: 20),
                  titleLarge:
                    TextStyle(color: AppColors.dialogTitleText, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                dialogTheme: DialogThemeData(
                  backgroundColor: AppColors.dialogBackground,
                  titleTextStyle: TextStyle(
                      color: AppColors.dialogTitleText,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                  contentTextStyle:
                      TextStyle(color: AppColors.dialogContentText),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.dialogButtonText,
                  ),
                ),
              ),
              home: ProfileHomeScreen(wikiParser: wikiParser),
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('de'),
                Locale('en'),
              ],
            );
          },
        );
      },
    );
  }
}
