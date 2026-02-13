import { Router } from "express";
import {
  cacheResponse,
  extractScopedUserIds,
  invalidateCache,
} from "../middleware/cache.middleware";
import {
  getUserPreferences,
  updateUserPreferences,
  deleteUserPreferences,
} from "../controllers/user-preferences.controller";

const router = Router();
const userPreferencesReadCache = cacheResponse({
  namespace: "user-preferences",
  ttlSeconds: 900,
});
const invalidateUserPreferencesCache = invalidateCache((req) => {
  const userIds = extractScopedUserIds(req);
  if (userIds.length === 0) {
    return ["user-preferences:uid:_:"];
  }
  return [
    "user-preferences:uid:_:",
    ...userIds.map((id) => `user-preferences:uid:${id}:`),
  ];
});

// GET /user/preferences/:userId - Get user preferences
router.get("/preferences/:userId", userPreferencesReadCache, getUserPreferences);

// PUT /user/preferences - Update user preferences
router.put("/preferences", invalidateUserPreferencesCache, updateUserPreferences);

// DELETE /user/preferences/:userId - Delete user preferences
router.delete(
  "/preferences/:userId",
  invalidateUserPreferencesCache,
  deleteUserPreferences
);

export default router;
