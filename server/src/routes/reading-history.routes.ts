import { Router } from "express";
import {
  cacheResponse,
  extractScopedUserIds,
  invalidateCache,
} from "../middleware/cache.middleware";
import {
  getReadingHistory,
  addReadingHistory,
  getReadingAnalytics,
  clearReadingHistory,
} from "../controllers/reading-history.controller";

const router = Router();
const readingHistoryReadCache = cacheResponse({
  namespace: "reading-history",
  ttlSeconds: 300,
});
const readingAnalyticsReadCache = cacheResponse({
  namespace: "reading-analytics",
  ttlSeconds: 300,
});
const invalidateReadingHistoryCache = invalidateCache((req) => {
  const userIds = extractScopedUserIds(req);
  if (userIds.length === 0) {
    return ["reading-history:uid:_:", "reading-analytics:uid:_:"];
  }
  return userIds.flatMap((id) => [
    `reading-history:uid:${id}:`,
    `reading-analytics:uid:${id}:`,
  ]);
});

// GET /user/reading-history/:userId - Get reading history
router.get("/reading-history/:userId", readingHistoryReadCache, getReadingHistory);

// POST /user/reading-history - Add reading history entries
router.post("/reading-history", invalidateReadingHistoryCache, addReadingHistory);

// GET /user/analytics/:userId - Get reading analytics
router.get("/analytics/:userId", readingAnalyticsReadCache, getReadingAnalytics);

// DELETE /user/reading-history/:userId - Clear reading history
router.delete(
  "/reading-history/:userId",
  invalidateReadingHistoryCache,
  clearReadingHistory
);

export default router;
