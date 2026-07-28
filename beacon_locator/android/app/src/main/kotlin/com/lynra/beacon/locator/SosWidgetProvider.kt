package com.lynra.beacon.locator

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.util.Log

class SosWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
				context: Context,
				appWidgetManager: AppWidgetManager,
				appWidgetIds: IntArray,
		) {
				for (appWidgetId in appWidgetIds) {
						updateWidget(
								context,
								appWidgetManager,
								appWidgetId,
						)
				}
		}
		
		override fun onReceive(
				context: Context,
				intent: Intent,
		) {

				super.onReceive(
						context,
						intent,
				)

				if (intent.action == "SOS_CLICK") {
					val widgetId = intent.getIntExtra(
							AppWidgetManager.EXTRA_APPWIDGET_ID,
							AppWidgetManager.INVALID_APPWIDGET_ID,
					)

					if (
							widgetId ==
							AppWidgetManager.INVALID_APPWIDGET_ID
					) {
							return
					}

					val prefs = context.getSharedPreferences(
							"sos_widget",
							Context.MODE_PRIVATE,
					)

					val now = System.currentTimeMillis()

					val lastClickTime = prefs.getLong(
							"widget_${widgetId}_lastClickTime",
							0L,
					)

					if (now - lastClickTime < 3000L) {
							Log.e(
									"sos_WIDGET",
									"CLICK IGNORED widget=$widgetId cooldown",
							)
							return
					}

					prefs.edit()
							.putLong(
									"widget_${widgetId}_lastClickTime",
									now,
							)
							.apply()

					Log.e(
							"sos_WIDGET",
							"CLICK widget=$widgetId",
					)
					
					showSuccessFeedback(
							context,
							widgetId,
					)

					SosWidgetService.send(
							context,
							widgetId,
					)
	
					restoreWidget(
							context,
							widgetId,
					)
			}
		}
		
		private fun showSuccessFeedback(
				context: Context,
				appWidgetId: Int,
					) {
							val views = RemoteViews(
					context.packageName,
					R.layout.sos_widget,
			)

			views.setTextViewText(
					R.id.sosText,
					"✓",
			)

			views.setTextColor(
					R.id.sosText,
					android.graphics.Color.GREEN,
			)

			AppWidgetManager
					.getInstance(context)
					.updateAppWidget(
							appWidgetId,
							views,
					)
		}
		
		private fun restoreWidget(
				context: Context,
				appWidgetId: Int,
		) {
				android.os.Handler(
						android.os.Looper.getMainLooper(),
				).postDelayed(
						{
								updateWidget(
										context,
										AppWidgetManager.getInstance(context),
										appWidgetId,
								)
						},
						2000L,
				)
		}
		
		companion object {
				
				fun updateWidget(
    context: Context,
					appWidgetManager: AppWidgetManager,
					appWidgetId: Int,
			) {
					val views = RemoteViews(
							context.packageName,
							R.layout.sos_widget,
					)

					views.setTextViewText(
							R.id.sosText,
							"SOS",
					)

					views.setTextColor(
							R.id.sosText,
							android.graphics.Color.WHITE,
					)

					val intent = Intent(
							context,
							SosWidgetProvider::class.java,
					).apply {
							action = "SOS_CLICK"

							putExtra(
									AppWidgetManager.EXTRA_APPWIDGET_ID,
									appWidgetId,
							)
					}

					val pendingIntent = PendingIntent.getBroadcast(
							context,
							appWidgetId,
							intent,
							PendingIntent.FLAG_UPDATE_CURRENT or
									PendingIntent.FLAG_IMMUTABLE,
					)

					views.setOnClickPendingIntent(
							R.id.widgetRoot,
							pendingIntent,
					)

					appWidgetManager.updateAppWidget(
							appWidgetId,
							views,
					)
			}
		}
		
}