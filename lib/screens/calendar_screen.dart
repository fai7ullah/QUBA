import 'package:flutter/material.dart';

import '../i18n.dart';
import '../prayer_calc.dart';
import '../theme.dart';
import '../widgets.dart';

/// Hijri calendar (civil / Kuwaiti algorithm): a month grid with
/// navigation, tap-a-day Gregorian equivalents, and the notable days
/// of the displayed month.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const List<String> _gregMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Week starts on Saturday (Afghan week).
  static const List<String> _weekdays = [
    'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri',
  ];

  /// Notable days, keyed "month-day".
  static const Map<String, String> _notableDays = {
    '1-1': 'Islamic New Year',
    '1-10': 'Ashura',
    '3-12': "Prophet's Birthday (Mawlid)",
    '7-27': "Laylat al-Mi'raj",
    '8-15': "Laylat al-Bara'ah",
    '9-1': 'Ramadan begins',
    '9-27': 'Laylat al-Qadr',
    '10-1': 'Eid al-Fitr',
    '12-9': 'Day of Arafah',
    '12-10': 'Eid al-Adha',
  };

  late HijriDate _todayHijri;
  late int _year;
  late int _month;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _todayHijri = HijriDate.fromDate(DateTime.now());
    _year = _todayHijri.year;
    _month = _todayHijri.month;
    _selectedDay = _todayHijri.day;
  }

  bool get _isCurrentMonth =>
      _year == _todayHijri.year && _month == _todayHijri.month;

  /// Gregorian date of the 1st of the current Hijri month, found by
  /// scanning backwards from today (up to 40 days) for the date whose
  /// Hijri day is 1 in the current month/year.
  DateTime _firstOfCurrentMonth() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 40; i++) {
      final d = today.subtract(Duration(days: i));
      final h = HijriDate.fromDate(d);
      if (h.day == 1 &&
          h.month == _todayHijri.month &&
          h.year == _todayHijri.year) {
        return d;
      }
    }
    // Fallback (should not happen): step back by the day-of-month.
    return today.subtract(Duration(days: _todayHijri.day - 1));
  }

  /// Gregorian date of the 1st of the displayed Hijri month: anchor on
  /// the current month's 1st (found by the scan above), then step
  /// forward/backward by whole Hijri months.
  DateTime _firstOfDisplayedMonth() {
    var first = _firstOfCurrentMonth();
    var y = _todayHijri.year;
    var m = _todayHijri.month;
    while (y != _year || m != _month) {
      if (y < _year || (y == _year && m < _month)) {
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
    return first;
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month += delta;
      while (_month > 12) {
        _month -= 12;
        _year++;
      }
      while (_month < 1) {
        _month += 12;
        _year--;
      }
      final days = HijriDate.daysInMonth(_year, _month);
      _selectedDay =
          _isCurrentMonth ? _todayHijri.day : _selectedDay.clamp(1, days);
    });
  }

  void _goToday() {
    setState(() {
      _todayHijri = HijriDate.fromDate(DateTime.now());
      _year = _todayHijri.year;
      _month = _todayHijri.month;
      _selectedDay = _todayHijri.day;
    });
  }

  String _gregString(DateTime d) =>
      '${d.day} ${_gregMonths[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final firstGreg = _firstOfDisplayedMonth();
    final daysInMonth = HijriDate.daysInMonth(_year, _month);
    // Saturday-first offset: weekday Mon=1..Sun=7, Sat=6 -> 0.
    final offset = (firstGreg.weekday + 1) % 7;
    final selectedGreg =
        firstGreg.add(Duration(days: _selectedDay - 1));
    final selectedHijri = HijriDate(_year, _month, _selectedDay);
    final selectedNotable = _notableDays['$_month-$_selectedDay'];

    final monthNotables = _notableDays.entries
        .where((e) => int.parse(e.key.split('-')[0]) == _month)
        .map((e) => (int.parse(e.key.split('-')[1]), e.value))
        .toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));

    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TitleRow(
                  title: tr('calendar'),
                  subtitle: _todayHijri.toString(),
                ),
                const SizedBox(height: 20),
                // Month navigation.
                Row(
                  children: [
                    GlassCard(
                      radius: 16,
                      padding: const EdgeInsets.all(8),
                      onTap: () => _shiftMonth(-1),
                      child: Icon(Icons.chevron_left_rounded,
                          size: 22, color: p.emerald),
                    ),
                    Expanded(
                      child: Text(
                        '${HijriDate.months[_month - 1]} $_year AH',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                    ),
                    GlassCard(
                      radius: 16,
                      padding: const EdgeInsets.all(8),
                      onTap: () => _shiftMonth(1),
                      child: Icon(Icons.chevron_right_rounded,
                          size: 22, color: p.emerald),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GlassCard(
                    radius: 16,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    onTap: _goToday,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.today_rounded, size: 18, color: p.emerald),
                        const SizedBox(width: 6),
                        Text(
                          tr('today'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Weekday header.
                      Row(
                        children: [
                          for (final d in _weekdays)
                            Expanded(
                              child: Text(
                                d,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: p.muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1,
                        ),
                        itemCount: offset + daysInMonth,
                        itemBuilder: (context, i) {
                          if (i < offset) return const SizedBox.shrink();
                          final day = i - offset + 1;
                          final isToday =
                              _isCurrentMonth && day == _todayHijri.day;
                          final isSelected = day == _selectedDay;
                          final notable = _notableDays.containsKey('$_month-$day');
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDay = day),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday
                                    ? p.emerald
                                    : isSelected
                                        ? p.activeFill
                                        : Colors.transparent,
                                border: isSelected && !isToday
                                    ? Border.all(color: p.gold, width: 1.5)
                                    : null,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    '$day',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isToday || isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: isToday ? p.onEmerald : p.ink,
                                    ),
                                  ),
                                  if (notable)
                                    Positioned(
                                      bottom: 6,
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isToday ? p.champagne : p.gold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Selected day detail.
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event_rounded, size: 20, color: p.gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedHijri.toString(),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '= ${_gregString(selectedGreg)}',
                        style: TextStyle(fontSize: 14.5, color: p.muted),
                      ),
                      if (selectedNotable != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 18, color: p.gold),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                selectedNotable,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: p.emerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Notable days of this month.
                if (monthNotables.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SectionLabel('Notable days'),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (var i = 0; i < monthNotables.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: p.gold.withValues(alpha: 0.25),
                            ),
                          ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.activeFill,
                              ),
                              child: Text(
                                '${monthNotables[i].$1}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: p.emerald,
                                ),
                              ),
                            ),
                            title: Text(
                              monthNotables[i].$2,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                            subtitle: Text(
                              _gregString(firstGreg.add(Duration(
                                  days: monthNotables[i].$1 - 1))),
                              style: TextStyle(color: p.muted),
                            ),
                            onTap: () => setState(
                                () => _selectedDay = monthNotables[i].$1),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'This is the civil (Kuwaiti algorithm) Hijri calendar. '
                  'Dates may differ by a day from moon-sighting calendars.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: p.muted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
