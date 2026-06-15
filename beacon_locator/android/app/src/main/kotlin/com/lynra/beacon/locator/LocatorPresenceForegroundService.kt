package com.lynra.beacon.locator
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log

class LocatorPresenceForegroundService : Service() {
	private var flutterEngine: FlutterEngine? = null

    override fun onCreate() {
        super.onCreate()

        Log.e(
            "LYNRA_SERVICE",
            "Foreground service created",
        )

        startForeground(
            1001,
            createNotification(),
        )
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int,
    ): Int {

        Log.e(
            "LYNRA_SERVICE",
            "Foreground service started action=${intent?.action}",
        )

				if (flutterEngine == null) {

					Log.e(
							"LYNRA_SERVICE",
							"Starting FlutterEngine",
					)

					flutterEngine =
							FlutterEngine(applicationContext)

					val flutterLoader = FlutterLoader()

					flutterLoader.startInitialization(
							applicationContext,
					)

					flutterLoader.ensureInitializationComplete(
							applicationContext,
							null,
					)

					val bundlePath =
							flutterLoader.findAppBundlePath()

					flutterEngine!!
							.dartExecutor
							.executeDartEntrypoint(
									DartExecutor.DartEntrypoint(
											bundlePath,
											"locatorPresenceServiceMain",
									)
							)
			}
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotification(): Notification {

        val channelId = "lynra_presence_service"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "LynraFamily Member Service",
                NotificationManager.IMPORTANCE_LOW,
            )

            val manager =
                getSystemService(
                    NotificationManager::class.java,
                )

            manager.createNotificationChannel(channel)
        }

        return Notification.Builder(
            this,
            channelId,
        )
            .setContentTitle("LynraFamily Member is active")
            .setContentText("Sharing status with your family group.")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()
    }
}