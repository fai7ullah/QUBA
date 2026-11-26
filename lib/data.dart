import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'app_state.dart';

/// One verse of the Quran: Uthmani Arabic + Pickthall English.
/// [arabic] is ALWAYS the Uthmani text. For the text in the user's chosen
/// Mushaf style (Madani / IndoPak), use [QuranRepository.arabicText].
class Ayah {
  const Ayah({
    required this.number,
    required this.arabic,
    required this.english,
  });
  final int number;
  final String arabic;
  final String english;
}

class Surah {
  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.meaning,
    required this.revelation,
    required this.ayahs,
  });
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String meaning;
  final String revelation; // Meccan / Medinan
  final List<Ayah> ayahs;
  int get ayahCount => ayahs.length;
}

/// Loads the bundled, checksum-verified Quran data asset.
/// Source editions: quran-uthmani (Tanzil) + en.pickthall — 114 surahs, 6,236 verses.
///
/// A second Arabic text (IndoPak, quran-indopak from Tanzil) is loaded as
/// well when the asset exists. The Mushaf style in [AppState] picks which
/// text the UI shows; [arabicText] / [surahNameArabic] / [bismillah] /
/// [arabicFontFamily] are the style-aware accessors — every screen that
/// shows Quran Arabic must use them, never [Ayah.arabic] directly.
/// If the IndoPak asset is missing or invalid, the style silently falls
/// back to Madani so the app never breaks.
class QuranRepository {
  QuranRepository._();
  static final QuranRepository instance = QuranRepository._();

  List<Surah>? _surahs;
  List<Surah> get surahs => _surahs ?? const [];
  bool get loaded => _surahs != null;

  /// IndoPak text, same shape as [_surahs] but Arabic-only:
  /// [surah index 0..113] -> [ayah index 0..n-1] -> IndoPak Arabic.
  /// Null when the asset is missing or failed validation.
  List<List<String>>? _indopak;
  List<String>? _indopakSurahNames;

  /// True when the IndoPak text loaded and verified (114 surahs,
  /// 6,236 ayahs). False until then — and the style falls back to Madani.
  bool get indopakAvailable => _indopak != null;

  /// The active Mushaf style, resolved against availability: IndoPak only
  /// when the text is actually loaded.
  bool get _useIndoPak => appState.isIndoPak && indopakAvailable;

  /// Font family for Quran Arabic in the active style.
  String get arabicFontFamily => _useIndoPak ? 'IndoPakQuran' : 'AmiriQuran';

  /// The verse's Arabic in the active Mushaf style.
  String arabicText(int surah, int ayah) {
    if (_useIndoPak) return _indopak![surah - 1][ayah - 1];
    return _surahs![surah - 1].ayahs[ayah - 1].arabic;
  }

  /// The surah's Arabic name (with the سُورَةُ prefix, as bundled) in
  /// the active Mushaf style — used by the mushaf banner and bookmarks.
  String surahNameArabic(int surah) {
    if (_useIndoPak) return _indopakSurahNames![surah - 1];
    return _surahs![surah - 1].nameArabic;
  }

  /// The Basmala header line in the active style. Surah 1's first ayah
  /// IS the Basmala in both editions, so the IndoPak form is read from
  /// its own text rather than hard-coded.
  String get bismillah => _useIndoPak ? _indopak![0][0] : bismillahUthmani;

  /// Cumulative verse index (1-based global position) of a surah's first verse.
  int globalStartOf(int surahNumber) {
    var sum = 0;
    for (final s in surahs) {
      if (s.number == surahNumber) return sum + 1;
      sum += s.ayahCount;
    }
    return 1;
  }

  /// Global 1-based ayah index (1..6236) of a surah:ayah.
  int globalIndexOf(int surahNumber, int ayah) =>
      globalStartOf(surahNumber) + ayah - 1;

  /// [surah, ayah] for a global 1-based index; clamps to the last verse.
  List<int> surahAyahForGlobal(int global) {
    var remaining = global;
    for (final s in surahs) {
      if (remaining <= s.ayahCount) return [s.number, remaining];
      remaining -= s.ayahCount;
    }
    final last = surahs.last;
    return [last.number, last.ayahCount];
  }

  /// Diacritic-insensitive Arabic normalization for search: strips tashkeel
  /// and tatweel, unifies alef forms and ya / alef-maqsura — and the
  /// IndoPak letter variants (ہ/ھ, ی/ے, ک), so one query matches both
  /// editions of the text.
  static String normalizeArabic(String s) {
    return s
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
        .replaceAll(RegExp(r'[إأآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[ہھ]'), 'ه')
        .replaceAll(RegExp(r'[یے]'), 'ي')
        .replaceAll('ک', 'ك');
  }

  /// Searches Arabic text (diacritic-insensitive) and the Pickthall
  /// translation. Returns up to [limit] hits in Quran order.
  /// Arabic matches run against BOTH editions, so a query typed in
  /// either script finds its verse; the hit's [SearchHit.arabic] is in
  /// the active Mushaf style.
  List<SearchHit> search(String query, {int limit = 200}) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(q);
    final nq = isArabic ? normalizeArabic(q) : q.toLowerCase();
    final hits = <SearchHit>[];
    for (final s in surahs) {
      for (final a in s.ayahs) {
        final hay = isArabic
            ? normalizeArabic(a.arabic)
            : a.english.toLowerCase();
        var found = hay.contains(nq);
        if (!found && isArabic && _indopak != null) {
          found = normalizeArabic(_indopak![s.number - 1][a.number - 1])
              .contains(nq);
        }
        if (found) {
          hits.add(
            SearchHit(
              surah: s.number,
              ayah: a.number,
              arabic: arabicText(s.number, a.number),
              english: a.english,
            ),
          );
          if (hits.length >= limit) return hits;
        }
      }
    }
    return hits;
  }

  Future<void> load() async {
    if (_surahs != null) return;
    final raw = await rootBundle.loadString('assets/quran/quran_bundle.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = <Surah>[];
    for (final s in json['surahs'] as List<dynamic>) {
      final m = s as Map<String, dynamic>;
      list.add(
        Surah(
          number: m['number'] as int,
          nameArabic: m['name'] as String,
          nameEnglish: m['englishName'] as String,
          meaning: m['englishNameTranslation'] as String,
          revelation: m['revelationType'] as String,
          ayahs: [
            for (final a in m['ayahs'] as List<dynamic>)
              Ayah(
                number: (a as Map<String, dynamic>)['n'] as int,
                arabic: a['ar'] as String,
                english: a['en'] as String,
              ),
          ],
        ),
      );
    }
    _surahs = list;
    await _loadIndoPak();
  }

  /// Loads the IndoPak text asset (assets/quran/quran_indopak.json):
  /// {"surahs": [{"number": 1, "name": "...", "ayahs": ["...", ...]}]}.
  /// Validates 114 surahs / 6,236 ayahs; on ANY failure leaves
  /// [_indopak] null so the style falls back to Madani.
  Future<void> _loadIndoPak() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/quran/quran_indopak.json',
      );
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final surahsJson = json['surahs'] as List<dynamic>;
      if (surahsJson.length != 114) return;
      final text = <List<String>>[];
      final names = <String>[];
      var total = 0;
      for (final s in surahsJson) {
        final m = s as Map<String, dynamic>;
        final ayahs = (m['ayahs'] as List<dynamic>)
            .map((a) => a as String)
            .toList();
        text.add(ayahs);
        names.add(m['name'] as String);
        total += ayahs.length;
      }
      if (total != 6236) return;
      _indopak = text;
      _indopakSurahNames = names;
    } catch (_) {
      _indopak = null;
      _indopakSurahNames = null;
    }
  }

  Surah surah(int number) => surahs[number - 1];
}

/// One Quran search result.
class SearchHit {
  const SearchHit({
    required this.surah,
    required this.ayah,
    required this.arabic,
    required this.english,
  });
  final int surah;
  final int ayah;
  final String arabic;
  final String english;
}

/// The Bismillah header shown above surahs (except 1 — where it is verse 1 —
/// and 9, which has none). Kept in the Uthmani spelling of the bundled text.
const String bismillahUthmani = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

/// True when [surah] shows a separate Basmala header line above its verses:
/// every surah except 1 (Basmala IS ayah 1) and 9 (no Basmala at all).
/// The reader uses this for its list offset (1 when true, 0 otherwise);
/// the Basmala is never counted as an ayah.
bool hasBasmalaHeader(int surah) => surah != 1 && surah != 9;
