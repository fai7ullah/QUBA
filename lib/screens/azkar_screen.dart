import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../azkar_data.dart';
import '../content.dart';
import '../i18n.dart';
import '../notifications.dart';
import '../theme.dart';
import '../widgets.dart';

/// Morning / evening / after-prayer Azkar with tap counters, a per-day
/// "done" mark that feeds the streak, and optional daily reminders.
/// Taps are saved as you go (debounced), so leaving the screen never
/// loses today's progress.
class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key, this.initialSet});
  final String? initialSet;

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  late String _set;

  @override
  void initState() {
    super.initState();
    _set = widget.initialSet ??
        (DateTime.now().hour < 12 ? 'morning' : 'evening');
  }

  int _doneItems(List<ResolvedAzkar> items) {
    var n = 0;
    for (final r in items) {
      if (appState.azkarTaps(_set, r.index) >= r.count) n++;
    }
    return n;
  }

  void _tap(ResolvedAzkar r, List<ResolvedAzkar> items) {
    final before = appState.azkarTaps(_set, r.index);
    if (before >= r.count) return;
    final after = appState.azkarTap(_set, r.index, r.count);
    if (after >= r.count) {
      HapticFeedback.mediumImpact();
      // Last item completed -> mark the set done for today.
      if (_doneItems(items) == items.length) {
        appState.setAzkarDone(DateTime.now(), _set, true);
      }
    } else {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _toggleReminder(bool morning, bool on) async {
    if (on) {
      final ok =
          await NotificationService.instance.requestNotificationPermission();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('azkar_perm_denied'))),
        );
        return;
      }
    }
    appState.update(() {
      if (morning) {
        appState.azkarMorningNotify = on;
      } else {
        appState.azkarEveningNotify = on;
      }
    });
    await NotificationService.instance.scheduleAzkar(appState);
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, _) {
              final items = AzkarData.resolve(_set);
              final done = _doneItems(items);
              final today = DateTime.now();
              final setDone = appState.isAzkarDone(today, _set);
              return ListView(
                primary: false,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  TitleRow(
                    title: tr('azkar'),
                    subtitle: tr('azkar_subtitle'),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      for (final s in AzkarData.sets)
                        ButtonSegment(
                          value: s.id,
                          label: Text(tr(s.titleKey),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    selected: {_set},
                    onSelectionChanged: (v) => setState(() => _set = v.first),
                  ),
                  const SizedBox(height: 14),
                  _summaryCard(p, items, done, setDone),
                  const SizedBox(height: 12),
                  for (final r in items) ...[
                    _itemCard(p, r, items),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 4),
                  _remindersCard(p),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
      QubaPalette p, List<ResolvedAzkar> items, int done, bool setDone) {
    final streak = appState.azkarStreak;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                setDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: setDone ? p.emerald : p.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  setDone
                      ? tr('azkar_done_today')
                      : trf('azkar_progress',
                          {'done': done, 'total': items.length}),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ),
              if (streak > 0) ...[
                const SizedBox(width: 8),
                Icon(Icons.local_fire_department_rounded,
                    size: 18, color: p.gold),
                const SizedBox(width: 2),
                Text(
                  '$streak',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: p.ink),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: items.isEmpty ? 0 : done / items.length,
              minHeight: 6,
              backgroundColor: p.gold.withValues(alpha: 0.2),
              color: p.emerald,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: setDone
                    ? TextButton(
                        onPressed: () {
                          appState.setAzkarDone(DateTime.now(), _set, false);
                        },
                        child: Text(tr('azkar_undo')),
                      )
                    : FilledButton.tonal(
                        onPressed: () {
                          appState.setAzkarDone(DateTime.now(), _set, true);
                          HapticFeedback.mediumImpact();
                        },
                        child: Text(tr('azkar_mark_done')),
                      ),
              ),
              if (done > 0) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => appState.azkarResetSet(_set),
                  child: Text(tr('azkar_reset')),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemCard(
      QubaPalette p, ResolvedAzkar r, List<ResolvedAzkar> items) {
    final taps = appState.azkarTaps(_set, r.index);
    final remaining = r.count - taps;
    final complete = remaining <= 0;
    final arabic = duaArabic(r.dua);
    return GlassCard(
      onTap: complete ? null : () => _tap(r, items),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr(r.dua.title),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: p.emerald,
            ),
          ),
          if (arabic.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              arabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 24,
                height: 1.9,
                color: p.ink,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            r.dua.english,
            style: TextStyle(fontSize: 13.5, height: 1.45, color: p.ink),
          ),
          const SizedBox(height: 6),
          Text(
            r.dua.source,
            style: TextStyle(fontSize: 12, color: p.muted),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: complete
                  ? p.emerald.withValues(alpha: 0.15)
                  : p.gold.withValues(alpha: 0.16),
              border: Border.all(
                color: complete ? p.emerald : p.gold.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  complete
                      ? Icons.check_circle_rounded
                      : Icons.touch_app_rounded,
                  color: complete ? p.emerald : p.gold,
                ),
                const SizedBox(width: 8),
                Text(
                  complete
                      ? tr('azkar_item_done')
                      : trf('azkar_taps_left',
                          {'left': remaining, 'total': r.count}),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: complete ? p.emerald : p.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _remindersCard(QubaPalette p) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('azkar_reminders'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tr('azkar_reminders_hint'),
            style: TextStyle(fontSize: 12.5, color: p.muted),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('azkar_morning')),
            value: appState.azkarMorningNotify,
            onChanged: (v) => _toggleReminder(true, v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('azkar_evening')),
            value: appState.azkarEveningNotify,
            onChanged: (v) => _toggleReminder(false, v),
          ),
        ],
      ),
    );
  }
}
