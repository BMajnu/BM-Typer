import 'package:flutter/material.dart';

/// আধুনিক কালার প্যালেট - BM Typer
/// 
/// এই ক্লাসে অ্যাপের সব কালার সেন্ট্রালাইজড আছে।
/// গ্লাসমরফিজম এবং গ্রেডিয়েন্ট সাপোর্ট সহ।
class AppColors {
  AppColors._(); // Private constructor

  // ============================================
  // PRIMARY COLORS - Deep Purple/Violet
  // ============================================
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF6D28D9);
  static const Color primarySurface = Color(0xFFF5F3FF);

  // ============================================
  // SECONDARY COLORS - Cyan/Teal
  // ============================================
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color secondaryDark = Color(0xFF0891B2);

  // ============================================
  // ACCENT COLORS - Warm Orange/Amber
  // ============================================
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);

  // ============================================
  // SEMANTIC COLORS
  // ============================================
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  static const Color successSurface = Color(0xFFECFDF5);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorSurface = Color(0xFFFEF2F2);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningSurface = Color(0xFFFFFBEB);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoSurface = Color(0xFFEFF6FF);

  // ============================================
  // NEUTRAL COLORS - Light Mode
  // ============================================
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE5E7EB);

  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color textDisabledLight = Color(0xFFD1D5DB);

  // ============================================
  // NEUTRAL COLORS - Dark Mode
  // ============================================
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF475569);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textTertiaryDark = Color(0xFF94A3B8);
  static const Color textDisabledDark = Color(0xFF64748B);

  // ============================================
  // GRADIENTS
  // ============================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary, secondaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent, accentDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successLight, success],
  );

  static const LinearGradient surfaceGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceLight, backgroundLight],
  );

  static const LinearGradient surfaceGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceDark, backgroundDark],
  );

  // ============================================
  // GLASSMORPHISM COLORS
  // ============================================
  static Color glassWhite = Colors.white.withOpacity(0.15);
  static Color glassBorder = Colors.white.withOpacity(0.2);
  static Color glassShadow = Colors.black.withOpacity(0.1);
  
  static Color glassWhiteDark = Colors.white.withOpacity(0.08);
  static Color glassBorderDark = Colors.white.withOpacity(0.1);
  static Color glassShadowDark = Colors.black.withOpacity(0.3);

  // ============================================
  // KEYBOARD SPECIFIC COLORS
  // ============================================
  static const Color keyDefault = Color(0xFFF3F4F6);
  static const Color keyPressed = Color(0xFFE5E7EB);
  static const Color keyHighlight = Color(0xFF7C3AED);
  static const Color keyHighlightText = Colors.white;
  static const Color keyText = Color(0xFF374151);
  static const Color keyTextSecondary = Color(0xFF9CA3AF);
  
  // Light mode keyboard colors
  static const Color keyHighlightLight = Color(0xFFDDD6FE);
  static const Color keyLeftHandLight = Color(0xFFEDE9FE);
  static const Color keyRightHandLight = Color(0xFFCFFAFE);
  static const Color keyNeutralLight = Color(0xFFF3F4F6);

  // Dark mode keyboard colors
  static const Color keyDefaultDark = Color(0xFF374151);
  static const Color keyPressedDark = Color(0xFF4B5563);
  static const Color keyHighlightDark = Color(0xFF8B5CF6);
  static const Color keyTextDark = Color(0xFFF9FAFB);
  static const Color keyTextSecondaryDark = Color(0xFF9CA3AF);
  static const Color keyLeftHandDark = Color(0xFF4C3A7C);
  static const Color keyRightHandDark = Color(0xFF134E4A);
  static const Color keyNeutralDark = Color(0xFF374151);


  // ============================================
  // TYPING AREA COLORS
  // ============================================
  static const Color typingCursor = Color(0xFF7C3AED);
  static const Color typingCorrect = Color(0xFF10B981);
  static const Color typingIncorrect = Color(0xFFEF4444);
  static const Color typingPending = Color(0xFF6B7280);
  static const Color typingCurrent = Color(0xFF7C3AED);

  // ============================================
  // XP & PROGRESS COLORS
  // ============================================
  static const Color xpGold = Color(0xFFFBBF24);
  static const Color xpBronze = Color(0xFFCD7F32);
  static const Color xpSilver = Color(0xFFC0C0C0);
  static const Color xpPlatinum = Color(0xFFE5E4E2);

  static const LinearGradient xpBarGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  // ============================================
  // LEVEL COLORS
  // ============================================
  static const List<Color> levelColors = [
    Color(0xFF94A3B8), // Level 1-5: Stone
    Color(0xFF22C55E), // Level 6-10: Emerald
    Color(0xFF3B82F6), // Level 11-15: Sapphire
    Color(0xFF8B5CF6), // Level 16-20: Amethyst
    Color(0xFFF59E0B), // Level 21-25: Gold
    Color(0xFFEC4899), // Level 26-30: Ruby
    Color(0xFF06B6D4), // Level 31+: Diamond
  ];

  /// Get level color based on level number
  static Color getLevelColor(int level) {
    if (level <= 5) return levelColors[0];
    if (level <= 10) return levelColors[1];
    if (level <= 15) return levelColors[2];
    if (level <= 20) return levelColors[3];
    if (level <= 25) return levelColors[4];
    if (level <= 30) return levelColors[5];
    return levelColors[6];
  }
}
