package com.lynra.beacon.locator

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

class PresenceWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {

    override fun doWork(): Result {

        Log.e(
            "LYNRA_WORK",
            "PresenceWorker fired",
        )

        return Result.success()
    }
}