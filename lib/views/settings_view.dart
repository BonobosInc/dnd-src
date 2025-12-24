import 'package:flutter/material.dart';
import 'package:dnd/main.dart';
import 'package:dnd/l10n/app_localizations.dart';
import 'package:dnd/configs/colours.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.darkMode,
                  style: const TextStyle(fontSize: 18.0),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: isDarkMode,
                  builder: (context, value, child) {
                    return Switch(
                      value: value,
                      onChanged: (bool newValue) {
                        isDarkMode.value = newValue;
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.language,
                  style: const TextStyle(fontSize: 18.0),
                ),
                ValueListenableBuilder<Locale>(
                  valueListenable: appLocale,
                  builder: (context, value, child) {
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<Locale>(
                        value: value,
                        borderRadius: BorderRadius.circular(12),
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textColorLight),
                        style: TextStyle(
                          color: AppColors.textColorLight,
                          fontSize: 16,
                        ),
                        dropdownColor: AppColors.cardColor,
                        items: const [
                          DropdownMenuItem(
                            value: Locale('en'),
                            child: Text("English"),
                          ),
                          DropdownMenuItem(
                            value: Locale('de'),
                            child: Text("Deutsch"),
                          ),
                        ],
                        onChanged: (Locale? newLocale) async {
                          if (newLocale != null) {
                            appLocale.value = newLocale;
                            await saveLocale(newLocale);
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
