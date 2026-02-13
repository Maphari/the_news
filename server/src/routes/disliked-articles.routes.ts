import { Router } from "express";
import {
  cacheResponse,
  extractScopedUserIds,
  invalidateCache,
} from "../middleware/cache.middleware";
import {
  dislikeArticle,
  undislikeArticle,
  getDislikedArticles,
  checkIfDisliked,
} from "../controllers/disliked-articles.controller";

const dislikedArticlesRouter = Router();
const dislikedArticlesReadCache = cacheResponse({
  namespace: "disliked-articles",
  ttlSeconds: 180,
});
const invalidateDislikedArticlesCache = invalidateCache((req) => {
  const userIds = extractScopedUserIds(req);
  if (userIds.length === 0) {
    return ["disliked-articles:uid:_:"];
  }
  return [
    "disliked-articles:uid:_:",
    ...userIds.map((id) => `disliked-articles:uid:${id}:`),
  ];
});

// Mark article as disliked
dislikedArticlesRouter.post(
  "/disliked-articles",
  invalidateDislikedArticlesCache,
  dislikeArticle
);

// Remove article from disliked list
dislikedArticlesRouter.delete(
  "/disliked-articles",
  invalidateDislikedArticlesCache,
  undislikeArticle
);

// Get all disliked article IDs for a user
dislikedArticlesRouter.get(
  "/disliked-articles/:userId",
  dislikedArticlesReadCache,
  getDislikedArticles
);

// Check if article is disliked
dislikedArticlesRouter.get(
  "/disliked-articles/:userId/:articleId/check",
  dislikedArticlesReadCache,
  checkIfDisliked
);

export default dislikedArticlesRouter;
