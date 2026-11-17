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
