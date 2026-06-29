/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const {onDocumentCreated} =
    require("firebase-functions/v2/firestore");
const {onValueWritten} = require("firebase-functions/v2/database");

const admin = require("firebase-admin");

admin.initializeApp();
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
exports.onCallMeCreated = onDocumentCreated(
  "groups/{groupId}/call_me/{targetId}/items/{callMeId}",
  async (event) => {
    const data = event.data.data();

    const targetId = event.params.targetId;
    const callMeId = event.params.callMeId;

    const isRequesterToLocator =
      data.targetLocatorId === targetId;

    const isLocatorToRequester =
      data.targetRequesterId === targetId;

    let topic = "";
    let payload = {
      type: "call_me",
      callMeId,
    };

    if (isRequesterToLocator) {
      const requesterName =
        data.requesterName || "Requester";
      const requesterCode =
        data.requesterCode || "";

      topic = `locator_${targetId}`;

      payload = {
        ...payload,
        requesterName,
        requesterCode,
      };
    } else if (isLocatorToRequester) {
      const locatorName =
        data.locatorName || "Member";
      const locatorCode =
        data.locatorCode || "";

      topic = `requester_${targetId}`;

      payload = {
        ...payload,
        locatorName,
        locatorCode,
      };
    } else {
      console.error("CALL ME ERROR => unknown target", data);
      return;
    }

    console.log("CALL ME CREATED", data);
    console.log("CALL ME FCM TOPIC", topic);

    try {
      const notificationTitle = "Call Me";

			const notificationBody =
				isRequesterToLocator
					? `${data.requesterName || "Requester"} wants you to call.`
					: `${data.locatorName || "Member"} wants you to call.`;

			const response = await admin.messaging().send({
				topic,

				notification: {
					title: notificationTitle,
					body: notificationBody,
				},

				android: {
					priority: "high",
					notification: {
						channelId: "call_me",
						priority: "max",
						defaultSound: true,
					},
				},

				data: payload,
			});

      console.log("CALL ME FCM SENT", topic, response);
    } catch (error) {
      console.error("CALL ME FCM ERROR", error);
    }
  }
);
exports.onAlertCreated = onDocumentCreated(
  "groups/{groupId}/alerts/{requesterId}/items/{alertId}",
  async (event) => {
    const data = event.data.data();

    const requesterId = event.params.requesterId;
    const alertId = event.params.alertId;

    const locatorName = data.locatorName || "Locator";
    const locatorCode = data.locatorCode || "";
    const alertType = data.type || "alert";

    const topic = `requester_${requesterId}`;

    console.log("ALERT CREATED", data);
    console.log("ALERT FCM TOPIC", topic);

    try {
      const response = await admin.messaging().send({
        topic,

        notification: {
          title: "Beacon Alert",
          body: `${locatorName}: ${alertType}`,
        },

        android: {
          priority: "high",
          notification: {
            channelId: "call_me",
            priority: "max",
            defaultSound: true,
          },
        },

        data: {
          type: "alert",
          alertId,
          alertType,
          locatorName,
          locatorCode,
        },
      });

      console.log("ALERT FCM SENT", topic, response);
    } catch (error) {
      console.error("ALERT FCM ERROR", error);
    }
  }
);
exports.onRequestLocationCreated = onDocumentCreated(
  "groups/{groupId}/devices/{requesterId}/request_location/{requestId}",
  async (event) => {
    const data = event.data.data();

    const locatorId = data.locatorId;

    if (!locatorId) {
      console.error("RL ERROR => missing locatorId");
      return;
    }

    const topic = `locator_${locatorId}`;

    console.log("RL CREATED", data);
    console.log("RL FCM TOPIC", topic);

    try {
      const response = await admin.messaging().send({
				topic,

				android: {
					priority: "high",
				},

				data: {
					type: "request_location",
					locatorId,
				},
			});

						console.log("RL FCM SENT", topic, response);
					} catch (error) {
						console.error("RL FCM ERROR", error);
					}
				}
			);
exports.onActiveWatchersChanged = onValueWritten(
  "/presence/groups/{groupId}/active_watchers/{locatorId}",
  async (event) => {
    const locatorId = event.params.locatorId;

    const before = event.data.before.val() || {};
    const after = event.data.after.val() || {};

    const beforeCount = Object.keys(before).length;
    const afterCount = Object.keys(after).length;

    console.log(
      "ACTIVE WATCHERS CHANGED",
      "locatorId=", locatorId,
      "beforeCount=", beforeCount,
      "afterCount=", afterCount,
    );

    if (beforeCount === afterCount) {
      console.log("ACTIVE WATCHERS => count unchanged, skip FCM");
      return;
    }

    const topic = `locator_${locatorId}`;

    try {
      const response = await admin.messaging().send({
        topic,

        android: {
          priority: "high",
        },

        data: {
          type: "active_watchers_changed",
        },
      });

      console.log("ACTIVE WATCHERS FCM SENT", topic, response);
    } catch (error) {
      console.error("ACTIVE WATCHERS FCM ERROR", error);
    }
  }
);