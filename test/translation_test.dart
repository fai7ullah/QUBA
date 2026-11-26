import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quba/data.dart';
import 'package:quba/translation_data.dart';

/// Quran translation assets + TranslationRepository checks.
///
/// The file-integrity tests read the JSON straight from disk with
/// dart:io (same pattern as indopak_test.dart) — they pass or fail on
/// the real files, with no asset pipeline involved.
///
/// The repository tests run in file order on purpose: the real-asset
/// test loads through rootBundle first (the two files are declared in
/// pubspec.yaml), and only then does the loadForTest test overwrite
/// the singleton with a tiny hand-built map — load() is a no-op once
/// loaded, so the order matters.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  const files = {
    'en.yusufali': 'assets/quran/trans_en_yusufali.json',
    'ur.jalandhry': 'assets/quran/trans_ur_jalandhry.json',
    'fa.ghomshei': 'assets/quran/trans_fa_ghomshei.json',
  };

  for (final entry in files.entries) {
    final id = entry.key;
    final path = entry.value;

    test('$id: 114 surahs, 6,236 ayahs, counts match Uthmani', () {
      final trans = readJson(path);
      final uthmani = readJson('assets/quran/quran_bundle.json');
      final trSurahs = trans['surahs'] as List<dynamic>;
      final uthSurahs = uthmani['surahs'] as List<dynamic>;

      expect(trSurahs.length, 114);
      var total = 0;
      for (var i = 0; i < 114; i++) {
        final s = trSurahs[i] as Map<String, dynamic>;
        expect(s['number'], i + 1, reason: 'surah order');
        final ayahs = s['ayahs'] as List<dynamic>;
        expect(
          ayahs.length,
          ((uthSurahs[i] as Map<String, dynamic>)['ayahs'] as List<dynamic>)
              .length,
          reason: 'surah ${i + 1} ayah count must match the Uthmani bundle',
        );
        for (final a in ayahs) {
          expect(a, isA<String>());
          expect(
            (a as String).isNotEmpty,
            true,
            reason: 'surah ${i + 1} has an empty ayah',
          );
        }
        total += ayahs.length;
      }
      expect(total, 6236);
    });

    test('$id spot checks: 1:1 and 2:255 exist and are non-empty', () {
      final trans = readJson(path);
      final trSurahs = trans['surahs'] as List<dynamic>;
      String text(int s, int a) =>
          ((trSurahs[s - 1] as Map<String, dynamic>)['ayahs']
                  as List<dynamic>)[a - 1]
              as String;
      expect(text(1, 1).isNotEmpty, true);
      expect(text(2, 255).isNotEmpty, true);
    });
  }

  test('Translations differ from each other and from Pickthall', () {
    final ur =
        readJson('assets/quran/trans_ur_jalandhry.json')['surahs']
            as List<dynamic>;
    final fa =
        readJson('assets/quran/trans_fa_ghomshei.json')['surahs']
            as List<dynamic>;
    final bundle =
        readJson('assets/quran/quran_bundle.json')['surahs'] as List<dynamic>;
    String urText(int s, int a) =>
        ((ur[s - 1] as Map<String, dynamic>)['ayahs'] as List<dynamic>)[a - 1]
            as String;
    String faText(int s, int a) =>
        ((fa[s - 1] as Map<String, dynamic>)['ayahs'] as List<dynamic>)[a - 1]
            as String;
    String enText(int s, int a) =>
        (((bundle[s - 1] as Map<String, dynamic>)['ayahs'] as List<dynamic>)[a -
                    1]
                as Map<String, dynamic>)['en']
            as String;
    expect(urText(1, 1), isNot(faText(1, 1)));
    expect(urText(1, 1), isNot(enText(1, 1)));
    expect(faText(1, 1), isNot(enText(1, 1)));
    // Exact 1:1 wording, as downloaded from AlQuran Cloud.
    expect(
      urText(1, 1),
      'شروع الله کا نام لے کر جو بڑا مہربان نہایت رحم والا ہے',
    );
    expect(faText(1, 1), 'به نام خداوند بخشنده مهربان');
  });

  test('TranslationRepository loads the real assets via rootBundle', () async {
    // The Quran bundle must load first: 'en.pickthall' reads from it.
    final quran = QuranRepository.instance;
    await quran.load();
    expect(quran.loaded, true);

    final repo = TranslationRepository.instance;
    await repo.load();
    expect(repo.loaded, true);
    expect(repo.isAvailable('en.yusufali'), true);
    expect(repo.isAvailable('en.pickthall'), true);
    expect(repo.isAvailable('ur.jalandhry'), true);
    expect(repo.isAvailable('fa.ghomshei'), true);
    expect(repo.isAvailable('none'), true);

    expect(
      repo.textFor('en.yusufali', 1, 1),
      'In the name of Allah, Most Gracious, Most Merciful.',
    );
    expect(
      repo.textFor('en.pickthall', 1, 1),
      'In the name of Allah, the Beneficent, the Merciful.',
    );
    expect(
      repo.textFor('ur.jalandhry', 1, 1),
      'شروع الله کا نام لے کر جو بڑا مہربان نہایت رحم والا ہے',
    );
    expect(repo.textFor('fa.ghomshei', 1, 1), 'به نام خداوند بخشنده مهربان');
    expect(repo.textFor('ur.jalandhry', 2, 255)!.isNotEmpty, true);
    expect(repo.textFor('fa.ghomshei', 2, 255)!.isNotEmpty, true);

    expect(
      repo.textFor('en.pickthall', 1, 8),
      null,
      reason: 'surah 1 has only 7 ayahs',
    );
    expect(repo.textFor('en.pickthall', 115, 1), null);
    expect(repo.textFor('none', 1, 1), null);
  });

  test('TranslationRepository.textFor via loadForTest', () {
    final repo = TranslationRepository.instance;
    repo.loadForTest(
      {
        'surahs': [
          {
            'number': 1,
            'ayahs': ['ur one', 'ur two'],
          },
        ],
      },
      {
        'surahs': [
          {
            'number': 1,
            'ayahs': ['fa one', 'fa two'],
          },
        ],
      },
    );

    expect(repo.loaded, true);
    expect(repo.isAvailable('ur.jalandhry'), true);
    expect(repo.isAvailable('fa.ghomshei'), true);
    expect(repo.isAvailable('none'), true);
    expect(repo.isAvailable('xx.unknown'), false);

    expect(repo.textFor('ur.jalandhry', 1, 1), 'ur one');
    expect(repo.textFor('ur.jalandhry', 1, 2), 'ur two');
    expect(repo.textFor('fa.ghomshei', 1, 1), 'fa one');
    expect(repo.textFor('fa.ghomshei', 1, 2), 'fa two');

    expect(repo.textFor('none', 1, 1), null);
    expect(repo.textFor('xx.unknown', 1, 1), null);

    // Out of range in every direction.
    expect(repo.textFor('ur.jalandhry', 1, 3), null);
    expect(repo.textFor('ur.jalandhry', 2, 1), null);
    expect(repo.textFor('ur.jalandhry', 0, 1), null);
    expect(repo.textFor('ur.jalandhry', 1, 0), null);
    expect(repo.textFor('fa.ghomshei', 1, 99), null);

    expect(repo.isRtl('ur.jalandhry'), true);
    expect(repo.isRtl('fa.ghomshei'), true);
    expect(repo.isRtl('en.pickthall'), false);
    expect(repo.isRtl('none'), false);
    expect(repo.isRtl('xx.unknown'), false);

    expect(TranslationRepository.ids, [
      'en.yusufali',
      'en.pickthall',
      'ur.jalandhry',
      'fa.ghomshei',
      'none',
    ]);
  });

  test('Yusuf Ali is the default English translation (round 4)', () {
    final repo = TranslationRepository.instance;
    repo.loadForTest(
      {
        'surahs': [
          {
            'number': 1,
            'ayahs': ['ur one'],
          },
        ],
      },
      {
        'surahs': [
          {
            'number': 1,
            'ayahs': ['fa one'],
          },
        ],
      },
      {
        'surahs': [
          {
            'number': 1,
            'ayahs': ['In the name of Allah, Most Gracious, Most Merciful.'],
          },
        ],
      },
    );

    expect(repo.isAvailable('en.yusufali'), true);
    expect(
      repo.textFor('en.yusufali', 1, 1),
      'In the name of Allah, Most Gracious, Most Merciful.',
    );
    expect(
      repo.textFor('en.yusufali', 1, 2),
      null,
      reason: 'fixture has only one ayah for surah 1',
    );
    expect(repo.isRtl('en.yusufali'), false);
    expect(
      TranslationRepository.labelKeyFor('en.yusufali'),
      'translation_yusufali',
    );
    // Yusuf Ali is first in the list, so it is the default shown.
    expect(TranslationRepository.ids.first, 'en.yusufali');
  });
}
