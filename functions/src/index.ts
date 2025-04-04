import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import axios from "axios";

// Initialize Firebase Admin
admin.initializeApp();

// Export notification functions
export const processNotificationsSimple = functions.pubsub
  .schedule("every 60 minutes")
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
              method: "post",
              url: "https://odlikas-e-dnevnik-api-d98502da5fd5.herokuapp.com/api/Scraper/ScrapeNewGrades",
              headers: {
                "Content-Type": "application/json",
              },
              data: {
                Email: userData.email,
                Password: userData.password,
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
              let title = "Imate novu ocjenu";
              let body = "Pogledajte vaše ocjene.";

              // If there's only one grade, make a more specific notification
              if (grades.length === 1) {
                const grade = grades[0];

                // Check if it's a grade or a note
                if (grade.gradeNumber && grade.gradeNumber.trim() !== "") {
                  title = `Nova ocjena za predmet ${grade.subjectName}`;
                  body = `Dobili ste: ${grade.gradeNumber} za ${grade.elementOfEvaluation}`;
                } else {
                  title = `Nova bilješka za predmet ${grade.subjectName}`;
                  body = `Dobili ste novu bilješku za ${grade.elementOfEvaluation}`;
                }
              } else {
                // Count how many grades and how many notes
                const actualGrades = grades.filter(
                  (g: { gradeNumber: string }) =>
                    g.gradeNumber && g.gradeNumber.trim() !== ""
                );
                const notes = grades.filter(
                  (g: { gradeNumber: string }) =>
                    !g.gradeNumber || g.gradeNumber.trim() === ""
                );

                // Create an appropriate title
                if (actualGrades.length > 0 && notes.length > 0) {
                  title = `Imate ${actualGrades.length} nove ocjene i ${notes.length} bilješke`;
                } else if (actualGrades.length > 0) {
                  title = `Imate ${actualGrades.length} nove ocjene`;
                } else {
                  title = `Imate ${notes.length} nove bilješke`;
                }

                // List the subjects with their grade numbers or indication of note
                const gradeDetails = grades.map(
                  (g: { gradeNumber: string; subjectName: any }) => {
                    if (g.gradeNumber && g.gradeNumber.trim() !== "") {
                      return `${g.subjectName}: ${g.gradeNumber}`;
                    } else {
                      return `${g.subjectName}: bilješka`;
                    }
                  }
                );

                // Take only the first 3 for the notification
                const gradeList = gradeDetails.slice(0, 3).join(", ");

                // Create the message with appropriate ending
                if (grades.length <= 3) {
                  body = `Nove ocjene/bilješke: ${gradeList}`;
                } else {
                  body = `Nove ocjene/bilješke: ${gradeList} i još ${
                    grades.length - 3
                  }...`;
                }
              }

              // Create the message object specifically for this user
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

              // Send the notification only to this specific user
              try {
                console.log(
                  `Sending notification to user ${userId} with token ${userData.fcmToken.substring(
                    0,
                    10
                  )}...`
                );
                const response = await admin.messaging().send(message);
                console.log(
                  `Successfully sent message to ${userId}: ${response}`
                );
              } catch (fcmError) {
                console.error(
                  `Error sending notification to user ${userId}:`,
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

// Export test notification function
export const processNewTests = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    console.log("Starting scheduled function for tests");

    try {
      // Reference to the newNotifications collection
      const notificationsRef = admin.firestore().collection("newNotifications");

      // Get all users that need notifications
      const snapshot = await notificationsRef.get();

      console.log(
        `Found ${snapshot.size} users in the newNotifications collection`
      );

      if (snapshot.empty) {
        console.log("No users to process for test notifications");
        return null;
      }

      // Process each user's notification individually
      for (const doc of snapshot.docs) {
        const userData = doc.data();
        const userId = doc.id;

        try {
          console.log(
            `Processing user ${userId} with email: ${userData.email} for test notifications`
          );

          // Check credentials
          if (userData.email && userData.password && userData.fcmToken) {
            console.log(`Making API call for tests for user ${userId}`);

            // Make the API call to the tests endpoint
            const apiResponse = await axios({
              method: "post",
              url: "https://odlikas-e-dnevnik-api-d98502da5fd5.herokuapp.com/api/Scraper/ScrapeNewTests",
              headers: {
                "Content-Type": "application/json",
              },
              data: {
                Email: userData.email,
                Password: userData.password,
              },
            });

            console.log(`API call for tests successful for user ${userId}`);
            console.log(`Response status: ${apiResponse.status}`);

            // Check if we have tests in the response
            if (apiResponse.data.tests && apiResponse.data.tests.length > 0) {
              const tests = apiResponse.data.tests;
              console.log(`Found ${tests.length} new tests for user ${userId}`);

              // Create notification message
              let title = "Novi ispiti";
              let body = "Imate nove zakazane ispite.";

              // If there's only one test, make a more specific notification
              if (tests.length === 1) {
                const test = tests[0];
                title = `Novi ispit iz predmeta ${test.testSubject}`;
                body = `Datum: ${test.date}, ${test.description}`;
              } else {
                // Create a summary for multiple tests
                title = `Imate ${tests.length} nova ispita`;

                // List the subjects with their dates
                const testDetails = tests.map(
                  (t: { testSubject: string; date: string }) => {
                    return `${t.testSubject}: ${t.date}`;
                  }
                );

                // Take only the first 3 for the notification
                const testList = testDetails.slice(0, 3).join(", ");

                // Create the message with appropriate ending
                if (tests.length <= 3) {
                  body = `Novi ispiti: ${testList}`;
                } else {
                  body = `Novi ispiti: ${testList} i još ${
                    tests.length - 3
                  }...`;
                }
              }

              // Create the message object specifically for this user
              const message = {
                notification: {
                  title: title,
                  body: body,
                },
                data: {
                  type: "tests",
                  timestamp: new Date().toISOString(),
                  count: tests.length.toString(),
                },
                token: userData.fcmToken,
              };

              // Send the notification only to this specific user
              try {
                console.log(
                  `Sending test notification to user ${userId} with token ${userData.fcmToken.substring(
                    0,
                    10
                  )}...`
                );
                const response = await admin.messaging().send(message);
                console.log(
                  `Successfully sent test message to ${userId}: ${response}`
                );
              } catch (fcmError) {
                console.error(
                  `Error sending test notification to user ${userId}:`,
                  fcmError
                );
              }
            } else {
              console.log(`No new tests found for user ${userId}`);
            }

            // Update the document with timestamp
            await doc.ref.update({
              lastTestProcessed: admin.firestore.FieldValue.serverTimestamp(),
            });
          } else {
            console.log(`Missing credentials for user ${userId}`);
          }
        } catch (error) {
          console.error(`Error processing tests for user ${userId}:`, error);

          // Update document with error information
          await doc.ref.update({
            lastTestProcessed: admin.firestore.FieldValue.serverTimestamp(),
            lastTestError:
              error instanceof Error ? error.message : "Unknown error",
          });
        }
      }

      console.log("Test notification function completed successfully");
      return null;
    } catch (error) {
      console.error("Error in processNewTests function:", error);
      return null;
    }
  });
