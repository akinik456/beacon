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
  "groups/{groupId}/call_me/{requesterId}/items/{callMeId}",
  async (event) => {
    const data = event.data.data();

    const requesterId = event.params.requesterId;
    const callMeId = event.params.callMeId;

    const locatorName = data.locatorName || "Locator";
    const locatorCode = data.locatorCode || "";

    const topic = `requester_${requesterId}`;

    console.log("CALL ME CREATED", data);
    console.log("CALL ME FCM TOPIC", topic);

    try {
			const response = await admin.messaging().send({
				topic,
				notification: {
					title: "Call Me",
					body: `${locatorName} wants you to call.`,
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
					type: "call_me",
					callMeId,
					locatorName,
					locatorCode,
				},
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