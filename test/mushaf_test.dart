// The fit-measurement tests intentionally print their reports — the
// counts are the deliverable.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quba/app_state.dart';
import 'package:quba/data.dart';
import 'package:quba/juz_data.dart';
import 'package:quba/mushaf_data.dart';
import 'package:quba/screens/mushaf_screen.dart';
import 'package:quba/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

// How each dataset reached the test (asset bundle vs source file) —
// printed by the first test so a missing pubspec entry is visible.
String _metaSource = 'unknown';
String _indopakPagesSource = 'unknown';
bool _amiriLoaded = false;
bool _indopakFontLoaded = false;

/// Reads a repo file for the test bundle, first relative to the working
/// directory (`flutter test` runs with cwd = the package root), then
/// relative to this test file's own location.
Future<String> _readSourceFile(String relative) async {
  final direct = File(relative);
  if (await direct.exists()) return direct.readAsString();
  final script = Platform.script.toFilePath();
  final root = File(script).parent.parent.path;
  return File('$root/$relative').readAsString();
}

/// Loads one Quran font for TextPainter measurement, so the fit numbers
/// come from real glyphs rather than the test fallback font.
Future<bool> _loadFont(String family, String asset) async {
  try {
    final loader = FontLoader(family);
    loader.addFont(rootBundle.load(asset));
    await loader.load();
    return true;
  } catch (e) {
    print('MUSHAF TEST: WARNING — could not load $family ($e)');
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final repo = QuranRepository.instance;
    await repo.load();

    // Madani meta: the asset bundle first; the source file when the
    // asset is not (yet) declared in pubspec.yaml.
    try {
      await MushafData.instance.load();
      _metaSource = 'asset bundle';
    } catch (_) {
      MushafData.instance
          .loadFromJsonString(await _readSourceFile(
              'assets/quran/quran_meta.json'));
      _metaSource = 'source file (dart:io) — not in the asset bundle';
    }
    // IndoPak pages: same pattern. MushafData.load() already tried the
    // bundle (and silently fell back to Madani when it was absent), so
    // only the source-file fallback is left to try here.
    if (MushafData.instance.indopakAvailable) {
      _indopakPagesSource = 'asset bundle';
    } else {
      try {
        await MushafData.instance.loadIndoPakFromJsonString(
            await _readSourceFile(
                'assets/quran/quran_indopak_pages.json'));
        _indopakPagesSource = 'source file (dart:io) — not in the bundle';
      } catch (e) {
        _indopakPagesSource = 'UNAVAILABLE ($e)';
      }
    }
    _amiriLoaded =
        await _loadFont('AmiriQuran', 'assets/fonts/AmiriQuran-Regular.ttf');
    _indopakFontLoaded = await _loadFont(
        'IndoPakQuran', 'assets/fonts/IndoPakQuran-Regular.ttf');
    print('MUSHAF TEST: meta=[$_metaSource] '
        'indopak-pages=[$_indopakPagesSource] '
        'indopak-text-available=${repo.indopakAvailable} '
        'amiri-font=$_amiriLoaded indopak-font=$_indopakFontLoaded');
  });

  // (surah, ayah) of a zero-based global index, via the repository.
  (int, int) at(int global0) {
    final sa = QuranRepository.instance.surahAyahForGlobal(global0 + 1);
    return (sa[0], sa[1]);
  }

  group('Madani layout (604 pages)', () {
    test('page anchors match the reference screenshots', () {
      final m = MushafData.instance;
      final madani = m.madani;
      // Page 1 = Al-Fatihah complete (globals 0..6).
      var r = m.pageRange(1, madani);
      expect((r.start, r.end), (0, 7));
      expect(at(r.start), (1, 1));
      expect(at(r.end - 1), (1, 7));
      // Page 2 = 2:1–2:5 (globals 7..11).
      r = m.pageRange(2, madani);
      expect((r.start, r.end), (7, 12));
      expect(at(r.start), (2, 1));
      expect(at(r.end - 1), (2, 5));
      // Page 3 = 2:6–2:16 (globals 12..22).
      r = m.pageRange(3, madani);
      expect((r.start, r.end), (12, 23));
      expect(at(r.start), (2, 6));
      expect(at(r.end - 1), (2, 16));
    });

    test('juz first-page mapping', () {
      final m = MushafData.instance;
      final madani = m.madani;
      expect(m.pageOfJuz(1, madani), 1);
      // Strictly increasing, inside 1..604.
      var prev = 0;
      for (var j = 1; j <= 30; j++) {
        final p = m.pageOfJuz(j, madani);
        expect(p, greaterThan(prev), reason: 'juz $j first page');
        expect(p, inInclusiveRange(1, 604));
        prev = p;
      }
      // Juz 30 starts at global 5672 — its page, counted independently
      // from the raw page starts (NOT the 571 the brief guessed at).
      final expected =
          madani.pageStarts.where((s) => s <= 5672).length;
      expect(m.pageOfJuz(30, madani), expected);
      expect(expected, 582);
      // The meta's juz starts agree with juz_data's [surah, ayah] starts.
      final repo = QuranRepository.instance;
      for (var j = 0; j < 30; j++) {
        final info = juzList[j];
        expect(
            repo.globalIndexOf(info.startSurah, info.startAyah) - 1,
            m.juzStarts[j],
            reason: 'juz ${j + 1} start');
      }
    });

    test('all 604 pages cover all 6,236 ayahs exactly once', () {
      final m = MushafData.instance;
      final madani = m.madani;
      var total = 0;
      var prevEnd = 0;
      for (var p = 1; p <= 604; p++) {
        final r = m.pageRange(p, madani);
        expect(r.start, prevEnd, reason: 'page $p must follow page ${p - 1}');
        expect(r.end, greaterThan(r.start));
        total += r.end - r.start;
        prevEnd = r.end;
      }
      expect(total, 6236);
      expect(prevEnd, 6236);
    });

    test('hizbOfPage sanity', () {
      final m = MushafData.instance;
      final madani = m.madani;
      expect(m.hizbOfPage(1, madani), 1);
      expect(m.hizbOfPage(604, madani), 60);
      var prev = 0;
      for (var p = 1; p <= 604; p++) {
        final h = m.hizbOfPage(p, madani);
        expect(h, inInclusiveRange(1, 60));
        expect(h, greaterThanOrEqualTo(prev));
        prev = h;
      }
    });
  });

  group('IndoPak layout (610 pages)', () {
    test('page anchors', () {
      final m = MushafData.instance;
      expect(m.indopakAvailable, isTrue,
          reason: 'quran_indopak_pages.json must load for this test');
      final indopak = m.indopak!;
      expect(indopak.totalPages, 610);
      // Page 1 = Al-Fatihah complete.
      var r = m.pageRange(1, indopak);
      expect(at(r.start), (1, 1));
      expect(at(r.end - 1), (1, 7));
      // 2:255 (Ayat al-Kursi) is on p.42 — same page as Madani here.
      expect(m.pageOf(2, 255, indopak), 42);
      // 67:1 opens p.562.
      expect(m.pageOf(67, 1, indopak), 562);
      expect(m.firstAyahOfPage(562, indopak), (67, 1));
      // 78:1 (juz 30) opens p.586.
      expect(m.pageOf(78, 1, indopak), 586);
      expect(m.pageOfJuz(30, indopak), 586);
      // Last page 610 = 113:1–114:6.
      r = m.pageRange(610, indopak);
      expect(at(r.start), (113, 1));
      expect(at(r.end - 1), (114, 6));
    });

    test('all 610 pages cover all 6,236 ayahs exactly once', () {
      final m = MushafData.instance;
      expect(m.indopakAvailable, isTrue);
      final indopak = m.indopak!;
      var total = 0;
      var prevEnd = 0;
      for (var p = 1; p <= 610; p++) {
        final r = m.pageRange(p, indopak);
        expect(r.start, prevEnd, reason: 'page $p must follow page ${p - 1}');
        expect(r.end, greaterThan(r.start));
        total += r.end - r.start;
        prevEnd = r.end;
      }
      expect(total, 6236);
      expect(prevEnd, 6236);
    });
  });

  test('style switch: the same ayah maps to the right page per layout', () {
    final m = MushafData.instance;
    expect(m.indopakAvailable, isTrue);
    final madani = m.madani;
    final indopak = m.indopak!;
    // 78:1 is where the layouts visibly diverge: Madani p.582,
    // IndoPak p.586 (and juz 30 follows it).
    expect(m.pageOf(78, 1, madani), 582);
    expect(m.pageOf(78, 1, indopak), 586);
    expect(m.pageOfJuz(30, madani), 582);
    expect(m.pageOfJuz(30, indopak), 586);
    // layoutFor resolves the style name, with Madani as the fallback.
    expect(identical(m.layoutFor('madani'), madani), isTrue);
    expect(identical(m.layoutFor('indopak'), indopak), isTrue);
    expect(identical(m.layoutFor('anything-else'), madani), isTrue);
    // The active layout follows appState.mushafStyle (restored after).
    final prev = appState.mushafStyle;
    try {
      appState.mushafStyle = 'indopak';
      expect(m.activeLayout.name, 'indopak');
      expect(m.totalPages, 610);
      appState.mushafStyle = 'madani';
      expect(m.activeLayout.name, 'madani');
      expect(m.totalPages, 604);
    } finally {
      appState.mushafStyle = prev;
    }
  });

  test('hasBasmalaHeader', () {
    expect(hasBasmalaHeader(1), isFalse); // Basmala IS ayah 1
    expect(hasBasmalaHeader(9), isFalse); // no Basmala at all
    expect(hasBasmalaHeader(2), isTrue);
    expect(hasBasmalaHeader(114), isTrue);
    for (var s = 2; s <= 114; s++) {
      if (s != 9) expect(hasBasmalaHeader(s), isTrue, reason: 'surah $s');
    }
  });

  test('toArabicIndic', () {
    expect(toArabicIndic(0), '٠');
    expect(toArabicIndic(7), '٧');
    expect(toArabicIndic(78), '٧٨');
    expect(toArabicIndic(114), '١١٤');
    expect(toArabicIndic(286), '٢٨٦');
  });

  test('page chunks: banners at surah starts, Basmala rules', () {
    final m = MushafData.instance;
    final madani = m.madani;
    // Page 1: one chunk, Al-Fatihah banner, NO separate Basmala line
    // (the Basmala is ayah 1, with its own medallion).
    var chunks = mushafPageChunks(1, madani);
    expect(chunks.length, 1);
    expect(chunks[0].bannerSurah, 1);
    expect(chunks[0].hasBasmala, isFalse);
    expect(chunks[0].ayahs.length, 7);
    // Page 2: one chunk, Al-Baqarah banner + Basmala line.
    chunks = mushafPageChunks(2, madani);
    expect(chunks.length, 1);
    expect(chunks[0].bannerSurah, 2);
    expect(chunks[0].hasBasmala, isTrue);
    expect(chunks[0].ayahs.length, 5);
    // Page 3: one chunk, continues surah 2 — no banner at all.
    chunks = mushafPageChunks(3, madani);
    expect(chunks.length, 1);
    expect(chunks[0].bannerSurah, isNull);
    expect(chunks[0].ayahs.length, 11);
    // Page 106: a surah starts mid-page (5:1) — two chunks, the second
    // opening with surah 5's banner + Basmala.
    chunks = mushafPageChunks(106, madani);
    expect(chunks.length, 2);
    expect(chunks[1].bannerSurah, 5);
    expect(chunks[1].hasBasmala, isTrue);
    expect(chunks[1].ayahs.first, (5, 1));
    // Last Madani page: three short surahs, three banners.
    chunks = mushafPageChunks(604, madani);
    expect(chunks.length, 3);
    expect(chunks.map((c) => c.bannerSurah).toList(), [112, 113, 114]);
    expect(chunks.every((c) => c.hasBasmala), isTrue);
    // Last IndoPak page: two surahs, two banners.
    expect(m.indopakAvailable, isTrue);
    chunks = mushafPageChunks(610, m.indopak!);
    expect(chunks.length, 2);
    expect(chunks.map((c) => c.bannerSurah).toList(), [113, 114]);
  });

  test('measurement uses the real Quran fonts', () {
    // The Basmala laid out in AmiriQuran must measure differently from
    // the same string in an unknown family (which falls back to the
    // test font) — otherwise the fit numbers below would be meaningless.
    double width(String family) {
      final painter = TextPainter(
        text: TextSpan(
          text: QuranRepository.instance.bismillah,
          style: TextStyle(fontFamily: family, fontSize: 30),
        ),
        textDirection: TextDirection.rtl,
      );
      painter.layout(maxWidth: 1000);
      return painter.width;
    }

    final amiri = width('AmiriQuran');
    final fallback = width('DefinitelyNotAFont');
    print('MUSHAF TEST: basmala width AmiriQuran=$amiri '
        'fallback=$fallback (amiri loaded: $_amiriLoaded)');
    if (_amiriLoaded) {
      expect(amiri, isNot(fallback),
          reason: 'AmiriQuran must measure differently from the fallback');
    }
    final indopak = width('IndoPakQuran');
    print('MUSHAF TEST: basmala width IndoPakQuran=$indopak '
        '(indopak font loaded: $_indopakFontLoaded)');
    if (_indopakFontLoaded) {
      expect(indopak, isNot(fallback),
          reason: 'IndoPakQuran must measure differently from the fallback');
    }
  });

  /// Runs the fit search over every page of [layout] at the assumed
  /// 390x844 phone size and prints the fit-vs-scroll report. Returns
  /// (fitCount, scrollCount, scrollPages). Uses the screen's own
  /// [fitMushafPage], so the counts are the counts the screen produces.
  (int, int, List<int>) measureFit(
      String label, MushafLayout layout, String fontFamily) {
    const width = kMushafTestScreenWidth - 2 * kMushafPagePadding;
    const height = kMushafTestScreenHeight -
        kMushafTestSafeTop -
        kMushafTopBarHeight -
        kMushafLabelHeight -
        kMushafBottomBarHeight -
        2 * kMushafPageVerticalPadding;
    var fitCount = 0;
    final scrollPages = <int>[];
    final histogram = <int, int>{};
    for (var page = 1; page <= layout.totalPages; page++) {
      final fit = fitMushafPage(page,
          maxWidth: width,
          maxHeight: height,
          fontFamily: fontFamily,
          layout: layout);
      if (fit.scrolls) {
        scrollPages.add(page);
      } else {
        fitCount++;
      }
      final size = fit.fontSize.round();
      histogram[size] = (histogram[size] ?? 0) + 1;
    }
    final sizes = histogram.keys.toList()..sort();
    print('MUSHAF FIT [$label] phone ${kMushafTestScreenWidth}x'
        '$kMushafTestScreenHeight content ${width}x$height '
        'font $fontFamily: ${layout.totalPages} pages, '
        '$fitCount fit, ${scrollPages.length} scroll');
    print('MUSHAF FIT [$label] font-size histogram (size: pages): '
        '{${sizes.map((s) => '$s: ${histogram[s]}').join(', ')}}');
    if (scrollPages.isNotEmpty) {
      print('MUSHAF FIT [$label] scroll pages: $scrollPages');
    }
    return (fitCount, scrollPages.length, scrollPages);
  }

  test('page-fit measurement: Madani layout at 390x844',
      timeout: const Timeout(Duration(minutes: 10)), () {
    final m = MushafData.instance;
    final (fit, scroll, _) =
        measureFit('madani', m.madani, 'AmiriQuran');
    expect(fit + scroll, 604);
    // The count is the deliverable (printed above); scrolling is a
    // designed fallback, not a failure — but every page must resolve.
    expect(fit, greaterThan(0));
  });

  test('page-fit measurement: IndoPak layout at 390x844',
      timeout: const Timeout(Duration(minutes: 10)), () {
    final m = MushafData.instance;
    expect(m.indopakAvailable, isTrue);
    // The IndoPak text + font only apply when the style is IndoPak.
    final prev = appState.mushafStyle;
    try {
      appState.mushafStyle = 'indopak';
      final repo = QuranRepository.instance;
      if (!repo.indopakAvailable) {
        print('MUSHAF FIT [indopak]: WARNING — IndoPak TEXT asset not '
            'loaded, measuring the IndoPak pagination with Madani text');
      }
      final (fit, scroll, _) = measureFit(
          'indopak', m.indopak!, repo.arabicFontFamily);
      expect(fit + scroll, 610);
      expect(fit, greaterThan(0));
    } finally {
      appState.mushafStyle = prev;
    }
  });

  group('MushafScreen smoke tests', () {
    Future<void> pumpMushaf(WidgetTester tester, int page) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: qubaLightTheme(),
          home: MushafScreen(initialPage: page),
        ),
      );
      await tester.pumpAndSettle();
    }

    // NOTE: this Flutter version's PageView.builder builds ONLY the
    // current page (verified with a bare-PageView diagnostic in both
    // RTL and LTR — neighbours are not pre-built), so every count
    // below covers the current page alone.
    testWidgets('page 1 (Madani): banner, medallions, bottom bar',
        (tester) async {
      await pumpMushaf(tester, 1);
      final m = MushafData.instance;
      final madani = m.madani;
      final medallions = m.pageAyahs(1, madani).length; // 7
      final banners = mushafPageChunks(1, madani)
          .where((c) => c.bannerSurah != null)
          .length; // 1
      expect(find.byType(AyahMedallion), findsNWidgets(medallions));
      expect(find.byType(SurahBanner), findsNWidgets(banners));
      // Top-bar title + the page's grey label (bundle spelling).
      final name = QuranRepository.instance.surah(1).nameEnglish;
      expect(find.text(name), findsNWidgets(2));
      // Bottom bar: page number 1 (tappable) + Hizb 1.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Hizb 1'), findsOneWidget);
    });

    testWidgets('page 3 (Madani): dense page fits without overflow',
        (tester) async {
      await pumpMushaf(tester, 3);
      final m = MushafData.instance;
      final madani = m.madani;
      final medallions = m.pageAyahs(3, madani).length; // 11
      final banners = mushafPageChunks(3, madani)
          .where((c) => c.bannerSurah != null)
          .length; // 0 — continues surah 2
      expect(find.byType(AyahMedallion), findsNWidgets(medallions));
      expect(find.byType(SurahBanner), findsNWidgets(banners));
      expect(find.text('3'), findsOneWidget);
      // Top-bar title + the page's grey label (bundle spelling).
      final name = QuranRepository.instance.surah(2).nameEnglish;
      expect(find.text(name), findsNWidgets(2));
    });

    testWidgets('page 586 (IndoPak): juz 30 opens in the IndoPak layout',
        (tester) async {
      final m = MushafData.instance;
      expect(m.indopakAvailable, isTrue);
      final prev = appState.mushafStyle;
      appState.mushafStyle = 'indopak';
      try {
        await pumpMushaf(tester, 586);
        final indopak = m.indopak!;
        final medallions = m.pageAyahs(586, indopak).length; // 27
        final banners = mushafPageChunks(586, indopak)
            .where((c) => c.bannerSurah != null)
            .length; // 1 — surah 78
        expect(find.byType(AyahMedallion), findsNWidgets(medallions));
        expect(find.byType(SurahBanner), findsNWidgets(banners));
        expect(find.text('586'), findsOneWidget);
        // Top-bar title + the page's grey label (bundle spelling).
        final name = QuranRepository.instance.surah(78).nameEnglish;
        expect(find.text(name), findsNWidgets(2));
      } finally {
        appState.mushafStyle = prev;
      }
    });
  });
}
