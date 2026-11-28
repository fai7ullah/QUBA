import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quba/app_state.dart';
import 'package:quba/data.dart';
import 'package:quba/main.dart';
import 'package:quba/prayer_service.dart';
import 'package:quba/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reference-layout checks for the 2026-11-28 liquid-glass Home
/// (Umar's screenshot): header capsule + settings button, Next
/// Prayer ring, six aligned prayer rows with right-aligned times,
/// Continue Reading progress, and the four-tab floating nav.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final regular = File('/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf');
    final bold = File('/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf');
    if (regular.existsSync() && bold.existsSync()) {
      final roboto = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(regular.readAsBytesSync())))
        ..addFont(Future.value(ByteData.sublistView(bold.readAsBytesSync())));
      await roboto.load();
    }
    SharedPreferences.setMockInitialValues({});
    await appState.load();
    await QuranRepository.instance.load();
    appState.onboardingDone = true;
    appState.lang = 'en';
    appState.themeMode = ThemeMode.light;
    appState.lastReadSurah = 2;
    appState.lastReadAyah = 270;
  });

  Future<void> pumpHome(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const QubaApp());
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('Home matches the reference layout at 390px', (tester) async {
    await pumpHome(tester, const Size(390, 844));

    // Header capsule + separate settings button.
    expect(find.text('QUBA'), findsOneWidget);
    expect(find.text('Your Islamic Companion'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsNWidgets(2));

    // Next Prayer card with a large countdown ring.
    expect(find.text('Next Prayer'), findsOneWidget);
    var ringFound = false;
    for (final e in find.byType(CustomPaint).evaluate()) {
      if (tester.getSize(find.byWidget(e.widget)).width >= 112) {
        ringFound = true;
      }
    }
    expect(ringFound, isTrue, reason: 'countdown ring >= 112px');

    // Six prayer rows; header medallion + one oval bubble per row.
    for (final name in [
      'Fajr',
      'Sunrise',
      'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha',
    ]) {
      expect(find.text(name), findsWidgets, reason: name);
    }
    expect(find.byType(PrayerMedallion), findsNWidgets(7));

    // Prayer times share one right edge.
    final today = PrayerService.dayList(DateTime.now(), appState);
    final rights = <double>[];
    for (final e in today) {
      final f = find.text(PrayerService.formatTime(e.time));
      expect(f, findsWidgets, reason: e.name);
      rights.add(tester.getRect(f.first).right);
    }
    for (final r in rights) {
      expect((r - rights.first).abs(), lessThan(1.5));
    }

    // Continue Reading shows the real place and a matching percent.
    expect(find.text('Continue Reading'), findsOneWidget);
    expect(find.text('Al-Baqara'), findsOneWidget);
    expect(find.text('verse 270 of 286'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    final pct = ((bar.value ?? 0) * 100).round();
    expect(find.text('$pct%'), findsOneWidget);

    // Four-tab floating nav, fixed at the bottom.
    for (final label in ['Home', 'Quran', 'Extras', 'Settings']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('Home reference layout fits at 320px', (tester) async {
    await pumpHome(tester, const Size(320, 844));
    expect(find.text('QUBA'), findsOneWidget);
    expect(find.text('Next Prayer'), findsOneWidget);
    expect(find.byType(PrayerMedallion), findsNWidgets(7));
    expect(find.text('Continue Reading'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
