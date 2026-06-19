package com.lynra.beacon.locator

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
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

        if (!hasLocationAlwaysPermission(context)) {
            Log.e(
                "LYNRA_BOOT",
                "Location always missing, skip service start",
            )
            return
        }

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

    private fun hasLocationAlwaysPermission(
        context: Context,
    ): Boolean {
        val fineGranted =
            context.checkSelfPermission(
                Manifest.permission.ACCESS_FINE_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED

        val backgroundGranted =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                context.checkSelfPermission(
                    Manifest.permission.ACCESS_BACKGROUND_LOCATION,
                ) == PackageManager.PERMISSION_GRANTED
            } else {
                true
            }

        return fineGranted && backgroundGranted
    }
}