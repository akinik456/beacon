package com.lynra.beacon.locator

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.RadioButton
import android.widget.RadioGroup

import com.google.firebase.firestore.FirebaseFirestore

class CallMeWidgetConfigActivity : Activity() {

    private var appWidgetId =
        AppWidgetManager.INVALID_APPWIDGET_ID

    private val firestore =
        FirebaseFirestore.getInstance()

    private var selectedRequesterId: String? = null
    private var selectedRequesterName: String? = null
    private var askEverybody = true

    override fun onCreate(
        savedInstanceState: Bundle?,
    ) {
        super.onCreate(savedInstanceState)

        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (
            appWidgetId ==
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) {
            finish()
            return
        }

        setContentView(
            R.layout.activity_call_me_widget_config,
        )

        findViewById<Button>(
            R.id.saveButton,
        ).setOnClickListener {
            finishConfiguration()
        }

        val prefs = getSharedPreferences(
            "FlutterSharedPreferences",
            MODE_PRIVATE,
        )

        val groupId = prefs.getString(
            "flutter.group_id",
            null,
        )

        val locatorId = prefs.getString(
            "flutter.locator_id",
            null,
        )

        Log.e(
            "CALL_ME_WIDGET",
            "groupId=$groupId locatorId=$locatorId",
        )

        if (
            groupId.isNullOrEmpty() ||
            locatorId.isNullOrEmpty()
        ) {
            Log.e(
                "CALL_ME_WIDGET",
                "Missing groupId or locatorId",
            )
            return
        }

        loadRequesterOptions(
            groupId,
            locatorId,
        )
    }

    private fun loadRequesterOptions(
        groupId: String,
        locatorId: String,
    ) {
        firestore
            .collection("groups")
            .document(groupId)
            .collection("devices")
            .document(locatorId)
            .get()
            .addOnSuccessListener { snapshot ->

                if (!snapshot.exists()) {
                    Log.e(
                        "CALL_ME_WIDGET",
                        "Locator document not found",
                    )
                    return@addOnSuccessListener
                }

                val container =
                    findViewById<RadioGroup>(
                        R.id.requesterGroup,
                    )

                container.removeAllViews()

                val askEverybodyRadio =
                    RadioButton(this).apply {
                        text = "Ask Everybody"
                        textSize = 18f
                        tag = "ALL"
                        isChecked = true
                    }

                container.addView(
                    askEverybodyRadio,
                )

                val paired =
                    snapshot.get(
                        "pairedRequesters",
                    )

                @Suppress("UNCHECKED_CAST")
                val pairedRequesters =
                    paired as?
                        Map<String, Map<String, Any>>
                        ?: emptyMap()

                for (
                    (requesterId, requesterData)
                    in pairedRequesters
                ) {
                    val requesterName =
                        requesterData[
                            "requesterName"
                        ]?.toString()
                            ?: "Requester"

                    val requesterCode =
                        requesterData[
                            "requesterCode"
                        ]?.toString()
                            ?: ""

                    val radioButton =
                        RadioButton(this).apply {
                            text =
                                "$requesterName " +
                                "($requesterCode)"

                            tag = Pair(
                                requesterId,
                                requesterName,
                            )

                            textSize = 18f
                        }

                    container.addView(
                        radioButton,
                    )
                }

                container.setOnCheckedChangeListener {
                    group,
                    checkedId ->

                    val radio =
                        group.findViewById<RadioButton>(
                            checkedId,
                        ) ?: return@setOnCheckedChangeListener

                    when (
                        val tag = radio.tag
                    ) {
                        "ALL" -> {
                            askEverybody = true
                            selectedRequesterId = null
                            selectedRequesterName = null
                        }

                        is Pair<*, *> -> {
                            askEverybody = false
                            selectedRequesterId =
                                tag.first as? String
                            selectedRequesterName =
                                tag.second as? String
                        }
                    }

                    Log.e(
                        "CALL_ME_WIDGET",
                        "askEverybody=$askEverybody " +
                            "requesterId=$selectedRequesterId " +
                            "requesterName=$selectedRequesterName",
                    )
                }

                Log.e(
                    "CALL_ME_WIDGET",
                    "pairedRequesters=$paired",
                )
            }
            .addOnFailureListener { error ->
                Log.e(
                    "CALL_ME_WIDGET",
                    "Firestore error",
                    error,
                )
            }
    }

    private fun finishConfiguration() {
        val prefs = getSharedPreferences(
            "call_me_widget",
            MODE_PRIVATE,
        )

        prefs.edit()
            .putBoolean(
                "widget_${appWidgetId}_all",
                askEverybody,
            )
            .putString(
                "widget_${appWidgetId}_requesterId",
                selectedRequesterId,
            )
            .putString(
                "widget_${appWidgetId}_requesterName",
                selectedRequesterName,
            )
            .apply()
				
				val appWidgetManager =
						AppWidgetManager.getInstance(this)

				CallMeWidgetProvider.updateWidget(
						this,
						appWidgetManager,
						appWidgetId,
				)				
						

        Log.e(
            "CALL_ME_WIDGET",
            "SAVED widget=$appWidgetId " +
                "all=$askEverybody " +
                "requesterId=$selectedRequesterId " +
                "requesterName=$selectedRequesterName",
        )

        val result = Intent().apply {
            putExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                appWidgetId,
            )
        }

        setResult(
            RESULT_OK,
            result,
        )

        finish()
    }
}