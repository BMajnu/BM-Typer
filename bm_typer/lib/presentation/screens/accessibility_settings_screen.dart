import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/services/accessibility_service.dart';
import 'package:bm_typer/presentation/screens/audio_settings_screen.dart';
import 'package:bm_typer/presentation/screens/tts_settings_screen.dart';

class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'অ্যাকসেসিবিলিটি সেটিংস',
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'অ্যাকসেসিবিলিটি বিকল্পসমূহ'),
            const SizedBox(height: 16),

            // Text size settings
            _buildSettingCard(
              context,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.text_fields),
                        const SizedBox(width: 12),
                        Text(
                          'টেক্সট সাইজ',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ছোট',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'মাঝারি',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'বড়',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: 1.0,
                      min: 0.8,
                      max: 1.2,
                      divisions: 4,
                      activeColor: colorScheme.primary,
                      inactiveColor: colorScheme.surfaceVariant,
                      onChanged: (value) {
                        // TODO: Implement text size scaling
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // High contrast mode
            _buildSettingCard(
              context,
              child: SwitchListTile(
                title: Text(
                  'হাই কনট্রাস্ট মোড',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'টেক্সট এবং ব্যাকগ্রাউন্ডের মধ্যে কনট্রাস্ট বাড়ায়',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                secondary: const Icon(Icons.contrast),
                value: false,
                activeColor: colorScheme.primary,
                onChanged: (value) {
                  // TODO: Implement high contrast mode
                },
              ),
            ),

            const SizedBox(height: 16),

            // Reduced motion
            _buildSettingCard(
              context,
              child: SwitchListTile(
                title: Text(
                  'কম অ্যানিমেশন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'অ্যানিমেশন এবং মোশন ইফেক্ট কমায়',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                secondary: const Icon(Icons.animation),
                value: false,
                activeColor: colorScheme.primary,
                onChanged: (value) {
                  // TODO: Implement reduced motion
                },
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(context, 'অডিও এবং স্পীচ'),
            const SizedBox(height: 16),

            // Audio settings
            _buildNavigationCard(
              context,
              title: 'অডিও সেটিংস',
              description: 'সাউন্ড এফেক্ট এবং ভলিউম কন্ট্রোল',
              icon: Icons.volume_up,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AudioSettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // TTS settings
            _buildNavigationCard(
              context,
              title: 'টেক্সট টু স্পীচ',
              description: 'স্পীচ রেট, ভয়েস এবং ভাষা সেটিংস',
              icon: Icons.record_voice_over,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TtsSettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(context, 'কীবোর্ড নেভিগেশন'),
            const SizedBox(height: 16),

            // Keyboard navigation
            _buildSettingCard(
              context,
              child: SwitchListTile(
                title: Text(
                  'কীবোর্ড নেভিগেশন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'কীবোর্ড দিয়ে অ্যাপ নেভিগেট করুন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                secondary: const Icon(Icons.keyboard),
                value: true,
                activeColor: colorScheme.primary,
                onChanged: (value) {
                  // TODO: Implement keyboard navigation
                },
              ),
            ),

            const SizedBox(height: 16),

            // Key shortcuts help
            _buildSettingCard(
              context,
              child: ListTile(
                title: Text(
                  'কীবোর্ড শর্টকাট',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'সমস্ত কীবোর্ড শর্টকাট দেখুন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                leading: const Icon(Icons.keyboard_alt_outlined),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showKeyboardShortcutsDialog(context);
                },
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(context, 'অন্যান্য সেটিংস'),
            const SizedBox(height: 16),

            // Auto-scroll speed
            _buildSettingCard(
              context,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed),
                        const SizedBox(width: 12),
                        Text(
                          'অটো-স্ক্রল স্পিড',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ধীর',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'দ্রুত',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: 0.5,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      activeColor: colorScheme.primary,
                      inactiveColor: colorScheme.surfaceVariant,
                      onChanged: (value) {
                        // TODO: Implement auto-scroll speed
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: GoogleFonts.hindSiliguri(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return _buildSettingCard(
      context,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKeyboardShortcutsDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'কীবোর্ড শর্টকাট',
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShortcutItem(
                context,
                shortcut: 'Tab',
                description: 'পরবর্তী আইটেমে যান',
              ),
              _buildShortcutItem(
                context,
                shortcut: 'Shift + Tab',
                description: 'আগের আইটেমে যান',
              ),
              _buildShortcutItem(
                context,
                shortcut: 'Space / Enter',
                description: 'আইটেম সিলেক্ট করুন',
              ),
              _buildShortcutItem(
                context,
                shortcut: 'Esc',
                description: 'ডায়ালগ বন্ধ করুন',
              ),
              _buildShortcutItem(
                context,
                shortcut: 'Alt + Left',
                description: 'পিছনে যান',
              ),
              _buildShortcutItem(
                context,
                shortcut: 'Ctrl + Home',
                description: 'হোম স্ক্রিনে যান',
              ),
              _buildShortcutItem(
                context,
                shortcut: 'Ctrl + P',
                description: 'প্রোফাইল দেখুন',
              ),
              _buildShortcutItem(
                context,
                shortcut: 'Ctrl + S',
                description: 'সেটিংস খুলুন',
              ),
              _buildShortcutItem(
                context,
                shortcut: 'Ctrl + A',
                description: 'অর্জন দেখুন',
              ),
              _buildShortcutItem(
                context,
                shortcut: 'Ctrl + L',
                description: 'লিডারবোর্ড দেখুন',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'বন্ধ করুন',
              style: GoogleFonts.hindSiliguri(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(
    BuildContext context, {
    required String shortcut,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
