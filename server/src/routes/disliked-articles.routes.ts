import { Router } from "express";
import {
  dislikeArticle,
  undislikeArticle,
  getDislikedArticles,
  checkIfDisliked,
} from "../controllers/disliked-articles.controller";

const dislikedArticlesRouter = Router();

// Mark article as disliked
dislikedArticlesRouter.post("/disliked-articles", dislikeArticle);

// Remove article from disliked list
dislikedArticlesRouter.delete("/disliked-articles", undislikeArticle);

// Get all disliked article IDs for a user
dislikedArticlesRouter.get("/disliked-articles/:userId", getDislikedArticles);

// Check if article is disliked
dislikedArticlesRouter.get(
  "/disliked-articles/:userId/:articleId/check",
  checkIfDisliked
);

export default dislikedArticlesRouter;
