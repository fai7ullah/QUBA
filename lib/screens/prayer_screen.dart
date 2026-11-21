import 'package:flutter/material.dart';

import '../app_state.dart';
import '../i18n.dart';
import '../notifications.dart';
import '../prayer_service.dart';
import '../theme.dart';
import '../widgets.dart';

/// Prayer tab: browse any day's times, toggle Athan reminders,
/// see how times are calculated.
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  int _dayOffset = 0;

  Future<void> _toggleNotify(String name, bool enabled) async {
    appState.update(() => appState.prayerNotify[name] = enabled);
    await NotificationService.instance.scheduleAll(appState);
  }

  /// Today's 5 prayers with tap-to-toggle checks, a prayed count, and
  /// a 7-day strip (oldest first) of daily prayed counts.
  Widget _prayerLogCard(
      BuildContext context, QubaPalette p, List<PrayerEntry> entries) {
    final today = DateTime.now();
    const five = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final last7 = appState.prayedLast7Days();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, color: p.gold, size: 20),
              const SizedBox(width: 8),
              // Expanded + ellipsis: two unprotected Texts with a
              // Spacer between them is the squeeze defect class — a
              // long label in another language starved the count (or
              // vice versa) and overflowed the row.
              Expanded(
                child: Text(
                  tr('prayer_log'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                trf('prayers_prayed_count',
                    {'count': appState.prayedCountOn(today)}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: p.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final name in five)
            _logRow(context, p, name, today, entries),
          const SizedBox(height: 12),
          Text(
            tr('this_week'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.muted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                _weekColumn(p, last7[i],
                    today.subtract(Duration(days: 6 - i)), i == 6),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logRow(BuildContext context, QubaPalette p, String name,
      DateTime today, List<PrayerEntry> entries) {
    final prayed = appState.isPrayed(today, name);
    PrayerEntry? entry;
    for (final e in entries) {
      if (e.name == name) entry = e;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => appState.togglePrayed(today, name),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                prayed
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 26,
                color: prayed ? p.emerald : p.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trPrayer(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        prayed ? FontWeight.w800 : FontWeight.w600,
                    color: p.ink,
                  ),
                ),
              ),
              if (entry != null)
                Text(
                  PrayerService.formatTime(entry.time),
                  style: TextStyle(fontSize: 14, color: p.muted),
                ),
              if (prayed) ...[
                const SizedBox(width: 8),
                Text(
                  tr('prayed'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p.emerald,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// One day of the week strip: count number, a bar sized by the
  /// count (0–5), and a one-letter weekday label.
  Widget _weekColumn(
      QubaPalette p, int count, DateTime day, bool isToday) {
    final label = tr('weekday_abbr_${day.weekday}');
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: count > 0 ? p.emerald : p.muted,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 14,
            height: 8 + count * 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: count == 0
                  ? p.cardBorder
                  : p.emerald
                      .withValues(alpha: 0.35 + 0.13 * count),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.isEmpty ? '' : label[0],
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  isToday ? FontWeight.w800 : FontWeight.w600,
              color: isToday ? p.emerald : p.muted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final now = DateTime.now();
        final date = DateTime(now.year, now.month, now.day + _dayOffset);
        final entries = PrayerService.dayList(date, appState);
        final next = _dayOffset == 0
            ? PrayerService.nextPrayer(now, appState)
            : null;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          children: [
            Row(
              children: [
                GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(8),
                  onTap: () => setState(() => _dayOffset--),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: p.emerald,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _dayOffset == 0
                            ? tr('today')
                            : "${tr('weekday_${date.weekday}')}, ${date.day} ${tr('greg_month_short_${date.month}')} ${date.year}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        PrayerService.hijriString(date),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: p.muted),
                      ),
                    ],
                  ),
                ),
                GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(8),
                  onTap: () => setState(() => _dayOffset++),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: p.emerald,
                  ),
                ),
              ],
            ),
            if (_dayOffset != 0)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _dayOffset = 0),
                  child: Text(
                    tr('today'),
                    style: TextStyle(color: p.emerald),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            PrayerScheduleCard(
              entries: entries,
              nextName: next?.name,
              onToggle: _toggleNotify,
            ),
            // Today's prayer log: shown only on today's view, since the
            // log (and the week strip) is always about today.
            if (_dayOffset == 0) ...[
              const SizedBox(height: 16),
              _prayerLogCard(context, p, entries),
            ],
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate_outlined,
                          color: p.gold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        tr('calculation'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trf('prayer_info', {
                      'method': PrayerService.methodLabel(appState),
                      'madhab': PrayerService.madhabLabel(appState),
                      'location': trLocation(appState.locationName),
                      'coords':
                          '${appState.lat.toStringAsFixed(3)}, ${appState.lng.toStringAsFixed(3)}',
                    }),
                    style: TextStyle(
                      fontSize: 14,
                      color: p.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tr('prayer_bell_hint'),
              style: TextStyle(fontSize: 12.5, color: p.muted),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}
