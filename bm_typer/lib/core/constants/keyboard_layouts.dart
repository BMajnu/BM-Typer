/// বাংলা Keyboard Layout Data
/// Bijoy Bayanno layout - বাংলাদেশে সর্বাধিক ব্যবহৃত keyboard layout
/// Avro Phonetic layout - ফনেটিক/অভ্র স্টাইল
/// Reference: Official Bijoy Bayanno 52 and Avro Keyboard documentation
/// Cross-platform compatible - Windows, Mac, Linux, Mobile

export 'layouts/bijoy_layout.dart';
export 'layouts/phonetic_layout.dart';
export 'layouts/qwerty_layout.dart';

/// Keyboard layout types
enum KeyboardLayout {
  qwerty, // English QWERTY
  bijoy, // Bijoy Bengali layout (Official Bijoy Bayanno)
  phonetic, // Phonetic Bengali layout (Avro style)
}
