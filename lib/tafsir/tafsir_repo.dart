import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

/// Per-ayah tafsir text, bundled as JSON assets with the same shape as
/// the Quran translation files:
/// `{"surahs": [{"number": n, "ayahs": ["...", ...]}, ...]}` — 114
/// surahs, 6,236 ayahs.
///
/// Sources:
/// - `jalalayn` — Tafsir al-Jalalayn (Arabic, classical, public
///   domain), assets/tafsir/jalalayn.json. Every ayah has text.
/// - `yusufali_commentary` — Abdullah Yusuf Ali's commentary/footnotes
///   (English, public domain, died 1953), optionally present at
///   assets/tafsir/yusufali_commentary.json. Footnotes exist only for
///   some ayahs, so empty entries are normal here — [textFor] returns
///   null for them.
///
/// Like the translation repository, this never throws: a missing or
/// invalid file just leaves that source unavailable.
class TafsirRepository {
  TafsirRepository._();
  static final TafsirRepository instance = TafsirRepository._();

  /// Tafsir sources, in display order.
  static const List<String> sources = ['jalalayn', 'yusufali_commentary'];

  static const Map<String, String> _assets = {
    'jalalayn': 'assets/tafsir/jalalayn.json',
    'yusufali_commentary': 'assets/tafsir/yusufali_commentary.json',
  };

  /// True once [load] (or [loadForTest]) has run, even if a source
  /// failed to load — check [isAvailable] per source.
  bool loaded = false;

  /// [source] -> [surah index 0..113] -> [ayah index 0..n-1] -> text.
  /// Null when the asset is missing or failed validation. Entries may
  /// be empty strings (no commentary for that ayah).
  final Map<String, List<List<String>>?> _texts = {};

  /// Loads both tafsir assets via rootBundle. Never throws.
  Future<void> load() async {
    if (loaded) return;
    for (final source in sources) {
      _texts[source] = await _loadOne(_assets[source]!);
    }
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
  /// Empty strings are kept: a missing commentary is data, not damage.
  static List<List<String>>? _parse(Map<String, dynamic> json) {
    try {
      final surahsJson = json['surahs'] as List<dynamic>;
      final text = <List<String>>[];
      for (var i = 0; i < surahsJson.length; i++) {
        final m = surahsJson[i] as Map<String, dynamic>;
        if (m['number'] as int != i + 1) return null;
        text.add(
          (m['ayahs'] as List<dynamic>).map((a) => a as String).toList(),
        );
      }
      return text;
    } catch (_) {
      return null;
    }
  }

  /// Test-only loader: installs small hand-built tafsir maps so
  /// [textFor] is unit-testable without Flutter asset loading.
  @visibleForTesting
  void loadForTest(Map<String, Map<String, dynamic>> bySource) {
    for (final e in bySource.entries) {
      _texts[e.key] = _parse(e.value);
    }
    loaded = true;
  }

  /// The tafsir text for one verse, or null when:
  /// - [source] is unknown or unavailable,
  /// - [surah] / [ayah] is out of range,
  /// - the source has no text for that ayah (empty entry — normal for
  ///   the Yusuf Ali commentary, which covers only some ayahs).
  String? textFor(String source, int surah, int ayah) {
    final text = _texts[source];
    if (text == null) return null;
    if (surah < 1 || surah > text.length) return null;
    final ayahs = text[surah - 1];
    if (ayah < 1 || ayah > ayahs.length) return null;
    final t = ayahs[ayah - 1];
    return t.isEmpty ? null : t;
  }

  /// True when [source] can currently serve text. Unknown sources are
  /// never available.
  bool isAvailable(String source) => _texts[source] != null;
}
