package com.lynra.beacon.locator

import android.content.Context
import android.util.Log

import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore

import java.util.UUID

object CallMeWidgetService {

    private val firestore =
        FirebaseFirestore.getInstance()

    fun send(
        context: Context,
        appWidgetId: Int,
    ) {
        val widgetPrefs = context.getSharedPreferences(
            "call_me_widget",
            Context.MODE_PRIVATE,
        )

        val identityPrefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
        )

        val askEverybody = widgetPrefs.getBoolean(
            "widget_${appWidgetId}_all",
            true,
        )

        val targetRequesterId = widgetPrefs.getString(
            "widget_${appWidgetId}_requesterId",
            null,
        )

        val groupId = identityPrefs.getString(
            "flutter.group_id",
            null,
        )

        val locatorId = identityPrefs.getString(
            "flutter.locator_id",
            null,
        )

        val locatorName = identityPrefs.getString(
            "flutter.locator_name",
            "Locator",
        ) ?: "Locator"

        val locatorCode = identityPrefs.getString(
            "flutter.locator_code",
            "------",
        ) ?: "------"

        if (
            groupId.isNullOrEmpty() ||
            locatorId.isNullOrEmpty()
        ) {
            Log.e(
                "CALL_ME_WIDGET",
                "send failed: missing groupId or locatorId",
            )
            return
        }

        if (askEverybody) {
            sendToAll(
                groupId = groupId,
                locatorId = locatorId,
                locatorName = locatorName,
                locatorCode = locatorCode,
            )
        } else {
            if (targetRequesterId.isNullOrEmpty()) {
                Log.e(
                    "CALL_ME_WIDGET",
                    "send failed: missing requesterId",
                )
                return
            }

            sendToRequester(
                groupId = groupId,
                locatorId = locatorId,
                locatorName = locatorName,
                locatorCode = locatorCode,
                requesterId = targetRequesterId,
            )
        }
    }

    private fun sendToAll(
        groupId: String,
        locatorId: String,
        locatorName: String,
        locatorCode: String,
    ) {
        firestore
            .collection("groups")
            .document(groupId)
            .collection("devices")
            .document(locatorId)
            .get()
            .addOnSuccessListener { snapshot ->
                val paired =
                    snapshot.get("pairedRequesters")

                @Suppress("UNCHECKED_CAST")
                val pairedRequesters =
                    paired as?
                        Map<String, Map<String, Any>>
                        ?: emptyMap()

                if (pairedRequesters.isEmpty()) {
                    Log.e(
                        "CALL_ME_WIDGET",
                        "send all skipped: no paired requesters",
                    )
                    return@addOnSuccessListener
                }

                for (requesterId in pairedRequesters.keys) {
                    sendToRequester(
                        groupId = groupId,
                        locatorId = locatorId,
                        locatorName = locatorName,
                        locatorCode = locatorCode,
                        requesterId = requesterId,
                    )
                }
            }
            .addOnFailureListener { error ->
                Log.e(
                    "CALL_ME_WIDGET",
                    "send all read failed",
                    error,
                )
            }
    }

    private fun sendToRequester(
        groupId: String,
        locatorId: String,
        locatorName: String,
        locatorCode: String,
        requesterId: String,
    ) {
        firestore
            .collection("groups")
            .document(groupId)
            .collection("devices")
            .document(locatorId)
            .collection("notifyRequesters")
            .document(requesterId)
            .get()
            .addOnSuccessListener { notifySnapshot ->
                val enabled =
                    notifySnapshot.getBoolean("callMe") == true

                if (!enabled) {
                    Log.e(
                        "CALL_ME_WIDGET",
                        "skipped disabled requester=$requesterId",
                    )
                    return@addOnSuccessListener
                }

                val callMeId =
                    UUID.randomUUID().toString()

                firestore
                    .collection("groups")
                    .document(groupId)
                    .collection("call_me")
                    .document(requesterId)
                    .collection("items")
                    .document(callMeId)
                    .set(
                        mapOf(
                            "callMeId" to callMeId,
                            "groupId" to groupId,
                            "locatorId" to locatorId,
                            "locatorName" to locatorName,
                            "locatorCode" to locatorCode,
                            "targetRequesterId" to requesterId,
                            "status" to "pending",
                            "createdAt" to FieldValue.serverTimestamp(),
                        )
                    )
                    .addOnSuccessListener {
                        Log.e(
                            "CALL_ME_WIDGET",
                            "sent requester=$requesterId callMeId=$callMeId",
                        )
                    }
                    .addOnFailureListener { error ->
                        Log.e(
                            "CALL_ME_WIDGET",
                            "send failed requester=$requesterId",
                            error,
                        )
                    }
            }
            .addOnFailureListener { error ->
                Log.e(
                    "CALL_ME_WIDGET",
                    "notify settings read failed requester=$requesterId",
                    error,
                )
            }
    }
}