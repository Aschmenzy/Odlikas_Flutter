import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { UserNotificationData, NotificationResult } from "../types";
import * as apiService from "./api-service";
import * as fcmService from "./fcm-service";

// Scheduled notification function that runs every hour
export const processNotifications = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async () => {
    try {
      // Reference to the newNotifications collection
      const notificationsRef = admin.firestore().collection("newNotifications");

      // Get all users that need notifications
      const snapshot = await notificationsRef.get();

      if (snapshot.empty) {
        console.log("No notifications to process");
        return null;
      }

      // Process each user's notification
      const promises = snapshot.docs.map(async (doc) => {
        const userData = doc.data() as UserNotificationData;
        const userId = doc.id;

        try {
          const { email, password, fcmToken } = userData;

          if (!email || !password || !fcmToken) {
            console.log(`Missing required data for user ${userId}`);
            return;
          }

          const apiResponse = await apiService.makeApiCall(userData);

          // Process API response and determine if notification is needed
          if (apiService.shouldSendNotification(apiResponse, userData)) {
            // Prepare notification message
            const message = apiService.createNotificationMessage(
              apiResponse,
              userData
            );

            // Send FCM notification
            await fcmService.sendNotification(fcmToken, message);

            // Update the notification document to store current grades for future reference
            await doc.ref.update({
              lastSeenGrades: apiResponse.data.grades,
              lastProcessed: admin.firestore.FieldValue.serverTimestamp(),
              lastResult: apiResponse.status,
            });

            console.log(`Notification sent to user ${userId}`);
          } else {
            // If no new grades, just update the lastProcessed time
            await doc.ref.update({
              lastProcessed: admin.firestore.FieldValue.serverTimestamp(),
            });

            // If we have grades in the response but none are new, update the lastSeenGrades
            if (apiResponse.data.grades && apiResponse.data.grades.length > 0) {
              await doc.ref.update({
                lastSeenGrades: apiResponse.data.grades,
              });
            }

            console.log(`No new grades for user ${userId}`);
          }
        } catch (error) {
          console.error(
            `Error processing notification for user ${userId}:`,
            error
          );

          // Update document with error information
          await doc.ref.update({
            lastProcessed: admin.firestore.FieldValue.serverTimestamp(),
            lastError: error instanceof Error ? error.message : "Unknown error",
          });
        }
      });

      await Promise.all(promises);
      console.log("All notifications processed");
      return null;
    } catch (error) {
      console.error("Error in processNotifications function:", error);
      throw error;
    }
  });

// HTTP callable function for manual testing or triggering from the app
export const sendNotificationHttp = functions.https.onCall(
  async (data, context): Promise<NotificationResult> => {
    // Check authentication
    if (!context || !context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const userId = data.userId || context.auth.uid;

    try {
      // Get user data from Firestore
      const userDoc = await admin
        .firestore()
        .collection("newNotifications")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "User notification data not found."
        );
      }

      const userData = userDoc.data() as UserNotificationData;

      // Make API call
      const apiResponse = await apiService.makeApiCall(userData);

      // Check if notification should be sent
      if (apiService.shouldSendNotification(apiResponse, userData)) {
        // Create and send notification
        const message = apiService.createNotificationMessage(
          apiResponse,
          userData
        );
        await fcmService.sendNotification(userData.fcmToken, message);

        // Update the document with current grades
        await userDoc.ref.update({
          lastSeenGrades: apiResponse.data.grades,
          lastProcessed: admin.firestore.FieldValue.serverTimestamp(),
          lastResult: apiResponse.status,
        });

        return {
          success: true,
          message: `Notification sent with ${
            apiService.getNewGrades(apiResponse, userData).length
          } new grades`,
        };
      } else {
        // If no new grades, just update the lastProcessed time
        await userDoc.ref.update({
          lastProcessed: admin.firestore.FieldValue.serverTimestamp(),
        });

        // If we have grades in the response but none are new, update the lastSeenGrades
        if (apiResponse.data.grades && apiResponse.data.grades.length > 0) {
          await userDoc.ref.update({
            lastSeenGrades: apiResponse.data.grades,
          });
        }

        return { success: true, message: "No new grades found" };
      }
    } catch (error) {
      console.error("Error in HTTP function:", error);
      throw new functions.https.HttpsError(
        "internal",
        error instanceof Error ? error.message : "Unknown error"
      );
    }
  }
);
