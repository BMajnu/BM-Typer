
/// ================================================================
/// Avro Phonetic Keyboard Layout
/// Based on Official Avro Keyboard phonetic mapping
/// Reference: https://www.omicronlab.com/avro-keyboard.html
/// ================================================================
class PhoneticKeyboardLayout {
  
  /// Normal keys (without Shift) - Avro Phonetic
  static const Map<String, String> normalKeys = {
    // Vowels (স্বরবর্ণ) - single key
    'o': 'অ',    // o = অ
    'a': 'া',    // a = া-কার (আ after nothing/space)
    'i': 'ি',    // i = ি-কার (ই after nothing/space)
    'u': 'ু',    // u = ু-কার (উ after nothing/space)
    'e': 'ে',    // e = ে-কার (এ after nothing/space)
    'w': 'ও',    // w = ও
    'q': 'ৃ',    // q = ঋ-কার
    
    // Consonants (ব্যঞ্জনবর্ণ) - অল্পপ্রাণ
    'k': 'ক', 'g': 'গ', 'c': 'চ', 'j': 'জ',
    't': 'ত', 'd': 'দ', 'n': 'ন',
    'p': 'প', 'f': 'ফ', 'b': 'ব', 'v': 'ভ', 'm': 'ম',
    'z': 'য', 'r': 'র', 'l': 'ল', 's': 'স', 'h': 'হ',
    'y': 'য়',
    
    // Numbers (Bengali)
    '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
    '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
    
    // Punctuation
    '.': '।',    // Period = Dari
    ',': ',', ';': ';', '\'': '\'',
    '`': '্',    // Backtick = Hasanta/Virama
    'x': 'ক্স', // x = ক্স conjunct
  };

  /// Shift keys (uppercase = aspirated/retroflex/alternate)
  static const Map<String, String> shiftKeys = {
    // Vowels (Shifted) - Full/Long vowels
    'A': 'আ',    // Shift+A = আ (independent)
    'I': 'ী',    // Shift+I = ী-কার (long i)
    'U': 'ূ',    // Shift+U = ূ-কার (long u)
    'E': 'ৈ',    // Shift+E = ৈ-কার (oi)
    'O': 'ঔ',    // Shift+O = ঔ
    'W': 'ঊ',    // Shift+W = ঊ (long u independent)
    'Q': 'ঋ',    // Shift+Q = ঋ (independent)
    
    // Consonants (মহাপ্রাণ/Aspirated)
    'K': 'খ',    // Shift+K = খ
    'G': 'ঘ',    // Shift+G = ঘ
    'C': 'ছ',    // Shift+C = ছ
    'J': 'ঝ',    // Shift+J = ঝ
    
    // Retroflex consonants (মূর্ধন্য বর্ণ)
    'T': 'ট',    // Shift+T = ট
    'D': 'ড',    // Shift+D = ড
    'N': 'ণ',    // Shift+N = ণ
    'R': 'ড়',   // Shift+R = ড়
    
    // Other aspirated
    'P': 'ফ',    // Shift+P = ফ (alternate)
    'B': 'ভ',    // Shift+B = ভ
    
    // Sibilants
    'S': 'শ',    // Shift+S = শ
    'H': 'ঃ',    // Shift+H = বিসর্গ
    
    // Special
    'Y': 'ঞ',    // Shift+Y = ঞ
    'M': 'ং',    // Shift+M = অনুস্বার
    'L': 'ল',    // Shift+L = ল
    'Z': 'য',    // Shift+Z = য
    'F': 'ৎ',    // Shift+F = খণ্ড ত
    'V': 'ঙ',    // Shift+V = ঙ
    'X': 'ঢ়',   // Shift+X = ঢ়
    
    // Special Characters
    '^': 'ঁ',    // Shift+6 = চন্দ্রবিন্দু
    '\$': '৳',   // Shift+4 = টাকা চিহ্ন
    ':': 'ঃ',    // Colon = বিসর্গ
    '~': '৳',    // Tilde = টাকা
    '<': 'ৎ',    // Less than = খণ্ড ত
    '>': 'ঃ',    // Greater than = বিসর্গ
  };

  /// Multi-character sequences (for Avro-style phonetic typing)
  /// These are typed as sequences and produce the Bengali character
  static const Map<String, String> multiKeySequences = {
    // Aspirated consonants (kh, gh, ch, etc.)
    'kh': 'খ', 'gh': 'ঘ', 'ch': 'ছ', 'jh': 'ঝ',
    'Th': 'ঠ', 'Dh': 'ঢ', 'th': 'থ', 'dh': 'ধ',
    'ph': 'ফ', 'bh': 'ভ', 'sh': 'শ', 'Sh': 'ষ',
    
    // Nasals
    'ng': 'ং', 'Ng': 'ঙ', 'NG': 'ঞ', 'nj': 'ঞ',
    
    // Long vowels
    'aa': 'আ', 'ee': 'ী', 'ii': 'ঈ', 'oo': 'ূ', 'uu': 'ঊ',
    'OI': 'ৈ', 'oi': 'ৈ', 'OU': 'ৌ', 'ou': 'ৌ',
    'rri': 'ঋ', 'RRI': 'ঋ',
    
    // Special
    'Rh': 'ঢ়', 'rh': 'ঢ়',
    'Tt': 'ৎ', 'tt': 'ৎ',
  };

  /// Get character for a single key press
  static String? getCharacter(String key, {bool shift = false}) {
    if (shift) {
      final upperKey = key.toUpperCase();
      if (shiftKeys.containsKey(upperKey)) return shiftKeys[upperKey];
    }
    if (normalKeys.containsKey(key)) return normalKeys[key];
    if (shiftKeys.containsKey(key)) return shiftKeys[key];
    return null;
  }

  /// English to Bengali mapping for typing
  static const Map<String, String> englishToBengali = {
    // Vowels
    'o': 'অ', 'a': 'া', 'i': 'ি', 'u': 'ু', 'e': 'ে',
    'A': 'আ', 'I': 'ী', 'U': 'ূ', 'E': 'ৈ', 'O': 'ঔ',
    'w': 'ও', 'W': 'ঊ', 'q': 'ৃ', 'Q': 'ঋ',
    // Consonants - Normal
    'k': 'ক', 'g': 'গ', 'c': 'চ', 'j': 'জ',
    't': 'ত', 'd': 'দ', 'n': 'ন',
    'p': 'প', 'f': 'ফ', 'b': 'ব', 'v': 'ভ', 'm': 'ম',
    'z': 'য', 'r': 'র', 'l': 'ল', 's': 'স', 'h': 'হ', 'y': 'য়',
    // Consonants - Shift (Aspirated/Retroflex)
    'K': 'খ', 'G': 'ঘ', 'C': 'ছ', 'J': 'ঝ',
    'T': 'ট', 'D': 'ড', 'N': 'ণ',
    'P': 'ফ', 'B': 'ভ', 'S': 'শ', 'H': 'ঃ',
    'R': 'ড়', 'Y': 'ঞ', 'M': 'ং', 'L': 'ল', 'Z': 'য',
    'V': 'ঙ', 'F': 'ৎ', 'X': 'ঢ়',
    // Numbers
    '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
    '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
    // Punctuation
    '.': '।', '`': '্', ':': 'ঃ', '^': 'ঁ', '\$': '৳',
  };

  /// Get display rows for virtual keyboard (Normal state) - Phonetic output
  static List<List<String>> getDisplayRows() {
    return [
      // Number row - Bengali numbers
      ['১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯', '০', '-', '=', '⌫'],
      // Top row: q w e r t y u i o p
      ['ৃ', 'ও', 'ে', 'র', 'ত', 'য়', 'ু', 'ি', 'অ', 'প'],
      // Home row: a s d f g h j k l
      ['া', 'স', 'দ', 'ফ', 'গ', 'হ', 'জ', 'ক', 'ল'],
      // Bottom row: z x c v b n m
      ['shift', 'য', 'ক্স', 'চ', 'ভ', 'ব', 'ন', 'ম', ',', '।', '/', 'shift'],
    ];
  }

  /// Get display rows for virtual keyboard (Shift state)
  static List<List<String>> getShiftDisplayRows() {
    return [
      // Number row with shift
      ['!', '@', '#', '৳', '%', 'ঁ', '&', '*', '(', ')', '_', '+', '⌫'],
      // Top row shifted: Q W E R T Y U I O P
      ['ঋ', 'ঊ', 'ৈ', 'ড়', 'ট', 'ঞ', 'ূ', 'ী', 'ঔ', 'ফ'],
      // Home row shifted: A S D F G H J K L
      ['আ', 'শ', 'ড', 'ৎ', 'ঘ', 'ঃ', 'ঝ', 'খ', 'ল'],
      // Bottom row shifted: Z X C V B N M
      ['shift', 'য', 'ঢ়', 'ছ', 'ঙ', 'ভ', 'ণ', 'ং', '<', '>', '?', 'shift'],
    ];
  }
  
  /// Common conjuncts formed automatically in Avro
  static const Map<String, String> commonConjuncts = {
    'kk': 'ক্ক', 'kt': 'ক্ত', 'kT': 'ক্ট', 'kb': 'ক্ব', 'km': 'ক্ম',
    'kl': 'ক্ল', 'kS': 'ক্ষ', 'ksh': 'ক্ষ',
    'gg': 'গ্গ', 'gn': 'গ্ন', 'gm': 'গ্ম', 'gl': 'গ্ল',
    'cc': 'চ্চ', 'jj': 'জ্জ', 'jY': 'জ্ঞ', 'jn': 'জ্ঞ',
    'tt': 'ত্ত', 'tn': 'ত্ন', 'tm': 'ত্ম', 'tr': 'ত্র', 'tb': 'ত্ব',
    'dd': 'দ্দ', 'db': 'দ্ব', 'dm': 'দ্ম', 'dh': 'ধ',
    'nn': 'ন্ন', 'nt': 'ন্ত', 'nd': 'ন্দ', 'nT': 'ন্ট', 'nD': 'ন্ড',
    'pp': 'প্প', 'pt': 'প্ত', 'pr': 'প্র', 'pl': 'প্ল',
    'bb': 'ব্ব', 'bd': 'ব্দ', 'bl': 'ব্ল', 'br': 'ব্র',
    'mm': 'ম্ম', 'mn': 'ম্ন', 'mr': 'ম্র', 'ml': 'ম্ল', 'mb': 'ম্ব',
    'ss': 'স্স', 'st': 'স্ত', 'sn': 'স্ন', 'sp': 'স্প', 'sr': 'স্র', 'sk': 'স্ক',
    'll': 'ল্ল', 'lk': 'ল্ক', 'lb': 'ল্ব', 'lm': 'ল্ম',
    'Shm': 'ষ্ম', 'ShT': 'ষ্ট', 'ShN': 'ষ্ণ',
  };
}
