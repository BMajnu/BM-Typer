import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/presentation/screens/theme_settings_screen.dart';
import 'package:bm_typer/presentation/screens/audio_settings_screen.dart';
import 'package:bm_typer/presentation/screens/tts_settings_screen.dart';
import 'package:bm_typer/presentation/screens/accessibility_settings_screen.dart';
import 'package:bm_typer/presentation/screens/reminder_settings_screen.dart';
import 'package:bm_typer/presentation/screens/leaderboard_screen.dart';
import 'package:bm_typer/presentation/screens/profile_screen.dart';
import 'package:bm_typer/presentation/screens/achievements_screen.dart';
import 'package:bm_typer/presentation/screens/achievements_screen.dart';
import 'package:bm_typer/presentation/screens/about_app_screen.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPanel extends ConsumerWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth > 600 ? 380.0 : screenWidth * 0.85;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        bottomLeft: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: panelWidth,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a1a2e).withOpacity(0.95) : Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildHeader(context, colorScheme, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('দ্রুত অ্যাকশন', isDark),
                      const SizedBox(height: 12),
                      _buildQuickActionsGrid(context, colorScheme, isDark),
                      const SizedBox(height: 24),
                      _buildSectionTitle('সেটিংস', isDark),
                      const SizedBox(height: 12),
                      _buildSettingsList(context, colorScheme, isDark),
                      const SizedBox(height: 24),
                      _buildSectionTitle('অন্যান্য', isDark),
                      const SizedBox(height: 12),
                      _buildOtherOptions(context, colorScheme, isDark),
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

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary.withOpacity(0.2), colorScheme.primary.withOpacity(0.05)],
        ),
        border: Border(bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.settings_rounded, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'সেটিংস ও দ্রুত অ্যাকশন',
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.hindSiliguri(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, ColorScheme colorScheme, bool isDark) {
    final actions = [
      {'icon': Icons.speed_rounded, 'label': 'স্পিড টেস্ট', 'color': Colors.orange, 'route': '/typing_test'},
      {'icon': Icons.leaderboard_rounded, 'label': 'লিডারবোর্ড', 'color': Colors.green, 'screen': const LeaderboardScreen()},
      {'icon': Icons.emoji_events_rounded, 'label': 'অ্যাচিভমেন্ট', 'color': Colors.amber, 'screen': const AchievementsScreen()},
      {'icon': Icons.person_rounded, 'label': 'প্রোফাইল', 'color': Colors.blue, 'screen': const ProfileScreen()},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionCard(
          context,
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          color: action['color'] as Color,
          onTap: () {
            Navigator.pop(context);
            if (action.containsKey('route')) {
              Navigator.pushNamed(context, action['route'] as String);
            } else if (action.containsKey('screen')) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => action['screen'] as Widget));
            }
          },
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildQuickActionCard(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, ColorScheme colorScheme, bool isDark) {
    final settings = [
      {'icon': Icons.palette_rounded, 'label': 'থিম সেটিংস', 'subtitle': 'রঙ এবং থিম কাস্টমাইজ করুন', 'screen': const ThemeSettingsScreen()},
      {'icon': Icons.volume_up_rounded, 'label': 'অডিও সেটিংস', 'subtitle': 'সাউন্ড এফেক্ট ও ভলিউম', 'screen': const AudioSettingsScreen()},
      {'icon': Icons.record_voice_over_rounded, 'label': 'টেক্সট টু স্পীচ', 'subtitle': 'ভয়েস ও ভাষা সেটিংস', 'screen': const TtsSettingsScreen()},
      {'icon': Icons.accessibility_new_rounded, 'label': 'অ্যাকসেসিবিলিটি', 'subtitle': 'ব্যবহার সহজতা সেটিংস', 'screen': const AccessibilitySettingsScreen()},
      {'icon': Icons.notifications_rounded, 'label': 'রিমাইন্ডার', 'subtitle': 'প্র্যাকটিস রিমাইন্ডার সেট করুন', 'screen': const ReminderSettingsScreen()},
    ];

    return Column(
      children: settings.map((setting) => _buildSettingItem(
        context,
        icon: setting['icon'] as IconData,
        label: setting['label'] as String,
        subtitle: setting['subtitle'] as String,
        screen: setting['screen'] as Widget,
        colorScheme: colorScheme,
        isDark: isDark,
      )).toList(),
    );
  }

  Widget _buildSettingItem(BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Widget screen,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherOptions(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        _buildOtherItem(
          context,
          icon: Icons.share_rounded,
          label: 'শেয়ার করুন',
          onTap: () {
            Navigator.pop(context);
            Share.share(
              'BM Typer - বাংলা টাইপিং শেখার সেরা অ্যাপ!\n\n'
              '🇧🇩 বিজয় ও ফনেটিক উভয় পদ্ধতিতে টাইপিং শিখুন\n'
              '⌨️ ইন্টারেক্টিভ লেসন ও অনুশীলন\n'
              '🏆 অ্যাচিভমেন্ট ও লিডারবোর্ড\n\n'
              'ডাউনলোড করুন: https://play.google.com/store/apps/details?id=com.techzoneit.bmtyper',
              subject: 'BM Typer - বাংলা টাইপিং টিউটর',
            );
          },
          colorScheme: colorScheme,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildOtherItem(
          context,
          icon: Icons.info_rounded,
          label: 'অ্যাপ সম্পর্কে',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppScreen()));
          },
          colorScheme: colorScheme,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildOtherItem(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the settings panel
void showSettingsPanel(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Settings Panel',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: const SettingsPanel(),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}
