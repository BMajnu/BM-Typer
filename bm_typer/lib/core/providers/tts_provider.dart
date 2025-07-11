import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/services/tts_service.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final ttsEnabledProvider = StateProvider<bool>((ref) {
  return ref.watch(ttsServiceProvider).isTtsEnabled;
});

final ttsSpeechRateProvider = StateProvider<double>((ref) {
  return ref.watch(ttsServiceProvider).speechRate;
});

final ttsVolumeProvider = StateProvider<double>((ref) {
  return ref.watch(ttsServiceProvider).volume;
});

final ttsPitchProvider = StateProvider<double>((ref) {
  return ref.watch(ttsServiceProvider).pitch;
});

final ttsLanguageProvider = StateProvider<String>((ref) {
  return ref.watch(ttsServiceProvider).language;
});
