import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as notificationFunctions from "./notifications";
import axios from "axios";

// Initialize Firebase Admin
admin.initializeApp();

// Export notification functions
//export const processNotifications = notificationFunctions.processNotifications;
export const processNotificationsSimple = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async () => {
    console.log("Starting scheduled function");

    try {
      // Reference to the newNotifications collection
      const notificationsRef = admin.firestore().collection("newNotifications");

      // Get all users that need notifications
      const snapshot = await notificationsRef.get();

      console.log(
        `Found ${snapshot.size} users in the newNotifications collection`
      );

      if (snapshot.empty) {
        console.log("No notifications to process");
        return null;
      }

      // Process each user's notification
      for (const doc of snapshot.docs) {
        const userData = doc.data();
        const userId = doc.id;

        try {
          console.log(
            `Processing user ${userId} with email: ${userData.email}`
          );

          // Check credentials
          if (userData.email && userData.password && userData.fcmToken) {
            console.log(`Making API call for user ${userId}`);

            // Make the actual API call
            const apiResponse = await axios({
              method: "get",
              url: "https://odlikas-e-dnevnik-api-d98502da5fd5.herokuapp.com/api/Scraper/ScrapeNewGrades",
              headers: {
                "Content-Type": "application/json",
              },
              params: {
                email: userData.email,
                password: userData.password,
              },
            });

            console.log(`API call successful for user ${userId}`);
            console.log(`Response status: ${apiResponse.status}`);

            // Check if we have grades in the response
            if (apiResponse.data.grades && apiResponse.data.grades.length > 0) {
              const grades = apiResponse.data.grades;
              console.log(
                `Found ${grades.length} new grades for user ${userId}`
              );

              // Create notification message
              let title = "New Grades Available";
              let body = "You have new grades to check.";

              // If there's only one grade, make a more specific notification
              if (grades.length === 1) {
                const grade = grades[0];
                title = `New Grade in ${grade.subjectName}`;
                body = `You received ${grade.gradeNumber} for ${grade.elementOfEvaluation}`;
              } else {
                // Multiple grades
                title = `${grades.length} New Grades Available`;

                // List the subjects (up to 3)
                const subjects = [
                  ...new Set(
                    grades.map((g: { subjectName: any }) => g.subjectName)
                  ),
                ];
                const subjectList = subjects.slice(0, 3).join(", ");

                body = `New grades in: ${subjectList}${
                  subjects.length > 3 ? "..." : ""
                }`;
              }

              // Create the message object
              const message = {
                notification: {
                  title: title,
                  body: body,
                },
                data: {
                  type: "grades",
                  timestamp: new Date().toISOString(),
                  count: grades.length.toString(),
                },
                token: userData.fcmToken,
              };

              // Send the notification
              try {
                console.log(`Sending notification to ${userId}`);
                const response = await admin.messaging().send(message);
                console.log(`Successfully sent message: ${response}`);
              } catch (fcmError) {
                console.error(
                  `Error sending notification to ${userId}:`,
                  fcmError
                );
              }
            } else {
              console.log(`No new grades found for user ${userId}`);
            }

            // Update the document with timestamp
            await doc.ref.update({
              lastProcessed: admin.firestore.FieldValue.serverTimestamp(),
            });
          } else {
            console.log(`Missing credentials for user ${userId}`);
          }
        } catch (error) {
          console.error(`Error processing user ${userId}:`, error);

          // Update document with error information
          await doc.ref.update({
            lastProcessed: admin.firestore.FieldValue.serverTimestamp(),
            lastError: error instanceof Error ? error.message : "Unknown error",
          });
        }
      }

      console.log("Function completed successfully");
      return null;
    } catch (error) {
      console.error("Error in processNotificationsSimple function:", error);
      return null;
    }
  });

export const sendNotificationHttp = notificationFunctions.sendNotificationHttp;

// Simple test function to verify setup
export const helloWorld = functions.https.onRequest((request, response) => {
  response.send("Hello from Firebase!");
});
