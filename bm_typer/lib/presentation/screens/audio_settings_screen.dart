import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/services/sound_service.dart';
import 'package:bm_typer/core/providers/sound_provider.dart';

class AudioSettingsScreen extends ConsumerStatefulWidget {
  const AudioSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends ConsumerState<AudioSettingsScreen> {
  late bool _isSoundEnabled;
  late double _volume;
  late KeyboardSoundTheme _selectedTheme;

  @override
  void initState() {
    super.initState();
    final soundService = ref.read(soundServiceProvider);
    _isSoundEnabled = soundService.isSoundEnabled;
    _volume = soundService.volume;
    _selectedTheme = soundService.currentTheme;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await soundService.initialize();
      setState(() {
        _isSoundEnabled = soundService.isSoundEnabled;
        _volume = soundService.volume;
        _selectedTheme = soundService.currentTheme;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      _buildSectionTitle('সাউন্ড সেটিংস', isDark),
                      const SizedBox(height: 12),
                      _buildSoundToggleCard(colorScheme, isDark),
                      const SizedBox(height: 12),
                      _buildVolumeCard(colorScheme, isDark),
                      const SizedBox(height: 24),
                      _buildSectionTitle('কীবোর্ড সাউন্ড থিম', isDark),
                      const SizedBox(height: 12),
                      _buildThemeOptionsCard(colorScheme, isDark),
                      const SizedBox(height: 24),
                      _buildSectionTitle('সাউন্ড টেস্ট', isDark),
                      const SizedBox(height: 12),
                      _buildSoundTestCard(colorScheme, isDark),
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
          Icon(Icons.volume_up_rounded, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            'অডিও সেটিংস',
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

  Widget _buildSoundToggleCard(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'সাউন্ড এনাবল করুন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'টাইপিং এবং নোটিফিকেশন সাউন্ড',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isSoundEnabled,
            onChanged: _updateSoundEnabled,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ভলিউম',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_volume * 100).round()}%',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: _volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: _isSoundEnabled ? _updateVolume : null,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.volume_mute_rounded, size: 18, color: (isDark ? Colors.white : Colors.black).withOpacity(0.4)),
              Icon(Icons.volume_up_rounded, size: 18, color: (isDark ? Colors.white : Colors.black).withOpacity(0.4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptionsCard(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        children: [
          _buildThemeOption('মেকানিকাল', 'মেকানিকাল কীবোর্ডের মত শব্দ', KeyboardSoundTheme.mechanical, Icons.keyboard_rounded, colorScheme, isDark),
          const SizedBox(height: 8),
          _buildThemeOption('সফট', 'হালকা এবং মৃদু টাইপিং শব্দ', KeyboardSoundTheme.soft, Icons.keyboard_alt_outlined, colorScheme, isDark),
          const SizedBox(height: 8),
          _buildThemeOption('টাইপরাইটার', 'ক্লাসিক টাইপরাইটারের মত শব্দ', KeyboardSoundTheme.typewriter, Icons.keyboard_hide_rounded, colorScheme, isDark),
          const SizedBox(height: 8),
          _buildThemeOption('কোন শব্দ নয়', 'টাইপিং এর সময় কোন শব্দ হবে না', KeyboardSoundTheme.none, Icons.volume_off_rounded, colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title, String description, KeyboardSoundTheme theme, IconData icon, ColorScheme colorScheme, bool isDark) {
    final isSelected = _selectedTheme == theme;
    
    return GestureDetector(
      onTap: _isSoundEnabled ? () => _updateSoundTheme(theme) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _isSoundEnabled
                          ? (isSelected ? colorScheme.primary : (isDark ? Colors.white : Colors.black87))
                          : (isDark ? Colors.white38 : Colors.black26),
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      color: _isSoundEnabled
                          ? (isDark ? Colors.white : Colors.black).withOpacity(0.5)
                          : (isDark ? Colors.white24 : Colors.black12),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundTestCard(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'সাউন্ড পরীক্ষা করুন',
            style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSoundTestButton('কী প্রেস', Icons.keyboard_rounded, SoundType.keyPress, colorScheme, isDark),
              _buildSoundTestButton('ভুল কী', Icons.error_outline_rounded, SoundType.keyError, colorScheme, isDark),
              _buildSoundTestButton('লেভেল সম্পন্ন', Icons.check_circle_outline_rounded, SoundType.levelComplete, colorScheme, isDark),
              _buildSoundTestButton('অর্জন', Icons.emoji_events_outlined, SoundType.achievement, colorScheme, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoundTestButton(String label, IconData icon, SoundType soundType, ColorScheme colorScheme, bool isDark) {
    return ElevatedButton.icon(
      onPressed: _isSoundEnabled ? () => ref.read(soundServiceProvider).playSound(soundType) : null,
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.hindSiliguri(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary.withOpacity(0.2),
        foregroundColor: colorScheme.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _updateSoundEnabled(bool value) async {
    setState(() => _isSoundEnabled = value);
    await ref.read(soundServiceProvider).setSoundEnabled(value);
    ref.read(soundEnabledProvider.notifier).state = value;
    if (value) ref.read(soundServiceProvider).playSound(SoundType.keyPress);
  }

  void _updateVolume(double value) async {
    setState(() => _volume = value);
    await ref.read(soundServiceProvider).setVolume(value);
    ref.read(soundVolumeProvider.notifier).state = value;
    if (_isSoundEnabled) ref.read(soundServiceProvider).playSound(SoundType.keyPress);
  }

  void _updateSoundTheme(KeyboardSoundTheme theme) async {
    setState(() => _selectedTheme = theme);
    await ref.read(soundServiceProvider).setKeyboardSoundTheme(theme);
    ref.read(soundThemeProvider.notifier).state = theme;
    if (_isSoundEnabled && theme != KeyboardSoundTheme.none) {
      ref.read(soundServiceProvider).playSound(SoundType.keyPress);
    }
  }
}
