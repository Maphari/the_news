import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import { Timestamp } from "firebase-admin/firestore";
import {
  DislikedArticle,
  DislikeArticleRequest,
  DislikedArticlesResponse,
} from "../models/disliked-article.model";

const dislikedArticlesCollection = db.collection("dislikedArticles");

/**
 * Mark an article as disliked by user
 * POST /api/v1/disliked-articles
 */
export const dislikeArticle = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { userId, articleId }: DislikeArticleRequest = req.body;

    if (!userId || !articleId) {
      res.status(400).json({
        success: false,
        message: "userId and articleId are required",
      });
      return;
    }

    // Check if already disliked
    const existingDislike = await dislikedArticlesCollection
      .where("userId", "==", userId)
      .where("articleId", "==", articleId)
      .limit(1)
      .get();

    if (!existingDislike.empty) {
      res.status(200).json({
        success: true,
        message: "Article already disliked",
      });
      return;
    }

    // Add dislike record
    const dislikedArticle: DislikedArticle = {
      userId,
      articleId,
      dislikedAt: Timestamp.now(),
    };

    await dislikedArticlesCollection.add(dislikedArticle);

    res.status(200).json({
      success: true,
      message: "Article disliked successfully",
    });
  } catch (error) {
    console.error("Error disliking article:", error);
    res.status(500).json({
      success: false,
      message: "Failed to dislike article",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Remove article from disliked list
 * DELETE /api/v1/disliked-articles
 */
export const undislikeArticle = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { userId, articleId }: DislikeArticleRequest = req.body;

    if (!userId || !articleId) {
      res.status(400).json({
        success: false,
        message: "userId and articleId are required",
      });
      return;
    }

    // Find the dislike record
    const dislikeQuery = await dislikedArticlesCollection
      .where("userId", "==", userId)
      .where("articleId", "==", articleId)
      .limit(1)
      .get();

    if (dislikeQuery.empty) {
      res.status(404).json({
        success: false,
        message: "Article not found in disliked list",
      });
      return;
    }

    // Delete the dislike record
    await dislikeQuery.docs[0].ref.delete();

    res.status(200).json({
      success: true,
      message: "Article removed from disliked list",
    });
  } catch (error) {
    console.error("Error undisliking article:", error);
    res.status(500).json({
      success: false,
      message: "Failed to undislike article",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get all disliked article IDs for a user
 * GET /api/v1/disliked-articles/:userId
 */
export const getDislikedArticles = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { userId } = req.params;

    if (!userId) {
      res.status(400).json({
        success: false,
        message: "userId is required",
      });
      return;
    }

    // Fetch all disliked articles for this user
    const dislikedQuery = await dislikedArticlesCollection
      .where("userId", "==", userId)
      .get();

    const articleIds = dislikedQuery.docs.map((doc) => {
      const data = doc.data() as DislikedArticle;
      return data.articleId;
    });

    const response: DislikedArticlesResponse = {
      success: true,
      articleIds,
      count: articleIds.length,
    };

    res.status(200).json(response);
  } catch (error) {
    console.error("Error fetching disliked articles:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch disliked articles",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Check if an article is disliked by user
 * GET /api/v1/disliked-articles/:userId/:articleId/check
 */
export const checkIfDisliked = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { userId, articleId } = req.params;

    if (!userId || !articleId) {
      res.status(400).json({
        success: false,
        message: "userId and articleId are required",
      });
      return;
    }

    const dislikeQuery = await dislikedArticlesCollection
      .where("userId", "==", userId)
      .where("articleId", "==", articleId)
      .limit(1)
      .get();

    res.status(200).json({
      success: true,
      isDisliked: !dislikeQuery.empty,
    });
  } catch (error) {
    console.error("Error checking if article is disliked:", error);
    res.status(500).json({
      success: false,
      message: "Failed to check dislike status",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
