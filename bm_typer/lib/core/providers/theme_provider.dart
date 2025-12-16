import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/services/theme_service.dart';
import 'package:bm_typer/core/theme/theme.dart';

/// Theme state containing both theme mode and color
class ThemeState {
  final ThemeMode themeMode;
  final ThemeColor themeColor;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.themeColor = ThemeColor.purple,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    ThemeColor? themeColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      themeColor: themeColor ?? this.themeColor,
    );
  }

  /// Get the seed color for the current theme color
  Color get seedColor => ThemeService.getThemeColorSeed(themeColor);

  /// Get the current brightness based on theme mode
  Brightness getBrightness(Brightness platformBrightness) {
    switch (themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
      default:
        return platformBrightness;
    }
  }

  /// Get light theme data - uses new AppTheme design system
  ThemeData getLightTheme() {
    return AppTheme.lightTheme(seedColor: seedColor);
  }

  /// Get dark theme data - uses new AppTheme design system
  ThemeData getDarkTheme() {
    return AppTheme.darkTheme(seedColor: seedColor);
  }
}

/// Theme notifier to manage theme state
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadThemePreferences();
  }

  /// Load theme preferences from storage
  Future<void> _loadThemePreferences() async {
    final themeMode = await ThemeService.getThemeMode();
    final themeColor = await ThemeService.getThemeColor();

    state = state.copyWith(
      themeMode: themeMode,
      themeColor: themeColor,
    );
  }

  /// Set theme mode and save to preferences
  Future<void> setThemeMode(ThemeMode mode) async {
    await ThemeService.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  /// Set theme color and save to preferences
  Future<void> setThemeColor(ThemeColor color) async {
    await ThemeService.setThemeColor(color);
    state = state.copyWith(themeColor: color);
  }

  /// Toggle between light and dark mode
  Future<void> toggleThemeMode() async {
    final newMode =
        state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
}

/// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
