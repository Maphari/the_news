import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import { Timestamp } from "firebase-admin/firestore";
import { getOptionalString } from "../utils/request.utils";

const serializeValue = (value: any): any => {
  if (value instanceof Timestamp) {
    return value.toMillis();
  }

  if (Array.isArray(value)) {
    return value.map(serializeValue);
  }

  if (value && typeof value === "object") {
    const out: Record<string, any> = {};
    for (const [key, val] of Object.entries(value)) {
      out[key] = serializeValue(val);
    }
    return out;
  }

  return value;
};

const serializeDocs = (snapshot: FirebaseFirestore.QuerySnapshot) =>
  snapshot.docs.map((doc) => ({
    id: doc.id,
    ...serializeValue(doc.data()),
  }));

/**
 * Export all user data for portability
 * GET /api/v1/users/:userId/export
 */
export const exportUserData = async (req: Request, res: Response) => {
  try {
    const userId = getOptionalString(req.params.userId);

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    if (req.user?.userId && req.user.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: "Not authorized to export another user's data",
      });
    }

    const [
      userDoc,
      subscriptionDoc,
      preferencesDoc,
      notificationPrefsDoc,
      profileDoc,
      savedArticlesSnap,
      dislikedArticlesSnap,
      followedPublishersSnap,
      notificationHistorySnap,
      readingHistorySnap,
      readingListsSnap,
      followersSnap,
      followingSnap,
      savedPodcastsSnap,
      listeningProgressSnap,
    ] = await Promise.all([
      db.collection("users").doc(userId).get(),
      db.collection("subscriptions").doc(userId).get(),
      db.collection("userPreferences").doc(userId).get(),
      db.collection("notificationPreferences").doc(userId).get(),
      db.collection("userProfiles").doc(userId).get(),
      db.collection("savedArticles").where("userId", "==", userId).get(),
      db.collection("dislikedArticles").where("userId", "==", userId).get(),
      db.collection("followedPublishers").where("userId", "==", userId).get(),
      db.collection("notificationHistory").where("userId", "==", userId).get(),
      db.collection("readingHistory").where("userId", "==", userId).get(),
      db.collection("readingLists").where("ownerId", "==", userId).get(),
      db.collection("userFollows").where("followingId", "==", userId).get(),
      db.collection("userFollows").where("followerId", "==", userId).get(),
      db.collection("savedPodcasts").where("userId", "==", userId).get(),
      db.collection("listeningProgress").where("userId", "==", userId).get(),
    ]);

    const exportPayload = {
      generatedAt: new Date().toISOString(),
      userId,
      user: userDoc.exists ? serializeValue(userDoc.data()) : null,
      subscription: subscriptionDoc.exists ? serializeValue(subscriptionDoc.data()) : null,
      preferences: preferencesDoc.exists ? serializeValue(preferencesDoc.data()) : null,
      notificationPreferences: notificationPrefsDoc.exists
        ? serializeValue(notificationPrefsDoc.data())
        : null,
      profile: profileDoc.exists ? serializeValue(profileDoc.data()) : null,
      savedArticles: serializeDocs(savedArticlesSnap),
      dislikedArticles: serializeDocs(dislikedArticlesSnap),
      followedPublishers: serializeDocs(followedPublishersSnap),
      notificationHistory: serializeDocs(notificationHistorySnap),
      readingHistory: serializeDocs(readingHistorySnap),
      readingLists: serializeDocs(readingListsSnap),
      followers: serializeDocs(followersSnap),
      following: serializeDocs(followingSnap),
      savedPodcasts: serializeDocs(savedPodcastsSnap),
      listeningProgress: serializeDocs(listeningProgressSnap),
    };

    return res.status(200).json({
      success: true,
      export: exportPayload,
    });
  } catch (error: any) {
    console.error("❌ Export user data error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to export user data",
      error: error?.message ?? "Unknown error",
    });
  }
};
