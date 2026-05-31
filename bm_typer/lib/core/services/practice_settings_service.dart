import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PracticeSettingsService {
  static final PracticeSettingsService _instance =
      PracticeSettingsService._internal();
  factory PracticeSettingsService() => _instance;
  PracticeSettingsService._internal();

  static const String _showTransitionPopupKey = 'show_lesson_transition_popup';
  static const String _showLayerIntroPopupKey = 'show_lesson_layer_intro_popup';

  bool _isInitialized = false;
  bool _showTransitionPopup = true;
  bool _showLayerIntroPopup = true;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadSettings();
    _isInitialized = true;
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showTransitionPopup = prefs.getBool(_showTransitionPopupKey) ?? true;
      _showLayerIntroPopup = prefs.getBool(_showLayerIntroPopupKey) ?? true;
    } catch (e) {
      debugPrint('Error loading practice settings: $e');
      _showTransitionPopup = true;
      _showLayerIntroPopup = true;
    }
  }

  Future<void> setShowTransitionPopup(bool value) async {
    _showTransitionPopup = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTransitionPopupKey, value);
  }

  bool get showTransitionPopup => _showTransitionPopup;

  Future<void> setShowLayerIntroPopup(bool value) async {
    _showLayerIntroPopup = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showLayerIntroPopupKey, value);
  }

  bool get showLayerIntroPopup => _showLayerIntroPopup;
}
