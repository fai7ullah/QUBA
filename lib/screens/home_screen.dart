import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../decor.dart';
import '../i18n.dart';
import '../notifications.dart';
import '../prayer_service.dart';
import '../rate_service.dart';
import '../theme.dart';
import '../widgets.dart';

/// Home — QUBA header, Next Prayer glass card, gold divider, prayer
/// schedule, Continue Reading. Feature chips and the daily card follow
/// below the fold.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onGoTab,
    required this.onOpenReader,
    required this.onOpenFeature,
    required this.onOpenPrayer,
  });
  final void Function(int tab) onGoTab;
  final void Function(int surah, int ayah) onOpenReader;
  final void Function(String key) onOpenFeature;

  /// Opens the full Prayer screen (the Next Prayer card and the
  /// Prayer Times "View All" both lead there; Prayer has no tab in
  /// the four-tab bar).
  final VoidCallback onOpenPrayer;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ticker;
  Timer? _ratingTimer;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // After a real achievement (7-day streak) ask once, politely, for a
    // rating — a few seconds after launch, never over the first frame.
    _ratingTimer = Timer(const Duration(seconds: 4), _maybeAskRating);
  }

  Future<void> _maybeAskRating() async {
    if (!mounted || !appState.shouldAskForRating) return;
    appState.noteRatingAsked();
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('rate_title')),
        content: Text(tr('rate_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('rate_later')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('rate_now')),
          ),
        ],
      ),
    );
    if (yes == true) {
      appState.noteRated();
      await RateService.requestReview();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ratingTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleNotify(String name, bool enabled) async {
    appState.update(() => appState.prayerNotify[name] = enabled);
    await NotificationService.instance.scheduleAll(appState);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final now = DateTime.now();
        final next = PrayerService.nextPrayer(now, appState);
        final today = PrayerService.dayList(now, appState);
        final isTodayNext =
            next.time.day == now.day &&
            next.time.month == now.month &&
            next.time.year == now.year;
        final bottomInset = MediaQuery.of(context).padding.bottom;
        return ListView(
          // NOT primary: all four tab ListViews live in one
          // IndexedStack in the Shell, and primary ListViews all
          // attach to the route's single PrimaryScrollController.
          // Each tab owns its scroll state instead (2026-11-21:
          // Settings scrolled down and would not scroll back up
          // on the owner's phone — the shared controller is the
          // one structural anomaly in the scroll path, so every
          // tab gets its own controller now).
          primary: false,
          padding: EdgeInsets.zero,
          children: [
            QubaHeader(onSettings: () => widget.onGoTab(3)),
            Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 120 + bottomInset),
              child: Column(
                children: [
                  _nextPrayerCard(context, next, now, today),
                  const SizedBox(height: 18),
                  PrayerScheduleCard(
                    entries: today,
                    nextName: isTodayNext ? next.name : null,
                    onToggle: _toggleNotify,
                    onViewAll: widget.onOpenPrayer,
                  ),
                  const SizedBox(height: 18),
                  _continueReadingCard(context),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _nextPrayerCard(
    BuildContext context,
    PrayerEntry next,
    DateTime now,
    List<PrayerEntry> today,
  ) {
    final p = QubaPalette.of(context);
    var countdown = next.time.difference(now);
    if (countdown.isNegative) countdown = Duration.zero;
    // Ring = share of the gap since the previous prayer still to wait.
    DateTime? prev;
    for (final e in today) {
      if (e.time.isBefore(now)) prev = e.time;
    }
    final gap = prev == null
        ? const Duration(hours: 6)
        : next.time.difference(prev);
    final fraction = gap.inSeconds <= 0
        ? 0.0
        : (countdown.inSeconds / gap.inSeconds).clamp(0.0, 1.0).toDouble();
    final ink = p.dark ? p.ink : const Color(0xFF17211B);
    return GlassCard(
      radius: 40,
      blur: 24,
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      onTap: widget.onOpenPrayer,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Ring scales with the card (reference proportions), clamped
          // so narrow screens keep room for the prayer name.
          final ringSize = (constraints.maxWidth * 0.34)
              .clamp(112.0, 152.0)
              .toDouble();
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _GlossyPill(),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        trPrayer(next.name),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          color: ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 26, color: ink),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              '${tr('in')} ${PrayerService.formatCountdownLong(countdown)}',
                              maxLines: 1,
                              style: TextStyle(fontSize: 20, color: ink),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: ringSize,
                height: ringSize,
                child: CustomPaint(
                  painter: _RingPainter(
                    fraction: fraction,
                    dark: p.dark,
                    color: p.dark ? p.activeText : const Color(0xFF0B7A3B),
                  ),
                  child: Center(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            PrayerService.formatCountdown(countdown),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: ink,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _continueReadingCard(BuildContext context) {
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;
    final hasPlace =
        appState.lastReadSurah >= 1 && appState.lastReadSurah <= 114;
    final surah = repo.loaded && hasPlace
        ? repo.surah(appState.lastReadSurah)
        : null;
    final globalPos = repo.loaded && hasPlace
        ? repo.globalIndexOf(appState.lastReadSurah, appState.lastReadAyah)
        : 1;
    final progress = (globalPos / 6236.0).clamp(0.0, 1.0);
    final pct = (progress * 100).round();
    final String? surahName = surah?.nameEnglish;
    final verseLine = surah == null
        ? null
        : trf('verse_of', {
            'n': appState.lastReadAyah,
            'total': surah.ayahCount,
          });
    final ink = p.dark ? p.ink : const Color(0xFF17211B);
    final soft = p.dark ? p.muted : const Color(0xFF2F3A33);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GlassCard(
      radius: 38,
      blur: 24,
      padding: const EdgeInsets.fromLTRB(20, 16, 18, 16),
      onTap: () => widget.onOpenReader(
        hasPlace ? appState.lastReadSurah : 1,
        hasPlace ? appState.lastReadAyah : 1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 2.4,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.2),
              color: p.emerald,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('continue_reading'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w600,
                              color: p.emerald,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            surahName ?? tr('start_fatihah'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: ink,
                            ),
                          ),
                          if (verseLine != null)
                            Text(
                              verseLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.5,
                                color: soft,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GlassBubble(
                      width: 50,
                      height: 50,
                      glow: true,
                      child: GlossyIcon(
                        rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 32,
                        colors: glossyGreen(p),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: p.dark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : const Color(0xFFE1E9E4),
                              color: p.dark
                                  ? p.activeText
                                  : const Color(0xFF0B7A3B),
                            ),
                          ),
                          Positioned(
                            top: 1,
                            left: 2,
                            right: 2,
                            height: 3,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '$pct%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// Glossy "Next Prayer" label pill: green gradient, bright rim, and a
/// specular highlight behind the text.
class _GlossyPill extends StatelessWidget {
  const _GlossyPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.4),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3CCB76), Color(0xFF0E8A43), Color(0xFF09672F)],
          stops: [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B7A3B).withValues(alpha: 0.38),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            Positioned(
              top: 1,
              left: 10,
              right: 10,
              height: 15,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
              child: Text(
                tr('next_prayer'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Color(0x40000000), offset: Offset(0, 1), blurRadius: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glossy countdown ring: a thick deep-green arc with a soft glow for
/// the share of the wait still left (clockwise from the top), around a
/// raised glass disc with a bright rim and a specular highlight.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.dark,
    required this.color,
  });
  final double fraction;
  final bool dark;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final c = size.center(Offset.zero);
    final r = size.width / 2 - stroke / 2 - 3;
    final discR = r - stroke / 2 - 5;
    final ringRect = Rect.fromCircle(center: c, radius: r);
    final discRect = Rect.fromCircle(center: c, radius: discR);

    // Faint glass track.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = dark
            ? Colors.white.withValues(alpha: 0.10)
            : const Color(0xFFDDF3E5).withValues(alpha: 0.9),
    );

    // Raised glass disc: drop glow, milky body, bright rim.
    canvas.drawCircle(
      c.translate(0, 4),
      discR,
      Paint()
        ..color = const Color(0xFF2FB765).withValues(alpha: dark ? 0.15 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      c,
      discR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.5),
          radius: 1.0,
          colors: dark
              ? const [Color(0x6634D399), Color(0x330A3C2C)]
              : const [Color(0xFFFFFFFF), Color(0xFFF1FAF4), Color(0xFFDCF1E4)],
        ).createShader(discRect),
    );
    canvas.drawCircle(
      c,
      discR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [Colors.white.withValues(alpha: 0.4), const Color(0x5534D399)]
              : const [Colors.white, Color(0xFFA8E2C0), Colors.white],
        ).createShader(discRect),
    );
    // Specular highlight across the disc's upper half.
    final hl = Rect.fromCenter(
      center: Offset(c.dx, c.dy - discR * 0.48),
      width: discR * 1.5,
      height: discR * 0.8,
    );
    canvas.drawOval(
      hl,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.22 : 0.9),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(hl),
    );

    if (fraction <= 0) return;
    final sweep = 2 * math.pi * fraction;
    // Glow under the arc.
    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2FB765).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Deep glossy green arc.
    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          transform: const GradientRotation(-math.pi / 2),
          colors: dark
              ? [color, color]
              : const [Color(0xFF2FB765), Color(0xFF0B7A3B), Color(0xFF065A28)],
        ).createShader(ringRect),
    );
    // Thin highlight line along the arc for the wet-glass shine.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - stroke * 0.18),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction || old.dark != dark || old.color != color;
}
