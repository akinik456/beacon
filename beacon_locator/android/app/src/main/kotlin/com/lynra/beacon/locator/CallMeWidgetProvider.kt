package com.lynra.beacon.locator

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.util.Log

class CallMeWidgetProvider : AppWidgetProvider() {

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

				if (intent.action == "CALL_ME_CLICK") {
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
							"call_me_widget",
							Context.MODE_PRIVATE,
					)

					val now = System.currentTimeMillis()

					val lastClickTime = prefs.getLong(
							"widget_${widgetId}_lastClickTime",
							0L,
					)

					if (now - lastClickTime < 3000L) {
							Log.e(
									"CALL_ME_WIDGET",
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
							"CALL_ME_WIDGET",
							"CLICK widget=$widgetId",
					)
					
					CallMeWidgetService.send(
							context,
							widgetId,
					)

					// Bir sonraki adımda gerçek Call Me burada çalışacak.
			}
		}
		
		companion object {
				
				fun updateWidget(
						context: Context,
						appWidgetManager: AppWidgetManager,
						appWidgetId: Int,
				) {
						val views = RemoteViews(
								context.packageName,
								R.layout.call_me_widget,
						)
						val intent = Intent(
								context,
								CallMeWidgetProvider::class.java,
						).apply {
								action = "CALL_ME_CLICK"

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

						val prefs = context.getSharedPreferences(
								"call_me_widget",
								Context.MODE_PRIVATE,
						)

						val askEverybody = prefs.getBoolean(
								"widget_${appWidgetId}_all",
								true,
						)

						val requesterName = prefs.getString(
								"widget_${appWidgetId}_requesterName",
								null,
						)

						val targetText =
								if (askEverybody) {
										"Ask Everybody"
								} else {
										requesterName ?: "Unknown"
								}

						views.setTextViewText(
								R.id.callMeWidgetTarget,
								targetText,
						)

						appWidgetManager.updateAppWidget(
								appWidgetId,
								views,
						)
				}
		}
		
}