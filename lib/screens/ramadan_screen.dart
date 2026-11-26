import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../i18n.dart';
import '../prayer_calc.dart';
import '../prayer_service.dart';
import '../ramadan/ramadan_goals.dart';
import '../theme.dart';
import '../widgets.dart';

/// Ramadan mode: during Ramadan it shows the current Ramadan day,
/// today's Suhoor end (Fajr) + Iftar (Maghrib) with a live countdown
/// to the next one, and a daily goals checklist. Outside Ramadan it
/// shows the days until Ramadan 1 plus the full 30-day timetable.
///
/// Ramadan 1 is found the same way as the Calendar screen's Ramadan
/// timetable (anchor on the current Hijri month's 1st, then step whole
/// Hijri months) — one source of truth, no second date invented here.
/// Verified in round 3: Ramadan 1 = 2027-02-08.
class RamadanScreen extends StatefulWidget {
  const RamadanScreen({super.key});

  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends State<RamadanScreen> {
  Timer? _ticker;
  Set<String> _goalsDone = {};
  bool _goalsLoaded = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final done = await RamadanGoals.load(DateTime.now());
    if (mounted) {
      setState(() {
        _goalsDone = done;
        _goalsLoaded = true;
      });
    }
  }

  Future<void> _toggleGoal(String goal) async {
    final done = await RamadanGoals.toggle(DateTime.now(), goal);
    if (mounted) setState(() => _goalsDone = done);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Hijri anchoring — same algorithm as CalendarScreen (one source of
  // truth for the Ramadan-1 date).
  // ------------------------------------------------------------------

  /// Gregorian date of the 1st of the current Hijri month, found by
  /// scanning backwards from today (up to 40 days).
  DateTime _firstOfCurrentHijriMonth() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayHijri = HijriDate.fromDate(today);
    for (var i = 0; i < 40; i++) {
      final d = today.subtract(Duration(days: i));
      final h = HijriDate.fromDate(d);
      if (h.day == 1 &&
          h.month == todayHijri.month &&
          h.year == todayHijri.year) {
        return d;
      }
    }
    return today.subtract(Duration(days: todayHijri.day - 1));
  }

  /// Gregorian date of any Hijri [year]/[month]/[day]: anchor on the
  /// 1st of the current Hijri month, then step whole Hijri months.
  DateTime _gregOfHijri(int year, int month, int day) {
    var first = _firstOfCurrentHijriMonth();
    final todayHijri = HijriDate.fromDate(DateTime.now());
    var y = todayHijri.year;
    var m = todayHijri.month;
    while (y != year || m != month) {
      if (y < year || (y == year && m < month)) {
        first = first.add(Duration(days: HijriDate.daysInMonth(y, m)));
        m++;
        if (m > 12) {
          m = 1;
          y++;
        }
      } else {
        m--;
        if (m < 1) {
          m = 12;
          y--;
        }
        first = first.subtract(Duration(days: HijriDate.daysInMonth(y, m)));
      }
    }
    return first.add(Duration(days: day - 1));
  }

  String _gregString(DateTime d) =>
      '${d.day} ${tr('greg_month_${d.month}')} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayHijri = HijriDate.fromDate(today);
    final inRamadan = todayHijri.month == 9;
    final ramadanYear = todayHijri.month > 9
        ? todayHijri.year + 1
        : todayHijri.year;
    final ramadanStart = _gregOfHijri(ramadanYear, 9, 1);
    final ramadanDays = HijriDate.daysInMonth(ramadanYear, 9);

    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TitleRow(
                      title: tr('ramadan_mode_title'),
                      subtitle: tr('ramadan_subtitle'),
                    ),
                    const SizedBox(height: 16),
                    if (inRamadan) ...[
                      _inRamadan(p, now, today, todayHijri),
                      const SizedBox(height: 20),
                      _goalsCard(p),
                    ] else ...[
                      _countdownCard(p, today, ramadanStart),
                    ],
                    const SizedBox(height: 20),
                    SectionLabel(tr('ramadan_timetable')),
                    const SizedBox(height: 6),
                    Text(
                      inRamadan
                          ? '${_gregString(ramadanStart)} — '
                                '${_gregString(ramadanStart.add(Duration(days: ramadanDays - 1)))}'
                          : '${tr('ramadan_next')} · ${_gregString(ramadanStart)}',
                      style: TextStyle(fontSize: 13.5, color: p.muted),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          for (var n = 1; n <= ramadanDays; n++) ...[
                            if (n > 1)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: p.gold.withValues(alpha: 0.25),
                              ),
                            _timetableRow(
                              p,
                              n,
                              ramadanStart.add(Duration(days: n - 1)),
                              today,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // In Ramadan: day N + Suhoor/Iftar + live countdown
  // ------------------------------------------------------------------

  Widget _inRamadan(
    QubaPalette p,
    DateTime now,
    DateTime today,
    HijriDate todayHijri,
  ) {
    final entries = PrayerService.dayList(today, appState);
    final fajr = entries[0].time;
    final maghrib = entries[4].time;
    // Countdown target: Suhoor end (Fajr) before Fajr, Iftar (Maghrib)
    // after Fajr, tomorrow's Fajr after Maghrib.
    late final DateTime target;
    late final String targetLabel;
    if (now.isBefore(fajr)) {
      target = fajr;
      targetLabel = tr('ramadan_until_suhoor');
    } else if (now.isBefore(maghrib)) {
      target = maghrib;
      targetLabel = tr('ramadan_until_iftar');
    } else {
      target = PrayerService.dayList(
        today.add(const Duration(days: 1)),
        appState,
      )[0].time;
      targetLabel = tr('ramadan_until_suhoor');
    }
    final countdown = target.difference(now);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            trf('ramadan_today_is', {'day': todayHijri.day}),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            todayHijri.localizedString(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: p.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _timeBox(
                  p,
                  label: tr('ramadan_suhoor_ends'),
                  time: PrayerService.formatTime(fajr),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeBox(
                  p,
                  label: tr('ramadan_iftar_at'),
                  time: PrayerService.formatTime(maghrib),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            targetLabel,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: p.muted),
          ),
          const SizedBox(height: 4),
          Text(
            PrayerService.formatCountdownLong(countdown),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: p.emerald,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(
    QubaPalette p, {
    required String label,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: p.activeFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Outside Ramadan: days-until countdown
  // ------------------------------------------------------------------

  Widget _countdownCard(QubaPalette p, DateTime today, DateTime start) {
    final days = start.difference(today).inDays;
    return GlassCard(
      child: Column(
        children: [
          Icon(Icons.nightlight_round, size: 44, color: p.gold),
          const SizedBox(height: 8),
          Text(
            tr('ramadan_starts_in'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: p.muted),
          ),
          const SizedBox(height: 4),
          Text(
            trf('ramadan_days_left', {'days': days}),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: p.emerald,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _gregString(start),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: p.muted),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Daily goals checklist (during Ramadan)
  // ------------------------------------------------------------------

  Widget _goalsCard(QubaPalette p) {
    final done = _goalsDone.length;
    final total = RamadanGoals.goalKeys.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: SectionLabel(tr('ramadan_goals'))),
            if (_goalsLoaded)
              Text(
                trf('ramadan_goals_done', {'done': done, 'total': total}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.emerald,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < RamadanGoals.goalKeys.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: p.gold.withValues(alpha: 0.25),
                  ),
                _goalRow(p, RamadanGoals.goalKeys[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _goalRow(QubaPalette p, String goal) {
    final checked = _goalsDone.contains(goal);
    return ListTile(
      leading: Icon(
        checked
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: checked ? p.emerald : p.muted,
      ),
      title: Text(
        tr('ramadan_goal_$goal'),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: checked ? p.muted : p.ink,
          decoration: checked ? TextDecoration.lineThrough : null,
        ),
      ),
      onTap: () => _toggleGoal(goal),
    );
  }

  // ------------------------------------------------------------------
  // Timetable row (same shape as the Calendar screen's Ramadan rows)
  // ------------------------------------------------------------------

  Widget _timetableRow(QubaPalette p, int day, DateTime greg, DateTime today) {
    final entries = PrayerService.dayList(greg, appState);
    final fajr = entries[0].time;
    final maghrib = entries[4].time;
    final fast = maghrib.difference(fajr);
    final fastText = '${fast.inHours}h ${fast.inMinutes % 60}m';
    final isToday =
        greg.year == today.year &&
        greg.month == today.month &&
        greg.day == today.day;
    return Container(
      decoration: BoxDecoration(
        color: isToday ? p.activeFill : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday ? p.emerald : p.activeFill,
          ),
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isToday ? p.onEmerald : p.emerald,
            ),
          ),
        ),
        title: Text(
          trf('ramadan_day', {'day': day}),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w700, color: p.ink),
        ),
        subtitle: Text(
          _gregString(greg),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: p.muted),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${tr('suhoor')} ${PrayerService.formatTime(fajr)}',
              style: TextStyle(fontSize: 13, color: p.ink),
            ),
            Text(
              '${tr('iftar')} ${PrayerService.formatTime(maghrib)}',
              style: TextStyle(fontSize: 13, color: p.ink),
            ),
            Text(
              trf('fasting_hours', {'hours': fastText}),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
