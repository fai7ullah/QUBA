import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../homewidget/home_widget_service.dart';
import '../i18n.dart';
import '../notifications.dart';
import '../prayer_calc.dart';
import '../prayer_service.dart';
import '../theme.dart';
import '../widgets.dart';

/// Debounced "prayer times changed" refresh: re-registers the Athan
/// alerts (and the Azkar reminders) and updates the home-screen widget.
/// Debounced because the +/- buttons can be tapped quickly and every
/// reschedule cancels and re-registers dozens of alarms. Lives outside
/// any widget so leaving the screen never loses a pending refresh.
class PrayerReschedule {
  PrayerReschedule._();
  static Timer? _timer;

  static void request() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 700), () async {
      try {
        await NotificationService.instance.scheduleAll(appState);
        await HomeWidgetService.update(appState);
      } catch (_) {
        // Best-effort: the next app start re-registers everything.
      }
    });
  }
}

/// The "Calculation" card in Settings: method, Asr, high-latitude rule,
/// per-prayer minute adjustments and the Hijri date correction.
class CalcSettingsCard extends StatelessWidget {
  const CalcSettingsCard({super.key});

  static const _highLatKeys = {
    'auto': 'high_lat_auto',
    'midnight': 'high_lat_midnight',
    'oneseventh': 'high_lat_seventh',
    'anglebased': 'high_lat_angle',
  };

  static const _prayers = [
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  static String _angleText(PrayerMethod m) {
    final fajr = m.fajr == m.fajr.roundToDouble()
        ? m.fajr.toInt().toString()
        : m.fajr.toString();
    if (m.ishaMinutes > 0) {
      return '${trPrayer('Fajr')} $fajr° • '
          '${trf('isha_minutes_after', {'min': m.ishaMinutes})}';
    }
    final isha = m.isha == m.isha.roundToDouble()
        ? m.isha.toInt().toString()
        : m.isha.toString();
    return '${trPrayer('Fajr')} $fajr° • ${trPrayer('Isha')} $isha°';
  }

  void _changed() => PrayerReschedule.request();

  Future<void> _suggest(BuildContext context) async {
    final id = PrayerMethod.suggestFor(appState.lat, appState.lng);
    final m = PrayerMethod.byId(id);
    if (id == appState.calcMethod) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trf('calc_suggest_same', {'method': m.name}))),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('calc_suggest')),
        content: Text(trf('calc_suggest_body', {'method': m.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('use_it')),
          ),
        ],
      ),
    );
    if (ok == true) {
      appState.update(() => appState.calcMethod = id);
      _changed();
    }
  }

  Widget _stepper(
    QubaPalette p, {
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    String suffix = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w600, color: p.ink),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: p.emerald,
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${value > 0 ? '+' : ''}$value$suffix',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: value == 0 ? p.muted : p.ink,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: p.emerald,
            onPressed: value < max ? () => onChanged(value + 1) : null,
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
        final method = PrayerMethod.byId(appState.calcMethod);
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Method ----
              Text(tr('calc_method'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: p.muted)),
              DropdownButton<String>(
                isExpanded: true,
                value: method.id,
                underline: const SizedBox.shrink(),
                items: [
                  for (final m in PrayerMethod.all)
                    DropdownMenuItem(
                      value: m.id,
                      child: Text(m.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  appState.update(() => appState.calcMethod = v);
                  _changed();
                },
              ),
              Text(_angleText(method),
                  style: TextStyle(fontSize: 13, color: p.muted)),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => _suggest(context),
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(tr('calc_suggest')),
                ),
              ),
              const Divider(height: 1),
              // ---- Asr ----
              RadioGroup<bool>(
                groupValue: appState.asrHanafi,
                onChanged: (v) {
                  if (v == null) return;
                  appState.update(() => appState.asrHanafi = v);
                  _changed();
                },
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          "${trPrayer('Asr')} — ${tr('madhab_hanafi')}"),
                      subtitle: Text(tr('asr_hanafi_sub')),
                      value: true,
                    ),
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          "${trPrayer('Asr')} — ${tr('madhab_shafii')}"),
                      subtitle: Text(tr('asr_shafii_sub')),
                      value: false,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // ---- High latitude ----
              const SizedBox(height: 10),
              Text(tr('high_lat'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: p.muted)),
              DropdownButton<String>(
                isExpanded: true,
                value: appState.highLatRule,
                underline: const SizedBox.shrink(),
                items: [
                  for (final e in _highLatKeys.entries)
                    DropdownMenuItem(
                      value: e.key,
                      child: Text(tr(e.value),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  appState.update(() => appState.highLatRule = v);
                  _changed();
                },
              ),
              Text(tr('high_lat_hint'),
                  style: TextStyle(fontSize: 12.5, color: p.muted)),
              const SizedBox(height: 6),
              const Divider(height: 1),
              // ---- Per-prayer minutes ----
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(tr('adjust_minutes'),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: p.ink)),
                  subtitle: Text(tr('adjust_hint'),
                      style: TextStyle(fontSize: 12.5, color: p.muted)),
                  children: [
                    for (var i = 0; i < _prayers.length; i++)
                      _stepper(
                        p,
                        label: trPrayer(_prayers[i]),
                        value: appState.prayerAdjust[i],
                        min: -30,
                        max: 30,
                        suffix: ' ${tr('minutes_short')}',
                        onChanged: (v) {
                          appState.update(() {
                            final next = List<int>.from(appState.prayerAdjust);
                            next[i] = v;
                            appState.prayerAdjust = next;
                          });
                          _changed();
                        },
                      ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: appState.prayerAdjust.every((e) => e == 0)
                            ? null
                            : () {
                                appState.update(() => appState.prayerAdjust =
                                    [0, 0, 0, 0, 0, 0]);
                                _changed();
                              },
                        child: Text(tr('reset_all')),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // ---- Hijri correction ----
              const SizedBox(height: 8),
              _stepper(
                p,
                label: tr('hijri_adjust'),
                value: appState.hijriOffset,
                min: -2,
                max: 2,
                suffix: ' ${tr('days_short')}',
                onChanged: (v) {
                  appState.update(() => appState.hijriOffset = v);
                },
              ),
              Text(
                '${PrayerService.hijriString(DateTime.now())}  •  '
                '${tr('hijri_adjust_hint')}',
                style: TextStyle(fontSize: 12.5, color: p.muted),
              ),
            ],
          ),
        );
      },
    );
  }
}
