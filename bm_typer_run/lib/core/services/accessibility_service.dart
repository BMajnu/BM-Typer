import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // Accessibility settings
  bool _keyboardNavigationEnabled = true;
  bool _highContrastMode = false;
  bool _reducedMotion = false;
  double _textScaleFactor = 1.0;
  double _autoScrollSpeed = 0.5;

  // Keyboard shortcuts
  final Map<LogicalKeySet, String> _keyboardShortcuts = {
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH): 'home',
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP):
        'profile',
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
        'settings',
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
        'achievements',
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL):
        'leaderboard',
    LogicalKeySet(LogicalKeyboardKey.escape): 'back',
  };

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _keyboardNavigationEnabled =
          prefs.getBool('keyboard_navigation_enabled') ?? true;
      _highContrastMode = prefs.getBool('high_contrast_mode') ?? false;
      _reducedMotion = prefs.getBool('reduced_motion') ?? false;
      _textScaleFactor = prefs.getDouble('text_scale_factor') ?? 1.0;
      _autoScrollSpeed = prefs.getDouble('auto_scroll_speed') ?? 0.5;
    } catch (e) {
      debugPrint('Error loading accessibility settings: $e');
      // Use defaults
      _keyboardNavigationEnabled = true;
      _highContrastMode = false;
      _reducedMotion = false;
      _textScaleFactor = 1.0;
      _autoScrollSpeed = 0.5;
    }
  }

  Future<void> setKeyboardNavigationEnabled(bool enabled) async {
    _keyboardNavigationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keyboard_navigation_enabled', enabled);
  }

  Future<void> setHighContrastMode(bool enabled) async {
    _highContrastMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast_mode', enabled);
  }

  Future<void> setReducedMotion(bool enabled) async {
    _reducedMotion = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reduced_motion', enabled);
  }

  Future<void> setTextScaleFactor(double factor) async {
    _textScaleFactor = factor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_scale_factor', factor);
  }

  Future<void> setAutoScrollSpeed(double speed) async {
    _autoScrollSpeed = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('auto_scroll_speed', speed);
  }

  String? getActionForKeySet(KeyEvent event) {
    if (!_keyboardNavigationEnabled) return null;

    // Handle special cases for Tab and Shift+Tab for focus navigation
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          return 'previousFocus';
        } else {
          return 'nextFocus';
        }
      }

      // Check for registered shortcuts
      for (final entry in _keyboardShortcuts.entries) {
        final keySet = entry.key;
        final action = entry.value;

        bool match = true;
        for (final key in keySet.keys) {
          if (!HardwareKeyboard.instance.isLogicalKeyPressed(key)) {
            match = false;
            break;
          }
        }

        if (match) {
          return action;
        }
      }
    }

    return null;
  }

  // Helper method to get high contrast colors
  ColorScheme getHighContrastColorScheme(bool isDarkMode) {
    if (_highContrastMode) {
      // High contrast light theme
      if (!isDarkMode) {
        return const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF000080), // Navy
          onPrimary: Color(0xFFFFFFFF), // White
          primaryContainer: Color(0xFF000080), // Navy
          onPrimaryContainer: Color(0xFFFFFFFF), // White
          secondary: Color(0xFF800000), // Maroon
          onSecondary: Color(0xFFFFFFFF), // White
          secondaryContainer: Color(0xFF800000), // Maroon
          onSecondaryContainer: Color(0xFFFFFFFF), // White
          tertiary: Color(0xFF008000), // Green
          onTertiary: Color(0xFFFFFFFF), // White
          tertiaryContainer: Color(0xFF008000), // Green
          onTertiaryContainer: Color(0xFFFFFFFF), // White
          error: Color(0xFFFF0000), // Red
          onError: Color(0xFFFFFFFF), // White
          errorContainer: Color(0xFFFF0000), // Red
          onErrorContainer: Color(0xFFFFFFFF), // White
          background: Color(0xFFFFFFFF), // White
          onBackground: Color(0xFF000000), // Black
          surface: Color(0xFFFFFFFF), // White
          onSurface: Color(0xFF000000), // Black
          surfaceVariant: Color(0xFFEEEEEE), // Light Gray
          onSurfaceVariant: Color(0xFF000000), // Black
          outline: Color(0xFF000000), // Black
          outlineVariant: Color(0xFF444444), // Dark Gray
          shadow: Color(0xFF000000), // Black
          scrim: Color(0xFF000000), // Black
          inverseSurface: Color(0xFF000000), // Black
          onInverseSurface: Color(0xFFFFFFFF), // White
          inversePrimary: Color(0xFFADD8E6), // Light Blue
        );
      }
      // High contrast dark theme
      else {
        return const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFADD8E6), // Light Blue
          onPrimary: Color(0xFF000000), // Black
          primaryContainer: Color(0xFFADD8E6), // Light Blue
          onPrimaryContainer: Color(0xFF000000), // Black
          secondary: Color(0xFFFFAAAA), // Light Red
          onSecondary: Color(0xFF000000), // Black
          secondaryContainer: Color(0xFFFFAAAA), // Light Red
          onSecondaryContainer: Color(0xFF000000), // Black
          tertiary: Color(0xFFAAFFAA), // Light Green
          onTertiary: Color(0xFF000000), // Black
          tertiaryContainer: Color(0xFFAAFFAA), // Light Green
          onTertiaryContainer: Color(0xFF000000), // Black
          error: Color(0xFFFF6666), // Light Red
          onError: Color(0xFF000000), // Black
          errorContainer: Color(0xFFFF6666), // Light Red
          onErrorContainer: Color(0xFF000000), // Black
          background: Color(0xFF000000), // Black
          onBackground: Color(0xFFFFFFFF), // White
          surface: Color(0xFF000000), // Black
          onSurface: Color(0xFFFFFFFF), // White
          surfaceVariant: Color(0xFF333333), // Dark Gray
          onSurfaceVariant: Color(0xFFFFFFFF), // White
          outline: Color(0xFFFFFFFF), // White
          outlineVariant: Color(0xFFCCCCCC), // Light Gray
          shadow: Color(0xFF000000), // Black
          scrim: Color(0xFF000000), // Black
          inverseSurface: Color(0xFFFFFFFF), // White
          onInverseSurface: Color(0xFF000000), // Black
          inversePrimary: Color(0xFF000080), // Navy
        );
      }
    }

    // Return null to use the default theme
    return isDarkMode ? const ColorScheme.dark() : const ColorScheme.light();
  }

  // Getters
  bool get keyboardNavigationEnabled => _keyboardNavigationEnabled;
  bool get highContrastMode => _highContrastMode;
  bool get reducedMotion => _reducedMotion;
  double get textScaleFactor => _textScaleFactor;
  double get autoScrollSpeed => _autoScrollSpeed;

  // Animation duration based on reduced motion setting
  Duration getAnimationDuration(Duration defaultDuration) {
    if (_reducedMotion) {
      // Reduce animation duration or return zero to disable
      return const Duration(milliseconds: 100);
    }
    return defaultDuration;
  }
}
