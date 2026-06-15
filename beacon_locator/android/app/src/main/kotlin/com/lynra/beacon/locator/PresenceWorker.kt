package com.lynra.beacon.locator

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.location.LocationManager
import android.os.BatteryManager
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

class PresenceWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {

    override fun doWork(): Result {

        val batteryInfo =
            readBatteryInfo(applicationContext)

        val locationEnabled =
            isLocationEnabled(applicationContext)

        Log.e(
            "LYNRA_WORK",
            "Health check battery=${batteryInfo.level} charging=${batteryInfo.isCharging} locationEnabled=$locationEnabled",
        )

        return Result.success()
    }

    private fun readBatteryInfo(
        context: Context,
    ): BatteryInfo {

        val intent =
            context.registerReceiver(
                null,
                IntentFilter(Intent.ACTION_BATTERY_CHANGED),
            )

        val level =
            intent?.getIntExtra(
                BatteryManager.EXTRA_LEVEL,
                -1,
            ) ?: -1

        val scale =
            intent?.getIntExtra(
                BatteryManager.EXTRA_SCALE,
                -1,
            ) ?: -1

        val status =
            intent?.getIntExtra(
                BatteryManager.EXTRA_STATUS,
                -1,
            ) ?: -1

        val plugged =
            intent?.getIntExtra(
                BatteryManager.EXTRA_PLUGGED,
                0,
            ) ?: 0

        val percent =
            if (level >= 0 && scale > 0) {
                ((level * 100f) / scale).toInt()
            } else {
                -1
            }

        val isCharging =
            status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL ||
                plugged != 0

        return BatteryInfo(
            level = percent,
            isCharging = isCharging,
        )
    }

    private fun isLocationEnabled(
        context: Context,
    ): Boolean {

        val locationManager =
            context.getSystemService(
                Context.LOCATION_SERVICE,
            ) as LocationManager

        return try {
            locationManager.isProviderEnabled(
                LocationManager.GPS_PROVIDER,
            ) ||
                locationManager.isProviderEnabled(
                    LocationManager.NETWORK_PROVIDER,
                )
        } catch (e: Exception) {
            false
        }
    }
}

data class BatteryInfo(
    val level: Int,
    val isCharging: Boolean,
)