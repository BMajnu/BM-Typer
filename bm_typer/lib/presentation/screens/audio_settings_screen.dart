import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/services/sound_service.dart';
import 'package:bm_typer/core/providers/sound_provider.dart';

class AudioSettingsScreen extends ConsumerStatefulWidget {
  const AudioSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AudioSettingsScreen> createState() =>
      _AudioSettingsScreenState();
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

    // Initialize the sound service
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'অডিও সেটিংস',
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
            _buildSectionTitle(context, 'সাউন্ড সেটিংস'),
            const SizedBox(height: 16),

            // Sound enabled switch
            _buildSettingCard(
              context,
              child: SwitchListTile(
                title: Text(
                  'সাউন্ড এনাবল করুন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'টাইপিং এবং নোটিফিকেশন সাউন্ড',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _isSoundEnabled,
                activeColor: colorScheme.primary,
                onChanged: _updateSoundEnabled,
              ),
            ),

            const SizedBox(height: 16),

            // Volume slider
            _buildSettingCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16.0, top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ভলিউম',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(_volume * 100).round()}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Slider(
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    activeColor: colorScheme.primary,
                    inactiveColor: colorScheme.surfaceVariant,
                    onChanged: _isSoundEnabled ? _updateVolume : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.volume_mute,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        Icon(
                          Icons.volume_up,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(context, 'কীবোর্ড সাউন্ড থিম'),
            const SizedBox(height: 16),

            // Sound theme options
            _buildThemeOption(
              context,
              title: 'মেকানিকাল',
              description: 'মেকানিকাল কীবোর্ডের মত শব্দ',
              theme: KeyboardSoundTheme.mechanical,
              icon: Icons.keyboard,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              title: 'সফট',
              description: 'হালকা এবং মৃদু টাইপিং শব্দ',
              theme: KeyboardSoundTheme.soft,
              icon: Icons.keyboard_alt_outlined,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              title: 'টাইপরাইটার',
              description: 'ক্লাসিক টাইপরাইটারের মত শব্দ',
              theme: KeyboardSoundTheme.typewriter,
              icon: Icons.keyboard_hide,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              title: 'কোন শব্দ নয়',
              description: 'টাইপিং এর সময় কোন শব্দ হবে না',
              theme: KeyboardSoundTheme.none,
              icon: Icons.volume_off,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(context, 'টেস্ট সাউন্ড'),
            const SizedBox(height: 16),

            // Test sound buttons
            _buildSettingCard(
              context,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'সাউন্ড পরীক্ষা করুন',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildSoundTestButton(
                          context,
                          'কী প্রেস',
                          Icons.keyboard,
                          SoundType.keyPress,
                        ),
                        _buildSoundTestButton(
                          context,
                          'ভুল কী',
                          Icons.error_outline,
                          SoundType.keyError,
                        ),
                        _buildSoundTestButton(
                          context,
                          'লেভেল সম্পন্ন',
                          Icons.check_circle_outline,
                          SoundType.levelComplete,
                        ),
                        _buildSoundTestButton(
                          context,
                          'অর্জন',
                          Icons.emoji_events_outlined,
                          SoundType.achievement,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String description,
    required KeyboardSoundTheme theme,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedTheme == theme;

    return _buildSettingCard(
      context,
      child: InkWell(
        onTap: _isSoundEnabled ? () => _updateSoundTheme(theme) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
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
                        color: _isSoundEnabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: _isSoundEnabled
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundTestButton(
    BuildContext context,
    String label,
    IconData icon,
    SoundType soundType,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton.icon(
      onPressed: _isSoundEnabled
          ? () => ref.read(soundServiceProvider).playSound(soundType)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.surfaceVariant,
        foregroundColor: colorScheme.onSurfaceVariant,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.hindSiliguri(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _updateSoundEnabled(bool value) async {
    setState(() {
      _isSoundEnabled = value;
    });

    await ref.read(soundServiceProvider).setSoundEnabled(value);
    ref.read(soundEnabledProvider.notifier).state = value;

    // Play a test sound if enabled
    if (value) {
      ref.read(soundServiceProvider).playSound(SoundType.keyPress);
    }
  }

  void _updateVolume(double value) async {
    setState(() {
      _volume = value;
    });

    await ref.read(soundServiceProvider).setVolume(value);
    ref.read(soundVolumeProvider.notifier).state = value;

    // Play a test sound
    if (_isSoundEnabled) {
      ref.read(soundServiceProvider).playSound(SoundType.keyPress);
    }
  }

  void _updateSoundTheme(KeyboardSoundTheme theme) async {
    setState(() {
      _selectedTheme = theme;
    });

    await ref.read(soundServiceProvider).setKeyboardSoundTheme(theme);
    ref.read(soundThemeProvider.notifier).state = theme;

    // Play a test sound
    if (_isSoundEnabled && theme != KeyboardSoundTheme.none) {
      ref.read(soundServiceProvider).playSound(SoundType.keyPress);
    }
  }
}
