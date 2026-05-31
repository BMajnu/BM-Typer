import 'package:bm_typer/data/local_lesson_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('English home row lesson', () {
    test('includes G and H in the opening drills', () {
      final lesson = englishKeyboardLessons.first;

      expect(lesson.title, contains('ASDFG-HJKL;'));
      expect(lesson.exercises[0].text, 'asdfg hjkl;');
      expect(lesson.exercises[1].text, contains('ggg'));
      expect(lesson.exercises[2].text, contains('hhh'));
    });
  });
}
