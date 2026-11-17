import 'package:flutter_test/flutter_test.dart';
import 'package:quba/data.dart';

void main() {
  group('Basmala header rule', () {
    test('surah 1 has no separate header (Basmala IS ayah 1)', () {
      expect(hasBasmalaHeader(1), isFalse);
    });

    test('surah 9 has no Basmala at all', () {
      expect(hasBasmalaHeader(9), isFalse);
    });

    test('every other surah shows the Basmala header', () {
      for (var s = 2; s <= 114; s++) {
        if (s == 9) continue;
        expect(hasBasmalaHeader(s), isTrue, reason: 'surah $s');
      }
    });

    test('reader list offset: header surahs hold ayahCount + 1 items', () {
      // The reader's itemCount is ayahCount + (hasBasmalaHeader ? 1 : 0)
      // and verse i sits at list index i - 1 + offset, so numbering
      // stays 1-based: ayah 1 is at index 1 with a header, 0 without.
      int offset(int surah) => hasBasmalaHeader(surah) ? 1 : 0;
      expect(offset(1), 0);
      expect(offset(9), 0);
      expect(offset(2), 1);
      expect(offset(114), 1);
      // Ayah 1's list index for Al-Baqara (header shown) is 1, not 0.
      expect(1 - 1 + offset(2), 1);
      // Ayah 1's list index for Al-Fatihah (no header) is 0.
      expect(1 - 1 + offset(1), 0);
    });
  });
}
