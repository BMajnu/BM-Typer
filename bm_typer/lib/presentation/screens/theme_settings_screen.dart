import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/providers/theme_provider.dart';
import 'package:bm_typer/core/services/theme_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() =>
      _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  // Added to handle button style preview
  String _selectedStyleType = 'Elevated';

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final isDarkMode =
        themeState.getBrightness(MediaQuery.platformBrightnessOf(context)) ==
            Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Theme Settings',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Theme Mode'),
              const SizedBox(height: 8),
              _buildThemeModeOption(
                context,
                'System',
                Icons.brightness_auto,
                themeState.themeMode == ThemeMode.system,
                () {
                  ref
                      .read(themeProvider.notifier)
                      .setThemeMode(ThemeMode.system);
                },
              ),
              const SizedBox(height: 8),
              _buildThemeModeOption(
                context,
                'Light',
                Icons.light_mode,
                themeState.themeMode == ThemeMode.light,
                () {
                  ref
                      .read(themeProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                },
              ),
              const SizedBox(height: 8),
              _buildThemeModeOption(
                context,
                'Dark',
                Icons.dark_mode,
                themeState.themeMode == ThemeMode.dark,
                () {
                  ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Theme Color'),
              const SizedBox(height: 16),
              _buildColorGrid(context),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Preview'),
              const SizedBox(height: 16),
              _buildPreviewSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.notoSans(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildThemeModeOption(BuildContext context, String title,
      IconData icon, bool isSelected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.7),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: colorScheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildColorGrid(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 16,
      children: ThemeService.themeColors.map((themeColor) {
        final bool isSelected = themeState.themeColor == themeColor;
        final String colorName =
            ThemeService.getThemeColorDisplayName(themeColor);
        final Color color = ThemeService.getThemeColorSeed(themeColor);

        return GestureDetector(
          onTap: () {
            ref.read(themeProvider.notifier).setThemeColor(themeColor);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 70,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeColor == ThemeColor.highContrast
                            ? Colors.grey.withOpacity(0.3)
                            : color.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  colorName,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Heading',
          style: GoogleFonts.notoSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This is a preview of how your selected theme will look.',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        // Button style selector row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStyleButton('Elevated', _selectedStyleType == 'Elevated',
                  () => setState(() => _selectedStyleType = 'Elevated')),
              const SizedBox(width: 8),
              _buildStyleButton('Filled', _selectedStyleType == 'Filled',
                  () => setState(() => _selectedStyleType = 'Filled')),
              const SizedBox(width: 8),
              _buildStyleButton('Outlined', _selectedStyleType == 'Outlined',
                  () => setState(() => _selectedStyleType = 'Outlined')),
              const SizedBox(width: 8),
              _buildStyleButton('Text', _selectedStyleType == 'Text',
                  () => setState(() => _selectedStyleType = 'Text')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Color preview boxes
        _buildColorPreviewBox(
            'Primary', colorScheme.primary, colorScheme.onPrimary),
        const SizedBox(height: 8),
        _buildColorPreviewBox(
            'Secondary', colorScheme.secondary, colorScheme.onSecondary),
        const SizedBox(height: 8),
        _buildColorPreviewBox(
            'Tertiary', colorScheme.tertiary, colorScheme.onTertiary),
        const SizedBox(height: 8),
        _buildColorPreviewBox('Error', colorScheme.error, colorScheme.onError),
        const SizedBox(height: 24),
        // Button preview section
        Center(
          child: _getPreviewButton(context, _selectedStyleType),
        ),
      ],
    );
  }

  Widget _buildStyleButton(String label, bool isSelected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _getPreviewButton(BuildContext context, String type) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case 'Elevated':
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: colorScheme.onPrimary,
            backgroundColor: colorScheme.primary,
            elevation: 4,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {},
          child: const Text('Elevated Button', style: TextStyle(fontSize: 16)),
        );
      case 'Filled':
        return FilledButton(
          style: FilledButton.styleFrom(
            foregroundColor: colorScheme.onPrimary,
            backgroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {},
          child: const Text('Filled Button', style: TextStyle(fontSize: 16)),
        );
      case 'Outlined':
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {},
          child: const Text('Outlined Button', style: TextStyle(fontSize: 16)),
        );
      case 'Text':
        return TextButton(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {},
          child: const Text('Text Button', style: TextStyle(fontSize: 16)),
        );
      default:
        return ElevatedButton(
          onPressed: () {},
          child: const Text('Default Button'),
        );
    }
  }
}
