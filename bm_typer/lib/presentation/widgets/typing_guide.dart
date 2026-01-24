import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TypingGuide extends ConsumerWidget {
  final String currentCharacter;
  final bool isVisible;
  final bool isMobile;
  final bool isNumpad; // true for numpad lessons, false for regular keyboard
  final String exerciseType; // 'bijoy', 'phonetic', 'qwerty', or 'numpad'

  const TypingGuide({
    Key? key,
    required this.currentCharacter,
    required this.isVisible,
    this.isMobile = true,
    this.isNumpad = false,
    this.exerciseType = 'qwerty',
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

    // Get finger and key guidance based on character and exercise type
    final (fingerGuidance, keyGuidance) = isNumpad 
        ? _getNumpadGuidance(char) 
        : _getGuidanceForCharacter(char, exerciseType);

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
  (String, String) _getGuidanceForCharacter(String character, String exerciseType) {
    String fingerGuidance = 'সঠিক আঙ্গুল ব্যবহার করুন';
    String keyGuidance = 'কীবোর্ড নয়, স্ক্রিনে তাকান';
    
    // Check if character is uppercase (English only logic for Shift)
    bool isUpperCase = character.contains(RegExp(r'[A-Z]'));
    String lowerChar = character.toLowerCase();

    // Check if it's Bangla character
    bool isBangla = character.contains(RegExp(r'[\u0980-\u09FF]'));
    
    // === BIJOY BANGLA CHARACTER MAPPING ===
    if (exerciseType.toLowerCase() == 'bijoy' && isBangla) {
      return _getBijoyGuidance(character);
    }
    
    // === PHONETIC BANGLA CHARACTER MAPPING ===
    if ((exerciseType.toLowerCase() == 'phonetic' || exerciseType.isEmpty) && isBangla) {
      return _getPhoneticGuidance(character);
    }
    
    // If Bangla but no specific type matched, try to detect
    if (isBangla) {
      // Default to Phonetic for unspecified Bangla
      return _getPhoneticGuidance(character);
    }

    // Space (common for all)
    if (character == ' ') return ('বৃদ্ধাঙ্গুলি | স্পেসবার চাপুন', 'স্পেস → Space Bar');
    
    // Numbers
    if (character == '০') return ('ডান কনিষ্ঠা | 0 কী চাপুন', '০ (শূন্য) → 0');
    if (character == '১') return ('বাম কনিষ্ঠা | 1 কী চাপুন', '১ (এক) → 1');
    if (character == '২') return ('বাম অনামিকা | 2 কী চাপুন', '২ (দুই) → 2');
    if (character == '৩') return ('বাম মধ্যমা | 3 কী চাপুন', '৩ (তিন) → 3');
    if (character == '৪') return ('বাম তর্জনী | 4 কী চাপুন', '৪ (চার) → 4');
    if (character == '৫') return ('বাম তর্জনী | 5 কী চাপুন', '৫ (পাঁচ) → 5');
    if (character == '৬') return ('ডান তর্জনী | 6 কী চাপুন', '৬ (ছয়) → 6');
    if (character == '৭') return ('ডান তর্জনী | 7 কী চাপুন', '৭ (সাত) → 7');
    if (character == '৮') return ('ডান মধ্যমা | 8 কী চাপুন', '৮ (আট) → 8');
    if (character == '৯') return ('ডান অনামিকা | 9 কী চাপুন', '৯ (নয়) → 9');

    // Punctuation
    if (character == '।') return ('ডান অনামিকা | . (Period) কী চাপুন', 'দাড়ি → . (Period)');
    if (character == '্') return ('বাম কনিষ্ঠা | G কী চাপুন (Bijoy)', 'হসন্ত → G');

    // === ENGLISH CHARACTER MAPPING (EXPANDED) ===
    
    // Helper to determine shift hand
    // Left hand keys: Q W E R T A S D F G Z X C V B
    // Right hand keys: Y U I O P H J K L N M 
    bool isLeftHandKey = 'qwertasdfgzxcvb'.contains(lowerChar);
    
    String shiftPrefix = '';
    String shiftDesc = '';
    
    if (isUpperCase) {
      if (isLeftHandKey) {
        shiftPrefix = 'ডান কনিষ্ঠা (Shift) + ';
        shiftDesc = 'Shift (ডান) + ';
      } else {
        shiftPrefix = 'বাম কনিষ্ঠা (Shift) + ';
        shiftDesc = 'Shift (বাম) + ';
      }
    }

    switch (lowerChar) {
      // --- TOP ROW ---
      case 'q':
        fingerGuidance = '${shiftPrefix}বাম কনিষ্ঠা | ${isUpperCase ? "Q" : "q"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "Q" : "q"} কী-টি কিবোর্ডের উপরের সারির বাম প্রান্তে';
        break;
      case 'w':
        fingerGuidance = '${shiftPrefix}বাম অনামিকা | ${isUpperCase ? "W" : "w"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "W" : "w"} কী-টি Q এর পাশে';
        break;
      case 'e':
        fingerGuidance = '${shiftPrefix}বাম মধ্যমা | ${isUpperCase ? "E" : "e"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "E" : "e"} কী-টি W এর পাশে';
        break;
      case 'r':
        fingerGuidance = '${shiftPrefix}বাম তর্জনী | ${isUpperCase ? "R" : "r"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "R" : "r"} কী-টি E এর পাশে';
        break;
      case 't':
        fingerGuidance = '${shiftPrefix}বাম তর্জনী | ${isUpperCase ? "T" : "t"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "T" : "t"} কী-টি R এর পাশে';
        break;
      case 'y':
        fingerGuidance = '${shiftPrefix}ডান তর্জনী | ${isUpperCase ? "Y" : "y"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "Y" : "y"} কী-টি কিবোর্ডের মাঝ বরাবর উপরে';
        break;
      case 'u':
        fingerGuidance = '${shiftPrefix}ডান তর্জনী | ${isUpperCase ? "U" : "u"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "U" : "u"} কী-টি Y এর পাশে';
        break;
      case 'i':
        fingerGuidance = '${shiftPrefix}ডান মধ্যমা | ${isUpperCase ? "I" : "i"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "I" : "i"} কী-টি U এর পাশে';
        break;
      case 'o':
        fingerGuidance = '${shiftPrefix}ডান অনামিকা | ${isUpperCase ? "O" : "o"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "O" : "o"} কী-টি I এর পাশে';
        break;
      case 'p':
        fingerGuidance = '${shiftPrefix}ডান কনিষ্ঠা | ${isUpperCase ? "P" : "p"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "P" : "p"} কী-টি O এর পাশে';
        break;

      // --- HOME ROW ---
      case 'a':
        fingerGuidance = '${shiftPrefix}বাম কনিষ্ঠা | ${isUpperCase ? "A" : "a"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "A" : "a"} কী-টি হোম রো-এর বাম প্রান্তে';
        break;
      case 's':
        fingerGuidance = '${shiftPrefix}বাম অনামিকা | ${isUpperCase ? "S" : "s"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "S" : "s"} কী-টি A এর পাশে';
        break;
      case 'd':
        fingerGuidance = '${shiftPrefix}বাম মধ্যমা | ${isUpperCase ? "D" : "d"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "D" : "d"} কী-টি S এর পাশে';
        break;
      case 'f':
        fingerGuidance = '${shiftPrefix}বাম তর্জনী | ${isUpperCase ? "F" : "f"} কী চাপুন';
        keyGuidance = 'এটি বাম তর্জনীর হোম পজিশন';
        break;
      case 'g':
        fingerGuidance = '${shiftPrefix}বাম তর্জনী | ${isUpperCase ? "G" : "g"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "G" : "g"} কী-টি F এর পাশে';
        break;
      case 'h':
        fingerGuidance = '${shiftPrefix}ডান তর্জনী | ${isUpperCase ? "H" : "h"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "H" : "h"} কী-টি J এর পাশে';
        break;
      case 'j':
        fingerGuidance = '${shiftPrefix}ডান তর্জনী | ${isUpperCase ? "J" : "j"} কী চাপুন';
        keyGuidance = 'এটি ডান তর্জনীর হোম পজিশন';
        break;
      case 'k':
        fingerGuidance = '${shiftPrefix}ডান মধ্যমা | ${isUpperCase ? "K" : "k"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "K" : "k"} কী-টি J এর পাশে';
        break;
      case 'l':
        fingerGuidance = '${shiftPrefix}ডান অনামিকা | ${isUpperCase ? "L" : "l"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "L" : "l"} কী-টি K এর পাশে';
        break;
      case ';':
        fingerGuidance = '${shiftPrefix}ডান কনিষ্ঠা | ; কী চাপুন';
        keyGuidance = '; কী-টি L এর পাশে';
        break;
      case ':':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান কনিষ্ঠা | : কী চাপুন';
        keyGuidance = 'Shift + ; চাপুন';
        break;

      // --- BOTTOM ROW ---
      case 'z':
        fingerGuidance = '${shiftPrefix}বাম কনিষ্ঠা | ${isUpperCase ? "Z" : "z"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "Z" : "z"} কী-টি নিচের সারির বাম প্রান্তে';
        break;
      case 'x':
        fingerGuidance = '${shiftPrefix}বাম অনামিকা | ${isUpperCase ? "X" : "x"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "X" : "x"} কী-টি Z এর পাশে';
        break;
      case 'c':
        fingerGuidance = '${shiftPrefix}বাম মধ্যমা | ${isUpperCase ? "C" : "c"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "C" : "c"} কী-টি X এর পাশে';
        break;
      case 'v':
        fingerGuidance = '${shiftPrefix}বাম তর্জনী | ${isUpperCase ? "V" : "v"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "V" : "v"} কী-টি C এর পাশে';
        break;
      case 'b':
        fingerGuidance = '${shiftPrefix}বাম তর্জনী | ${isUpperCase ? "B" : "b"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "B" : "b"} কী-টি V এর পাশে';
        break;
      case 'n':
        fingerGuidance = '${shiftPrefix}ডান তর্জনী | ${isUpperCase ? "N" : "n"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "N" : "n"} কী-টি J এর নিচে';
        break;
      case 'm':
        fingerGuidance = '${shiftPrefix}ডান তর্জনী | ${isUpperCase ? "M" : "m"} কী চাপুন';
        keyGuidance = '${shiftDesc}${isUpperCase ? "M" : "m"} কী-টি N এর পাশে';
        break;
      case ',':
        fingerGuidance = 'ডান মধ্যমা | , (Comma) কী চাপুন';
        keyGuidance = ', কী-টি M এর পাশে';
        break;
      case '<':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান মধ্যমা | < কী চাপুন';
        keyGuidance = 'Shift + , চাপুন';
        break;
      case '.':
        fingerGuidance = 'ডান অনামিকা | . (Period) কী চাপুন';
        keyGuidance = '. কী-টি , এর পাশে';
        break;
      case '>':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান অনামিকা | > কী চাপুন';
        keyGuidance = 'Shift + . চাপুন';
        break;
      case '/':
        fingerGuidance = 'ডান কনিষ্ঠা | / (Slash) কী চাপুন';
        keyGuidance = '/ কী-টি . এর পাশে';
        break;
      case '?':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান কনিষ্ঠা | ? কী চাপুন';
        keyGuidance = 'Shift + / চাপুন';
        break;

      // --- NUMBER ROW (Top Row Numbers) ---
      case '1':
        fingerGuidance = 'বাম কনিষ্ঠা | 1 কী চাপুন';
        keyGuidance = '1 কী-টি Q এর উপরে, নাম্বার সারিতে';
        break;
      case '!':
        fingerGuidance = 'ডান কনিষ্ঠা (Shift) + বাম কনিষ্ঠা | ! কী চাপুন';
        keyGuidance = 'Shift + 1 চাপুন';
        break;
      case '2':
        fingerGuidance = 'বাম অনামিকা | 2 কী চাপুন';
        keyGuidance = '2 কী-টি W এর উপরে';
        break;
      case '@':
        fingerGuidance = 'ডান কনিষ্ঠা (Shift) + বাম অনামিকা | @ কী চাপুন';
        keyGuidance = 'Shift + 2 চাপুন';
        break;
      case '3':
        fingerGuidance = 'বাম মধ্যমা | 3 কী চাপুন';
        keyGuidance = '3 কী-টি E এর উপরে';
        break;
      case '#':
        fingerGuidance = 'ডান কনিষ্ঠা (Shift) + বাম মধ্যমা | # কী চাপুন';
        keyGuidance = 'Shift + 3 চাপুন';
        break;
      case '4':
        fingerGuidance = 'বাম তর্জনী | 4 কী চাপুন';
        keyGuidance = '4 কী-টি R এর উপরে';
        break;
      case '\$':
        fingerGuidance = 'ডান কনিষ্ঠা (Shift) + বাম তর্জনী | \$ কী চাপুন';
        keyGuidance = 'Shift + 4 চাপুন';
        break;
      case '5':
        fingerGuidance = 'বাম তর্জনী | 5 কী চাপুন';
        keyGuidance = '5 কী-টি T এর উপরে';
        break;
      case '%':
        fingerGuidance = 'ডান কনিষ্ঠা (Shift) + বাম তর্জনী | % কী চাপুন';
        keyGuidance = 'Shift + 5 চাপুন';
        break;
      case '6':
        fingerGuidance = 'ডান তর্জনী | 6 কী চাপুন';
        keyGuidance = '6 কী-টি Y এর উপরে';
        break;
      case '^':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান তর্জনী | ^ কী চাপুন';
        keyGuidance = 'Shift + 6 চাপুন';
        break;
      case '7':
        fingerGuidance = 'ডান তর্জনী | 7 কী চাপুন';
        keyGuidance = '7 কী-টি U এর উপরে';
        break;
      case '&':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান তর্জনী | & কী চাপুন';
        keyGuidance = 'Shift + 7 চাপুন';
        break;
      case '8':
        fingerGuidance = 'ডান মধ্যমা | 8 কী চাপুন';
        keyGuidance = '8 কী-টি I এর উপরে';
        break;
      case '*':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান মধ্যমা | * কী চাপুন';
        keyGuidance = 'Shift + 8 চাপুন';
        break;
      case '9':
        fingerGuidance = 'ডান অনামিকা | 9 কী চাপুন';
        keyGuidance = '9 কী-টি O এর উপরে';
        break;
      case '(':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান অনামিকা | ( কী চাপুন';
        keyGuidance = 'Shift + 9 চাপুন';
        break;
      case '0':
        fingerGuidance = 'ডান কনিষ্ঠা | 0 কী চাপুন';
        keyGuidance = '0 কী-টি P এর উপরে';
        break;
      case ')':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান কনিষ্ঠা | ) কী চাপুন';
        keyGuidance = 'Shift + 0 চাপুন';
        break;
      case '-':
        fingerGuidance = 'ডান কনিষ্ঠা | - (Hyphen) কী চাপুন';
        keyGuidance = '- কী-টি 0 এর পাশে';
        break;
      case '_':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান কনিষ্ঠা | _ কী চাপুন';
        keyGuidance = 'Shift + - চাপুন';
        break;
      case '=':
        fingerGuidance = 'ডান কনিষ্ঠা | = (Equal) কী চাপুন';
        keyGuidance = '= কী-টি - এর পাশে';
        break;
      case '+':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান কনিষ্ঠা | + কী চাপুন';
        keyGuidance = 'Shift + = চাপুন';
        break;
      case '`':
        fingerGuidance = 'বাম কনিষ্ঠা | ` (Backtick) কী চাপুন';
        keyGuidance = '` কী-টি 1 এর বামে';
        break;
      case '~':
        fingerGuidance = 'ডান কনিষ্ঠা (Shift) + বাম কনিষ্ঠা | ~ কী চাপুন';
        keyGuidance = 'Shift + ` চাপুন';
        break;
      case '[':
        fingerGuidance = 'ডান কনিষ্ঠা | [ কী চাপুন';
        keyGuidance = '[ কী-টি P এর পাশে';
        break;
      case '{':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান কনিষ্ঠা | { কী চাপুন';
        keyGuidance = 'Shift + [ চাপুন';
        break;
      case ']':
        fingerGuidance = 'ডান কনিষ্ঠা | ] কী চাপুন';
        keyGuidance = '] কী-টি [ এর পাশে';
        break;
      case '}':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান কনিষ্ঠা | } কী চাপুন';
        keyGuidance = 'Shift + ] চাপুন';
        break;
      case '\\':
        fingerGuidance = 'ডান কনিষ্ঠা | \\ (Backslash) কী চাপুন';
        keyGuidance = '\\ কী-টি ] এর পাশে';
        break;
      case '|':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান কনিষ্ঠা | | কী চাপুন';
        keyGuidance = 'Shift + \\ চাপুন';
        break;
      case '\'':
        fingerGuidance = 'ডান কনিষ্ঠা | \' (Apostrophe) কী চাপুন';
        keyGuidance = '\' কী-টি ; এর পাশে';
        break;
      case '"':
        fingerGuidance = 'বাম কনিষ্ঠা (Shift) + ডান কনিষ্ঠা | " কী চাপুন';
        keyGuidance = 'Shift + \' চাপুন';
        break;
        
      default:
        if (character.isEmpty) {
          fingerGuidance = 'পরবর্তী অক্ষরের জন্য প্রস্তুত হোন';
          keyGuidance = 'হোম রো-তে আঙ্গুল রাখুন (ASDF JKL;)';
        }
    }

    return (fingerGuidance, keyGuidance);
  }

  // Numpad-specific guidance (Right hand only)
  // Home position: 4-5-6
  // Index: 1, 4, 7, 0 | Middle: 2, 5, 8, . | Ring: 3, 6, 9 | Pinky: Enter, +, -
  (String, String) _getNumpadGuidance(String character) {
    String fingerGuidance = 'ডান হাত ব্যবহার করুন (নাম্বার প্যাড)';
    String keyGuidance = 'হোম পজিশন: 4-5-6';

    switch (character) {
      // Index Finger (তর্জনী) - 1, 4, 7, 0
      case '1':
        fingerGuidance = 'ডান তর্জনী | Numpad 1 চাপুন';
        keyGuidance = '1 কী-টি নাম্বার প্যাডের নিচের বাম দিকে';
        break;
      case '4':
        fingerGuidance = 'ডান তর্জনী | Numpad 4 চাপুন (হোম পজিশন)';
        keyGuidance = '4 কী-টি তর্জনীর হোম পজিশন';
        break;
      case '7':
        fingerGuidance = 'ডান তর্জনী | Numpad 7 চাপুন';
        keyGuidance = '7 কী-টি নাম্বার প্যাডের উপরের বাম দিকে';
        break;
      case '0':
        fingerGuidance = 'ডান বৃদ্ধাঙ্গুলি/তর্জনী | Numpad 0 চাপুন';
        keyGuidance = '0 কী-টি নাম্বার প্যাডের সবচেয়ে নিচে (বড় কী)';
        break;

      // Middle Finger (মধ্যমা) - 2, 5, 8, .
      case '2':
        fingerGuidance = 'ডান মধ্যমা | Numpad 2 চাপুন';
        keyGuidance = '2 কী-টি নাম্বার প্যাডের নিচের মাঝে';
        break;
      case '5':
        fingerGuidance = 'ডান মধ্যমা | Numpad 5 চাপুন (হোম পজিশন)';
        keyGuidance = '5 কী-টি মধ্যমার হোম পজিশন (উঁচু বাম্প আছে)';
        break;
      case '8':
        fingerGuidance = 'ডান মধ্যমা | Numpad 8 চাপুন';
        keyGuidance = '8 কী-টি নাম্বার প্যাডের উপরের মাঝে';
        break;
      case '.':
        fingerGuidance = 'ডান মধ্যমা | Numpad . (Decimal) চাপুন';
        keyGuidance = '. কী-টি 0 এর ডানে';
        break;

      // Ring Finger (অনামিকা) - 3, 6, 9
      case '3':
        fingerGuidance = 'ডান অনামিকা | Numpad 3 চাপুন';
        keyGuidance = '3 কী-টি নাম্বার প্যাডের নিচের ডানে';
        break;
      case '6':
        fingerGuidance = 'ডান অনামিকা | Numpad 6 চাপুন (হোম পজিশন)';
        keyGuidance = '6 কী-টি অনামিকার হোম পজিশন';
        break;
      case '9':
        fingerGuidance = 'ডান অনামিকা | Numpad 9 চাপুন';
        keyGuidance = '9 কী-টি নাম্বার প্যাডের উপরের ডানে';
        break;

      // Pinky Finger (কনিষ্ঠা) - Enter, +, -
      case '+':
        fingerGuidance = 'ডান কনিষ্ঠা | Numpad + চাপুন';
        keyGuidance = '+ কী-টি নাম্বার প্যাডের ডান পাশে';
        break;
      case '-':
        fingerGuidance = 'ডান কনিষ্ঠা | Numpad - চাপুন';
        keyGuidance = '- কী-টি নাম্বার প্যাডের উপরের ডানে';
        break;
      case '*':
        fingerGuidance = 'ডান অনামিকা | Numpad * চাপুন';
        keyGuidance = '* কী-টি - এর বামে';
        break;
      case '/':
        fingerGuidance = 'ডান মধ্যমা | Numpad / চাপুন';
        keyGuidance = '/ কী-টি * এর বামে';
        break;

      default:
        fingerGuidance = 'ডান হাত ব্যবহার করুন';
        keyGuidance = 'হোম পজিশন: তর্জনী-4, মধ্যমা-5, অনামিকা-6';
    }

    return (fingerGuidance, keyGuidance);
  }

  // === BIJOY KEYBOARD MAPPING ===
  // Source: lib/core/constants/layouts/bijoy_layout.dart (Official Bijoy Bayanno)
  (String, String) _getBijoyGuidance(String character) {
    switch (character) {
      // === NORMAL KEYS (Without Shift) ===
      
      // Top Row (Q-P) - Normal
      case 'ঙ': return ('বাম কনিষ্ঠা | Q কী চাপুন (Bijoy)', 'ঙ → Q');
      case 'য': return ('বাম অনামিকা | W কী চাপুন (Bijoy)', 'য → W');
      case 'ড': return ('বাম মধ্যমা | E কী চাপুন (Bijoy)', 'ড → E');
      case 'প': return ('বাম তর্জনী | R কী চাপুন (Bijoy)', 'প → R');
      case 'ট': return ('বাম তর্জনী | T কী চাপুন (Bijoy)', 'ট → T');
      case 'চ': return ('ডান তর্জনী | Y কী চাপুন (Bijoy)', 'চ → Y');
      case 'জ': return ('ডান তর্জনী | U কী চাপুন (Bijoy)', 'জ → U');
      case 'হ': return ('ডান মধ্যমা | I কী চাপুন (Bijoy)', 'হ → I');
      case 'গ': return ('ডান অনামিকা | O কী চাপুন (Bijoy)', 'গ → O');
      case 'ড়': return ('ডান কনিষ্ঠা | P কী চাপুন (Bijoy)', 'ড় → P');
      
      // Home Row (A-L) - Normal
      case 'ৃ': return ('বাম কনিষ্ঠা | A কী চাপুন (Bijoy)', 'ৃ-কার → A');
      case 'ু': return ('বাম অনামিকা | S কী চাপুন (Bijoy)', 'ু-কার → S');
      case 'ি': return ('বাম মধ্যমা | D কী চাপুন (Bijoy)', 'ি-কার → D');
      case 'া': return ('বাম তর্জনী | F কী চাপুন (Bijoy)', 'া-কার → F');
      case '্': return ('বাম তর্জনী | G কী চাপুন (Bijoy)', 'হসন্ত → G');
      case 'ব': return ('ডান তর্জনী | H কী চাপুন (Bijoy)', 'ব → H');
      case 'ক': return ('ডান তর্জনী | J কী চাপুন (Bijoy)', 'ক → J');
      case 'ত': return ('ডান মধ্যমা | K কী চাপুন (Bijoy)', 'ত → K');
      case 'দ': return ('ডান অনামিকা | L কী চাপুন (Bijoy)', 'দ → L');
      
      // Bottom Row (Z-M) - Normal
      case '্র': return ('বাম কনিষ্ঠা | Z কী চাপুন (Bijoy)', 'র-ফলা → Z');
      case 'ও': return ('বাম অনামিকা | X কী চাপুন (Bijoy)', 'ও → X');
      case 'ে': return ('বাম মধ্যমা | C কী চাপুন (Bijoy)', 'ে-কার → C');
      case 'র': return ('বাম তর্জনী | V কী চাপুন (Bijoy)', 'র → V');
      case 'ন': return ('বাম তর্জনী | B কী চাপুন (Bijoy)', 'ন → B');
      case 'স': return ('ডান তর্জনী | N কী চাপুন (Bijoy)', 'স → N');
      case 'ম': return ('ডান তর্জনী | M কী চাপুন (Bijoy)', 'ম → M');
      case '।': return ('ডান অনামিকা | . কী চাপুন (Bijoy)', 'দাড়ি → .');
      
      // === SHIFT KEYS (With Shift) ===
      
      // Top Row (Shift+Q-P)
      case 'ং': return ('বাম কনিষ্ঠা | Shift+Q চাপুন (Bijoy)', 'ং → Shift+Q');
      case 'য়': return ('বাম অনামিকা | Shift+W চাপুন (Bijoy)', 'য় → Shift+W');
      case 'ঢ': return ('বাম মধ্যমা | Shift+E চাপুন (Bijoy)', 'ঢ → Shift+E');
      case 'ফ': return ('বাম তর্জনী | Shift+R চাপুন (Bijoy)', 'ফ → Shift+R');
      case 'ঠ': return ('বাম তর্জনী | Shift+T চাপুন (Bijoy)', 'ঠ → Shift+T');
      case 'ছ': return ('ডান তর্জনী | Shift+Y চাপুন (Bijoy)', 'ছ → Shift+Y');
      case 'ঝ': return ('ডান তর্জনী | Shift+U চাপুন (Bijoy)', 'ঝ → Shift+U');
      case 'ঞ': return ('ডান মধ্যমা | Shift+I চাপুন (Bijoy)', 'ঞ → Shift+I');
      case 'ঘ': return ('ডান অনামিকা | Shift+O চাপুন (Bijoy)', 'ঘ → Shift+O');
      case 'ঢ়': return ('ডান কনিষ্ঠা | Shift+P চাপুন (Bijoy)', 'ঢ় → Shift+P');
      
      // Home Row (Shift+A-L)
      case 'র্': return ('বাম কনিষ্ঠা | Shift+A চাপুন (Bijoy)', 'রেফ → Shift+A');
      case 'ূ': return ('বাম অনামিকা | Shift+S চাপুন (Bijoy)', 'ূ-কার → Shift+S');
      case 'ী': return ('বাম মধ্যমা | Shift+D চাপুন (Bijoy)', 'ী-কার → Shift+D');
      case 'অ': return ('বাম তর্জনী | Shift+F চাপুন (Bijoy)', 'অ → Shift+F');
      // Shift+G = দাড়ি (same as .)
      case 'ভ': return ('ডান তর্জনী | Shift+H চাপুন (Bijoy)', 'ভ → Shift+H');
      case 'খ': return ('ডান তর্জনী | Shift+J চাপুন (Bijoy)', 'খ → Shift+J');
      case 'থ': return ('ডান মধ্যমা | Shift+K চাপুন (Bijoy)', 'থ → Shift+K');
      case 'ধ': return ('ডান অনামিকা | Shift+L চাপুন (Bijoy)', 'ধ → Shift+L');
      
      // Bottom Row (Shift+Z-M)
      case '্য': return ('বাম কনিষ্ঠা | Shift+Z চাপুন (Bijoy)', 'য-ফলা → Shift+Z');
      case 'ঔ': return ('বাম অনামিকা | Shift+X চাপুন (Bijoy)', 'ঔ → Shift+X');
      case 'ৈ': return ('বাম মধ্যমা | Shift+C চাপুন (Bijoy)', 'ৈ-কার → Shift+C');
      case 'ল': return ('বাম তর্জনী | Shift+V চাপুন (Bijoy)', 'ল → Shift+V');
      case 'ণ': return ('বাম তর্জনী | Shift+B চাপুন (Bijoy)', 'ণ → Shift+B');
      case 'ষ': return ('ডান তর্জনী | Shift+N চাপুন (Bijoy)', 'ষ → Shift+N');
      case 'শ': return ('ডান তর্জনী | Shift+M চাপুন (Bijoy)', 'শ → Shift+M');
      case 'ৎ': return ('ডান কনিষ্ঠা | \\ (ব্যাকস্ল্যাশ) কী চাপুন (Bijoy)', 'খণ্ড-ত → \\');
      case 'ঃ': return ('ডান কনিষ্ঠা | Shift+\\ চাপুন (Bijoy)', 'বিসর্গ → Shift+\\');
      
      // Special - Chandrabindu (Shift+7)
      case 'ঁ': return ('ডান তর্জনী | Shift+7 চাপুন (Bijoy)', 'চন্দ্রবিন্দু → Shift+7');
      
      // Special - Taka sign (Shift+4)
      case '৳': return ('বাম তর্জনী | Shift+4 চাপুন (Bijoy)', 'টাকা চিহ্ন → Shift+4');
      
      // Numbers (Bengali)
      case '১': return ('বাম কনিষ্ঠা | 1 কী চাপুন (Bijoy)', '১ → 1');
      case '২': return ('বাম অনামিকা | 2 কী চাপুন (Bijoy)', '২ → 2');
      case '৩': return ('বাম মধ্যমা | 3 কী চাপুন (Bijoy)', '৩ → 3');
      case '৪': return ('বাম তর্জনী | 4 কী চাপুন (Bijoy)', '৪ → 4');
      case '৫': return ('বাম তর্জনী | 5 কী চাপুন (Bijoy)', '৫ → 5');
      case '৬': return ('ডান তর্জনী | 6 কী চাপুন (Bijoy)', '৬ → 6');
      case '৭': return ('ডান তর্জনী | 7 কী চাপুন (Bijoy)', '৭ → 7');
      case '৮': return ('ডান মধ্যমা | 8 কী চাপুন (Bijoy)', '৮ → 8');
      case '৯': return ('ডান অনামিকা | 9 কী চাপুন (Bijoy)', '৯ → 9');
      case '০': return ('ডান কনিষ্ঠা | 0 কী চাপুন (Bijoy)', '০ → 0');
      
      // Composed vowels (formed with হসন্ত + vowel key)
      case 'আ': return ('বাম তর্জনী | G+F চাপুন (Bijoy)', 'আ → G+F অথবা Shift+F চেপে H');
      case 'ই': return ('বাম মধ্যমা+তর্জনী | G+D চাপুন (Bijoy)', 'ই → G+D');
      case 'ঈ': return ('বাম মধ্যমা | G+Shift+D চাপুন (Bijoy)', 'ঈ → G+Shift+D');
      case 'উ': return ('বাম অনামিকা | G+S চাপুন (Bijoy)', 'উ → G+S');
      case 'ঊ': return ('বাম অনামিকা | G+Shift+S চাপুন (Bijoy)', 'ঊ → G+Shift+S');
      case 'ঋ': return ('বাম কনিষ্ঠা | G+A চাপুন (Bijoy)', 'ঋ → G+A');
      case 'এ': return ('বাম মধ্যমা | G+C চাপুন (Bijoy)', 'এ → G+C');
      case 'ঐ': return ('বাম মধ্যমা | G+Shift+C চাপুন (Bijoy)', 'ঐ → G+Shift+C');
      // ও = GX, ঔ = Shift+X
      
      // Space
      case ' ': return ('বৃদ্ধাঙ্গুলি | স্পেসবার চাপুন', 'স্পেস → Space Bar');
      
      default:
        return ('সঠিক আঙ্গুল ব্যবহার করুন (Bijoy)', 'বিজয় কীবোর্ড অনুসরণ করুন');
    }
  }

  // === PHONETIC KEYBOARD MAPPING ===
  (String, String) _getPhoneticGuidance(String character) {
    switch (character) {
      // === HOME ROW ===
      case 'া': return ('বাম কনিষ্ঠা | A কী চাপুন (Phonetic)', 'া-কার → A');
      case 'স': return ('বাম অনামিকা | S কী চাপুন (Phonetic)', 'স → S');
      case 'দ': return ('বাম মধ্যমা | D কী চাপুন (Phonetic)', 'দ → D');
      case 'ফ': return ('বাম তর্জনী | F কী চাপুন (Phonetic)', 'ফ → F');
      case 'গ': return ('বাম তর্জনী | G কী চাপুন (Phonetic)', 'গ → G');
      case 'হ': return ('ডান তর্জনী | H কী চাপুন (Phonetic)', 'হ → H');
      case 'জ': return ('ডান তর্জনী | J কী চাপুন (Phonetic)', 'জ → J');
      case 'ক': return ('ডান মধ্যমা | K কী চাপুন (Phonetic)', 'ক → K');
      case 'ল': return ('ডান অনামিকা | L কী চাপুন (Phonetic)', 'ল → L');
      
      // === TOP ROW ===
      case 'ৃ': return ('বাম কনিষ্ঠা | Q কী চাপুন (Phonetic)', 'ৃ-কার → Q');
      case 'ও': return ('বাম অনামিকা | W কী চাপুন (Phonetic)', 'ও → W');
      case 'ে': return ('বাম মধ্যমা | E কী চাপুন (Phonetic)', 'ে-কার → E');
      case 'র': return ('বাম তর্জনী | R কী চাপুন (Phonetic)', 'র → R');
      case 'ত': return ('বাম তর্জনী | T কী চাপুন (Phonetic)', 'ত → T');
      case 'য়': return ('ডান তর্জনী | Y কী চাপুন (Phonetic)', 'য় → Y');
      case 'ু': return ('ডান তর্জনী | U কী চাপুন (Phonetic)', 'ু-কার → U');
      case 'ি': return ('ডান মধ্যমা | I কী চাপুন (Phonetic)', 'ি-কার → I');
      case 'অ': return ('ডান অনামিকা | O কী চাপুন (Phonetic)', 'অ → O');
      case 'প': return ('ডান কনিষ্ঠা | P কী চাপুন (Phonetic)', 'প → P');

      // === BOTTOM ROW ===
      case 'য': return ('বাম কনিষ্ঠা | Z কী চাপুন (Phonetic)', 'য → Z');
      case 'চ': return ('বাম মধ্যমা | C কী চাপুন (Phonetic)', 'চ → C');
      case 'ভ': return ('বাম তর্জনী | V কী চাপুন (Phonetic)', 'ভ → V');
      case 'ব': return ('বাম তর্জনী | B কী চাপুন (Phonetic)', 'ব → B');
      case 'ন': return ('ডান তর্জনী | N কী চাপুন (Phonetic)', 'ন → N');
      case 'ম': return ('ডান তর্জনী | M কী চাপুন (Phonetic)', 'ম → M');
      
      // === SHIFT MAPPINGS ===
      case 'আ': return ('বাম কনিষ্ঠা | Shift + A চাপুন (Phonetic)', 'আ → Shift + A');
      case 'শ': return ('বাম অনামিকা | Shift + S চাপুন (Phonetic)', 'শ → Shift + S');
      case 'ড': return ('বাম মধ্যমা | Shift + D চাপুন (Phonetic)', 'ড → Shift + D');
      case 'ট': return ('বাম তর্জনী | Shift + T চাপুন (Phonetic)', 'ট → Shift + T');
      case 'ঘ': return ('বাম তর্জনী | Shift + G চাপুন (Phonetic)', 'ঘ → Shift + G');
      case 'খ': return ('ডান মধ্যমা | Shift + K চাপুন (Phonetic)', 'খ → Shift + K');
      case 'ঝ': return ('ডান তর্জনী | Shift + J চাপুন (Phonetic)', 'ঝ → Shift + J');
      case 'ছ': return ('বাম মধ্যমা | Shift + C চাপুন (Phonetic)', 'ছ → Shift + C');
      case 'ণ': return ('ডান তর্জনী | Shift + N চাপুন (Phonetic)', 'ণ → Shift + N');
      case 'ং': return ('ডান তর্জনী | Shift + M চাপুন (Phonetic)', 'ং → Shift + M');
      case 'ী': return ('ডান মধ্যমা | Shift + I চাপুন (Phonetic)', 'ী-কার → Shift + I');
      case 'ূ': return ('ডান তর্জনী | Shift + U চাপুন (Phonetic)', 'ূ-কার → Shift + U');
      case 'ৈ': return ('বাম মধ্যমা | Shift + E চাপুন (Phonetic)', 'ৈ-কার → Shift + E');
      case 'ঔ': return ('ডান অনামিকা | Shift + O চাপুন (Phonetic)', 'ঔ → Shift + O');
      case 'ঋ': return ('বাম কনিষ্ঠা | Shift + Q চাপুন (Phonetic)', 'ঋ → Shift + Q');
      case 'ড়': return ('বাম তর্জনী | Shift + R চাপুন (Phonetic)', 'ড় → Shift + R');
      case 'ঞ': return ('ডান তর্জনী | Shift + Y চাপুন (Phonetic)', 'ঞ → Shift + Y');
      case 'ঃ': return ('ডান তর্জনী | Shift + H চাপুন (Phonetic)', 'বিসর্গ → Shift + H');
      case 'ৎ': return ('বাম তর্জনী | Shift + F চাপুন (Phonetic)', 'খণ্ড-ত → Shift + F');
      case 'ঙ': return ('বাম তর্জনী | Shift + V চাপুন (Phonetic)', 'ঙ → Shift + V');
      case '্': return ('বাম কনিষ্ঠা | ` (Backtick) কী চাপুন (Phonetic)', 'হসন্ত → `');
      
      // Space
      case ' ': return ('বৃদ্ধাঙ্গুলি | স্পেসবার চাপুন', 'স্পেস → Space Bar');
      
      default:
        return ('সঠিক আঙ্গুল ব্যবহার করুন (Phonetic)', 'কীবোর্ড নয়, স্ক্রিনে তাকান');
    }
  }
}

class FingerInfo {
  final String finger;
  final String hand;

  FingerInfo(this.finger, this.hand);
}
