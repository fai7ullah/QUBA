import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quba/app_state.dart';
import 'package:quba/audio.dart';
import 'package:quba/data.dart';
import 'package:quba/main.dart';
import 'package:quba/mushaf_data.dart';
import 'package:quba/screens/names_screen.dart';
import 'package:quba/screens/quran_screen.dart';
import 'package:quba/screens/reader_screen.dart';
import 'package:quba/theme.dart';
import 'package:quba/translation_data.dart';
import 'package:quba/widgets/global_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app-wide bottom player: visible on every screen while a
/// session is active, gone when closed; plus the 99 Names grid at
/// 320px and the bundled name-audio assets.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await appState.load();
    await QuranRepository.instance.load();
    await TranslationRepository.instance.load();
    await MushafData.instance.load();
    appState.onboardingDone = true;
  });

  void clearSession() {
    final audio = AudioService.instance;
    audio.currentSurah.value = null;
    audio.currentAyah.value = null;
    audio.currentName.value = null;
  }

  tearDown(clearSession);

  Widget harness(Widget home) {
    return MaterialApp(
      theme: qubaLightTheme(),
      navigatorKey: QubaApp.navigatorKey,
      navigatorObservers: [QubaApp.routeObserver],
      builder: (context, child) => QubaPlayerOverlay(
        routeObserver: QubaApp.routeObserver,
        navigatorKey: QubaApp.navigatorKey,
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    );
  }

  void setSize(WidgetTester tester, double width, double height) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('player follows across pushed screens; close hides it', (
    tester,
  ) async {
    setSize(tester, 390, 844);
    final audio = AudioService.instance;
    audio.currentSurah.value = 36;
    audio.currentAyah.value = 1;

    await tester.pumpWidget(
      harness(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const Scaffold(body: Center(child: Text('pushed'))),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Yaseen: 1'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('pushed'), findsOneWidget);
    // Still visible on the pushed screen.
    expect(find.text('Yaseen: 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    // stop() is async (platform player); let it settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(audio.currentSurah.value, isNull);
    expect(audio.currentAyah.value, isNull);
    expect(find.text('Yaseen: 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  Future<void> pumpFrames(WidgetTester tester, {int count = 12}) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  void suppressListTileErrors() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('ListTile background')) {
        return;
      }
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);
  }

  testWidgets('player stays after leaving the reader in the real app', (
    tester,
  ) async {
    suppressListTileErrors();
    setSize(tester, 390, 844);
    final audio = AudioService.instance;

    await tester.pumpWidget(const QubaApp());
    await pumpFrames(tester);

    // Real navigation: Quran tab -> first surah -> reader.
    await tester.tap(find.text('Quran'));
    await pumpFrames(tester);
    final firstName = QuranRepository.instance.surah(1).nameEnglish;
    final firstSurah = find.descendant(
      of: find.byType(QuranScreen),
      matching: find.text(firstName),
    );
    expect(firstSurah, findsWidgets);
    await tester.tap(firstSurah.last);
    await pumpFrames(tester);
    expect(find.byType(ReaderScreen), findsOneWidget);

    // A recitation session started from the reader.
    audio.currentSurah.value = 1;
    audio.currentAyah.value = 1;
    await tester.pump();
    expect(find.text('$firstName: 1'), findsOneWidget);

    // Leave the Quran pages back to the tab shell.
    Navigator.of(tester.element(find.byType(ReaderScreen))).pop();
    await pumpFrames(tester);
    expect(find.byType(ReaderScreen), findsNothing);
    expect(audio.currentSurah.value, 1);
    expect(audio.currentAyah.value, 1);
    expect(find.text('$firstName: 1'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Still visible on a pushed non-Quran screen.
    QubaApp.navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: Text('extras'))),
      ),
    );
    await pumpFrames(tester);
    expect(find.text('extras'), findsOneWidget);
    expect(find.text('$firstName: 1'), findsOneWidget);

    // Close stops the session and hides the player.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(audio.currentSurah.value, isNull);
    expect(audio.currentAyah.value, isNull);
    expect(find.text('$firstName: 1'), findsNothing);
  });

  testWidgets('player returns after options sheet closes, then reader pops', (
    tester,
  ) async {
    suppressListTileErrors();
    setSize(tester, 390, 844);
    final audio = AudioService.instance;

    await tester.pumpWidget(const QubaApp());
    await pumpFrames(tester);
    await tester.tap(find.text('Quran'));
    await pumpFrames(tester);
    final firstName = QuranRepository.instance.surah(1).nameEnglish;
    await tester.tap(find.text(firstName).last);
    await pumpFrames(tester);
    expect(find.byType(ReaderScreen), findsOneWidget);

    audio.currentSurah.value = 1;
    audio.currentAyah.value = 1;
    await tester.pump();
    expect(find.text('$firstName: 1'), findsOneWidget);

    // Open the player options sheet: the player hides under the modal.
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await pumpFrames(tester);
    expect(find.text('$firstName: 1'), findsNothing);

    // Dismiss the sheet (pop the top route).
    QubaApp.navigatorKey.currentState!.pop();
    await pumpFrames(tester);
    expect(find.text('$firstName: 1'), findsOneWidget);

    Navigator.of(tester.element(find.byType(ReaderScreen))).pop();
    await pumpFrames(tester);
    expect(find.byType(ReaderScreen), findsNothing);
    expect(audio.hasActiveSession, isTrue);
    expect(find.text('$firstName: 1'), findsOneWidget);
  });

  testWidgets('switching surah in the reader keeps the session playing', (
    tester,
  ) async {
    suppressListTileErrors();
    setSize(tester, 390, 844);
    final audio = AudioService.instance;

    await tester.pumpWidget(const QubaApp());
    await pumpFrames(tester);
    await tester.tap(find.text('Quran'));
    await pumpFrames(tester);
    final firstName = QuranRepository.instance.surah(1).nameEnglish;
    await tester.tap(find.text(firstName).last);
    await pumpFrames(tester);
    expect(find.byType(ReaderScreen), findsOneWidget);

    audio.currentSurah.value = 1;
    audio.currentAyah.value = 1;
    await tester.pump();
    expect(find.text('$firstName: 1'), findsOneWidget);

    // Switch to another surah through the reader's surah picker.
    await tester.tap(find.text(firstName).first);
    await pumpFrames(tester);
    final secondName = QuranRepository.instance.surah(2).nameEnglish;
    await tester.tap(find.text(secondName).last);
    await pumpFrames(tester);

    // Playback of the first surah continues; the player still shows it.
    expect(audio.currentSurah.value, 1);
    expect(audio.currentAyah.value, 1);
    expect(find.text('$firstName: 1'), findsOneWidget);

    Navigator.of(tester.element(find.byType(ReaderScreen))).pop();
    await pumpFrames(tester);
    expect(find.text('$firstName: 1'), findsOneWidget);
  });

  testWidgets('name session shows the name; close hides it', (tester) async {
    setSize(tester, 390, 844);
    final audio = AudioService.instance;
    audio.currentName.value = 2; // Ar-Rahman

    await tester.pumpWidget(harness(const Scaffold(body: SizedBox())));
    await tester.pump();
    expect(find.text('Ar-Rahman'), findsOneWidget);
    expect(find.byIcon(Icons.skip_next_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(audio.currentName.value, isNull);
    expect(find.text('Ar-Rahman'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('99 Names grid fits 320px with equal cards and play buttons', (
    tester,
  ) async {
    setSize(tester, 320, 844);
    await tester.pumpWidget(harness(const NamesScreen()));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);

    final first = tester.getSize(find.byKey(const ValueKey('name-card-1')));
    final second = tester.getSize(find.byKey(const ValueKey('name-card-2')));
    final third = tester.getSize(find.byKey(const ValueKey('name-card-3')));
    expect(first, second);
    expect(second, third);
    expect(first.height, 124);
  });

  testWidgets('Extras opens the redesigned 99 Names page at 320px', (
    tester,
  ) async {
    suppressListTileErrors();
    setSize(tester, 320, 844);
    final audio = AudioService.instance;

    await tester.pumpWidget(const QubaApp());
    await pumpFrames(tester);
    await tester.tap(find.text('Extras'));
    await pumpFrames(tester);
    await tester.tap(find.text('99 Names'));
    await pumpFrames(tester);

    expect(find.byType(NamesScreen), findsOneWidget);
    expect(find.text('99 Names of Allah'), findsOneWidget);
    expect(find.text('Asma ul-Husna'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    final first = tester.getSize(find.byKey(const Key('name-card-1')));
    final second = tester.getSize(find.byKey(const Key('name-card-2')));
    final third = tester.getSize(find.byKey(const Key('name-card-3')));
    expect(first, second);
    expect(second, third);
    expect(first.height, 124);
    expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);

    // A name session plays through the bottom player and survives
    // leaving the Names page.
    audio.currentName.value = 1;
    await tester.pump();
    expect(find.text('Allah'), findsWidgets);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    Navigator.of(tester.element(find.byType(NamesScreen))).pop();
    await pumpFrames(tester);
    expect(find.byType(NamesScreen), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(audio.currentName.value, 1);
  });

  test('all 99 name clips are bundled with a licence note', () {
    for (var n = 1; n <= 99; n++) {
      final path = AudioService.nameAssetPath(n);
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      expect(file.lengthSync(), greaterThan(1000), reason: path);
    }
    final licence = File('assets/names/LICENSE.txt').readAsStringSync();
    expect(licence, contains('CC BY-SA 4.0'));
    expect(licence, contains('CC BY-SA 3.0'));
    expect(licence, contains('Mohammed Sadiq'));
    expect(licence, contains('Hakeem.gadi'));
  });
}
