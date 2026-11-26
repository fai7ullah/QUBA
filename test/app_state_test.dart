import 'package:flutter_test/flutter_test.dart';
import 'package:quba/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit tests for the round-3 AppState logic: prayer log, reading
/// streak and verse notes. No UI — fresh [AppState] instances against
/// the mocked SharedPreferences backend.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  int epochDay(DateTime d) => d.difference(DateTime.utc(1970)).inDays;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('prayer log', () {
    test('isPrayed is false by default', () {
      final s = AppState();
      expect(s.isPrayed(DateTime.now(), 'Fajr'), isFalse);
      expect(s.isPrayed(DateTime.now(), 'Isha'), isFalse);
    });

    test('togglePrayed marks and unmarks', () {
      final s = AppState();
      final today = DateTime.now();
      s.togglePrayed(today, 'Fajr');
      expect(s.isPrayed(today, 'Fajr'), isTrue);
      s.togglePrayed(today, 'Fajr');
      expect(s.isPrayed(today, 'Fajr'), isFalse);
    });

    test('togglePrayed on one day does not affect another', () {
      final s = AppState();
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      s.togglePrayed(today, 'Dhuhr');
      expect(s.isPrayed(yesterday, 'Dhuhr'), isFalse);
    });

    test('prayedCountOn counts correctly', () {
      final s = AppState();
      final today = DateTime.now();
      expect(s.prayedCountOn(today), 0);
      s.togglePrayed(today, 'Fajr');
      s.togglePrayed(today, 'Dhuhr');
      s.togglePrayed(today, 'Isha');
      expect(s.prayedCountOn(today), 3);
      s.togglePrayed(today, 'Dhuhr');
      expect(s.prayedCountOn(today), 2);
      expect(s.prayedCountOn(today.subtract(const Duration(days: 1))), 0);
    });

    test('prayedLast7Days returns 7 values with today last', () {
      final s = AppState();
      final today = DateTime.now();
      s.togglePrayed(today, 'Fajr');
      s.togglePrayed(today.subtract(const Duration(days: 6)), 'Isha');
      s.togglePrayed(today.subtract(const Duration(days: 6)), 'Fajr');
      final last7 = s.prayedLast7Days();
      expect(last7, hasLength(7));
      expect(last7[6], 1); // today
      expect(last7[0], 2); // 6 days ago
      expect(last7[1], 0);
      expect(last7[5], 0);
    });
  });

  group('reading streak', () {
    test('empty reading days -> streak 0', () {
      expect(AppState().readingStreak, 0);
    });

    test('today, yesterday, day before -> streak 3', () {
      final s = AppState();
      final today = epochDay(DateTime.now());
      s.readingDays = {today, today - 1, today - 2};
      expect(s.readingStreak, 3);
    });

    test('yesterday and day before only (no today) -> streak 2', () {
      final s = AppState();
      final today = epochDay(DateTime.now());
      s.readingDays = {today - 1, today - 2};
      expect(s.readingStreak, 2);
    });

    test('a gap breaks the streak', () {
      final s = AppState();
      final today = epochDay(DateTime.now());
      s.readingDays = {today, today - 2, today - 3};
      expect(s.readingStreak, 1);
    });

    test('only old days -> streak 0', () {
      final s = AppState();
      final today = epochDay(DateTime.now());
      s.readingDays = {today - 5, today - 6};
      expect(s.readingStreak, 0);
    });

    test('readToday false until a reading day is recorded', () {
      final s = AppState();
      expect(s.readToday, isFalse);
      s.recordReadingDay();
      expect(s.readToday, isTrue);
      expect(s.readingStreak, 1);
    });

    test('setLastRead records a reading day', () {
      final s = AppState();
      expect(s.readToday, isFalse);
      s.setLastRead(2, 1);
      expect(s.readToday, isTrue);
    });
  });

  group('notes', () {
    test('setNote / noteFor round-trip', () {
      final s = AppState();
      s.setNote(2, 255, 'Ayat al-Kursi');
      expect(s.noteFor(2, 255), 'Ayat al-Kursi');
    });

    test('noteFor returns empty string when there is no note', () {
      expect(AppState().noteFor(1, 1), '');
    });

    test('empty text deletes the note', () {
      final s = AppState();
      s.setNote(2, 255, 'something');
      s.setNote(2, 255, '   ');
      expect(s.noteFor(2, 255), '');
      expect(s.notesSorted, isEmpty);
    });

    test('deleteNote removes the note', () {
      final s = AppState();
      s.setNote(1, 1, 'first verse');
      s.deleteNote(1, 1);
      expect(s.noteFor(1, 1), '');
      expect(s.notesSorted, isEmpty);
    });

    test('notesSorted orders by surah then ayah', () {
      final s = AppState();
      s.setNote(2, 10, 'b');
      s.setNote(1, 5, 'a');
      s.setNote(2, 3, 'c');
      s.setNote(1, 2, 'd');
      final sorted = s.notesSorted;
      expect(sorted.map((n) => (n.$1, n.$2)).toList(), [
        (1, 2),
        (1, 5),
        (2, 3),
        (2, 10),
      ]);
      expect(sorted.map((n) => n.$3).toList(), ['d', 'a', 'c', 'b']);
    });
  });

  group('onboarding', () {
    test('completeOnboarding flips the flag', () {
      final s = AppState();
      expect(s.onboardingDone, isFalse);
      s.completeOnboarding();
      expect(s.onboardingDone, isTrue);
    });
  });
}
