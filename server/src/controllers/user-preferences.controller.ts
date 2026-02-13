import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import { Timestamp } from "firebase-admin/firestore";
import { getOptionalString } from "../utils/request.utils";

const userPreferencesCollection = db.collection("userPreferences");

/**
 * Get user preferences for cross-device sync
 * GET /api/v1/user/preferences/:userId
 */
export const getUserPreferences = async (req: Request, res: Response) => {
  try {
    const userId = getOptionalString(req.params.userId);

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    // Get user preferences document
    const docRef = userPreferencesCollection.doc(userId);
    const doc = await docRef.get();

    if (!doc.exists) {
      // Return default preferences if none exist
      const defaultPreferences = {
        isDarkMode: true,
        themeMode: "dark",
        languageCode: "en",
        fontSize: 16.0,
        fontFamily: "Default",
        lineHeight: 1.5,
        notificationsEnabled: true,
        digestNotifications: true,
        breakingNewsNotifications: false,
        aiProvider: "none",
        aiSummaryEnabled: true,
        autoDownloadOnWifi: false,
        downloadImagesOffline: true,
        highContrast: false,
        screenReaderEnabled: false,
        lastModified: Date.now(),
      };

      return res.status(200).json({
        success: true,
        preferences: defaultPreferences,
        isDefault: true,
      });
    }

    const data = doc.data();

    // Convert Firestore Timestamp to milliseconds
    const preferences = {
      ...data,
      lastModified: data?.lastModified?.toMillis() || Date.now(),
    };

    return res.status(200).json({
      success: true,
      preferences,
    });
  } catch (error) {
    console.error("Error fetching user preferences:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch user preferences",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Update user preferences (upsert)
 * PUT /api/v1/user/preferences
 */
export const updateUserPreferences = async (req: Request, res: Response) => {
  try {
    const { userId, preferences } = req.body;

    if (!userId || !preferences) {
      return res.status(400).json({
        success: false,
        message: "userId and preferences are required",
      });
    }

    // Prepare preferences data with timestamp
    const preferencesData = {
      ...preferences,
      lastModified: Timestamp.now(),
      updatedAt: Timestamp.now(),
    };

    // Upsert preferences (set with merge)
    const docRef = userPreferencesCollection.doc(userId);
    await docRef.set(preferencesData, { merge: true });

    return res.status(200).json({
      success: true,
      message: "User preferences updated successfully",
      preferences: {
        ...preferencesData,
        lastModified: preferencesData.lastModified.toMillis(),
        updatedAt: preferencesData.updatedAt.toMillis(),
      },
    });
  } catch (error) {
    console.error("Error updating user preferences:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update user preferences",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Delete user preferences
 * DELETE /api/v1/user/preferences/:userId
 */
export const deleteUserPreferences = async (req: Request, res: Response) => {
  try {
    const userId = getOptionalString(req.params.userId);

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    await userPreferencesCollection.doc(userId).delete();

    return res.status(200).json({
      success: true,
      message: "User preferences deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting user preferences:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete user preferences",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
