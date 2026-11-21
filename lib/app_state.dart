import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// All user settings + reading state, persisted with SharedPreferences.
/// Defaults follow the plan: Muslim World League + Hanafi, Kabul fallback.
class AppState extends ChangeNotifier {
  static const double kabulLat = 34.5553;
  static const double kabulLng = 69.2075;

  ThemeMode themeMode = ThemeMode.system;
  String calcMethod = 'mwl'; // 'mwl' | 'karachi'
  bool asrHanafi = true;
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

  /// UI language: 'en' (default), 'ps' Pashto, 'fa' Dari/Farsi, 'ur' Urdu.
  String lang = 'en';
  bool get isRtl => lang != 'en';

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
    _ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('themeMode', themeMode.name);
    await p.setString('calcMethod', calcMethod);
    await p.setBool('asrHanafi', asrHanafi);
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
