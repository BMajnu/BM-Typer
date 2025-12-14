import 'package:bm_typer/core/models/lesson_model.dart';
import 'package:bm_typer/data/english_paragraph_data.dart';
import 'package:bm_typer/data/bangla_lesson_data.dart' show realBanglaLessons;
import 'package:bm_typer/data/phonetic_lesson_data.dart' show phoneticBanglaLessons;

// ignore_for_file: prefer_const_constructors

// Bangla lessons
final List<Lesson> banglaLessons = [
  Lesson(
    title: "lesson_1_1", // Translation key for "পাঠ ১.১: হোম রো (বাম হাত)"
    description: "home_row_left_hand", // Translation key
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
          text: "asdfg asdfg",
          repetitions: 10,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "sad dad fad gas sag",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "a sad dad; a glad fad",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "fads gags dads sags",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "add a gaff; add a gag",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
    ],
  ),
  Lesson(
    title: "lesson_1_2", // Translation key for "পাঠ ১.২: হোম রো (ডান হাত)"
    description: "home_row_right_hand", // Translation key
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
          text: "jkl; jkl;",
          repetitions: 10,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "jak lad hal jak",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "a jak; a lad; a hal",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "ask flask task flask",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "all fall hall; all fall",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
    ],
  ),
  Lesson(
    title: "lesson_2", // Translation key for "পাঠ ২: উপরের সারি"
    description: "upper_row", // Translation key
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
          text: "qwerty qwerty",
          repetitions: 10,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "we were wet; we were wet",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "quit quiet quip; quit quiet",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "you your you; you your you",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "type trip try; type trip try",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
    ],
  ),
  Lesson(
    title: "lesson_3", // Translation key for "পাঠ ৩: নিচের সারি"
    description: "lower_row", // Translation key
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
          text: "zxcvbnm zxcvbnm",
          repetitions: 10,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "zoo zebra zap; zoo zebra zap",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "box next mix; box next mix",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "car cat cab; car cat cab",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
      Exercise(
          text: "van vet very; van vet very",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 1),
    ],
  ),
  Lesson(
    title: "lesson_4", // Translation key for "পাঠ ৪: সাধারণ শব্দ"
    description: "common_words", // Translation key
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
          text: "the and that was his with they",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 2),
      Exercise(
          text: "for are but had has have him",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 2),
      Exercise(
          text: "not she this which you your will",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 2),
      Exercise(
          text: "one all were when there can more",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 2),
      Exercise(
          text: "if no man out time up very who",
          repetitions: 5,
          type: ExerciseType.drill,
          difficultyLevel: 2),
    ],
  ),
  Lesson(
    title: "lesson_5", // Translation key for "পাঠ ৫: সাধারণ বাক্য"
    description: "common_sentences", // Translation key
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "The quick brown fox jumps over the lazy dog.",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "A journey of a thousand miles begins with a single step.",
        repetitions: 5,
        type: ExerciseType.quote,
        difficultyLevel: 2,
        source: "Lao Tzu",
      ),
      Exercise(
        text: "To be or not to be, that is the question.",
        repetitions: 5,
        type: ExerciseType.quote,
        difficultyLevel: 2,
        source: "William Shakespeare, Hamlet",
      ),
      Exercise(
        text: "All that glitters is not gold.",
        repetitions: 5,
        type: ExerciseType.quote,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "The early bird catches the worm.",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),
];

// Combined lessons (Real Bangla + Keyboard Practice + English)
final List<Lesson> lessons = [
  ...realBanglaLessons, // প্রকৃত বাংলা টাইপিং lessons
  ...phoneticBanglaLessons, // Phonetic Typing lessons
  ...banglaLessons, // Keyboard drill lessons (English keys)
  ...englishLessons, // English paragraph lessons
];
