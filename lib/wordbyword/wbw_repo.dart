import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

/// One word of a verse: Arabic word, Latin transliteration, English
/// meaning. Data: Quranic Arabic Corpus word-by-word data (CC BY-SA),
/// bundled as assets/quran/wordbyword.json.
class WbwWord {
  const WbwWord({
    required this.arabic,
    required this.transliteration,
    required this.meaning,
  });

  final String arabic;
  final String transliteration;
  final String meaning;
}

/// Loads the bundled word-by-word data (assets/quran/wordbyword.json):
/// `{"surahs": [{"number": 1, "ayahs": [[{"a": "...", "t": "...",
/// "m": "..."}, ...], ...]}]}` — 114 surahs, 6,236 ayahs.
///
/// Like the translation repository, this never throws: a missing or
/// invalid file just leaves the feature unavailable.
class WordByWordRepository {
  WordByWordRepository._();
  static final WordByWordRepository instance = WordByWordRepository._();

  /// True once [load] (or [loadForTest]) has run, even if the file
  /// failed to load — check [isAvailable].
  bool loaded = false;

  /// [surah index 0..113] -> [ayah index 0..n-1] -> words of the ayah.
  /// Null when the asset is missing or failed validation.
  List<List<List<WbwWord>>>? _words;

  /// Loads the word-by-word asset via rootBundle. Never throws.
  Future<void> load() async {
    if (loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/quran/wordbyword.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final words = _parse(json);
      if (words != null) {
        var total = 0;
        for (final ayahs in words) {
          total += ayahs.length;
        }
        if (words.length == 114 && total == 6236) _words = words;
      }
    } catch (_) {
      _words = null;
    }
    loaded = true;
  }

  /// Parses the word-by-word file into per-surah, per-ayah word lists.
  /// Returns null on any shape problem. Count validation (114 /
  /// 6,236) is the caller's job, so tests can load small hand-built
  /// maps through [loadForTest].
  static List<List<List<WbwWord>>>? _parse(Map<String, dynamic> json) {
    try {
      final surahsJson = json['surahs'] as List<dynamic>;
      final words = <List<List<WbwWord>>>[];
      for (var i = 0; i < surahsJson.length; i++) {
        final m = surahsJson[i] as Map<String, dynamic>;
        if (m['number'] as int != i + 1) return null;
        final ayahs = <List<WbwWord>>[];
        for (final a in m['ayahs'] as List<dynamic>) {
          final list = <WbwWord>[];
          for (final w in a as List<dynamic>) {
            final wm = w as Map<String, dynamic>;
            list.add(
              WbwWord(
                arabic: wm['a'] as String,
                transliteration: (wm['t'] as String?) ?? '',
                meaning: (wm['m'] as String?) ?? '',
              ),
            );
          }
          ayahs.add(list);
        }
        words.add(ayahs);
      }
      return words;
    } catch (_) {
      return null;
    }
  }

  /// Test-only loader: installs a small hand-built word map so
  /// [wordsFor] is unit-testable without Flutter asset loading.
  @visibleForTesting
  void loadForTest(Map<String, dynamic> json) {
    _words = _parse(json);
    loaded = true;
  }

  /// The words of one verse, in reading order — or an empty list when
  /// the data is unavailable or [surah] / [ayah] is out of range.
  List<WbwWord> wordsFor(int surah, int ayah) {
    final words = _words;
    if (words == null) return const [];
    if (surah < 1 || surah > words.length) return const [];
    final ayahs = words[surah - 1];
    if (ayah < 1 || ayah > ayahs.length) return const [];
    return ayahs[ayah - 1];
  }

  /// True when the word-by-word data loaded and verified.
  bool get isAvailable => _words != null;
}
