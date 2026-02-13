import { Router } from "express";
import {
  cacheResponse,
  extractScopedUserIds,
  invalidateCache,
} from "../middleware/cache.middleware";
import {
  // User Profiles
  createOrUpdateProfile,
  getUserProfile,
  getProfileInsights,
  getMySpaceSummary,
  searchUsers,
  getRecommendedUsers,
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
  getReadingListById,
  addArticleToList,
  removeArticleFromList,
  addCollaboratorToList,
  reorderReadingListArticles,
  // Activity Feed
  getActivityFeed,
  getNetworkHighlights,
  getFeedSummary,
  getPeopleSummary,
  // Network Posts
  createNetworkPost,
  getNetworkPosts,
  likeNetworkPost,
  unlikeNetworkPost,
  commentOnNetworkPost,
} from "../controllers/social.controller";

const socialRouter = Router();
const socialReadCache = cacheResponse({
  namespace: "social",
  ttlSeconds: 90,
});
const invalidateSocialCacheForUsers = invalidateCache((req) => {
  const userIds = extractScopedUserIds(req);
  if (userIds.length === 0) {
    return ["social:uid:_:"];
  }
  return userIds.map((id) => `social:uid:${id}:`);
});

// ===== USER PROFILES =====
// Create or update user profile
socialRouter.post("/social/profile", invalidateSocialCacheForUsers, createOrUpdateProfile);

// Get user profile by ID
socialRouter.get("/social/profile/:userId", socialReadCache, getUserProfile);

// Get profile insights
socialRouter.get("/social/profile/:userId/insights", socialReadCache, getProfileInsights);

// My Space summary (aggregated social payload)
socialRouter.get("/social/my-space/:userId", socialReadCache, getMySpaceSummary);

// Update user profile
socialRouter.put("/social/profile", invalidateSocialCacheForUsers, updateProfile);

// Search users by username or display name
socialRouter.get("/social/users/search", socialReadCache, searchUsers);

// Recommended users to follow
socialRouter.get("/social/users/recommended/:userId", socialReadCache, getRecommendedUsers);

// ===== FOLLOW SYSTEM =====
// Follow a user
socialRouter.post("/social/follow", invalidateSocialCacheForUsers, followUser);

// Unfollow a user
socialRouter.delete("/social/follow", invalidateSocialCacheForUsers, unfollowUser);

// Check if following a user
socialRouter.get("/social/follow/check/:followerId/:followingId", socialReadCache, checkFollowing);

// Get followers of a user
socialRouter.get("/social/followers/:userId", socialReadCache, getFollowers);

// Get users that a user follows
socialRouter.get("/social/following/:userId", socialReadCache, getFollowing);

// ===== READING LISTS =====
// Create a reading list
socialRouter.post("/social/reading-lists", invalidateSocialCacheForUsers, createReadingList);

// Get public reading lists
socialRouter.get("/social/reading-lists/public", socialReadCache, getPublicReadingLists);
socialRouter.get("/social/reading-lists/list/:listId", socialReadCache, getReadingListById);

// Add article to reading list
socialRouter.post("/social/reading-lists/articles", invalidateSocialCacheForUsers, addArticleToList);
socialRouter.delete("/social/reading-lists/articles", invalidateSocialCacheForUsers, removeArticleFromList);
socialRouter.put("/social/reading-lists/order", invalidateSocialCacheForUsers, reorderReadingListArticles);
socialRouter.post("/social/reading-lists/collaborators", invalidateSocialCacheForUsers, addCollaboratorToList);

// Get user's reading lists
socialRouter.get("/social/reading-lists/:userId", socialReadCache, getUserReadingLists);

// ===== ACTIVITY FEED =====
// Get activity feed for a user
socialRouter.get("/social/activity/:userId", socialReadCache, getActivityFeed);

// Get deduplicated network highlights (shared articles)
socialRouter.get("/social/highlights/:userId", socialReadCache, getNetworkHighlights);

// Feed summary (pre-ranked tab payload)
socialRouter.get("/social/feed-summary/:userId", socialReadCache, getFeedSummary);
socialRouter.get("/social/people-summary/:userId", socialReadCache, getPeopleSummary);

// ===== NETWORK POSTS =====
socialRouter.post("/social/posts", invalidateSocialCacheForUsers, createNetworkPost);
socialRouter.get("/social/posts/:userId", socialReadCache, getNetworkPosts);
socialRouter.post("/social/posts/:postId/like", invalidateSocialCacheForUsers, likeNetworkPost);
socialRouter.delete("/social/posts/:postId/like", invalidateSocialCacheForUsers, unlikeNetworkPost);
socialRouter.post("/social/posts/:postId/comments", invalidateSocialCacheForUsers, commentOnNetworkPost);

export default socialRouter;
