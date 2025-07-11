import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language codes for the application
enum AppLanguage {
  /// Bengali language
  bengali('bn', 'বাংলা'),

  /// English language
  english('en', 'English');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.bengali, // Default to Bengali
    );
  }
}

/// Provider for the current app language
final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, AppLanguage>(
  (ref) => AppLanguageNotifier(),
);

/// Notifier class to manage the app language state
class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.bengali) {
    _loadSavedLanguage();
  }

  /// Load the saved language preference from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('app_language') ?? 'bn';
    state = AppLanguage.fromCode(savedLanguageCode);
  }

  /// Change the app language
  Future<void> changeLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language.code);
  }
}

/// Provider for translated strings based on the current language
final translationProvider = Provider.family<String, String>((ref, key) {
  final currentLanguage = ref.watch(appLanguageProvider);

  // Get the translation for the given key based on the current language
  return _getTranslation(key, currentLanguage.code);
});

/// Get a translation for a given key and language code
String _getTranslation(String key, String languageCode) {
  // Define translations for different languages
  final translations = {
    'en': {
      // General UI
      'exercises': 'Exercises',
      'lesson': 'Lesson',
      'select_language': 'Select Language',
      'app_language': 'App Language',
      'interface_language': 'Interface Language',
      'typing_language': 'Typing Content',
      'all_content': 'All Content',
      'bengali_content': 'Bengali Content',
      'english_content': 'English Content',
      'select_interface_language': 'Select Interface Language',
      'select_typing_content': 'Select Typing Content',
      'profile': 'Profile',
      'achievements': 'Achievements',
      'leaderboard': 'Leaderboard',
      'settings': 'Settings',
      'theme': 'Theme',
      'audio': 'Audio',
      'accessibility': 'Accessibility',
      'export': 'Export & Share',
      'typing_test': 'Typing Speed Test',
      'start_typing': 'Start Typing',
      'next_lesson': 'Next Lesson',
      'previous_lesson': 'Previous Lesson',
      'wpm': 'WPM',
      'accuracy': 'Accuracy',
      'time': 'Time',
      'progress': 'Progress',
      'ok': 'OK',
      'cancel': 'Cancel',

      // Typing instructions and tips
      'home_row_left_hand':
          'Place your left hand fingers on A, S, D, F keys. Practice pressing F and G with your index finger.',
      'home_row_right_hand':
          'Place your right hand fingers on J, K, L, ; keys. Practice pressing J and H with your index finger.',
      'upper_row':
          'Practice typing with the upper row keys: Q, W, E, R, T, Y, U, I, O, P.',
      'lower_row':
          'Practice typing with the lower row keys: Z, X, C, V, B, N, M.',
      'common_words': 'Practice typing common words using all rows.',
      'common_sentences':
          'Practice typing common sentences using home, upper, and lower rows.',

      // Exercise types
      'standard': 'Standard',
      'paragraph': 'Paragraph',
      'drill': 'Drill',
      'quote': 'Quote',
      'business': 'Business',

      // UI elements
      'press_to_start': 'Press to start typing',
      'keyboard_shortcuts': 'Keyboard Shortcuts',
      'statistics': 'Statistics',
      'history': 'History',
      'settings_tooltip': 'Settings',
      'help_tooltip': 'Help',
      'about_tooltip': 'About',
      'feedback_tooltip': 'Feedback',
      'practice_daily': 'Practice daily to improve your typing skills',
      'current_streak': 'Current Streak',
      'best_streak': 'Best Streak',
      'days': 'days',
      'level': 'Level',
      'xp': 'XP',
      'next_level': 'Next Level',

      // Accessibility settings
      'font_size': 'Font Size',
      'contrast': 'Contrast',
      'animation_speed': 'Animation Speed',
      'keyboard_sound': 'Keyboard Sound',
      'speech_rate': 'Speech Rate',
      'volume': 'Volume',
      'pitch': 'Pitch',
      'language': 'Language',
      'test_text': 'Can you hear this text being spoken?',

      // Lesson descriptions
      'lesson_1_1': 'Lesson 1.1: Home Row (Left Hand)',
      'lesson_1_2': 'Lesson 1.2: Home Row (Right Hand)',
      'lesson_2': 'Lesson 2: Upper Row',
      'lesson_3': 'Lesson 3: Lower Row',
      'lesson_4': 'Lesson 4: Common Words',
      'lesson_5': 'Lesson 5: Common Sentences',
    },
    'bn': {
      // General UI
      'exercises': 'অনুশীলনী',
      'lesson': 'পাঠ',
      'select_language': 'ভাষা নির্বাচন করুন',
      'app_language': 'অ্যাপ ভাষা',
      'interface_language': 'ইন্টারফেস ভাষা',
      'typing_language': 'টাইপিং কন্টেন্ট',
      'all_content': 'সব কন্টেন্ট',
      'bengali_content': 'বাংলা কন্টেন্ট',
      'english_content': 'ইংরেজি কন্টেন্ট',
      'select_interface_language': 'ইন্টারফেস ভাষা নির্বাচন করুন',
      'select_typing_content': 'টাইপিং কন্টেন্ট নির্বাচন করুন',
      'profile': 'প্রোফাইল',
      'achievements': 'অর্জনসমূহ',
      'leaderboard': 'লিডারবোর্ড',
      'settings': 'সেটিংস',
      'theme': 'থিম',
      'audio': 'অডিও',
      'accessibility': 'অ্যাক্সেসিবিলিটি',
      'export': 'এক্সপোর্ট ও শেয়ার',
      'typing_test': 'টাইপিং স্পিড টেস্ট',
      'start_typing': 'টাইপিং শুরু করুন',
      'next_lesson': 'পরবর্তী পাঠ',
      'previous_lesson': 'পূর্ববর্তী পাঠ',
      'wpm': 'ডব্লিউপিএম',
      'accuracy': 'নির্ভুলতা',
      'time': 'সময়',
      'progress': 'অগ্রগতি',
      'ok': 'ঠিক আছে',
      'cancel': 'বাতিল',

      // Typing instructions and tips
      'home_row_left_hand':
          'আপনার বাম হাতের আঙুলগুলো রাখুন A, S, D, F কী-এর উপর। তর্জনী দিয়ে F ও G চাপার অনুশীলন করুন।',
      'home_row_right_hand':
          'আপনার ডান হাতের আঙুলগুলো রাখুন J, K, L, ; কী-এর উপর। তর্জনী দিয়ে J ও H চাপার অনুশীলন করুন।',
      'upper_row':
          'উপরের সারির কী-গুলো দিয়ে অনুশীলন করুন: Q, W, E, R, T, Y, U, I, O, P।',
      'lower_row':
          'নিচের সারির কী-গুলো দিয়ে অনুশীলন করুন: Z, X, C, V, B, N, M।',
      'common_words': 'সব সারি ব্যবহার করে সাধারণ শব্দ অনুশীলন করুন।',
      'common_sentences':
          'হোম, উপরের এবং নিচের সারি ব্যবহার করে সাধারণ বাক্য অনুশীলন করুন।',

      // Exercise types
      'standard': 'স্ট্যান্ডার্ড',
      'paragraph': 'অনুচ্ছেদ',
      'drill': 'ড্রিল',
      'quote': 'উক্তি',
      'business': 'ব্যবসায়িক',

      // UI elements
      'press_to_start': 'টাইপিং শুরু করতে চাপুন',
      'keyboard_shortcuts': 'কীবোর্ড শর্টকাট',
      'statistics': 'পরিসংখ্যান',
      'history': 'ইতিহাস',
      'settings_tooltip': 'সেটিংস',
      'help_tooltip': 'সাহায্য',
      'about_tooltip': 'সম্পর্কে',
      'feedback_tooltip': 'মতামত',
      'practice_daily': 'আপনার টাইপিং দক্ষতা উন্নত করতে প্রতিদিন অনুশীলন করুন',
      'current_streak': 'বর্তমান স্ট্রিক',
      'best_streak': 'সর্বোচ্চ স্ট্রিক',
      'days': 'দিন',
      'level': 'লেভেল',
      'xp': 'এক্সপি',
      'next_level': 'পরবর্তী লেভেল',

      // Accessibility settings
      'font_size': 'ফন্ট সাইজ',
      'contrast': 'কনট্রাস্ট',
      'animation_speed': 'অ্যানিমেশন স্পিড',
      'keyboard_sound': 'কীবোর্ড সাউন্ড',
      'speech_rate': 'স্পীচ রেট',
      'volume': 'ভলিউম',
      'pitch': 'পিচ',
      'language': 'ভাষা',
      'test_text': 'আপনি কি এই টেক্সট শুনতে পাচ্ছেন?',

      // Lesson descriptions
      'lesson_1_1': 'পাঠ ১.১: হোম রো (বাম হাত)',
      'lesson_1_2': 'পাঠ ১.২: হোম রো (ডান হাত)',
      'lesson_2': 'পাঠ ২: উপরের সারি',
      'lesson_3': 'পাঠ ৩: নিচের সারি',
      'lesson_4': 'পাঠ ৪: সাধারণ শব্দ',
      'lesson_5': 'পাঠ ৫: সাধারণ বাক্য',
    },
  };

  // Return the translation or the key itself if not found
  return translations[languageCode]?[key] ?? key;
}
