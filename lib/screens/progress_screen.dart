import 'package:flutter/material.dart';

import '../app_state.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';
import 'azkar_screen.dart';

/// One achievement badge: earned when [current] reaches [target].
class BadgeDef {
  const BadgeDef(this.id, this.icon, this.titleKey, this.target, this.current);
  final String id;
  final IconData icon;

  /// i18n key with an `{n}` placeholder for [target].
  final String titleKey;
  final int target;
  final int current;

  bool get earned => current >= target;
  double get fraction =>
      target == 0 ? 1 : (current / target).clamp(0.0, 1.0).toDouble();
}

/// All badges, computed from the current app state (nothing extra is
/// stored: a badge is simply "has this number been reached").
List<BadgeDef> computeBadges(AppState s) {
  final prayer = s.prayerStreak;
  final reading = s.longestReadingStreak > s.readingStreak
      ? s.longestReadingStreak
      : s.readingStreak;
  final azkar = s.azkarStreak;
  final total = s.totalPrayed;
  final tasbih = s.tasbihLifetime;
  return [
    BadgeDef('prayer7', Icons.verified_rounded, 'badge_prayer_streak', 7, prayer),
    BadgeDef('prayer30', Icons.verified_rounded, 'badge_prayer_streak', 30, prayer),
    BadgeDef('read7', Icons.menu_book_rounded, 'badge_read_streak', 7, reading),
    BadgeDef('read30', Icons.menu_book_rounded, 'badge_read_streak', 30, reading),
    BadgeDef('azkar7', Icons.wb_twilight_rounded, 'badge_azkar_streak', 7, azkar),
    BadgeDef('total100', Icons.mosque_rounded, 'badge_total_prayers', 100, total),
    BadgeDef('total500', Icons.mosque_rounded, 'badge_total_prayers', 500, total),
    BadgeDef('tasbih1k', Icons.blur_circular_rounded, 'badge_tasbih', 1000, tasbih),
    BadgeDef('tasbih10k', Icons.blur_circular_rounded, 'badge_tasbih', 10000, tasbih),
  ];
}

/// Progress: three streaks, the week's prayers, an Azkar shortcut and
/// the badges. Everything is derived from data the app already keeps.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, _) {
              final badges = computeBadges(appState);
              final earned = badges.where((b) => b.earned).length;
              return ListView(
                primary: false,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  TitleRow(
                    title: tr('progress'),
                    subtitle: trf('badges_earned',
                        {'n': earned, 'total': badges.length}),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _statCard(p, Icons.verified_rounded,
                          appState.prayerStreak, tr('prayer_streak_label')),
                      const SizedBox(width: 10),
                      _statCard(p, Icons.local_fire_department_rounded,
                          appState.readingStreak, tr('reading_streak_label')),
                      const SizedBox(width: 10),
                      _statCard(p, Icons.wb_twilight_rounded,
                          appState.azkarStreak, tr('azkar_streak_label')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _weekCard(p),
                  const SizedBox(height: 14),
                  GlassCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const AzkarScreen()),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wb_twilight_rounded, color: p.gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr('azkar_open'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: p.muted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tr('badges'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 14),
                    child: Column(
                      children: [
                        for (var i = 0; i < badges.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: p.gold.withValues(alpha: 0.22),
                            ),
                          _badgeRow(p, badges[i]),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _statCard(QubaPalette p, IconData icon, int value, String label) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: value > 0 ? p.gold : p.muted, size: 26),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: p.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekCard(QubaPalette p) {
    final last7 = appState.prayedLast7Days();
    final total = last7.fold<int>(0, (a, b) => a + b);
    final now = DateTime.now();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('this_week'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            trf('week_summary', {'done': total, 'total': 35}),
            style: TextStyle(fontSize: 13, color: p.muted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _bar(
                      p,
                      last7[i],
                      now.subtract(Duration(days: 6 - i)).weekday,
                      i == 6,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(QubaPalette p, int count, int weekday, bool isToday) {
    final label = tr('weekday_abbr_$weekday');
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: count > 0 ? p.emerald : p.muted,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 16,
          height: 6 + count * 9.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: count == 0
                ? p.cardBorder
                : p.emerald.withValues(alpha: count >= 5 ? 1 : 0.35 + 0.12 * count),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label.isEmpty ? '' : label.substring(0, 1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: isToday ? p.ink : p.muted,
          ),
        ),
      ],
    );
  }

  Widget _badgeRow(QubaPalette p, BadgeDef b) {
    final color = b.earned ? p.gold : p.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: b.earned ? 0.2 : 0.1),
              border: Border.all(color: color.withValues(alpha: 0.7)),
            ),
            child: Icon(b.icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trf(b.titleKey, {'n': b.target}),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: b.earned ? p.ink : p.muted,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: b.fraction,
                    minHeight: 5,
                    backgroundColor: p.gold.withValues(alpha: 0.18),
                    color: b.earned ? p.gold : p.emerald,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (b.earned)
            Icon(Icons.check_circle_rounded, color: p.emerald)
          else
            Text(
              '${b.current > b.target ? b.target : b.current}/${b.target}',
              style: TextStyle(fontSize: 12.5, color: p.muted),
            ),
        ],
      ),
    );
  }
}
