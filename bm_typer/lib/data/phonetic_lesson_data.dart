import 'package:bm_typer/core/models/lesson_model.dart';

// Progressive Phonetic (Avro-style) Bangla Lessons (Row-by-Row)
// Mapped to QWERTY keys but teaching the Bengali output

final List<Lesson> phoneticBanglaLessons = [
  // ==================================================================================
  // HOME ROW
  // ==================================================================================
  
  // Lesson 1: Home Row (Normal State)
  // Keys: a(আ/া) s(স) d(দ) f(ফ) g(গ) h(হ) j(জ) k(ক) l(ল)
  // Phonetic Mappings (approximate for drill):
  // a=আ, s=স, d=দ, f=ফ, g=গ, h=হ, j=জ, k=ক, l=ল
  Lesson(
    title: "phonetic_home_row_normal",
    description: "practice_phonetic_home_row",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "ক জ হ গ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ফ দ স আ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "সদ গদ হক",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "কাজ সহল দাদা",
        repetitions: 10,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // Lesson 2: Home Row (Shift State)
  // Keys: A(অ) S(শ) D(ড) F(উ) G(ঘ) H(ঝ) J(ঝ-alt) K(খ) L(ল)
  // Note: Mappings depend on exact Phonetic Layout implementation in keyboard_layouts.dart
  // Let's assume standard Avro-like:
  // K=ক, Shift+K=খ
  // G=গ, Shift+G=ঘ
  // J=জ, Shift+J=ঝ
  // D=দ, Shift+D=ড
  // S=স, Shift+S=শ
  Lesson(
    title: "phonetic_home_row_shift",
    description: "practice_phonetic_home_row_shift",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "খ ঝ ঘ ড শ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "অ আ ই ঈ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "শখ ঝগড়া",
        repetitions: 10,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // TOP ROW
  // ==================================================================================

  // Lesson 3: Top Row (Normal)
  // q(্) w(ঊ) e(এ) r(র) t(ট) y(য়) u(উ) i(ই) o(ও) p(প)
  Lesson(
    title: "phonetic_top_row_normal",
    description: "practice_phonetic_top_row",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "প ও ই উ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "য় ট র এ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "পর ওই",
        repetitions: 10,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // Lesson 4: Top Row (Shift)
  // Q(ং) W(ঊ) E(ঐ) R(ড়) T(ঠ) Y(য়) U(ঊ) I(ঈ) O(ঔ) P(ফ)
  Lesson(
    title: "phonetic_top_row_shift",
    description: "practice_phonetic_top_row_shift",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "ফ ঔ ঈ ঊ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "য় ঠ ড় ঐ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঐরাবত ঔষুধ",
        repetitions: 10,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // BOTTOM ROW
  // ==================================================================================

  // Lesson 5: Bottom Row (Normal)
  // z(য) x(ক্স) c(চ) v(ভ) b(ব) n(ন) m(ম)
  Lesson(
    title: "phonetic_bottom_row_normal",
    description: "practice_phonetic_bottom_row",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "ম ন ব ভ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "চ য",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "মন জন বন",
        repetitions: 10,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // Lesson 6: Bottom Row (Shift)
  // Z(য) X(ক্স) C(ছ) V(ভ) B(ভ) N(ণ) M(ম)
  Lesson(
    title: "phonetic_bottom_row_shift",
    description: "practice_phonetic_bottom_row_shift",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "ণ ভ ছ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "চরণ মরণ",
        repetitions: 10,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),
];
