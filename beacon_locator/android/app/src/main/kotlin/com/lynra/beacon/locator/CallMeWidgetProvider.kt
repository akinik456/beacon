package com.lynra.beacon.locator

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

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