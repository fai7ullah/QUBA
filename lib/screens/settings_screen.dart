import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app_state.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Location permission not granted — keeping current location')));
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
            const SnackBar(content: Text('Location updated from GPS')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not get location: $e')));
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
                        Text('Theme',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: p.ink)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                      ],
                      selected: {appState.themeMode},
                      onSelectionChanged: (s) =>
                          appState.update(() => appState.themeMode = s.first),
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
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 36),
                  child: Text(
                    'Pashto, Dari and Urdu translations are drafts awaiting correction.',
                    style: TextStyle(fontSize: 12, color: p.muted),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.text_fields_rounded, color: p.emerald),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Arabic text size',
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
                  title: const Text('Show translation'),
                  subtitle:
                      const Text('English — Pickthall (test build)'),
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
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Muslim World League'),
                        subtitle: Text('Fajr 18° • Isha 17°'),
                        value: 'mwl',
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Univ. of Islamic Sciences, Karachi'),
                        subtitle: Text('Fajr 18° • Isha 18°'),
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
                  child: const Column(
                    children: [
                      RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Asr — Hanafi'),
                        subtitle: Text('Shadow = twice the object (default)'),
                        value: true,
                      ),
                      RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        title: Text("Asr — Shafi'i"),
                        subtitle: Text('Shadow = the object itself'),
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
                          Text(appState.locationName,
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
                        label: const Text('Use my location'),
                        onPressed: () => _useGps(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.location_city_rounded),
                        label: const Text('Kabul default'),
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
                    title: Text(name),
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
                  'Athan alerts need the exact-alarm permission. On OPPO, '
                  'Samsung and Xiaomi phones also allow QUBA to run in the '
                  'background (battery settings) so alerts are not delayed.',
                  style: TextStyle(fontSize: 12.5, color: p.muted),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.alarm_rounded),
                    label: const Text('Allow exact alarms'),
                    onPressed: () async {
                      final ok = await NotificationService.instance
                          .requestExactAlarmPermission();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Exact alarms allowed'
                                : 'Exact-alarm permission was not granted'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          _section(context, 'Features'),
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
                  'Quran text: Uthmani script, Tanzil edition via AlQuran Cloud '
                  '(quran-uthmani) — 114 surahs, 6,236 verses, verified.\n'
                  'Translation: Mohammed Marmaduke Pickthall (public domain) — '
                  'test build only; the release translation set is being licensed.\n'
                  'Audio: Mishary Alafasy, Islamic Network / EveryAyah CDN.\n'
                  'Prayer times: calculated on this device (ported PrayTimes algorithm).\n\n'
                  'Bundled Quran data SHA-256:\n'
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
