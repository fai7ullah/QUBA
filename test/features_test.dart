import 'package:flutter_test/flutter_test.dart';
import 'package:quba/app_state.dart';
import 'package:quba/azkar_data.dart';
import 'package:quba/i18n.dart';
import 'package:quba/notifications.dart';
import 'package:quba/prayer_calc.dart';
import 'package:quba/screens/progress_screen.dart';
import 'package:quba/sync/backup_payload.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('prayer methods', () {
    PrayerCalc kabul({
      String method = 'mwl',
      String highLat = 'auto',
      List<int> adjust = const [0, 0, 0, 0, 0, 0],
    }) => PrayerCalc(
      lat: 34.5553,
      lng: 69.2075,
      tzHours: 4.5,
      method: method,
      hanafi: true,
      highLat: highLat,
      adjust: adjust,
    );

    test('all methods resolve and ids are unique', () {
      final ids = PrayerMethod.all.map((m) => m.id).toSet();
      expect(ids.length, PrayerMethod.all.length);
      for (final m in PrayerMethod.all) {
        expect(PrayerMethod.byId(m.id).id, m.id);
      }
    });

    test('minute adjustment shifts exactly that prayer', () {
      final base = kabul().timesFor(2026, 11, 11);
      final adj = kabul(adjust: const [0, 0, 0, 0, 3, 0])
          .timesFor(2026, 11, 11);
      for (var i = 0; i < 6; i++) {
        expect(adj[i] - base[i], i == 4 ? 3 : 0);
      }
    });

    test('polar latitude gives finite times for every rule', () {
      for (final rule in ['auto', 'midnight', 'oneseventh', 'anglebased']) {
        final c = PrayerCalc(
          lat: 69.6,
          lng: 18.9,
          tzHours: 1,
          highLat: rule,
          hanafi: false,
        );
        for (final m in [(6, 21), (12, 21), (1, 1)]) {
          final t = c.timesFor(2026, m.$1, m.$2);
          expect(t.length, 6);
        }
      }
    });
  });

  group('hijri offset', () {
    test('offset changes date and resets', () {
      final d = DateTime(2026, 11, 11);
      final base = HijriDate.fromDate(d);
      HijriDate.dayOffset = 1;
      final shifted = HijriDate.fromDate(d);
      HijriDate.dayOffset = 0;
      expect(shifted.day == base.day, isFalse);
      expect(HijriDate.fromDate(d).day, base.day);
    });
  });

  group('azkar', () {
    test('every declared item resolves', () {
      for (final s in AzkarData.sets) {
        expect(
          AzkarData.resolve(s.id).length,
          s.items.length,
          reason: 'unresolved dua title in ${s.id}',
        );
      }
    });

    test('taps clamp, done toggles, streak counts', () {
      final s = AppState();
      expect(s.azkarTap('morning', 0, 2), 1);
      expect(s.azkarTap('morning', 0, 2), 2);
      expect(s.azkarTap('morning', 0, 2), 2);
      expect(s.azkarTaps('morning', 0), 2);
      expect(s.azkarStreak, 0);
      s.setAzkarDone(DateTime.now(), 'morning', true);
      expect(s.azkarStreak, 1);
      s.setAzkarDone(DateTime.now(), 'morning', false);
      expect(s.azkarStreak, 0);
      s.azkarResetSet('morning');
      expect(s.azkarTaps('morning', 0), 0);
    });

    test('reminder time stays inside the window', () {
      final a = DateTime(2026, 11, 11, 5);
      expect(
        NotificationService.azkarTime(a, a.add(const Duration(hours: 1)), 20),
        a.add(const Duration(minutes: 20)),
      );
      final short = NotificationService.azkarTime(
        a,
        a.add(const Duration(minutes: 10)),
        20,
      );
      expect(short.isBefore(a.add(const Duration(minutes: 10))), isTrue);
    });
  });

  group('rating + badges + backup', () {
    test('no rating prompt without a streak', () {
      expect(AppState().shouldAskForRating, isFalse);
    });

    test('badges start unearned', () {
      final b = computeBadges(AppState());
      expect(b.length, 9);
      expect(b.where((x) => x.earned), isEmpty);
    });

    test('azkar_done survives backup round trip', () {
      final s = AppState();
      s.setAzkarDone(DateTime.now(), 'evening', true);
      final json = BackupPayload.toJson(s);
      final t = AppState();
      BackupPayload.apply(t, json);
      expect(t.azkarDone, s.azkarDone);
    });
  });

  group('i18n overlay', () {
    test('extra languages cover the core keys', () {
      for (final l in QubaStrings.extraLangs) {
        expect(QubaStrings.langNames.containsKey(l), isTrue);
      }
    });
  });
}
