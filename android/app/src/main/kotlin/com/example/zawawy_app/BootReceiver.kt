package com.example.zawawy_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            val sharedPref = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
            val prayersJson = sharedPref.getString(MainActivity.KEY_PRAYERS, null)
            if (!prayersJson.isNullOrEmpty()) {
                MainActivity.scheduleAlarms(context, prayersJson)
            }
            AppWidgetHelper.updateAll(context)
        }
    }
}
