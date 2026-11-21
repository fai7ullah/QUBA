import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quba/tafsir/tafsir_repo.dart';

/// Tafsir data assets + TafsirRepository checks.
///
/// The file-integrity tests read the JSON straight from disk with
/// dart:io (same pattern as translation_test.dart) — they pass or fail
/// on the real files, with no asset pipeline involved.
///
/// The repository tests run in file order on purpose: the real-asset
/// test loads through rootBundle first (the files are declared in
/// pubspec.yaml), and only then does the loadForTest test overwrite
/// the singleton with tiny hand-built maps — load() is a no-op once
/// loaded, so the order matters.
///
/// yusufali_commentary.json is OPTIONAL: its file test is skipped when
/// the file is not present.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  List<dynamic> uthmaniSurahs() =>
      readJson('assets/quran/quran_bundle.json')['surahs'] as List<dynamic>;

  test('jalalayn.json: 114 surahs, 6,236 ayahs, counts match Uthmani',
      () {
    final tafsir = readJson('assets/tafsir/jalalayn.json');
    final uth = uthmaniSurahs();
    final trSurahs = tafsir['surahs'] as List<dynamic>;

    expect(trSurahs.length, 114);
    var total = 0;
    for (var i = 0; i < 114; i++) {
      final s = trSurahs[i] as Map<String, dynamic>;
      expect(s['number'], i + 1, reason: 'surah order');
      final ayahs = s['ayahs'] as List<dynamic>;
      expect(
        ayahs.length,
        ((uth[i] as Map<String, dynamic>)['ayahs'] as List<dynamic>).length,
        reason: 'surah ${i + 1} ayah count must match the Uthmani bundle',
      );
      for (final a in ayahs) {
        expect(a, isA<String>());
        expect((a as String).isNotEmpty, true,
            reason: 'surah ${i + 1} has an empty Jalalayn entry');
      }
      total += ayahs.length;
    }
    expect(total, 6236);
  });

  test('jalalayn.json spot checks: 1:1 and 2:255 exist and are non-empty',
      () {
    final tafsir = readJson('assets/tafsir/jalalayn.json');
    final trSurahs = tafsir['surahs'] as List<dynamic>;
    String text(int s, int a) =>
        ((trSurahs[s - 1] as Map<String, dynamic>)['ayahs']
            as List<dynamic>)[a - 1] as String;
    expect(text(1, 1).isNotEmpty, true);
    expect(text(2, 255).isNotEmpty, true);
  });

  test(
      'yusufali_commentary.json, when present: 114 surahs, 6,236 ayahs, '
      'counts match Uthmani', () {
    if (!File('assets/tafsir/yusufali_commentary.json').existsSync()) {
      markTestSkipped('optional file not present yet');
      return;
    }
    final tafsir = readJson('assets/tafsir/yusufali_commentary.json');
    final uth = uthmaniSurahs();
    final trSurahs = tafsir['surahs'] as List<dynamic>;

    expect(trSurahs.length, 114);
    var total = 0;
    var nonEmpty = 0;
    for (var i = 0; i < 114; i++) {
      final s = trSurahs[i] as Map<String, dynamic>;
      expect(s['number'], i + 1, reason: 'surah order');
      final ayahs = s['ayahs'] as List<dynamic>;
      expect(
        ayahs.length,
        ((uth[i] as Map<String, dynamic>)['ayahs'] as List<dynamic>).length,
        reason: 'surah ${i + 1} ayah count must match the Uthmani bundle',
      );
      for (final a in ayahs) {
        expect(a, isA<String>());
        // Empty entries are normal here: Yusuf Ali has footnotes only
        // for some ayahs.
        if ((a as String).isNotEmpty) nonEmpty++;
      }
      total += ayahs.length;
    }
    expect(total, 6236);
    expect(nonEmpty, greaterThan(100),
        reason: 'commentary should cover a meaningful number of ayahs');
  });

  test('TafsirRepository loads the real assets via rootBundle', () async {
    final repo = TafsirRepository.instance;
    await repo.load();
    expect(repo.loaded, true);
    expect(repo.isAvailable('jalalayn'), true);
    // The Yusuf Ali commentary is optional: availability must match
    // whether its file exists.
    expect(
      repo.isAvailable('yusufali_commentary'),
      File('assets/tafsir/yusufali_commentary.json').existsSync(),
    );
    expect(repo.isAvailable('xx.unknown'), false);

    expect(repo.textFor('jalalayn', 1, 1)!.isNotEmpty, true);
    expect(repo.textFor('jalalayn', 2, 255)!.isNotEmpty, true);

    expect(repo.textFor('jalalayn', 1, 8), null,
        reason: 'surah 1 has only 7 ayahs');
    expect(repo.textFor('jalalayn', 115, 1), null);
    expect(repo.textFor('jalalayn', 0, 1), null);
    expect(repo.textFor('jalalayn', 1, 0), null);
    expect(repo.textFor('xx.unknown', 1, 1), null);
  });

  test('TafsirRepository.textFor via loadForTest', () {
    final repo = TafsirRepository.instance;
    repo.loadForTest({
      'jalalayn': {
        'surahs': [
          {
            'number': 1,
            'ayahs': ['tafsir one', 'tafsir two'],
          },
        ],
      },
      'yusufali_commentary': {
        'surahs': [
          {
            'number': 1,
            'ayahs': ['commentary one', ''],
          },
        ],
      },
    });

    expect(repo.loaded, true);
    expect(repo.isAvailable('jalalayn'), true);
    expect(repo.isAvailable('yusufali_commentary'), true);
    expect(repo.isAvailable('xx.unknown'), false);

    expect(repo.textFor('jalalayn', 1, 1), 'tafsir one');
    expect(repo.textFor('jalalayn', 1, 2), 'tafsir two');
    expect(repo.textFor('yusufali_commentary', 1, 1), 'commentary one');
    // An empty commentary entry reads as "no commentary for this ayah".
    expect(repo.textFor('yusufali_commentary', 1, 2), null);

    expect(repo.textFor('xx.unknown', 1, 1), null);

    // Out of range in every direction.
    expect(repo.textFor('jalalayn', 1, 3), null);
    expect(repo.textFor('jalalayn', 2, 1), null);
    expect(repo.textFor('jalalayn', 0, 1), null);
    expect(repo.textFor('jalalayn', 1, 0), null);

    expect(TafsirRepository.sources, ['jalalayn', 'yusufali_commentary']);
  });

  test('real jalalayn file parses via loadForTest', () {
    // Verifies the parse path on the REAL file without the asset
    // pipeline (which needs the pubspec entries the integrator adds).
    // Runs last: it replaces the small test maps with the full text.
    final repo = TafsirRepository.instance;
    repo.loadForTest({'jalalayn': readJson('assets/tafsir/jalalayn.json')});
    expect(repo.isAvailable('jalalayn'), true);
    expect(repo.textFor('jalalayn', 1, 1)!.isNotEmpty, true);
    expect(repo.textFor('jalalayn', 2, 255)!.isNotEmpty, true);
    expect(repo.textFor('jalalayn', 114, 6)!.isNotEmpty, true);
  });
}
