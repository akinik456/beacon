package com.lynra.beacon.locator

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {

        Log.e(
            "LYNRA_BOOT",
            "Receiver fired action=${intent.action}",
        )

        val serviceIntent = Intent(
            context,
            LocatorPresenceForegroundService::class.java,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}