import { Router } from "express";
import {
  cacheResponse,
  extractScopedUserIds,
  invalidateCache,
} from "../middleware/cache.middleware";
import {
  saveArticle,
  unsaveArticle,
  getSavedArticleIds,
  checkIfSaved,
} from "../controllers/saved-articles.controller";

const savedArticlesRouter = Router();
const invalidateSavedUserCache = invalidateCache((req) => {
  const userIds = extractScopedUserIds(req);
  if (userIds.length === 0) {
    return ["saved-articles:uid:_:", "saved-articles-check:uid:_:"];
  }

  return userIds.flatMap((id) => [
    `saved-articles:uid:${id}:`,
    `saved-articles-check:uid:${id}:`,
  ]);
});

// Save an article
savedArticlesRouter.post(
  "/saved-articles",
  invalidateSavedUserCache,
  saveArticle
);

// Unsave an article
savedArticlesRouter.delete(
  "/saved-articles",
  invalidateSavedUserCache,
  unsaveArticle
);

// Get all saved article IDs for a user
savedArticlesRouter.get(
  "/saved-articles/:userId",
  cacheResponse({
    namespace: "saved-articles",
    ttlSeconds: 90,
  }),
  getSavedArticleIds
);

// Check if an article is saved
savedArticlesRouter.get(
  "/saved-articles/check/:userId/:articleId",
  cacheResponse({
    namespace: "saved-articles-check",
    ttlSeconds: 60,
  }),
  checkIfSaved
);

export default savedArticlesRouter;
