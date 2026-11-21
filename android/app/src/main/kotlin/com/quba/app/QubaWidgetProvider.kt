package com.quba.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * QUBA home-screen widget: next prayer name + time, the countdown to
 * it ("in 2 h 07 m") and the Hijri date.
 *
 * Data comes from Flutter via HomeWidgetService
 * (lib/homewidget/home_widget_service.dart), which writes the four
 * keys below into the widget SharedPreferences and then calls
 * HomeWidget.updateWidget. This provider only renders them.
 *
 * LIMIT (Android): the widget cannot tick every second. The countdown
 * is computed at update time and stays frozen until the next update
 * (at most every 30 minutes via updatePeriodMillis, plus whenever the
 * app calls HomeWidgetService.update). So the displayed countdown can
 * lag the true one by up to 30 minutes. That is an Android platform
 * limit, not a bug.
 *
 * Manifest wiring (the integrator adds this inside <application>):
 * <receiver android:name=".QubaWidgetProvider" android:exported="true">
 *   <intent-filter>
 *     <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
 *   </intent-filter>
 *   <meta-data android:name="android.appwidget.provider"
 *              android:resource="@xml/quba_widget_info" />
 * </receiver>
 */
class QubaWidgetProvider : HomeWidgetProvider() {

    companion object {
        // Keep these in sync with HomeWidgetService in Dart.
        const val KEY_NEXT_PRAYER_NAME = "next_prayer_name"
        const val KEY_NEXT_PRAYER_TIME = "next_prayer_time"
        const val KEY_COUNTDOWN = "countdown"
        const val KEY_HIJRI = "hijri"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quba_widget).apply {
                // Tapping the widget opens the app.
                val pendingIntent =
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                // Fallbacks show only before the app has ever pushed data
                // (widget added before first app launch). They are plain
                // English on purpose: the provider has no access to the
                // app's i18n dictionary.
                setTextViewText(
                    R.id.widget_next_prayer_name,
                    widgetData.getString(KEY_NEXT_PRAYER_NAME, null) ?: "QUBA",
                )
                setTextViewText(
                    R.id.widget_next_prayer_time,
                    widgetData.getString(KEY_NEXT_PRAYER_TIME, null) ?: "",
                )
                setTextViewText(
                    R.id.widget_countdown,
                    widgetData.getString(KEY_COUNTDOWN, null) ?: "Open QUBA to update",
                )
                setTextViewText(
                    R.id.widget_hijri,
                    widgetData.getString(KEY_HIJRI, null) ?: "",
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
