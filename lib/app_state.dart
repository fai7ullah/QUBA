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
  bool showTranslation = true;

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
    showTranslation = p.getBool('showTranslation') ?? true;
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
    _ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('themeMode', themeMode.name);
    await p.setString('calcMethod', calcMethod);
    await p.setBool('asrHanafi', asrHanafi);
    await p.setDouble('arabicFontSize', arabicFontSize);
    await p.setBool('showTranslation', showTranslation);
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
}

/// Global app state singleton.
final appState = AppState();
