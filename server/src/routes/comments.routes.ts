import { Router } from "express";
import {
  getComments,
  addComment,
  updateComment,
  deleteComment,
  likeComment,
  unlikeComment,
} from "../controllers/comments.controller";

const commentsRouter = Router();

// Get comments for an article
commentsRouter.get("/comments/:articleId", getComments);

// Add a comment
commentsRouter.post("/comments", addComment);

// Update a comment
commentsRouter.put("/comments/:commentId", updateComment);

// Delete a comment
commentsRouter.delete("/comments/:commentId", deleteComment);

// Like a comment
commentsRouter.post("/comments/like", likeComment);

// Unlike a comment
commentsRouter.delete("/comments/like", unlikeComment);

export default commentsRouter;
