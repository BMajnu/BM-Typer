import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/services/database_service.dart';
import 'package:bm_typer/core/services/achievement_service.dart';
import 'package:bm_typer/core/services/cloud_sync_service.dart';
import 'package:bm_typer/core/services/sync_queue_service.dart';
import 'package:bm_typer/core/services/connectivity_service.dart';
import 'package:bm_typer/core/models/sync_operation.dart';
import 'package:flutter/foundation.dart';

/// Provider for the current user
final currentUserProvider =
    StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier(ref);
});

/// Notifier to manage user state
class UserNotifier extends StateNotifier<UserModel?> {
  final Ref _ref;
  final CloudSyncService _cloudSync = CloudSyncService();
  final SyncQueueService _syncQueue = SyncQueueService();
  final ConnectivityService _connectivity = ConnectivityService();

  UserNotifier(this._ref) : super(null) {
    _initialize();
  }

  /// Initialize the notifier by loading the current user from storage
  Future<void> _initialize() async {
    final user = await DatabaseService.getCurrentUser();
    if (user != null) {
      // Check and update login streak
      final updatedUser = user.updateLoginStreak();

      // Check for achievements after streak update
      final achievements = AchievementService.checkForNewAchievements(
        updatedUser,
        user,
      );

      // Check for special login achievement
      final specialAchievements = AchievementService.checkSpecialAchievements(
        updatedUser,
        'first_login',
      );

      // Combine all achievements
      final allAchievements = [...achievements, ...specialAchievements];

      // Calculate total XP to award
      final xpToAward =
          AchievementService.calculateTotalXpReward(allAchievements);

      // Add achievements and XP
      UserModel finalUser = updatedUser;

      if (xpToAward > 0) {
        finalUser = finalUser.addXP(xpToAward);
      }

      for (final achievement in allAchievements) {
        finalUser = finalUser.unlockAchievement(achievement.id);
      }

      // Save and update state
      await DatabaseService.saveUser(finalUser);
      state = finalUser;
      
      // Sync to cloud
      await _syncToCloud(finalUser);
    }
  }

  /// Sync user data to cloud (with offline queue fallback)
  Future<void> _syncToCloud(UserModel user) async {
    try {
      if (_connectivity.isOnline) {
        await _cloudSync.syncUser(user);
        debugPrint('☁️ User synced to cloud: ${user.name}');
      } else {
        // Add to offline queue
        await _syncQueue.addOperation(SyncOperation(
          collection: 'users',
          documentId: user.id,
          data: {
            'profile': {
              'name': user.name,
              'email': user.email,
              'lastLoginDate': user.lastLoginDate?.toIso8601String(),
            },
            'stats': {
              'highestWpm': user.highestWpm,
              'xpPoints': user.xpPoints,
              'level': user.level,
              'streakCount': user.streakCount,
            },
            'progress': {
              'completedLessons': user.completedLessons,
              'unlockedAchievements': user.unlockedAchievements,
            },
          },
          operationType: 'update',
        ));
        debugPrint('📥 User queued for sync: ${user.name}');
      }
    } catch (e) {
      debugPrint('❌ Sync error: $e');
    }
  }

  /// Register a new user
  Future<void> registerUser(String name, String email) async {
    final user = UserModel(
      name: name,
      email: email,
      lastLoginDate: DateTime.now(),
      streakCount: 1,
    );

    await DatabaseService.saveUser(user);
    await DatabaseService.setCurrentUser(user);

    // Check for first login achievement
    final achievements = AchievementService.checkSpecialAchievements(
      user,
      'first_login',
    );

    // Calculate total XP to award
    final xpToAward = AchievementService.calculateTotalXpReward(achievements);

    // Add achievements and XP
    UserModel finalUser = user;

    if (xpToAward > 0) {
      finalUser = finalUser.addXP(xpToAward);
    }

    for (final achievement in achievements) {
      finalUser = finalUser.unlockAchievement(achievement.id);
    }

    if (finalUser != user) {
      await DatabaseService.saveUser(finalUser);
    }

    state = finalUser;
    
    // Sync new user to cloud
    await _syncToCloud(finalUser);
  }

  /// Update the user information
  Future<void> updateUser(UserModel updatedUser) async {
    // if (state == null) return; // Removed to allow login/initialization

    await DatabaseService.saveUser(updatedUser);
    state = updatedUser;
    
    // Sync to cloud
    await _syncToCloud(updatedUser);
  }

  /// Update user typing goals
  Future<void> updateGoals({double? wpm, double? accuracy}) async {
    if (state == null) return;

    final updatedUser = state!.copyWith(
      goalWpm: wpm,
      goalAccuracy: accuracy,
    );

    await DatabaseService.saveUser(updatedUser);
    state = updatedUser;
    
    // Sync goals to cloud
    await _syncToCloud(updatedUser);
  }

  /// Mark an achievement notification as shown
  Future<void> markAchievementAsShown(String achievementId) async {
    if (state == null) return;

    final updatedUser = state!.markAchievementNotificationShown(achievementId);
    await DatabaseService.saveUser(updatedUser);
    state = updatedUser;
  }

  /// Add typing statistics and check for achievements
  Future<List<Achievement>> addTypingStats({
    required double wpm,
    required double accuracy,
    String? completedLesson,
    int additionalXp = 0,
  }) async {
    if (state == null) return [];

    // Keep a copy of the previous user state for achievement comparison
    final previousUser = state!;

    // Create new WPM and accuracy history
    final newWpmHistory = List<double>.from(state!.wpmHistory)..add(wpm);
    final newAccuracyHistory = List<double>.from(state!.accuracyHistory)
      ..add(accuracy);

    // Update highest WPM if needed
    final newHighestWpm = wpm > state!.highestWpm ? wpm : state!.highestWpm;

    // Update completed lessons if needed
    List<String>? newCompletedLessons;
    if (completedLesson != null &&
        !state!.completedLessons.contains(completedLesson)) {
      newCompletedLessons = List<String>.from(state!.completedLessons)
        ..add(completedLesson);
    }

    // Create updated user with new stats
    final updatedUser = state!.copyWith(
      wpmHistory: newWpmHistory,
      accuracyHistory: newAccuracyHistory,
      highestWpm: newHighestWpm,
      completedLessons: newCompletedLessons,
    );

    // Check for new achievements
    final achievements = AchievementService.checkForNewAchievements(
      updatedUser,
      previousUser,
    );

    // Calculate total XP to award
    final xpToAward = AchievementService.calculateTotalXpReward(achievements);

    // Add XP and achievements
    UserModel finalUser = updatedUser;

    if (xpToAward > 0) {
      finalUser = finalUser.addXP(xpToAward);
    }

    for (final achievement in achievements) {
      finalUser = finalUser.unlockAchievement(achievement.id);
    }

    // Save and update state
    await DatabaseService.saveUser(finalUser);
    state = finalUser;

    // Sync user stats and typing session to cloud
    await _syncToCloud(finalUser);
    await _cloudSync.syncTypingSession(
      wpm: wpm,
      accuracy: accuracy,
      lessonId: completedLesson,
    );

    return achievements;
  }

  /// Add XP to the user
  Future<void> addXP(int amount) async {
    if (state == null) return;

    final updatedUser = state!.addXP(amount);
    await DatabaseService.saveUser(updatedUser);
    state = updatedUser;
  }

  /// Logout the current user
  Future<void> logout() async {
    await DatabaseService.clearCurrentUser();
    state = null;
  }

  /// Fetch current user from database
  Future<void> loadCurrentUser() async {
    try {
      state = DatabaseService.getCurrentUser();
    } catch (e) {
      state = null;
    }
  }

  // -----------------------------------------------------------------------
  // Backwards-compatibility helpers
  // -----------------------------------------------------------------------

  /// Alias for [registerUser] kept for compatibility with older UI code.
  Future<void> createUser({required String name, required String email}) {
    return registerUser(name, email);
  }

  /// Alias for [addTypingStats] that uses the parameter names expected by
  /// the older implementation (e.g. `earnedXp`).
  Future<List<Achievement>> updateTypingStats({
    required double wpm,
    required double accuracy,
    String? completedLesson,
    int earnedXp = 0,
  }) {
    return addTypingStats(
      wpm: wpm,
      accuracy: accuracy,
      completedLesson: completedLesson,
      additionalXp: earnedXp,
    );
  }
}
