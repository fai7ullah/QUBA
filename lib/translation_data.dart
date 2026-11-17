import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import 'data.dart';

/// Quran translations shipped with QUBA, in addition to the Pickthall
/// English already inside [QuranRepository]'s bundle.
///
/// Translation ids (see [ids]):
/// - `en.pickthall` — Pickthall English, read from the Quran bundle.
/// - `ur.jalandhry` — Urdu, Fateh Muhammad Jalandhari
///   (assets/quran/trans_ur_jalandhry.json).
/// - `fa.ghomshei` — Persian/Dari, Mahdi Elahi Ghomshei
///   (assets/quran/trans_fa_ghomshei.json).
/// - `none` — no translation shown.
///
/// Licence basis for every shipped translation: public domain. See
/// TRANSLATIONS.md at the project root for the translator dates and the
/// copyright-term reasoning, including the life+70 caveat.
///
/// The two JSON assets have the same shape as quran_indopak.json:
/// `{"surahs": [{"number": 1, "ayahs": ["...", ...]}, ...]}` — 114
/// surahs, 6,236 ayahs, per-surah ayah counts matching the Uthmani
/// bundle. [load] validates those counts; a missing or invalid file
/// leaves that translation unavailable instead of throwing, so the app
/// never breaks over a translation asset.
class TranslationRepository {
  TranslationRepository._();
  static final TranslationRepository instance = TranslationRepository._();

  /// Translation ids the app can offer, in display order.
  static const List<String> ids = [
    'en.pickthall',
    'ur.jalandhry',
    'fa.ghomshei',
    'none',
  ];

  /// True once [load] (or [loadForTest]) has run, even if one of the
  /// translation files failed to load — check [isAvailable] per id.
  bool loaded = false;

  /// [surah index 0..113] -> [ayah index 0..n-1] -> translated text.
  /// Null when the asset is missing or failed validation.
  List<List<String>>? _ur;
  List<List<String>>? _fa;

  /// Loads both translation assets via rootBundle. Never throws: a
  /// missing or invalid file just leaves that translation unavailable.
  Future<void> load() async {
    if (loaded) return;
    _ur = await _loadOne('assets/quran/trans_ur_jalandhry.json');
    _fa = await _loadOne('assets/quran/trans_fa_ghomshei.json');
    loaded = true;
  }

  Future<List<List<String>>?> _loadOne(String asset) async {
    try {
      final raw = await rootBundle.loadString(asset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final text = _parse(json);
      if (text == null) return null;
      if (text.length != 114) return null;
      var total = 0;
      for (final ayahs in text) {
        for (final a in ayahs) {
          if (a.isEmpty) return null;
        }
        total += ayahs.length;
      }
      if (total != 6236) return null;
      return text;
    } catch (_) {
      return null;
    }
  }

  /// Parses `{"surahs": [{"number": n, "ayahs": [...]}, ...]}` into
  /// per-surah ayah lists, in file order. Returns null on any shape
  /// problem. Count validation (114 / 6,236) is the caller's job, so
  /// tests can load small hand-built maps through [loadForTest].
  static List<List<String>>? _parse(Map<String, dynamic> json) {
    try {
      final surahsJson = json['surahs'] as List<dynamic>;
      final text = <List<String>>[];
      for (var i = 0; i < surahsJson.length; i++) {
        final m = surahsJson[i] as Map<String, dynamic>;
        if (m['number'] as int != i + 1) return null;
        text.add((m['ayahs'] as List<dynamic>)
            .map((a) => a as String)
            .toList());
      }
      return text;
    } catch (_) {
      return null;
    }
  }

  /// Test-only loader: installs small hand-built translation maps so
  /// [textFor] is unit-testable without Flutter asset loading.
  @visibleForTesting
  void loadForTest(Map<String, dynamic> ur, Map<String, dynamic> fa) {
    _ur = _parse(ur);
    _fa = _parse(fa);
    loaded = true;
  }

  /// The translation text for one verse, or null when:
  /// - [id] is `'none'` or unknown,
  /// - the translation is unavailable (asset missing/invalid, or the
  ///   Quran bundle not loaded yet for `'en.pickthall'`),
  /// - [surah] / [ayah] is out of range.
  String? textFor(String id, int surah, int ayah) {
    if (id == 'none') return null;
    if (id == 'en.pickthall') {
      final repo = QuranRepository.instance;
      if (!repo.loaded) return null;
      if (surah < 1 || surah > repo.surahs.length) return null;
      final s = repo.surah(surah);
      if (ayah < 1 || ayah > s.ayahs.length) return null;
      return s.ayahs[ayah - 1].english;
    }
    final text = id == 'ur.jalandhry'
        ? _ur
        : id == 'fa.ghomshei'
            ? _fa
            : null;
    if (text == null) return null;
    if (surah < 1 || surah > text.length) return null;
    final ayahs = text[surah - 1];
    if (ayah < 1 || ayah > ayahs.length) return null;
    return ayahs[ayah - 1];
  }

  /// True when [id] can currently serve text. `'none'` is always
  /// available (it is a choice, not a file); `'en.pickthall'` needs
  /// the Quran bundle loaded; the other two need their asset loaded.
  /// Unknown ids are never available.
  bool isAvailable(String id) {
    switch (id) {
      case 'none':
        return true;
      case 'en.pickthall':
        return QuranRepository.instance.loaded;
      case 'ur.jalandhry':
        return _ur != null;
      case 'fa.ghomshei':
        return _fa != null;
      default:
        return false;
    }
  }

  /// True for the right-to-left translations (Urdu, Persian/Dari).
  bool isRtl(String id) => id == 'ur.jalandhry' || id == 'fa.ghomshei';

  /// i18n key for a translation id's display label (callers wrap it
  /// with tr()). Unknown ids fall back to the Pickthall label.
  static String labelKeyFor(String id) {
    switch (id) {
      case 'ur.jalandhry':
        return 'translation_jalandhry';
      case 'fa.ghomshei':
        return 'translation_ghomshei';
      case 'none':
        return 'translation_none';
      case 'en.pickthall':
      default:
        return 'translation_pickthall';
    }
  }
}
