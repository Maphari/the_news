import { Router } from "express";
import {
  // User Profiles
  createOrUpdateProfile,
  getUserProfile,
  searchUsers,
  updateProfile,
  // Follow System
  followUser,
  unfollowUser,
  checkFollowing,
  getFollowers,
  getFollowing,
  // Reading Lists
  createReadingList,
  getUserReadingLists,
  getPublicReadingLists,
  addArticleToList,
  // Activity Feed
  getActivityFeed,
} from "../controllers/social.controller";

const socialRouter = Router();

// ===== USER PROFILES =====
// Create or update user profile
socialRouter.post("/social/profile", createOrUpdateProfile);

// Get user profile by ID
socialRouter.get("/social/profile/:userId", getUserProfile);

// Update user profile
socialRouter.put("/social/profile", updateProfile);

// Search users by username or display name
socialRouter.get("/social/users/search", searchUsers);

// ===== FOLLOW SYSTEM =====
// Follow a user
socialRouter.post("/social/follow", followUser);

// Unfollow a user
socialRouter.delete("/social/follow", unfollowUser);

// Check if following a user
socialRouter.get("/social/follow/check/:followerId/:followingId", checkFollowing);

// Get followers of a user
socialRouter.get("/social/followers/:userId", getFollowers);

// Get users that a user follows
socialRouter.get("/social/following/:userId", getFollowing);

// ===== READING LISTS =====
// Create a reading list
socialRouter.post("/social/reading-lists", createReadingList);

// Get user's reading lists
socialRouter.get("/social/reading-lists/:userId", getUserReadingLists);

// Get public reading lists
socialRouter.get("/social/reading-lists/public", getPublicReadingLists);

// Add article to reading list
socialRouter.post("/social/reading-lists/articles", addArticleToList);

// ===== ACTIVITY FEED =====
// Get activity feed for a user
socialRouter.get("/social/activity/:userId", getActivityFeed);

export default socialRouter;
