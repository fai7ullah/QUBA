import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app_state.dart';
import '../data.dart';
import '../homewidget/home_widget_service.dart';
import '../i18n.dart';
import '../notifications.dart';
import '../reciters.dart';
import '../sync/backup_service.dart';
import '../theme.dart';
import '../translation_data.dart';
import '../widgets.dart';
import 'calc_settings.dart';

/// Settings tab: theme, language, text, prayer calculation, location,
/// reminders, feature links, backup, about.
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
      await HomeWidgetService.update(appState);
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
        // NOT primary: see home_screen.dart — each tab owns its scroll
        // state instead of sharing the route's PrimaryScrollController
        // across the IndexedStack (2026-11-21: this list scrolled down
        // and would not scroll back up on the owner's phone).
        primary: false,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: p.ink)),
                    ),
                    DropdownButton<String>(
                      value: appState.lang,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final l in QubaStrings.allLangs)
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                // Reciter: label-above-control, like Theme — the
                // dropdown holds long names ("Abdul Basit Abdul Samad")
                // and would squeeze the label to one letter wide if it
                // shared the row (seen 2026-11-17: "Reciter" wrapped
                // mid-word, "Translation" went vertical).
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.record_voice_over_rounded,
                            color: p.emerald),
                        const SizedBox(width: 12),
                        Text(tr('reciter'),
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: p.ink)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: appState.reciterId,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final r in reciters)
                          DropdownMenuItem(
                            value: r.id,
                            child: Text(tr(r.nameKey)),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) appState.setReciter(v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Translation: same label-above-control layout.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.translate_rounded, color: p.emerald),
                        const SizedBox(width: 12),
                        Text(tr('translation'),
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: p.ink)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: appState.translationId,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final id in TranslationRepository.ids)
                          DropdownMenuItem(
                            value: id,
                            child: Text(tr(TranslationRepository
                                .labelKeyFor(id))),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) appState.setTranslation(v);
                      },
                    ),
                  ],
                ),
                if (!TranslationRepository.instance
                    .isAvailable(appState.translationId))
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      tr('translation_unavailable'),
                      style: TextStyle(fontSize: 12, color: p.muted),
                    ),
                  ),
              ],
            ),
          ),
          _section(context, tr('calculation')),
          const CalcSettingsCard(),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                        // One line + ellipsis: the Farsi label ("از مکان
                        // من استفاده کن") is wider than its half-width
                        // slot at 320px and overflowed the button.
                        label: Text(
                          tr('use_my_location'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => _useGps(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.location_city_rounded),
                        label: Text(
                          tr('kabul_default'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                const _NotificationStatusCard(),
                const SizedBox(height: 8),
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
                const SizedBox(height: 6),
                Text(
                  tr('oppo_battery_note'),
                  style: TextStyle(fontSize: 12.5, color: p.muted),
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
          _section(context, tr('backup_title')),
          const _BackupCard(),
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

/// Local backup & restore (fully offline file export/import, no
/// account). Moved here from the deleted Sync screen when cloud sync
/// was removed (2026-11-21, owner's order): the backup itself stays,
/// only the cloud part went.
class _BackupCard extends StatefulWidget {
  const _BackupCard();

  @override
  State<_BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends State<_BackupCard> {
  bool _busy = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _run(Future<BackupResult> Function() op) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await op();
      _snack(result.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('backup_subtitle'),
            style: TextStyle(fontSize: 13.5, color: p.muted),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(BackupService.instance.exportToFile),
            icon: const Icon(Icons.upload_rounded),
            label: Text(
              tr('backup_export'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: p.emerald,
              foregroundColor: p.onEmerald,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(BackupService.instance.importFromPicker),
            icon: const Icon(Icons.download_rounded),
            label: Text(
              tr('backup_import'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Round 4: live notification permission + scheduling status. The 7-day
/// Athan soak test failed at day 3 with NO notifications at all on the
/// owner's OPPO, so this card makes the state visible instead of failing
/// silently: whether notifications + exact alarms are granted, how many
/// alerts are scheduled, a 1-minute test button, and the way to fix a
/// blocked state (request again, or open the system settings).
class _NotificationStatusCard extends StatefulWidget {
  const _NotificationStatusCard();

  @override
  State<_NotificationStatusCard> createState() =>
      _NotificationStatusCardState();
}

class _NotificationStatusCardState extends State<_NotificationStatusCard> {
  late Future<NotificationPermissionState> _future;

  /// Last ScheduleResult seen: when scheduleAll runs elsewhere (a
  /// prayer toggle), a new result instance appears and the card
  /// re-queries so the count stays fresh.
  ScheduleResult? _seenResult;

  @override
  void initState() {
    super.initState();
    _future = NotificationService.instance.permissionState();
    _seenResult = NotificationService.instance.lastResult;
  }

  void _refresh() {
    setState(() {
      _future = NotificationService.instance.permissionState();
      _seenResult = NotificationService.instance.lastResult;
    });
  }

  Future<void> _requestNotifications() async {
    final ok =
        await NotificationService.instance.requestNotificationPermission();
    _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(ok ? tr('notif_now_on') : tr('notif_still_off'))),
    );
  }

  Future<void> _requestExactAlarms() async {
    final ok =
        await NotificationService.instance.requestExactAlarmPermission();
    _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            ok ? tr('exact_alarms_allowed') : tr('exact_alarm_denied')),
      ),
    );
  }

  Future<void> _sendTest() async {
    final ok = await NotificationService.instance.sendTestNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(ok ? tr('notif_test_sent') : tr('notif_test_failed'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    // A new schedule result (e.g. after a prayer toggle) means the
    // count below changed: re-query the live state in this build.
    final current = NotificationService.instance.lastResult;
    if (!identical(current, _seenResult)) {
      _seenResult = current;
      _future = NotificationService.instance.permissionState();
    }
    return FutureBuilder<NotificationPermissionState>(
      future: _future,
      builder: (context, snap) {
        final state = snap.data;
        final notifOk = state?.notificationsEnabled ?? true;
        final exactOk = state?.exactAlarmsEnabled ?? false;
        final result = NotificationService.instance.lastResult;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusRow(
              context,
              icon: Icons.notifications_rounded,
              label: tr('notif_permission'),
              granted: notifOk,
              loading: snap.connectionState == ConnectionState.waiting,
            ),
            const SizedBox(height: 6),
            _statusRow(
              context,
              icon: Icons.alarm_rounded,
              label: tr('exact_alarm_permission'),
              granted: exactOk,
              loading: snap.connectionState == ConnectionState.waiting,
            ),
            if (result != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.event_available_rounded,
                      size: 20, color: p.emerald),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.failed > 0
                          ? tr('notif_some_failed')
                          : result.scheduled > 0
                              ? trf('notif_scheduled_n',
                                  {'count': result.scheduled})
                              : tr('notif_none_scheduled'),
                      style: TextStyle(fontSize: 13.5, color: p.muted),
                    ),
                  ),
                ],
              ),
            ],
            if (!notifOk) ...[
              const SizedBox(height: 8),
              Text(
                tr('notif_blocked_warning'),
                style: TextStyle(fontSize: 13, color: p.muted),
              ),
            ],
            const SizedBox(height: 10),
            if (!notifOk)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: Text(
                    tr('allow_notifications'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: _requestNotifications,
                ),
              ),
            if (!notifOk) const SizedBox(height: 8),
            if (!exactOk)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.alarm_rounded),
                  label: Text(
                    tr('allow_exact_alarms'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: _requestExactAlarms,
                ),
              ),
            if (!exactOk) const SizedBox(height: 8),
            if (!notifOk || !exactOk)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.settings_rounded),
                  label: Text(
                    tr('notif_open_settings'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: AppSettings.openAppSettings,
                ),
              ),
            if (!notifOk || !exactOk) const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.science_rounded),
                label: Text(
                  tr('notif_test'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _sendTest,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statusRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool granted,
    required bool loading,
  }) {
    final p = QubaPalette.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: p.emerald),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w600, color: p.ink),
          ),
        ),
        if (loading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                granted
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 18,
                color: granted ? p.emerald : Colors.red.shade700,
              ),
              const SizedBox(width: 5),
              Text(
                granted ? tr('notif_allowed') : tr('notif_blocked'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: granted ? p.emerald : Colors.red.shade700,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
