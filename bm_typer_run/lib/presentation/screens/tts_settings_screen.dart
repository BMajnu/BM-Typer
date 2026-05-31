import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/services/tts_service.dart';
import 'package:bm_typer/core/providers/tts_provider.dart';

class TtsSettingsScreen extends ConsumerStatefulWidget {
  const TtsSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TtsSettingsScreen> createState() => _TtsSettingsScreenState();
}

class _TtsSettingsScreenState extends ConsumerState<TtsSettingsScreen> {
  late bool _isTtsEnabled;
  late double _speechRate;
  late double _volume;
  late double _pitch;
  late String _language;
  List<String> _availableLanguages = ['en-US', 'bn-BD'];
  String _testText = 'আপনি কি এই টেক্সট শুনতে পাচ্ছেন?';
  final TextEditingController _testTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final ttsService = ref.read(ttsServiceProvider);
    _isTtsEnabled = ttsService.isTtsEnabled;
    _speechRate = ttsService.speechRate;
    _volume = ttsService.volume;
    _pitch = ttsService.pitch;
    _language = ttsService.language;
    _testTextController.text = _testText;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ttsService.initialize();
      final languages = await ttsService.getAvailableLanguages();
      setState(() {
        _isTtsEnabled = ttsService.isTtsEnabled;
        _speechRate = ttsService.speechRate;
        _volume = ttsService.volume;
        _pitch = ttsService.pitch;
        _language = ttsService.language;
        _availableLanguages = languages;
        _testText = _language.startsWith('en') ? 'Can you hear this text being spoken?' : 'আপনি কি এই টেক্সট শুনতে পাচ্ছেন?';
        _testTextController.text = _testText;
      });
    });
  }

  @override
  void dispose() {
    _testTextController.dispose();
    super.dispose();
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
                      _buildSectionTitle('টেক্সট টু স্পীচ', isDark),
                      const SizedBox(height: 12),
                      _buildTtsToggleCard(colorScheme, isDark),
                      const SizedBox(height: 12),
                      _buildLanguageCard(colorScheme, isDark),
                      const SizedBox(height: 12),
                      _buildSliderCard('স্পীচ রেট', _speechRate, 0.0, 1.0, Icons.speed_rounded, (v) => _updateSpeechRate(v), colorScheme, isDark),
                      const SizedBox(height: 12),
                      _buildSliderCard('ভলিউম', _volume, 0.0, 1.0, Icons.volume_up_rounded, (v) => _updateVolume(v), colorScheme, isDark),
                      const SizedBox(height: 12),
                      _buildSliderCard('পিচ', _pitch, 0.5, 2.0, Icons.graphic_eq_rounded, (v) => _updatePitch(v), colorScheme, isDark),
                      const SizedBox(height: 24),
                      _buildSectionTitle('টেস্ট করুন', isDark),
                      const SizedBox(height: 12),
                      _buildTestCard(colorScheme, isDark),
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
          Icon(Icons.record_voice_over_rounded, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            'টেক্সট টু স্পীচ সেটিংস',
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

  Widget _buildTtsToggleCard(ColorScheme colorScheme, bool isDark) {
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
              _isTtsEnabled ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'টেক্সট টু স্পীচ এনাবল',
                  style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                ),
                Text(
                  'অ্যাপ্লিকেশন টেক্সট পড়ে শোনাবে',
                  style: GoogleFonts.hindSiliguri(fontSize: 13, color: (isDark ? Colors.white : Colors.black).withOpacity(0.6)),
                ),
              ],
            ),
          ),
          Switch(value: _isTtsEnabled, onChanged: _updateTtsEnabled, activeColor: colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ভাষা', style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w600, color: _isTtsEnabled ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white38 : Colors.black26))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _language,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF2a2a4e) : Colors.white,
                items: _availableLanguages.map((lang) {
                  String name = lang.startsWith('en') ? 'English' : lang.startsWith('bn') ? 'বাংলা' : lang.startsWith('hi') ? 'हिन्दी' : lang;
                  return DropdownMenuItem(value: lang, child: Text(name, style: GoogleFonts.hindSiliguri(color: isDark ? Colors.white : Colors.black87)));
                }).toList(),
                onChanged: _isTtsEnabled ? _updateLanguage : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard(String title, double value, double min, double max, IconData icon, Function(double) onChanged, ColorScheme colorScheme, bool isDark) {
    final displayValue = max == 2.0 ? value.toStringAsFixed(1) : '${(value * 100).round()}%';
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(title, style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w600, color: _isTtsEnabled ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white38 : Colors.black26))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(displayValue, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(value: value, min: min, max: max, divisions: max == 2.0 ? 15 : 10, onChanged: _isTtsEnabled ? onChanged : null),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(ColorScheme colorScheme, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('টেক্সট টু স্পীচ পরীক্ষা করুন', style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.w600, color: _isTtsEnabled ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white38 : Colors.black26))),
          const SizedBox(height: 12),
          TextField(
            controller: _testTextController,
            enabled: _isTtsEnabled,
            maxLines: 3,
            style: GoogleFonts.hindSiliguri(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'টেস্ট টেক্সট লিখুন',
              hintStyle: GoogleFonts.hindSiliguri(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
              filled: true,
              fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isTtsEnabled ? () => ref.read(ttsServiceProvider).speak(_testTextController.text) : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('প্লে করুন', style: GoogleFonts.hindSiliguri()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTtsEnabled ? () => ref.read(ttsServiceProvider).stop() : null,
                  icon: const Icon(Icons.stop_rounded),
                  label: Text('স্টপ', style: GoogleFonts.hindSiliguri()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateTtsEnabled(bool value) async {
    setState(() => _isTtsEnabled = value);
    await ref.read(ttsServiceProvider).setTtsEnabled(value);
    ref.read(ttsEnabledProvider.notifier).state = value;
    if (value) ref.read(ttsServiceProvider).speak(_testTextController.text);
  }

  void _updateSpeechRate(double value) async {
    setState(() => _speechRate = value);
    await ref.read(ttsServiceProvider).setSpeechRate(value);
    ref.read(ttsSpeechRateProvider.notifier).state = value;
  }

  void _updateVolume(double value) async {
    setState(() => _volume = value);
    await ref.read(ttsServiceProvider).setVolume(value);
    ref.read(ttsVolumeProvider.notifier).state = value;
  }

  void _updatePitch(double value) async {
    setState(() => _pitch = value);
    await ref.read(ttsServiceProvider).setPitch(value);
    ref.read(ttsPitchProvider.notifier).state = value;
  }

  void _updateLanguage(String? value) async {
    if (value == null) return;
    setState(() {
      _language = value;
      _testText = value.startsWith('en') ? 'Can you hear this text being spoken?' : 'আপনি কি এই টেক্সট শুনতে পাচ্ছেন?';
      _testTextController.text = _testText;
    });
    await ref.read(ttsServiceProvider).setLanguage(value);
    ref.read(ttsLanguageProvider.notifier).state = value;
  }
}
