import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_calc.dart';

/// All user settings + reading state, persisted with SharedPreferences.
/// Defaults follow the plan: Muslim World League + Hanafi, Kabul fallback.
class AppState extends ChangeNotifier {
  static const double kabulLat = 34.5553;
  static const double kabulLng = 69.2075;

  ThemeMode themeMode = ThemeMode.system;
  String calcMethod = 'mwl'; // a PrayerMethod id (see prayer_calc.dart)
  bool asrHanafi = true;

  /// High-latitude rule: 'auto' (default), 'midnight', 'oneseventh',
  /// 'anglebased'. See [PrayerCalc].
  String highLatRule = 'auto';

  /// Per-prayer minute adjustments for [Fajr, Sunrise, Dhuhr, Asr,
  /// Maghrib, Isha], each clamped to -30..+30.
  List<int> prayerAdjust = [0, 0, 0, 0, 0, 0];

  /// Hijri date correction in days (-2..+2) for moon-sighting differences.
  int hijriOffset = 0;

  /// Azkar sets completed: "yyyy-MM-dd:morning" / ":evening" / ":after".
  Set<String> azkarDone = {};

  /// Today's tap counts per Azkar item: "yyyy-MM-dd:set:index" -> taps.
  /// Only today's entries are kept (older ones are dropped on load).
  Map<String, int> azkarCounts = {};

  /// Daily reminder for the morning / evening Azkar (off by default).
  bool azkarMorningNotify = false;
  bool azkarEveningNotify = false;

  /// Rate-the-app prompt state: how many times asked, the epoch day
  /// before which we must not ask again, and whether the user rated.
  int rateAsks = 0;
  int rateNextAfterDay = 0;
  bool rateDone = false;
  double arabicFontSize = 30;

  /// Quran translation shown under each verse: 'en.yusufali' (default
  /// since round 4), 'en.pickthall', 'ur.jalandhry', 'fa.ghomshei',
  /// or 'none' (Arabic only).
  /// Replaces the old showTranslation toggle (round 3): 'none' means
  /// hidden. The old 'showTranslation' preference is still read once for
  /// users upgrading from a build that had the toggle.
  String translationId = 'en.yusufali';

  /// True when a translation is shown (translationId != 'none').
  bool get showTranslation => translationId != 'none';

  /// Active reciter (audio edition id): 'ar.alafasy' (default),
  /// 'ar.abdulsamad', 'ar.mahermuaiqly', 'ar.saoodshuraym'.
  String reciterId = 'ar.alafasy';

  /// First-run onboarding completed (shown once, skippable).
  bool onboardingDone = false;

  /// Prayer log: "yyyy-MM-dd" -> set of prayer names marked prayed
  /// (Fajr, Dhuhr, Asr, Maghrib, Isha). Sunrise is not a prayer and is
  /// never logged.
  Map<String, Set<String>> prayerLog = {};

  /// Verse notes: "surah:ayah" -> free text. Empty text = no note.
  Map<String, String> notes = {};

  /// Epoch days (UTC days since 1970-01-01) with reading activity:
  /// opening the reader or advancing the last-read position.
  Set<int> readingDays = {};

  /// Surahs downloaded verse-by-verse per reciter: "edition:surah"
  /// (e.g. "ar.mahermuaiqly:2"). Alafasy whole-surah files use the
  /// separate [downloadedSurahs] set below.
  Set<String> downloadedAyahSets = {};

  /// UI language: 'en' (default), 'ps' Pashto, 'fa' Dari/Farsi, 'ur' Urdu,
  /// 'ar' Arabic, 'id' Indonesian, 'tr' Turkish, 'bn' Bengali, 'fr' French,
  /// 'ms' Malay.
  String lang = 'en';
  bool get isRtl => const {'ps', 'fa', 'ur', 'ar'}.contains(lang);

  /// Mushaf style for the Arabic Quran text shown everywhere in the app:
  /// 'madani' (Uthmani script, default) or 'indopak' (IndoPak script).
  /// The text itself comes from QuranRepository; this only picks it.
  String mushafStyle = 'madani';
  bool get isIndoPak => mushafStyle == 'indopak';

  /// Khatma plan: goal days (0 = no plan), global ayah index (0-based)
  /// where the plan started, start day as epoch day.
  int khatmaDays = 0;
  int khatmaStartGlobal = 0;
  int khatmaStartDay = 0;

  /// Tasbih: total count per phrase key, and the current session target.
  Map<String, int> tasbihTotals = {};
  int tasbihTarget = 33;

  double lat = kabulLat;
  double lng = kabulLng;
  String locationName = 'Kabul (default)';
  bool locationIsGps = false;

  /// Notification toggle per prayer key: fajr, sunrise, dhuhr, asr, maghrib, isha.
  Map<String, bool> prayerNotify = {
    'Fajr': true,
    'Sunrise': false,
    'Dhuhr': true,
    'Asr': true,
    'Maghrib': true,
    'Isha': true,
  };

  int lastReadSurah = 1;
  int lastReadAyah = 1;
  Set<String> bookmarks = {}; // "surah:ayah"
  Set<int> downloadedSurahs = {};

  bool _ready = false;
  bool get ready => _ready;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    themeMode = switch (p.getString('themeMode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    calcMethod = p.getString('calcMethod') ?? 'mwl';
    asrHanafi = p.getBool('asrHanafi') ?? true;
    highLatRule = p.getString('high_lat_rule') ?? 'auto';
    if (!const {'auto', 'midnight', 'oneseventh', 'anglebased'}
        .contains(highLatRule)) {
      highLatRule = 'auto';
    }
    final adj = (p.getStringList('prayer_adjust') ?? const [])
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    prayerAdjust = [
      for (var i = 0; i < 6; i++)
        (i < adj.length ? adj[i] : 0).clamp(-30, 30).toInt(),
    ];
    hijriOffset = (p.getInt('hijri_offset') ?? 0).clamp(-2, 2).toInt();
    azkarDone = (p.getStringList('azkar_done') ?? const []).toSet();
    final todayKey = _dateKey(DateTime.now());
    azkarCounts = {};
    for (final e in p.getStringList('azkar_counts') ?? const <String>[]) {
      final i = e.lastIndexOf('=');
      if (i <= 0 || !e.startsWith(todayKey)) continue;
      final v = int.tryParse(e.substring(i + 1));
      if (v != null && v > 0) azkarCounts[e.substring(0, i)] = v;
    }
    azkarMorningNotify = p.getBool('azkar_morning_notify') ?? false;
    azkarEveningNotify = p.getBool('azkar_evening_notify') ?? false;
    rateAsks = p.getInt('rate_asks') ?? 0;
    rateNextAfterDay = p.getInt('rate_next_after_day') ?? 0;
    rateDone = p.getBool('rate_done') ?? false;
    arabicFontSize = p.getDouble('arabicFontSize') ?? 30;
    translationId = p.getString('translation_id') ??
        ((p.getBool('showTranslation') ?? true) ? 'en.yusufali' : 'none');
    reciterId = p.getString('reciter_id') ?? 'ar.alafasy';
    onboardingDone = p.getBool('onboarding_done') ?? false;
    final logEntries = p.getStringList('prayer_log') ?? const [];
    final log = <String, Set<String>>{};
    for (final e in logEntries) {
      final i = e.indexOf(':');
      if (i > 0) log.putIfAbsent(e.substring(0, i), () => {}).add(e.substring(i + 1));
    }
    prayerLog = log;
    try {
      final rawNotes = p.getString('verse_notes_json');
      if (rawNotes != null && rawNotes.isNotEmpty) {
        final decoded = jsonDecode(rawNotes) as Map<String, dynamic>;
        notes = decoded.map((k, v) => MapEntry(k, v as String));
      }
    } catch (_) {
      notes = {};
    }
    readingDays = (p.getStringList('reading_days') ?? const [])
        .map((e) => int.tryParse(e) ?? -1)
        .where((d) => d >= 0)
        .toSet();
    downloadedAyahSets =
        (p.getStringList('downloaded_ayah_sets') ?? const []).toSet();
    lang = p.getString('ui_lang') ?? 'en';
    mushafStyle = p.getString('mushaf_style') ?? 'madani';
    khatmaDays = p.getInt('khatma_days') ?? 0;
    khatmaStartGlobal = p.getInt('khatma_start_global') ?? 0;
    khatmaStartDay = p.getInt('khatma_start_day') ?? 0;
    tasbihTarget = p.getInt('tasbih_target') ?? 33;
    tasbihTotals = {
      for (final e in p.getStringList('tasbih_totals') ?? const [])
        if (e.contains(':')) e.split(':')[0]: int.tryParse(e.split(':')[1]) ?? 0,
    };
    lat = p.getDouble('lat') ?? kabulLat;
    lng = p.getDouble('lng') ?? kabulLng;
    locationName = p.getString('locationName') ?? 'Kabul (default)';
    locationIsGps = p.getBool('locationIsGps') ?? false;
    for (final k in prayerNotify.keys.toList()) {
      prayerNotify[k] = p.getBool('notify_$k') ?? prayerNotify[k]!;
    }
    lastReadSurah = p.getInt('lastReadSurah') ?? 1;
    lastReadAyah = p.getInt('lastReadAyah') ?? 1;
    bookmarks = (p.getStringList('bookmarks') ?? const []).toSet();
    downloadedSurahs =
        (p.getStringList('downloadedSurahs') ?? const []).map(int.parse).toSet();
    // Round 4: Yusuf Ali is the new default English translation, for
    // new installs AND existing users. One-time migration, done here
    // at the END of load (all fields are read, so _save is safe):
    // anyone still on the old default (Pickthall) moves to Yusuf Ali
    // once. The flag keeps it one-time, so a user who re-picks
    // Pickthall afterwards is never moved again.
    if (p.getBool('translation_migrated_yusufali') != true) {
      if (translationId == 'en.pickthall') translationId = 'en.yusufali';
      await p.setBool('translation_migrated_yusufali', true);
      await _save();
    }
    _applyDerived();
    _ready = true;
    notifyListeners();
  }

  /// Pushes settings that other layers read statically.
  void _applyDerived() {
    HijriDate.dayOffset = hijriOffset;
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('themeMode', themeMode.name);
    await p.setString('calcMethod', calcMethod);
    await p.setBool('asrHanafi', asrHanafi);
    await p.setString('high_lat_rule', highLatRule);
    await p.setStringList(
        'prayer_adjust', prayerAdjust.map((e) => '$e').toList());
    await p.setInt('hijri_offset', hijriOffset);
    await p.setStringList('azkar_done', azkarDone.toList());
    await p.setStringList('azkar_counts',
        [for (final e in azkarCounts.entries) '${e.key}=${e.value}']);
    await p.setBool('azkar_morning_notify', azkarMorningNotify);
    await p.setBool('azkar_evening_notify', azkarEveningNotify);
    await p.setInt('rate_asks', rateAsks);
    await p.setInt('rate_next_after_day', rateNextAfterDay);
    await p.setBool('rate_done', rateDone);
    await p.setDouble('arabicFontSize', arabicFontSize);
    await p.setString('translation_id', translationId);
    await p.setString('reciter_id', reciterId);
    await p.setBool('onboarding_done', onboardingDone);
    await p.setStringList('prayer_log', [
      for (final date in prayerLog.keys)
        for (final prayer in prayerLog[date]!) '$date:$prayer',
    ]);
    await p.setString('verse_notes_json', jsonEncode(notes));
    await p.setStringList(
        'reading_days', readingDays.map((d) => d.toString()).toList());
    await p.setStringList('downloaded_ayah_sets', downloadedAyahSets.toList());
    await p.setString('ui_lang', lang);
    await p.setString('mushaf_style', mushafStyle);
    await p.setInt('khatma_days', khatmaDays);
    await p.setInt('khatma_start_global', khatmaStartGlobal);
    await p.setInt('khatma_start_day', khatmaStartDay);
    await p.setInt('tasbih_target', tasbihTarget);
    await p.setStringList(
      'tasbih_totals',
      tasbihTotals.entries.map((e) => '${e.key}:${e.value}').toList(),
    );
    await p.setDouble('lat', lat);
    await p.setDouble('lng', lng);
    await p.setString('locationName', locationName);
    await p.setBool('locationIsGps', locationIsGps);
    for (final e in prayerNotify.entries) {
      await p.setBool('notify_${e.key}', e.value);
    }
    await p.setInt('lastReadSurah', lastReadSurah);
    await p.setInt('lastReadAyah', lastReadAyah);
    await p.setStringList('bookmarks', bookmarks.toList());
    await p.setStringList(
        'downloadedSurahs', downloadedSurahs.map((e) => '$e').toList());
  }

  void update(VoidCallback fn) {
    fn();
    _applyDerived();
    notifyListeners();
    _save();
  }

  void setLastRead(int surah, int ayah) {
    if (surah == lastReadSurah && ayah == lastReadAyah) return;
    lastReadSurah = surah;
    lastReadAyah = ayah;
    readingDays.add(_epochDayNow());
    _save();
    notifyListeners();
  }

  bool isBookmarked(int surah, int ayah) => bookmarks.contains('$surah:$ayah');

  void toggleBookmark(int surah, int ayah) {
    update(() {
      final key = '$surah:$ayah';
      if (!bookmarks.remove(key)) bookmarks.add(key);
    });
  }

  void setKhatma(int days, int startGlobal) {
    update(() {
      khatmaDays = days;
      khatmaStartGlobal = startGlobal;
      khatmaStartDay =
          DateTime.now().difference(DateTime.utc(1970)).inDays;
    });
  }

  void clearKhatma() => update(() => khatmaDays = 0);

  void addTasbihTotal(String key, int delta) =>
      update(() => tasbihTotals[key] = (tasbihTotals[key] ?? 0) + delta);

  void markDownloaded(int surah) => update(() => downloadedSurahs.add(surah));
  void unmarkDownloaded(int surah) =>
      update(() => downloadedSurahs.remove(surah));

  // ------------------------------------------------------------------
  // Round 3: reciter, translation, onboarding, prayer log, notes,
  // reading streak, per-reciter downloads.
  // ------------------------------------------------------------------

  void setReciter(String id) => update(() => reciterId = id);

  void setTranslation(String id) => update(() => translationId = id);

  void completeOnboarding() => update(() => onboardingDone = true);

  static int _epochDayNow() =>
      DateTime.now().difference(DateTime.utc(1970)).inDays;

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Toggle one prayer as prayed on [date] (prayer names: Fajr, Dhuhr,
  /// Asr, Maghrib, Isha).
  void togglePrayed(DateTime date, String prayer) {
    update(() {
      final key = _dateKey(date);
      final set = prayerLog.putIfAbsent(key, () => {});
      if (!set.remove(prayer)) set.add(prayer);
      if (set.isEmpty) prayerLog.remove(key);
    });
  }

  bool isPrayed(DateTime date, String prayer) =>
      prayerLog[_dateKey(date)]?.contains(prayer) ?? false;

  /// How many of the 5 prayers were marked prayed on [date].
  int prayedCountOn(DateTime date) =>
      prayerLog[_dateKey(date)]?.length ?? 0;

  /// Prayed counts for the last 7 days, oldest first.
  List<int> prayedLast7Days() {
    final now = DateTime.now();
    return List.generate(
        7, (i) => prayedCountOn(now.subtract(Duration(days: 6 - i))));
  }

  /// Free-text note on one verse (empty string = no note).
  String noteFor(int surah, int ayah) => notes['$surah:$ayah'] ?? '';

  void setNote(int surah, int ayah, String text) {
    update(() {
      final key = '$surah:$ayah';
      if (text.trim().isEmpty) {
        notes.remove(key);
      } else {
        notes[key] = text.trim();
      }
    });
  }

  void deleteNote(int surah, int ayah) =>
      update(() => notes.remove('$surah:$ayah'));

  /// Notes sorted by surah then ayah: (surah, ayah, text).
  List<(int, int, String)> get notesSorted {
    final out = <(int, int, String)>[];
    for (final entry in notes.entries) {
      final parts = entry.key.split(':');
      if (parts.length != 2) continue;
      final s = int.tryParse(parts[0]);
      final a = int.tryParse(parts[1]);
      if (s == null || a == null) continue;
      out.add((s, a, entry.value));
    }
    out.sort((x, y) => x.$1 != y.$1
        ? x.$1.compareTo(y.$1)
        : x.$2.compareTo(y.$2));
    return out;
  }

  /// Mark today as a reading day (called when the reader opens).
  void recordReadingDay() {
    if (readingDays.add(_epochDayNow())) {
      _save();
      notifyListeners();
    }
  }

  /// Consecutive days with reading activity, ending today (or yesterday
  /// if today has no activity yet).
  int get readingStreak {
    var day = _epochDayNow();
    if (!readingDays.contains(day)) day -= 1;
    var streak = 0;
    while (readingDays.contains(day)) {
      streak++;
      day -= 1;
    }
    return streak;
  }

  bool get readToday => readingDays.contains(_epochDayNow());

  // ------------------------------------------------------------------
  // Daily habits: prayer streak, totals, Azkar, rate prompt.
  // ------------------------------------------------------------------

  /// True when all five prayers are marked prayed on [date].
  bool allFivePrayedOn(DateTime date) => prayedCountOn(date) >= 5;

  /// Consecutive days with all five prayers marked, ending today (or
  /// yesterday while today is still incomplete). Capped at 3660 days.
  int get prayerStreak {
    var day = DateTime.now();
    if (!allFivePrayedOn(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (streak < 3660 && allFivePrayedOn(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Every prayer ever marked prayed.
  int get totalPrayed {
    var n = 0;
    for (final s in prayerLog.values) {
      n += s.length;
    }
    return n;
  }

  /// Sum of the tasbih counters (all phrases).
  int get tasbihLifetime {
    var n = 0;
    for (final v in tasbihTotals.values) {
      n += v;
    }
    return n;
  }

  /// Longest run of consecutive reading days ever recorded.
  int get longestReadingStreak {
    if (readingDays.isEmpty) return 0;
    final days = readingDays.toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i] == days[i - 1] + 1) {
        run++;
        if (run > best) best = run;
      } else if (days[i] != days[i - 1]) {
        run = 1;
      }
    }
    return best;
  }

  Timer? _saveTimer;

  /// Persist soon (coalesces rapid taps into one write).
  void _saveSoon() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _save);
  }

  String _azkarCountKey(String set, int index) =>
      '${_dateKey(DateTime.now())}:$set:$index';

  /// Taps recorded today for item [index] of Azkar set [set].
  int azkarTaps(String set, int index) =>
      azkarCounts[_azkarCountKey(set, index)] ?? 0;

  /// Record one tap (never above [target]); returns the new tap count.
  int azkarTap(String set, int index, int target) {
    final k = _azkarCountKey(set, index);
    final next = ((azkarCounts[k] ?? 0) + 1).clamp(0, target).toInt();
    azkarCounts[k] = next;
    notifyListeners();
    _saveSoon();
    return next;
  }

  /// Clear today's taps for one Azkar set.
  void azkarResetSet(String set) {
    final prefix = '${_dateKey(DateTime.now())}:$set:';
    update(() => azkarCounts.removeWhere((k, _) => k.startsWith(prefix)));
  }

  String azkarKey(DateTime date, String set) => '${_dateKey(date)}:$set';

  bool isAzkarDone(DateTime date, String set) =>
      azkarDone.contains(azkarKey(date, set));

  void setAzkarDone(DateTime date, String set, bool done) {
    update(() {
      final k = azkarKey(date, set);
      if (done) {
        azkarDone.add(k);
      } else {
        azkarDone.remove(k);
      }
    });
  }

  /// Consecutive days on which at least one Azkar set was completed.
  int get azkarStreak {
    bool any(DateTime d) =>
        isAzkarDone(d, 'morning') ||
        isAzkarDone(d, 'evening') ||
        isAzkarDone(d, 'after');
    var day = DateTime.now();
    if (!any(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (streak < 3660 && any(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Should the "rate QUBA" prompt be shown now? Only after a real
  /// achievement (7-day prayer or reading streak), at most twice, and
  /// never again once the user rated.
  bool get shouldAskForRating {
    if (rateDone || rateAsks >= 2) return false;
    if (_epochDayNow() < rateNextAfterDay) return false;
    return prayerStreak >= 7 || readingStreak >= 7;
  }

  /// Record that the prompt was shown; the next one waits 30 days.
  void noteRatingAsked() => update(() {
        rateAsks++;
        rateNextAfterDay = _epochDayNow() + 30;
      });

  void noteRated() => update(() => rateDone = true);

  /// Per-reciter verse-by-verse downloads ("edition:surah").
  bool isSurahDownloadedFor(String reciter, int surah) =>
      downloadedAyahSets.contains('$reciter:$surah');

  void markSurahDownloadedFor(String reciter, int surah) =>
      update(() => downloadedAyahSets.add('$reciter:$surah'));

  void unmarkSurahDownloadedFor(String reciter, int surah) =>
      update(() => downloadedAyahSets.remove('$reciter:$surah'));
}

/// Global app state singleton.
final appState = AppState();
