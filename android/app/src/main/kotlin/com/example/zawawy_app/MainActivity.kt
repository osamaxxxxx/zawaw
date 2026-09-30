package com.example.zawawy_app

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import java.util.Calendar
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val channelName = "zawawy_app/prayer_notifications"
    private val notificationChannelId = "prayer_times"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "schedulePrayerNotifications") {
                val prayers = call.argument<List<Map<String, Any>>>("prayers") ?: emptyList()

                // Convert list to JSON string
                val jsonArray = org.json.JSONArray()
                prayers.forEach { prayer ->
                    val jsonObject = org.json.JSONObject()
                    jsonObject.put("name", prayer["name"])
                    jsonObject.put("time", prayer["time"])
                    jsonArray.put(jsonObject)
                }
                val prayersJson = jsonArray.toString()

                // Save to SharedPreferences
                val sharedPref = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                sharedPref.edit().putString(KEY_PRAYERS, prayersJson).apply()

                requestNotificationPermission()
                scheduleAlarms(this, prayersJson)
                AppWidgetHelper.updateAll(this)
                result.success(true)
            } else if (call.method == "updateSavedAyahs") {
                val ayahs = call.argument<List<Map<String, Any>>>("ayahs") ?: emptyList()
                val serializedAyahs = ayahs.map { org.json.JSONObject(it).toString() }.toSet()
                getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    .edit()
                    .putStringSet(AppWidgetHelper.SAVED_AYAHS_KEY, serializedAyahs)
                    .apply()
                AppWidgetHelper.updateAll(this)
                result.success(true)
            } else if (call.method == "getLaunchTarget") {
                val launchTarget = intent.getStringExtra(EXTRA_NAV_TARGET)
                intent.removeExtra(EXTRA_NAV_TARGET)
                result.success(launchTarget)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra(EXTRA_NAV_TARGET)?.let { target ->
            methodChannel?.invokeMethod("notificationNavigation", target)
            intent.removeExtra(EXTRA_NAV_TARGET)
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                notificationChannelId,
                "تنبيهات الصلاة",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "تنبيه عند دخول وقت الصلاة"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    companion object {
        const val PREFS_NAME = "prayer_notifications_pref"
        const val KEY_PRAYERS = "prayers_list"
        const val EXTRA_NAV_TARGET = "nav_target"
        private const val FRIDAY_KAHF_REQUEST_CODE = 9700

        fun scheduleAlarms(context: Context, prayersJson: String) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            // First, cancel previously scheduled alarms (up to 100 request codes)
            for (i in 0 until 100) {
                val intent = Intent(context, PrayerAlarmReceiver::class.java)
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    i + 700,
                    intent,
                    PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
                )
                if (pendingIntent != null) {
                    alarmManager.cancel(pendingIntent)
                    pendingIntent.cancel()
                }
            }

            try {
                val jsonArray = org.json.JSONArray(prayersJson)
                val now = System.currentTimeMillis()
                for (i in 0 until jsonArray.length()) {
                    val jsonObject = jsonArray.getJSONObject(i)
                    val name = jsonObject.getString("name")
                    val time = jsonObject.getLong("time")
                    if (time <= now) continue

                    val navTarget = when {
                        name.contains("الصباح") -> "adhkar_morning"
                        name.contains("المساء") -> "adhkar_evening"
                        name.contains("أذكار") -> "adhkar"
                        else -> "prayer"
                    }
                    val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
                        putExtra("prayer_name", name)
                        putExtra("notification_id", i + 700)
                        putExtra("trigger_time", time)
                        putExtra(EXTRA_NAV_TARGET, navTarget)
                    }
                    val pendingIntent = PendingIntent.getBroadcast(
                        context,
                        i + 700,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                        !alarmManager.canScheduleExactAlarms()
                    ) {
                        alarmManager.set(AlarmManager.RTC_WAKEUP, time, pendingIntent)
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            time,
                            pendingIntent
                        )
                    } else {
                        alarmManager.setExact(AlarmManager.RTC_WAKEUP, time, pendingIntent)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            scheduleFridayKahfReminder(context, alarmManager)
        }

        private fun scheduleFridayKahfReminder(context: Context, alarmManager: AlarmManager) {
            val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
                putExtra("prayer_name", "سورة الكهف")
                putExtra("notification_id", FRIDAY_KAHF_REQUEST_CODE)
                putExtra("notification_type", "kahf")
                putExtra(EXTRA_NAV_TARGET, "quran_kahf")
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                FRIDAY_KAHF_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val nextFriday = Calendar.getInstance().apply {
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.HOUR_OF_DAY, 9)
                set(Calendar.DAY_OF_WEEK, Calendar.FRIDAY)
                if (timeInMillis <= System.currentTimeMillis()) {
                    add(Calendar.WEEK_OF_YEAR, 1)
                }
            }

            alarmManager.setRepeating(
                AlarmManager.RTC_WAKEUP,
                nextFriday.timeInMillis,
                AlarmManager.INTERVAL_DAY * 7,
                pendingIntent
            )
        }
    }
}
