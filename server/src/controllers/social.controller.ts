import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import { Timestamp, FieldValue } from "firebase-admin/firestore";
import {
  UserProfile,
  UserFollow,
  ReadingList,
  ActivityFeedItem,
  CreateUserProfileRequest,
  UpdateUserProfileRequest,
  FollowUserRequest,
  CreateReadingListRequest,
  UpdateReadingListRequest,
  AddArticleToListRequest,
  AddCollaboratorRequest,
  CreateActivityRequest,
  SearchUsersRequest,
  GetActivityFeedRequest,
} from "../models/social.model";

const userProfilesCollection = db.collection("userProfiles");
const userFollowsCollection = db.collection("userFollows");
const readingListsCollection = db.collection("readingLists");
const activityFeedCollection = db.collection("activityFeed");

// Helper function to convert Firestore Timestamps to ISO strings
const convertTimestampsToISO = (data: any): any => {
  if (!data) return data;

  const converted: any = {};
  for (const key in data) {
    const value = data[key];
    if (value && typeof value === 'object' && '_seconds' in value) {
      // Convert Firestore Timestamp to ISO string
      converted[key] = new Date(value._seconds * 1000).toISOString();
    } else if (value && typeof value === 'object' && value.toDate) {
      // Handle Timestamp objects with toDate method
      converted[key] = value.toDate().toISOString();
    } else if (Array.isArray(value)) {
      converted[key] = value.map(item => convertTimestampsToISO(item));
    } else if (value && typeof value === 'object') {
      converted[key] = convertTimestampsToISO(value);
    } else {
      converted[key] = value;
    }
  }
  return converted;
};

// ===== USER PROFILES =====

/**
 * Create or update user profile
 * POST /api/v1/social/profile
 */
export const createOrUpdateProfile = async (req: Request, res: Response) => {
  try {
    const { userId, username, displayName, bio, avatarUrl }: CreateUserProfileRequest = req.body;

    if (!userId || !username || !displayName) {
      return res.status(400).json({
        success: false,
        message: "userId, username, and displayName are required",
      });
    }

    // Check if username is already taken (excluding current user)
    const usernameQuery = await userProfilesCollection
      .where("username", "==", username)
      .limit(1)
      .get();

    // Check if the found profile belongs to a different user
    if (!usernameQuery.empty) {
      const existingProfileId = usernameQuery.docs[0].id;
      if (existingProfileId !== userId) {
        return res.status(400).json({
          success: false,
          message: "Username already taken",
        });
      }
    }

    const profileData: Partial<UserProfile> = {
      userId,
      username,
      displayName,
      bio: bio || "",
      avatarUrl: avatarUrl || "",
      isPublic: true,
      interests: [],
      stats: {},
    };

    // Check if profile exists
    const existingProfile = await userProfilesCollection.doc(userId).get();

    if (existingProfile.exists) {
      // Update existing profile
      await userProfilesCollection.doc(userId).update({
        ...profileData,
        updatedAt: Timestamp.now(),
      });
    } else {
      // Create new profile
      await userProfilesCollection.doc(userId).set({
        ...profileData,
        joinedDate: Timestamp.now(),
        followersCount: 0,
        followingCount: 0,
        articlesReadCount: 0,
        collectionsCount: 0,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });
    }

    return res.status(200).json({
      success: true,
      message: "Profile saved successfully",
    });
  } catch (error) {
    console.error("Error creating/updating profile:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to save profile",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get user profile by ID
 * GET /api/v1/social/profile/:userId
 */
export const getUserProfile = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const profileDoc = await userProfilesCollection.doc(userId).get();

    if (!profileDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Profile not found",
      });
    }

    const profileData = profileDoc.data();
    const convertedProfile = convertTimestampsToISO(profileData);

    return res.status(200).json({
      success: true,
      profile: { id: profileDoc.id, ...convertedProfile },
    });
  } catch (error) {
    console.error("Error fetching profile:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch profile",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Search users by username or display name
 * GET /api/v1/social/users/search?query=...&limit=20
 */
export const searchUsers = async (req: Request, res: Response) => {
  try {
    const { query, limit = "20" } = req.query as { query?: string; limit?: string };

    if (!query) {
      return res.status(400).json({
        success: false,
        message: "Query parameter is required",
      });
    }

    const searchQuery = query.toLowerCase();
    const limitNum = parseInt(limit as string) || 20;

    // Fetch all profiles (Firestore doesn't support case-insensitive LIKE queries)
    const profilesSnapshot = await userProfilesCollection
      .where("isPublic", "==", true)
      .limit(100) // Limit initial fetch for performance
      .get();

    const matchingProfiles: any[] = [];
    profilesSnapshot.forEach((doc) => {
      const profile = doc.data();
      const username = (profile.username || "").toLowerCase();
      const displayName = (profile.displayName || "").toLowerCase();

      if (username.includes(searchQuery) || displayName.includes(searchQuery)) {
        const convertedProfile = convertTimestampsToISO(profile);
        matchingProfiles.push({ id: doc.id, ...convertedProfile });
      }
    });

    // Sort by relevance (exact matches first) and limit results
    const sortedProfiles = matchingProfiles
      .sort((a, b) => {
        const aUsername = a.username.toLowerCase();
        const bUsername = b.username.toLowerCase();
        const aExact = aUsername === searchQuery ? 1 : 0;
        const bExact = bUsername === searchQuery ? 1 : 0;
        return bExact - aExact;
      })
      .slice(0, limitNum);

    return res.status(200).json({
      success: true,
      users: sortedProfiles,
      count: sortedProfiles.length,
    });
  } catch (error) {
    console.error("Error searching users:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to search users",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Update user profile
 * PUT /api/v1/social/profile
 */
export const updateProfile = async (req: Request, res: Response) => {
  try {
    const { userId, ...updates }: UpdateUserProfileRequest = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    // Check if profile exists
    const profileDoc = await userProfilesCollection.doc(userId).get();
    if (!profileDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Profile not found",
      });
    }

    // Update profile
    await userProfilesCollection.doc(userId).update({
      ...updates,
      updatedAt: Timestamp.now(),
    });

    return res.status(200).json({
      success: true,
      message: "Profile updated successfully",
    });
  } catch (error) {
    console.error("Error updating profile:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update profile",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

// ===== FOLLOW SYSTEM =====

/**
 * Follow a user
 * POST /api/v1/social/follow
 */
export const followUser = async (req: Request, res: Response) => {
  try {
    const { followerId, followingId }: FollowUserRequest = req.body;

    if (!followerId || !followingId) {
      return res.status(400).json({
        success: false,
        message: "followerId and followingId are required",
      });
    }

    if (followerId === followingId) {
      return res.status(400).json({
        success: false,
        message: "Cannot follow yourself",
      });
    }

    // Check if already following
    const existingFollow = await userFollowsCollection
      .where("followerId", "==", followerId)
      .where("followingId", "==", followingId)
      .limit(1)
      .get();

    if (!existingFollow.empty) {
      return res.status(200).json({
        success: true,
        message: "Already following this user",
        alreadyFollowing: true,
      });
    }

    // Create follow relationship
    const followData: UserFollow = {
      followerId,
      followingId,
      followedAt: Timestamp.now(),
    };

    await userFollowsCollection.add(followData);

    // Update follower/following counts
    await userProfilesCollection.doc(followerId).update({
      followingCount: FieldValue.increment(1),
    });
    await userProfilesCollection.doc(followingId).update({
      followersCount: FieldValue.increment(1),
    });

    // Create activity
    const followerProfile = await userProfilesCollection.doc(followerId).get();
    const followingProfile = await userProfilesCollection.doc(followingId).get();

    if (followerProfile.exists && followingProfile.exists) {
      const followerData = followerProfile.data() as UserProfile;
      const followingData = followingProfile.data() as UserProfile;

      await activityFeedCollection.add({
        userId: followerId,
        username: followerData.username,
        userAvatarUrl: followerData.avatarUrl || null,
        activityType: 'followUser',
        timestamp: Timestamp.now(),
        followedUserId: followingId,
        followedUsername: followingData.username,
      });
    }

    return res.status(201).json({
      success: true,
      message: "User followed successfully",
    });
  } catch (error) {
    console.error("Error following user:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to follow user",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Unfollow a user
 * DELETE /api/v1/social/follow
 */
export const unfollowUser = async (req: Request, res: Response) => {
  try {
    const { followerId, followingId } = req.body;

    if (!followerId || !followingId) {
      return res.status(400).json({
        success: false,
        message: "followerId and followingId are required",
      });
    }

    // Find and delete follow relationship
    const followQuery = await userFollowsCollection
      .where("followerId", "==", followerId)
      .where("followingId", "==", followingId)
      .limit(1)
      .get();

    if (followQuery.empty) {
      return res.status(404).json({
        success: false,
        message: "Follow relationship not found",
      });
    }

    await followQuery.docs[0].ref.delete();

    // Update follower/following counts
    await userProfilesCollection.doc(followerId).update({
      followingCount: FieldValue.increment(-1),
    });
    await userProfilesCollection.doc(followingId).update({
      followersCount: FieldValue.increment(-1),
    });

    return res.status(200).json({
      success: true,
      message: "User unfollowed successfully",
    });
  } catch (error) {
    console.error("Error unfollowing user:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to unfollow user",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Check if following a user
 * GET /api/v1/social/follow/check/:followerId/:followingId
 */
export const checkFollowing = async (req: Request, res: Response) => {
  try {
    const { followerId, followingId } = req.params;

    const followQuery = await userFollowsCollection
      .where("followerId", "==", followerId)
      .where("followingId", "==", followingId)
      .limit(1)
      .get();

    return res.status(200).json({
      success: true,
      isFollowing: !followQuery.empty,
    });
  } catch (error) {
    console.error("Error checking follow status:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to check follow status",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get followers of a user
 * GET /api/v1/social/followers/:userId
 */
export const getFollowers = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const followersQuery = await userFollowsCollection
      .where("followingId", "==", userId)
      .get();

    const followerIds = followersQuery.docs.map((doc) => doc.data().followerId);

    // Fetch follower profiles
    const followers: any[] = [];
    for (const followerId of followerIds) {
      const profileDoc = await userProfilesCollection.doc(followerId).get();
      if (profileDoc.exists) {
        const profileData = profileDoc.data();
        const convertedProfile = convertTimestampsToISO(profileData);
        followers.push({ id: profileDoc.id, ...convertedProfile });
      }
    }

    return res.status(200).json({
      success: true,
      followers,
      count: followers.length,
    });
  } catch (error) {
    console.error("Error fetching followers:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch followers",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get users that a user follows
 * GET /api/v1/social/following/:userId
 */
export const getFollowing = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const followingQuery = await userFollowsCollection
      .where("followerId", "==", userId)
      .get();

    const followingIds = followingQuery.docs.map((doc) => doc.data().followingId);

    // Fetch following profiles
    const following: any[] = [];
    for (const followingId of followingIds) {
      const profileDoc = await userProfilesCollection.doc(followingId).get();
      if (profileDoc.exists) {
        const profileData = profileDoc.data();
        const convertedProfile = convertTimestampsToISO(profileData);
        following.push({ id: profileDoc.id, ...convertedProfile });
      }
    }

    return res.status(200).json({
      success: true,
      following,
      count: following.length,
    });
  } catch (error) {
    console.error("Error fetching following:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch following",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

// ===== READING LISTS =====

/**
 * Create a reading list
 * POST /api/v1/social/reading-lists
 */
export const createReadingList = async (req: Request, res: Response) => {
  try {
    const { ownerId, name, description, visibility = 'public', tags = [] }: CreateReadingListRequest = req.body;

    if (!ownerId || !name) {
      return res.status(400).json({
        success: false,
        message: "ownerId and name are required",
      });
    }

    // Get owner profile
    const ownerProfile = await userProfilesCollection.doc(ownerId).get();
    if (!ownerProfile.exists) {
      return res.status(404).json({
        success: false,
        message: "Owner profile not found",
      });
    }

    const ownerData = ownerProfile.data() as UserProfile;

    const listData: ReadingList = {
      name,
      description: description || "",
      ownerId,
      ownerName: ownerData.username,
      articleIds: [],
      collaboratorIds: [],
      visibility,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      tags,
      isCollaborative: false,
    };

    const docRef = await readingListsCollection.add(listData);

    // Update user's collection count
    await userProfilesCollection.doc(ownerId).update({
      collectionsCount: FieldValue.increment(1),
    });

    // Create activity
    await activityFeedCollection.add({
      userId: ownerId,
      username: ownerData.username,
      userAvatarUrl: ownerData.avatarUrl || null,
      activityType: 'createList',
      timestamp: Timestamp.now(),
      listId: docRef.id,
      listName: name,
    });

    return res.status(201).json({
      success: true,
      message: "Reading list created successfully",
      listId: docRef.id,
    });
  } catch (error) {
    console.error("Error creating reading list:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to create reading list",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get user's reading lists
 * GET /api/v1/social/reading-lists/:userId
 */
export const getUserReadingLists = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const listsQuery = await readingListsCollection
      .where("ownerId", "==", userId)
      .orderBy("updatedAt", "desc")
      .get();

    const lists = listsQuery.docs.map((doc) => {
      const listData = doc.data();
      const convertedList = convertTimestampsToISO(listData);
      return {
        id: doc.id,
        ...convertedList,
      };
    });

    return res.status(200).json({
      success: true,
      lists,
      count: lists.length,
    });
  } catch (error) {
    console.error("Error fetching reading lists:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch reading lists",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get public reading lists
 * GET /api/v1/social/reading-lists/public
 */
export const getPublicReadingLists = async (req: Request, res: Response) => {
  try {
    const { limit = "50" } = req.query;
    const limitNum = parseInt(limit as string) || 50;

    const listsQuery = await readingListsCollection
      .where("visibility", "==", "public")
      .orderBy("updatedAt", "desc")
      .limit(limitNum)
      .get();

    const lists = listsQuery.docs.map((doc) => {
      const listData = doc.data();
      const convertedList = convertTimestampsToISO(listData);
      return {
        id: doc.id,
        ...convertedList,
      };
    });

    return res.status(200).json({
      success: true,
      lists,
      count: lists.length,
    });
  } catch (error) {
    console.error("Error fetching public lists:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch public lists",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Add article to reading list
 * POST /api/v1/social/reading-lists/articles
 */
export const addArticleToList = async (req: Request, res: Response) => {
  try {
    const { listId, articleId }: AddArticleToListRequest = req.body;

    if (!listId || !articleId) {
      return res.status(400).json({
        success: false,
        message: "listId and articleId are required",
      });
    }

    const listDoc = await readingListsCollection.doc(listId).get();
    if (!listDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Reading list not found",
      });
    }

    const listData = listDoc.data() as ReadingList;

    if (listData.articleIds.includes(articleId)) {
      return res.status(200).json({
        success: true,
        message: "Article already in list",
        alreadyAdded: true,
      });
    }

    await readingListsCollection.doc(listId).update({
      articleIds: FieldValue.arrayUnion(articleId),
      updatedAt: Timestamp.now(),
    });

    return res.status(200).json({
      success: true,
      message: "Article added to list successfully",
    });
  } catch (error) {
    console.error("Error adding article to list:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to add article to list",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get activity feed for a user
 * GET /api/v1/social/activity/:userId?limit=50
 */
export const getActivityFeed = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const { limit = "50" } = req.query;
    const limitNum = parseInt(limit as string) || 50;

    // Get users that current user follows
    const followingQuery = await userFollowsCollection
      .where("followerId", "==", userId)
      .get();

    const followingIds = followingQuery.docs.map((doc) => doc.data().followingId);

    // Include user's own activities
    followingIds.push(userId);

    if (followingIds.length === 0) {
      return res.status(200).json({
        success: true,
        activities: [],
        count: 0,
      });
    }

    // Fetch activities from followed users (Firestore 'in' query limits to 10 items)
    const activities: any[] = [];

    // Split into chunks of 10 for Firestore 'in' query limitation
    const chunks = [];
    for (let i = 0; i < followingIds.length; i += 10) {
      chunks.push(followingIds.slice(i, i + 10));
    }

    for (const chunk of chunks) {
      const activitiesQuery = await activityFeedCollection
        .where("userId", "in", chunk)
        .orderBy("timestamp", "desc")
        .limit(limitNum)
        .get();

      activitiesQuery.docs.forEach((doc) => {
        const activityData = doc.data();
        const convertedActivity = convertTimestampsToISO(activityData);
        activities.push({ id: doc.id, ...convertedActivity });
      });
    }

    // Sort all activities by timestamp and limit
    const sortedActivities = activities
      .sort((a, b) => {
        const aTime = a.timestamp.toDate ? a.timestamp.toDate().getTime() : new Date(a.timestamp).getTime();
        const bTime = b.timestamp.toDate ? b.timestamp.toDate().getTime() : new Date(b.timestamp).getTime();
        return bTime - aTime;
      })
      .slice(0, limitNum);

    return res.status(200).json({
      success: true,
      activities: sortedActivities,
      count: sortedActivities.length,
    });
  } catch (error) {
    console.error("Error fetching activity feed:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch activity feed",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
