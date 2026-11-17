import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app_state.dart';
import 'i18n.dart';
import 'prayer_service.dart';

/// Prayer alert scheduling with exact alarms.
/// - Times are computed on-device; notifications are scheduled 7 days ahead.
/// - Rescheduling happens on every app start and on any relevant settings
///   change; after a device reboot, Android restores the plugin's stored
///   alarms via the boot receiver declared in AndroidManifest, and the app
///   re-registers the rolling 7-day window on next open.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'prayer_athan';

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

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }
    _initialized = true;
  }

  /// Ask Android for the exact-alarm permission (needed for on-time Athan).
  /// Returns true when granted, or when the platform does not need it.
  Future<bool> requestExactAlarmPermission() async {
    if (!_initialized) await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestExactAlarmsPermission() ?? true;
  }

  NotificationDetails _details() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        tr('notif_channel'),
        channelDescription: tr('notif_channel_desc'),
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('athan_chime'),
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  /// Cancel everything and re-schedule the next 7 days from current settings.
  Future<void> scheduleAll(AppState state) async {
    if (!_initialized) await init();
    await _plugin.cancelAll();
    final now = DateTime.now();
    var scheduled = 0;
    for (var day = 0; day < 7; day++) {
      final date = now.add(Duration(days: day));
      final entries = PrayerService.dayList(date, state);
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        if (state.prayerNotify[e.name] != true) continue;
        if (!e.time.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          1000 + day * 10 + i,
          trf('notif_title', {'prayer': trPrayer(e.name)}),
          trf('notif_body', {'prayer': trPrayer(e.name)}),
          tz.TZDateTime.from(e.time, tz.local),
          _details(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: e.name,
        );
        scheduled++;
      }
    }
    debugPrint('QUBA: scheduled $scheduled prayer notifications');
  }
}
