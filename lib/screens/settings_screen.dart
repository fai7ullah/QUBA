import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app_state.dart';
import '../data.dart';
import '../i18n.dart';
import '../notifications.dart';
import '../theme.dart';
import '../widgets.dart';

/// Settings tab: theme, language, text, prayer calculation, location,
/// reminders, feature links, about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.onOpenFeature});
  final void Function(String key) onOpenFeature;

  Future<void> _useGps(BuildContext context) async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(tr('loc_permission_denied'))));
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 20));
      appState.update(() {
        appState.lat = pos.latitude;
        appState.lng = pos.longitude;
        appState.locationName = 'My location (GPS)';
        appState.locationIsGps = true;
      });
      await NotificationService.instance.scheduleAll(appState);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('loc_updated_gps'))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(trf('loc_error', {'error': '$e'}))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          _section(context, tr('appearance')),
          GlassCard(
            child: Column(
              children: [
                // Label on its own line: the three-segment control is
                // too wide to share the row — it used to starve the
                // label to one character wide ("Theme" rendered as
                // T/h/e/m/e, one letter per line).
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.brightness_6_rounded, color: p.emerald),
                        const SizedBox(width: 12),
                        Text(tr('theme'),
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: p.ink)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                            value: ThemeMode.system,
                            label: Text(tr('theme_auto'))),
                        ButtonSegment(
                            value: ThemeMode.light,
                            label: Text(tr('theme_light'))),
                        ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text(tr('theme_dark'))),
                      ],
                      selected: {appState.themeMode},
                      onSelectionChanged: (s) =>
                          appState.update(() => appState.themeMode = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Mushaf style: same label-above-control layout as Theme —
                // the two-segment control is too wide to share the row.
                // The IndoPak choice is only offered when the IndoPak text
                // actually loaded (QuranRepository.indopakAvailable); if
                // the asset is missing the whole control is disabled and a
                // note says so, so the style can never point at text that
                // isn't there.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded, color: p.emerald),
                        const SizedBox(width: 12),
                        Text(tr('mushaf_style'),
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: p.ink)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                            value: 'madani',
                            label: Text(tr('madani'))),
                        ButtonSegment(
                            value: 'indopak',
                            label: Text(tr('indopak'))),
                      ],
                      selected: {appState.mushafStyle},
                      onSelectionChanged:
                          QuranRepository.instance.indopakAvailable
                              ? (s) => appState.update(
                                  () => appState.mushafStyle = s.first)
                              : null,
                    ),
                    if (!QuranRepository.instance.indopakAvailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          tr('indopak_unavailable'),
                          style: TextStyle(fontSize: 12, color: p.muted),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.language_rounded, color: p.emerald),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(tr('language'),
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: p.ink)),
                    ),
                    DropdownButton<String>(
                      value: appState.lang,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final l in QubaStrings.langs)
                          DropdownMenuItem(
                            value: l,
                            child: Text(QubaStrings.langNames[l]!),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          appState.update(() => appState.lang = v);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.text_fields_rounded, color: p.emerald),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(tr('arabic_text_size'),
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: p.ink)),
                    ),
                    Text('${appState.arabicFontSize.round()}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: p.ink)),
                  ],
                ),
                Slider(
                  value: appState.arabicFontSize,
                  min: 20,
                  max: 46,
                  divisions: 26,
                  label: appState.arabicFontSize.round().toString(),
                  onChanged: (v) =>
                      appState.update(() => appState.arabicFontSize = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary:
                      Icon(Icons.translate_rounded, color: p.emerald),
                  title: Text(tr('show_translation')),
                  subtitle: Text(tr('translation_pickthall')),
                  value: appState.showTranslation,
                  onChanged: (v) =>
                      appState.update(() => appState.showTranslation = v),
                ),
              ],
            ),
          ),
          _section(context, tr('calculation')),
          GlassCard(
            child: Column(
              children: [
                RadioGroup<String>(
                  groupValue: appState.calcMethod,
                  onChanged: (v) async {
                    if (v == null) return;
                    appState.update(() => appState.calcMethod = v);
                    await NotificationService.instance.scheduleAll(appState);
                  },
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Muslim World League'),
                        subtitle: Text(
                            '${trPrayer('Fajr')} 18° • ${trPrayer('Isha')} 17°'),
                        value: 'mwl',
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                            'Univ. of Islamic Sciences, Karachi'),
                        subtitle: Text(
                            '${trPrayer('Fajr')} 18° • ${trPrayer('Isha')} 18°'),
                        value: 'karachi',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                RadioGroup<bool>(
                  groupValue: appState.asrHanafi,
                  onChanged: (v) async {
                    if (v == null) return;
                    appState.update(() => appState.asrHanafi = v);
                    await NotificationService.instance.scheduleAll(appState);
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
              ],
            ),
          ),
          _section(context, tr('location')),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: p.emerald),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trLocation(appState.locationName),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: p.ink)),
                          Text(
                            '${appState.lat.toStringAsFixed(4)}, ${appState.lng.toStringAsFixed(4)}',
                            style:
                                TextStyle(fontSize: 13, color: p.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.my_location_rounded),
                        label: Text(tr('use_my_location')),
                        onPressed: () => _useGps(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.location_city_rounded),
                        label: Text(tr('kabul_default')),
                        onPressed: () async {
                          appState.update(() {
                            appState.lat = AppState.kabulLat;
                            appState.lng = AppState.kabulLng;
                            appState.locationName = 'Kabul (default)';
                            appState.locationIsGps = false;
                          });
                          await NotificationService.instance
                              .scheduleAll(appState);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _section(context, tr('reminders')),
          GlassCard(
            child: Column(
              children: [
                for (final name in [
                  'Fajr',
                  'Sunrise',
                  'Dhuhr',
                  'Asr',
                  'Maghrib',
                  'Isha',
                ])
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: PrayerMedallion(
                      icon: prayerIcon(name),
                      size: 34,
                    ),
                    title: Text(trPrayer(name)),
                    value: appState.prayerNotify[name] ?? false,
                    onChanged: (v) async {
                      appState.update(
                          () => appState.prayerNotify[name] = v);
                      await NotificationService.instance
                          .scheduleAll(appState);
                    },
                  ),
                const SizedBox(height: 6),
                Text(
                  tr('exact_alarm_note'),
                  style: TextStyle(fontSize: 12.5, color: p.muted),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.alarm_rounded),
                    label: Text(tr('allow_exact_alarms')),
                    onPressed: () async {
                      final ok = await NotificationService.instance
                          .requestExactAlarmPermission();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? tr('exact_alarms_allowed')
                                : tr('exact_alarm_denied')),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          _section(context, tr('features')),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Column(
              children: [
                for (final f in [
                  (Icons.explore_rounded, tr('qibla'), 'qibla'),
                  (Icons.calendar_month_rounded, tr('calendar'), 'calendar'),
                  (Icons.flag_rounded, tr('khatma'), 'khatma'),
                  (
                    Icons.volunteer_activism_rounded,
                    tr('duas'),
                    'duas',
                  ),
                  (Icons.auto_awesome_rounded, tr('names99'), 'names'),
                  (Icons.blur_circular_rounded, tr('tasbih'), 'tasbih'),
                  (Icons.search_rounded, tr('search_quran'), 'search'),
                ])
                  ListTile(
                    leading: Icon(f.$1, color: p.emerald),
                    title: Text(f.$2),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: p.muted),
                    onTap: () => onOpenFeature(f.$3),
                  ),
              ],
            ),
          ),
          _section(context, tr('about')),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QUBA v1.0 (Flutter)',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: p.ink)),
                const SizedBox(height: 8),
                Text(
                  "${tr('about_text')}\n"
                  '9665930bd9eb8ccc2535d80b68ddd53c7c3ff55a86d19e9b50cbcf7da46a0a1f',
                  style:
                      TextStyle(height: 1.5, fontSize: 13, color: p.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: QubaPalette.of(context).ink,
        ),
      ),
    );
  }
}
