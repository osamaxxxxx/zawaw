package com.example.zawawy_app

import android.app.Notification
import android.app.Notification.Builder
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra("prayer_name") ?: return
        val notificationId = intent.getIntExtra("notification_id", 700)
        val notificationType = intent.getStringExtra("notification_type")
        val navTarget = intent.getStringExtra(MainActivity.EXTRA_NAV_TARGET)
            ?: when {
                notificationType == "kahf" -> "quran_kahf"
                prayerName.contains("الصباح") -> "adhkar_morning"
                prayerName.contains("المساء") -> "adhkar_evening"
                prayerName.contains("أذكار") -> "adhkar"
                else -> "prayer"
            }

        val notification = buildNotification(context, prayerName, notificationType, navTarget)

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(notificationId, notification)
    }

    private fun buildNotification(
        context: Context,
        prayerName: String,
        notificationType: String?,
        navTarget: String
    ): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Builder(context, "prayer_times")
        } else {
            Builder(context)
        }

        val launchIntent = (context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_NAV_TARGET, navTarget)
        }
        val contentIntent = PendingIntent.getActivity(
            context,
            navTarget.hashCode(),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = if (notificationType == "kahf") {
            "تذكير سورة الكهف"
        } else if (prayerName.contains("أذكار")) {
            "حان وقت $prayerName"
        } else {
            "حان وقت صلاة $prayerName"
        }

        val text = when {
            notificationType == "kahf" -> "لا تنس قراءة سورة الكهف اليوم"
            prayerName == "أذكار الصباح" -> "لا تنسَ قراءة أذكار الصباح لتحصين نفسك"
            prayerName == "أذكار المساء" -> "لا تنسَ قراءة أذكار المساء لحفظك وتحصينك"
            else -> "تقبّل الله منا ومنكم صالح الأعمال"
        }

        return builder
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .setPriority(Notification.PRIORITY_HIGH)
            .build()
    }
}
