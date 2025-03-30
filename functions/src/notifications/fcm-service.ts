import * as admin from "firebase-admin";

// Instead of extending the Message interface, create a complete type
type MessagePayload = {
  notification?: {
    title?: string;
    body?: string;
  };
  data?: {
    [key: string]: string;
  };
};

export const sendNotification = async (
  token: string,
  messagePayload: MessagePayload
): Promise<string> => {
  try {
    // Create a message object that matches what the Firebase Admin SDK expects
    const message: admin.messaging.Message = {
      token: token,
      notification: messagePayload.notification,
      data: messagePayload.data,
    };

    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);
    return response;
  } catch (error) {
    console.error("Error sending message:", error);
    throw error;
  }
};
