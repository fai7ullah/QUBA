import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app_state.dart';
import 'i18n.dart';
import 'prayer_service.dart';

/// Result of a [NotificationService.scheduleAll] run. Scheduling never
/// fails silently: the caller (and the Settings screen) can see exactly
/// what happened.
/// - [scheduled]: alerts actually registered.
/// - [failed]: prayers that could not be scheduled at all.
/// - [exactAlarms]: whether exact alarms were used (false = fell back
///   to inexact scheduling because the exact-alarm permission is off).
class ScheduleResult {
  const ScheduleResult({
    required this.scheduled,
    required this.failed,
    required this.exactAlarms,
  });
  final int scheduled;
  final int failed;
  final bool exactAlarms;

  bool get ok => failed == 0 && scheduled > 0;
}

/// Permission state for the Settings screen. Both flags come from live
/// platform queries, never from cached guesses.
class NotificationPermissionState {
  const NotificationPermissionState({
    required this.notificationsEnabled,
    required this.exactAlarmsEnabled,
  });
  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;

  bool get allGranted => notificationsEnabled && exactAlarmsEnabled;
}

/// Prayer alert scheduling with exact alarms.
/// - Times are computed on-device; notifications are scheduled 7 days ahead.
/// - Rescheduling happens on every app start and on any relevant settings
///   change; after a device reboot, Android restores the plugin's stored
///   alarms via the boot receiver declared in AndroidManifest, and the app
///   re-registers the rolling 7-day window on next open.
/// - Round 4 (2026-11-21): the 7-day Athan soak test FAILED at day 3 —
//    no notifications at all on the owner's OPPO. Prime suspects: a
///   denied notification / exact-alarm permission (init used to ignore
///   the results, so a denial failed SILENTLY) or ColorOS battery
///   optimisation killing the alarms. This version surfaces the
///   permission state in Settings, never fails silently, falls back to
///   inexact scheduling when exact alarms are denied, and offers a
///   1-minute test notification.
/// - The notification sound is the Adhan (channel prayer_athan_v2).
///   Android locks a channel's sound at first creation, so the new
///   sound needed a NEW channel id — changing the file alone would not
///   have changed the sound on existing installs.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'prayer_athan_v2';

  /// The round-1..3 channel (short chime sound). Deleted on init so the
  /// old channel — and its locked-in chime — cannot linger.
  static const _legacyChannelId = 'prayer_athan';

  /// Notification id for the 1-minute test alert. Prayer alerts use
  /// 1000 + day * 10 + prayerIndex, so 7 can never collide.
  static const testNotificationId = 7;

  /// Last scheduleAll outcome, for the Settings screen to display.
  ScheduleResult? lastResult;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('QUBA tz fallback: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kabul'));
      } catch (_) {}
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      // Drop the legacy chime channel (best-effort).
      try {
        await android.deleteNotificationChannel(_legacyChannelId);
      } catch (_) {}
      // Ask for the notification permission once (a normal runtime
      // dialog on Android 13+; on older Android, and when the user has
      // already decided, it just returns the stored decision).
      // The result is NOT trusted here — Settings re-queries the live
      // state with [permissionState] instead.
      try {
        await android.requestNotificationsPermission();
      } catch (_) {}
      // NOTE: exact alarms are NOT requested here — on Android 12+
      // that call opens the system settings page, which must only
      // happen when the user taps the button in Settings.
    }
    _initialized = true;
  }

  /// Live permission state, queried from the platform each time.
  Future<NotificationPermissionState> permissionState() async {
    if (!_initialized) await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      // Non-Android: no runtime permission model for notifications.
      return const NotificationPermissionState(
        notificationsEnabled: true,
        exactAlarmsEnabled: true,
      );
    }
    var notif = true;
    var exact = false;
    try {
      notif = await android.areNotificationsEnabled() ?? true;
    } catch (_) {}
    try {
      exact = await android.canScheduleExactNotifications() ?? false;
    } catch (_) {}
    return NotificationPermissionState(
      notificationsEnabled: notif,
      exactAlarmsEnabled: exact,
    );
  }

  /// Ask Android for the notification permission. Returns true when
  /// granted. On Android 13+, if the user previously denied, the system
  /// shows no dialog and this returns false — the user must then enable
  /// it in the system settings (Settings offers that button).
  Future<bool> requestNotificationPermission() async {
    if (!_initialized) await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    try {
      return await android.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Ask Android for the exact-alarm permission (needed for on-time Athan).
  /// Returns true when granted, or when the platform does not need it.
  /// On Android 12+ this opens the system "Alarms & reminders" page.
  Future<bool> requestExactAlarmPermission() async {
    if (!_initialized) await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    try {
      return await android.requestExactAlarmsPermission() ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _canScheduleExact() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    try {
      return await android.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails _details() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        tr('notif_channel'),
        channelDescription: tr('notif_channel_desc'),
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('athan_adhan'),
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  /// Cancel the prayer alerts (ids 1000..1065) without touching the
  /// 1-minute test alert, so a reschedule never eats a pending test.
  Future<void> _cancelPrayerAlerts() async {
    for (var day = 0; day < 7; day++) {
      for (var i = 0; i < 6; i++) {
        try {
          await _plugin.cancel(1000 + day * 10 + i);
        } catch (_) {}
      }
    }
  }

  /// Cancel everything and re-schedule the next 7 days from current settings.
  /// Never throws and never fails silently: every prayer is tried
  /// exact-first (when allowed) with an inexact retry, and the outcome
  /// is returned + stored in [lastResult].
  Future<ScheduleResult> scheduleAll(AppState state) async {
    if (!_initialized) await init();
    await _cancelPrayerAlerts();
    final canExact = await _canScheduleExact();
    final now = DateTime.now();
    var scheduled = 0;
    var failed = 0;
    var exactUsed = false;
    for (var day = 0; day < 7; day++) {
      final date = now.add(Duration(days: day));
      final entries = PrayerService.dayList(date, state);
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        if (state.prayerNotify[e.name] != true) continue;
        if (!e.time.isAfter(now)) continue;
        final id = 1000 + day * 10 + i;
        final when = tz.TZDateTime.from(e.time, tz.local);
        final title = trf('notif_title', {'prayer': trPrayer(e.name)});
        final body = trf('notif_body', {'prayer': trPrayer(e.name)});
        var done = false;
        if (canExact) {
          try {
            await _plugin.zonedSchedule(
              id,
              title,
              body,
              when,
              _details(),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              payload: e.name,
            );
            done = true;
            exactUsed = true;
          } catch (_) {
            // Exact scheduling can still fail on some devices even
            // when the check passed — fall through to the inexact
            // retry below instead of dropping this prayer.
          }
        }
        if (!done) {
          try {
            await _plugin.zonedSchedule(
              id,
              title,
              body,
              when,
              _details(),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: e.name,
            );
            done = true;
          } catch (_) {
            failed++;
          }
        }
        if (done) scheduled++;
      }
    }
    // Azkar reminders ride along with every prayer reschedule so they
    // follow the (possibly adjusted) prayer times.
    await scheduleAzkar(state);
    final result = ScheduleResult(
      scheduled: scheduled,
      failed: failed,
      exactAlarms: exactUsed,
    );
    lastResult = result;
    debugPrint(
      'QUBA: scheduled ${result.scheduled} prayer notifications '
      '(${result.failed} failed, exact=${result.exactAlarms})',
    );
    return result;
  }

  // ------------------------------------------------------------------
  // Azkar reminders (morning after Fajr, evening after Asr).
  // ------------------------------------------------------------------

  static const _azkarChannelId = 'azkar_reminders';

  /// Azkar alerts use ids 2000 + day * 2 + (0 morning | 1 evening) —
  /// clear of the prayer ids (1000..1065) and the test id (7).
  static int _azkarId(int day, bool morning) =>
      2000 + day * 2 + (morning ? 0 : 1);

  NotificationDetails _azkarDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _azkarChannelId,
        tr('azkar_channel'),
        channelDescription: tr('azkar_channel_desc'),
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
  }

  /// When a reminder should fire: [gapMinutes] after [start], but always
  /// inside the window [start, end): if the window is too short, use the
  /// middle of it.
  static DateTime azkarTime(DateTime start, DateTime end, int gapMinutes) {
    final candidate = start.add(Duration(minutes: gapMinutes));
    if (candidate.isBefore(end)) return candidate;
    return start.add(Duration(minutes: (end.difference(start).inMinutes ~/ 2)));
  }

  /// (Re)schedules the next 7 days of Azkar reminders from the current
  /// settings. Never throws. Inexact alarms are enough here (a reminder
  /// a few minutes late is fine), so no exact-alarm permission is needed.
  Future<void> scheduleAzkar(AppState state) async {
    try {
      if (!_initialized) await init();
      for (var day = 0; day < 7; day++) {
        for (final morning in const [true, false]) {
          try {
            await _plugin.cancel(_azkarId(day, morning));
          } catch (_) {}
        }
      }
      if (!state.azkarMorningNotify && !state.azkarEveningNotify) return;
      final now = DateTime.now();
      for (var day = 0; day < 7; day++) {
        final date = now.add(Duration(days: day));
        final list = PrayerService.dayList(date, state);
        DateTime timeOf(String name) =>
            list.firstWhere((e) => e.name == name).time;
        final fajr = timeOf('Fajr');
        final sunrise = timeOf('Sunrise');
        final asr = timeOf('Asr');
        final maghrib = timeOf('Maghrib');
        for (final morning in const [true, false]) {
          if (morning && !state.azkarMorningNotify) continue;
          if (!morning && !state.azkarEveningNotify) continue;
          final at = morning
              ? azkarTime(fajr, sunrise, 20)
              : azkarTime(asr, maghrib, 20);
          if (!at.isAfter(now)) continue;
          try {
            await _plugin.zonedSchedule(
              _azkarId(day, morning),
              tr(
                morning
                    ? 'azkar_morning_notif_title'
                    : 'azkar_evening_notif_title',
              ),
              tr(
                morning
                    ? 'azkar_morning_notif_body'
                    : 'azkar_evening_notif_body',
              ),
              tz.TZDateTime.from(at, tz.local),
              _azkarDetails(),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: morning ? 'azkar_morning' : 'azkar_evening',
            );
          } catch (_) {
            // One failed reminder must not stop the others.
          }
        }
      }
    } catch (e) {
      debugPrint('QUBA: azkar scheduling failed: $e');
    }
  }

  /// Schedules a one-off test notification 1 minute from now so the
  /// user can verify alerts work without waiting for prayer time.
  /// Returns false when it could not be scheduled.
  Future<bool> sendTestNotification() async {
    if (!_initialized) await init();
    try {
      final canExact = await _canScheduleExact();
      await _plugin.zonedSchedule(
        testNotificationId,
        tr('notif_test_title'),
        tr('notif_test_body'),
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)),
        _details(),
        androidScheduleMode: canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'test',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
