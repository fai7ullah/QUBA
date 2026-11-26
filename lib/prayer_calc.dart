import 'dart:math' as math;

import 'i18n.dart';

/// One prayer-time calculation method: Fajr angle, and either an Isha
/// angle or "Isha = N minutes after Maghrib" (Umm al-Qura, Qatar).
/// Values follow the published standards used by PrayTimes / Aladhan.
class PrayerMethod {
  const PrayerMethod(this.id, this.name, this.fajr, this.isha,
      {this.ishaMinutes = 0});
  final String id;

  /// Proper name of the authority (not translated, like the other names).
  final String name;
  final double fajr;
  final double isha;

  /// When > 0, Isha is this many minutes after Maghrib and [isha] is unused.
  final int ishaMinutes;

  static const List<PrayerMethod> all = [
    PrayerMethod('mwl', 'Muslim World League', 18, 17),
    PrayerMethod('isna', 'ISNA (North America)', 15, 15),
    PrayerMethod('egypt', 'Egyptian General Authority of Survey', 19.5, 17.5),
    PrayerMethod('makkah', 'Umm al-Qura, Makkah', 18.5, 0, ishaMinutes: 90),
    PrayerMethod('karachi', 'Univ. of Islamic Sciences, Karachi', 18, 18),
    PrayerMethod('kuwait', 'Kuwait', 18, 17.5),
    PrayerMethod('qatar', 'Qatar', 18, 0, ishaMinutes: 90),
    PrayerMethod('dubai', 'Dubai (UAE)', 18.2, 18.2),
    PrayerMethod('singapore', 'Singapore / Malaysia (JAKIM)', 20, 18),
    PrayerMethod('turkey', 'Diyanet, Turkey', 18, 17),
    PrayerMethod('france', 'France (UOIF)', 12, 12),
  ];

  /// The method for [id]; unknown ids fall back to Muslim World League.
  static PrayerMethod byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return all.first;
  }

  /// A rough, offline suggestion of the method most used around a
  /// location (coarse regions, NOT country borders). It is only ever a
  /// suggestion — the user confirms it. Falls back to MWL.
  static String suggestFor(double lat, double lng) {
    bool inBox(double la1, double la2, double ln1, double ln2) =>
        lat >= la1 && lat <= la2 && lng >= ln1 && lng <= ln2;
    if (inBox(36, 42.5, 26, 45)) return 'turkey';
    if (inBox(16, 32.5, 34.5, 56)) return 'makkah';
    if (inBox(22, 32, 24.5, 34.5)) return 'egypt';
    if (inBox(22, 26.5, 51, 56.5)) return 'dubai';
    if (inBox(-11, 8, 95, 141)) return 'singapore';
    if (inBox(5, 38, 60, 93)) return 'karachi';
    if (inBox(15, 72, -170, -50)) return 'isna';
    if (inBox(41, 51.5, -5, 8.5)) return 'france';
    return 'mwl';
  }
}

/// On-device prayer-time calculation — a faithful Dart port of the native
/// QUBA `PrayerCalc` (standard PrayTimes-family solar-position formulas).
/// Methods: see [PrayerMethod.all]. Asr factor: Shafi'i 1, Hanafi 2.
/// Optional high-latitude rule ([highLat]) and per-prayer minute
/// adjustments ([adjust]). No network is ever involved.
///
/// [highLat] values: 'auto' (default — only fixes prayers that cannot be
/// computed at all, the original behaviour), 'midnight', 'oneseventh',
/// 'anglebased' (the three PrayTimes rules, always applied).
///
/// Verified against the native app's Aladhan-checked values for Kabul
/// (34.5553, 69.2075) on 2026-11-11, MWL + Hanafi — see
/// test/prayer_accuracy_test.dart.
class PrayerCalc {
  static const List<String> keys = [
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  PrayerCalc({
    required this.lat,
    required this.lng,
    required this.tzHours,
    this.method = 'mwl',
    this.hanafi = true,
    this.highLat = 'auto',
    this.adjust = const [0, 0, 0, 0, 0, 0],
  })  : fajrAngle = PrayerMethod.byId(method).fajr,
        ishaAngle = PrayerMethod.byId(method).isha,
        ishaMinutes = PrayerMethod.byId(method).ishaMinutes,
        asrFactor = hanafi ? 2 : 1;

  final double lat;
  final double lng;
  final double tzHours;
  final String method; // a PrayerMethod id
  final bool hanafi;
  final String highLat;

  /// Minute offsets for [Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha].
  final List<int> adjust;
  final double fajrAngle;
  final double ishaAngle;
  final int ishaMinutes;
  final int asrFactor;

  static double _dtr(double d) => d * math.pi / 180.0;
  static double _rtd(double r) => r * 180.0 / math.pi;
  static double _sin(double d) => math.sin(_dtr(d));
  static double _cos(double d) => math.cos(_dtr(d));
  static double _tan(double d) => math.tan(_dtr(d));
  static double _arcsin(double x) => _rtd(math.asin(x));
  static double _arccos(double x) => _rtd(math.acos(x));
  static double _arctan2(double y, double x) => _rtd(math.atan2(y, x));
  static double _arccot(double x) => _rtd(math.atan(1.0 / x));
  static double _fix(double a, double b) {
    final r = a - b * (a / b).floor();
    return r < 0 ? r + b : r;
  }

  static double _fixAngle(double a) => _fix(a, 360);
  static double _fixHour(double a) => _fix(a, 24);

  static double _julian(int y, int m, int d) {
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5;
  }

  /// Returns [declination (deg), equation of time (hours)].
  static List<double> _sunPosition(double jd) {
    final d = jd - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));
    final e = 23.439 - 0.00000036 * d;
    final ra = _fixHour(_arctan2(_cos(e) * _sin(l), _cos(l)) / 15.0);
    final decl = _arcsin(_sin(e) * _sin(l));
    final eqt = q / 15.0 - ra;
    return [decl, eqt];
  }

  double _midDay(double jd) => _fixHour(12 - _sunPosition(jd)[1]);

  /// Time when the sun reaches [angleDeg] below the horizon
  /// (negative = above); [ccw] = morning. NaN if it never happens.
  double _sunAngleTime(double jd, double angleDeg, bool ccw) {
    final decl = _sunPosition(jd)[0];
    final z = _midDay(jd);
    final arg = (-_sin(angleDeg) - _sin(decl) * _sin(lat)) /
        (_cos(decl) * _cos(lat));
    if (arg < -1 || arg > 1) return double.nan;
    final v = _arccos(arg) / 15.0;
    return z + (ccw ? -v : v);
  }

  double _asrTime(double jd, int factor) {
    final decl = _sunPosition(jd)[0];
    final angle = -_arccot(factor + _tan((lat - decl).abs()));
    return _sunAngleTime(jd, angle, false);
  }

  /// Minutes-from-midnight for the 6 prayers on the given local date.
  List<int> timesFor(int year, int month, int day) {
    final jd = _julian(year, month, day) - lng / (15.0 * 24.0);
    final dhuhr = _midDay(jd);
    var fajr = _sunAngleTime(jd, fajrAngle, true);
    var sunrise = _sunAngleTime(jd, 0.833, true);
    var asr = _asrTime(jd, asrFactor);
    var maghrib = _sunAngleTime(jd, 0.833, false);
    var isha = ishaMinutes > 0
        ? maghrib + ishaMinutes / 60.0
        : _sunAngleTime(jd, ishaAngle, false);

    // Polar day/night: keep every value finite.
    if (sunrise.isNaN) sunrise = dhuhr - 6;
    if (maghrib.isNaN) maghrib = dhuhr + 6;
    if (asr.isNaN) asr = dhuhr + 3;
    if (isha.isNaN && ishaMinutes > 0) isha = maghrib + ishaMinutes / 60.0;

    // High-latitude handling (PrayTimes "night portion" rules).
    final night = _fixHour(sunrise - maghrib); // sunset -> sunrise, hours
    final always = highLat != 'auto';
    double portion(double angle) {
      switch (highLat) {
        case 'midnight':
          return 0.5;
        case 'oneseventh':
          return 1.0 / 7.0;
        default: // 'anglebased' and the 'auto' fallback
          return angle / 60.0;
      }
    }

    final fajrLimit = portion(fajrAngle) * night;
    if (fajr.isNaN || (always && _fixHour(sunrise - fajr) > fajrLimit)) {
      fajr = sunrise - fajrLimit;
    }
    if (ishaMinutes == 0) {
      final ishaLimit = portion(ishaAngle) * night;
      if (isha.isNaN || (always && _fixHour(isha - maghrib) > ishaLimit)) {
        isha = maghrib + ishaLimit;
      }
    }

    final hours = [fajr, sunrise, dhuhr, asr, maghrib, isha];
    return [
      for (var i = 0; i < hours.length; i++)
        ((_fixHour(hours[i] + (tzHours - lng / 15.0)) * 60.0).round() +
                (i < adjust.length ? adjust[i] : 0)) %
            (24 * 60),
    ];
  }

  List<int> timesForDate(DateTime date) =>
      timesFor(date.year, date.month, date.day);

  static String fmt(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    var h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:${m.toString().padLeft(2, '0')}';
  }

  static String ampm(int minutes) => minutes ~/ 60 < 12 ? 'AM' : 'PM';

  static String fmt12(int minutes) => '${fmt(minutes)} ${ampm(minutes)}';
}

/// Arithmetic (civil/Kuwaiti-algorithm) Hijri date from a Gregorian date.
/// Faithful port of the native QUBA `Hijri`. May differ by a day from
/// sighting-based calendars on rare month boundaries.
class HijriDate {
  const HijriDate(this.year, this.month, this.day);

  static const List<String> months = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    'Shaban',
    'Ramadan',
    'Shawwal',
    'Dhul-Qadah',
    'Dhul-Hijjah',
  ];

  final int year;
  final int month; // 1..12
  final int day;

  static HijriDate fromGregorian(int gy, int gm, int gd) {
    // Julian Day Number (integer)
    final a = (14 - gm) ~/ 12;
    final y = gy + 4800 - a;
    final m = gm + 12 * a - 3;
    final jd =
        gd + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;

    // Kuwaiti algorithm
    var l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * l) ~/ 709;
    final day = l - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;
    return HijriDate(year, month, day);
  }

  /// User correction (in days, -2..+2) applied by [fromDate], because
  /// moon-sighting calendars differ by country. Set from the settings.
  /// 0 by default (and in tests).
  static int dayOffset = 0;

  static HijriDate fromDate(DateTime date) =>
      fromGregorian(date.year, date.month, date.day + dayOffset);

  /// Number of days in a Hijri month (civil calendar: 30/29 alternating,
  /// with leap years in the 30-year cycle adding a day to Dhul-Hijjah).
  static int daysInMonth(int year, int month) {
    if (month == 12) {
      // Leap years in the 30-year cycle: 2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29
      const leaps = {2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29};
      return leaps.contains(year % 30) ? 30 : 29;
    }
    return month.isOdd ? 30 : 29;
  }

  String get monthName => months[month - 1];

  @override
  String toString() => '$day $monthName $year AH';

  /// Display form in the current UI language (translated month name and
  /// era suffix). [toString] stays English — tests pin it.
  String localizedString() => trf('hijri_date', {
        'day': day,
        'month': tr('hijri_month_$month'),
        'year': year,
      });
}

/// Great-circle initial bearing from a point to the Kaaba in Makkah.
/// Faithful port of the native QUBA `Qibla`.
class QiblaMath {
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  /// Bearing in degrees clockwise from true north, 0..360.
  /// Kabul → 250.77° (verified against the native app).
  static double bearing(double latDeg, double lngDeg) {
    final lat1 = latDeg * math.pi / 180.0;
    final lat2 = kaabaLat * math.pi / 180.0;
    final dLng = (kaabaLng - lngDeg) * math.pi / 180.0;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180.0 / math.pi + 360.0) % 360.0;
  }

  /// 16-wind compass point for a bearing.
  static String compassPoint(double bearing) {
    const pts = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    return pts[(bearing / 22.5).round() % 16];
  }
}
