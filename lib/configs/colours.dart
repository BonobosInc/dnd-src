import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static bool isDarkMode = true;

  static Future<void> loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('isDarkMode') ?? true;
  }

  static Future<void> saveThemePreference(bool darkMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', darkMode);
  }

  // Anthracite dark mode with vibrant accent colors
  static Color get primaryColor =>
      isDarkMode ? const Color(0xFF0F1722) : const Color(0xFFF2F2F2);  // Deep anthracite with cool tint
  static Color get appBarColor =>
      isDarkMode ? const Color(0xFF17202A) : const Color(0xFFE0E0E0);  // Slight blue-teal tint
  static Color get cardColor =>
      isDarkMode ? const Color(0xFF1E2732) : const Color(0xFFF5F5F5);  // Muted slate for surfaces
  static Color get borderColor =>
      isDarkMode ? const Color(0xFF32424E) : const Color(0xFFBDBDBD);  // Subtle desaturated teal border
  static Color get dividerColor =>
      isDarkMode ? const Color(0xFF2B3A44) : const Color(0xFFB0B0B0);  // Cool-toned divider
  static Color get textColorLight =>
      isDarkMode ? const Color(0xFFEEEEEE) : const Color(0xFF212121);  // Crisp white
  static Color get textColorDark =>
      isDarkMode ? const Color(0xFFB7C0C7) : const Color(0xFF424242);  // Cooler soft gray
  static Color get warningColor =>
      isDarkMode ? const Color(0xFFFF5252) : const Color(0xFFB71C1C);  // Bright red accent
  static Color get missingHealth => isDarkMode
      ? const Color(0xFFD32F2F)  // Vibrant red for damage
      : const Color(0xFF8B3C2B);
  static Color get currentHealth =>
      isDarkMode ? const Color(0xFF00C853) : const Color(0xFF2E8B57);  // Bright green for health
  static Color get tempHealth =>
      isDarkMode ? const Color(0xFF2196F3) : const Color(0xFF1976D2);  // Bright blue for temp HP

  // Dialog / modal colors (keep accents unchanged)
  static Color get dialogBackground =>
      isDarkMode ? const Color(0xFF142531) : const Color(0xFFFFFFFF); // Cool-tinted dark dialog bg
  static Color get dialogTitleText =>
      isDarkMode ? const Color(0xFFEDF6FB) : const Color(0xFF212121); // Slightly bluish white
  static Color get dialogContentText =>
      isDarkMode ? const Color(0xFFB7C0C7) : const Color(0xFF424242); // Cooler soft gray
  static Color get dialogButtonText =>
      isDarkMode ? accentCyan : const Color(0xFF1976D2); // Use existing cyan accent in dark mode

  // Additional accent colors for UI elements
  static Color get accentPurple =>
      isDarkMode ? const Color(0xFFAB47BC) : const Color(0xFF8E24AA);  // Purple accent
  static Color get accentOrange =>
      isDarkMode ? const Color(0xFFFF9800) : const Color(0xFFF57C00);  // Orange accent
  static Color get accentTeal =>
      isDarkMode ? const Color(0xFF26A69A) : const Color(0xFF00897B);  // Teal accent
  static Color get accentYellow =>
      isDarkMode ? const Color(0xFFFFEB3B) : const Color(0xFFFBC02D);  // Yellow accent
  static Color get accentPink =>
      isDarkMode ? const Color(0xFFEC407A) : const Color(0xFFD81B60);  // Pink accent
  static Color get accentCyan =>
      isDarkMode ? const Color(0xFF00BCD4) : const Color(0xFF0097A7);  // Cyan accent

  // Session specific colors
  static Color get sessionHost =>
      isDarkMode ? const Color(0xFF9575CD) : const Color(0xFF8E24AA);  // Muted purple for host
  static Color get sessionJoin =>
      isDarkMode ? const Color(0xFF4C9A92) : const Color(0xFF0097A7);  // Dark muted teal for join

  static void toggleTheme(bool darkMode) async {
    isDarkMode = darkMode;
    await saveThemePreference(darkMode);
  }
}
