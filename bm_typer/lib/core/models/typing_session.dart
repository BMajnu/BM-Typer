import 'package:meta/meta.dart';

/// Simple model holding summary statistics for a single typing session.
///
/// The model is intentionally kept free from Hive / Json annotations to avoid
/// extra code-generation complexity for now. Only the data required by the UI
/// is stored.
@immutable
class TypingSession {
  final double wpm;
  final double accuracy;
  final DateTime timestamp;
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
