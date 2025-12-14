import 'package:bm_typer/core/models/lesson_model.dart';

// Progressive Bijoy Bangla Lessons (Row-by-Row)
final List<Lesson> realBanglaLessons = [
  // ==================================================================================
  // HOME ROW
  // ==================================================================================
  
  // Lesson 1: Home Row (Normal State)
  // Keys: a s d f g h j k l ; '
  // Bijoy: ৃ ু ি া ্ ব ক ত দ ; '
  Lesson(
    title: "bangla_home_row_normal",
    description: "practice_home_row_chars",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "ক ত দ ব",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "া ি ু ৃ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "কদ বা দি দু",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "বাবা দাদু কাকা",
        repetitions: 10,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // Lesson 2: Home Row (Shift State)
  // Keys: A S D F G H J K L : "
  // Bijoy: র্ ূ ী অ । ভ খ থ ধ : "
  Lesson(
    title: "bangla_home_row_shift",
    description: "practice_home_row_shift_chars",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "খ থ ধ ভ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "অ । র্ ূ ী",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "খুই থই ধুই",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // TOP ROW
  // ==================================================================================

  // Lesson 3: Top Row (Normal State)
  // Keys: q w e r t y u i o p
  // Bijoy: ঙ য ড প ট চ জ হ গ ড়
  Lesson(
    title: "bangla_top_row_normal",
    description: "practice_top_row_chars",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "প ট চ জ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "হ গ ড় ড",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "পচ টগ জহ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "গরম জল দিও",
        repetitions: 10,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // Lesson 4: Top Row (Shift State)
  // Keys: Q W E R T Y U I O P
  // Bijoy: ং য় ঢ ফ ঠ ছ ঝ ঞ ঘ ঢ়
  Lesson(
    title: "bangla_top_row_shift",
    description: "practice_top_row_shift_chars",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "ফ ঠ ছ ঝ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঘ ঢ় ঞ য় ং",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঝড় মেঘ রং",
        repetitions: 10,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // BOTTOM ROW
  // ==================================================================================

  // Lesson 5: Bottom Row (Normal State)
  // Keys: z x c v b n m , . /
  // Bijoy: ্র ও ে র ন স ম , । /
  Lesson(
    title: "bangla_bottom_row_normal",
    description: "practice_bottom_row_chars",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "ন স ম র",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ও ে ্র",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "মনে করো সব",
        repetitions: 10,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // Lesson 6: Bottom Row (Shift State)
  // Keys: Z X C V B N M < > ?
  // Bijoy: ্য ঔ ৈ ল ণ ষ শ ৎ ঃ ?
  Lesson(
    title: "bangla_bottom_row_shift",
    description: "practice_bottom_row_shift_chars",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "শ ষ ণ ল",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঔ ৈ ্য",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "শেষ ফল",
        repetitions: 10,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),
  
  // ==================================================================================
  // FULL VOWELS (SWOROBORNO) - Using Composite Logic
  // ==================================================================================
  
  // Lesson 7: Vowels (Composites)
  // Teaching g + KEY
  Lesson(
    title: "bangla_vowels_composite",
    description: "practice_full_vowels",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "অ আ ই ঈ উ ঊ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঋ এ ঐ ও ঔ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "আমাদের ইমান উনুন",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),
];
