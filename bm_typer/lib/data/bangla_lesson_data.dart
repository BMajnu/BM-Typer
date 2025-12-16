import 'package:bm_typer/core/models/lesson_model.dart';

// ================================================================
// বাংলা বিজয় কীবোর্ড লেসন
// QWERTY কীবোর্ড লেআউটের ক্রম অনুসারে সাজানো
// হোম রো → উপরের সারি → নিচের সারি
// প্রতিটি সারিতে: বাম হাত → ডান হাত, Normal → Shift
// ================================================================

final List<Lesson> realBanglaLessons = [
  // ==================================================================================
  // লেসন ৭: হোম রো - বাম হাত (A S D F G) - Normal
  // Bijoy: A=ৃ, S=ু, D=ি, F=া, G=্
  // ==================================================================================
  Lesson(
    title: "লেসন ৭: হোম রো বাম হাত (ৃ ু ি া ্)",
    description: "বিজয় কীবোর্ডের হোম রো - বাম হাতের কী (A S D F G)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      // Individual keys
      Exercise(
        text: "ৃ ৃ ৃ ৃ ৃ",  // A key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ু ু ু ু ু",  // S key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ি ি ি ি ি",  // D key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "া া া া া",  // F key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "্ ্ ্ ্ ্",  // G key (hasanta)
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      // Combined practice
      Exercise(
        text: "ৃ ু ি া ্",  // A S D F G sequence
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "া ি ু ৃ ্ া ি",  // F D S A G F D
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৮: হোম রো - ডান হাত (H J K L ;) - Normal
  // Bijoy: H=ব, J=ক, K=ত, L=দ
  // ==================================================================================
  Lesson(
    title: "লেসন ৮: হোম রো ডান হাত (ব ক ত দ)",
    description: "বিজয় কীবোর্ডের হোম রো - ডান হাতের কী (H J K L)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "ব ব ব ব ব",  // H key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ক ক ক ক ক",  // J key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ত ত ত ত ত",  // K key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "দ দ দ দ দ",  // L key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      // Combined practice
      Exercise(
        text: "ব ক ত দ",  // H J K L sequence
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "কদ তব দক বত",  // J L K H L J H K
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      // Words using home row right hand
      Exercise(
        text: "কত বদ তক",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৯: হোম রো সম্পূর্ণ (Normal) - উভয় হাত একত্রে
  // A S D F G + H J K L → ৃ ু ি া ্ ব ক ত দ
  // ==================================================================================
  Lesson(
    title: "লেসন ৯: হোম রো সম্পূর্ণ (ৃ ু ি া ্ ব ক ত দ)",
    description: "হোম রো-এর সব কী একত্রে অনুশীলন করুন",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "ৃ ু ি া ্ ব ক ত দ",  // Full home row
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "কা তা দা বা",  // J+F, K+F, L+F, H+F
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "কি তি দি বি",  // J+D, K+D, L+D, H+D
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "কু তু দু বু",  // J+S, K+S, L+S, H+S
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      // Simple words
      Exercise(
        text: "কাক দাদ বাবা তাত",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "কাদা দাতা বাতা",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ১০: হোম রো - বাম হাত (Shift) - A S D F G
  // Bijoy Shift: A=র্, S=ূ, D=ী, F=অ, G=।
  // ==================================================================================
  Lesson(
    title: "লেসন ১০: হোম রো বাম হাত - শিফট (র্ ূ ী অ ।)",
    description: "শিফট সহ হোম রো বাম হাত (Shift + A S D F G)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "র্ র্ র্ র্ র্",  // Shift+A (reph)
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ূ ূ ূ ূ ূ",  // Shift+S
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ী ী ী ী ী",  // Shift+D
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "অ অ অ অ অ",  // Shift+F
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "। । । । ।",  // Shift+G (dari)
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "র্ ূ ী অ ।",  // Shift + A S D F G sequence
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ১১: হোম রো - ডান হাত (Shift) - H J K L
  // Bijoy Shift: H=ভ, J=খ, K=থ, L=ধ
  // ==================================================================================
  Lesson(
    title: "লেসন ১১: হোম রো ডান হাত - শিফট (ভ খ থ ধ)",
    description: "শিফট সহ হোম রো ডান হাত (Shift + H J K L)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "ভ ভ ভ ভ ভ",  // Shift+H
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "খ খ খ খ খ",  // Shift+J
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "থ থ থ থ থ",  // Shift+K
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ধ ধ ধ ধ ধ",  // Shift+L
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ভ খ থ ধ",  // Shift + H J K L sequence
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      // Words with shift home row
      Exercise(
        text: "খাবা থালা ধান ভাত",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ১২: হোম রো সম্পূর্ণ (Shift)
  // ==================================================================================
  Lesson(
    title: "লেসন ১২: হোম রো সম্পূর্ণ - শিফট",
    description: "শিফট সহ হোম রো-এর সব কী একত্রে",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "র্ ূ ী অ । ভ খ থ ধ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "খী থী ধী ভী",  // Shift combos
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "খূ থূ ধূ ভূ",
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "অধীন। খথধভ।",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ১৩: উপরের সারি - বাম হাত (Q W E R T) - Normal
  // Bijoy: Q=ঙ, W=য, E=ড, R=প, T=ট
  // ==================================================================================
  Lesson(
    title: "লেসন ১৩: উপরের সারি বাম হাত (ঙ য ড প ট)",
    description: "বিজয় কীবোর্ডের উপরের সারি - বাম হাত (Q W E R T)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "ঙ ঙ ঙ ঙ ঙ",  // Q key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "য য য য য",  // W key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ড ড ড ড ড",  // E key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "প প প প প",  // R key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ট ট ট ট ট",  // T key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ঙ য ড প ট",  // Q W E R T sequence
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ১৪: উপরের সারি - ডান হাত (Y U I O P) - Normal
  // Bijoy: Y=চ, U=জ, I=হ, O=গ, P=ড়
  // ==================================================================================
  Lesson(
    title: "লেসন ১৪: উপরের সারি ডান হাত (চ জ হ গ ড়)",
    description: "বিজয় কীবোর্ডের উপরের সারি - ডান হাত (Y U I O P)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "চ চ চ চ চ",  // Y key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "জ জ জ জ জ",  // U key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "হ হ হ হ হ",  // I key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "গ গ গ গ গ",  // O key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ড় ড় ড় ড় ড়",  // P key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "চ জ হ গ ড়",  // Y U I O P sequence
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      // Simple words
      Exercise(
        text: "চা জা হা গা",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ১৫: উপরের সারি সম্পূর্ণ (Normal)
  // ==================================================================================
  Lesson(
    title: "লেসন ১৫: উপরের সারি সম্পূর্ণ",
    description: "উপরের সারির সব কী একত্রে অনুশীলন",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "ঙ য ড প ট চ জ হ গ ড়",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "পা টা চা জা হা গা",
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "পাখি গরু জল",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ১৬: উপরের সারি - বাম হাত (Shift)
  // Bijoy Shift: Q=ং, W=য়, E=ঢ, R=ফ, T=ঠ
  // ==================================================================================
  Lesson(
    title: "লেসন ১৬: উপরের সারি বাম হাত - শিফট (ং য় ঢ ফ ঠ)",
    description: "শিফট সহ উপরের সারি বাম হাত (Shift + Q W E R T)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "ং ং ং ং ং",  // Shift+Q
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "য় য় য় য় য়",  // Shift+W
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঢ ঢ ঢ ঢ ঢ",  // Shift+E
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ফ ফ ফ ফ ফ",  // Shift+R
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঠ ঠ ঠ ঠ ঠ",  // Shift+T
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ং য় ঢ ফ ঠ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ১৭: উপরের সারি - ডান হাত (Shift)
  // Bijoy Shift: Y=ছ, U=ঝ, I=ঞ, O=ঘ, P=ঢ়
  // ==================================================================================
  Lesson(
    title: "লেসন ১৭: উপরের সারি ডান হাত - শিফট (ছ ঝ ঞ ঘ ঢ়)",
    description: "শিফট সহ উপরের সারি ডান হাত (Shift + Y U I O P)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "ছ ছ ছ ছ ছ",  // Shift+Y
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঝ ঝ ঝ ঝ ঝ",  // Shift+U
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঞ ঞ ঞ ঞ ঞ",  // Shift+I
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঘ ঘ ঘ ঘ ঘ",  // Shift+O
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঢ় ঢ় ঢ় ঢ় ঢ়",  // Shift+P
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ছ ঝ ঞ ঘ ঢ়",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঝড় মেঘ ছবি",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ১৮: নিচের সারি - বাম হাত (Z X C V B) - Normal
  // Bijoy: Z=্র, X=ও, C=ে, V=র, B=ন
  // ==================================================================================
  Lesson(
    title: "লেসন ১৮: নিচের সারি বাম হাত (্র ও ে র ন)",
    description: "বিজয় কীবোর্ডের নিচের সারি - বাম হাত (Z X C V B)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "্র ্র ্র ্র ্র",  // Z key (ro-fola)
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ও ও ও ও ও",  // X key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ে ে ে ে ে",  // C key (e-kar)
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "র র র র র",  // V key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ন ন ন ন ন",  // B key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "্র ও ে র ন",  // Z X C V B sequence
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ১৯: নিচের সারি - ডান হাত (N M , . /) - Normal
  // Bijoy: N=স, M=ম
  // ==================================================================================
  Lesson(
    title: "লেসন ১৯: নিচের সারি ডান হাত (স ম)",
    description: "বিজয় কীবোর্ডের নিচের সারি - ডান হাত (N M)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "স স স স স",  // N key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ম ম ম ম ম",  // M key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "স ম স ম স ম",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "সম নম রম",
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "মন সন নাম",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ২০: নিচের সারি সম্পূর্ণ (Normal)
  // ==================================================================================
  Lesson(
    title: "লেসন ২০: নিচের সারি সম্পূর্ণ",
    description: "নিচের সারির সব কী একত্রে অনুশীলন",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "্র ও ে র ন স ম",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "রে নে সে মে",
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "মনে করো সব",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ২১: নিচের সারি - বাম হাত (Shift)
  // Bijoy Shift: Z=্য, X=ঔ, C=ৈ, V=ল, B=ণ
  // ==================================================================================
  Lesson(
    title: "লেসন ২১: নিচের সারি বাম হাত - শিফট (্য ঔ ৈ ল ণ)",
    description: "শিফট সহ নিচের সারি বাম হাত (Shift + Z X C V B)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "্য ্য ্য ্য ্য",  // Shift+Z (jo-fola)
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঔ ঔ ঔ ঔ ঔ",  // Shift+X
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ৈ ৈ ৈ ৈ ৈ",  // Shift+C (oi-kar)
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ল ল ল ল ল",  // Shift+V
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ণ ণ ণ ণ ণ",  // Shift+B
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "্য ঔ ৈ ল ণ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ২২: নিচের সারি - ডান হাত (Shift)
  // Bijoy Shift: N=ষ, M=শ, <=ৎ, >=ঃ
  // ==================================================================================
  Lesson(
    title: "লেসন ২২: নিচের সারি ডান হাত - শিফট (ষ শ ৎ ঃ)",
    description: "শিফট সহ নিচের সারি ডান হাত (Shift + N M < >)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "ষ ষ ষ ষ ষ",  // Shift+N
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "শ শ শ শ শ",  // Shift+M
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ৎ ৎ ৎ ৎ ৎ",  // Shift+<
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঃ ঃ ঃ ঃ ঃ",  // Shift+>
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ষ শ ৎ ঃ",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "শিক্ষা ষষ্ঠ",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ২৩: সংখ্যা সারি
  // ==================================================================================
  Lesson(
    title: "লেসন ২৩: বাংলা সংখ্যা (১ ২ ৩ ৪ ৫ ৬ ৭ ৮ ৯ ০)",
    description: "বাংলা সংখ্যা টাইপ করুন (1-0 keys)",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "১ ২ ৩ ৪ ৫",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "৬ ৭ ৮ ৯ ০",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "১২৩৪৫৬৭৮৯০",
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "২০২৫ ১৯৭১",
        repetitions: 5,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ২৪: স্বরবর্ণ কম্পোজিশন (G + vowel key)
  // ==================================================================================
  Lesson(
    title: "লেসন ২৪: পূর্ণ স্বরবর্ণ (G + কার = স্বর)",
    description: "G + কার কী = পূর্ণ স্বরবর্ণ শিখুন",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "আ আ আ আ আ",  // G+F = আ
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ই ই ই ই ই",  // G+D = ই
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "উ উ উ উ উ",  // G+S = উ
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "এ এ এ এ এ",  // G+C = এ
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
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
        text: "আম ইট উট এক ঐক্য",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ২৫: যুক্তাক্ষর - প্রাথমিক
  // ==================================================================================
  Lesson(
    title: "লেসন ২৫: যুক্তাক্ষর - প্রাথমিক (ক্ত ন্ত স্ত)",
    description: "সাধারণ যুক্তাক্ষর অনুশীলন",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 3,
    exercises: [
      Exercise(
        text: "ক্ত ক্ত ক্ত ক্ত",
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 3,
      ),
      Exercise(
        text: "ন্ত ন্ত ন্ত ন্ত",
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 3,
      ),
      Exercise(
        text: "স্ত স্ত স্ত স্ত",
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 3,
      ),
      Exercise(
        text: "ক্ত ন্ত স্ত ত্ত",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 3,
      ),
      Exercise(
        text: "শক্তি অন্ত মাস্তান",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 3,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ২৬: বাংলা বাক্য অনুশীলন
  // ==================================================================================
  Lesson(
    title: "লেসন ২৬: বাংলা বাক্য অনুশীলন",
    description: "সম্পূর্ণ বাংলা বাক্য টাইপ করুন",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 3,
    exercises: [
      Exercise(
        text: "আমি বাংলায় গান গাই।",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 3,
      ),
      Exercise(
        text: "বাংলাদেশ আমার দেশ।",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 3,
      ),
      Exercise(
        text: "আজ আকাশ নীল।",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 3,
      ),
      Exercise(
        text: "পাখি গাছে বসে গান করে।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 3,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ২৭: বাংলা অনুচ্ছেদ অনুশীলন
  // ==================================================================================
  Lesson(
    title: "লেসন ২৭: বাংলা অনুচ্ছেদ অনুশীলন",
    description: "দীর্ঘ বাংলা অনুচ্ছেদ টাইপ করে দক্ষতা বাড়ান",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 3,
    exercises: [
      Exercise(
        text: "বাংলাদেশ দক্ষিণ এশিয়ার একটি স্বাধীন সার্বভৌম রাষ্ট্র। ১৯৭১ সালে মুক্তিযুদ্ধের মাধ্যমে বাংলাদেশ স্বাধীন হয়।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 3,
      ),
      Exercise(
        text: "ঢাকা বাংলাদেশের রাজধানী এবং বৃহত্তম শহর। এটি বুড়িগঙ্গা নদীর তীরে অবস্থিত।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 3,
      ),
      Exercise(
        text: "বাংলা ভাষা বাংলাদেশের রাষ্ট্রভাষা। একুশে ফেব্রুয়ারি আন্তর্জাতিক মাতৃভাষা দিবস হিসেবে পালিত হয়।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 3,
      ),
      Exercise(
        text: "পদ্মা, মেঘনা ও যমুনা বাংলাদেশের প্রধান নদী। এই নদীগুলো দেশের কৃষি ও অর্থনীতিতে গুরুত্বপূর্ণ ভূমিকা রাখে।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 3,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ২৮: বাংলা প্রবন্ধ ও সাহিত্য
  // ==================================================================================
  Lesson(
    title: "লেসন ২৮: বাংলা প্রবন্ধ ও সাহিত্য",
    description: "বাংলা সাহিত্যের উদ্ধৃতি ও প্রবন্ধ টাইপ করুন",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 4,
    exercises: [
      Exercise(
        text: "আমার সোনার বাংলা আমি তোমায় ভালোবাসি। চিরদিন তোমার আকাশ তোমার বাতাস আমার প্রাণে বাজায় বাঁশি।",
        repetitions: 3,
        type: ExerciseType.quote,
        difficultyLevel: 4,
        source: "রবীন্দ্রনাথ ঠাকুর",
      ),
      Exercise(
        text: "যেখানে দেখিবে ছাই, উড়াইয়া দেখ তাই, পাইলেও পাইতে পার অমূল্য রতন।",
        repetitions: 3,
        type: ExerciseType.quote,
        difficultyLevel: 4,
        source: "বাংলা প্রবাদ",
      ),
      Exercise(
        text: "শিক্ষা জাতির মেরুদণ্ড। শিক্ষা ছাড়া কোন জাতি উন্নতি করতে পারে না। তাই প্রত্যেক নাগরিকের শিক্ষিত হওয়া উচিত।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 4,
      ),
      Exercise(
        text: "সময় এবং স্রোত কারো জন্য অপেক্ষা করে না। সময়ের সঠিক ব্যবহার জীবনে সফলতা আনে।",
        repetitions: 3,
        type: ExerciseType.quote,
        difficultyLevel: 4,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ২৯: ব্যবসায়িক চিঠি ও দরখাস্ত
  // ==================================================================================
  Lesson(
    title: "লেসন ২৯: ব্যবসায়িক চিঠি ও দরখাস্ত",
    description: "অফিসিয়াল চিঠি ও দরখাস্ত লেখার অনুশীলন",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 4,
    exercises: [
      Exercise(
        text: "বরাবর, ব্যবস্থাপনা পরিচালক, বাংলাদেশ কম্পিউটার কাউন্সিল, ঢাকা।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 4,
      ),
      Exercise(
        text: "বিষয়: চাকরির জন্য আবেদন। জনাব, বিনীত নিবেদন এই যে, আমি আপনার প্রতিষ্ঠানে নিম্নলিখিত পদে চাকরির জন্য আবেদন করছি।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 4,
      ),
      Exercise(
        text: "আমি ঢাকা বিশ্ববিদ্যালয় থেকে কম্পিউটার সায়েন্স অ্যান্ড ইঞ্জিনিয়ারিং বিষয়ে স্নাতক ডিগ্রি অর্জন করেছি।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 4,
      ),
      Exercise(
        text: "অতএব, আমার আবেদন বিবেচনার জন্য অনুরোধ করছি। ধন্যবাদান্তে, আপনার একান্ত অনুগত।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 4,
      ),
      Exercise(
        text: "তারিখ: ১৫ ডিসেম্বর, ২০২৫। স্বাক্ষর: মোহাম্মদ আলী। ঠিকানা: বাড়ি নং ৪৫, রোড নং ১২, ঢাকা-১২১৫।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 4,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৩০: পেশাদার বাংলা টাইপিং
  // ==================================================================================
  Lesson(
    title: "লেসন ৩০: পেশাদার বাংলা টাইপিং",
    description: "পেশাদার মানের দ্রুত ও নির্ভুল বাংলা টাইপিং অনুশীলন",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 5,
    exercises: [
      Exercise(
        text: "তথ্য ও যোগাযোগ প্রযুক্তি বর্তমান বিশ্বে অত্যন্ত গুরুত্বপূর্ণ। কম্পিউটার ও ইন্টারনেট আমাদের জীবনযাত্রাকে সহজ করেছে।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
      Exercise(
        text: "বাংলাদেশ সরকার ডিজিটাল বাংলাদেশ গঠনে নিরলস কাজ করে যাচ্ছে। ২০৪১ সালের মধ্যে বাংলাদেশ একটি উন্নত দেশে পরিণত হবে।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
      Exercise(
        text: "ফ্রিল্যান্সিং এখন যুব সমাজের মধ্যে জনপ্রিয় পেশা। অনেক তরুণ-তরুণী ঘরে বসে আন্তর্জাতিক মানের কাজ করছে।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
      Exercise(
        text: "সফটওয়্যার ডেভেলপমেন্ট, গ্রাফিক ডিজাইন, ডাটা এন্ট্রি, ওয়েব ডেভেলপমেন্ট ইত্যাদি ক্ষেত্রে বাংলাদেশের তরুণরা দক্ষতার স্বাক্ষর রাখছে।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৩১: টেক জোন আইটি - পেশাদার অনুচ্ছেদ অনুশীলন
  // ==================================================================================
  Lesson(
    title: "লেসন ৩১: টেক জোন আইটি - পেশাদার অনুচ্ছেদ",
    description: "টেক জোন আইটি সম্পর্কে বিস্তারিত অনুচ্ছেদ টাইপ করুন",
    category: "Bangla",
    language: "bn",
    difficultyLevel: 5,
    exercises: [
      Exercise(
        text: "লালমনিরহাটের আদিতমারীতে অবস্থিত 'টেকজোন আইটি' সকল প্রযুক্তি সমাধান এক জায়গায় এই মূল দর্শনকে ধারণ করে পরিচালিত একটি অত্যাধুনিক প্রযুক্তি কেন্দ্র।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
      Exercise(
        text: "এটি কেবল একটি সাধারণ কম্পিউটার বিক্রয় কেন্দ্র নয়, বরং একটি পূর্ণাঙ্গ ডিজিটাল ইকোসিস্টেম যেখানে গ্রাহকের যেকোনো প্রযুক্তিগত চাহিদার সামগ্রিক সমাধান মেলে।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
      Exercise(
        text: "অত্যাধুনিক ইন্টেল বা এএমডি রাইজেন প্রসেসর নির্ভর উচ্চ-ক্ষমতাসম্পন্ন কাস্টম পিসি তৈরি থেকে শুরু করে এইচপি, ডেল, এসার, লেনোভোর মতো বিশ্বখ্যাত ব্র্যান্ডের ল্যাপটপ সরবরাহ করা হয়।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
      Exercise(
        text: "কম্পিউটিংয়ের যাবতীয় অপরিহার্য যন্ত্রাংশ যেমন—এসএসডি, র‍্যাম, মাদারবোর্ড, প্রসেসর, পিএসইউ, গেমিং কেসিং, কুলার, মনিটর, কিবোর্ড, মাউস এবং সাউন্ড সিস্টেমের বিপুল সমাহার রয়েছে।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
      Exercise(
        text: "টেকজোন আইটি প্রিন্টিং ও ডকুমেন্টেশন সলিউশনের ক্ষেত্রেও একটি নির্ভরযোগ্য গন্তব্য, যেখানে এপসন, এইচপি, ক্যানন, ব্রাদার, প্যান্টামের মতো শীর্ষস্থানীয় ব্র্যান্ডের প্রিন্টার সরবরাহ করা হয়।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
      Exercise(
        text: "অভিজ্ঞ টেকনিশিয়ান দ্বারা ডেস্কটপ ও ল্যাপটপের যেকোনো জটিল হার্ডওয়্যার সমস্যা মেরামত, নষ্ট বা ক্র্যাশ করা স্টোরেজ ডিভাইস থেকে গুরুত্বপূর্ণ ডেটা রিকভারি সেবা প্রদান করা হয়।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
      Exercise(
        text: "টেকজোন আইটি হার্ডওয়্যার, সফটওয়্যার, সার্ভিসিং, নেটওয়ার্কিং এবং স্কিল ডেভেলপমেন্টের এক অপূর্ব সমন্বয়ে প্রকৃত অর্থে একটি ওয়ান-স্টপ প্রযুক্তি সেবাদাতা প্রতিষ্ঠান।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
      Exercise(
        text: "টেকজোন আইটি-তে বেসিক কম্পিউটার ও অফিস অ্যাপ্লিকেশন থেকে শুরু করে ফ্রিল্যান্সিং-এর সকল ক্যাটাগরিতে প্রশিক্ষণ প্রদান করা হয়।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
      Exercise(
        text: "প্রশিক্ষণের ক্ষেত্রগুলোর মধ্যে রয়েছে: গ্রাফিক্স ডিজাইন, ওয়েব ডেভেলপমেন্ট, প্রোগ্রামিং, কাস্টম অ্যাপ ডেভেলপমেন্ট, বাগ ফিক্সিং এবং ডিজিটাল মার্কেটিং।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
      Exercise(
        text: "এছাড়াও এআই (AI) এবং অটোমেশন সংক্রান্ত আধুনিক কোর্সে প্রশিক্ষণ দেওয়া হয়, যা তরুণদের ভবিষ্যৎ ক্যারিয়ার গঠনে সহায়তা করে।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
    ],
  ),
];
