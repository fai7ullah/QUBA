import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../i18n.dart';
import '../prayer_service.dart';

/// Pushes the next-prayer data to the Android home-screen widget.
///
/// The widget itself is native code (see
/// `android/.../QubaWidgetProvider.kt` + `res/layout/quba_widget.xml`).
/// This class only writes the data the provider reads — it does NOT
/// decide when to update. Call sites (app start, prayer-time changes,
/// a periodic refresh) belong to the integrator; this class just
/// exposes [update].
///
/// LIMIT (Android): a home-screen widget cannot tick every second.
/// The countdown shown is computed at update time and stays frozen
/// until the next update — the system re-renders the widget at most
/// every 30 minutes (`updatePeriodMillis`), plus whenever [update] is
/// called. So the widget's "in Xh Ym" can lag the true countdown by
/// up to 30 minutes. That is an Android platform limit, not a bug.
class HomeWidgetService {
  /// Fully qualified provider class name (package + class). Using the
  /// qualified name means the plugin never has to guess the package.
  static const String qualifiedAndroidName = 'com.quba.app.QubaWidgetProvider';

  /// Keys the Kotlin provider reads from the widget SharedPreferences.
  /// Keep these in sync with QubaWidgetProvider.kt.
  static const String keyNextPrayerName = 'next_prayer_name';
  static const String keyNextPrayerTime = 'next_prayer_time';
  static const String keyCountdown = 'countdown';
  static const String keyHijri = 'hijri';

  /// Whether the app pushes data to the widget (WidgetScreen toggle).
  /// Defaults to true: the widget works as soon as it is added, and
  /// pushing data when no widget exists is a harmless no-op.
  static const String _enabledKey = 'home_widget_enabled';

  static Future<bool> get enabled async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (_) {}
  }

  /// Compute the next prayer + Hijri date from [state] and push them
  /// to the widget. Never throws: a platform failure just means the
  /// widget keeps showing its previous data.
  static Future<void> update(AppState state) async {
    try {
      if (!await enabled) return;
      final now = DateTime.now();
      final next = PrayerService.nextPrayer(now, state);
      final countdown = next.time.difference(now);
      await HomeWidget.saveWidgetData<String>(
        keyNextPrayerName,
        trPrayer(next.name),
      );
      await HomeWidget.saveWidgetData<String>(
        keyNextPrayerTime,
        PrayerService.formatTime(next.time),
      );
      await HomeWidget.saveWidgetData<String>(
        keyCountdown,
        '${tr('in')} ${PrayerService.formatCountdownLong(countdown)}',
      );
      await HomeWidget.saveWidgetData<String>(
        keyHijri,
        PrayerService.hijriString(now),
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: qualifiedAndroidName);
    } catch (_) {
      // Widget updates are best-effort: never crash the app over them.
    }
  }
}
