import 'package:bm_typer/data/lesson_layer_intro_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Lesson layer intro mapping', () {
    test('returns intros only for the first lesson of grouped keyboard layers',
        () {
      expect(lessonLayerIntroForIndex(0)?.id, 'qwerty-home-row');
      expect(lessonLayerIntroForIndex(1)?.id, 'qwerty-upper-row');

      expect(lessonLayerIntroForIndex(8)?.id, 'bijoy-home-row');
      expect(lessonLayerIntroForIndex(9), isNull);

      expect(lessonLayerIntroForIndex(36)?.id, 'phonetic-home-row');
      expect(lessonLayerIntroForIndex(37), isNull);
    });

    test('stores grouped home-row keys so G stays with the left hand', () {
      final qwertyHomeRow = lessonLayerIntroForIndex(0);
      final phoneticHomeRow = lessonLayerIntroForIndex(36);

      expect(
        qwertyHomeRow?.keyGroups,
        const [
          ['A', 'S', 'D', 'F', 'G'],
          ['H', 'J', 'K', 'L', ';'],
        ],
      );
      expect(
        phoneticHomeRow?.keyGroups,
        const [
          ['a', 's', 'd', 'f', 'g'],
          ['h', 'j', 'k', 'l'],
        ],
      );
    });
  });
}
