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

  const Lesson({
    required this.title,
    required this.description,
    required this.exercises,
    this.category,
    this.difficultyLevel = 1,
    this.language = 'bn', // Default to Bangla
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
}
