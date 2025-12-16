import 'dart:ui';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      _buildSectionTitle('অ্যাকসেসিবিলিটি বিকল্প', isDark),
                      const SizedBox(height: 12),
                      _buildTextSizeCard(context, colorScheme, isDark),
                      const SizedBox(height: 12),
                      _buildSwitchCard('হাই কনট্রাস্ট মোড', 'টেক্সট এবং ব্যাকগ্রাউন্ডের মধ্যে কনট্রাস্ট বাড়ায়', Icons.contrast_rounded, false, (v) {}, colorScheme, isDark),
                      const SizedBox(height: 12),
                      _buildSwitchCard('কম অ্যানিমেশন', 'অ্যানিমেশন এবং মোশন ইফেক্ট কমায়', Icons.animation_rounded, false, (v) {}, colorScheme, isDark),
                      const SizedBox(height: 24),
                      _buildSectionTitle('অডিও এবং স্পীচ', isDark),
                      const SizedBox(height: 12),
                      _buildNavigationCard(context, 'অডিও সেটিংস', 'সাউন্ড এফেক্ট এবং ভলিউম কন্ট্রোল', Icons.volume_up_rounded, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioSettingsScreen()));
                      }, colorScheme, isDark),
                      const SizedBox(height: 12),
                      _buildNavigationCard(context, 'টেক্সট টু স্পীচ', 'স্পীচ রেট, ভয়েস এবং ভাষা সেটিংস', Icons.record_voice_over_rounded, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TtsSettingsScreen()));
                      }, colorScheme, isDark),
                      const SizedBox(height: 24),
                      _buildSectionTitle('কীবোর্ড নেভিগেশন', isDark),
                      const SizedBox(height: 12),
                      _buildSwitchCard('কীবোর্ড নেভিগেশন', 'কীবোর্ড দিয়ে অ্যাপ নেভিগেট করুন', Icons.keyboard_rounded, true, (v) {}, colorScheme, isDark),
                      const SizedBox(height: 12),
                      _buildShortcutsCard(context, colorScheme, isDark),
                      const SizedBox(height: 24),
                      _buildSectionTitle('অন্যান্য সেটিংস', isDark),
                      const SizedBox(height: 12),
                      _buildScrollSpeedCard(context, colorScheme, isDark),
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
          Icon(Icons.accessibility_new_rounded, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            'অ্যাকসেসিবিলিটি সেটিংস',
            style: GoogleFonts.hindSiliguri(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(title, style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildGlassCard(bool isDark, Widget child) {
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

  Widget _buildTextSizeCard(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(isDark, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.text_fields_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text('টেক্সট সাইজ', style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ছোট', style: GoogleFonts.hindSiliguri(fontSize: 12, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
            Text('মাঝারি', style: GoogleFonts.hindSiliguri(fontSize: 14, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
            Text('বড়', style: GoogleFonts.hindSiliguri(fontSize: 16, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colorScheme.primary, inactiveTrackColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1), thumbColor: colorScheme.primary, trackHeight: 6),
          child: Slider(value: 1.0, min: 0.8, max: 1.2, divisions: 4, onChanged: (v) {}),
        ),
      ],
    ));
  }

  Widget _buildSwitchCard(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged, ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(isDark, Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              Text(subtitle, style: GoogleFonts.hindSiliguri(fontSize: 13, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6))),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: colorScheme.primary),
      ],
    ));
  }

  Widget _buildNavigationCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap, ColorScheme colorScheme, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassCard(isDark, Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                Text(subtitle, style: GoogleFonts.hindSiliguri(fontSize: 13, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6))),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 18, color: (isDark ? Colors.white : Colors.black).withOpacity(0.4)),
        ],
      )),
    );
  }

  Widget _buildShortcutsCard(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return GestureDetector(
      onTap: () => _showShortcutsDialog(context, colorScheme, isDark),
      child: _buildGlassCard(isDark, Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.keyboard_alt_outlined, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('কীবোর্ড শর্টকাট', style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                Text('সমস্ত কীবোর্ড শর্টকাট দেখুন', style: GoogleFonts.hindSiliguri(fontSize: 13, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6))),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 18, color: (isDark ? Colors.white : Colors.black).withOpacity(0.4)),
        ],
      )),
    );
  }

  Widget _buildScrollSpeedCard(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(isDark, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text('অটো-স্ক্রল স্পিড', style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ধীর', style: GoogleFonts.hindSiliguri(fontSize: 14, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
            Text('দ্রুত', style: GoogleFonts.hindSiliguri(fontSize: 14, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5))),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colorScheme.primary, inactiveTrackColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1), thumbColor: colorScheme.primary, trackHeight: 6),
          child: Slider(value: 0.5, min: 0.1, max: 1.0, divisions: 9, onChanged: (v) {}),
        ),
      ],
    ));
  }

  void _showShortcutsDialog(BuildContext context, ColorScheme colorScheme, bool isDark) {
    final shortcuts = [
      ['Tab', 'পরবর্তী আইটেমে যান'],
      ['Shift + Tab', 'আগের আইটেমে যান'],
      ['Space / Enter', 'আইটেম সিলেক্ট করুন'],
      ['Esc', 'ডায়ালগ বন্ধ করুন'],
      ['Alt + Left', 'পিছনে যান'],
      ['Ctrl + Home', 'হোম স্ক্রিনে যান'],
      ['Ctrl + P', 'প্রোফাইল দেখুন'],
      ['Ctrl + S', 'সেটিংস খুলুন'],
      ['Ctrl + A', 'অর্জন দেখুন'],
      ['Ctrl + L', 'লিডারবোর্ড দেখুন'],
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2a2a4e) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('কীবোর্ড শর্টকাট', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: shortcuts.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(s[0], style: GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(s[1], style: GoogleFonts.hindSiliguri(color: isDark ? Colors.white70 : Colors.black87))),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বন্ধ করুন', style: GoogleFonts.hindSiliguri(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
