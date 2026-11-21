import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quba/hadith/hadith_repo.dart';

/// Hadith data assets + HadithRepository checks.
///
/// The file-integrity tests read the JSON straight from disk with
/// dart:io (same pattern as translation_test.dart) — they pass or fail
/// on the real files, with no asset pipeline involved.
///
/// The repository tests run in file order on purpose: the real-asset
/// tests load through rootBundle first (the six files are declared in
/// pubspec.yaml), and only then does the loadForTest test overwrite the
/// singleton's 'bukhari' book with a tiny hand-built map — loadBook is
/// a no-op once a book is loaded, so the order matters.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  const bookIds = [
    'bukhari',
    'muslim',
    'abudawud',
    'tirmidhi',
    'nasai',
    'ibnmajah',
  ];

  group('hadith data files (dart:io)', () {
    for (final id in bookIds) {
      test('$id: total matches parsed count; every hadith has Arabic', () {
        final json = readJson('assets/hadith/$id.json');
        expect(json['book'], id);
        expect((json['title_en'] as String).isNotEmpty, true,
            reason: '$id title_en');
        expect((json['title_ar'] as String).isNotEmpty, true,
            reason: '$id title_ar');
        final total = json['total'] as int;
        final chapters = json['chapters'] as List<dynamic>;
        expect(chapters.isNotEmpty, true, reason: '$id has no chapters');
        var count = 0;
        for (final c in chapters) {
          final cm = c as Map<String, dynamic>;
          final hadiths = cm['hadiths'] as List<dynamic>;
          for (final h in hadiths) {
            final hm = h as Map<String, dynamic>;
            expect((hm['ar'] as String).isNotEmpty, true,
                reason: '$id hadith ${hm['n']} has empty Arabic');
            count++;
          }
        }
        expect(count, total,
            reason: '$id parsed count must match the file "total"');
      });

      test('$id spot check: first hadith non-empty with a reference', () {
        final json = readJson('assets/hadith/$id.json');
        final chapters = json['chapters'] as List<dynamic>;
        final first = ((chapters[0] as Map<String, dynamic>)['hadiths']
            as List<dynamic>)[0] as Map<String, dynamic>;
        expect((first['ar'] as String).isNotEmpty, true);
        expect((first['ref'] as String).isNotEmpty, true);
      });
    }
  });

  group('HadithRepository (rootBundle, real assets)', () {
    test('loads all six books; totals match the files', () async {
      final repo = HadithRepository.instance;
      for (final id in bookIds) {
        await repo.loadBook(id);
        expect(repo.isLoaded(id), true, reason: '$id should load');
        expect(repo.isAvailable(id), true);
        final book = repo.book(id)!;
        final fileTotal =
            readJson('assets/hadith/$id.json')['total'] as int;
        expect(book.total, fileTotal, reason: '$id total');
        expect(book.count, fileTotal, reason: '$id parsed count');
      }
      expect(repo.books.length, 6);
      expect(
        repo.books.map((b) => b.id).toList(),
        bookIds,
        reason: 'books are listed in canonical order',
      );
    });

    test('search finds Arabic matches across books', () async {
      final repo = HadithRepository.instance;
      await repo.loadAll();
      expect(repo.search('الله').isNotEmpty, true,
          reason: 'Arabic search should find matches');
      // All six books are Arabic-only in the current data (every "en"
      // is null), so an English query correctly finds nothing. The
      // English search path itself is covered by the loadForTest test
      // below with hand-built English content. If translations ship
      // later, this expectation must be revisited.
      expect(repo.search('Allah'), isEmpty,
          reason: 'current data is Arabic-only');
      expect(repo.search(''), isEmpty);
      expect(repo.search('zzzqqqxxyy'), isEmpty);
      final limited = repo.search('الله', limit: 5);
      expect(limited.length, lessThanOrEqualTo(5));
    });
  });

  group('HadithRepository search logic (loadForTest, no assets)', () {
    test('Arabic search ignores diacritics; English is case-insensitive',
        () {
      final repo = HadithRepository.instance;
      repo.loadForTest('bukhari', {
        'book': 'bukhari',
        'title_en': 'Sahih al-Bukhari',
        'title_ar': 'صحيح البخاري',
        'total': 2,
        'chapters': [
          {
            'n': 1,
            'title_en': 'Revelation',
            'title_ar': 'بدء الوحي',
            'hadiths': [
              {
                'n': 1,
                'ar': 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
                'en': 'Actions are but by intentions.',
                'grade': 'Sahih',
                'ref': 'Sahih al-Bukhari 1',
              },
              {
                'n': 2,
                'ar': 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ',
                'en': null,
                'grade': null,
                'ref': 'Sahih al-Bukhari 2',
              },
            ],
          },
        ],
      });
      expect(repo.isLoaded('bukhari'), true);
      expect(repo.book('bukhari')!.count, 2);
      expect(repo.book('bukhari')!.total, 2);
      // The real-asset tests above may already have loaded the other
      // books, so these assertions check the small map's hadiths are
      // found (by ref) rather than exact hit counts.
      bool found(String query, String ref) =>
          repo.search(query).any((h) => h.ref == ref);
      // Query without tashkeel finds text with tashkeel.
      expect(found('الاعمال', 'Sahih al-Bukhari 1'), true);
      expect(found('actions', 'Sahih al-Bukhari 1'), true);
      expect(found('ACTIONS', 'Sahih al-Bukhari 1'), true);
      // Arabic-only hadith is invisible to English search: hadith 2
      // means "I seek refuge" in Arabic but has no English text.
      expect(found('refuge', 'Sahih al-Bukhari 2'), false);
      expect(found('اعوذ', 'Sahih al-Bukhari 2'), true);
      expect(repo.search(''), isEmpty);
      // The limit is respected.
      expect(repo.search('ا', limit: 1).length, 1);
    });

    test('real bukhari file parses via loadForTest and is searchable',
        () {
      // Verifies the parse + search path on the REAL file without the
      // asset pipeline (which needs the pubspec entries the integrator
      // adds). Runs last: it replaces the small test map with the full
      // book.
      final repo = HadithRepository.instance;
      repo.loadForTest('bukhari', readJson('assets/hadith/bukhari.json'));
      final book = repo.book('bukhari')!;
      expect(book.total, book.count);
      expect(book.chapters.isNotEmpty, true);
      expect(repo.search('الله').isNotEmpty, true);
      // Bukhari is Arabic-only in the current data (every "en" null).
      expect(repo.search('Allah'), isEmpty);
    });

    test('unknown book ids stay unavailable', () async {
      final repo = HadithRepository.instance;
      await repo.loadBook('no_such_book');
      expect(repo.isLoaded('no_such_book'), false);
      expect(repo.isAvailable('no_such_book'), false);
      expect(repo.book('no_such_book'), null);
    });
  });
}
