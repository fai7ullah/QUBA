import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app_state.dart';
import '../i18n.dart';
import '../notifications.dart';
import '../theme.dart';
import '../widgets.dart';

/// First-run onboarding: four quick steps, skippable at every step.
/// (1) language, (2) location, (3) prayer calculation, (4) Athan.
/// Shown by main.dart when `!appState.onboardingDone`; finishing (any
/// path) calls [AppState.completeOnboarding] then [onDone].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _steps = 4;
  static const List<String> _fivePrayers = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  final PageController _pageController = PageController();
  int _step = 0;
  bool _locating = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    appState.completeOnboarding();
    widget.onDone();
  }

  void _next() {
    if (_step == _steps - 1) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// GPS like Settings does; on denial, timeout or any error the Kabul
  /// defaults are kept silently — onboarding never blocks on location.
  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 20));
      appState.update(() {
        appState.lat = pos.latitude;
        appState.lng = pos.longitude;
        appState.locationName = 'My location (GPS)';
        appState.locationIsGps = true;
      });
      await NotificationService.instance.scheduleAll(appState);
    } catch (_) {
      // Silent fallback to the Kabul defaults.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _setAthan(bool on) async {
    appState.update(() {
      for (final name in _fivePrayers) {
        appState.prayerNotify[name] = on;
      }
    });
    try {
      await NotificationService.instance.scheduleAll(appState);
    } catch (_) {
      // A failed schedule must not break onboarding.
    }
  }

  Future<void> _setCalc(String method) async {
    appState.update(() => appState.calcMethod = method);
    try {
      await NotificationService.instance.scheduleAll(appState);
    } catch (_) {}
  }

  Future<void> _setAsr(bool hanafi) async {
    appState.update(() => appState.asrHanafi = hanafi);
    try {
      await NotificationService.instance.scheduleAll(appState);
    } catch (_) {}
  }

  bool get _athanOn =>
      _fivePrayers.every((n) => appState.prayerNotify[n] ?? false);

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < _steps; i++)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _step
                                    ? p.emerald
                                    : p.cardBorder,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        child: Text(
                          tr('onboard_skip'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: p.emerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _step = i),
                      children: [
                        _languageStep(p),
                        _locationStep(p),
                        _calcStep(p),
                        _athanStep(p),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _step == _steps - 1
                            ? tr('onboard_done')
                            : tr('onboard_next'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepScroll(QubaPalette p, List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _stepTitle(QubaPalette p, String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(fontSize: 15, color: p.muted, height: 1.5),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// One big tappable option row with a check mark when selected.
  Widget _option(
    QubaPalette p, {
    required bool selected,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: p.emerald),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13.5, color: p.muted),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (selected)
              Icon(Icons.check_circle_rounded,
                  size: 24, color: p.emerald),
          ],
        ),
      ),
    );
  }

  Widget _languageStep(QubaPalette p) {
    return _stepScroll(p, [
      _stepTitle(p, tr('onboard_welcome'), tr('onboard_welcome_body')),
      SectionLabel(tr('onboard_language')),
      const SizedBox(height: 12),
      for (final lang in QubaStrings.allLangs)
        _option(
          p,
          selected: appState.lang == lang,
          icon: Icons.language_rounded,
          title: QubaStrings.langNames[lang]!,
          onTap: () => appState.update(() => appState.lang = lang),
        ),
    ]);
  }

  Widget _locationStep(QubaPalette p) {
    return _stepScroll(p, [
      _stepTitle(p, tr('onboard_location'), tr('onboard_location_body')),
      _option(
        p,
        selected: appState.locationIsGps,
        icon: Icons.my_location_rounded,
        title: tr('onboard_location_gps'),
        subtitle: appState.locationIsGps
            ? trLocation(appState.locationName)
            : null,
        trailing: _locating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : null,
        onTap: _locating
            ? () {}
            : () async {
                await _useGps();
                if (mounted) _next();
              },
      ),
      _option(
        p,
        selected: !appState.locationIsGps,
        icon: Icons.location_city_rounded,
        title: tr('onboard_location_default'),
        onTap: _next,
      ),
    ]);
  }

  Widget _calcStep(QubaPalette p) {
    return _stepScroll(p, [
      _stepTitle(p, tr('onboard_calc'), tr('onboard_calc_body')),
      SectionLabel(tr('calculation')),
      const SizedBox(height: 12),
      _option(
        p,
        selected: appState.calcMethod == 'mwl',
        icon: Icons.public_rounded,
        title: 'Muslim World League',
        subtitle: "${trPrayer('Fajr')} 18° • ${trPrayer('Isha')} 17°",
        onTap: () => _setCalc('mwl'),
      ),
      _option(
        p,
        selected: appState.calcMethod == 'karachi',
        icon: Icons.school_rounded,
        title: 'Univ. of Islamic Sciences, Karachi',
        subtitle: "${trPrayer('Fajr')} 18° • ${trPrayer('Isha')} 18°",
        onTap: () => _setCalc('karachi'),
      ),
      const SizedBox(height: 8),
      SectionLabel(trPrayer('Asr')),
      const SizedBox(height: 12),
      _option(
        p,
        selected: appState.asrHanafi,
        icon: Icons.light_mode_rounded,
        title: tr('madhab_hanafi'),
        subtitle: tr('asr_hanafi_sub'),
        onTap: () => _setAsr(true),
      ),
      _option(
        p,
        selected: !appState.asrHanafi,
        icon: Icons.light_mode_outlined,
        title: tr('madhab_shafii'),
        subtitle: tr('asr_shafii_sub'),
        onTap: () => _setAsr(false),
      ),
    ]);
  }

  Widget _athanStep(QubaPalette p) {
    return _stepScroll(p, [
      _stepTitle(p, tr('onboard_athan'), tr('onboard_athan_body')),
      GlassCard(
        onTap: () => _setAthan(!_athanOn),
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.notifications_active_rounded,
                size: 24, color: p.emerald),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                tr('onboard_athan_on'),
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
            ),
            Switch(
              value: _athanOn,
              onChanged: _setAthan,
            ),
          ],
        ),
      ),
    ]);
  }
}
