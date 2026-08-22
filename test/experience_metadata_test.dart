import 'package:classmates/screens/Experiences/experience_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('experienceLocationLabel', () {
    test('adds the location prefix', () {
      expect(
        experienceLocationLabel('Natural History Museum'),
        'Located at the Natural History Museum',
      );
    });

    test('replaces the old hosted-by prefix', () {
      expect(
        experienceLocationLabel('Hosted by Natural History Museum'),
        'Located at the Natural History Museum',
      );
    });

    test('does not duplicate an existing location prefix', () {
      expect(
        experienceLocationLabel('Located at the Natural History Museum'),
        'Located at the Natural History Museum',
      );
    });
  });
}
