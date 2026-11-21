import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quba/app_state.dart';
import 'package:quba/audio.dart';
import 'package:quba/content.dart';
import 'package:quba/data.dart';
import 'package:quba/hadith/hadith_repo.dart';
import 'package:quba/hadith/hadith_screen.dart';
import 'package:quba/i18n.dart';
import 'package:quba/mushaf_data.dart';
import 'package:quba/reciters.dart';
import 'package:quba/screens/calendar_screen.dart';
import 'package:quba/screens/duas_screen.dart';
import 'package:quba/screens/extras_screen.dart';
import 'package:quba/screens/home_screen.dart';
import 'package:quba/screens/khatma_screen.dart';
import 'package:quba/screens/mushaf_screen.dart';
import 'package:quba/screens/names_screen.dart';
import 'package:quba/screens/notes_screen.dart';
import 'package:quba/screens/onboarding_screen.dart';
import 'package:quba/screens/prayer_screen.dart';
import 'package:quba/screens/qibla_screen.dart';
import 'package:quba/screens/quran_screen.dart';
import 'package:quba/screens/ramadan_screen.dart';
import 'package:quba/screens/reader_screen.dart';
import 'package:quba/screens/search_screen.dart';
import 'package:quba/screens/settings_screen.dart';
import 'package:quba/screens/tasbih_screen.dart';
import 'package:quba/screens/test_mode_screen.dart';
import 'package:quba/screens/widget_screen.dart';
import 'package:quba/tafsir/tafsir_screen.dart';
import 'package:quba/theme.dart';
import 'package:quba/translation_data.dart';
import 'package:quba/wordbyword/wordbyword_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 2 squeeze / vertical-text audit (the user's #1 quality bar:
/// "I don't want anything wrong like the texts in vertical like that
/// those we just fixed. Everything should be perfect. Check.").
///
/// EVERY screen — old and new — is pumped at narrow phone widths
/// (360px and 320px) in English and Arabic (the longest labels),
/// scrolled top to bottom, and the test fails if any RenderFlex or
/// RenderParagraph overflows — Flutter reports overflows as errors,
/// so a passing run means no squeezed, clipped or vertically-wrapped
/// text anywhere on these screens.
///
/// The tightest screens (Home, Prayer, Quran, Settings, Extras) are
/// additionally pumped at 320px in all five UI languages, and the
/// stateful spots get their own tests: the reader mini-player (with
/// the longest reciter short name), the player-options sheet with a
/// repeat range, the text-settings sheet, the surah picker, the
/// mushaf jump dialog, the Juz list, the test-mode quiz + summary,
/// onboarding's four steps, a Khatma plan, a note row, search
/// results, and the Hadith chapter + hadith lists.
///
/// Harness note: screens are settled with BOUNDED pumping
/// ([pumpFrames]), never pumpAndSettle — Home and Ramadan tick every
/// second, so pumpAndSettle never returns on them (the old harness
/// hung the whole file).
///
/// Fonts note: `flutter test` renders with the Ahem test font (every
/// glyph a full-em square), which makes Latin text ~70% wider than
/// the real Roboto and turns tight-but-fine rows into false
/// overflows. [_loadTestFonts] registers real fonts first — Noto Sans
/// (metrically near-identical to Roboto) under the theme's 'Roboto'
/// family, plus the app's own AmiriQuran/IndoPakQuran from its
/// assets — so the measurements below are the measurements the user
/// sees on his phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loadTestFonts() async {
    final regular =
        File('/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf');
    final bold = File('/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf');
    if (regular.existsSync() && bold.existsSync()) {
      final roboto = FontLoader('Roboto')
        ..addFont(Future.value(
            ByteData.sublistView(regular.readAsBytesSync())))
        ..addFont(
            Future.value(ByteData.sublistView(bold.readAsBytesSync())));
      await roboto.load();
    } else {
      // No system sans available: measurements fall back to Ahem and
      // tight rows may false-fail (see the fonts note above).
      debugPrint('QUBA squeeze audit: Noto Sans not found; '
          'measuring with the Ahem test font.');
    }
    final amiri = FontLoader('AmiriQuran')
      ..addFont(rootBundle.load('assets/fonts/AmiriQuran-Regular.ttf'));
    await amiri.load();
    final indopak = FontLoader('IndoPakQuran')
      ..addFont(rootBundle.load('assets/fonts/IndoPakQuran-Regular.ttf'));
    await indopak.load();
  }

  setUpAll(() async {
    await loadTestFonts();
    SharedPreferences.setMockInitialValues({});
    await appState.load();
    await QuranRepository.instance.load();
    await TranslationRepository.instance.load();
    await MushafData.instance.load();
    // Pre-load Bukhari here (real async), NOT inside a testWidgets
    // body: the Hadith screen starts the same load from initState
    // inside the fake-async zone, and a load begun there can strand
    // — its platform-channel Future never completes once that test's
    // zone tears down, so a later await of the shared in-flight
    // Future hangs forever (the full-file run stalled on exactly
    // this, 2026-11-21). Loaded here, the Hadith test's loadBook is
    // an instant no-op.
    await HadithRepository.instance.loadBook('bukhari');
    // Today counts as a reading day, so the Home streak chip (and the
    // Khatma streak card) render in every Home/Khatma pump.
    appState.recordReadingDay();
  });

  /// Errors recorded while pumping + scrolling one screen, EXCLUDING
  /// the pre-existing cosmetic "ListTile background color or ink
  /// splashes may be invisible" assertion: ListTiles inside GlassCard's
  /// DecoratedBox trigger it in debug/test builds (release builds strip
  /// assertions, so users never see it — the ink splash is simply
  /// invisible on glass). That pattern ships in builds 1–12 and is not
  /// a layout defect; this audit fails on overflows, not on it.
  final errors = <FlutterErrorDetails>[];

  /// Pumps [count] frames, advancing fake time by [step] each: enough
  /// for asset loads, futures and animations to land, without waiting
  /// for periodic timers (which would hang pumpAndSettle forever).
  Future<void> pumpFrames(
    WidgetTester tester, {
    int count = 12,
    Duration step = const Duration(milliseconds: 100),
  }) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(step);
    }
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required Size size,
    required String lang,
    int frames = 12,
  }) async {
    appState.lang = lang;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    addTearDown(() => appState.lang = 'en');
    errors.clear();
    // Chain real errors to the framework's handler: it records them as
    // pending test failures (with full details). Swallowing them here
    // breaks the framework's own bookkeeping — it asserts when an
    // uncaught error arrives while its handler is bypassed.
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('ListTile background')) {
        return; // Pre-existing cosmetic assertion (see above).
      }
      errors.add(details);
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);
    await tester.pumpWidget(
      MaterialApp(
        theme: qubaLightTheme(),
        // Tab pages (Home, Prayer, Quran, Extras, Settings) have no
        // Scaffold of their own — in the app the Shell provides it.
        // The outer Scaffold here stands in for the Shell; screens
        // with their own Scaffold are unaffected by the extra
        // ancestor.
        home: Scaffold(body: screen),
      ),
    );
    await pumpFrames(tester, count: frames);
  }

  /// Scrolls through the screen's scrollables so below-fold content
  /// is built too (ListViews build lazily — an overflow below the fold
  /// only surfaces once it is on screen).
  Future<void> scrollThrough(WidgetTester tester) async {
    final scrollables = find.byType(Scrollable);
    for (var i = 0; i < scrollables.evaluate().length; i++) {
      final target = scrollables.at(i);
      // warnIfMissed: false — some Scrollables (e.g. the search
      // field's internal one) have no draggable area; a missed drag
      // is expected there, not a defect, and the warning is noise.
      for (var n = 0; n < 6; n++) {
        await tester.drag(target, const Offset(0, -400),
            warnIfMissed: false);
        await tester.pump();
      }
      // Back to the top for the next scrollable.
      for (var n = 0; n < 6; n++) {
        await tester.drag(target, const Offset(0, 400),
            warnIfMissed: false);
        await tester.pump();
      }
    }
  }

  void expectNoErrors() {
    expect(
      errors,
      isEmpty,
      reason: errors
          .map((e) => e.exceptionAsString().split('\n').first)
          .join('; '),
    );
  }

  void noopReader(int surah, int ayah) {}

  final screens = <String, Widget Function()>{
    'Home': () => HomeScreen(
          onGoTab: (_) {},
          onOpenReader: noopReader,
          onOpenFeature: (_) {},
        ),
    'Prayer': () => const PrayerScreen(),
    'Quran': () => QuranScreen(
          onOpenSurah: (_) {},
          onOpenSearch: () {},
          onOpenReader: noopReader,
          onOpenJuz: (_) {},
          onOpenSettings: () {},
        ),
    'Reader': () => const ReaderScreen(surahNumber: 2),
    'Mushaf': () => const MushafScreen(initialPage: 2),
    'Extras': () => ExtrasScreen(onOpenFeature: (_) {}),
    'Hadith': () => const HadithScreen(),
    'Tafsir': () => const TafsirScreen(surah: 2, ayah: 255),
    'WordByWord': () => const WordByWordScreen(surah: 2, ayah: 255),
    'TestMode': () => const TestModeScreen(),
    'Ramadan': () => const RamadanScreen(),
    'Widget': () => const WidgetScreen(),
    'Settings': () => SettingsScreen(onOpenFeature: (_) {}),
    'Calendar': () => const CalendarScreen(),
    'Duas': () => const DuasScreen(),
    'Names': () => const NamesScreen(),
    'Khatma': () => KhatmaScreen(onOpenReader: noopReader),
    'Qibla': () => const QiblaScreen(),
    'Tasbih': () => const TasbihScreen(),
    'Notes': () => NotesScreen(onOpenReader: noopReader),
    'Search': () => SearchScreen(onOpenReader: noopReader),
    'Onboarding': () => OnboardingScreen(onDone: () {}),
  };

  for (final entry in screens.entries) {
    for (final lang in ['en', 'ar']) {
      for (final size in [
        const Size(360, 640),
        const Size(320, 568),
      ]) {
        testWidgets(
          '${entry.key} fits at ${size.width.toInt()}px in $lang',
          (tester) async {
            await pumpScreen(tester, entry.value(),
                size: size, lang: lang);
            await scrollThrough(tester);
            // Any overflow raises a FlutterError, recorded in errors.
            // An empty list means the screen fits at this size.
            expectNoErrors();
          },
        );
      }
    }
  }

  // The tightest screens in all five languages at the narrowest width:
  // their rows hold the longest translated labels (Farsi "Use my
  // location", Pashto/Urdu "Sunrise", Urdu weekday abbreviations).
  for (final name in ['Home', 'Prayer', 'Quran', 'Settings', 'Extras']) {
    for (final lang in ['ps', 'fa', 'ur']) {
      testWidgets(
        '$name fits at 320px in $lang',
        (tester) async {
          await pumpScreen(tester, screens[name]!(),
              size: const Size(320, 568), lang: lang);
          await scrollThrough(tester);
          expectNoErrors();
        },
      );
    }
  }

  // ------------------------------------------------------------------
  // Stateful spots: states the plain pump never reaches.
  // ------------------------------------------------------------------

  /// Fakes "verse 5 of surah 2 is playing" so the mini-player (and the
  /// mushaf audio controls) render. Pure Dart state — no audio is
  /// actually played. The longest reciter short name ("Abdul Basit")
  /// is the worst case for the mini-player's squeezed column.
  void fakePlaying() {
    final audio = AudioService.instance;
    audio.currentSurah.value = 2;
    audio.currentAyah.value = 5;
    audio.currentReciter.value = reciterById('ar.abdulsamad');
    addTearDown(() {
      audio.currentSurah.value = null;
      audio.currentAyah.value = null;
      audio.currentReciter.value = reciterById(appState.reciterId);
    });
  }

  // At a normal phone width the mini-player title must show in FULL —
  // not just fit without overflowing. Surah 2 ("Al-Baqara: 5") with the
  // longest reciter short name ("Abdul Basit") is the worst case.
  testWidgets(
    'Reader mini-player shows full title at 390px',
    (tester) async {
      fakePlaying();
      await pumpScreen(tester, const ReaderScreen(surahNumber: 2),
          size: const Size(390, 844), lang: 'en');
      final title = tester.renderObject<RenderParagraph>(
          find.text('Al-Baqara: 5'));
      expect(title.didExceedMaxLines, isFalse,
          reason: 'mini-player title is truncated at 390px');
      final reciter = tester.renderObject<RenderParagraph>(
          find.text('Abdul Basit'));
      expect(reciter.didExceedMaxLines, isFalse,
          reason: 'mini-player reciter name is truncated at 390px');
      expectNoErrors();
    },
  );

  for (final lang in ['en', 'ar']) {
    testWidgets(
      'Reader mini-player fits at 320px in $lang',
      (tester) async {
        fakePlaying();
        await pumpScreen(tester, const ReaderScreen(surahNumber: 2),
            size: const Size(320, 568), lang: lang);
        await scrollThrough(tester);
        expectNoErrors();
      },
    );

    testWidgets(
      'Player options sheet fits at 320px in $lang',
      (tester) async {
        fakePlaying();
        await pumpScreen(tester, const ReaderScreen(surahNumber: 2),
            size: const Size(320, 568), lang: lang);
        // The tune button lives in the mini-player; the sheet shows
        // the repeat-range steppers only while a surah is playing.
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await pumpFrames(tester);
        await scrollThrough(tester);
        expectNoErrors();
      },
    );

    testWidgets(
      'Mushaf audio controls fit at 320px in $lang',
      (tester) async {
        fakePlaying();
        await pumpScreen(tester, const MushafScreen(initialPage: 2),
            size: const Size(320, 568), lang: lang, frames: 20);
        expectNoErrors();
      },
    );

    testWidgets(
      'Quran Juz list fits at 320px in $lang',
      (tester) async {
        await pumpScreen(
          tester,
          QuranScreen(
            onOpenSurah: (_) {},
            onOpenSearch: () {},
            onOpenReader: noopReader,
            onOpenJuz: (_) {},
            onOpenSettings: () {},
          ),
          size: const Size(320, 568),
          lang: lang,
        );
        await tester.tap(find.text(tr('juz').toUpperCase()));
        await pumpFrames(tester);
        await scrollThrough(tester);
        expectNoErrors();
      },
    );
  }

  testWidgets(
    'Reader text-settings sheet fits at 320px',
    (tester) async {
      await pumpScreen(tester, const ReaderScreen(surahNumber: 2),
          size: const Size(320, 568), lang: 'en');
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await pumpFrames(tester);
      expectNoErrors();
    },
  );

  testWidgets(
    'Reader surah picker fits at 320px',
    (tester) async {
      await pumpScreen(tester, const ReaderScreen(surahNumber: 2),
          size: const Size(320, 568), lang: 'en');
      // The surah name comes from the data (Al-Baqara), not a guess.
      await tester.tap(
          find.text(QuranRepository.instance.surah(2).nameEnglish));
      await pumpFrames(tester);
      await scrollThrough(tester);
      expectNoErrors();
    },
  );

  testWidgets(
    'Reader verse-note row fits at 320px',
    (tester) async {
      appState.setNote(2, 1, 'A note on the first verse of Al-Baqarah.');
      addTearDown(() => appState.deleteNote(2, 1));
      await pumpScreen(
        tester,
        const ReaderScreen(surahNumber: 2, initialAyah: 1),
        size: const Size(320, 568),
        lang: 'en',
      );
      await scrollThrough(tester);
      expectNoErrors();
    },
  );

  testWidgets(
    'Mushaf jump dialog fits at 320px',
    (tester) async {
      await pumpScreen(tester, const MushafScreen(initialPage: 2),
          size: const Size(320, 568), lang: 'en', frames: 20);
      // Page 2 is even: the page number sits at the bottom-left.
      // Bottom bar centre: y = 568 - 12 (page padding) - 18.
      await tester.tapAt(const Offset(41, 538));
      await pumpFrames(tester);
      expect(find.text(tr('go_to')), findsOneWidget);
      // An out-of-range page shows the error line under the field.
      await tester.enterText(find.byType(TextField), '999');
      await tester.tap(find.text(tr('go')));
      await pumpFrames(tester);
      expectNoErrors();
    },
  );

  testWidgets(
    'Quran bookmarks sheet fits at 320px',
    (tester) async {
      await pumpScreen(
        tester,
        QuranScreen(
          onOpenSurah: (_) {},
          onOpenSearch: () {},
          onOpenReader: noopReader,
          onOpenJuz: (_) {},
          onOpenSettings: () {},
        ),
        size: const Size(320, 568),
        lang: 'en',
      );
      // The header button's tooltip is 'bookmarks'; the row buttons
      // use 'bookmark'/'remove_bookmark', so the tooltip is unique.
      await tester.tap(find.byTooltip(tr('bookmarks')));
      await pumpFrames(tester);
      expectNoErrors();
    },
  );

  testWidgets(
    'Prayer log with prayed prayers fits at 320px',
    (tester) async {
      final today = DateTime.now();
      appState.togglePrayed(today, 'Fajr');
      appState.togglePrayed(today, 'Dhuhr');
      addTearDown(() {
        appState.togglePrayed(today, 'Fajr');
        appState.togglePrayed(today, 'Dhuhr');
      });
      await pumpScreen(tester, const PrayerScreen(),
          size: const Size(320, 568), lang: 'ar');
      await scrollThrough(tester);
      expectNoErrors();
    },
  );

  testWidgets(
    'Duas expanded card fits at 320px',
    (tester) async {
      await pumpScreen(tester, const DuasScreen(),
          size: const Size(320, 568), lang: 'en');
      await tester.tap(find.text(tr(duas.first.title)));
      await pumpFrames(tester);
      await scrollThrough(tester);
      expectNoErrors();
    },
  );

  testWidgets(
    'Notes with a note fits at 320px',
    (tester) async {
      appState.setNote(2, 255, 'The Throne Verse — read after every prayer.');
      addTearDown(() => appState.deleteNote(2, 255));
      await pumpScreen(tester, NotesScreen(onOpenReader: noopReader),
          size: const Size(320, 568), lang: 'en');
      await scrollThrough(tester);
      expectNoErrors();
    },
  );

  testWidgets(
    'Search results fit at 320px',
    (tester) async {
      await pumpScreen(tester, SearchScreen(onOpenReader: noopReader),
          size: const Size(320, 568), lang: 'en');
      await tester.enterText(find.byType(TextField), 'mercy');
      await pumpFrames(tester);
      await scrollThrough(tester);
      expectNoErrors();
    },
  );

  testWidgets(
    'Search results fit at 320px in Arabic',
    (tester) async {
      await pumpScreen(tester, SearchScreen(onOpenReader: noopReader),
          size: const Size(320, 568), lang: 'ar');
      await tester.enterText(find.byType(TextField), 'الرحمن');
      await pumpFrames(tester);
      await scrollThrough(tester);
      expectNoErrors();
    },
  );

  testWidgets(
    'Khatma plan fits at 320px',
    (tester) async {
      appState.setKhatma(30, 0);
      addTearDown(appState.clearKhatma);
      await pumpScreen(tester, KhatmaScreen(onOpenReader: noopReader),
          size: const Size(320, 568), lang: 'ar');
      await scrollThrough(tester);
      expectNoErrors();
    },
  );

  testWidgets(
    'Onboarding all four steps fit at 320px',
    (tester) async {
      await pumpScreen(tester, OnboardingScreen(onDone: () {}),
          size: const Size(320, 568), lang: 'ar');
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await pumpFrames(tester, count: 8);
      }
      expect(find.text(tr('onboard_done')), findsOneWidget);
      expectNoErrors();
    },
  );

  testWidgets(
    'TestMode quiz and summary fit at 320px',
    (tester) async {
      await pumpScreen(tester, const TestModeScreen(),
          size: const Size(320, 568), lang: 'en');
      await tester.tap(find.text(tr('test_start')));
      await pumpFrames(tester);
      // Tap a masked word, then "Knew it" — the two-button row.
      final hidden = find.text('• • •');
      if (hidden.evaluate().isNotEmpty) {
        await tester.tap(hidden.first);
        await pumpFrames(tester, count: 4);
        await tester.tap(find.text(tr('test_knew_it')));
        await pumpFrames(tester, count: 4);
      }
      // Step through all 7 ayahs of Al-Fatiha to the summary.
      for (var i = 0; i < 7; i++) {
        final next = find.text(tr('test_next'));
        if (next.evaluate().isEmpty) break;
        await tester.tap(next);
        await pumpFrames(tester, count: 4);
      }
      expect(find.text(tr('test_finished')), findsOneWidget);
      expectNoErrors();
    },
  );

  testWidgets(
    'TestMode next-ayah flow fits at 320px',
    (tester) async {
      await pumpScreen(tester, const TestModeScreen(),
          size: const Size(320, 568), lang: 'en');
      await tester.tap(find.text(tr('test_mode_next_ayah')));
      await pumpFrames(tester, count: 4);
      await tester.tap(find.text(tr('test_start')));
      await pumpFrames(tester);
      await tester.tap(find.text(tr('test_show_answer')));
      await pumpFrames(tester, count: 4);
      await tester.tap(find.text(tr('test_correct')));
      await pumpFrames(tester, count: 4);
      expectNoErrors();
    },
  );

  testWidgets(
    'Hadith chapters and hadith list fit at 320px',
    (tester) async {
      final repo = HadithRepository.instance;
      // runAsync is REQUIRED here: loadBook awaits a platform-channel
      // asset load, and a bare await inside testWidgets never
      // completes — the fake-async zone only advances on pump, so the
      // test hung for the full 10-minute timeout (caught 2026-11-21).
      await tester.runAsync(() => repo.loadBook('bukhari'));
      await pumpScreen(tester, const HadithScreen(),
          size: const Size(320, 568), lang: 'en');
      final book = repo.book('bukhari')!;
      await tester.tap(find.text(book.titleEn));
      await pumpFrames(tester);
      await scrollThrough(tester);
      final chapter = book.chapters.first;
      final chapterTitle = chapter.titleEn.isNotEmpty
          ? chapter.titleEn
          : trf('hadith_chapter_n', {'n': chapter.number});
      await tester.tap(find.text(chapterTitle));
      await pumpFrames(tester);
      await scrollThrough(tester);
      expectNoErrors();
    },
  );
}
