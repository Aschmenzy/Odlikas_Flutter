import axios, { AxiosResponse } from "axios";
import { ApiResponseData, UserNotificationData } from "../types";

// Define our message payload type to match what our fcm-service expects
type MessagePayload = {
  notification?: {
    title?: string;
    body?: string;
  };
  data?: {
    [key: string]: string;
  };
};

export const makeApiCall = async (
  userData: UserNotificationData
): Promise<AxiosResponse<ApiResponseData>> => {
  try {
    // Directly call the API endpoint with email and password
    const gradesResponse = await axios({
      method: "get",
      url: "https://odlikas-e-dnevnik-api-d98502da5fd5.herokuapp.com/api/Scraper/ScrapeNewGrades",
      headers: {
        "Content-Type": "application/json",
      },
      // Send credentials as query parameters
      params: {
        email: userData.email,
        password: userData.password,
      },
    });

    // Return the API response
    return gradesResponse;
  } catch (error) {
    console.error("API call failed:", error);

    // Rethrow with more context
    if (error instanceof Error) {
      throw new Error(`Failed to fetch grades: ${error.message}`);
    }
    throw error;
  }
};

export const shouldSendNotification = (
  apiResponse: AxiosResponse<ApiResponseData>,
  userData: UserNotificationData
): boolean => {
  // Check that we have a successful response
  if (apiResponse.status !== 200) {
    return false;
  }

  // Check if we have grades in the response
  if (!apiResponse.data.grades || apiResponse.data.grades.length === 0) {
    return false;
  }

  // Get previously seen grades (if any)
  const previousGrades = userData.lastSeenGrades || [];

  // Filter to find truly new grades
  const newGrades = apiResponse.data.grades.filter((grade) => {
    // Logic to determine if a grade is new (by date, subject, and grade)
    return !previousGrades.some(
      (pg) =>
        pg.date === grade.date &&
        pg.subjectName === grade.subjectName &&
        pg.gradeNumber === grade.gradeNumber
    );
  });

  // Only notify if there are truly new grades
  return newGrades.length > 0;
};

export const getNewGrades = (
  apiResponse: AxiosResponse<ApiResponseData>,
  userData: UserNotificationData
) => {
  if (!apiResponse.data.grades) {
    return [];
  }

  const previousGrades = userData.lastSeenGrades || [];

  // Filter to find truly new grades
  return apiResponse.data.grades.filter((grade) => {
    return !previousGrades.some(
      (pg) =>
        pg.date === grade.date &&
        pg.subjectName === grade.subjectName &&
        pg.gradeNumber === grade.gradeNumber
    );
  });
};

export const createNotificationMessage = (
  apiResponse: AxiosResponse<ApiResponseData>,
  userData: UserNotificationData
): MessagePayload => {
  let title = "New Grades Available";
  let body = "You have new grades to check.";

  // Get the new grades
  const newGrades = getNewGrades(apiResponse, userData);

  // Check if we have grades in the response
  if (newGrades.length > 0) {
    // If there's only one grade, make a more specific notification
    if (newGrades.length === 1) {
      const grade = newGrades[0];
      title = `New Grade in ${grade.subjectName}`;
      body = `You received ${grade.gradeNumber} for ${grade.elementOfEvaluation}`;
    } else {
      // Multiple grades
      title = `${newGrades.length} New Grades Available`;

      // List the subjects (up to 3)
      const subjects = [...new Set(newGrades.map((g) => g.subjectName))];
      const subjectList = subjects.slice(0, 3).join(", ");

      body = `New grades in: ${subjectList}${subjects.length > 3 ? "..." : ""}`;
    }
  }

  // Return a properly formatted notification message
  return {
    notification: {
      title: title,
      body: body,
    },
    data: {
      type: "grades",
      timestamp: new Date().toISOString(),
      count: newGrades.length.toString(),
    },
  };
};
