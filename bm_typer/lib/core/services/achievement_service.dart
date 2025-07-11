import 'package:bm_typer/core/models/achievement_model.dart';
import 'package:bm_typer/core/models/user_model.dart';
import 'package:bm_typer/data/local_lesson_data.dart';
import 'package:flutter/material.dart';

/// Service to check and award achievements
class AchievementService {
  /// Check for newly unlocked achievements based on user stats
  static List<Achievement> checkForNewAchievements(
    UserModel user,
    UserModel previousUser,
  ) {
    final newAchievements = <Achievement>[];
    final unlockedIds = user.unlockedAchievements;

    // Speed achievements check
    final currentWpm = user.highestWpm.toInt();
    final speedAchievements =
        Achievements.byCategory(AchievementCategory.speed);

    for (final achievement in speedAchievements) {
      if (!unlockedIds.contains(achievement.id) &&
          currentWpm >= achievement.requiredValue) {
        newAchievements.add(achievement);
      }
    }

    // Accuracy achievements check
    final currentAccuracy = user.averageAccuracy.toInt();
    final accuracyAchievements =
        Achievements.byCategory(AchievementCategory.accuracy);

    for (final achievement in accuracyAchievements) {
      if (!unlockedIds.contains(achievement.id) &&
          currentAccuracy >= achievement.requiredValue) {
        newAchievements.add(achievement);
      }
    }

    // Consistency achievements check
    final currentStreak = user.streakCount;
    final consistencyAchievements =
        Achievements.byCategory(AchievementCategory.consistency);

    for (final achievement in consistencyAchievements) {
      if (!unlockedIds.contains(achievement.id) &&
          currentStreak >= achievement.requiredValue) {
        newAchievements.add(achievement);
      }
    }

    // Lesson achievements check
    final completedLessonsCount = user.completedLessons.length;
    final lessonAchievements =
        Achievements.byCategory(AchievementCategory.lesson);

    for (final achievement in lessonAchievements) {
      if (!unlockedIds.contains(achievement.id)) {
        if (achievement.id == 'lessons_all') {
          // Special case for completing all lessons
          if (completedLessonsCount >= lessons.length) {
            newAchievements.add(achievement);
          }
        } else if (completedLessonsCount >= achievement.requiredValue) {
          newAchievements.add(achievement);
        }
      }
    }

    return newAchievements;
  }

  /// Check for special achievements that need to be awarded based on specific events
  static List<Achievement> checkSpecialAchievements(
      UserModel user, String eventType) {
    final newAchievements = <Achievement>[];
    final unlockedIds = user.unlockedAchievements;

    switch (eventType) {
      case 'first_login':
        final firstLoginAchievement =
            Achievements.getById('special_first_login');
        if (firstLoginAchievement != null &&
            !unlockedIds.contains(firstLoginAchievement.id)) {
          newAchievements.add(firstLoginAchievement);
        }
        break;
      // Add more special achievement checks as needed
    }

    return newAchievements;
  }

  /// Calculate the total XP that should be awarded for a list of achievements
  static int calculateTotalXpReward(List<Achievement> achievements) {
    int totalXp = 0;
    for (final achievement in achievements) {
      totalXp += achievement.xpReward;
    }
    return totalXp;
  }

  /// Get achievements grouped by category
  static Map<AchievementCategory, List<Achievement>> getGroupedAchievements() {
    final Map<AchievementCategory, List<Achievement>> groupedAchievements = {};

    for (final category in AchievementCategory.values) {
      groupedAchievements[category] = Achievements.byCategory(category);
    }

    return groupedAchievements;
  }

  /// Get the progress towards an achievement
  static double getProgressTowards(Achievement achievement, UserModel user) {
    switch (achievement.category) {
      case AchievementCategory.speed:
        final currentWpm = user.highestWpm.toInt();
        return _calculateProgress(currentWpm, achievement.requiredValue);

      case AchievementCategory.accuracy:
        final currentAccuracy = user.averageAccuracy.toInt();
        return _calculateProgress(currentAccuracy, achievement.requiredValue);

      case AchievementCategory.consistency:
        final currentStreak = user.streakCount;
        return _calculateProgress(currentStreak, achievement.requiredValue);

      case AchievementCategory.lesson:
        final completedLessonsCount = user.completedLessons.length;
        if (achievement.id == 'lessons_all') {
          return _calculateProgress(completedLessonsCount, lessons.length);
        } else {
          return _calculateProgress(
              completedLessonsCount, achievement.requiredValue);
        }

      case AchievementCategory.special:
        // Special achievements are either unlocked or not
        return user.unlockedAchievements.contains(achievement.id) ? 1.0 : 0.0;
    }
  }

  /// Calculate progress percentage (0.0 to 1.0)
  static double _calculateProgress(int currentValue, int requiredValue) {
    if (requiredValue <= 0) return 0.0;
    double progress = currentValue / requiredValue;
    return progress.clamp(0.0, 1.0);
  }

  /// Get icon and color for achievement category
  static IconData getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.speed:
        return Icons.speed;
      case AchievementCategory.accuracy:
        return Icons.check_circle;
      case AchievementCategory.consistency:
        return Icons.calendar_month;
      case AchievementCategory.lesson:
        return Icons.menu_book;
      case AchievementCategory.special:
        return Icons.emoji_events;
    }
  }

  static Color getCategoryColor(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.speed:
        return Colors.blue;
      case AchievementCategory.accuracy:
        return Colors.green;
      case AchievementCategory.consistency:
        return Colors.orange;
      case AchievementCategory.lesson:
        return Colors.purple;
      case AchievementCategory.special:
        return Colors.amber;
    }
  }
}
