import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../content.dart';
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
  });
  final void Function(int tab) onGoTab;
  final void Function(int surah, int ayah) onOpenReader;
  final void Function(String key) onOpenFeature;

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
        final isTodayNext = next.time.day == now.day &&
            next.time.month == now.month &&
            next.time.year == now.year;
        final bottomInset = MediaQuery.of(context).padding.bottom;
        return ListView(
              // NOT primary: all five tab ListViews live in one
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
                QubaHeader(onSettings: () => widget.onGoTab(4)),
                Padding(
                  padding: EdgeInsets.fromLTRB(13, 0, 13, 120 + bottomInset),
                  child: Column(
                    children: [
                      _nextPrayerCard(context, next, now),
                      const SizedBox(height: 4),
                      const GoldDivider(),
                      const SizedBox(height: 2),
                      PrayerScheduleCard(
                        entries: today,
                        nextName: isTodayNext ? next.name : null,
                        onToggle: _toggleNotify,
                      ),
                      const SizedBox(height: 18),
                      _continueReadingCard(context),
                      if (appState.readingStreak > 0) ...[
                        const SizedBox(height: 12),
                        _streakChip(context),
                      ],
                      if (appState.prayerStreak > 0) ...[
                        const SizedBox(height: 12),
                        _prayerStreakChip(context),
                      ],
                      // Below the fold: shortcuts and the daily card.
                      const SizedBox(height: 120),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FeatureChip(
                              icon: Icons.explore_rounded,
                              label: tr('qibla'),
                              onTap: () => widget.onOpenFeature('qibla'),
                            ),
                            FeatureChip(
                              icon: Icons.blur_circular_rounded,
                              label: tr('tasbih'),
                              onTap: () => widget.onOpenFeature('tasbih'),
                            ),
                            FeatureChip(
                              icon: Icons.volunteer_activism_rounded,
                              label: tr('duas'),
                              onTap: () => widget.onOpenFeature('duas'),
                            ),
                            FeatureChip(
                              icon: Icons.auto_awesome_rounded,
                              label: tr('names99'),
                              onTap: () => widget.onOpenFeature('names'),
                            ),
                            FeatureChip(
                              icon: Icons.flag_rounded,
                              label: tr('khatma'),
                              onTap: () => widget.onOpenFeature('khatma'),
                            ),
                            FeatureChip(
                              icon: Icons.calendar_month_rounded,
                              label: tr('calendar'),
                              onTap: () => widget.onOpenFeature('calendar'),
                            ),
                            FeatureChip(
                              icon: Icons.wb_twilight_rounded,
                              label: tr('azkar'),
                              onTap: () => widget.onOpenFeature('azkar'),
                            ),
                            FeatureChip(
                              icon: Icons.emoji_events_rounded,
                              label: tr('progress'),
                              onTap: () => widget.onOpenFeature('progress'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _todayCard(context),
                    ],
                  ),
                ),
              ],
            );
      },
    );
  }

  Widget _nextPrayerCard(
      BuildContext context, PrayerEntry next, DateTime now) {
    final p = QubaPalette.of(context);
    final countdown = next.time.difference(now);
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(16, 7, 12, 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ArchImage(
            width: 66,
            height: 89,
            image: Image.asset(
              'assets/images/mosque_arch.webp',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              color: p.dark ? Colors.black.withValues(alpha: 0.25) : null,
              colorBlendMode: p.dark ? BlendMode.darken : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SectionLabel(tr('next_prayer')),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    trPrayer(next.name),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      color: p.dark ? p.ink : const Color(0xFF1F2420),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${tr('in')} ${PrayerService.formatCountdownLong(countdown)}',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 15.5,
                      color: p.dark ? p.muted : const Color(0xFF3B3F38),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: p.dark
                  ? p.activeFill
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: p.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: p.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded,
                    size: 22, color: p.dark ? p.activeText : p.emeraldDeep),
                const SizedBox(width: 7),
                Text(
                  PrayerService.formatTime(next.time),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: p.dark ? p.activeText : p.emeraldDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueReadingCard(BuildContext context) {
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;
    final hasPlace =
        appState.lastReadSurah >= 1 && appState.lastReadSurah <= 114;
    final surah =
        repo.loaded && hasPlace ? repo.surah(appState.lastReadSurah) : null;
    final globalPos = repo.loaded && hasPlace
        ? repo.globalIndexOf(appState.lastReadSurah, appState.lastReadAyah)
        : 1;
    final progress = (globalPos / 6236.0).clamp(0.0, 1.0);
    final title = surah == null
        ? tr('start_fatihah')
        : "${surah.nameEnglish} — ${trf('verse_of', {
              'n': appState.lastReadAyah,
              'total': surah.ayahCount,
            })}";
    final pct = (progress * 100).round();
    final pctText = trf('pct_of_quran', {'pct': pct});
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      onTap: () => widget.onOpenReader(
        hasPlace ? appState.lastReadSurah : 1,
        hasPlace ? appState.lastReadAyah : 1,
      ),
      child: Row(
        children: [
          // The book image has a cream backdrop: feather its edges so it
          // melts into the card like the cut-out in the reference.
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const RadialGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
              stops: [0.0, 0.62, 1.0],
              radius: 0.78,
            ).createShader(rect),
            child: Image.asset(
              'assets/images/quran_rehal.webp',
              width: 92,
              height: 74,
              fit: BoxFit.cover,
              color: p.dark ? Colors.black.withValues(alpha: 0.25) : null,
              colorBlendMode: p.dark ? BlendMode.darken : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(tr('continue_reading')),
                const SizedBox(height: 5),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: p.dark ? p.ink : const Color(0xFF1F2420),
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: p.dark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFD9D3C4),
                    color: p.dark ? p.activeText : p.emeraldDeep,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pctText,
                  style: TextStyle(
                    fontSize: 14,
                    color: p.dark ? p.muted : const Color(0xFF4A4D45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.dark
                  ? p.activeFill
                  : Colors.white.withValues(alpha: 0.55),
              border: Border.all(color: p.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: p.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 26,
              color: p.dark ? p.activeText : p.emeraldDeep,
            ),
          ),
        ],
      ),
    );
  }

  /// Prayer streak chip (all five prayers logged on consecutive days).
  /// Tapping opens the Progress screen.
  Widget _prayerStreakChip(BuildContext context) {
    final p = QubaPalette.of(context);
    final doneToday = appState.allFivePrayedOn(DateTime.now());
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
      onTap: () => widget.onOpenFeature('progress'),
      child: Row(
        children: [
          Icon(
            doneToday ? Icons.verified_rounded : Icons.verified_outlined,
            size: 24,
            color: p.emerald,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              trf('prayer_streak_days', {'count': appState.prayerStreak}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.muted),
        ],
      ),
    );
  }

  /// Reading streak chip: filled flame when today is already read,
  /// outline flame otherwise. Only shown once a streak exists.
  Widget _streakChip(BuildContext context) {
    final p = QubaPalette.of(context);
    final readToday = appState.readToday;
    return GlassCard(
      radius: 22,
      padding:
          const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
      child: Row(
        children: [
          Icon(
            readToday
                ? Icons.local_fire_department_rounded
                : Icons.local_fire_department_outlined,
            size: 24,
            color: p.gold,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              trf('streak_days', {'count': appState.readingStreak}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
          ),
          if (readToday)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 18, color: p.emerald),
                const SizedBox(width: 5),
                Text(
                  tr('read_today'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.emerald,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _todayCard(BuildContext context) {
    final repo = QuranRepository.instance;
    final now = DateTime.now();
    final verseRef = dailyVerses[dayIndex(dailyVerses.length, now)];
    final dua = duas[dayIndex(duas.length, now)];
    final hadith = hadiths[dayIndex(hadiths.length, now)];
    final verse = repo.loaded
        ? repo.surah(verseRef[0]).ayahs[verseRef[1] - 1]
        : null;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(tr('today_card')),
          const SizedBox(height: 14),
          _todayRow(
            context,
            icon: Icons.menu_book_rounded,
            label: tr('verse_of_day'),
            body: verse == null
                ? ''
                : '${repo.arabicText(verseRef[0], verseRef[1])}  (${repo.surah(verseRef[0]).nameEnglish} ${verseRef[0]}:${verseRef[1]})',
            isArabic: true,
            onTap: verse == null
                ? null
                : () => widget.onOpenReader(verseRef[0], verseRef[1]),
          ),
          const SizedBox(height: 14),
          _todayRow(
            context,
            icon: Icons.volunteer_activism_rounded,
            label: tr('dua_of_day'),
            body: tr(dua.title),
            onTap: () => widget.onOpenFeature('duas'),
          ),
          const SizedBox(height: 14),
          _todayRow(
            context,
            icon: Icons.format_quote_rounded,
            label: tr('hadith_of_day'),
            body: '${hadith.english} (${hadith.reference})',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _todayRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String body,
    bool isArabic = false,
    VoidCallback? onTap,
  }) {
    final p = QubaPalette.of(context);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: p.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: p.muted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textDirection: isArabic ? TextDirection.rtl : null,
                textAlign: isArabic ? TextAlign.right : TextAlign.start,
                style: TextStyle(
                  fontFamily: isArabic
                      ? QuranRepository.instance.arabicFontFamily
                      : null,
                  fontSize: isArabic ? 19 : 14.5,
                  height: isArabic ? 1.8 : 1.45,
                  color: p.ink,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(Icons.chevron_right_rounded, size: 20, color: p.muted),
      ],
    );
    if (onTap == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: row,
    );
  }
}
