import { Router } from "express";
import {
  saveArticle,
  unsaveArticle,
  getSavedArticleIds,
  checkIfSaved,
} from "../controllers/saved-articles.controller";

const savedArticlesRouter = Router();

// Save an article
savedArticlesRouter.post("/saved-articles", saveArticle);

// Unsave an article
savedArticlesRouter.delete("/saved-articles", unsaveArticle);

// Get all saved article IDs for a user
savedArticlesRouter.get("/saved-articles/:userId", getSavedArticleIds);

// Check if an article is saved
savedArticlesRouter.get(
  "/saved-articles/check/:userId/:articleId",
  checkIfSaved
);

export default savedArticlesRouter;
