import 'package:flutter_test/flutter_test.dart';
import 'package:bm_typer/core/constants/keyboard_layouts.dart';

void main() {
  group('Bijoy Keyboard Layout Tests', () {
    test('Official Mappings Correctness', () {
      // Basic Consonants
      expect(BijoyKeyboardLayout.getCharacter('j'), 'ক');
      expect(BijoyKeyboardLayout.getCharacter('k'), 'ত');
      expect(BijoyKeyboardLayout.getCharacter('l'), 'দ');
      expect(BijoyKeyboardLayout.getCharacter('h'), 'ব');
      expect(BijoyKeyboardLayout.getCharacter('r'), 'প');
      expect(BijoyKeyboardLayout.getCharacter('p'), 'ড়'); // Corrected from র
      expect(BijoyKeyboardLayout.getCharacter('v'), 'র'); // Corrected from ল
      expect(BijoyKeyboardLayout.getCharacter('x'), 'ও'); // Corrected

      // Shifted Characters
      expect(BijoyKeyboardLayout.getCharacter('J', shift: true), 'খ');
      expect(BijoyKeyboardLayout.getCharacter('K', shift: true), 'থ');
      expect(BijoyKeyboardLayout.getCharacter('L', shift: true), 'ধ');
      expect(BijoyKeyboardLayout.getCharacter('H', shift: true), 'ভ');
      expect(BijoyKeyboardLayout.getCharacter('R', shift: true), 'ফ');
      expect(BijoyKeyboardLayout.getCharacter('P', shift: true), 'ঢ়');
      expect(BijoyKeyboardLayout.getCharacter('V', shift: true), 'ল'); // Corrected
      expect(BijoyKeyboardLayout.getCharacter('X', shift: true), 'ঔ');
      expect(BijoyKeyboardLayout.getCharacter('A', shift: true), 'র্'); // Corrected Shift+A = Reph
      
      // Vowels & Signs
      expect(BijoyKeyboardLayout.getCharacter('f'), 'া');
      expect(BijoyKeyboardLayout.getCharacter('d'), 'ি');
      expect(BijoyKeyboardLayout.getCharacter('s'), 'ু');
      expect(BijoyKeyboardLayout.getCharacter('a'), 'ৃ');
      expect(BijoyKeyboardLayout.getCharacter('c'), 'ে');
      
      // Punctuation
      expect(BijoyKeyboardLayout.getCharacter('.'), '।');
    });
  });

  group('Phonetic Keyboard Layout Tests', () {
    test('Basic Phonetic Mappings', () {
      // Vowels
      expect(PhoneticKeyboardLayout.getCharacter('o'), 'অ');
      expect(PhoneticKeyboardLayout.getCharacter('a'), 'া');
      expect(PhoneticKeyboardLayout.getCharacter('i'), 'ি');
      expect(PhoneticKeyboardLayout.getCharacter('u'), 'ু');
      expect(PhoneticKeyboardLayout.getCharacter('e'), 'ে');
      
      // Consonants
      expect(PhoneticKeyboardLayout.getCharacter('k'), 'ক');
      expect(PhoneticKeyboardLayout.getCharacter('g'), 'গ');
      expect(PhoneticKeyboardLayout.getCharacter('c'), 'চ');
      expect(PhoneticKeyboardLayout.getCharacter('j'), 'জ');
      expect(PhoneticKeyboardLayout.getCharacter('t'), 'ত');
      expect(PhoneticKeyboardLayout.getCharacter('d'), 'দ');
      expect(PhoneticKeyboardLayout.getCharacter('n'), 'ন');
      expect(PhoneticKeyboardLayout.getCharacter('p'), 'প');
      expect(PhoneticKeyboardLayout.getCharacter('f'), 'ফ');
      expect(PhoneticKeyboardLayout.getCharacter('b'), 'ব');
      expect(PhoneticKeyboardLayout.getCharacter('m'), 'ম');
      expect(PhoneticKeyboardLayout.getCharacter('r'), 'র');
      expect(PhoneticKeyboardLayout.getCharacter('l'), 'ল');
    });

    test('Shifted/Alternate Phonetic Mappings', () {
      // Vowels
      expect(PhoneticKeyboardLayout.getCharacter('A', shift: true), 'আ');
      expect(PhoneticKeyboardLayout.getCharacter('I', shift: true), 'ী');
      expect(PhoneticKeyboardLayout.getCharacter('U', shift: true), 'ূ');
      
      // Consonants (Aspirated)
      expect(PhoneticKeyboardLayout.getCharacter('K', shift: true), 'খ'); // k -> K (Kh)
      expect(PhoneticKeyboardLayout.getCharacter('G', shift: true), 'ঘ');
      expect(PhoneticKeyboardLayout.getCharacter('C', shift: true), 'ছ');
      expect(PhoneticKeyboardLayout.getCharacter('J', shift: true), 'ঝ');
      expect(PhoneticKeyboardLayout.getCharacter('T', shift: true), 'ঠ');
      expect(PhoneticKeyboardLayout.getCharacter('D', shift: true), 'ঢ');
      expect(PhoneticKeyboardLayout.getCharacter('t', shift: true), 'থ'); // wait, t shift is Th?
      // In my map: 't' normal is ત. 't' in shift map?
      // phonetic layout code:
      // normalKeys: ... 't': 'ত', ...
      // shiftKeys: ... 't': 'থ', ... 
      // So if shift is true, it should return 'থ'.
      expect(PhoneticKeyboardLayout.getCharacter('t', shift: true), 'থ');
      
      expect(PhoneticKeyboardLayout.getCharacter('d', shift: true), 'ধ');
      expect(PhoneticKeyboardLayout.getCharacter('B', shift: true), 'ভ');
    });
  });
}
