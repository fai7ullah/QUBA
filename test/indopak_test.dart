import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quba/app_state.dart';
import 'package:quba/data.dart';

/// IndoPak text + page-break data checks.
///
/// The bundled file is NOT yet declared in pubspec.yaml (the parent adds
/// the asset entry after this round), so the file-integrity tests below
/// read the JSON straight from disk with dart:io — they pass or fail on
/// the real files, with no asset pipeline involved. The repository test
/// loads through rootBundle like the app does; until the pubspec entry
/// lands it reports indopakAvailable == false, and that test SKIPS with
/// an explicit message instead of faking a pass.
///
/// Arabic literals are built from codepoint arrays (same convention as
/// widget_test.dart): IndoPak spelling is codepoint-sensitive and
/// literals can be normalized differently by editors.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  test('IndoPak bundle: 114 surahs, 6,236 ayahs, counts match Uthmani',
      () {
    final indopak = readJson('assets/quran/quran_indopak.json');
    final uthmani = readJson('assets/quran/quran_bundle.json');
    final indSurahs = indopak['surahs'] as List<dynamic>;
    final uthSurahs = uthmani['surahs'] as List<dynamic>;

    expect(indSurahs.length, 114);
    var total = 0;
    for (var i = 0; i < 114; i++) {
      final s = indSurahs[i] as Map<String, dynamic>;
      expect(s['number'], i + 1, reason: 'surah order');
      final name = s['name'] as String;
      expect(name.isNotEmpty, true, reason: 'surah ${i + 1} has a name');
      final ayahs = s['ayahs'] as List<dynamic>;
      expect(ayahs.length, (uthSurahs[i] as Map<String, dynamic>)['ayahs']
          .length,
          reason: 'surah ${i + 1} ayah count must match the Uthmani bundle');
      for (final a in ayahs) {
        expect(a, isA<String>());
        expect((a as String).isNotEmpty, true);
      }
      total += ayahs.length;
    }
    expect(total, 6236);
  });

  test('IndoPak spot checks: Basmala, 2:3, 2:255 in IndoPak spelling',
      () {
    final indopak = readJson('assets/quran/quran_indopak.json');
    final uthmani = readJson('assets/quran/quran_bundle.json');
    final indSurahs = indopak['surahs'] as List<dynamic>;
    final uthSurahs = uthmani['surahs'] as List<dynamic>;
    String ind(int s, int a) =>
        ((indSurahs[s - 1] as Map<String, dynamic>)['ayahs']
            as List<dynamic>)[a - 1] as String;
    String uth(int s, int a) =>
        (((uthSurahs[s - 1] as Map<String, dynamic>)['ayahs']
            as List<dynamic>)[a - 1] as Map<String, dynamic>)['ar'] as String;

    // 1:1 — the Basmala in IndoPak spelling: dotless head of khah
    // (U+06E1) as sukun, Farsi yeh (U+06CC) in al-raheem.
    final basmala = String.fromCharCodes(const [
      0x628, 0x650, 0x633, 0x6e1, 0x645, 0x650, 0x20, 0x671, 0x644, 0x644,
      0x651, 0x64e, 0x647, 0x650, 0x20, 0x671, 0x644, 0x631, 0x651, 0x64e,
      0x62d, 0x6e1, 0x645, 0x64e, 0x640, 0x670, 0x646, 0x650, 0x20, 0x671,
      0x644, 0x631, 0x651, 0x64e, 0x62d, 0x650, 0x6cc, 0x645, 0x650
    ]);
    expect(ind(1, 1), basmala);
    expect(ind(1, 1), isNot(uth(1, 1)),
        reason: 'IndoPak Basmala must differ from the Uthmani one');

    // 2:3 — contains the IndoPak spelling of the prayer word:
    // al-salah with waw + superscript alef + teh marbuta (U+0670),
    // and the verse uses Farsi yeh (U+06CC) + dotless khah sukun
    // (U+06E1) where Uthmani has Arabic yeh + plain sukun.
    final salah = String.fromCharCodes(const [
      0x671, 0x644, 0x635, 0x651, 0x64e, 0x644, 0x64e, 0x648, 0x670, 0x629
    ]);
    expect(ind(2, 3), contains(salah));
    final yuminoon = String.fromCharCodes(const [
      0x6cc, 0x64f, 0x624, 0x6e1, 0x645, 0x650, 0x646, 0x64f, 0x648, 0x646
    ]);
    expect(ind(2, 3), contains(yuminoon),
        reason: '2:3 must use Farsi yeh + dotless-khah sukun');
    expect(ind(2, 3).contains('\u064a'), false,
        reason: 'IndoPak text must not contain Arabic yeh U+064A');
    expect(ind(2, 3), isNot(uth(2, 3)));

    // 2:255 (Ayat al-Kursi) — al-hayy with Farsi yeh: U+06CC.
    final hayy = String.fromCharCodes(const [
      0x671, 0x644, 0x6e1, 0x62d, 0x64e, 0x6cc, 0x651, 0x64f
    ]);
    expect(ind(2, 255), contains(hayy));
    expect(ind(2, 255), isNot(uth(2, 255)));
  });

  test('IndoPak 15-line pages: 610 ranges covering all 6,236 ayahs', () {
    final pages = readJson('assets/quran/quran_indopak_pages.json');
    final uthmani = readJson('assets/quran/quran_bundle.json');
    final uthSurahs = uthmani['surahs'] as List<dynamic>;
    final counts = [
      for (final s in uthSurahs)
        ((s as Map<String, dynamic>)['ayahs'] as List<dynamic>).length
    ];
    final ranges = pages['pageRanges'] as List<dynamic>;
    expect(pages['totalPages'], 610);
    expect(ranges.length, 610);

    // Flatten the ranges and require exact, gapless, duplicate-free
    // coverage of the whole Quran in order.
    final flat = <String>[];
    for (var i = 0; i < 610; i++) {
      final r = ranges[i] as Map<String, dynamic>;
      expect(r['page'], i + 1, reason: 'page order');
      final from = (r['from'] as List<dynamic>).cast<int>();
      final to = (r['to'] as List<dynamic>).cast<int>();
      var s = from[0];
      var a = from[1];
      while (true) {
        flat.add('$s:$a');
        if (s == to[0] && a == to[1]) break;
        if (a < counts[s - 1]) {
          a++;
        } else {
          s++;
          a = 1;
        }
      }
    }
    expect(flat.length, 6236);
    expect(flat.toSet().length, 6236, reason: 'no ayah on two pages');
    expect(flat.first, '1:1');
    expect(flat.last, '114:6');
    // Anchors cross-checked against the Qudratullah print as published
    // by Quran Loop / Her Quran Academy: 2:255 on p.42, al-Mulk opens
    // p.562, juz 30 opens p.586.
    String pageOf(int s, int a) {
      for (final r in ranges) {
        final m = r as Map<String, dynamic>;
        final from = (m['from'] as List<dynamic>).cast<int>();
        final to = (m['to'] as List<dynamic>).cast<int>();
        final afterStart =
            s > from[0] || (s == from[0] && a >= from[1]);
        final beforeEnd = s < to[0] || (s == to[0] && a <= to[1]);
        if (afterStart && beforeEnd) return m['page'].toString();
      }
      return 'not found';
    }

    expect(pageOf(2, 255), '42');
    expect(pageOf(67, 1), '562');
    expect(pageOf(78, 1), '586');
  });

  test('QuranRepository loads IndoPak and the style switch changes text',
      () async {
    final repo = QuranRepository.instance;
    await repo.load();
    if (!repo.indopakAvailable) {
      markTestSkipped(
          'assets/quran/quran_indopak.json is not declared in pubspec.yaml '
          'yet, so rootBundle cannot see it and the repository falls back '
          'to Madani. Add the asset entry, then this test runs for real.');
      return;
    }
    expect(repo.indopakAvailable, true);
    expect(repo.surahNameArabic(1).isNotEmpty, true);

    // Madani (default) vs IndoPak text for 2:3 must differ, and the
    // IndoPak form must be the one from the bundled file.
    appState.mushafStyle = 'madani';
    final madani = repo.arabicText(2, 3);
    appState.mushafStyle = 'indopak';
    try {
      final indopakText = repo.arabicText(2, 3);
      expect(indopakText, isNot(madani));
      expect(indopakText.contains('\u06cc'), true,
          reason: 'IndoPak 2:3 must contain Farsi yeh U+06CC');
      expect(repo.arabicFontFamily, 'IndoPakQuran');
      expect(repo.bismillah.contains('\u06e1'), true,
          reason: 'IndoPak Basmala uses the dotless-khah sukun');
    } finally {
      appState.mushafStyle = 'madani';
    }
  });
}
