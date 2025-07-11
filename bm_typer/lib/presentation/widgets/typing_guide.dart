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

  // Helper method to get guidance based on character
  (String, String) _getGuidanceForCharacter(String character) {
    // Default guidance
    String fingerGuidance = 'সঠিক আঙ্গুল ব্যবহার করুন';
    String keyGuidance = 'কীবোর্ড নয়, স্ক্রিনে তাকান';

    // Character-specific guidance
    switch (character.toLowerCase()) {
      // Home row keys
      case 'a':
        fingerGuidance = 'বাম হাতের কনিষ্ঠা আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'A কী-টি হোম রো-এর বাম দিকে অবস্থিত';
        break;
      case 's':
        fingerGuidance = 'বাম হাতের অনামিকা আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'S কী-টি হোম রো-এর বাম দিকে A এর পাশে অবস্থিত';
        break;
      case 'd':
        fingerGuidance = 'বাম হাতের মধ্যমা আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'D কী-টি হোম রো-এর বাম দিকে S এর পাশে অবস্থিত';
        break;
      case 'f':
        fingerGuidance = 'বাম হাতের তর্জনী আঙ্গুল ব্যবহার করুন';
        keyGuidance =
            'F কী-টি হোম রো-এর বাম দিকে, বাম হাতের তর্জনী আঙ্গুলের নীচে';
        break;
      case 'g':
        fingerGuidance = 'বাম হাতের তর্জনী আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'G কী-টি হোম রো-এর F এর পাশে অবস্থিত';
        break;
      case 'h':
        fingerGuidance = 'ডান হাতের তর্জনী আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'H কী-টি হোম রো-এর ডান দিকে G এর পাশে অবস্থিত';
        break;
      case 'j':
        fingerGuidance = 'ডান হাতের তর্জনী আঙ্গুল ব্যবহার করুন';
        keyGuidance =
            'J কী-টি হোম রো-এর ডান দিকে, ডান হাতের তর্জনী আঙ্গুলের নীচে';
        break;
      case 'k':
        fingerGuidance = 'ডান হাতের মধ্যমা আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'K কী-টি হোম রো-এর ডান দিকে J এর পাশে অবস্থিত';
        break;
      case 'l':
        fingerGuidance = 'ডান হাতের অনামিকা আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'L কী-টি হোম রো-এর ডান দিকে K এর পাশে অবস্থিত';
        break;
      case ';':
        fingerGuidance = 'ডান হাতের কনিষ্ঠা আঙ্গুল ব্যবহার করুন';
        keyGuidance = '; কী-টি হোম রো-এর ডান দিকে L এর পাশে অবস্থিত';
        break;

      // Top row keys
      case 'q':
        fingerGuidance = 'বাম হাতের কনিষ্ঠা আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'Q কী-টি উপরের সারিতে A এর উপরে অবস্থিত';
        break;
      case 'w':
        fingerGuidance = 'বাম হাতের অনামিকা আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'W কী-টি উপরের সারিতে S এর উপরে অবস্থিত';
        break;
      case 'e':
        fingerGuidance = 'বাম হাতের মধ্যমা আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'E কী-টি উপরের সারিতে D এর উপরে অবস্থিত';
        break;
      case 'r':
        fingerGuidance = 'বাম হাতের তর্জনী আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'R কী-টি উপরের সারিতে F এর উপরে অবস্থিত';
        break;

      // Bottom row keys
      case 'z':
        fingerGuidance = 'বাম হাতের কনিষ্ঠা আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'Z কী-টি নীচের সারিতে A এর নীচে অবস্থিত';
        break;
      case 'x':
        fingerGuidance = 'বাম হাতের অনামিকা আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'X কী-টি নীচের সারিতে S এর নীচে অবস্থিত';
        break;
      case 'c':
        fingerGuidance = 'বাম হাতের মধ্যমা আঙ্গুল ব্যবহার করুন';
        keyGuidance = 'C কী-টি নীচের সারিতে D এর নীচে অবস্থিত';
        break;

      // Space key
      case ' ':
        fingerGuidance = 'ডান হাতের বৃদ্ধাঙ্গুলি ব্যবহার করুন';
        keyGuidance = 'স্পেসবার কীবোর্ডের নীচের দিকে মাঝখানে অবস্থিত';
        break;

      default:
        if (character.isEmpty) {
          fingerGuidance = 'পরবর্তী অক্ষরের জন্য প্রস্তুত হোন';
          keyGuidance = 'হোম রো-তে আঙ্গুল রাখুন (ASDF JKL;)';
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
