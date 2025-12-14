import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional import: use stub on non-web, dart:html on web
import 'sound_service_stub.dart'
    if (dart.library.html) 'sound_service_web.dart' as web_audio;


enum SoundType {
  keyPress,
  keyError,
  levelComplete,
  achievement,
}

enum KeyboardSoundTheme {
  mechanical,
  soft,
  typewriter,
  none,
}

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioPlayer? _audioPlayer;
  // For web platform
  Map<String, web_audio.AudioElement> _webAudioElements = {};
  bool _isSoundEnabled = true;
  double _volume = 0.5;
  KeyboardSoundTheme _currentTheme = KeyboardSoundTheme.soft;

  // Cache for sound assets
  final Map<String, Uint8List> _soundCache = {};

  Future<void> initialize() async {
    // Create a player for **all** platforms so that audio also works on the web.
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
    }

    // Load persisted settings first.
    await _loadSettings();

    if (!kIsWeb) {
      // Only preload (and cache) the byte data on mobile / desktop.
      await _preloadSounds();
    } else {
      // On web we rely on playing straight from the asset bundle, no caching
      debugPrint('Sound service: Web platform detected, using HTML Audio API.');
      await _preloadWebSounds();
    }
  }

  Future<void> _preloadWebSounds() async {
    if (!kIsWeb || !_isSoundEnabled || _currentTheme == KeyboardSoundTheme.none)
      return;

    try {
      // Preload key press sounds based on theme
      await _loadWebSound(_getSoundPath(SoundType.keyPress));

      // Preload other sounds
      await _loadWebSound(_getSoundPath(SoundType.keyError));
      await _loadWebSound(_getSoundPath(SoundType.levelComplete));
      await _loadWebSound(_getSoundPath(SoundType.achievement));
    } catch (e) {
      debugPrint('Error preloading web sounds: $e');
    }
  }

  Future<void> _loadWebSound(String path) async {
    if (path.isEmpty) return;

    if (!_webAudioElements.containsKey(path)) {
      final audio = web_audio.createAudioElement();
      audio.src = path;
      audio.preload = 'auto';
      // Set volume
      audio.volume = _volume;
      // Add to document to allow preloading
      web_audio.document.body?.append(audio);
      // Hide the element
      audio.style.display = 'none';
      // Store for later use
      _webAudioElements[path] = audio;
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      _volume = prefs.getDouble('sound_volume') ?? 0.5;
      _currentTheme = KeyboardSoundTheme.values[
          prefs.getInt('keyboard_sound_theme') ??
              KeyboardSoundTheme.soft.index];
    } catch (e) {
      debugPrint('Error loading sound settings: $e');
      // Use defaults if settings can't be loaded
      _isSoundEnabled = true;
      _volume = 0.5;
      _currentTheme = KeyboardSoundTheme.soft;
    }
  }

  Future<void> _preloadSounds() async {
    if (!_isSoundEnabled || _currentTheme == KeyboardSoundTheme.none || kIsWeb)
      return;

    try {
      // Preload key press sounds based on theme
      await _loadSoundToCache(_getSoundPath(SoundType.keyPress));

      // Preload other sounds
      await _loadSoundToCache(_getSoundPath(SoundType.keyError));
      await _loadSoundToCache(_getSoundPath(SoundType.levelComplete));
      await _loadSoundToCache(_getSoundPath(SoundType.achievement));
    } catch (e) {
      debugPrint('Error preloading sounds: $e');
    }
  }

  Future<void> _loadSoundToCache(String path) async {
    if (_soundCache.containsKey(path)) return;

    try {
      final data = await rootBundle.load(path);
      _soundCache[path] = data.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error loading sound: $path - $e');
    }
  }

  String _getSoundPath(SoundType type) {
    switch (type) {
      case SoundType.keyPress:
        switch (_currentTheme) {
          case KeyboardSoundTheme.mechanical:
            return 'assets/sounds/key_mechanical.mp3';
          case KeyboardSoundTheme.soft:
            return 'assets/sounds/key_soft.mp3';
          case KeyboardSoundTheme.typewriter:
            return 'assets/sounds/key_typewriter.mp3';
          case KeyboardSoundTheme.none:
            return '';
        }
      case SoundType.keyError:
        return 'assets/sounds/key_error.mp3';
      case SoundType.levelComplete:
        return 'assets/sounds/level_complete.mp3';
      case SoundType.achievement:
        return 'assets/sounds/achievement.mp3';
    }
  }

  Future<void> playSound(SoundType type) async {
    if (!_isSoundEnabled || _currentTheme == KeyboardSoundTheme.none) return;

    try {
      final path = _getSoundPath(type);
      if (path.isEmpty) return;

      if (kIsWeb) {
        // Web-specific audio playback
        await _playWebSound(path);
      } else {
        if (!_soundCache.containsKey(path)) {
          await _loadSoundToCache(path);
        }

        if (_soundCache.containsKey(path)) {
          await _audioPlayer!.setSourceBytes(_soundCache[path]!);
          await _audioPlayer!.setVolume(_volume);
          await _audioPlayer!.resume();
        }
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> _playWebSound(String path) async {
    if (!_webAudioElements.containsKey(path)) {
      await _loadWebSound(path);
    }

    if (_webAudioElements.containsKey(path)) {
      try {
        final audio = _webAudioElements[path]!;

        // Reset the audio to the beginning if it's already playing
        audio.currentTime = 0;
        audio.volume = _volume;

        // Play the sound
        await audio.play();
      } catch (e) {
        debugPrint('Error playing web sound: $e');
      }
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_volume', _volume);

    // Update volume for web audio elements
    if (kIsWeb) {
      for (var audio in _webAudioElements.values) {
        audio.volume = _volume;
      }
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _isSoundEnabled);
  }

  Future<void> setKeyboardSoundTheme(KeyboardSoundTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('keyboard_sound_theme', _currentTheme.index);
    await _preloadSounds();
    if (kIsWeb) {
      await _preloadWebSounds();
    }
  }

  bool get isSoundEnabled => _isSoundEnabled;
  double get volume => _volume;
  KeyboardSoundTheme get currentTheme => _currentTheme;

  void dispose() {
    if (!kIsWeb) {
      _audioPlayer?.dispose();
      _audioPlayer = null;
    } else {
      // Clean up web audio elements
      for (var audio in _webAudioElements.values) {
        audio.remove();
      }
      _webAudioElements.clear();
    }
    _soundCache.clear();
  }
}
