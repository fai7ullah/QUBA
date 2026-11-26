import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quba/app_state.dart';
import 'package:quba/sync/backup_service.dart';
import 'package:quba/sync/backup_payload.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backup/restore tests: JSON round-trip (all fields survive), plus
/// malformed JSON, wrong format/version, missing keys and wrong types.
/// Fresh [AppState] instances against the mocked SharedPreferences
/// backend (same pattern as app_state_test.dart).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppState fullState() {
    final s = AppState();
    s.bookmarks = {'1:1', '2:255'};
    s.notes = {'2:255': 'Ayat al-Kursi', '36:58': 'Peace'};
    s.prayerLog = {
      '2026-11-21': {'Fajr', 'Dhuhr'},
      '2026-11-20': {'Isha'},
    };
    s.readingDays = {20750, 20751};
    s.khatmaDays = 30;
    s.khatmaStartGlobal = 100;
    s.khatmaStartDay = 20750;
    s.tasbihTotals = {'subhanallah': 100, 'alhamdulillah': 33};
    s.lastReadSurah = 2;
    s.lastReadAyah = 255;
    return s;
  }

  void expectMatchesFull(AppState s) {
    expect(s.bookmarks, {'1:1', '2:255'});
    expect(s.notes, {'2:255': 'Ayat al-Kursi', '36:58': 'Peace'});
    expect(s.prayerLog, {
      '2026-11-21': {'Fajr', 'Dhuhr'},
      '2026-11-20': {'Isha'},
    });
    expect(s.readingDays, {20750, 20751});
    expect(s.khatmaDays, 30);
    expect(s.khatmaStartGlobal, 100);
    expect(s.khatmaStartDay, 20750);
    expect(s.tasbihTotals, {'subhanallah': 100, 'alhamdulillah': 33});
    expect(s.lastReadSurah, 2);
    expect(s.lastReadAyah, 255);
  }

  group('round-trip', () {
    test('buildBackupJson -> restoreFromJson restores every field', () {
      final json = BackupService.buildBackupJson(fullState());
      final restored = AppState();
      final result = BackupService.restoreFromJson(json, restored);
      expect(result.ok, isTrue);
      expectMatchesFull(restored);
    });

    test('backup JSON has the format header', () {
      final decoded = jsonDecode(
        BackupService.buildBackupJson(fullState()),
      ) as Map<String, dynamic>;
      expect(decoded['format'], 'quba-backup');
      expect(decoded['version'], 1);
      expect(decoded['exported_at'], isA<String>());
      expect(decoded['data'], isA<Map<String, dynamic>>());
    });

    test('backup payload matches the sync payload shape', () {
      final state = fullState();
      final backup = jsonDecode(
        BackupService.buildBackupJson(state),
      ) as Map<String, dynamic>;
      expect(backup['data'], BackupPayload.toJson(state));
    });

    test('empty state round-trips', () {
      final json = BackupService.buildBackupJson(AppState());
      final restored = AppState();
      // A payload with only empty collections still applies (the
      // fields are present, just empty).
      final result = BackupService.restoreFromJson(json, restored);
      expect(result.ok, isTrue);
      expect(restored.bookmarks, isEmpty);
      expect(restored.khatmaDays, 0);
    });
  });

  group('invalid input never throws, returns ok:false', () {
    test('malformed JSON', () {
      final target = fullState();
      final result = BackupService.restoreFromJson('{not json', target);
      expect(result.ok, isFalse);
      expectMatchesFull(target); // untouched
    });

    test('empty string', () {
      expect(BackupService.restoreFromJson('', AppState()).ok, isFalse);
    });

    test('JSON array instead of object', () {
      expect(
        BackupService.restoreFromJson('[1, 2, 3]', AppState()).ok,
        isFalse,
      );
    });

    test('wrong format name', () {
      final json = jsonEncode({
        'format': 'other-app',
        'version': 1,
        'data': {
          'bookmarks': ['1:1'],
        },
      });
      expect(BackupService.restoreFromJson(json, AppState()).ok, isFalse);
    });

    test('wrong version', () {
      final json = jsonEncode({
        'format': 'quba-backup',
        'version': 99,
        'data': {
          'bookmarks': ['1:1'],
        },
      });
      expect(BackupService.restoreFromJson(json, AppState()).ok, isFalse);
    });

    test('missing data object', () {
      final json = jsonEncode({'format': 'quba-backup', 'version': 1});
      expect(BackupService.restoreFromJson(json, AppState()).ok, isFalse);
    });

    test('data with no usable field', () {
      final json = jsonEncode({
        'format': 'quba-backup',
        'version': 1,
        'data': {'unknown_field': 123},
      });
      expect(BackupService.restoreFromJson(json, AppState()).ok, isFalse);
    });
  });

  group('partial + mistyped payloads', () {
    test('missing keys: present fields apply, absent ones stay', () {
      final target = fullState();
      final json = jsonEncode({
        'format': 'quba-backup',
        'version': 1,
        'data': {
          'bookmarks': ['36:1'],
        },
      });
      final result = BackupService.restoreFromJson(json, target);
      expect(result.ok, isTrue);
      expect(target.bookmarks, {'36:1'});
      // Everything else untouched.
      expect(target.notes, {'2:255': 'Ayat al-Kursi', '36:58': 'Peace'});
      expect(target.khatmaDays, 30);
      expect(target.lastReadSurah, 2);
    });

    test('wrong-typed fields are skipped, valid ones still apply', () {
      final target = AppState();
      final json = jsonEncode({
        'format': 'quba-backup',
        'version': 1,
        'data': {
          'bookmarks': 'not-a-list',
          'notes': {'1:1': 'kept'},
          'tasbih_totals': {'subhanallah': 'not-a-number'},
          'reading_days': [20750, 'junk', 20751],
        },
      });
      final result = BackupService.restoreFromJson(json, target);
      expect(result.ok, isTrue);
      expect(target.bookmarks, isEmpty); // skipped, not crashed
      expect(target.notes, {'1:1': 'kept'});
      expect(target.tasbihTotals, isEmpty);
      expect(target.readingDays, {20750, 20751}); // bad entry dropped
    });

    test('out-of-range last_read is ignored', () {
      final target = AppState();
      final json = jsonEncode({
        'format': 'quba-backup',
        'version': 1,
        'data': {
          'bookmarks': ['1:1'],
          'last_read': {'surah': 999, 'ayah': 0},
        },
      });
      final result = BackupService.restoreFromJson(json, target);
      expect(result.ok, isTrue);
      expect(target.bookmarks, {'1:1'});
      expect(target.lastReadSurah, 1); // defaults kept
      expect(target.lastReadAyah, 1);
    });

    test('prayer_log with bad entries keeps the good ones', () {
      final target = AppState();
      final json = jsonEncode({
        'format': 'quba-backup',
        'version': 1,
        'data': {
          'prayer_log': {
            '2026-11-21': ['Fajr', 42, 'Dhuhr'],
            'not-a-date': 'nope',
          },
        },
      });
      final result = BackupService.restoreFromJson(json, target);
      expect(result.ok, isTrue);
      expect(target.prayerLog, {
        '2026-11-21': {'Fajr', 'Dhuhr'},
      });
    });
  });
}
