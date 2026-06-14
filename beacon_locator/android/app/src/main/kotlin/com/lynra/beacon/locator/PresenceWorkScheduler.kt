package com.lynra.beacon.locator

import android.content.Context
import android.util.Log
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

object PresenceWorkScheduler {

    private const val WORK_NAME =
        "lynra_presence_long_work"

    fun scheduleLongPresence(
        context: Context,
    ) {

        val request =
            PeriodicWorkRequestBuilder<PresenceWorker>(
                15,
                TimeUnit.MINUTES,
            ).build()

        WorkManager.getInstance(context)
            .enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                request,
            )

        Log.e(
            "LYNRA_WORK",
            "Long presence work scheduled",
        )
    }
}