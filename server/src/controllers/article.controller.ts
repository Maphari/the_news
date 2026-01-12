import { Request, Response } from "express";
import { db, admin } from "../config/firebase.connection";
import { Article, ArticleBatchRequest, ArticleSaveResponse } from "../models/article.model";

/**
 * Save batch of articles to database
 * POST /api/v1/articles/batch
 */
async function saveArticlesBatch(req: Request, res: Response) {
  console.log('Running');
  try {
    const { articles }: ArticleBatchRequest = req.body;

    console.log(articles);

    // Validate input
    if (!articles || !Array.isArray(articles) || articles.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid request: articles array is required",
      });
    }

    let savedCount = 0;
    let skippedCount = 0;
    const now = admin.firestore.Timestamp.now();
    const batch = db.batch();
    const articlesCollection = db.collection("articles");

    // Get all article IDs to check for duplicates in one query
    const articleIds = articles
      .filter(a => a.articleId && a.title)
      .map(a => a.articleId);

    if (articleIds.length === 0) {
      return res.status(200).json({
        success: true,
        message: "No valid articles to save",
        savedCount: 0,
        skippedCount: articles.length,
      });
    }

    // Check existing articles in batches (Firestore 'in' supports up to 10 items)
    const existingArticleIds = new Set<string>();
    const batchSize = 10;

    for (let i = 0; i < articleIds.length; i += batchSize) {
      const batchIds = articleIds.slice(i, i + batchSize);
      const existingSnapshot = await articlesCollection
        .where("articleId", "in", batchIds)
        .select("articleId")
        .get();

      existingSnapshot.docs.forEach(doc => {
        const data = doc.data();
        if (data.articleId) {
          existingArticleIds.add(data.articleId);
        }
      });
    }

    // Process each article
    for (const article of articles) {
      if (!article.articleId || !article.title) {
        skippedCount++;
        continue;
      }

      // Check if article already exists
      if (existingArticleIds.has(article.articleId)) {
        skippedCount++;
        continue;
      }

      // Prepare article data
      const articleData: Partial<Article> = {
        ...article,
        createdAt: now,
        updatedAt: now,
      };

      // Add to batch
      const articleRef = articlesCollection.doc();
      batch.set(articleRef, articleData);
      savedCount++;
    }

    // Commit batch
    if (savedCount > 0) {
      await batch.commit();
    }

    const response: ArticleSaveResponse = {
      success: true,
      message: `Successfully processed ${articles.length} articles`,
      savedCount,
      skippedCount,
    };

    return res.status(200).json(response);
  } catch (error) {
    console.error("Article save error:", {
      error: error instanceof Error ? error.message : "Unknown error",
      stack: error instanceof Error ? error.stack : undefined,
      timestamp: new Date().toISOString(),
    });

    return res.status(500).json({
      success: false,
      message: "An error occurred while saving articles. Please try again later.",
      savedCount: 0,
      skippedCount: 0,
      ...(process.env.NODE_ENV === "development" && {
        debug: {
          error: error instanceof Error ? error.message : String(error),
          type: error instanceof Error ? error.constructor.name : typeof error,
        },
      }),
    });
  }
}

/**
 * Get articles with filters
 * GET /api/v1/articles?category=technology&limit=10
 */
async function getArticles(req: Request, res: Response) {
  try {
    const { category, limit = 20, offset = 0 } = req.query;

    let query = db.collection("articles").orderBy("pubDate", "desc");

    // Apply filters
    if (category) {
      query = query.where("category", "array-contains", category);
    }

    // Apply pagination
    const snapshot = await query
      .limit(Number(limit))
      .offset(Number(offset))
      .get();

    const articles = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return res.status(200).json({
      success: true,
      count: articles.length,
      articles,
    });
  } catch (error) {
    console.error("Article fetch error:", {
      error: error instanceof Error ? error.message : "Unknown error",
      timestamp: new Date().toISOString(),
    });

    return res.status(500).json({
      success: false,
      message: "An error occurred while fetching articles.",
      ...(process.env.NODE_ENV === "development" && {
        debug: {
          error: error instanceof Error ? error.message : String(error),
        },
      }),
    });
  }
}

/**
 * Get single article by ID
 * GET /api/v1/articles/:articleId
 */
async function getArticleById(req: Request, res: Response) {
  try {
    const { articleId } = req.params;

    const snapshot = await db
      .collection("articles")
      .where("articleId", "==", articleId)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return res.status(404).json({
        success: false,
        message: "Article not found",
      });
    }

    const article = {
      id: snapshot.docs[0].id,
      ...snapshot.docs[0].data(),
    };

    return res.status(200).json({
      success: true,
      article,
    });
  } catch (error) {
    console.error("Article fetch error:", {
      error: error instanceof Error ? error.message : "Unknown error",
      timestamp: new Date().toISOString(),
    });

    return res.status(500).json({
      success: false,
      message: "An error occurred while fetching the article.",
      ...(process.env.NODE_ENV === "development" && {
        debug: {
          error: error instanceof Error ? error.message : String(error),
        },
      }),
    });
  }
}

export { saveArticlesBatch, getArticles, getArticleById };
