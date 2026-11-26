import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../data.dart';

/// One hadith from a bundled collection.
///
/// The Arabic matn is the classical text (public domain); [english] is
/// the bundled translation when the book ships one, or null for
/// Arabic-only books. [grade] (e.g. "Sahih") is null when the source
/// carries no grade for this hadith.
///
/// [normalizedArabic] / [englishLower] are search indexes computed once
/// at parse time so [HadithRepository.search] never re-normalizes text.
class Hadith {
  Hadith({
    required this.number,
    required this.arabic,
    required this.english,
    required this.grade,
    required this.ref,
    required this.bookId,
    required this.chapter,
  }) : normalizedArabic = QuranRepository.normalizeArabic(arabic),
       englishLower = english?.toLowerCase();

  final int number;
  final String arabic;
  final String? english;
  final String? grade;
  final String ref;
  final String bookId;
  final int chapter;
  final String normalizedArabic;
  final String? englishLower;
}

/// One chapter (bab) of a hadith book. Titles may be empty strings in
/// the data; the UI falls back to "Chapter N" (tr('hadith_chapter_n')).
class HadithChapter {
  const HadithChapter({
    required this.number,
    required this.titleEn,
    required this.titleAr,
    required this.hadiths,
  });

  final int number;
  final String titleEn;
  final String titleAr;
  final List<Hadith> hadiths;
}

/// One parsed hadith book. [total] is the count declared in the file;
/// [count] is the number of hadiths actually parsed — the two must
/// agree (see test/hadith_test.dart).
class HadithBook {
  const HadithBook({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.total,
    required this.chapters,
  });

  final String id;
  final String titleEn;
  final String titleAr;
  final int total;
  final List<HadithChapter> chapters;

  int get count {
    var n = 0;
    for (final c in chapters) {
      n += c.hadiths.length;
    }
    return n;
  }
}

/// Loads the six bundled hadith collections (assets/hadith/*.json),
/// one book at a time, on demand.
///
/// File shape:
/// `{"book": "bukhari", "title_en": "...", "title_ar": "...",
/// "total": 7563, "chapters": [{"n": 1, "title_en": "...",
/// "title_ar": "...", "hadiths": [{"n": 1, "ar": "...",
/// "en": "... or null", "grade": "... or null",
/// "ref": "Sahih al-Bukhari 1"}]}]}`
///
/// Like the translation repository, this never throws: a missing or
/// invalid file just leaves that book unavailable, so the app never
/// breaks over a hadith asset. Books load lazily — [loadBook] fetches
/// one book; [loadAll] fetches all six (used before a search).
class HadithRepository {
  HadithRepository._();
  static final HadithRepository instance = HadithRepository._();

  /// The six books, in the order the UI lists them.
  static const List<String> bookIds = [
    'bukhari',
    'muslim',
    'abudawud',
    'tirmidhi',
    'nasai',
    'ibnmajah',
  ];

  final Map<String, HadithBook> _books = {};
  final Set<String> _attempted = {};
  final Map<String, Future<void>> _inFlight = {};

  /// Loads one book via rootBundle. Never throws. A second call for
  /// the same book is a no-op; concurrent calls share one load.
  Future<void> loadBook(String id) {
    if (_books.containsKey(id) || _attempted.contains(id)) {
      return Future.value();
    }
    return _inFlight.putIfAbsent(id, () async {
      try {
        final raw = await rootBundle.loadString('assets/hadith/$id.json');
        final book = _parse(id, jsonDecode(raw) as Map<String, dynamic>);
        if (book != null) _books[id] = book;
      } catch (_) {
        // Missing or invalid file: the book stays unavailable.
      } finally {
        _attempted.add(id);
        _inFlight.remove(id);
      }
    });
  }

  /// Loads all six books, one at a time. Never throws.
  Future<void> loadAll() async {
    for (final id in bookIds) {
      await loadBook(id);
    }
  }

  /// True once [loadBook] has loaded [id] successfully.
  bool isLoaded(String id) => _books.containsKey(id);

  /// True when [id] can currently serve hadith — i.e. it has loaded
  /// successfully. Call [loadBook] first; a book that failed to load
  /// (missing/invalid file) is never available.
  bool isAvailable(String id) => _books.containsKey(id);

  /// True once a load of [id] has been attempted (success or failure).
  /// Lets the UI tell "still loading" from "unavailable".
  bool loadAttempted(String id) => _attempted.contains(id);

  /// The loaded book, or null when it has not loaded (yet).
  HadithBook? book(String id) => _books[id];

  /// Loaded books, in [bookIds] order.
  List<HadithBook> get books => [
    for (final id in bookIds)
      if (_books.containsKey(id)) _books[id]!,
  ];

  /// Searches the LOADED books for [query] (up to [limit] hits, in
  /// book/chapter order). Arabic queries match diacritic-insensitively
  /// (see [QuranRepository.normalizeArabic]); other queries match the
  /// English translation case-insensitively. Arabic-only hadiths are
  /// invisible to English queries. An empty query returns no hits.
  List<Hadith> search(String query, {int limit = 100}) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(q);
    final nq = isArabic ? QuranRepository.normalizeArabic(q) : q.toLowerCase();
    final hits = <Hadith>[];
    for (final book in books) {
      for (final chapter in book.chapters) {
        for (final h in chapter.hadiths) {
          final found = isArabic
              ? h.normalizedArabic.contains(nq)
              : (h.englishLower?.contains(nq) ?? false);
          if (found) {
            hits.add(h);
            if (hits.length >= limit) return hits;
          }
        }
      }
    }
    return hits;
  }

  /// Test-only loader: installs a hand-built book map so [search] is
  /// unit-testable without Flutter asset loading.
  @visibleForTesting
  void loadForTest(String id, Map<String, dynamic> json) {
    final book = _parse(id, json);
    if (book != null) {
      _books[id] = book;
      _attempted.add(id);
    }
  }

  /// Parses one book file. Returns null on any shape problem.
  static HadithBook? _parse(String id, Map<String, dynamic> json) {
    try {
      final titleEn = json['title_en'] as String;
      final titleAr = json['title_ar'] as String;
      final total = (json['total'] as num).toInt();
      final chapters = <HadithChapter>[];
      for (final c in json['chapters'] as List<dynamic>) {
        final cm = c as Map<String, dynamic>;
        final chapterNo = (cm['n'] as num).toInt();
        final hadiths = <Hadith>[];
        for (final h in cm['hadiths'] as List<dynamic>) {
          final hm = h as Map<String, dynamic>;
          hadiths.add(
            Hadith(
              number: (hm['n'] as num).toInt(),
              arabic: hm['ar'] as String,
              english: hm['en'] as String?,
              grade: hm['grade'] as String?,
              ref: (hm['ref'] as String?) ?? '',
              bookId: id,
              chapter: chapterNo,
            ),
          );
        }
        chapters.add(
          HadithChapter(
            number: chapterNo,
            titleEn: (cm['title_en'] as String?) ?? '',
            titleAr: (cm['title_ar'] as String?) ?? '',
            hadiths: hadiths,
          ),
        );
      }
      if (chapters.isEmpty) return null;
      return HadithBook(
        id: id,
        titleEn: titleEn,
        titleAr: titleAr,
        total: total,
        chapters: chapters,
      );
    } catch (_) {
      return null;
    }
  }
}
