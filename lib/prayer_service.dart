import 'app_state.dart';
import 'i18n.dart';
import 'prayer_calc.dart';

class PrayerEntry {
  const PrayerEntry(this.name, this.time);
  final String name;
  final DateTime time;
}

/// On-device prayer calculation (ported PrayTimes algorithm — see
/// prayer_calc.dart) + Hijri date helpers. No network is ever involved.
class PrayerService {
  static const prayerNames = [
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  static PrayerCalc calcFor(AppState s) {
    final tzHours = DateTime.now().timeZoneOffset.inMinutes / 60.0;
    return PrayerCalc(
      lat: s.lat,
      lng: s.lng,
      tzHours: tzHours,
      method: s.calcMethod,
      hanafi: s.asrHanafi,
    );
  }

  static List<PrayerEntry> dayList(DateTime date, AppState s) {
    final minutes = calcFor(s).timesForDate(date);
    final day = DateTime(date.year, date.month, date.day);
    return [
      for (var i = 0; i < 6; i++)
        PrayerEntry(
          prayerNames[i],
          day.add(Duration(minutes: minutes[i])),
        ),
    ];
  }

  /// The next prayer from [now]: today's remaining one, else tomorrow's Fajr.
  static PrayerEntry nextPrayer(DateTime now, AppState s) {
    for (final e in dayList(now, s)) {
      if (e.time.isAfter(now)) return e;
    }
    final tomorrow = dayList(now.add(const Duration(days: 1)), s);
    return tomorrow.first;
  }

  static String methodLabel(AppState s) => s.calcMethod == 'karachi'
      ? 'Univ. of Islamic Sciences, Karachi'
      : 'Muslim World League';

  static String madhabLabel(AppState s) =>
      s.asrHanafi ? tr('madhab_hanafi') : tr('madhab_shafii');

  static String hijriString(DateTime date) =>
      HijriDate.fromDate(date).localizedString();

  static String formatTime(DateTime t) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$h12:${t.minute.toString().padLeft(2, '0')} $ampm';
  }

  /// Countdown like "2 h 07 m 21 s" (reference design format).
  static String formatCountdownLong(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    if (h > 0) return '$h h ${two(m)} m ${two(s)} s';
    return '${two(m)} m ${two(s)} s';
  }

  static String formatCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}
