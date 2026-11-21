import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quba/wordbyword/wbw_repo.dart';

/// Word-by-word data asset + WordByWordRepository checks.
///
/// NOTE (phase 2, 2026-11-21): word-by-word did NOT ship — no licensed
/// source exists for a bundled file (Quranic Arabic Corpus is GPL +
/// no-change + has no English glosses; quran.com forbids redistribution
/// and its glosses ban commercial use; Tanzil transliteration is
/// non-commercial). The screen, repository and i18n keys stay in the
/// tree, ready for a future runtime-fetch implementation, but the
/// Extras tile and the reader button are hidden until data exists.
/// The four file-dependent tests below are therefore SKIPPED (not
/// deleted): they re-activate the moment a licensed wordbyword.json
/// lands. The loadForTest logic test still runs.
///
/// The file-integrity tests read the JSON straight from disk with
/// dart:io (same pattern as translation_test.dart) — they pass or fail
/// on the real file, with no asset pipeline involved.
///
/// The repository tests run in file order on purpose: the real-asset
/// test loads through rootBundle first (the file is declared in
/// pubspec.yaml), and only then does the loadForTest test overwrite
/// the singleton with a tiny hand-built map — load() is a no-op once
/// loaded, so the order matters.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  // Shared skip reason for the tests that need the (unshipped) data file.
  const noDataFile =
      'wordbyword.json not shipped: no licensed source (phase 2, 2026-11-21)';

  test('wordbyword.json: 114 surahs, 6,236 ayahs, counts match Uthmani',
      () {
    final wbw = readJson('assets/quran/wordbyword.json');
    final uthmani = readJson('assets/quran/quran_bundle.json');
    final wbwSurahs = wbw['surahs'] as List<dynamic>;
    final uthSurahs = uthmani['surahs'] as List<dynamic>;

    expect(wbwSurahs.length, 114);
    var total = 0;
    for (var i = 0; i < 114; i++) {
      final s = wbwSurahs[i] as Map<String, dynamic>;
      expect(s['number'], i + 1, reason: 'surah order');
      final ayahs = s['ayahs'] as List<dynamic>;
      expect(
        ayahs.length,
        ((uthSurahs[i] as Map<String, dynamic>)['ayahs'] as List<dynamic>)
            .length,
        reason: 'surah ${i + 1} ayah count must match the Uthmani bundle',
      );
      for (final a in ayahs) {
        final words = a as List<dynamic>;
        for (final w in words) {
          final wm = w as Map<String, dynamic>;
          expect((wm['a'] as String).isNotEmpty, true,
              reason: 'surah ${i + 1} has a word with empty Arabic');
          expect(wm['t'], isA<String>());
          expect(wm['m'], isA<String>());
        }
      }
      total += ayahs.length;
    }
    expect(total, 6236);
  }, skip: noDataFile);

  test('wordbyword.json spot check: 1:1 has 4 words, starting with '
      'بِسْمِ', () {
    final wbw = readJson('assets/quran/wordbyword.json');
    final wbwSurahs = wbw['surahs'] as List<dynamic>;
    final ayah1 = ((wbwSurahs[0] as Map<String, dynamic>)['ayahs']
        as List<dynamic>)[0] as List<dynamic>;
    expect(ayah1.length, 4);
    final first = ayah1[0] as Map<String, dynamic>;
    expect(first['a'], 'بِسْمِ');
    expect((first['t'] as String).isNotEmpty, true);
    expect((first['m'] as String).isNotEmpty, true);
  }, skip: noDataFile);

  test('WordByWordRepository loads the real asset via rootBundle',
      () async {
    final repo = WordByWordRepository.instance;
    await repo.load();
    expect(repo.loaded, true);
    expect(repo.isAvailable, true);

    final words = repo.wordsFor(1, 1);
    expect(words.length, 4);
    expect(words[0].arabic, 'بِسْمِ');
    expect(words[0].transliteration.isNotEmpty, true);
    expect(words[0].meaning.isNotEmpty, true);
    expect(repo.wordsFor(2, 255).isNotEmpty, true);

    expect(repo.wordsFor(1, 8), isEmpty,
        reason: 'surah 1 has only 7 ayahs');
    expect(repo.wordsFor(115, 1), isEmpty);
    expect(repo.wordsFor(0, 1), isEmpty);
    expect(repo.wordsFor(1, 0), isEmpty);
  }, skip: noDataFile);

  test('WordByWordRepository.wordsFor via loadForTest', () {
    final repo = WordByWordRepository.instance;
    repo.loadForTest({
      'surahs': [
        {
          'number': 1,
          'ayahs': [
            [
              {'a': 'بِسْمِ', 't': 'bismi', 'm': 'In (the) name'},
              {'a': 'ٱللَّهِ', 't': 'l-lahi', 'm': 'of Allah'},
            ],
            [
              {'a': 'ٱلْحَمْدُ', 't': 'al-hamdu', 'm': 'All praise'},
            ],
          ],
        },
      ],
    });

    expect(repo.loaded, true);
    expect(repo.isAvailable, true);

    final words = repo.wordsFor(1, 1);
    expect(words.length, 2);
    expect(words[0].arabic, 'بِسْمِ');
    expect(words[0].transliteration, 'bismi');
    expect(words[0].meaning, 'In (the) name');
    expect(words[1].arabic, 'ٱللَّهِ');
    expect(repo.wordsFor(1, 2).length, 1);

    expect(repo.wordsFor(1, 3), isEmpty);
    expect(repo.wordsFor(2, 1), isEmpty);
    expect(repo.wordsFor(0, 1), isEmpty);
    expect(repo.wordsFor(1, 0), isEmpty);
  });

  test('real wordbyword file parses via loadForTest', () {
    // Verifies the parse path on the REAL file without the asset
    // pipeline (which needs the pubspec entry the integrator adds).
    // Runs last: it replaces the small test map with the full data.
    final repo = WordByWordRepository.instance;
    repo.loadForTest(readJson('assets/quran/wordbyword.json'));
    expect(repo.isAvailable, true);
    final words = repo.wordsFor(1, 1);
    expect(words.length, 4);
    expect(words[0].arabic, 'بِسْمِ');
    expect(repo.wordsFor(2, 255).isNotEmpty, true);
  }, skip: noDataFile);
}
