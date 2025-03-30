import * as admin from "firebase-admin";

export interface UserNotificationData {
  email: string;
  fcmToken: string;
  password: string;
  lastUpdated?: string;
  lastProcessed?: admin.firestore.Timestamp;
  lastResult?: number;
  lastError?: string;
  lastSeenGrades?: Grade[];
}

export interface ApiResponseData {
  grades?: Grade[];
  [key: string]: any;
}

export interface Grade {
  date: string;
  subjectName: string;
  description: string | null;
  gradeNumber: string;
  elementOfEvaluation: string;
}

export interface NotificationResult {
  success: boolean;
  message: string;
}
