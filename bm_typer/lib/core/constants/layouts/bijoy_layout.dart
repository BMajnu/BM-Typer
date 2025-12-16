
/// Bijoy Bayanno keyboard layout mapping (Official)
/// Based on Bijoy Bayanno 52 standard layout
class BijoyKeyboardLayout {
  /// Normal keys (without Shift) - Official Bijoy Bayanno
  static const Map<String, String> normalKeys = {
    // Number row - Bengali numbers (normal state)
    '`': '`',
    '1': '১', '2': '২', '3': '৩', '4': '৪', '5': '৫',
    '6': '৬', '7': '৭', '8': '৮', '9': '৯', '0': '০',
    '-': '-', '=': '=',

    // Top row Q-P (Normal)
    'q': 'ঙ', 'w': 'য', 'e': 'ড', 'r': 'প', 't': 'ট',
    'y': 'চ', 'u': 'জ', 'i': 'হ', 'o': 'গ', 'p': 'ড়',
    '[': '[', ']': ']', '\\': '৳',

    // Home row A-L (Normal)
    'a': 'ৃ', 's': 'ু', 'd': 'ি', 'f': 'া', 'g': '্',
    'h': 'ব', 'j': 'ক', 'k': 'ত', 'l': 'দ',
    ';': ';', '\'': '\'',

    // Bottom row Z-M (Normal)
    'z': '্র', 'x': 'ও', 'c': 'ে', 'v': 'র', 'b': 'ন',
    'n': 'স', 'm': 'ম',
    ',': ',', '.': '।', '/': '/',
  };

  /// Shift keys (with Shift pressed) - Official Bijoy Bayanno
  static const Map<String, String> shiftKeys = {
    // Number row with Shift
    '~': '~', '!': '!', '@': '@', '#': '#', '\$': '৳',
    '%': '%', '^': 'ঁ', '&': '&', '*': '*',
    '(': '(', ')': ')', '_': '_', '+': '+',

    // Top row with Shift Q-P
    'Q': 'ং', 'W': 'য়', 'E': 'ঢ', 'R': 'ফ', 'T': 'ঠ',
    'Y': 'ছ', 'U': 'ঝ', 'I': 'ঞ', 'O': 'ঘ', 'P': 'ঢ়',
    '{': '{', '}': '}', '|': '|',

    // Home row with Shift A-L
    'A': 'র্', 'S': 'ূ', 'D': 'ী', 'F': 'অ', 'G': '।',
    'H': 'ভ', 'J': 'খ', 'K': 'থ', 'L': 'ধ',
    ':': ':', '"': '"',

    // Bottom row with Shift Z-M
    'Z': '্য', 'X': 'ঔ', 'C': 'ৈ', 'V': 'ল', 'B': 'ণ',
    'N': 'ষ', 'M': 'শ',
    '<': 'ৎ', '>': 'ঃ', '?': '?',
  };

  /// Get Bengali character for a key press
  static String? getCharacter(String key, {bool shift = false}) {
    if (shift) {
      final upperKey = key.toUpperCase();
      if (shiftKeys.containsKey(upperKey)) return shiftKeys[upperKey];
      return shiftKeys[key];
    }
    return normalKeys[key.toLowerCase()];
  }

  static List<List<String>> getDisplayRows() {
    return [
      ['১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯', '০', '-', '=', '⌫'],
      ['ঙ', 'য', 'ড', 'প', 'ট', 'চ', 'জ', 'হ', 'গ', 'ড়'],
      ['ৃ', 'ু', 'ি', 'া', '্', 'ব', 'ক', 'ত', 'দ'],
      ['shift', '্র', 'ও', 'ে', 'র', 'ন', 'স', 'ম', '।', '/', 'shift'],
    ];
  }

  static List<List<String>> getShiftDisplayRows() {
    return [
      ['!', '@', '#', '৳', '%', 'ঁ', '&', '*', '(', ')', '_', '+', '⌫'],
      ['ং', 'য়', 'ঢ', 'ফ', 'ঠ', 'ছ', 'ঝ', 'ঞ', 'ঘ', 'ঢ়'],
      ['ঋ', 'ূ', 'ী', 'অ', '।', 'ভ', 'খ', 'থ', 'ধ'],
      ['shift', '্য', 'ঔ', 'ৈ', 'ল', 'ণ', 'ষ', 'শ', 'ৎ', 'ঃ', 'shift'],
    ];
  }

  static const Map<String, String> englishToBengali = {
    // Lowercase letters (Normal state)
    'q': 'ঙ', 'w': 'য', 'e': 'ড', 'r': 'প', 't': 'ট',
    'y': 'চ', 'u': 'জ', 'i': 'হ', 'o': 'গ', 'p': 'ড়',
    'a': 'ৃ', 's': 'ু', 'd': 'ি', 'f': 'া', 'g': '্',
    'h': 'ব', 'j': 'ক', 'k': 'ত', 'l': 'দ',
    'z': '্র', 'x': 'ও', 'c': 'ে', 'v': 'র', 'b': 'ন',
    'n': 'স', 'm': 'ম',
    // Uppercase letters (Shift state)
    'Q': 'ং', 'W': 'য়', 'E': 'ঢ', 'R': 'ফ', 'T': 'ঠ',
    'Y': 'ছ', 'U': 'ঝ', 'I': 'ঞ', 'O': 'ঘ', 'P': 'ঢ়',
    'A': 'র্', 'S': 'ূ', 'D': 'ী', 'F': 'অ', 'G': '।',
    'H': 'ভ', 'J': 'খ', 'K': 'থ', 'L': 'ধ',
    'Z': '্য', 'X': 'ঔ', 'C': 'ৈ', 'V': 'ল', 'B': 'ণ',
    'N': 'ষ', 'M': 'শ',
    // Numbers - Bengali
    '1': '১', '2': '২', '3': '৩', '4': '৪', '5': '৫',
    '6': '৬', '7': '৭', '8': '৮', '9': '৯', '0': '০',
    // Punctuation
    '.': '।', ',': ',', ';': ';', '\'': '\'',
    '\$': '৳', '>': 'ঃ', '<': 'ৎ',
  };

  /// Vowels (স্বরবর্ণ)
  static const List<String> vowels = [
    'অ', 'আ', 'ই', 'ঈ', 'উ', 'ঊ', 'ঋ', 'এ', 'ঐ', 'ও', 'ঔ'
  ];

  /// Consonants (ব্যঞ্জনবর্ণ)
  static const List<String> consonants = [
    'ক', 'খ', 'গ', 'ঘ', 'ঙ',
    'চ', 'ছ', 'জ', 'ঝ', 'ঞ',
    'ট', 'ঠ', 'ড', 'ঢ', 'ণ',
    'ত', 'থ', 'দ', 'ধ', 'ন',
    'প', 'ফ', 'ব', 'ভ', 'ম',
    'য', 'র', 'ল', 'শ', 'ষ', 'স', 'হ',
    'ড়', 'ঢ়', 'য়',
  ];

  /// Vowel signs (কার চিহ্ন)
  static const Map<String, String> vowelSigns = {
    'আ-কার': 'া', 'ই-কার': 'ি', 'ঈ-কার': 'ী',
    'উ-কার': 'ু', 'ঊ-কার': 'ূ', 'ঋ-কার': 'ৃ',
    'এ-কার': 'ে', 'ঐ-কার': 'ৈ', 'ও-কার': 'ো', 'ঔ-কার': 'ৌ',
  };

  /// Special characters
  static const Map<String, String> specialChars = {
    'হসন্ত': '্', 'চন্দ্রবিন্দু': 'ঁ', 'অনুস্বার': 'ং',
    'বিসর্গ': 'ঃ', 'দাড়ি': '।', 'খণ্ড-ত': 'ৎ',
  };

  /// Bijoy Vowel Composition Map (G + vowel key = Full Vowel)
  static const Map<String, String> vowelComposition = {
    'f': 'আ', 'd': 'ই', 'D': 'ঈ', 's': 'উ', 'S': 'ঊ',
    'a': 'ঋ', 'c': 'এ', 'C': 'ঐ', 'x': 'ও', 'X': 'ঔ',
  };

  static bool isHasanta(String char) => char == '্';
  static String? getComposedVowel(String key) => vowelComposition[key];
}
