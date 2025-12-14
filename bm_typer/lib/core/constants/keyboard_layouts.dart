/// বাংলা Keyboard Layout Data
/// Bijoy Bayanno layout - বাংলাদেশে সর্বাধিক ব্যবহৃত keyboard layout
/// Reference: Official Bijoy Bayanno 52 keyboard layout
/// Cross-platform compatible - Windows, Mac, Linux, Mobile

/// Keyboard layout types
enum KeyboardLayout {
  qwerty, // English QWERTY
  bijoy, // Bijoy Bengali layout (Official Bijoy Bayanno)
  phonetic, // Phonetic Bengali layout (Avro style)
}

/// Bijoy Bayanno keyboard layout mapping (Official)
/// Based on Bijoy Bayanno 52 standard layout
class BijoyKeyboardLayout {
  /// Normal keys (without Shift) - Official Bijoy Bayanno
  static const Map<String, String> normalKeys = {
    // Number row - Bengali numbers (normal state)
    '`': '`',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
    '0': '০',
    '-': '-',
    '=': '=',

    // Top row Q-P (Normal)
    // Q=ঙ, W=য, E=ড, R=প, T=ট, Y=চ, U=জ, I=হ, O=গ, P=ড়
    'q': 'ঙ',
    'w': 'য',
    'e': 'ড',
    'r': 'প',
    't': 'ট',
    'y': 'চ',
    'u': 'জ',
    'i': 'হ',
    'o': 'গ',
    'p': 'ড়',
    '[': '[',
    ']': ']',
    '\\': '৳',

    // Home row A-L (Normal) - Official Bijoy
    // A=ৃ, S=ু, D=ি, F=া, G=্ (hoshonto), H=ব, J=ক, K=ত, L=দ
    'a': 'ৃ',
    's': 'ু',
    'd': 'ি',
    'f': 'া',
    'g': '্',
    'h': 'ব',
    'j': 'ক',
    'k': 'ত',
    'l': 'দ',
    ';': ';',
    '\'': '\'',

    // Bottom row Z-M (Normal) - Official Bijoy
    // Z=্র (ro-fola), X=ও (O), C=ে (e-kar), V=র (Ro), B=ন, N=স, M=ম
    'z': '্র',
    'x': 'ও',
    'c': 'ে',
    'v': 'র',
    'b': 'ন',
    'n': 'স',
    'm': 'ম',
    ',': ',',
    '.': '।', // Dari
    '/': '/', // Ref: usually / is / or ? in normal, but some layout maps it to something else. Keeping / for now.
  };

  /// Shift keys (with Shift pressed) - Official Bijoy Bayanno
  static const Map<String, String> shiftKeys = {
    // Number row with Shift
    '~': '~',
    '!': '!',
    '@': '@',
    '#': '#',
    '\$': '৳',
    '%': '%',
    '^': 'ঁ',
    '&': '&',
    '*': '*',
    '(': '(',
    ')': ')',
    '_': '_',
    '+': '+',

    // Top row with Shift Q-P
    // Q=ং, W=য়, E=ঢ, R=ফ, T=ঠ, Y=ছ, U=ঝ, I=ঞ, O=ঘ, P=ঢ়
    'Q': 'ং',
    'W': 'য়',
    'E': 'ঢ',
    'R': 'ফ',
    'T': 'ঠ',
    'Y': 'ছ',
    'U': 'ঝ',
    'I': 'ঞ',
    'O': 'ঘ',
    'P': 'ঢ়',
    '{': '{',
    '}': '}',
    '|': '|',

    // Home row with Shift A-L
    // A=র্ (Reph), S=ূ, D=ী, F=অ, G=। (dari), H=ভ, J=খ, K=থ, L=ধ
    'A': 'র্',
    'S': 'ূ',
    'D': 'ী',
    'F': 'অ',
    'G': '।',
    'H': 'ভ',
    'J': 'খ',
    'K': 'থ',
    'L': 'ধ',
    ':': ':', // Colon
    '"': '"',

    // Bottom row with Shift Z-M
    // Z=্য (jo-fola), X=ঔ (Ou), C=ৈ (Oi-kar), V=ল (La), B=ণ, N=ষ, M=শ
    'Z': '্য',
    'X': 'ঔ',
    'C': 'ৈ',
    'V': 'ল',
    'B': 'ণ',
    'N': 'ষ',
    'M': 'শ',
    '<': 'ৎ',
    '>': 'ঃ', // Bishorgo
    '?': '?',
  };

  /// Get Bengali character for a key press
  static String? getCharacter(String key, {bool shift = false}) {
    if (shift) {
      final upperKey = key.toUpperCase();
      if (shiftKeys.containsKey(upperKey)) {
        return shiftKeys[upperKey];
      }
      return shiftKeys[key];
    }
    return normalKeys[key.toLowerCase()];
  }

  static List<List<String>> getDisplayRows() {
    return [
      // Number row
      ['১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯', '০', '-', '=', '⌫'],
      // Top row Q-P (Normal)
      ['ঙ', 'য', 'ড', 'প', 'ট', 'চ', 'জ', 'হ', 'গ', 'ড়'],
      // Home row A-L (Normal)
      ['ৃ', 'ু', 'ি', 'া', '্', 'ব', 'ক', 'ত', 'দ'],
      // Bottom row Z-M (Normal)
      ['shift', '্র', 'ও', 'ে', 'র', 'ন', 'স', 'ম', '।', '/', 'shift'],
    ];
  }

  /// Get keys for display (Shift state)
  static List<List<String>> getShiftDisplayRows() {
    return [
      // Number row with shift
      ['!', '@', '#', '৳', '%', 'ঁ', '&', '*', '(', ')', '_', '+', '⌫'],
      // Top row shifted
      ['ং', 'য়', 'ঢ', 'ফ', 'ঠ', 'ছ', 'ঝ', 'ঞ', 'ঘ', 'ঢ়'],
      // Home row shifted
      ['ঋ', 'ূ', 'ী', 'অ', '।', 'ভ', 'খ', 'থ', 'ধ'],
      // Bottom row shifted
      ['shift', '্য', 'ঔ', 'ৈ', 'ল', 'ণ', 'ষ', 'শ', 'ৎ', 'ঃ', 'shift'],
    ];
  }

  static const Map<String, String> englishToBengali = {
    // Lowercase letters (Normal state)
    'q': 'ঙ', 'w': 'য', 'e': 'ড', 'r': 'প', 't': 'ট',
    'y': 'চ', 'u': 'জ', 'i': 'হ', 'o': 'গ', 'p': 'ড়',
    'a': 'ৃ', 's': 'ু', 'd': 'ি', 'f': 'া', 'g': '্',
    'h': 'ব', 'j': 'ক', 'k': 'ত', 'l': 'দ',
    'z': '্র', 'x': 'ও', 'c': 'ে', 'v': 'র', 'b': 'ন',
    'n': 'স', 'm': 'ম',
    
    // Uppercase letters (Shift state)
    'Q': 'ং', 'W': 'য়', 'E': 'ঢ', 'R': 'ফ', 'T': 'ঠ',
    'Y': 'ছ', 'U': 'ঝ', 'I': 'ঞ', 'O': 'ঘ', 'P': 'ঢ়',
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
    'আ-কার': 'া',
    'ই-কার': 'ি',
    'ঈ-কার': 'ী',
    'উ-কার': 'ু',
    'ঊ-কার': 'ূ',
    'ঋ-কার': 'ৃ',
    'এ-কার': 'ে',
    'ঐ-কার': 'ৈ',
    'ও-কার': 'ো',
    'ঔ-কার': 'ৌ',
  };

  /// Special characters
  static const Map<String, String> specialChars = {
    'হসন্ত': '্',
    'চন্দ্রবিন্দু': 'ঁ',
    'অনুস্বার': 'ং',
    'বিসর্গ': 'ঃ',
    'দাড়ি': '।',
    'খণ্ড-ত': 'ৎ',
  };
}


/// Phonetic keyboard layout (Avro style - Simplified for single keypress)
class PhoneticKeyboardLayout {
  static const Map<String, String> normalKeys = {
    // Vowels
    'o': 'অ', 'a': 'া', 'i': 'ি', 'u': 'ু', 'e': 'ে', 'O': 'ও',
    
    // Consonants
    'k': 'ক', 'g': 'গ', 'c': 'চ', 'j': 'জ', 'T': 'ট',
    'D': 'ড', 'N': 'ণ', 't': 'ত', 'd': 'দ', 'n': 'ন',
    'p': 'প', 'f': 'ফ', 'b': 'ব', 'v': 'ভ', 'm': 'ম',
    'z': 'য', 'r': 'র', 'l': 'ল', 'S': 'শ', 's': 'স',
    'h': 'হ', 'R': 'ড়', 'y': 'য়',
    
    // Others
    'x': 'ক্স', '\$': '৳', ':': 'ঃ', '^': 'ঁ', '.': '।',
  };

  static const Map<String, String> shiftKeys = {
    // Vowels (Shifted)
    'A': 'আ', 'I': 'ী', 'U': 'ূ', 'E': 'ৈ', 'O': 'ঔ',
    
    // Consonants (Aspirated / Alternate)
    'K': 'খ', 'G': 'ঘ', 'C': 'ছ', 'J': 'ঝ', 
    'T': 'ঠ', 'D': 'ঢ', 
    't': 'থ', 'd': 'ধ',
    'B': 'ভ', 'M': 'ং',
    'S': 'ষ', 'H': 'ঃ',
  };

  static String? getCharacter(String key, {bool shift = false}) {
    if (shift) {
      if (shiftKeys.containsKey(key)) return shiftKeys[key];
      // Check if standard specific mapping exists for this shifted key in normalKeys (unlikely but safe)
      if (normalKeys.containsKey(key)) return normalKeys[key];
    }
    
    // Check normalKeys first to ensure 't' maps to normal 't' char, not shift 't' char
    if (normalKeys.containsKey(key)) return normalKeys[key];
    if (shiftKeys.containsKey(key)) return shiftKeys[key];
    
    return null;
  }
}

/// QWERTY keyboard layout (English)
class QwertyKeyboardLayout {
  static List<List<String>> getDisplayRows() {
    return [
      ['`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '⌫'],
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\\'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\''],
      ['shift', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 'shift'],
    ];
  }

  static List<List<String>> getShiftDisplayRows() {
    return [
      ['~', '!', '@', '#', '\$', '%', '^', '&', '*', '(', ')', '_', '+', '⌫'],
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '|'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"'],
      ['shift', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 'shift'],
    ];
  }
}
