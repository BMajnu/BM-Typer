/// Unicode Normalization Utilities for Bengali Text
/// 
/// Handles Bengali characters that can have both composed (NFC) and 
/// decomposed (NFD) Unicode representations.
/// 
/// Characters with nukta (dot below):
/// - য় = য (U+09AF) + ◌̣ (U+09BC) → য় (U+09DF)
/// - ড় = ড (U+09A1) + ◌̣ (U+09BC) → ড় (U+09DC)  
/// - ঢ় = ঢ (U+09A2) + ◌̣ (U+09BC) → ঢ় (U+09DD)
/// 
/// Conjuncts (ফলা) that are typed with single keys in Bijoy:
/// - র-ফলা (্র) = ্ (U+09CD) + র (U+09B0) - typed with Z key
/// - য-ফলা (্য) = ্ (U+09CD) + য (U+09AF) - typed with Shift+Z key
/// - রেফ (র্) = র (U+09B0) + ্ (U+09CD) - typed with Shift+A key

class BengaliNormalizer {
  
  /// Bengali Nukta (sign nukta) - the dot that appears below letters
  static const String nukta = '\u09BC'; // ◌̣
  
  /// Bengali Hasanta (virama) - the killer mark
  static const String hasanta = '\u09CD'; // ্
  
  /// Mapping of decomposed (base + nukta) to composed forms
  static const Map<String, String> _decomposedToComposed = {
    'য\u09BC': 'য়',  // য + nukta → য়
    'ড\u09BC': 'ড়',  // ড + nukta → ড়
    'ঢ\u09BC': 'ঢ়',  // ঢ + nukta → ঢ়
  };
  
  /// Conjuncts (ফলা) - these are typed as single keys in Bijoy but stored as 2 chars
  /// Note: We DON'T normalize these as they need to stay as 2 chars for proper rendering.
  /// Instead, we use special markers to indicate they should be treated as single units.
  static const String roPhola = '্র';  // র-ফলা (hasanta + ra)
  static const String joPhola = '্য';  // য-ফলা (hasanta + ya)
  static const String ref = 'র্';      // রেফ (ra + hasanta)
  
  /// Normalize Bengali text to NFC (Canonical Composition)
  /// This ensures য়, ড়, ঢ় are represented as single composed characters
  static String normalize(String text) {
    String normalized = text;
    
    // Replace all decomposed nukta forms with composed forms
    for (final entry in _decomposedToComposed.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    
    return normalized;
  }
  
  /// Check if two strings are equal after normalization
  static bool equals(String a, String b) {
    return normalize(a) == normalize(b);
  }
  
  /// Check if a character is nukta
  static bool isNukta(String char) {
    return char == nukta;
  }
  
  /// Check if a character is hasanta
  static bool isHasanta(String char) {
    return char == hasanta;
  }
  
  /// Check if a character is a base consonant that can take nukta
  static bool canHaveNukta(String char) {
    return char == 'য' || char == 'ড' || char == 'ঢ';
  }
  
  /// Get the composed form if the character + nukta combination exists
  static String? getComposedForm(String baseChar, String nuktaChar) {
    if (nuktaChar != nukta) return null;
    switch (baseChar) {
      case 'য': return 'য়';
      case 'ড': return 'ড়';
      case 'ঢ': return 'ঢ়';
      default: return null;
    }
  }
  
  /// Check if starting at the given index, there's a conjunct (phola/ref)
  /// Returns the length of the conjunct if found (2 for phola/ref), 1 otherwise
  static int getClusterLength(String text, int index) {
    if (index >= text.length) return 0;
    if (index >= text.length - 1) return 1;
    
    final twoChars = text.substring(index, index + 2);
    
    // Check for র-ফলা, য-ফলা, or রেফ
    if (twoChars == roPhola || twoChars == joPhola || twoChars == ref) {
      return 2;
    }
    
    return 1;
  }
  
  /// Check if a 2-character sequence is a single-key typeable conjunct in Bijoy
  static bool isConjunct(String chars) {
    return chars == roPhola || chars == joPhola || chars == ref;
  }
  
  /// Get the full conjunct starting at the given index
  static String getCluster(String text, int index) {
    final length = getClusterLength(text, index);
    if (index + length <= text.length) {
      return text.substring(index, index + length);
    }
    return text[index];
  }
}

