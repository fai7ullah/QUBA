import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quba/app_state.dart';
import 'package:quba/data.dart';
import 'package:quba/main.dart';
import 'package:quba/mushaf_data.dart';
import 'package:quba/notifications.dart';
import 'package:quba/screens/extras_screen.dart';
import 'package:quba/screens/home_screen.dart';
import 'package:quba/screens/prayer_screen.dart';
import 'package:quba/screens/quran_screen.dart';
import 'package:quba/screens/settings_screen.dart';
import 'package:quba/translation_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests for the tab-scroll bug Umar found on his phone in
/// build 14 (2026-11-21): in the Settings tab, scroll down and you
/// CANNOT scroll back up — "it just tucks there".
///
/// ROOT CAUSE (as far as it could be established without a device):
/// all five tab ListViews were primary, so all five attached their
/// ScrollPositions to the route's single PrimaryScrollController
/// (verified: 5 positions on one controller). That is outside the
/// designed pattern (one primary scrollable per route). The bug did
/// NOT reproduce in widget tests — drags, flings, the notification
/// card's height change, the Home 1-second ticker and appState
/// rebuild storms all scrolled up fine here — so the exact on-device
/// trigger is unproven; the fix removes the one confirmed structural
/// anomaly in the scroll path (every tab ListView is now
/// `primary: false` with its own controller) and the on-device
/// verdict is the real test.
///
/// Test A pumps the REAL Shell (all five tabs in the IndexedStack).
/// Test B pumps SettingsScreen alone (the squeeze-audit harness
/// shape). Test E asserts no tab shares the route controller. Test H
/// scrolls EVERY tab down and back up (the class audit).
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

  // Filter the pre-existing cosmetic "ListTile background color or ink
  // splashes may be invisible" assertion (same filter as the squeeze
  // audit): ListTiles inside GlassCard's DecoratedBox trigger it in
  // debug/test builds; release builds strip assertions, so users never
  // see it. It is not a scroll defect.
  // Installed inside each test body (not setUp): the test binding
  // re-installs its own FlutterError.onError when the test starts,
  // which would clobber a setUp-installed filter.
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

  Future<void> pumpFrames(
    WidgetTester tester, {
    int count = 12,
    Duration step = const Duration(milliseconds: 100),
  }) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(step);
    }
  }

  /// The Settings tab's ListView Scrollable, and its current offset.
  ScrollableState settingsScrollable(WidgetTester tester) {
    final found = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(Scrollable),
    );
    expect(found, findsOneWidget,
        reason: 'SettingsScreen should hold exactly one Scrollable');
    return tester.state<ScrollableState>(found);
  }

  double settingsOffset(WidgetTester tester) =>
      settingsScrollable(tester).position.pixels;

  double settingsMaxExtent(WidgetTester tester) =>
      settingsScrollable(tester).position.maxScrollExtent;

  testWidgets('A: Settings scrolls back up inside the real Shell',
      (tester) async {
    suppressListTileErrors();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const QubaApp());
    await pumpFrames(tester);

    // Go to the Settings tab (bottom nav label).
    await tester.tap(find.text('Settings'));
    await pumpFrames(tester);

    final maxExtent = settingsMaxExtent(tester);
    expect(maxExtent, greaterThan(0),
        reason: 'Settings content must overflow the viewport');
    expect(settingsOffset(tester), 0);

    // Scroll DOWN (drag up) to the bottom. Settings content height
    // varies by version, so drag until near the bottom is reached.
    for (var i = 0; i < 12; i++) {
      await tester.drag(
        find.descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(ListView),
        ),
        const Offset(0, -500),
      );
      await tester.pump();
      if (settingsOffset(tester) > settingsMaxExtent(tester) * 0.8) break;
    }
    final atBottom = settingsOffset(tester);
    final maxAtBottom = settingsMaxExtent(tester);
    // ignore: avoid_print
    print('A: after scrolling down: offset=$atBottom max=$maxAtBottom');
    expect(atBottom, greaterThan(maxAtBottom * 0.8),
        reason: 'should have reached (near) the bottom');

    // Now scroll back UP (drag down). This is the reported bug.
    for (var i = 0; i < 12; i++) {
      await tester.drag(
        find.descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(ListView),
        ),
        const Offset(0, 500),
      );
      await tester.pump();
      if (settingsOffset(tester) < atBottom * 0.5) break;
    }
    final afterUp = settingsOffset(tester);
    // ignore: avoid_print
    print('A: after scrolling up: offset=$afterUp (was $atBottom)');
    expect(afterUp, lessThan(atBottom * 0.5),
        reason: 'scrolling up must move the list back toward the top');
  });

  testWidgets('B: Settings scrolls back up on its own (control)',
      (tester) async {
    suppressListTileErrors();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsScreen(onOpenFeature: (_) {}),
        ),
      ),
    );
    await pumpFrames(tester);

    final maxExtent = settingsMaxExtent(tester);
    expect(maxExtent, greaterThan(0),
        reason: 'Settings content must overflow the viewport');

    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      if (settingsOffset(tester) > settingsMaxExtent(tester) * 0.8) break;
    }
    final atBottom = settingsOffset(tester);
    final maxAtBottom = settingsMaxExtent(tester);
    // ignore: avoid_print
    print('B: after scrolling down: offset=$atBottom max=$maxAtBottom');
    expect(atBottom, greaterThan(maxAtBottom * 0.8));

    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pump();
      if (settingsOffset(tester) < atBottom * 0.5) break;
    }
    final afterUp = settingsOffset(tester);
    // ignore: avoid_print
    print('B: after scrolling up: offset=$afterUp (was $atBottom)');
    expect(afterUp, lessThan(atBottom * 0.5));
  });

  testWidgets('C: fling down then fling up inside the real Shell',
      (tester) async {
    suppressListTileErrors();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const QubaApp());
    await pumpFrames(tester);
    await tester.tap(find.text('Settings'));
    await pumpFrames(tester);

    final listFinder = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(ListView),
    );
    await tester.fling(listFinder, const Offset(0, -800), 3000);
    await pumpFrames(tester, count: 20);
    final atBottom = settingsOffset(tester);
    // ignore: avoid_print
    print('C: after fling down: offset=$atBottom '
        'max=${settingsMaxExtent(tester)}');

    await tester.fling(listFinder, const Offset(0, 800), 3000);
    await pumpFrames(tester, count: 20);
    final afterUp = settingsOffset(tester);
    // ignore: avoid_print
    print('C: after fling up: offset=$afterUp (was $atBottom)');
    expect(afterUp, lessThan(atBottom * 0.5));
  });

  testWidgets('D: notification-card transition while at the bottom',
      (tester) async {
    suppressListTileErrors();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const QubaApp());
    await pumpFrames(tester);
    await tester.tap(find.text('Settings'));
    await pumpFrames(tester);

    final listFinder = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(ListView),
    );
    for (var i = 0; i < 5; i++) {
      await tester.drag(listFinder, const Offset(0, -500));
      await tester.pump();
    }
    final atBottom = settingsOffset(tester);
    // ignore: avoid_print
    print('D: at bottom: offset=$atBottom '
        'max=${settingsMaxExtent(tester)}');

    // Simulate scheduleAll finishing on the phone: a NEW lastResult
    // instance appears, which makes _NotificationStatusCard rebuild
    // with a fresh permissionState() future (card shrinks to the
    // waiting state, then grows again when it resolves).
    NotificationService.instance.lastResult = const ScheduleResult(
        scheduled: 30, failed: 0, exactAlarms: false);
    appState.update(() {});
    await pumpFrames(tester, count: 20);
    // ignore: avoid_print
    print('D: after card transition: offset=${settingsOffset(tester)} '
        'max=${settingsMaxExtent(tester)}');

    for (var i = 0; i < 5; i++) {
      await tester.drag(listFinder, const Offset(0, 500));
      await tester.pump();
    }
    final afterUp = settingsOffset(tester);
    // ignore: avoid_print
    print('D: after scrolling up: offset=$afterUp (was $atBottom)');
    expect(afterUp, lessThan(atBottom * 0.5));
  });

  testWidgets('F: Home ticker fires while at the bottom, then scroll up',
      (tester) async {
    suppressListTileErrors();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const QubaApp());
    await pumpFrames(tester);
    await tester.tap(find.text('Settings'));
    await pumpFrames(tester);

    final listFinder = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(ListView),
    );
    for (var i = 0; i < 5; i++) {
      await tester.drag(listFinder, const Offset(0, -500));
      await tester.pump();
    }
    final atBottom = settingsOffset(tester);
    // ignore: avoid_print
    print('F: at bottom: offset=$atBottom');

    // Let 5 real seconds pass: Home's 1-second ticker rebuilds the
    // offstage Home ListView 5 times while we sit at the bottom.
    await tester.pump(const Duration(seconds: 5));
    // ignore: avoid_print
    print('F: after 5s ticker: offset=${settingsOffset(tester)}');

    for (var i = 0; i < 5; i++) {
      await tester.drag(listFinder, const Offset(0, 500));
      await tester.pump();
    }
    final afterUp = settingsOffset(tester);
    // ignore: avoid_print
    print('F: after scrolling up: offset=$afterUp (was $atBottom)');
    expect(afterUp, lessThan(atBottom * 0.5));
  });

  testWidgets('G: repeated appState rebuilds while at the bottom',
      (tester) async {
    suppressListTileErrors();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const QubaApp());
    await pumpFrames(tester);
    await tester.tap(find.text('Settings'));
    await pumpFrames(tester);

    final listFinder = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(ListView),
    );
    for (var i = 0; i < 5; i++) {
      await tester.drag(listFinder, const Offset(0, -500));
      await tester.pump();
    }
    final atBottom = settingsOffset(tester);
    // ignore: avoid_print
    print('G: at bottom: offset=$atBottom');

    // Simulate heavy appState traffic (e.g. slider drags): rebuild
    // the whole MaterialApp + all five tabs 10 times in a row.
    for (var i = 0; i < 10; i++) {
      appState.update(
          () => appState.arabicFontSize = 30 + (i % 2) * 0.5);
      await tester.pump();
    }
    // ignore: avoid_print
    print('G: after 10 rebuilds: offset=${settingsOffset(tester)}');

    for (var i = 0; i < 5; i++) {
      await tester.drag(listFinder, const Offset(0, 500));
      await tester.pump();
    }
    final afterUp = settingsOffset(tester);
    // ignore: avoid_print
    print('G: after scrolling up: offset=$afterUp (was $atBottom)');
    expect(afterUp, lessThan(atBottom * 0.5));
  });

  testWidgets('E: no tab shares the route PrimaryScrollController',
      (tester) async {
    suppressListTileErrors();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const QubaApp());
    await pumpFrames(tester);
    await tester.tap(find.text('Settings'));
    await pumpFrames(tester);

    // Before the fix this was 5 (all five tab ListViews attached to
    // the one route controller). Every tab now owns its scroll state,
    // so the shared controller must have no positions at all.
    final primary = PrimaryScrollController.of(
        tester.element(find.byType(SettingsScreen)));
    expect(primary.positions, isEmpty,
        reason: 'no tab ListView may attach to the shared '
            'PrimaryScrollController');
  });

  testWidgets('H: every tab scrolls down and back up in the Shell',
      (tester) async {
    suppressListTileErrors();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const QubaApp());
    await pumpFrames(tester);

    // (nav label, screen type) per tab. The Quran tab's scrollable is
    // the surah list (default view).
    final tabs = <(String, Type)>[
      ('Home', HomeScreen),
      ('Prayer', PrayerScreen),
      ('Quran', QuranScreen),
      ('Extras', ExtrasScreen),
      ('Settings', SettingsScreen),
    ];
    for (final (label, screenType) in tabs) {
      await tester.tap(find.text(label));
      await pumpFrames(tester);
      // The Quran tab also holds a horizontal Continue list; drag the
      // screen centre so the gesture lands on the visible vertical
      // list (the per-Scrollable check below only looks at vertical
      // positions anyway).
      final center = tester.getCenter(find.byType(Shell));
      final scrollableFinder = find.descendant(
        of: find.byType(screenType),
        matching: find.byType(Scrollable),
      );
      // Skip tabs whose content fits without scrolling.
      var maxExtent = 0.0;
      for (var i = 0; i < scrollableFinder.evaluate().length; i++) {
        final s = tester.state<ScrollableState>(scrollableFinder.at(i));
        if (s.position.axis == Axis.vertical &&
            s.position.maxScrollExtent > maxExtent) {
          maxExtent = s.position.maxScrollExtent;
        }
      }
      if (maxExtent <= 0) continue;
      await tester.dragFrom(center, const Offset(0, -2000));
      await tester.pump();
      await tester.dragFrom(center, const Offset(0, 2000));
      await tester.pump();
      // After scrolling down then up, the tab's vertical list must be
      // back near the top — i.e. upward scrolling works on every tab.
      for (var i = 0; i < scrollableFinder.evaluate().length; i++) {
        final s = tester.state<ScrollableState>(scrollableFinder.at(i));
        if (s.position.axis == Axis.vertical) {
          expect(s.position.pixels, lessThan(maxExtent * 0.5),
              reason: '$label tab must scroll back up after scrolling '
                  'down (offset ${s.position.pixels}, max $maxExtent)');
        }
      }
    }
  });
}
