import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'data.dart';
import 'i18n.dart';
import 'mushaf_data.dart';
import 'notifications.dart';
import 'translation_data.dart';
import 'screens/calendar_screen.dart';
import 'screens/duas_screen.dart';
import 'screens/home_screen.dart';
import 'screens/khatma_screen.dart';
import 'screens/mushaf_screen.dart';
import 'screens/names_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasbih_screen.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appState.load();
  await QuranRepository.instance.load();
  await MushafData.instance.load();
  // Translations are best-effort: if the asset load ever stalls, the
  // app must still open (translations just become unavailable).
  try {
    await TranslationRepository.instance
        .load()
        .timeout(const Duration(seconds: 10));
  } catch (_) {
    // Translation assets unavailable on this run; the app opens anyway.
  }
  runApp(const QubaApp());
  // Register prayer alerts after the first frame so startup stays instant.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationService.instance.init();
    await NotificationService.instance.scheduleAll(appState);
  });
}

class QubaApp extends StatelessWidget {
  const QubaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => MaterialApp(
        title: 'QUBA',
        debugShowCheckedModeBanner: false,
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
        builder: (_) => MushafScreen(
          initialPage: MushafData.instance.pageOfJuz(juz),
        ),
      ),
    );
  }

  void _openFeature(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
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
        return SearchScreen(onOpenReader: _openReader);
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
      ),
      const PrayerScreen(),
      QuranScreen(
        onOpenSurah: (s) => _openReader(s, 1),
        onOpenSearch: () => _openFeatureKey('search'),
        onOpenReader: _openReader,
        onOpenJuz: _openMushaf,
        onOpenSettings: () => setState(() => _tab = 3),
      ),
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

/// Floating liquid-glass bottom navigation: one wide pill, thin gold
/// separators and a frosted highlight with an emerald underline on the
/// active tab, as in the reference design.
class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.tab, required this.onTab});
  final int tab;
  final ValueChanged<int> onTab;

  static const _items = [
    (Icons.home_rounded, 'home'),
    (Icons.menu_book_rounded, 'prayer'),
    (Icons.mosque_rounded, 'quran'),
    (Icons.settings_rounded, 'settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 59,
              decoration: BoxDecoration(
                color: p.dark
                    ? p.cardFill
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: p.cardBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: p.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemW = constraints.maxWidth / _items.length;
                  final isRtl =
                      Directionality.of(context) == TextDirection.rtl;
                  // In RTL the visual order mirrors: index 0 is on the right.
                  final visualTab = isRtl ? _items.length - 1 - tab : tab;
                  return Stack(
                    children: [
                      // Active tab highlight with its underline.
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: visualTab * itemW + 2,
                        top: 2,
                        width: itemW - 4,
                        height: 55,
                        child: Container(
                          decoration: BoxDecoration(
                            color: p.dark
                                ? p.activeFill
                                : Colors.white.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: p.dark
                                  ? p.activeText.withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.9),
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
                            color: p.gold.withValues(alpha: 0.35),
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
    final iconColor = p.dark ? p.activeText : p.emeraldDeep;
    final labelColor = active
        ? (p.dark ? p.activeText : p.emerald)
        : (p.dark ? p.muted : const Color(0xFF4A4D45));
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 27, color: iconColor),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
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
