import { Router } from "express";
import { cacheResponse, invalidateCache } from "../middleware/cache.middleware";
import {
  getEngagement,
  likeArticle,
  unlikeArticle,
  shareArticle,
  updateCommentCount,
} from "../controllers/engagement.controller";

const engagementRouter = Router();
const engagementReadCache = cacheResponse({
  namespace: "engagement",
  ttlSeconds: 60,
});
const invalidateEngagementCache = invalidateCache(["engagement:uid:_:"]);

// Get engagement data for an article
engagementRouter.get("/engagement/:articleId", engagementReadCache, getEngagement);

// Like an article
engagementRouter.post("/engagement/like", invalidateEngagementCache, likeArticle);

// Unlike an article
engagementRouter.delete("/engagement/like", invalidateEngagementCache, unlikeArticle);

// Share an article
engagementRouter.post("/engagement/share", invalidateEngagementCache, shareArticle);

// Update comment count
engagementRouter.put("/engagement/comments/:articleId", invalidateEngagementCache, updateCommentCount);

export default engagementRouter;
