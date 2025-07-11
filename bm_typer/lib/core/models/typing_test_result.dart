import 'package:json_annotation/json_annotation.dart';

part 'typing_test_result.g.dart';

@JsonSerializable()
class TypingTestResult {
  final double wpm;
  final double accuracy;
  final int correctChars;
  final int incorrectChars;
  final int totalChars;
  final double duration;
  final String difficulty;
  final DateTime timestamp;

  TypingTestResult({
    required this.wpm,
    required this.accuracy,
    required this.correctChars,
    required this.incorrectChars,
    required this.totalChars,
    required this.duration,
    required this.difficulty,
    required this.timestamp,
  });

  // Create from JSON
  factory TypingTestResult.fromJson(Map<String, dynamic> json) =>
      _$TypingTestResultFromJson(json);

  // Convert to JSON
  Map<String, dynamic> toJson() => _$TypingTestResultToJson(this);

  // Calculate net WPM
  double get netWpm => wpm * accuracy;

  // Calculate characters per minute
  double get cpm => totalChars / duration;

  // Get difficulty level as enum
  TestDifficulty get difficultyLevel {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return TestDifficulty.easy;
      case 'hard':
        return TestDifficulty.hard;
      default:
        return TestDifficulty.medium;
    }
  }
}

enum TestDifficulty { easy, medium, hard }
