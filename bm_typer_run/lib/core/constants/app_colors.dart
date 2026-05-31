import 'package:flutter/material.dart';

class AppColors {
  // Light theme colors
  static const Color primaryLight = Color(0xFF6D28D9); // Violet
  static const Color backgroundLight = Color(0xFFF0F4F8);
  static const Color surfaceLight = Color(0xFFFFFFFF); // White card background

  // Dark theme colors
  static const Color primaryDark = Color(0xFFA78BFA); // Light Violet
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E); // Dark card background

  // Typing colors - Light theme
  static const Color correctLight = Color(0xFF22C55E); // Green
  static const Color incorrectLight = Color(0xFFEF4444); // Red
  static const Color currentLight =
      Color(0xFFA5B4FC); // Light purple for current character

  // Typing colors - Dark theme
  static const Color correctDark = Color(0xFF4ADE80); // Brighter Green
  static const Color incorrectDark = Color(0xFFF87171); // Brighter Red
  static const Color currentDark =
      Color(0xFFBFDBFE); // Light blue for current character

  // Keyboard colors - Light theme
  static const Color leftHandKeyLight = Color(0xFFE9D5FF);
  static const Color rightHandKeyLight = Color(0xFFD9F99D);
  static const Color neutralKeyLight = Color(0xFFF1F5F9);
  static const Color keyBorderLight = Color(0x33000000); // 20% black

  // Keyboard colors - Dark theme
  static const Color leftHandKeyDark = Color(0xFF7E22CE);
  static const Color rightHandKeyDark = Color(0xFF65A30D);
  static const Color neutralKeyDark = Color(0xFF334155);
  static const Color keyBorderDark = Color(0x33FFFFFF); // 20% white

  // Text colors - Light theme
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Text colors - Dark theme
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);

  // Dynamic getters based on brightness
  static Color primary(Brightness brightness) =>
      brightness == Brightness.light ? primaryLight : primaryDark;
  static Color background(Brightness brightness) =>
      brightness == Brightness.light ? backgroundLight : backgroundDark;
  static Color surface(Brightness brightness) =>
      brightness == Brightness.light ? surfaceLight : surfaceDark;

  static Color correct(Brightness brightness) =>
      brightness == Brightness.light ? correctLight : correctDark;
  static Color incorrect(Brightness brightness) =>
      brightness == Brightness.light ? incorrectLight : incorrectDark;
  static Color current(Brightness brightness) =>
      brightness == Brightness.light ? currentLight : currentDark;

  static Color leftHandKey(Brightness brightness) =>
      brightness == Brightness.light ? leftHandKeyLight : leftHandKeyDark;
  static Color rightHandKey(Brightness brightness) =>
      brightness == Brightness.light ? rightHandKeyLight : rightHandKeyDark;
  static Color neutralKey(Brightness brightness) =>
      brightness == Brightness.light ? neutralKeyLight : neutralKeyDark;
  static Color keyBorder(Brightness brightness) =>
      brightness == Brightness.light ? keyBorderLight : keyBorderDark;

  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.light ? textPrimaryLight : textPrimaryDark;
  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.light ? textSecondaryLight : textSecondaryDark;

  // Legacy getters for backward compatibility
  @Deprecated('Use primary(brightness) instead')
  static const Color primaryLegacy = primaryLight;
  @Deprecated('Use background(brightness) instead')
  static const Color backgroundLegacy = backgroundLight;
  @Deprecated('Use surface(brightness) instead')
  static const Color surfaceLegacy = surfaceLight;
  @Deprecated('Use correct(brightness) instead')
  static const Color correctLegacy = correctLight;
  @Deprecated('Use incorrect(brightness) instead')
  static const Color incorrectLegacy = incorrectLight;
  @Deprecated('Use current(brightness) instead')
  static const Color currentLegacy = currentLight;
  @Deprecated('Use leftHandKey(brightness) instead')
  static const Color leftHandKeyLegacy = leftHandKeyLight;
  @Deprecated('Use rightHandKey(brightness) instead')
  static const Color rightHandKeyLegacy = rightHandKeyLight;
  @Deprecated('Use neutralKey(brightness) instead')
  static const Color neutralKeyLegacy = neutralKeyLight;
  @Deprecated('Use keyBorder(brightness) instead')
  static const Color keyBorderLegacy = keyBorderLight;
  @Deprecated('Use textPrimary(brightness) instead')
  static const Color textPrimaryLegacy = textPrimaryLight;
  @Deprecated('Use textSecondary(brightness) instead')
  static const Color textSecondaryLegacy = textSecondaryLight;
}
