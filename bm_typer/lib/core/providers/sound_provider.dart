import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/services/sound_service.dart';

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final soundEnabledProvider = StateProvider<bool>((ref) {
  return ref.watch(soundServiceProvider).isSoundEnabled;
});

final soundVolumeProvider = StateProvider<double>((ref) {
  return ref.watch(soundServiceProvider).volume;
});

final soundThemeProvider = StateProvider<KeyboardSoundTheme>((ref) {
  return ref.watch(soundServiceProvider).currentTheme;
});
