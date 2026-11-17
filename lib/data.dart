import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One verse of the Quran: Uthmani Arabic + Pickthall English.
class Ayah {
  const Ayah({required this.number, required this.arabic, required this.english});
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
class QuranRepository {
  QuranRepository._();
  static final QuranRepository instance = QuranRepository._();

  List<Surah>? _surahs;
  List<Surah> get surahs => _surahs ?? const [];
  bool get loaded => _surahs != null;

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
  /// and tatweel, unifies alef forms and ya / alef-maqsura.
  static String normalizeArabic(String s) {
    return s
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
        .replaceAll(RegExp(r'[إأآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
  }

  /// Searches Arabic text (diacritic-insensitive) and the Pickthall
  /// translation. Returns up to [limit] hits in Quran order.
  List<SearchHit> search(String query, {int limit = 200}) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(q);
    final nq = isArabic ? normalizeArabic(q) : q.toLowerCase();
    final hits = <SearchHit>[];
    for (final s in surahs) {
      for (final a in s.ayahs) {
        final hay = isArabic ? normalizeArabic(a.arabic) : a.english.toLowerCase();
        if (hay.contains(nq)) {
          hits.add(SearchHit(
            surah: s.number,
            ayah: a.number,
            arabic: a.arabic,
            english: a.english,
          ));
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
      list.add(Surah(
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
      ));
    }
    _surahs = list;
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
