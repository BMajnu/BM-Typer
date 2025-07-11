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

  @override
  void initState() {
    super.initState();
    final ttsService = ref.read(ttsServiceProvider);
    _isTtsEnabled = ttsService.isTtsEnabled;
    _speechRate = ttsService.speechRate;
    _volume = ttsService.volume;
    _pitch = ttsService.pitch;
    _language = ttsService.language;

    // Initialize the TTS service and load available languages
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

        // Set test text based on language
        if (_language.startsWith('en')) {
          _testText = 'Can you hear this text being spoken?';
        } else {
          _testText = 'আপনি কি এই টেক্সট শুনতে পাচ্ছেন?';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'টেক্সট টু স্পীচ সেটিংস',
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
            _buildSectionTitle(context, 'টেক্সট টু স্পীচ সেটিংস'),
            const SizedBox(height: 16),

            // TTS enabled switch
            _buildSettingCard(
              context,
              child: SwitchListTile(
                title: Text(
                  'টেক্সট টু স্পীচ এনাবল করুন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'অ্যাপ্লিকেশন টেক্সট পড়ে শোনাবে',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _isTtsEnabled,
                activeColor: colorScheme.primary,
                onChanged: _updateTtsEnabled,
              ),
            ),

            const SizedBox(height: 16),

            // Language dropdown
            _buildSettingCard(
              context,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ভাষা',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _isTtsEnabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _language,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: _availableLanguages.map((language) {
                        String displayName = 'Unknown';
                        if (language.startsWith('en')) {
                          displayName = 'English';
                        } else if (language.startsWith('bn')) {
                          displayName = 'বাংলা';
                        } else if (language.startsWith('hi')) {
                          displayName = 'हिन्दी';
                        }
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: _isTtsEnabled
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _isTtsEnabled ? _updateLanguage : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Speech rate slider
            _buildSliderSetting(
              context,
              title: 'স্পীচ রেট',
              value: _speechRate,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              valueDisplay: '${(_speechRate * 100).round()}%',
              onChanged: _updateSpeechRate,
              startIcon: Icons.speed,
              endIcon: Icons.speed,
            ),

            const SizedBox(height: 16),

            // Volume slider
            _buildSliderSetting(
              context,
              title: 'ভলিউম',
              value: _volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              valueDisplay: '${(_volume * 100).round()}%',
              onChanged: _updateVolume,
              startIcon: Icons.volume_mute,
              endIcon: Icons.volume_up,
            ),

            const SizedBox(height: 16),

            // Pitch slider
            _buildSliderSetting(
              context,
              title: 'পিচ',
              value: _pitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              valueDisplay: _pitch.toStringAsFixed(1),
              onChanged: _updatePitch,
              startIcon: Icons.arrow_downward,
              endIcon: Icons.arrow_upward,
            ),

            const SizedBox(height: 24),

            // Test TTS button
            _buildSettingCard(
              context,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'টেক্সট টু স্পীচ পরীক্ষা করুন',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _isTtsEnabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: TextEditingController(text: _testText),
                      onChanged: (value) {
                        _testText = value;
                      },
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: _isTtsEnabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.5),
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintText: 'টেস্ট টেক্সট লিখুন',
                        hintStyle: GoogleFonts.hindSiliguri(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                      enabled: _isTtsEnabled,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isTtsEnabled
                              ? () =>
                                  ref.read(ttsServiceProvider).speak(_testText)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: Text(
                            'প্লে করুন',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isTtsEnabled
                              ? () => ref.read(ttsServiceProvider).stop()
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.surfaceVariant,
                            foregroundColor: colorScheme.onSurfaceVariant,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.stop, size: 18),
                          label: Text(
                            'স্টপ',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSliderSetting(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueDisplay,
    required Function(double) onChanged,
    required IconData startIcon,
    required IconData endIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return _buildSettingCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _isTtsEnabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  valueDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isTtsEnabled
                        ? colorScheme.primary
                        : colorScheme.primary.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.surfaceVariant,
            onChanged: _isTtsEnabled ? onChanged : null,
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  startIcon,
                  size: 20,
                  color: _isTtsEnabled
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                Icon(
                  endIcon,
                  size: 20,
                  color: _isTtsEnabled
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateTtsEnabled(bool value) async {
    setState(() {
      _isTtsEnabled = value;
    });

    await ref.read(ttsServiceProvider).setTtsEnabled(value);
    ref.read(ttsEnabledProvider.notifier).state = value;

    // Speak a test message if enabled
    if (value) {
      ref.read(ttsServiceProvider).speak(_testText);
    }
  }

  void _updateSpeechRate(double value) async {
    setState(() {
      _speechRate = value;
    });

    await ref.read(ttsServiceProvider).setSpeechRate(value);
    ref.read(ttsSpeechRateProvider.notifier).state = value;
  }

  void _updateVolume(double value) async {
    setState(() {
      _volume = value;
    });

    await ref.read(ttsServiceProvider).setVolume(value);
    ref.read(ttsVolumeProvider.notifier).state = value;
  }

  void _updatePitch(double value) async {
    setState(() {
      _pitch = value;
    });

    await ref.read(ttsServiceProvider).setPitch(value);
    ref.read(ttsPitchProvider.notifier).state = value;
  }

  void _updateLanguage(String? value) async {
    if (value == null) return;

    setState(() {
      _language = value;
      // Update test text based on language
      if (_language.startsWith('en')) {
        _testText = 'Can you hear this text being spoken?';
      } else {
        _testText = 'আপনি কি এই টেক্সট শুনতে পাচ্ছেন?';
      }
    });

    await ref.read(ttsServiceProvider).setLanguage(value);
    ref.read(ttsLanguageProvider.notifier).state = value;
  }
}
