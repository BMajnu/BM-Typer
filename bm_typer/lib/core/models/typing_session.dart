import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'typing_session.g.dart';

/// Simple model holding summary statistics for a single typing session.
///
/// This model is now persisted by Hive for tracking session history.
@immutable
@HiveType(typeId: 2)
class TypingSession {
  @HiveField(0)
  final double wpm;

  @HiveField(1)
  final double accuracy;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String? lessonId;

  // Convenience alias for older code
  String? get completedLesson => lessonId;

  const TypingSession({
    required this.wpm,
    required this.accuracy,
    required this.timestamp,
    this.lessonId,
  });
}

