import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// টাইপোগ্রাফি সিস্টেম - BM Typer
/// 
/// বাংলা ও ইংরেজি ফন্টের জন্য সেন্ট্রালাইজড টাইপোগ্রাফি।
class AppTypography {
  AppTypography._();

  // ============================================
  // FONT FAMILIES
  // ============================================
  
  /// Primary font for English text
  static String get primaryFontFamily => GoogleFonts.inter().fontFamily!;
  
  /// Font for Bangla text - uses Noto Sans Bengali
  static String get bangleFontFamily => GoogleFonts.notoSansBengali().fontFamily!;
  
  /// Monospace font for typing area
  static String get monospaceFontFamily => GoogleFonts.jetBrainsMono().fontFamily!;

  // ============================================
  // DISPLAY TEXT STYLES (Hero Text)
  // ============================================
  
  static TextStyle displayLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle displayMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle displaySmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ============================================
  // HEADLINE TEXT STYLES
  // ============================================
  
  static TextStyle headlineLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle headlineMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle headlineSmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ============================================
  // TITLE TEXT STYLES
  // ============================================
  
  static TextStyle titleLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle titleMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle titleSmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ============================================
  // BODY TEXT STYLES
  // ============================================
  
  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  // ============================================
  // LABEL TEXT STYLES
  // ============================================
  
  static TextStyle labelLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle labelMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  static TextStyle labelSmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  // ============================================
  // BANGLA SPECIFIC TEXT STYLES
  // ============================================
  
  /// Large Bangla text for typing display
  static TextStyle banglaDisplay(BuildContext context) => GoogleFonts.notoSansBengali(
    fontSize: 48,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Bangla text for typing area
  static TextStyle banglaTyping(BuildContext context) => GoogleFonts.notoSansBengali(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 1,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Bangla body text
  static TextStyle banglaBody(BuildContext context) => GoogleFonts.notoSansBengali(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Bangla title
  static TextStyle banglaTitle(BuildContext context) => GoogleFonts.notoSansBengali(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: Theme.of(context).colorScheme.onSurface,
  );

  // ============================================
  // KEYBOARD SPECIFIC TEXT STYLES
  // ============================================
  
  /// Primary key label (large character)
  static TextStyle keyLabelPrimary(BuildContext context) => GoogleFonts.notoSansBengali(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Secondary key label (small hint)
  static TextStyle keyLabelSecondary(BuildContext context) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  // ============================================
  // STATS & NUMBERS
  // ============================================
  
  /// Large number display (WPM, accuracy)
  static TextStyle statNumber(BuildContext context) => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Theme.of(context).colorScheme.primary,
  );

  /// Stat label
  static TextStyle statLabel(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// XP/Level number
  static TextStyle xpNumber(BuildContext context) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: const Color(0xFFF59E0B), // Gold
  );

  // ============================================
  // MONOSPACE (for code-like display)
  // ============================================
  
  static TextStyle monospace(BuildContext context) => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: Theme.of(context).colorScheme.onSurface,
  );
}
