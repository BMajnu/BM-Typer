import 'package:bm_typer/core/models/lesson_model.dart';
import 'package:bm_typer/data/english_paragraph_data.dart';
import 'package:bm_typer/data/bangla_lesson_data.dart' show realBanglaLessons;
import 'package:bm_typer/data/phonetic_lesson_data.dart' show phoneticBanglaLessons;

// ignore_for_file: prefer_const_constructors

// ============================================================
// LESSON STRUCTURE: 
// লেসন ১-৬: English Keyboard Mastery
// লেসন ৭-২৪: Bangla Bijoy Typing (from bangla_lesson_data.dart)
// লেসন ২৫+: Phonetic Bangla Typing
// ============================================================

// --- ENGLISH KEYBOARD MASTERY LESSONS (লেসন ১-৬) ---
final List<Lesson> englishKeyboardLessons = [
  Lesson(
    title: "লেসন ১: হোম রো (ASDF-JKL;)",
    description: "ইংরেজি কীবোর্ডের প্রধান সারি শিখুন - এটি আপনার আঙ্গুলের স্থায়ী অবস্থান",
    category: "English",
    language: "en",
    difficultyLevel: 1,
    exercises: [
      Exercise(text: "asdf jkl;", repetitions: 30, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "aaa sss ddd fff", repetitions: 24, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "jjj kkk lll ;;;", repetitions: 24, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "sad dad fad gas", repetitions: 18, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "ask flask task", repetitions: 18, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "a glad lad; a sad dad", repetitions: 15, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "all fall hall shall", repetitions: 15, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "add salad; fall flask", repetitions: 15, type: ExerciseType.drill, difficultyLevel: 1),
    ],
  ),
  Lesson(
    title: "লেসন ২: উপরের সারি (QWERTY)",
    description: "উপরের সারির কীগুলো শিখুন - দ্রুত টাইপিংয়ের জন্য গুরুত্বপূর্ণ",
    category: "English",
    language: "en",
    difficultyLevel: 1,
    exercises: [
      Exercise(text: "qwert yuiop", repetitions: 30, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "qqq www eee rrr ttt", repetitions: 24, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "yyy uuu iii ooo ppp", repetitions: 24, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "we were wet", repetitions: 18, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "quit quiet quip", repetitions: 18, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "your type trip", repetitions: 15, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "power tower tower", repetitions: 15, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "query quite quote", repetitions: 15, type: ExerciseType.drill, difficultyLevel: 1),
    ],
  ),
  Lesson(
    title: "লেসন ৩: নিচের সারি (ZXCVBNM)",
    description: "নিচের সারির কীগুলো আয়ত্ত করুন - সম্পূর্ণ কীবোর্ড নিয়ন্ত্রণ",
    category: "English",
    language: "en",
    difficultyLevel: 1,
    exercises: [
      Exercise(text: "zxcvb nm,./", repetitions: 30, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "zzz xxx ccc vvv bbb", repetitions: 24, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "nnn mmm ,,, ... ///", repetitions: 24, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "zoo zebra zap", repetitions: 18, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "box next mix", repetitions: 18, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "car cat cab van", repetitions: 15, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "come become welcome", repetitions: 15, type: ExerciseType.drill, difficultyLevel: 1),
      Exercise(text: "never move above", repetitions: 15, type: ExerciseType.drill, difficultyLevel: 1),
    ],
  ),
  Lesson(
    title: "লেসন ৪: সংখ্যা ও চিহ্ন (1234567890)",
    description: "নম্বর সারি এবং বিশেষ চিহ্নগুলো শিখুন",
    category: "English",
    language: "en",
    difficultyLevel: 2,
    exercises: [
      Exercise(text: "1234567890", repetitions: 30, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "111 222 333 444 555", repetitions: 24, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "666 777 888 999 000", repetitions: 24, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "12 34 56 78 90", repetitions: 18, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "100 200 300 400 500", repetitions: 18, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "2024 2025 2030", repetitions: 15, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "Phone: 0123456789", repetitions: 15, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "ID: 1234; PIN: 5678", repetitions: 15, type: ExerciseType.drill, difficultyLevel: 2),
    ],
  ),
  Lesson(
    title: "লেসন ৫: সাধারণ ইংরেজি শব্দ",
    description: "সবচেয়ে বেশি ব্যবহৃত ইংরেজি শব্দগুলো দ্রুত টাইপ করুন",
    category: "English",
    language: "en",
    difficultyLevel: 2,
    exercises: [
      Exercise(text: "the and that was his", repetitions: 9, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "for are but had have", repetitions: 9, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "not she this which you", repetitions: 8, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "one all were when there", repetitions: 8, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "can more if no man out", repetitions: 8, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "time up very who now", repetitions: 8, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "people my over know down", repetitions: 8, type: ExerciseType.drill, difficultyLevel: 2),
      Exercise(text: "after first also made did", repetitions: 8, type: ExerciseType.drill, difficultyLevel: 2),
    ],
  ),
  Lesson(
    title: "লেসন ৬: ইংরেজি বাক্য ও উক্তি",
    description: "বিখ্যাত উক্তি ও বাক্য টাইপ করে দক্ষতা বাড়ান",
    category: "English",
    language: "en",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "The quick brown fox jumps over the lazy dog.",
        repetitions: 8, type: ExerciseType.standard, difficultyLevel: 2,
      ),
      Exercise(
        text: "A journey of a thousand miles begins with a single step.",
        repetitions: 8, type: ExerciseType.quote, difficultyLevel: 2, source: "Lao Tzu",
      ),
      Exercise(
        text: "To be or not to be, that is the question.",
        repetitions: 8, type: ExerciseType.quote, difficultyLevel: 2, source: "Shakespeare",
      ),
      Exercise(
        text: "All that glitters is not gold.",
        repetitions: 8, type: ExerciseType.standard, difficultyLevel: 2,
      ),
      Exercise(
        text: "The early bird catches the worm.",
        repetitions: 8, type: ExerciseType.standard, difficultyLevel: 2,
      ),
      Exercise(
        text: "Practice makes perfect.",
        repetitions: 8, type: ExerciseType.standard, difficultyLevel: 2,
      ),
      Exercise(
        text: "Knowledge is power.",
        repetitions: 8, type: ExerciseType.quote, difficultyLevel: 2, source: "Francis Bacon",
      ),
      Exercise(
        text: "Actions speak louder than words.",
        repetitions: 8, type: ExerciseType.standard, difficultyLevel: 2,
      ),
    ],
  ),
  
  // --- LESSON 7: TechZone IT - Professional Paragraph Practice ---
  Lesson(
    title: "Lesson 7: TechZone IT - Professional Paragraph",
    description: "Practice typing professional business descriptions about TechZone IT",
    category: "English",
    language: "en",
    difficultyLevel: 3,
    exercises: [
      Exercise(
        text: "TechZone IT, strategically located in Aditmari, Lalmonirhat, operates on the profound philosophy of providing All Technology Solutions in One Place.",
        repetitions: 5, type: ExerciseType.paragraph, difficultyLevel: 3,
      ),
      Exercise(
        text: "It is not merely a conventional computer hardware store but a holistic digital ecosystem designed to cater to every conceivable technological requirement of its clientele.",
        repetitions: 5, type: ExerciseType.paragraph, difficultyLevel: 3,
      ),
      Exercise(
        text: "Its foundation is built upon a robust sales division offering everything from high-performance custom PC builds utilizing the latest Intel and AMD Ryzen processors.",
        repetitions: 5, type: ExerciseType.paragraph, difficultyLevel: 3,
      ),
      Exercise(
        text: "TechZone IT retails renowned branded laptops from industry giants like HP, Dell, Acer, and Lenovo, alongside an exhaustive array of essential computing components.",
        repetitions: 5, type: ExerciseType.paragraph, difficultyLevel: 3,
      ),
      Exercise(
        text: "The inventory includes SSDs, RAM, motherboards, processors, PSUs, gaming casings, coolers, monitors, keyboards, mice, and sound systems.",
        repetitions: 5, type: ExerciseType.paragraph, difficultyLevel: 3,
      ),
      Exercise(
        text: "Beyond core computing hardware, TechZone IT stands as a reliable destination for imaging and documentation solutions from leading brands like Epson, HP, Canon, Brother, and Pantum.",
        repetitions: 5, type: ExerciseType.paragraph, difficultyLevel: 3,
      ),
      Exercise(
        text: "Experienced technicians meticulously handle complex hardware repairs for desktops and laptops, perform critical data recovery operations from corrupted storage devices.",
        repetitions: 5, type: ExerciseType.paragraph, difficultyLevel: 3,
      ),
      Exercise(
        text: "TechZone IT truly embodies the essence of a One-Stop technology service provider through a unique synthesis of hardware, software, servicing, networking, and skill development.",
        repetitions: 5, type: ExerciseType.paragraph, difficultyLevel: 3,
      ),
      Exercise(
        text: "TechZone IT offers comprehensive training programs ranging from basic computer and office applications to all categories of freelancing.",
        repetitions: 5, type: ExerciseType.paragraph, difficultyLevel: 3,
      ),
      Exercise(
        text: "Training courses include Graphic Design, Web Development, Programming, Custom App Development, Bug Fixing, and Digital Marketing.",
        repetitions: 5, type: ExerciseType.paragraph, difficultyLevel: 3,
      ),
      Exercise(
        text: "Additionally, modern courses on AI and Automation are provided, helping young professionals build future-ready careers in technology.",
        repetitions: 5, type: ExerciseType.paragraph, difficultyLevel: 3,
      ),
    ],
  ),
];

// ============================================================
// COMBINED LESSONS - Final Export
// Order: English (১-৬) → Bijoy Bangla (৭-২৪) → Phonetic (২৫+)
// NO DUPLICATES - banglaBijoyLessons removed (content in realBanglaLessons)
// ============================================================
final List<Lesson> lessons = [
  ...englishKeyboardLessons,  // লেসন ১-৬: English Keyboard Mastery
  ...realBanglaLessons,       // লেসন ৭-২৪: Bangla Bijoy Typing (all renamed in Bengali)
  ...phoneticBanglaLessons,   // লেসন ২৫+: Phonetic Bangla Typing
  ...englishLessons,          // Additional English paragraph lessons
];


