import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Pool of players for rapid typing (prevent cutting off sounds)
  final List<AudioPlayer> _playerPool = [];
  int _poolIndex = 0;
  static const int _poolSize = 5; // Adjust based on needs

  bool _isSoundEnabled = true;
  bool _isCompletionSoundEnabled = true;
  double _volume = 0.5;
  KeyboardSoundTheme _currentTheme = KeyboardSoundTheme.soft;

  // Cache for sound assets (Mobile/Desktop only)
  final Map<String, Uint8List> _soundCache = {};

  Future<void> initialize() async {
    // Initialize player pool
    for (int i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop); // Reset after playing
        _playerPool.add(player);
    }

    // Load persisted settings first.
    await _loadSettings();

    if (!kIsWeb) {
      // Only preload (and cache) the byte data on mobile / desktop.
      await _preloadSounds();
    }
    // On Web, AudioPlayers handles loading via AssetSource, but we can't easily "preload" bytes.
    // However, playing it once with volume 0 might cache it in browser, but we'll skip that for now to avoid side effects.
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      _isCompletionSoundEnabled =
          prefs.getBool('completion_sound_enabled') ?? true;
      _volume = prefs.getDouble('sound_volume') ?? 0.5;
      _currentTheme = KeyboardSoundTheme.values[
          prefs.getInt('keyboard_sound_theme') ??
              KeyboardSoundTheme.soft.index];
    } catch (e) {
      debugPrint('Error loading sound settings: $e');
      _isSoundEnabled = true;
      _isCompletionSoundEnabled = true;
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
      await _loadSoundToCache(_getSoundPath(SoundType.keyError));
      await _loadSoundToCache(_getSoundPath(SoundType.levelComplete));
      await _loadSoundToCache(_getSoundPath(SoundType.achievement));
    } catch (e) {
      debugPrint('Error preloading sounds: $e');
    }
  }

  Future<void> _loadSoundToCache(String path) async {
    if (path.isEmpty) return;
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

  // Helper to get asset path without 'assets/' prefix for AudioPlayers AssetSource
  String _getAssetSourcePath(String fullPath) {
    if (fullPath.startsWith('assets/')) {
      return fullPath.substring(7); // Remove 'assets/'
    }
    return fullPath;
  }

  Future<void> playSound(SoundType type) async {
    if (!_isSoundEnabled || _currentTheme == KeyboardSoundTheme.none) return;
    if (type == SoundType.levelComplete && !_isCompletionSoundEnabled) return;

    try {
      final path = _getSoundPath(type);
      if (path.isEmpty) return;

      // Get next player from pool
      final player = _playerPool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _poolSize;

      await player.setVolume(_volume);

      if (kIsWeb) {
        // Web: Use AssetSource
        // path is like 'assets/sounds/key.mp3', AssetSource needs 'sounds/key.mp3'
        final assetPath = _getAssetSourcePath(path);
        await player.play(AssetSource(assetPath));
      } else {
        // Mobile/Desktop: Use Bytes if cached, else AssetSource
        if (_soundCache.containsKey(path)) {
           // We need to set source then play for bytes
           await player.setSourceBytes(_soundCache[path]!);
           await player.resume();
        } else {
           // Fallback if not cached
           final assetPath = _getAssetSourcePath(path);
           await player.play(AssetSource(assetPath));
           // Also try to cache for next time
           _loadSoundToCache(path); 
        }
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_volume', _volume);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _isSoundEnabled);
  }

  Future<void> setCompletionSoundEnabled(bool enabled) async {
    _isCompletionSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('completion_sound_enabled', enabled);
  }

  Future<void> setKeyboardSoundTheme(KeyboardSoundTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('keyboard_sound_theme', _currentTheme.index);
    if (!kIsWeb) await _preloadSounds();
  }

  bool get isSoundEnabled => _isSoundEnabled;
  bool get isCompletionSoundEnabled => _isCompletionSoundEnabled;
  double get volume => _volume;
  KeyboardSoundTheme get currentTheme => _currentTheme;

  void dispose() {
    for (var player in _playerPool) {
      player.dispose();
    }
    _playerPool.clear();
    _soundCache.clear();
  }
}
