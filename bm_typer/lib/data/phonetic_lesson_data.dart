import 'package:bm_typer/core/models/lesson_model.dart';

// ================================================================
// ফনেটিক বাংলা কীবোর্ড লেসন (Avro-style)
// QWERTY কীবোর্ড লেআউটের ক্রম অনুসারে সাজানো
// হোম রো → উপরের সারি → নিচের সারি
// ================================================================

final List<Lesson> phoneticBanglaLessons = [
  // ==================================================================================
  // লেসন ৩১: ফনেটিক হোম রো - বাম হাত (A S D F G)
  // Avro: a=া/আ, s=স, d=দ, f=ফ, g=গ
  // ==================================================================================
  Lesson(
    title: "লেসন ৩১: ফনেটিক হোম রো বাম (া স দ ফ গ)",
    description: "ফনেটিক কীবোর্ডের হোম রো - বাম হাত (a s d f g)",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "া া া া া",  // a key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "স স স স স",  // s key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "দ দ দ দ দ",  // d key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ফ ফ ফ ফ ফ",  // f key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "গ গ গ গ গ",  // g key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "া স দ ফ গ",  // a s d f g sequence
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "সদা গদা ফদ",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৩২: ফনেটিক হোম রো - ডান হাত (H J K L)
  // Avro: h=হ, j=জ, k=ক, l=ল
  // ==================================================================================
  Lesson(
    title: "লেসন ৩২: ফনেটিক হোম রো ডান (হ জ ক ল)",
    description: "ফনেটিক কীবোর্ডের হোম রো - ডান হাত (h j k l)",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "হ হ হ হ হ",  // h key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "জ জ জ জ জ",  // j key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ক ক ক ক ক",  // k key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ল ল ল ল ল",  // l key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "হ জ ক ল",  // h j k l sequence
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "কাজ হাল জল",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৩৩: ফনেটিক হোম রো - শিফট (Shift + A S D F G H J K L)
  // Avro Shift: A=আ, S=শ, D=ড, G=ঘ, K=খ, J=ঝ
  // ==================================================================================
  Lesson(
    title: "লেসন ৩৩: ফনেটিক হোম রো - শিফট (আ শ ড ঘ খ ঝ)",
    description: "শিফট সহ ফনেটিক হোম রো (Shift + A S D F G H J K L)",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "আ আ আ আ আ",  // Shift+A
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "শ শ শ শ শ",  // Shift+S
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ড ড ড ড ড",  // Shift+D
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঘ ঘ ঘ ঘ ঘ",  // Shift+G
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "খ খ খ খ খ",  // Shift+K
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঝ ঝ ঝ ঝ ঝ",  // Shift+J
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "আশা খাবার ঘর",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৩৪: ফনেটিক উপরের সারি - স্বরবর্ণ (E I O U)
  // Avro: e=ে/এ, i=ি/ই, o=অ, u=ু/উ
  // ==================================================================================
  Lesson(
    title: "লেসন ৩৪: ফনেটিক স্বরবর্ণ (এ ই অ উ)",
    description: "ফনেটিক স্বরবর্ণ শিখুন - e=এ, i=ই, o=অ, u=উ",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "ে ে ে ে ে",  // e key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ি ি ি ি ি",  // i key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "অ অ অ অ অ",  // o key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ু ু ু ু ু",  // u key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ে ি অ ু",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "কে কি অক কু",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৩৫: ফনেটিক উপরের সারি - ব্যঞ্জনবর্ণ (R T Y P)
  // Avro: r=র, t=ত, y=য়, p=প
  // ==================================================================================
  Lesson(
    title: "লেসন ৩৫: ফনেটিক উপরের সারি (র ত য় প)",
    description: "ফনেটিক উপরের সারি - r=র, t=ত, y=য়, p=প",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "র র র র র",  // r key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ত ত ত ত ত",  // t key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "য় য় য় য় য়",  // y key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "প প প প প",  // p key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "র ত য় প",
        repetitions: 10,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "রাত পাত তার",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৩৬: ফনেটিক নিচের সারি (Z X C V B N M)
  // Avro: z=য, c=চ, v=ভ, b=ব, n=ন, m=ম
  // ==================================================================================
  Lesson(
    title: "লেসন ৩৬: ফনেটিক নিচের সারি (য চ ভ ব ন ম)",
    description: "ফনেটিক নিচের সারি - z=য, c=চ, v=ভ, b=ব, n=ন, m=ম",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 1,
    exercises: [
      Exercise(
        text: "য য য য য",  // z key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "চ চ চ চ চ",  // c key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ভ ভ ভ ভ ভ",  // v key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ব ব ব ব ব",  // b key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ন ন ন ন ন",  // n key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "ম ম ম ম ম",  // m key
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 1,
      ),
      Exercise(
        text: "বন মন চা নাম",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 1,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৩৭: ফনেটিক মহাপ্রাণ বর্ণ (kh gh ch jh th dh ph bh)
  // ==================================================================================
  Lesson(
    title: "লেসন ৩৭: ফনেটিক মহাপ্রাণ বর্ণ (খ ঘ ছ ঝ থ ধ ফ ভ)",
    description: "ফনেটিক মহাপ্রাণ বর্ণ - kh=খ, gh=ঘ, ch=ছ, jh=ঝ, th=থ, dh=ধ",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "খ খ খ খ খ",  // kh
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ঘ ঘ ঘ ঘ ঘ",  // gh
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ছ ছ ছ ছ ছ",  // ch
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "থ থ থ থ থ",  // th
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "ধ ধ ধ ধ ধ",  // dh
        repetitions: 8,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "খাবার ঘর ছবি থালা ধান",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৩৮: ফনেটিক শব্দ অনুশীলন
  // ==================================================================================
  Lesson(
    title: "লেসন ৩৮: ফনেটিক শব্দ অনুশীলন",
    description: "ফনেটিক দিয়ে সাধারণ বাংলা শব্দ টাইপ করুন",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 2,
    exercises: [
      Exercise(
        text: "আমি তুমি সে তারা",
        repetitions: 6,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "করা যাওয়া আসা দেখা",
        repetitions: 6,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "বাংলাদেশ ঢাকা চট্টগ্রাম",
        repetitions: 5,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
      Exercise(
        text: "কম্পিউটার মোবাইল ইন্টারনেট",
        repetitions: 5,
        type: ExerciseType.drill,
        difficultyLevel: 2,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৩৯: ফনেটিক বাক্য অনুশীলন
  // ==================================================================================
  Lesson(
    title: "লেসন ৩৯: ফনেটিক বাক্য অনুশীলন",
    description: "ফনেটিক দিয়ে সম্পূর্ণ বাংলা বাক্য টাইপ করুন",
    category: "Phonetic",
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
        text: "শিক্ষা জাতির মেরুদণ্ড।",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 3,
      ),
      Exercise(
        text: "জ্ঞানই শক্তি।",
        repetitions: 5,
        type: ExerciseType.standard,
        difficultyLevel: 3,
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৪০: ফনেটিক অনুচ্ছেদ অনুশীলন
  // ==================================================================================
  Lesson(
    title: "লেসন ৪০: ফনেটিক অনুচ্ছেদ অনুশীলন",
    description: "ফনেটিক দিয়ে দীর্ঘ অনুচ্ছেদ টাইপ করুন",
    category: "Phonetic",
    language: "bn",
    difficultyLevel: 4,
    exercises: [
      Exercise(
        text: "বাংলাদেশ দক্ষিণ এশিয়ার একটি স্বাধীন সার্বভৌম রাষ্ট্র। ১৯৭১ সালে মুক্তিযুদ্ধের মাধ্যমে বাংলাদেশ স্বাধীন হয়।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 4,
      ),
      Exercise(
        text: "ফনেটিক কীবোর্ড ব্যবহার করে বাংলা টাইপ করা সহজ। ইংরেজি উচ্চারণ অনুযায়ী টাইপ করলে বাংলা অক্ষর আসে।",
        repetitions: 3,
        type: ExerciseType.paragraph,
        difficultyLevel: 4,
      ),
      Exercise(
        text: "আমার সোনার বাংলা আমি তোমায় ভালোবাসি। চিরদিন তোমার আকাশ তোমার বাতাস আমার প্রাণে বাজায় বাঁশি।",
        repetitions: 3,
        type: ExerciseType.quote,
        difficultyLevel: 4,
        source: "রবীন্দ্রনাথ ঠাকুর",
      ),
    ],
  ),

  // ==================================================================================
  // লেসন ৪১: টেক জোন আইটি - ফনেটিক পেশাদার অনুচ্ছেদ
  // ==================================================================================
  Lesson(
    title: "লেসন ৪১: টেক জোন আইটি - ফনেটিক অনুশীলন",
    description: "ফনেটিক দিয়ে টেক জোন আইটি সম্পর্কে বিস্তারিত অনুচ্ছেদ টাইপ করুন",
    category: "Phonetic",
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
