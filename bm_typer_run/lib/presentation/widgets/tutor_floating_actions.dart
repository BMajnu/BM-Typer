import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/providers/theme_provider.dart';
import 'package:bm_typer/core/providers/language_provider.dart';
import 'package:bm_typer/presentation/screens/theme_settings_screen.dart';
import 'package:bm_typer/presentation/screens/audio_settings_screen.dart';
import 'package:bm_typer/presentation/screens/accessibility_settings_screen.dart';
import 'package:bm_typer/presentation/screens/achievements_screen.dart';
import 'package:bm_typer/presentation/screens/export_screen.dart';

/// A reusable floating action button column for the TutorScreen.
/// Contains buttons for theme, audio, accessibility, language, achievements,
/// export, and typing speed test.
class TutorFloatingActions extends ConsumerWidget {
  const TutorFloatingActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isDarkMode =
        themeState.getBrightness(MediaQuery.platformBrightnessOf(context)) ==
            Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Theme button
        _buildFloatingButton(
          context: context,
          heroTag: 'theme_btn',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
          ),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          tooltip: 'Theme Settings',
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return RotationTransition(
                turns: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              key: ValueKey<bool>(isDarkMode),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Audio button
        _buildFloatingButton(
          context: context,
          heroTag: 'audio_btn',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AudioSettingsScreen()),
          ),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          tooltip: 'Audio Settings',
          child: const Icon(Icons.volume_up),
        ),
        const SizedBox(height: 8),

        // Accessibility button
        _buildFloatingButton(
          context: context,
          heroTag: 'accessibility_btn',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AccessibilitySettingsScreen()),
          ),
          backgroundColor: colorScheme.tertiaryContainer,
          foregroundColor: colorScheme.onTertiaryContainer,
          tooltip: 'Accessibility Settings',
          child: const Icon(Icons.accessibility_new),
        ),
        const SizedBox(height: 8),

        // Language button
        _buildFloatingButton(
          context: context,
          heroTag: 'language_btn',
          onPressed: () => _showLanguageDialog(context, ref),
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          tooltip: ref.watch(translationProvider('select_language')),
          child: const Icon(Icons.language),
        ),
        const SizedBox(height: 8),

        // Achievements button
        _buildFloatingButton(
          context: context,
          heroTag: 'achievements_btn',
          onPressed: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => const AchievementsScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position: Tween(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeInOutCubic)).animate(animation),
                  child: child,
                );
              },
            ),
          ),
          backgroundColor: colorScheme.tertiaryContainer,
          foregroundColor: colorScheme.onTertiaryContainer,
          tooltip: 'Achievements',
          child: const Icon(Icons.emoji_events),
        ),
        const SizedBox(height: 8),

        // Export button
        _buildFloatingButton(
          context: context,
          heroTag: 'export_btn',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExportScreen()),
          ),
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          tooltip: 'Export & Share',
          child: const Icon(Icons.ios_share),
        ),
        const SizedBox(height: 8),

        // Speed test button
        _buildFloatingButton(
          context: context,
          heroTag: 'speedtest_btn',
          onPressed: () => Navigator.pushNamed(context, '/typing_test'),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          tooltip: 'Typing Speed Test',
          child: const Icon(Icons.speed),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFloatingButton({
    required BuildContext context,
    required String heroTag,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    required String tooltip,
    required Widget child,
  }) {
    return FloatingActionButton(
      heroTag: heroTag,
      mini: true,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      tooltip: tooltip,
      child: child,
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        final appLanguage = ref.watch(appLanguageProvider);
        return AlertDialog(
          title: Text(
            ref.watch(translationProvider('select_language')),
            style: TextStyle(color: colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLanguageOption(
                context: context,
                ref: ref,
                language: AppLanguage.bengali,
                currentLanguage: appLanguage,
                title: 'বাংলা',
              ),
              _buildLanguageOption(
                context: context,
                ref: ref,
                language: AppLanguage.english,
                currentLanguage: appLanguage,
                title: 'English',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required WidgetRef ref,
    required AppLanguage language,
    required AppLanguage currentLanguage,
    required String title,
  }) {
    return ListTile(
      title: Text(title),
      onTap: () {
        ref.read(appLanguageProvider.notifier).changeLanguage(language);
        Navigator.pop(context);
      },
      selected: currentLanguage == language,
      leading: Radio<AppLanguage>(
        value: language,
        groupValue: currentLanguage,
        onChanged: (value) {
          if (value != null) {
            ref.read(appLanguageProvider.notifier).changeLanguage(value);
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
