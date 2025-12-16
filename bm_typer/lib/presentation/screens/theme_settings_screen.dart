import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/providers/theme_provider.dart';
import 'package:bm_typer/core/services/theme_service.dart';

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  String _selectedStyleType = 'Elevated';

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(isDark, colorScheme),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, colorScheme, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('থিম মোড', isDark),
                      const SizedBox(height: 12),
                      _buildThemeModeCard(themeState, colorScheme, isDark),
                      const SizedBox(height: 24),
                      _buildSectionTitle('থিম রঙ', isDark),
                      const SizedBox(height: 12),
                      _buildColorGrid(themeState, colorScheme, isDark),
                      const SizedBox(height: 24),
                      _buildSectionTitle('প্রিভিউ', isDark),
                      const SizedBox(height: 12),
                      _buildPreviewSection(colorScheme, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground(bool isDark, ColorScheme colorScheme) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f0f1a)]
            : [colorScheme.primaryContainer.withOpacity(0.3), colorScheme.surface, colorScheme.surface],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Icon(Icons.palette_rounded, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            'থিম সেটিংস',
            style: GoogleFonts.hindSiliguri(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: GoogleFonts.hindSiliguri(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildThemeModeCard(ThemeState themeState, ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        children: [
          _buildThemeModeOption('সিস্টেম', Icons.brightness_auto_rounded, themeState.themeMode == ThemeMode.system, colorScheme, isDark, () {
            ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
          }),
          const SizedBox(height: 8),
          _buildThemeModeOption('লাইট', Icons.light_mode_rounded, themeState.themeMode == ThemeMode.light, colorScheme, isDark, () {
            ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
          }),
          const SizedBox(height: 8),
          _buildThemeModeOption('ডার্ক', Icons.dark_mode_rounded, themeState.themeMode == ThemeMode.dark, colorScheme, isDark, () {
            ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
          }),
        ],
      ),
    );
  }

  Widget _buildThemeModeOption(String title, IconData icon, bool isSelected, ColorScheme colorScheme, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? colorScheme.primary : (isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.hindSiliguri(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colorScheme.primary : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildColorGrid(ThemeState themeState, ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: ThemeService.themeColors.map((themeColor) {
          final isSelected = themeState.themeColor == themeColor;
          final colorName = ThemeService.getThemeColorDisplayName(themeColor);
          final color = ThemeService.getThemeColorSeed(themeColor);

          return GestureDetector(
            onTap: () => ref.read(themeProvider.notifier).setThemeColor(themeColor),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    colorName,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11,
                      color: isSelected ? color : (isDark ? Colors.white70 : Colors.black54),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreviewSection(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'শিরোনাম',
            style: GoogleFonts.hindSiliguri(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'আপনার নির্বাচিত থিমের প্রিভিউ দেখুন।',
            style: GoogleFonts.hindSiliguri(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStyleButton('Elevated', _selectedStyleType == 'Elevated', () => setState(() => _selectedStyleType = 'Elevated'), colorScheme, isDark),
                const SizedBox(width: 8),
                _buildStyleButton('Filled', _selectedStyleType == 'Filled', () => setState(() => _selectedStyleType = 'Filled'), colorScheme, isDark),
                const SizedBox(width: 8),
                _buildStyleButton('Outlined', _selectedStyleType == 'Outlined', () => setState(() => _selectedStyleType = 'Outlined'), colorScheme, isDark),
                const SizedBox(width: 8),
                _buildStyleButton('Text', _selectedStyleType == 'Text', () => setState(() => _selectedStyleType = 'Text'), colorScheme, isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildColorPreviewBox('প্রাইমারি', colorScheme.primary, colorScheme.onPrimary),
          const SizedBox(height: 8),
          _buildColorPreviewBox('সেকেন্ডারি', colorScheme.secondary, colorScheme.onSecondary),
          const SizedBox(height: 8),
          _buildColorPreviewBox('টার্শিয়ারি', colorScheme.tertiary, colorScheme.onTertiary),
          const SizedBox(height: 20),
          Center(child: _getPreviewButton(colorScheme, _selectedStyleType)),
        ],
      ),
    );
  }

  Widget _buildStyleButton(String label, bool isSelected, VoidCallback onTap, ColorScheme colorScheme, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? colorScheme.primary : (isDark ? Colors.white : Colors.black).withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildColorPreviewBox(String label, Color color, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: GoogleFonts.hindSiliguri(color: textColor, fontWeight: FontWeight.bold)),
    );
  }

  Widget _getPreviewButton(ColorScheme colorScheme, String type) {
    switch (type) {
      case 'Elevated':
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: colorScheme.onPrimary,
            backgroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {},
          child: Text('Elevated Button', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        );
      case 'Filled':
        return FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {},
          child: Text('Filled Button', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        );
      case 'Outlined':
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {},
          child: Text('Outlined Button', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        );
      case 'Text':
        return TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {},
          child: Text('Text Button', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        );
      default:
        return ElevatedButton(onPressed: () {}, child: const Text('Button'));
    }
  }
}
