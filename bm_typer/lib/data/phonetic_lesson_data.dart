import 'package:bm_typer/core/models/lesson_model.dart';

/// Phonetic Bangla Typing Lessons (Avro Style)
final List<Lesson> phoneticBanglaLessons = [
  // Lesson 1: Vowels (Short)
  Lesson(
    title: "phonetic_lesson_1",
    description: "phonetic_vowels_short",
    category: "Bangla (Phonetic)",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "o a i u e O",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ama ami tumi",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "alo alu iti",
        repetitions: 5,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
    ],
  ),

  // Lesson 2: Vowels (Shifted/Long)
  Lesson(
    title: "phonetic_lesson_2",
    description: "phonetic_vowels_long",
    category: "Bangla (Phonetic)",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "A I U E O",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "Ai Oi Ou",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
    ],
  ),

  // Lesson 3: Consonants (Base)
  Lesson(
    title: "phonetic_lesson_3",
    description: "phonetic_consonants_base",
    category: "Bangla (Phonetic)",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "k g c j T D N t",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "d n p f b v m",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "z r l S s h R y",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
    ],
  ),
  
  // Lesson 4: Consonants (Shifted/Aspirated)
  Lesson(
    title: "phonetic_lesson_4",
    description: "phonetic_consonants_aspirated",
    category: "Bangla (Phonetic)",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "K G C J T D",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "B M S H",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
    ],
  ),
  
  // Lesson 5: Simple Words (Phonetic)
  Lesson(
    title: "phonetic_lesson_5",
    description: "phonetic_simple_words",
    category: "Bangla (Phonetic)",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "amar sonar bangla",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ami tomay valobasi",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "kothay jabe tumi",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),
];
