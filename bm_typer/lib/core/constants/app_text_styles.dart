import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/constants/app_colors.dart';

class AppTextStyles {
  // Headings
  static TextStyle title = GoogleFonts.hindSiliguri(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryLegacy,
  );

  static TextStyle subtitle = GoogleFonts.hindSiliguri(
    fontSize: 16,
    color: AppColors.textSecondaryLegacy,
  );

  static TextStyle lessonTitle = GoogleFonts.hindSiliguri(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryLegacy,
  );

  static TextStyle lessonDescription = GoogleFonts.hindSiliguri(
    fontSize: 14,
    color: AppColors.textSecondaryLegacy,
  );

  // Exercise text
  static TextStyle exerciseText = GoogleFonts.robotoMono(
    fontSize: 24,
    color: AppColors.textPrimaryLegacy,
    height: 1.5,
  );

  static TextStyle get exerciseTextCorrect => exerciseText.copyWith(
        color: AppColors.correctLegacy,
      );

  static TextStyle get exerciseTextIncorrect => exerciseText.copyWith(
        color: AppColors.incorrectLegacy,
        backgroundColor: const Color(0xFFFECACA), // Light red background
      );

  static TextStyle get exerciseTextCurrent => exerciseText.copyWith(
        backgroundColor: AppColors.currentLegacy,
      );

  // Stats
  static TextStyle statValue = GoogleFonts.robotoMono(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryLegacy,
  );

  static TextStyle statLabel = GoogleFonts.hindSiliguri(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondaryLegacy,
  );

  // Keyboard
  static TextStyle keyText = GoogleFonts.robotoMono(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  // Buttons
  static TextStyle buttonText = GoogleFonts.hindSiliguri(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Caption and small text
  static TextStyle caption = GoogleFonts.hindSiliguri(
    fontSize: 12,
    color: AppColors.textSecondaryLegacy,
  );
}
