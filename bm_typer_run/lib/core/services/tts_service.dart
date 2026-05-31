import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  FlutterTts? _flutterTts;
  TtsState _ttsState = TtsState.stopped;
  bool _isTtsEnabled = true;
  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;
  String _language = 'bn-BD'; // Default to Bengali

  Future<void> initialize() async {
    if (!kIsWeb) {
      // Skip initialization on web platform
      if (_flutterTts == null) {
        _flutterTts = FlutterTts();

        await _flutterTts!.setLanguage(_language);
        await _flutterTts!.setSpeechRate(_speechRate);
        await _flutterTts!.setVolume(_volume);
        await _flutterTts!.setPitch(_pitch);

        _flutterTts!.setStartHandler(() {
          _ttsState = TtsState.playing;
        });

        _flutterTts!.setCompletionHandler(() {
          _ttsState = TtsState.stopped;
        });

        _flutterTts!.setErrorHandler((msg) {
          _ttsState = TtsState.stopped;
          debugPrint("TTS Error: $msg");
        });
      }
    } else {
      debugPrint(
          'TTS service: Web platform detected, using limited functionality');
    }

    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTtsEnabled = prefs.getBool('tts_enabled') ?? true;
      _speechRate = prefs.getDouble('tts_speech_rate') ?? 0.5;
      _volume = prefs.getDouble('tts_volume') ?? 1.0;
      _pitch = prefs.getDouble('tts_pitch') ?? 1.0;
      _language = prefs.getString('tts_language') ?? 'bn-BD';

      if (_flutterTts != null && !kIsWeb) {
        await _flutterTts!.setLanguage(_language);
        await _flutterTts!.setSpeechRate(_speechRate);
        await _flutterTts!.setVolume(_volume);
        await _flutterTts!.setPitch(_pitch);
      }
    } catch (e) {
      debugPrint('Error loading TTS settings: $e');
      // Use defaults if settings can't be loaded
      _isTtsEnabled = true;
      _speechRate = 0.5;
      _volume = 1.0;
      _pitch = 1.0;
      _language = 'bn-BD';
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    if (_flutterTts == null || kIsWeb) {
      // Return default languages for web
      return ['en-US', 'bn-BD'];
    }

    try {
      final languages = await _flutterTts!.getLanguages;
      return languages.cast<String>();
    } catch (e) {
      debugPrint('Error getting available languages: $e');
      return ['en-US', 'bn-BD']; // Default fallback
    }
  }

  Future<void> speak(String text) async {
    if (!_isTtsEnabled || _flutterTts == null || text.isEmpty || kIsWeb) return;

    if (_ttsState == TtsState.playing) {
      await stop();
    }

    try {
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  Future<void> stop() async {
    if (_flutterTts == null || kIsWeb) return;
    try {
      await _flutterTts!.stop();
      _ttsState = TtsState.stopped;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  Future<void> pause() async {
    if (_flutterTts == null || kIsWeb) return;
    try {
      await _flutterTts!.pause();
      _ttsState = TtsState.paused;
    } catch (e) {
      debugPrint('Error pausing TTS: $e');
    }
  }

  Future<void> setTtsEnabled(bool enabled) async {
    _isTtsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', _isTtsEnabled);
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    if (_flutterTts != null && !kIsWeb) {
      await _flutterTts!.setSpeechRate(rate);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_speech_rate', _speechRate);
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    if (_flutterTts != null && !kIsWeb) {
      await _flutterTts!.setVolume(volume);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_volume', _volume);
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    if (_flutterTts != null && !kIsWeb) {
      await _flutterTts!.setPitch(pitch);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_pitch', _pitch);
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    if (_flutterTts != null && !kIsWeb) {
      await _flutterTts!.setLanguage(language);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_language', _language);
  }

  bool get isTtsEnabled => _isTtsEnabled;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  String get language => _language;
  TtsState get ttsState => _ttsState;

  void dispose() {
    if (!kIsWeb) {
      _flutterTts?.stop();
      _flutterTts = null;
    }
  }
}
