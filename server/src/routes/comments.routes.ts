import { Router } from "express";
import {
  cacheResponse,
  extractScopedUserIds,
  invalidateCache,
} from "../middleware/cache.middleware";
import {
  getComments,
  addComment,
  updateComment,
  deleteComment,
  likeComment,
  unlikeComment,
} from "../controllers/comments.controller";

const commentsRouter = Router();
const commentsReadCache = cacheResponse({
  namespace: "comments",
  ttlSeconds: 60,
});
const invalidateCommentsCache = invalidateCache((req) => {
  const userIds = extractScopedUserIds(req);
  if (userIds.length === 0) {
    return ["comments:uid:_:"];
  }
  return ["comments:uid:_:", ...userIds.map((id) => `comments:uid:${id}:`)];
});

// Get comments for an article
commentsRouter.get("/comments/:articleId", commentsReadCache, getComments);

// Add a comment
commentsRouter.post("/comments", invalidateCommentsCache, addComment);

// Update a comment
commentsRouter.put("/comments/:commentId", invalidateCommentsCache, updateComment);

// Delete a comment
commentsRouter.delete("/comments/:commentId", invalidateCommentsCache, deleteComment);

// Like a comment
commentsRouter.post("/comments/like", invalidateCommentsCache, likeComment);

// Unlike a comment
commentsRouter.delete("/comments/like", invalidateCommentsCache, unlikeComment);

export default commentsRouter;
