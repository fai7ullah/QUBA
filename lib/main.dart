import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'data.dart';
import 'hadith/hadith_screen.dart';
import 'homewidget/home_widget_service.dart';
import 'i18n.dart';
import 'mushaf_data.dart';
import 'notifications.dart';
import 'tafsir/tafsir_screen.dart';
import 'translation_data.dart';
import 'wordbyword/wordbyword_screen.dart';
import 'screens/azkar_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/duas_screen.dart';
import 'screens/extras_screen.dart';
import 'screens/home_screen.dart';
import 'screens/khatma_screen.dart';
import 'screens/mushaf_screen.dart';
import 'screens/names_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/ramadan_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasbih_screen.dart';
import 'screens/test_mode_screen.dart';
import 'screens/widget_screen.dart';
import 'theme.dart';
import 'widgets.dart';
import 'widgets/global_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appState.load();
  await QuranRepository.instance.load();
  await MushafData.instance.load();
  // Translations are best-effort: if the asset load ever stalls, the
  // app must still open (translations just become unavailable).
  try {
    await TranslationRepository.instance.load().timeout(
      const Duration(seconds: 10),
    );
  } catch (_) {
    // Translation assets unavailable on this run; the app opens anyway.
  }
  runApp(const QubaApp());
  // Register prayer alerts after the first frame so startup stays instant.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationService.instance.init();
    await NotificationService.instance.scheduleAll(appState);
    // Push fresh data to the home-screen widget (best-effort; the
    // widget also refreshes at most every 30 minutes on its own).
    await HomeWidgetService.update(appState);
  });
}

class QubaApp extends StatelessWidget {
  const QubaApp({super.key});

  static final QubaRouteObserver routeObserver = QubaRouteObserver();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => MaterialApp(
        title: 'QUBA',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        navigatorObservers: [routeObserver],
        // App-wide bottom player: floats above every route while a
        // recitation session is active (hidden under dialogs/sheets).
        builder: (context, child) => QubaPlayerOverlay(
          routeObserver: routeObserver,
          navigatorKey: navigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
        theme: qubaLightTheme(),
        darkTheme: qubaDarkTheme(),
        themeMode: appState.themeMode,
        locale: Locale(appState.lang),
        supportedLocales: const [
          Locale('en'),
          Locale('ps'),
          Locale('fa'),
          Locale('ur'),
          Locale('ar'),
          Locale('id'),
          Locale('tr'),
          Locale('bn'),
          Locale('fr'),
          Locale('ms'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: appState.onboardingDone
            ? const Shell()
            // First run: language → location → calculation → Athan.
            // completeOnboarding() notifies appState, so this rebuilds
            // into the Shell when the flow finishes (or is skipped).
            : OnboardingScreen(onDone: () {}),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  void _openReader(int surah, int ayah) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(surahNumber: surah, initialAyah: ayah),
      ),
    );
  }

  /// Juz reading opens the mushaf-page reader at the juz's first page
  /// (Madani 604 or IndoPak 610, per the Mushaf style setting).
  void _openMushaf(int juz) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MushafScreen(initialPage: MushafData.instance.pageOfJuz(juz)),
      ),
    );
  }

  void _openFeature(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  /// The full Prayer screen. Prayer has no bottom tab in the
  /// four-tab bar (Umar's liquid-glass brief); Home's Next Prayer
  /// card and Prayer Times "View All" open it as a pushed screen.
  void _openPrayer() {
    _openFeature(
      const Scaffold(
        body: QubaBackground(
          child: SafeArea(top: true, bottom: false, child: PrayerScreen()),
        ),
      ),
    );
  }

  Widget _featureScreen(String key) {
    switch (key) {
      case 'qibla':
        return const QiblaScreen();
      case 'calendar':
        return const CalendarScreen();
      case 'khatma':
        return KhatmaScreen(onOpenReader: _openReader);
      case 'duas':
        return const DuasScreen();
      case 'names':
        return const NamesScreen();
      case 'tasbih':
        return const TasbihScreen();
      case 'search':
        return SearchScreen(onOpenReader: _openReader, onOpenJuz: _openMushaf);
      // Phase 2 (round 4): all new features live in the Extras tab.
      case 'hadith':
        return const HadithScreen();
      case 'tafsir':
        return const TafsirScreen();
      case 'wbw':
        return const WordByWordScreen();
      case 'testmode':
        return const TestModeScreen();
      case 'ramadan':
        return const RamadanScreen();
      case 'widget':
        return const WidgetScreen();
      case 'azkar':
        return const AzkarScreen();
      case 'progress':
        return const ProgressScreen();
      default:
        return const QiblaScreen();
    }
  }

  void _openFeatureKey(String key) => _openFeature(_featureScreen(key));

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onGoTab: (t) => setState(() => _tab = t),
        onOpenReader: _openReader,
        onOpenFeature: _openFeatureKey,
        onOpenPrayer: _openPrayer,
      ),
      QuranScreen(
        onOpenSurah: (s) => _openReader(s, 1),
        onOpenSearch: () => _openFeatureKey('search'),
        onOpenReader: _openReader,
        onOpenJuz: _openMushaf,
        onOpenSettings: () => setState(() => _tab = 3),
      ),
      ExtrasScreen(onOpenFeature: _openFeatureKey),
      SettingsScreen(onOpenFeature: _openFeatureKey),
    ];
    return Scaffold(
      // No AppBar anywhere. The tab content sits in a top SafeArea so
      // no page touches the phone's notification bar; the background
      // itself stays edge-to-edge behind the bar.
      extendBody: true,
      body: QubaBackground(
        child: SafeArea(
          top: true,
          bottom: false,
          child: IndexedStack(index: _tab, children: pages),
        ),
      ),
      bottomNavigationBar: _GlassNavBar(
        tab: _tab,
        onTab: (t) => setState(() => _tab = t),
      ),
    );
  }
}

/// Floating liquid-glass bottom navigation (Umar's brief): four tabs
/// — Home, Quran, Extras, Settings — in one wide frosted pill; the
/// active tab gets a soft emerald glass highlight and a green
/// underline. (Prayer opens from Home; it has no tab.)
class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.tab, required this.onTab});
  final int tab;
  final ValueChanged<int> onTab;

  static const _items = [
    (Icons.home_rounded, 'home'),
    (Icons.menu_book_rounded, 'quran'),
    (Icons.star_rounded, 'extras'),
    (Icons.settings_rounded, 'settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: p.dark
                      ? [const Color(0xD90E4A38), const Color(0xC9083528)]
                      : [
                          Colors.white.withValues(alpha: 0.52),
                          const Color(0xFFE6F6EC).withValues(alpha: 0.40),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: p.dark
                      ? Colors.white.withValues(alpha: 0.28)
                      : Colors.white.withValues(alpha: 0.85),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: p.dark
                        ? p.shadow
                        : const Color(0xFF146441).withValues(alpha: 0.12),
                    blurRadius: 35,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemW = constraints.maxWidth / _items.length;
                  final isRtl = Directionality.of(context) == TextDirection.rtl;
                  // In RTL the visual order mirrors: index 0 is on the right.
                  final visualTab = isRtl ? _items.length - 1 - tab : tab;
                  return Stack(
                    children: [
                      // Specular highlight along the top glass edge.
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 26,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(
                                    alpha: p.dark ? 0.14 : 0.5,
                                  ),
                                  Colors.white.withValues(alpha: 0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Active tab highlight with its underline.
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: visualTab * itemW + 3,
                        top: 3,
                        width: itemW - 6,
                        height: 62,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: p.dark
                                  ? [p.activeFill, p.activeFill]
                                  : [
                                      const Color(0xFFD9F2E2)
                                          .withValues(alpha: 0.85),
                                      const Color(0xFFBFE8CF)
                                          .withValues(alpha: 0.70),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(31),
                            border: Border.all(
                              color: p.dark
                                  ? p.activeText.withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.9),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: p.shadow,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 46,
                              height: 3,
                              margin: const EdgeInsets.only(bottom: 3),
                              decoration: BoxDecoration(
                                color: p.dark ? p.activeText : p.emerald,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Thin gold separators between the tabs.
                      for (var i = 1; i < _items.length; i++)
                        Positioned(
                          left: itemW * i,
                          top: 11,
                          bottom: 11,
                          width: 1,
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                      Row(
                        children: [
                          for (var i = 0; i < _items.length; i++)
                            Expanded(
                              child: _NavItem(
                                icon: _items[i].$1,
                                label: tr(_items[i].$2),
                                active: i == tab,
                                onTap: () => onTab(i),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final iconColor = active
        ? (p.dark ? p.activeText : p.emerald)
        : (p.dark ? p.muted : const Color(0xFF1F2A23));
    final labelColor = active
        ? (p.dark ? p.activeText : p.emerald)
        : (p.dark ? p.muted : const Color(0xFF4A4D45));
    return InkWell(
      borderRadius: BorderRadius.circular(31),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glass bubble icon holder on every tab (the reference's
            // floating pill nav); the active bubble glows mint.
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.5),
                  colors: p.dark
                      ? [const Color(0x4034D399), const Color(0x1A34D399)]
                      : active
                      ? [
                          Colors.white.withValues(alpha: 0.98),
                          const Color(0xFFDFF3E7),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.85),
                          Colors.white.withValues(alpha: 0.45),
                        ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: p.dark ? 0.3 : 0.9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF146441).withValues(alpha: 0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.1,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
