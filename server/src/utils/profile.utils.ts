import { db } from "../config/firebase.connection";
import { Timestamp } from "firebase-admin/firestore";

/**
 * Ensures a user profile exists for social features.
 * If profile doesn't exist, creates one with default values.
 * Uses existing username from users collection if available.
 *
 * @param userId - The user's ID
 * @param displayName - The user's display name
 * @param email - The user's email address
 * @returns Promise<boolean> - true if profile exists or was created successfully
 */
export async function ensureUserProfile(
  userId: string,
  displayName: string,
  email: string
): Promise<boolean> {
  try {
    // Check if profile already exists
    const profileDoc = await db.collection("userProfiles").doc(userId).get();

    if (profileDoc.exists) {
      console.log(`✅ User profile already exists for: ${userId}`);
      return true;
    }

    // Check if user already has a username in the users collection
    const usersQuery = await db.collection("users")
      .where("id", "==", userId)
      .limit(1)
      .get();

    let username = "";

    if (!usersQuery.empty) {
      const userData = usersQuery.docs[0].data();
      username = userData.username || "";
    }

    // If no username exists in users collection, generate one from email
    if (!username) {
      const defaultUsername = email.split('@')[0].toLowerCase().replace(/[^a-z0-9]/g, '');
      let usernameExists = true;
      let counter = 1;
      username = defaultUsername;

      while (usernameExists) {
        const usernameQuery = await db.collection("userProfiles")
          .where("username", "==", username)
          .limit(1)
          .get();

        if (usernameQuery.empty) {
          usernameExists = false;
        } else {
          username = `${defaultUsername}${counter}`;
          counter++;
        }
      }
    }

    // Create user profile
    await db.collection("userProfiles").doc(userId).set({
      userId,
      username,
      displayName,
      bio: "",
      avatarUrl: "",
      coverImageUrl: "",
      socialLinks: {},
      privacySettings: {
        showStats: true,
        showLists: true,
        showActivity: true,
        showHighlights: true,
      },
      featuredListId: null,
      joinedDate: Timestamp.now(),
      followersCount: 0,
      followingCount: 0,
      articlesReadCount: 0,
      collectionsCount: 0,
      isPublic: true,
      interests: [],
      stats: {},
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });

    console.log(`✅ Created social profile for user: ${userId} with username: ${username}`);
    return true;
  } catch (error) {
    console.error("⚠️ Failed to ensure user profile:", error);
    return false;
  }
}
