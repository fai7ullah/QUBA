import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

/// Khatma plan: finish the whole Quran in 7, 30 or 90 days, starting
/// from the current reading position. Tracks progress against the
/// daily portion and opens the reader at today's target.
class KhatmaScreen extends StatefulWidget {
  const KhatmaScreen({super.key, required this.onOpenReader});
  final void Function(int surah, int ayah) onOpenReader;

  @override
  State<KhatmaScreen> createState() => _KhatmaScreenState();
}

class _KhatmaScreenState extends State<KhatmaScreen> {
  static const int _totalAyahs = 6236;

  int _epochDayNow() =>
      DateTime.now().difference(DateTime.utc(1970)).inDays;

  /// "Surah name S:A" label for a global 1-based ayah index.
  String _positionLabel(QuranRepository repo, int global) {
    final sa = repo.surahAyahForGlobal(global.clamp(1, _totalAyahs));
    return '${repo.surah(sa[0]).nameEnglish} ${sa[0]}:${sa[1]}';
  }

  void _startPlan(int days) {
    final repo = QuranRepository.instance;
    final startGlobal =
        repo.globalIndexOf(appState.lastReadSurah, appState.lastReadAyah) - 1;
    appState.setKhatma(days, startGlobal);
  }

  Future<void> _confirmEndPlan() async {
    final p = QubaPalette.of(context);
    final end = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(tr('end_plan_title')),
        content: Text(tr('end_plan_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              tr('end_plan'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (end == true) appState.clearKhatma();
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;

    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, _) {
              if (!repo.loaded) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TitleRow(title: tr('khatma')),
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          tr('loading'),
                          style: TextStyle(color: p.muted),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: appState.khatmaDays == 0
                    ? _buildNoPlan(context, p, repo)
                    : _buildPlan(context, p, repo),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNoPlan(
      BuildContext context, QubaPalette p, QuranRepository repo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitleRow(
          title: tr('khatma'),
          subtitle: tr('khatma_subtitle'),
        ),
        const SizedBox(height: 24),
        if (appState.readingStreak > 0) ...[
          _streakCard(p),
          const SizedBox(height: 20),
        ],
        GlassCard(
          child: Column(
            children: [
              PrayerMedallion(icon: Icons.menu_book_rounded, size: 64),
              const SizedBox(height: 16),
              Text(
                tr('khatma_intro'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                trf('khatma_explainer', {
                  'position': _positionLabel(
                      repo,
                      repo.globalIndexOf(appState.lastReadSurah,
                          appState.lastReadAyah)),
                }),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, color: p.muted, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionLabel(tr('choose_plan')),
        const SizedBox(height: 12),
        Row(
          children: [
            GlassButton(
              icon: Icons.bolt_rounded,
              label: trf('days_count', {'n': 7}),
              onTap: () => _startPlan(7),
            ),
            const SizedBox(width: 10),
            GlassButton(
              icon: Icons.calendar_month_rounded,
              label: trf('days_count', {'n': 30}),
              onTap: () => _startPlan(30),
            ),
            const SizedBox(width: 10),
            GlassButton(
              icon: Icons.flag_rounded,
              label: trf('days_count', {'n': 90}),
              onTap: () => _startPlan(90),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          trf('plan_rates', {
            'v7': ((_totalAyahs -
                        (repo.globalIndexOf(appState.lastReadSurah,
                                appState.lastReadAyah) -
                            1)) /
                    7)
                .ceil(),
            'v30': ((_totalAyahs -
                        (repo.globalIndexOf(appState.lastReadSurah,
                                appState.lastReadAyah) -
                            1)) /
                    30)
                .ceil(),
            'v90': ((_totalAyahs -
                        (repo.globalIndexOf(appState.lastReadSurah,
                                appState.lastReadAyah) -
                            1)) /
                    90)
                .ceil(),
          }),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: p.muted, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildPlan(
      BuildContext context, QubaPalette p, QuranRepository repo) {
    final start = appState.khatmaStartGlobal;
    final days = appState.khatmaDays;
    final remaining = math.max(0, _totalAyahs - start);
    final daily = math.max(1, (remaining / days).ceil());
    final elapsed = math.max(0, _epochDayNow() - appState.khatmaStartDay);
    final planDay = math.min(elapsed, days);
    final expected = start + daily * planDay;
    final actual =
        repo.globalIndexOf(appState.lastReadSurah, appState.lastReadAyah) - 1;
    final readInPlan = math.max(0, actual - start);
    final progress = remaining == 0
        ? 1.0
        : (readInPlan / remaining).clamp(0.0, 1.0);
    final daysLeft = math.max(0, days - elapsed);
    final complete = actual >= _totalAyahs;
    final onTrack = actual >= expected;

    // Today's target range (global 1-based).
    final rangeStart = start + daily * planDay + 1;
    final rangeEnd = math.min(start + daily * (planDay + 1), _totalAyahs);
    final rangeStartSa = repo.surahAyahForGlobal(rangeStart.clamp(1, _totalAyahs));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitleRow(
          title: tr('khatma'),
          subtitle: trf('day_plan', {'n': days}),
        ),
        const SizedBox(height: 24),
        if (appState.readingStreak > 0) ...[
          _streakCard(p),
          const SizedBox(height: 16),
        ],
        GlassCard(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 11,
                      backgroundColor: p.cardBorder,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(p.emerald),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                      Text(
                        tr('complete'),
                        style: TextStyle(fontSize: 13, color: p.muted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                complete
                    ? tr('plan_complete')
                    : onTrack
                        ? tr('on_track')
                        : trf('behind_by', {'n': expected - actual}),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: complete || onTrack ? p.emerald : p.gold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                trf('verses_read_in_plan',
                    {'read': readInPlan, 'remaining': remaining}),
                style: TextStyle(fontSize: 14, color: p.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            children: [
              _statRow(
                  p,
                  Icons.calendar_today_rounded,
                  tr('stat_day'),
                  trf('stat_of_days',
                      {'n': math.min(elapsed + 1, days), 'total': days})),
              const SizedBox(height: 12),
              _statRow(p, Icons.menu_book_rounded, tr('stat_daily_portion'),
                  trf('verses_count', {'n': daily})),
              const SizedBox(height: 12),
              _statRow(p, Icons.hourglass_bottom_rounded,
                  tr('stat_days_remaining'), '$daysLeft'),
            ],
          ),
        ),
        if (!complete) ...[
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(tr('todays_portion')),
                const SizedBox(height: 10),
                Text(
                  '${_positionLabel(repo, rangeStart)} — ${_positionLabel(repo, rangeEnd)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    GlassButton(
                      icon: Icons.play_arrow_rounded,
                      label: tr('read_todays_portion'),
                      onTap: () => widget.onOpenReader(
                          rangeStartSa[0], rangeStartSa[1]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.close_rounded, size: 20),
            label: Text(tr('end_plan')),
            onPressed: _confirmEndPlan,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  /// Reading streak card (shown only once a streak exists): flame
  /// filled when today is already read, outline otherwise.
  Widget _streakCard(QubaPalette p) {
    return GlassCard(
      child: Row(
        children: [
          Icon(
            appState.readToday
                ? Icons.local_fire_department_rounded
                : Icons.local_fire_department_outlined,
            size: 26,
            color: p.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('day_streak'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trf('streak_days',
                      {'count': appState.readingStreak}),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ],
            ),
          ),
          if (appState.readToday)
            Icon(Icons.check_circle_rounded,
                size: 22, color: p.emerald),
        ],
      ),
    );
  }

  Widget _statRow(QubaPalette p, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: p.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14.5, color: p.muted),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
        ),
      ],
    );
  }
}
