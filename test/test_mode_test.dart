import 'package:flutter_test/flutter_test.dart';

import 'package:quba/testmode/test_mode.dart';

/// Pure-Dart tests for the memorisation test-mode session logic:
/// masking determinism, scoring rules and range navigation.
void main() {
  const arabic10 =
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
  // 10 words above; keep the count explicit so the test fails loudly
  // if the fixture is ever edited.
  test('fixture has 10 words', () {
    expect(TestSession.splitWords(arabic10).length, 10);
  });

  group('masking', () {
    test('deterministic per ayah across sessions', () {
      final a = TestSession(surah: 2, startAyah: 1, endAyah: 5);
      final b = TestSession(surah: 2, startAyah: 1, endAyah: 5);
      expect(a.maskedIndices(3, arabic10), b.maskedIndices(3, arabic10));
      expect(a.maskedIndices(3, arabic10), a.maskedIndices(3, arabic10));
    });

    test('different ayahs mask different words', () {
      final s = TestSession(surah: 2, startAyah: 1, endAyah: 5);
      expect(s.maskedIndices(1, arabic10), isNot(s.maskedIndices(2, arabic10)));
    });

    test('masks ~40% by default and always leaves a word visible', () {
      final s = TestSession(surah: 2, startAyah: 1, endAyah: 5);
      final masked = s.maskedIndices(1, arabic10);
      expect(masked.length, 4); // ceil(10 * 0.4)
      expect(masked.length, lessThan(10));
      expect(masked.toSet().length, masked.length); // no duplicates
      for (final i in masked) {
        expect(i, inInclusiveRange(0, 9));
      }
    });

    test('single-word ayah masks nothing', () {
      final s = TestSession(surah: 55, startAyah: 64, endAyah: 64);
      expect(s.maskedIndices(64, 'مُدْهَامَّتَانِ'), isEmpty);
    });

    test('two-word ayah masks exactly one word', () {
      final s = TestSession(surah: 1, startAyah: 1, endAyah: 1);
      expect(s.maskedIndices(1, 'word1 word2').length, 1);
    });

    test('maskFraction is honoured', () {
      final s = TestSession(
        surah: 2,
        startAyah: 1,
        endAyah: 5,
        maskFraction: 0.8,
      );
      // 80% of 10 = 8, but one word must stay visible: 8 < 10, ok.
      expect(s.maskedIndices(1, arabic10).length, 8);
    });
  });

  group('hideWords scoring', () {
    test('knew / revealed counts and score', () {
      final s = TestSession(surah: 2, startAyah: 1, endAyah: 5);
      expect(s.score, 0); // nothing answered yet
      s.markKnew(1, 0);
      s.markKnew(1, 1);
      s.revealWord(1, 2);
      expect(s.knewCount, 2);
      expect(s.revealedCount, 1);
      expect(s.answeredCount, 3);
      expect(s.score, closeTo(2 / 3, 0.001));
      expect(s.correctCount, 2);
      expect(s.wrongCount, 1);
    });

    test('first mark wins: a revealed word can never become knew', () {
      final s = TestSession(surah: 2, startAyah: 1, endAyah: 5);
      s.revealWord(1, 0);
      s.markKnew(1, 0);
      expect(s.markOf(1, 0), WordMark.revealed);
      expect(s.knewCount, 0);
      expect(s.revealedCount, 1);
      s.markKnew(1, 1);
      s.revealWord(1, 1);
      expect(s.markOf(1, 1), WordMark.knew);
    });

    test('marks are tracked per ayah', () {
      final s = TestSession(surah: 2, startAyah: 1, endAyah: 5);
      s.markKnew(1, 0);
      s.markKnew(2, 0);
      expect(s.markOf(1, 0), WordMark.knew);
      expect(s.markOf(2, 0), WordMark.knew);
      expect(s.markOf(3, 0), isNull);
    });
  });

  group('nextAyah scoring', () {
    test('correct / wrong counts and score', () {
      final s = TestSession(
        surah: 2,
        startAyah: 1,
        endAyah: 5,
        mode: TestMode.nextAyah,
      );
      expect(s.answerShown, isFalse);
      s.showAnswer();
      expect(s.answerShown, isTrue);
      s.markNextAyah(true);
      s.next();
      s.markNextAyah(false);
      expect(s.nextCorrectCount, 1);
      expect(s.nextWrongCount, 1);
      expect(s.nextAyahAnswered, 2);
      expect(s.score, 0.5);
      expect(s.correctCount, 1);
      expect(s.wrongCount, 1);
    });

    test('first mark wins per ayah', () {
      final s = TestSession(
        surah: 2,
        startAyah: 1,
        endAyah: 5,
        mode: TestMode.nextAyah,
      );
      s.markNextAyah(false);
      s.markNextAyah(true);
      expect(s.nextAyahMark(1), isFalse);
      expect(s.nextCorrectCount, 0);
    });

    test('answerShown resets when moving', () {
      final s = TestSession(
        surah: 2,
        startAyah: 1,
        endAyah: 5,
        mode: TestMode.nextAyah,
      );
      s.showAnswer();
      s.next();
      expect(s.answerShown, isFalse);
    });
  });

  group('navigation', () {
    test('next/previous walk the range and stop at the ends', () {
      final s = TestSession(surah: 2, startAyah: 3, endAyah: 5);
      expect(s.totalAyahs, 3);
      expect(s.currentAyah, 3);
      expect(s.position, 1);
      expect(s.isFirst, isTrue);
      expect(s.isLast, isFalse);
      expect(s.previous(), isFalse);
      expect(s.next(), isTrue);
      expect(s.currentAyah, 4);
      expect(s.position, 2);
      expect(s.progress, closeTo(2 / 3, 0.001));
      expect(s.next(), isTrue);
      expect(s.currentAyah, 5);
      expect(s.isLast, isTrue);
      expect(s.next(), isFalse);
      expect(s.currentAyah, 5);
      expect(s.previous(), isTrue);
      expect(s.currentAyah, 4);
    });

    test('single-ayah range', () {
      final s = TestSession(surah: 1, startAyah: 1, endAyah: 1);
      expect(s.totalAyahs, 1);
      expect(s.isFirst, isTrue);
      expect(s.isLast, isTrue);
      expect(s.progress, 1);
      expect(s.next(), isFalse);
      expect(s.previous(), isFalse);
    });

    test('reset restarts the session and clears marks', () {
      final s = TestSession(surah: 2, startAyah: 1, endAyah: 5);
      s.markKnew(1, 0);
      s.next();
      s.next();
      s.reset();
      expect(s.currentAyah, 1);
      expect(s.knewCount, 0);
      expect(s.answeredCount, 0);
      expect(s.markOf(1, 0), isNull);
    });
  });
}
