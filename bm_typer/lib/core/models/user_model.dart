import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:bm_typer/core/models/typing_session.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final List<double> wpmHistory;

  @HiveField(4)
  final List<double> accuracyHistory;

  @HiveField(5)
  final double highestWpm;

  @HiveField(6)
  final List<String> completedLessons;

  @HiveField(7)
  final List<String> unlockedAchievements;

  @HiveField(8)
  final int xpPoints;

  @HiveField(9)
  final int level;

  @HiveField(10)
  final int streakCount;

  @HiveField(11)
  final DateTime? lastLoginDate;

  @HiveField(12)
  final List<String> shownAchievementNotifications;

  @HiveField(13)
  final double goalWpm;

  @HiveField(14)
  final double goalAccuracy;

  @HiveField(15)
  final List<TypingSession> typingSessions;

  UserModel({
    String? id,
    required this.name,
    required this.email,
    List<double>? wpmHistory,
    List<double>? accuracyHistory,
    double? highestWpm,
    List<String>? completedLessons,
    List<String>? unlockedAchievements,
    int? xpPoints,
    int? level,
    int? streakCount,
    this.lastLoginDate,
    List<String>? shownAchievementNotifications,
    double? goalWpm,
    double? goalAccuracy,
    List<TypingSession>? typingSessions,
  })  : id = id ?? const Uuid().v4(),
        wpmHistory = wpmHistory ?? [],
        accuracyHistory = accuracyHistory ?? [],
        highestWpm = highestWpm ?? 0.0,
        completedLessons = completedLessons ?? [],
        unlockedAchievements = unlockedAchievements ?? [],
        xpPoints = xpPoints ?? 0,
        level = level ?? 1,
        streakCount = streakCount ?? 0,
        shownAchievementNotifications = shownAchievementNotifications ?? [],
        goalWpm = goalWpm ?? 60.0,
        goalAccuracy = goalAccuracy ?? 95.0,
        typingSessions = typingSessions ?? [];

  /// Get the average WPM from history
  double get averageWpm {
    if (wpmHistory.isEmpty) return 0.0;
    return wpmHistory.reduce((a, b) => a + b) / wpmHistory.length;
  }

  /// Get the average accuracy from history
  double get averageAccuracy {
    if (accuracyHistory.isEmpty) return 0.0;
    return accuracyHistory.reduce((a, b) => a + b) / accuracyHistory.length;
  }

  /// Create a copy of this user with updated fields
  UserModel copyWith({
    String? name,
    String? email,
    List<double>? wpmHistory,
    List<double>? accuracyHistory,
    double? highestWpm,
    List<String>? completedLessons,
    List<String>? unlockedAchievements,
    int? xpPoints,
    int? level,
    int? streakCount,
    DateTime? lastLoginDate,
    List<String>? shownAchievementNotifications,
    double? goalWpm,
    double? goalAccuracy,
    List<TypingSession>? typingSessions,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      wpmHistory: wpmHistory ?? this.wpmHistory,
      accuracyHistory: accuracyHistory ?? this.accuracyHistory,
      highestWpm: highestWpm ?? this.highestWpm,
      completedLessons: completedLessons ?? this.completedLessons,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      xpPoints: xpPoints ?? this.xpPoints,
      level: level ?? this.level,
      streakCount: streakCount ?? this.streakCount,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      shownAchievementNotifications:
          shownAchievementNotifications ?? this.shownAchievementNotifications,
      goalWpm: goalWpm ?? this.goalWpm,
      goalAccuracy: goalAccuracy ?? this.goalAccuracy,
      typingSessions: typingSessions ?? this.typingSessions,
    );
  }

  /// Calculate the XP required for the next level
  static int xpRequiredForLevel(int level) {
    // Simple formula: each level requires level * 100 XP
    return level * 100;
  }

  /// Calculate the current level based on XP
  static int calculateLevelFromXP(int xp) {
    // Start at level 1
    int level = 1;
    int xpRequired = xpRequiredForLevel(level);

    // Keep incrementing level while we have enough XP
    while (xp >= xpRequired) {
      level++;
      xpRequired += xpRequiredForLevel(level);
    }

    return level;
  }

  /// Calculate progress towards the next level (0.0 to 1.0)
  double get nextLevelProgress {
    // Total XP needed for current level
    int currentLevelXP = 0;
    for (int i = 1; i < level; i++) {
      currentLevelXP += xpRequiredForLevel(i);
    }

    // XP needed for next level
    int nextLevelXP = xpRequiredForLevel(level);

    // XP progress towards next level
    int xpProgress = xpPoints - currentLevelXP;

    return xpProgress / nextLevelXP;
  }

  /// Get XP remaining to reach next level
  int get xpToNextLevel {
    int xpForNextLevel = xpRequiredForLevel(level);
    int currentLevelXP = 0;

    for (int i = 1; i < level; i++) {
      currentLevelXP += xpRequiredForLevel(i);
    }

    return xpForNextLevel - (xpPoints - currentLevelXP);
  }

  /// Add XP and automatically update the level if needed
  UserModel addXP(int amount) {
    final newXP = xpPoints + amount;
    final newLevel = calculateLevelFromXP(newXP);

    return copyWith(
      xpPoints: newXP,
      level: newLevel,
    );
  }

  /// Add an achievement to the unlocked list if not already unlocked
  UserModel unlockAchievement(String achievementId) {
    if (unlockedAchievements.contains(achievementId)) {
      return this;
    }

    final newUnlockedAchievements = List<String>.from(unlockedAchievements)
      ..add(achievementId);

    return copyWith(unlockedAchievements: newUnlockedAchievements);
  }

  /// Mark an achievement as having its notification shown
  UserModel markAchievementNotificationShown(String achievementId) {
    if (shownAchievementNotifications.contains(achievementId)) {
      return this;
    }

    final newShownNotifications =
        List<String>.from(shownAchievementNotifications)..add(achievementId);

    return copyWith(shownAchievementNotifications: newShownNotifications);
  }

  /// Update the streak count based on the current date
  UserModel updateLoginStreak() {
    // If this is the first login, start streak at 1
    if (lastLoginDate == null) {
      return copyWith(
        streakCount: 1,
        lastLoginDate: DateTime.now(),
      );
    }

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Check if last login was yesterday (continue streak)
    if (lastLoginDate!.year == yesterday.year &&
        lastLoginDate!.month == yesterday.month &&
        lastLoginDate!.day == yesterday.day) {
      // Continue streak
      return copyWith(
        streakCount: streakCount + 1,
        lastLoginDate: now,
      );
    }
    // Check if last login was today (maintain streak)
    else if (lastLoginDate!.year == now.year &&
        lastLoginDate!.month == now.month &&
        lastLoginDate!.day == now.day) {
      // Already logged in today, maintain streak
      return this;
    }
    // Otherwise, streak is broken
    else {
      // Reset streak
      return copyWith(
        streakCount: 1,
        lastLoginDate: now,
      );
    }
  }

  // --- BEGIN NEW GETTERS --------------------------------------------------

  /// Total lessons the user has completed.
  int get totalLessonsCompleted => completedLessons.length;

  /// Alias for [streakCount] used by UI.
  int get streak => streakCount;

  /// Whether the streak is currently maintained (i.e. the user practiced today).
  bool get streakMaintained {
    if (lastLoginDate == null) return false;
    final now = DateTime.now();
    return now.year == lastLoginDate!.year &&
        now.month == lastLoginDate!.month &&
        now.day == lastLoginDate!.day;
  }

  /// Alias for [xpPoints] used by some widgets.
  int get xp => xpPoints;

  // --- END NEW GETTERS ----------------------------------------------------

  // --- BEGIN NEW METHODS --------------------------------------------------

  /// Convenience method used by [DatabaseService] to append a typing session
  /// result and update stats in one go.
  UserModel addSessionResult({
    required double wpm,
    required double accuracy,
    String? completedLesson,
    List<String> newAchievements = const [],
    int earnedXp = 0,
  }) {
    // Update histories
    final newWpmHistory = List<double>.from(wpmHistory)..add(wpm);
    final newAccuracyHistory = List<double>.from(accuracyHistory)
      ..add(accuracy);

    // Highest WPM check
    final newHighestWpm = wpm > highestWpm ? wpm : highestWpm;

    // Completed lessons list update
    List<String> updatedLessons = completedLessons;
    if (completedLesson != null &&
        !completedLessons.contains(completedLesson)) {
      updatedLessons = List<String>.from(completedLessons)
        ..add(completedLesson);
    }

    // Achievements list update
    final updatedAchievements = Set<String>.from(unlockedAchievements)
      ..addAll(newAchievements);

    // Add a record of this session
    final newTypingSessions = List<TypingSession>.from(typingSessions)
      ..add(TypingSession(
        wpm: wpm,
        accuracy: accuracy,
        timestamp: DateTime.now(),
        lessonId: completedLesson,
      ));

    // Add XP and potentially level-up
    return copyWith(
      wpmHistory: newWpmHistory,
      accuracyHistory: newAccuracyHistory,
      highestWpm: newHighestWpm,
      completedLessons: updatedLessons,
      unlockedAchievements: updatedAchievements.toList(),
      xpPoints: xpPoints + earnedXp,
      level: calculateLevelFromXP(xpPoints + earnedXp),
      typingSessions: newTypingSessions,
    );
  }

  /// Calculate how much of the course has been completed in percentage.
  double getCompletionPercentage(int totalLessons) {
    if (totalLessons == 0) return 0.0;
    return (totalLessonsCompleted / totalLessons) * 100.0;
  }

  // --- END NEW METHODS ----------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        listEquals(other.wpmHistory, wpmHistory) &&
        listEquals(other.accuracyHistory, accuracyHistory) &&
        other.highestWpm == highestWpm &&
        listEquals(other.completedLessons, completedLessons) &&
        listEquals(other.unlockedAchievements, unlockedAchievements) &&
        other.xpPoints == xpPoints &&
        other.level == level &&
        other.streakCount == streakCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        wpmHistory.hashCode ^
        accuracyHistory.hashCode ^
        highestWpm.hashCode ^
        completedLessons.hashCode ^
        unlockedAchievements.hashCode ^
        xpPoints.hashCode ^
        level.hashCode ^
        streakCount.hashCode;
  }
}
