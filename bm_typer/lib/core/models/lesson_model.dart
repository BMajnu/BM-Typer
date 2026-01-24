import 'package:bm_typer/core/utils/bengali_normalizer.dart';

class Exercise {
  final String text;
  final int repetitions;
  final ExerciseType type;
  final int difficultyLevel;
  final String? source;

  const Exercise({
    required this.text,
    this.repetitions = 1,
    this.type = ExerciseType.standard,
    this.difficultyLevel = 1,
    this.source,
  });

  bool get isMultiLine => text.contains('\n');

  bool get isParagraph =>
      type == ExerciseType.paragraph || text.split(' ').length > 15;
  
  /// Get normalized text (য়, ড়, ঢ় as composed characters)
  String get normalizedText => BengaliNormalizer.normalize(text);
  
  /// Create a copy with normalized text
  Exercise normalize() => Exercise(
    text: BengaliNormalizer.normalize(text),
    repetitions: repetitions,
    type: type,
    difficultyLevel: difficultyLevel,
    source: source,
  );
}

/// Types of typing exercises
enum ExerciseType {
  /// Standard single-line typing exercise
  standard,

  /// Multi-line paragraph for extended typing practice
  paragraph,

  /// Specialized drill focusing on specific key combinations
  drill,

  /// Quote from literature or famous person
  quote,

  /// Business or professional content
  business
}

class Lesson {
  final String title;
  final String description;
  final List<Exercise> exercises;
  final String? category;
  final int difficultyLevel;
  final String language;
  final bool isNumpad; // true for numpad-only lessons

  const Lesson({
    required this.title,
    required this.description,
    required this.exercises,
    this.category,
    this.difficultyLevel = 1,
    this.language = 'bn', // Default to Bangla
    this.isNumpad = false,
  });

  /// Check if this lesson contains paragraph exercises
  bool get hasParagraphs => exercises.any((exercise) => exercise.isParagraph);

  /// Get the average difficulty level of all exercises
  int get averageDifficulty {
    if (exercises.isEmpty) return difficultyLevel;
    final sum = exercises.fold<int>(
        0, (sum, exercise) => sum + exercise.difficultyLevel);
    return (sum / exercises.length).round();
  }
  
  /// Create a copy with normalized exercises
  Lesson normalize() => Lesson(
    title: title,
    description: description,
    exercises: exercises.map((e) => e.normalize()).toList(),
    category: category,
    difficultyLevel: difficultyLevel,
    language: language,
    isNumpad: isNumpad,
  );
}

/// Normalize all lessons in a list (handles য়, ড়, ঢ় Unicode forms)
List<Lesson> normalizeLessons(List<Lesson> lessons) {
  return lessons.map((lesson) => lesson.normalize()).toList();
}
