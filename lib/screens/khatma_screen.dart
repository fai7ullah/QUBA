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
        title: const Text('End plan?'),
        content: const Text(
          'Your reading position is kept — only the plan is removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'End plan',
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
          subtitle: 'Finish the whole Quran',
        ),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(
            children: [
              PrayerMedallion(icon: Icons.menu_book_rounded, size: 64),
              const SizedBox(height: 16),
              Text(
                'Set a goal and read a little every day',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your plan starts from where you are reading now '
                '(${_positionLabel(repo, repo.globalIndexOf(appState.lastReadSurah, appState.lastReadAyah))}) '
                'and divides the remaining verses evenly across the days you choose.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, color: p.muted, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionLabel('Choose your plan'),
        const SizedBox(height: 12),
        Row(
          children: [
            GlassButton(
              icon: Icons.bolt_rounded,
              label: '7 days',
              onTap: () => _startPlan(7),
            ),
            const SizedBox(width: 10),
            GlassButton(
              icon: Icons.calendar_month_rounded,
              label: '30 days',
              onTap: () => _startPlan(30),
            ),
            const SizedBox(width: 10),
            GlassButton(
              icon: Icons.flag_rounded,
              label: '90 days',
              onTap: () => _startPlan(90),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '7 days ≈ ${((_totalAyahs - (repo.globalIndexOf(appState.lastReadSurah, appState.lastReadAyah) - 1)) / 7).ceil()} verses a day · '
          '30 days ≈ ${((_totalAyahs - (repo.globalIndexOf(appState.lastReadSurah, appState.lastReadAyah) - 1)) / 30).ceil()} a day · '
          '90 days ≈ ${((_totalAyahs - (repo.globalIndexOf(appState.lastReadSurah, appState.lastReadAyah) - 1)) / 90).ceil()} a day',
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
          subtitle: '$days-day plan',
        ),
        const SizedBox(height: 24),
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
                        'complete',
                        style: TextStyle(fontSize: 13, color: p.muted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                complete
                    ? 'Plan complete — you finished the Quran'
                    : onTrack
                        ? 'You are on track'
                        : 'Behind by ${expected - actual} verses',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: complete || onTrack ? p.emerald : p.gold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$readInPlan of $remaining verses read in this plan',
                style: TextStyle(fontSize: 14, color: p.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            children: [
              _statRow(p, Icons.calendar_today_rounded, 'Day',
                  '${math.min(elapsed + 1, days)} of $days'),
              const SizedBox(height: 12),
              _statRow(p, Icons.menu_book_rounded, 'Daily portion',
                  '$daily verses'),
              const SizedBox(height: 12),
              _statRow(p, Icons.hourglass_bottom_rounded, 'Days remaining',
                  '$daysLeft'),
            ],
          ),
        ),
        if (!complete) ...[
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel("Today's portion"),
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
                      label: "Read today's portion",
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
            label: const Text('End plan'),
            onPressed: _confirmEndPlan,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statRow(QubaPalette p, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: p.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 14.5, color: p.muted)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
      ],
    );
  }
}
