import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:bm_typer/core/models/user_model.dart';

class DatabaseService {
  static const String _userBoxName = 'users';
  static const String _currentUserKey = 'current_user';

  /// Initialize Hive database
  static Future<void> initialize() async {
    // Initialize Hive
    if (!kIsWeb) {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
    } else {
      await Hive.initFlutter();
    }

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }

    // Open boxes
    await Hive.openBox<UserModel>(_userBoxName);
    await Hive.openBox<String>('settings');
  }

  /// Get the box containing users
  static Box<UserModel> get _userBox => Hive.box<UserModel>(_userBoxName);

  /// Get the box containing settings
  static Box<String> get _settingsBox => Hive.box<String>('settings');

  /// Save user to the database
  static Future<void> saveUser(UserModel user) async {
    await _userBox.put(user.id, user);
  }

  /// Get user by ID
  static UserModel? getUserById(String id) {
    return _userBox.get(id);
  }

  /// Get all users
  static List<UserModel> getAllUsers() {
    return _userBox.values.toList();
  }

  /// Delete user by ID
  static Future<void> deleteUser(String id) async {
    await _userBox.delete(id);
  }

  /// Set current user
  static Future<void> setCurrentUser(UserModel user) async {
    await saveUser(user);
    await _settingsBox.put(_currentUserKey, user.id);
  }

  /// Get current user
  static UserModel? getCurrentUser() {
    final String? currentUserId = _settingsBox.get(_currentUserKey);
    if (currentUserId == null) return null;
    return getUserById(currentUserId);
  }

  /// Clear current user
  static Future<void> clearCurrentUser() async {
    await _settingsBox.delete(_currentUserKey);
  }

  /// Update user session data
  static Future<void> updateUserSession({
    required String userId,
    required double wpm,
    required double accuracy,
    String? completedLesson,
    List<String> newAchievements = const [],
    int earnedXp = 0,
  }) async {
    final user = getUserById(userId);
    if (user == null) return;

    final updatedUser = user.addSessionResult(
      wpm: wpm,
      accuracy: accuracy,
      completedLesson: completedLesson,
      newAchievements: newAchievements,
      earnedXp: earnedXp,
    );

    await saveUser(updatedUser);
  }
}
