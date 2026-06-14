package com.lynra.beacon.locator

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
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

        PresenceWorkScheduler.scheduleLongPresence(
            context.applicationContext,
        )
    }
}