import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bm_typer/core/constants/app_colors.dart';

/// Service for managing app themes
class ThemeService {
  static const String _themePreferenceKey = 'theme_preference';
  static const String _themeColorPreferenceKey = 'theme_color_preference';

  /// Available theme modes
  static const List<ThemeMode> themeModes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  /// Available theme colors
  static const List<ThemeColor> themeColors = [
    ThemeColor.purple,
    ThemeColor.blue,
    ThemeColor.green,
    ThemeColor.amber,
    ThemeColor.red,
    ThemeColor.highContrast,
  ];

  /// Get the current theme mode from preferences
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePreferenceKey) ?? 0;
    return themeModes[themeIndex.clamp(0, themeModes.length - 1)];
  }

  /// Set the theme mode in preferences
  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = themeModes.indexOf(mode);
    await prefs.setInt(_themePreferenceKey, themeIndex);
  }

  /// Get the current theme color from preferences
  static Future<ThemeColor> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorIndex = prefs.getInt(_themeColorPreferenceKey) ?? 0;
    return themeColors[colorIndex.clamp(0, themeColors.length - 1)];
  }

  /// Set the theme color in preferences
  static Future<void> setThemeColor(ThemeColor color) async {
    final prefs = await SharedPreferences.getInstance();
    final colorIndex = themeColors.indexOf(color);
    await prefs.setInt(_themeColorPreferenceKey, colorIndex);
  }

  /// Get the display name for a theme mode
  static String getThemeModeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'Unknown';
    }
  }

  /// Get the display name for a theme color
  static String getThemeColorDisplayName(ThemeColor color) {
    switch (color) {
      case ThemeColor.purple:
        return 'Purple';
      case ThemeColor.blue:
        return 'Blue';
      case ThemeColor.green:
        return 'Green';
      case ThemeColor.amber:
        return 'Amber';
      case ThemeColor.red:
        return 'Red';
      case ThemeColor.highContrast:
        return 'High Contrast';
      default:
        return 'Unknown';
    }
  }

  /// Get the seed color for a theme color
  static Color getThemeColorSeed(ThemeColor color) {
    switch (color) {
      case ThemeColor.purple:
        return const Color(0xFF6D28D9); // Violet
      case ThemeColor.blue:
        return const Color(0xFF2563EB); // Blue
      case ThemeColor.green:
        return const Color(0xFF16A34A); // Green
      case ThemeColor.amber:
        return const Color(0xFFD97706); // Amber
      case ThemeColor.red:
        return const Color(0xFFDC2626); // Red
      case ThemeColor.highContrast:
        return const Color(0xFF000000); // Black (for high contrast)
      default:
        return const Color(0xFF6D28D9); // Default to violet
    }
  }
}

/// Available theme colors
enum ThemeColor {
  purple,
  blue,
  green,
  amber,
  red,
  highContrast,
}
