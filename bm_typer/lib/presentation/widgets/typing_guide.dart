import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TypingGuide extends ConsumerWidget {
  final String currentCharacter;
  final bool isVisible;
  final bool isMobile;

  const TypingGuide({
    Key? key,
    required this.currentCharacter,
    required this.isVisible,
    this.isMobile = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDarkMode
          ? colorScheme.surfaceVariant.withOpacity(0.5)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFingerPositionGuide(context, currentCharacter),
            const Divider(height: 24),
            _buildTip(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerPositionGuide(BuildContext context, String char) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Get finger and key guidance based on character
    final (fingerGuidance, keyGuidance) = _getGuidanceForCharacter(char);

    // Determine which finger to use for the current character
    final fingerInfo = _getFingerForCharacter(char.toLowerCase());

    // Bengali translations for fingers and hands
    final fingerNameBn = _getBengliFinger(fingerInfo.finger);
    final handNameBn = _getBengliHand(fingerInfo.hand);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      char.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                fingerGuidance,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                keyGuidance,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return isMobile ? _buildMobileTips(context) : _buildDesktopTips(context);
  }

  Widget _buildMobileTips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.keyboard,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'আপনার আঙুলগুলি হোম রো-তে রাখুন (ASDF JKL;)',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.touch_app,
              color: colorScheme.secondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'কীবোর্ড নয়, স্ক্রিনে তাকান',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.psychology,
              color: colorScheme.tertiary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'টাইপিং করার সময় ভালো পসচার বজায় রাখুন',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopTips(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.keyboard,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'আপনার আঙুলগুলি হোম রো-তে রাখুন (ASDF JKL;)',
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 24),
        Icon(
          Icons.touch_app,
          color: colorScheme.secondary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'কীবোর্ড নয়, স্ক্রিনে তাকান',
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 24),
        Icon(
          Icons.psychology,
          color: colorScheme.tertiary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'ভালো পসচার বজায় রাখুন',
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  // Get Bengali finger name
  String _getBengliFinger(String finger) {
    switch (finger) {
      case 'pinky':
        return 'কনিষ্ঠ';
      case 'ring':
        return 'অনামিকা';
      case 'middle':
        return 'মধ্যমা';
      case 'index':
        return 'তর্জনী';
      case 'thumb':
        return 'বৃদ্ধাঙ্গুলি';
      default:
        return finger;
    }
  }

  // Get Bengali hand name
  String _getBengliHand(String hand) {
    switch (hand) {
      case 'left':
        return 'বাম';
      case 'right':
        return 'ডান';
      default:
        return hand;
    }
  }

  FingerInfo _getFingerForCharacter(String char) {
    // Define which finger is used for each character
    // Based on standard touch typing technique

    // Left hand
    if ('`1qaz'.contains(char)) {
      return FingerInfo('pinky', 'left');
    } else if ('2wsx'.contains(char)) {
      return FingerInfo('ring', 'left');
    } else if ('3edc'.contains(char)) {
      return FingerInfo('middle', 'left');
    } else if ('4rfv5tgb'.contains(char)) {
      return FingerInfo('index', 'left');
    }

    // Right hand
    else if ('6yhn7ujm'.contains(char)) {
      return FingerInfo('index', 'right');
    } else if ('8ik,'.contains(char)) {
      return FingerInfo('middle', 'right');
    } else if ('9ol.'.contains(char)) {
      return FingerInfo('ring', 'right');
    } else if ('0p;/[=]\\-_+'.contains(char)) {
      return FingerInfo('pinky', 'right');
    }

    // Space bar
    else if (char == ' ') {
      return FingerInfo('thumb', 'right');
    }

    // Default
    return FingerInfo('index', 'right');
  }

  // Helper method to get guidance based on character and current layout
  (String, String) _getGuidanceForCharacter(String character) {
    // Default guidance
    String fingerGuidance = 'সঠিক আঙ্গুল ব্যবহার করুন';
    String keyGuidance = 'কীবোর্ড নয়, স্ক্রিনে তাকান';

    // === PHONETIC BANGLA CHARACTER MAPPING ===
    // Check for Phonetic layout first (based on common Avro phonetic mapping)
    // Format: Bangla Character -> English Key (A, S, D, etc.)
    
    // --- PHONETIC HOME ROW (a s d f g h j k l) ---
    // Phonetic: া স দ ফ গ হ জ ক ল
    if (character == 'া') {
      fingerGuidance = 'বাম কনিষ্ঠা | A কী চাপুন (Phonetic)';
      keyGuidance = 'া-কার → A';
    } else if (character == 'স') {
      fingerGuidance = 'বাম অনামিকা | S কী চাপুন (Phonetic)';
      keyGuidance = 'স → S';
    } else if (character == 'দ') {
      fingerGuidance = 'বাম মধ্যমা | D কী চাপুন (Phonetic)';
      keyGuidance = 'দ → D';
    } else if (character == 'ফ') {
      fingerGuidance = 'বাম তর্জনী | F কী চাপুন (Phonetic)';
      keyGuidance = 'ফ → F';
    } else if (character == 'গ') {
      fingerGuidance = 'বাম তর্জনী | G কী চাপুন (Phonetic)';
      keyGuidance = 'গ → G';
    } else if (character == 'হ') {
      fingerGuidance = 'ডান তর্জনী | H কী চাপুন (Phonetic)';
      keyGuidance = 'হ → H';
    } else if (character == 'জ') {
      fingerGuidance = 'ডান তর্জনী | J কী চাপুন (Phonetic)';
      keyGuidance = 'জ → J';
    } else if (character == 'ক') {
      fingerGuidance = 'ডান মধ্যমা | K কী চাপুন (Phonetic)';
      keyGuidance = 'ক → K';
    } else if (character == 'ল') {
      fingerGuidance = 'ডান অনামিকা | L কী চাপুন (Phonetic)';
      keyGuidance = 'ল → L';
    }
    
    // --- PHONETIC TOP ROW (q w e r t y u i o p) ---
    // Phonetic: ৃ ও ে র ত য় ু ি অ প
    else if (character == 'ৃ') {
      fingerGuidance = 'বাম কনিষ্ঠা | Q কী চাপুন (Phonetic)';
      keyGuidance = 'ৃ-কার → Q';
    } else if (character == 'ও') {
      fingerGuidance = 'বাম অনামিকা | W কী চাপুন (Phonetic)';
      keyGuidance = 'ও → W';
    } else if (character == 'ে') {
      fingerGuidance = 'বাম মধ্যমা | E কী চাপুন (Phonetic)';
      keyGuidance = 'ে-কার → E';
    } else if (character == 'র') {
      fingerGuidance = 'বাম তর্জনী | R কী চাপুন (Phonetic)';
      keyGuidance = 'র → R';
    } else if (character == 'ত') {
      fingerGuidance = 'বাম তর্জনী | T কী চাপুন (Phonetic)';
      keyGuidance = 'ত → T';
    } else if (character == 'য়') {
      fingerGuidance = 'ডান তর্জনী | Y কী চাপুন (Phonetic)';
      keyGuidance = 'য় → Y';
    } else if (character == 'ু') {
      fingerGuidance = 'ডান তর্জনী | U কী চাপুন (Phonetic)';
      keyGuidance = 'ু-কার → U';
    } else if (character == 'ি') {
      fingerGuidance = 'ডান মধ্যমা | I কী চাপুন (Phonetic)';
      keyGuidance = 'ি-কার → I';
    } else if (character == 'অ') {
      fingerGuidance = 'ডান অনামিকা | O কী চাপুন (Phonetic)';
      keyGuidance = 'অ → O';
    } else if (character == 'প') {
      fingerGuidance = 'ডান কনিষ্ঠা | P কী চাপুন (Phonetic)';
      keyGuidance = 'প → P';
    }
    
    // --- PHONETIC BOTTOM ROW (z x c v b n m) ---
    // Phonetic: য ক্স চ ভ ব ন ম
    else if (character == 'য') {
      fingerGuidance = 'বাম কনিষ্ঠা | Z কী চাপুন (Phonetic)';
      keyGuidance = 'য → Z';
    } else if (character == 'চ') {
      fingerGuidance = 'বাম মধ্যমা | C কী চাপুন (Phonetic)';
      keyGuidance = 'চ → C';
    } else if (character == 'ভ') {
      fingerGuidance = 'বাম তর্জনী | V কী চাপুন (Phonetic)';
      keyGuidance = 'ভ → V';
    } else if (character == 'ব') {
      fingerGuidance = 'বাম তর্জনী | B কী চাপুন (Phonetic)';
      keyGuidance = 'ব → B';
    } else if (character == 'ন') {
      fingerGuidance = 'ডান তর্জনী | N কী চাপুন (Phonetic)';
      keyGuidance = 'ন → N';
    } else if (character == 'ম') {
      fingerGuidance = 'ডান তর্জনী | M কী চাপুন (Phonetic)';
      keyGuidance = 'ম → M';
    }
    
    // --- PHONETIC SHIFT ROW (Shift + Keys = Aspirated/Retroflex) ---
    else if (character == 'আ') {
      fingerGuidance = 'বাম কনিষ্ঠা | Shift + A চাপুন (Phonetic)';
      keyGuidance = 'আ → Shift + A';
    } else if (character == 'শ') {
      fingerGuidance = 'বাম অনামিকা | Shift + S চাপুন (Phonetic)';
      keyGuidance = 'শ → Shift + S';
    } else if (character == 'ড') {
      fingerGuidance = 'বাম মধ্যমা | Shift + D চাপুন (Phonetic)';
      keyGuidance = 'ড → Shift + D';
    } else if (character == 'ট') {
      fingerGuidance = 'বাম তর্জনী | Shift + T চাপুন (Phonetic)';
      keyGuidance = 'ট → Shift + T';
    } else if (character == 'ঘ') {
      fingerGuidance = 'বাম তর্জনী | Shift + G চাপুন (Phonetic)';
      keyGuidance = 'ঘ → Shift + G';
    } else if (character == 'খ') {
      fingerGuidance = 'ডান মধ্যমা | Shift + K চাপুন (Phonetic)';
      keyGuidance = 'খ → Shift + K';
    } else if (character == 'ঝ') {
      fingerGuidance = 'ডান তর্জনী | Shift + J চাপুন (Phonetic)';
      keyGuidance = 'ঝ → Shift + J';
    } else if (character == 'ছ') {
      fingerGuidance = 'বাম মধ্যমা | Shift + C চাপুন (Phonetic)';
      keyGuidance = 'ছ → Shift + C';
    } else if (character == 'ণ') {
      fingerGuidance = 'ডান তর্জনী | Shift + N চাপুন (Phonetic)';
      keyGuidance = 'ণ → Shift + N';
    } else if (character == 'ং') {
      fingerGuidance = 'ডান তর্জনী | Shift + M চাপুন (Phonetic)';
      keyGuidance = 'ং → Shift + M';
    } else if (character == 'ী') {
      fingerGuidance = 'ডান মধ্যমা | Shift + I চাপুন (Phonetic)';
      keyGuidance = 'ী-কার → Shift + I';
    } else if (character == 'ূ') {
      fingerGuidance = 'ডান তর্জনী | Shift + U চাপুন (Phonetic)';
      keyGuidance = 'ূ-কার → Shift + U';
    } else if (character == 'ৈ') {
      fingerGuidance = 'বাম মধ্যমা | Shift + E চাপুন (Phonetic)';
      keyGuidance = 'ৈ-কার → Shift + E';
    } else if (character == 'ঔ') {
      fingerGuidance = 'ডান অনামিকা | Shift + O চাপুন (Phonetic)';
      keyGuidance = 'ঔ → Shift + O';
    } else if (character == 'ঋ') {
      fingerGuidance = 'বাম কনিষ্ঠা | Shift + Q চাপুন (Phonetic)';
      keyGuidance = 'ঋ → Shift + Q';
    } else if (character == 'ড়') {
      fingerGuidance = 'বাম তর্জনী | Shift + R চাপুন (Phonetic)';
      keyGuidance = 'ড় → Shift + R';
    } else if (character == 'ঞ') {
      fingerGuidance = 'ডান তর্জনী | Shift + Y চাপুন (Phonetic)';
      keyGuidance = 'ঞ → Shift + Y';
    } else if (character == 'ঃ') {
      fingerGuidance = 'ডান তর্জনী | Shift + H চাপুন (Phonetic)';
      keyGuidance = 'বিসর্গ → Shift + H';
    } else if (character == 'ৎ') {
      fingerGuidance = 'বাম তর্জনী | Shift + F চাপুন (Phonetic)';
      keyGuidance = 'খণ্ড-ত → Shift + F';
    } else if (character == 'ঙ') {
      fingerGuidance = 'বাম তর্জনী | Shift + V চাপুন (Phonetic)';
      keyGuidance = 'ঙ → Shift + V';
    }
    
    // --- PHONETIC NUMBERS ---
    else if (character == '০') {
      fingerGuidance = 'ডান কনিষ্ঠা | 0 কী চাপুন';
      keyGuidance = '০ (শূন্য) → 0';
    } else if (character == '১') {
      fingerGuidance = 'বাম কনিষ্ঠা | 1 কী চাপুন';
      keyGuidance = '১ (এক) → 1';
    } else if (character == '২') {
      fingerGuidance = 'বাম অনামিকা | 2 কী চাপুন';
      keyGuidance = '২ (দুই) → 2';
    } else if (character == '৩') {
      fingerGuidance = 'বাম মধ্যমা | 3 কী চাপুন';
      keyGuidance = '৩ (তিন) → 3';
    } else if (character == '৪') {
      fingerGuidance = 'বাম তর্জনী | 4 কী চাপুন';
      keyGuidance = '৪ (চার) → 4';
    } else if (character == '৫') {
      fingerGuidance = 'বাম তর্জনী | 5 কী চাপুন';
      keyGuidance = '৫ (পাঁচ) → 5';
    } else if (character == '৬') {
      fingerGuidance = 'ডান তর্জনী | 6 কী চাপুন';
      keyGuidance = '৬ (ছয়) → 6';
    } else if (character == '৭') {
      fingerGuidance = 'ডান তর্জনী | 7 কী চাপুন';
      keyGuidance = '৭ (সাত) → 7';
    } else if (character == '৮') {
      fingerGuidance = 'ডান মধ্যমা | 8 কী চাপুন';
      keyGuidance = '৮ (আট) → 8';
    } else if (character == '৯') {
      fingerGuidance = 'ডান অনামিকা | 9 কী চাপুন';
      keyGuidance = '৯ (নয়) → 9';
    }
    
    // --- COMMON PUNCTUATION ---
    else if (character == '।') {
      fingerGuidance = 'ডান অনামিকা | . (Period) কী চাপুন';
      keyGuidance = 'দাড়ি → . (Period)';
    } else if (character == '্') {
      fingerGuidance = 'বাম কনিষ্ঠা | ` (Backtick) কী চাপুন';
      keyGuidance = 'হসন্ত → ` (Backtick)';
    } else if (character == ' ') {
      fingerGuidance = 'বৃদ্ধাঙ্গুলি | স্পেসবার চাপুন';
      keyGuidance = 'স্পেস → Space Bar';
    }
    
    // === ENGLISH CHARACTER MAPPING ===
    else {
      switch (character.toLowerCase()) {
        case 'a':
          fingerGuidance = 'বাম কনিষ্ঠা | A কী চাপুন';
          keyGuidance = 'A কী-টি হোম রো-এর বাম দিকে অবস্থিত';
          break;
        case 's':
          fingerGuidance = 'বাম অনামিকা | S কী চাপুন';
          keyGuidance = 'S কী-টি হোম রো-তে A এর পাশে';
          break;
        case 'd':
          fingerGuidance = 'বাম মধ্যমা | D কী চাপুন';
          keyGuidance = 'D কী-টি হোম রো-তে S এর পাশে';
          break;
        case 'f':
          fingerGuidance = 'বাম তর্জনী | F কী চাপুন';
          keyGuidance = 'F কী-টি হোম পজিশন (বাম তর্জনী)';
          break;
        case 'g':
          fingerGuidance = 'বাম তর্জনী | G কী চাপুন';
          keyGuidance = 'G কী-টি F এর পাশে';
          break;
        case 'h':
          fingerGuidance = 'ডান তর্জনী | H কী চাপুন';
          keyGuidance = 'H কী-টি G এর পাশে';
          break;
        case 'j':
          fingerGuidance = 'ডান তর্জনী | J কী চাপুন';
          keyGuidance = 'J কী-টি হোম পজিশন (ডান তর্জনী)';
          break;
        case 'k':
          fingerGuidance = 'ডান মধ্যমা | K কী চাপুন';
          keyGuidance = 'K কী-টি J এর পাশে';
          break;
        case 'l':
          fingerGuidance = 'ডান অনামিকা | L কী চাপুন';
          keyGuidance = 'L কী-টি K এর পাশে';
          break;
        case ';':
          fingerGuidance = 'ডান কনিষ্ঠা | ; কী চাপুন';
          keyGuidance = '; কী-টি L এর পাশে';
          break;
        default:
          if (character.isEmpty) {
            fingerGuidance = 'পরবর্তী অক্ষরের জন্য প্রস্তুত হোন';
            keyGuidance = 'হোম রো-তে আঙ্গুল রাখুন (ASDF JKL;)';
          }
      }
    }

    return (fingerGuidance, keyGuidance);
  }
}

class FingerInfo {
  final String finger;
  final String hand;

  FingerInfo(this.finger, this.hand);
}
