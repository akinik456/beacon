package com.lynra.beacon.locator

import android.content.Context
import android.util.Log

import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore

import java.util.UUID

object SosWidgetService {

    private val firestore =
        FirebaseFirestore.getInstance()

    fun send(
        context: Context,
        appWidgetId: Int,
    ) {
        val widgetPrefs = context.getSharedPreferences(
            "sos_widget",
            Context.MODE_PRIVATE,
        )

        val identityPrefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
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
                "sos_WIDGET",
                "send failed: missing groupId or locatorId",
            )
            return
        }

				sendToAll(
						groupId = groupId,
						locatorId = locatorId,
						locatorName = locatorName,
						locatorCode = locatorCode,
				)
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
                        "sos_WIDGET",
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
                    "sos_WIDGET",
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
		val sosId =
				UUID.randomUUID().toString()
		firestore
				.collection("groups")
				.document(groupId)
				.collection("sos")
				.document(requesterId)
				.collection("items")
				.document(sosId)
				.set(
						mapOf(
								"sosId" to sosId,
								"groupId" to groupId,
								"locatorId" to locatorId,
								"locatorName" to locatorName,
								"locatorCode" to locatorCode,
								"targetRequesterId" to requesterId,
								"status" to "pending",
								"createdAt" to FieldValue.serverTimestamp(),
						)
				)
    }
}