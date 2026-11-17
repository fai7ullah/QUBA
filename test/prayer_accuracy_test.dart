import 'package:flutter_test/flutter_test.dart';
import 'package:quba/prayer_calc.dart';

/// Validates the ported on-device prayer calculation (see
/// lib/prayer_calc.dart) against the native app's Aladhan-checked values
/// for Kabul (34.5553, 69.2075), timezone UTC+4:30.
///
/// Reference values (native app, verified 2026-11-11):
/// Kabul 2026-11-11, MWL + Hanafi — Fajr 04:56, Sunrise 06:22,
/// Dhuhr 11:37, Asr 15:14, Maghrib 16:52, Isha 18:13.
void main() {
  List<int> calc(
    DateTime date, {
    String method = 'mwl',
    bool hanafi = true,
  }) {
    return PrayerCalc(
      lat: 34.5553,
      lng: 69.2075,
      tzHours: 4.5,
      method: method,
      hanafi: hanafi,
    ).timesForDate(date);
  }

  void expectClose(List<int> times, int index, int h, int m, String label,
      {int tolerance = 1}) {
    final actual = times[index];
    final expected = h * 60 + m;
    final diff = (actual - expected).abs();
    // ignore: avoid_print
    print('$label -> ${actual ~/ 60}:${(actual % 60).toString().padLeft(2, '0')} '
        '(ref $h:${m.toString().padLeft(2, '0')}, diff ${diff}m)');
    expect(diff, lessThanOrEqualTo(tolerance), reason: label);
  }

  test('Kabul 2026-11-11 — MWL + Hanafi vs native verified values', () {
    final t = calc(DateTime(2026, 11, 11));
    expectClose(t, 0, 4, 56, 'Fajr');
    expectClose(t, 1, 6, 22, 'Sunrise');
    expectClose(t, 2, 11, 37, 'Dhuhr');
    expectClose(t, 3, 15, 14, 'Asr');
    expectClose(t, 4, 16, 52, 'Maghrib');
    expectClose(t, 5, 18, 13, 'Isha');
  });

  test('Kabul 2026-11-11 — Karachi + Hanafi', () {
    final t = calc(DateTime(2026, 11, 11), method: 'karachi');
    expectClose(t, 0, 4, 56, 'Fajr', tolerance: 2);
    expectClose(t, 5, 18, 18, 'Isha', tolerance: 2);
  });

  test('Kabul 2026-06-15 — MWL + Hanafi (summer) vs Aladhan', () {
    final t = calc(DateTime(2026, 6, 15));
    expectClose(t, 0, 2, 54, 'Fajr', tolerance: 2);
    expectClose(t, 1, 4, 40, 'Sunrise', tolerance: 2);
    expectClose(t, 2, 11, 54, 'Dhuhr', tolerance: 2);
    expectClose(t, 3, 16, 56, 'Asr', tolerance: 2);
    expectClose(t, 4, 19, 7, 'Maghrib', tolerance: 2);
    expectClose(t, 5, 20, 46, 'Isha', tolerance: 2);
  });

  test('Qibla bearing — Kabul, London, Jakarta', () {
    expect(QiblaMath.bearing(34.5553, 69.2075), closeTo(250.77, 0.5));
    expect(QiblaMath.bearing(51.5074, -0.1278), closeTo(119.0, 0.5));
    expect(QiblaMath.bearing(-6.2088, 106.8456), closeTo(295.2, 0.5));
    expect(QiblaMath.compassPoint(250.77), 'WSW');
  });

  test('Hijri date — 2026-11-12 is 1 Jumada al-Akhirah 1448', () {
    final h = HijriDate.fromDate(DateTime(2026, 11, 12));
    expect(h.year, 1448);
    expect(h.month, 6);
    expect(h.day, 1);
    expect(h.monthName, 'Jumada al-Akhirah');
  });
}
