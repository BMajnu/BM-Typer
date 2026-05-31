// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typing_test_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TypingTestResult _$TypingTestResultFromJson(Map<String, dynamic> json) =>
    TypingTestResult(
      wpm: (json['wpm'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      correctChars: (json['correctChars'] as num).toInt(),
      incorrectChars: (json['incorrectChars'] as num).toInt(),
      totalChars: (json['totalChars'] as num).toInt(),
      duration: (json['duration'] as num).toDouble(),
      difficulty: json['difficulty'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$TypingTestResultToJson(TypingTestResult instance) =>
    <String, dynamic>{
      'wpm': instance.wpm,
      'accuracy': instance.accuracy,
      'correctChars': instance.correctChars,
      'incorrectChars': instance.incorrectChars,
      'totalChars': instance.totalChars,
      'duration': instance.duration,
      'difficulty': instance.difficulty,
      'timestamp': instance.timestamp.toIso8601String(),
    };
