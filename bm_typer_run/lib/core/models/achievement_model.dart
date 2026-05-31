import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

class Achievement {
  // Field annotations kept for possible future persistence
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final IconData icon;

  @HiveField(4)
  final int xpReward;

  @HiveField(5)
  final AchievementCategory category;

  @HiveField(6)
  final int requiredValue;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.category,
    required this.requiredValue,
  });
}

enum AchievementCategory {
  @HiveField(0)
  speed,

  @HiveField(1)
  accuracy,

  @HiveField(2)
  consistency,

  @HiveField(3)
  lesson,

  @HiveField(4)
  special
}

/// Custom adapter for IconData since it's not directly serializable
class IconDataAdapter extends TypeAdapter<IconData> {
  @override
  final typeId = 3;

  @override
  IconData read(BinaryReader reader) {
    return IconData(
      reader.readInt(),
      fontFamily: reader.readString(),
      fontPackage: reader.readString(),
      matchTextDirection: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, IconData obj) {
    writer.writeInt(obj.codePoint);
    writer.writeString(obj.fontFamily ?? '');
    writer.writeString(obj.fontPackage ?? '');
    writer.writeBool(obj.matchTextDirection);
  }
}

/// Create a list of all available achievements in the app
class Achievements {
  static const List<Achievement> all = [
    // Speed Achievements
    Achievement(
      id: 'speed_20',
      title: 'Beginner Typist',
      description: 'Reach 20 WPM',
      icon: Icons.speed,
      xpReward: 10,
      category: AchievementCategory.speed,
      requiredValue: 20,
    ),
    Achievement(
      id: 'speed_40',
      title: 'Skilled Typist',
      description: 'Reach 40 WPM',
      icon: Icons.speed,
      xpReward: 30,
      category: AchievementCategory.speed,
      requiredValue: 40,
    ),
    Achievement(
      id: 'speed_60',
      title: 'Fast Fingers',
      description: 'Reach 60 WPM',
      icon: Icons.speed,
      xpReward: 50,
      category: AchievementCategory.speed,
      requiredValue: 60,
    ),
    Achievement(
      id: 'speed_80',
      title: 'Speed Demon',
      description: 'Reach 80 WPM',
      icon: Icons.rocket_launch,
      xpReward: 100,
      category: AchievementCategory.speed,
      requiredValue: 80,
    ),
    Achievement(
      id: 'speed_100',
      title: 'Typing Master',
      description: 'Reach 100 WPM',
      icon: Icons.rocket_launch,
      xpReward: 200,
      category: AchievementCategory.speed,
      requiredValue: 100,
    ),

    // Accuracy Achievements
    Achievement(
      id: 'accuracy_80',
      title: 'Careful Typist',
      description: 'Achieve 80% accuracy',
      icon: Icons.check_circle_outline,
      xpReward: 10,
      category: AchievementCategory.accuracy,
      requiredValue: 80,
    ),
    Achievement(
      id: 'accuracy_90',
      title: 'Precise Typist',
      description: 'Achieve 90% accuracy',
      icon: Icons.check_circle_outline,
      xpReward: 30,
      category: AchievementCategory.accuracy,
      requiredValue: 90,
    ),
    Achievement(
      id: 'accuracy_95',
      title: 'Accurate Typist',
      description: 'Achieve 95% accuracy',
      icon: Icons.check_circle,
      xpReward: 50,
      category: AchievementCategory.accuracy,
      requiredValue: 95,
    ),
    Achievement(
      id: 'accuracy_98',
      title: 'Perfectionist',
      description: 'Achieve 98% accuracy',
      icon: Icons.check_circle,
      xpReward: 100,
      category: AchievementCategory.accuracy,
      requiredValue: 98,
    ),
    Achievement(
      id: 'accuracy_100',
      title: 'Flawless',
      description: 'Achieve 100% accuracy',
      icon: Icons.verified,
      xpReward: 200,
      category: AchievementCategory.accuracy,
      requiredValue: 100,
    ),

    // Consistency Achievements
    Achievement(
      id: 'streak_3',
      title: 'Regular Practice',
      description: 'Practice for 3 days in a row',
      icon: Icons.calendar_today,
      xpReward: 30,
      category: AchievementCategory.consistency,
      requiredValue: 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Weekly Warrior',
      description: 'Practice for 7 days in a row',
      icon: Icons.calendar_month,
      xpReward: 100,
      category: AchievementCategory.consistency,
      requiredValue: 7,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Typing Devotee',
      description: 'Practice for 30 days in a row',
      icon: Icons.local_fire_department,
      xpReward: 500,
      category: AchievementCategory.consistency,
      requiredValue: 30,
    ),

    // Lesson Achievements
    Achievement(
      id: 'lessons_5',
      title: 'Getting Started',
      description: 'Complete 5 lessons',
      icon: Icons.menu_book,
      xpReward: 50,
      category: AchievementCategory.lesson,
      requiredValue: 5,
    ),
    Achievement(
      id: 'lessons_10',
      title: 'Intermediate Learner',
      description: 'Complete 10 lessons',
      icon: Icons.menu_book,
      xpReward: 100,
      category: AchievementCategory.lesson,
      requiredValue: 10,
    ),
    Achievement(
      id: 'lessons_all',
      title: 'Course Graduate',
      description: 'Complete all lessons',
      icon: Icons.school,
      xpReward: 300,
      category: AchievementCategory.lesson,
      requiredValue: -1, // Special value to be handled in code
    ),

    // Special Achievements
    Achievement(
      id: 'special_first_login',
      title: 'First Step',
      description: 'Create a profile and start your typing journey',
      icon: Icons.emoji_events,
      xpReward: 10,
      category: AchievementCategory.special,
      requiredValue: -1, // Special achievement, no specific required value
    ),
  ];

  /// Get an achievement by ID
  static Achievement? getById(String id) {
    try {
      return all.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all achievements of a specific category
  static List<Achievement> byCategory(AchievementCategory category) {
    return all
        .where((achievement) => achievement.category == category)
        .toList();
  }
}
