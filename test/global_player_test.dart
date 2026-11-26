import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quba/audio.dart';
import 'package:quba/data.dart';
import 'package:quba/main.dart';
import 'package:quba/screens/names_screen.dart';
import 'package:quba/theme.dart';
import 'package:quba/widgets/global_player.dart';

/// The app-wide bottom player: visible on every screen while a
/// session is active, gone when closed; plus the 99 Names grid at
/// 320px and the bundled name-audio assets.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await QuranRepository.instance.load();
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
    expect(first.height, 132);
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
