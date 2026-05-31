import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/services/accessibility_service.dart';

final accessibilityServiceProvider = Provider<AccessibilityService>((ref) {
  final service = AccessibilityService();
  return service;
});

final keyboardNavigationEnabledProvider = StateProvider<bool>((ref) {
  return ref.watch(accessibilityServiceProvider).keyboardNavigationEnabled;
});

final highContrastModeProvider = StateProvider<bool>((ref) {
  return ref.watch(accessibilityServiceProvider).highContrastMode;
});

final reducedMotionProvider = StateProvider<bool>((ref) {
  return ref.watch(accessibilityServiceProvider).reducedMotion;
});

final textScaleFactorProvider = StateProvider<double>((ref) {
  return ref.watch(accessibilityServiceProvider).textScaleFactor;
});

final autoScrollSpeedProvider = StateProvider<double>((ref) {
  return ref.watch(accessibilityServiceProvider).autoScrollSpeed;
});
