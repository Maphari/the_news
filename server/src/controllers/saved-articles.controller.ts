import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import {
  SavedArticle,
  SaveArticleRequest,
  UnsaveArticleRequest,
} from "../models/saved-article.model";
import { Timestamp } from "firebase-admin/firestore";

const savedArticlesCollection = db.collection("savedArticles");

/**
 * Save an article for a user
 * POST /api/v1/saved-articles
 */
export const saveArticle = async (req: Request, res: Response) => {
  try {
    const { userId, articleId, articleData }: any = req.body;

    if (!userId || !articleId) {
      return res.status(400).json({
        success: false,
        message: "userId and articleId are required",
      });
    }

    // Check if article is already saved
    const existingQuery = await savedArticlesCollection
      .where("userId", "==", userId)
      .where("articleId", "==", articleId)
      .limit(1)
      .get();

    if (!existingQuery.empty) {
      return res.status(200).json({
        success: true,
        message: "Article already saved",
        alreadySaved: true,
      });
    }

    // Save the article with full article data
    const savedArticle: any = {
      userId,
      articleId,
      articleData: articleData || null, // Store full article JSON
      savedAt: Timestamp.now(),
    };

    const docRef = await savedArticlesCollection.add(savedArticle);

    return res.status(201).json({
      success: true,
      message: "Article saved successfully",
      id: docRef.id,
    });
  } catch (error) {
    console.error("Error saving article:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to save article",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Unsave (remove) an article for a user
 * DELETE /api/v1/saved-articles
 */
export const unsaveArticle = async (req: Request, res: Response) => {
  try {
    const { userId, articleId }: UnsaveArticleRequest = req.body;

    if (!userId || !articleId) {
      return res.status(400).json({
        success: false,
        message: "userId and articleId are required",
      });
    }

    // Find and delete the saved article
    const query = await savedArticlesCollection
      .where("userId", "==", userId)
      .where("articleId", "==", articleId)
      .limit(1)
      .get();

    if (query.empty) {
      return res.status(404).json({
        success: false,
        message: "Saved article not found",
      });
    }

    // Delete the document
    await query.docs[0].ref.delete();

    return res.status(200).json({
      success: true,
      message: "Article unsaved successfully",
    });
  } catch (error) {
    console.error("Error unsaving article:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to unsave article",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get all saved article IDs for a user (with full article data)
 * GET /api/v1/saved-articles/:userId
 */
export const getSavedArticleIds = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    // Get all saved articles for this user
    const query = await savedArticlesCollection
      .where("userId", "==", userId)
      .orderBy("savedAt", "desc")
      .get();

    // Extract article IDs and full article data
    const articleIds: string[] = [];
    const articles: any[] = [];

    query.docs.forEach((doc) => {
      const data = doc.data() as any;
      articleIds.push(data.articleId);

      // Include full article data if available
      if (data.articleData) {
        articles.push(data.articleData);
      }
    });

    return res.status(200).json({
      success: true,
      articleIds,
      articles, // Return full article objects
      count: articleIds.length,
    });
  } catch (error) {
    console.error("Error fetching saved articles:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch saved articles",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Check if an article is saved by a user
 * GET /api/v1/saved-articles/check/:userId/:articleId
 */
export const checkIfSaved = async (req: Request, res: Response) => {
  try {
    const { userId, articleId } = req.params;

    if (!userId || !articleId) {
      return res.status(400).json({
        success: false,
        message: "userId and articleId are required",
      });
    }

    const query = await savedArticlesCollection
      .where("userId", "==", userId)
      .where("articleId", "==", articleId)
      .limit(1)
      .get();

    return res.status(200).json({
      success: true,
      isSaved: !query.empty,
    });
  } catch (error) {
    console.error("Error checking if article is saved:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to check saved status",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
