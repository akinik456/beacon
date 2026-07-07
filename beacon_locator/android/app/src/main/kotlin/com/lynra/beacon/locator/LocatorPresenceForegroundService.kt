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
import io.flutter.plugin.common.MethodChannel

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
				
				val groupId = intent?.getStringExtra("groupId")
				val locatorId = intent?.getStringExtra("locatorId")

				Log.e(
						"LYNRA_SERVICE",
						"groupId=$groupId locatorId=$locatorId",
				)
		
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
							
					MethodChannel(
							flutterEngine!!.dartExecutor.binaryMessenger,
							"lynra/presence_service",
					).setMethodCallHandler { call, result ->
							if (call.method == "getPresenceIds") {
									result.success(
											mapOf(
													"groupId" to groupId,
													"locatorId" to locatorId,
											)
									)
							} else {
									result.notImplemented()
							}
					}

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
								getString(R.string.presence_service_channel_name),
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
            .setContentTitle(
								getString(R.string.presence_service_notification_title),
						)
						.setContentText(
								getString(R.string.presence_service_notification_body),
						)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()
    }
}