import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/services/database_service.dart';
import 'package:bm_typer/core/services/achievement_service.dart';

/// Provider for the current user
final currentUserProvider =
    StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});

/// Notifier to manage user state
class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null) {
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
  }

  /// Update the user information
  Future<void> updateUser(UserModel updatedUser) async {
    if (state == null) return;

    await DatabaseService.saveUser(updatedUser);
    state = updatedUser;
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
