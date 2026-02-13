import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import {
  UnsaveArticleRequest,
} from "../models/saved-article.model";
import { Timestamp } from "firebase-admin/firestore";

const savedArticlesCollection = db.collection("savedArticles");

type SavedArticleRecord = {
  id: string;
  userId: string;
  articleId: string;
  articleData: Record<string, any> | null;
  savedAt: Timestamp;
};

type CacheEntry<T> = {
  value: T;
  expiresAtMs: number;
};

const USER_SAVED_CACHE_TTL_MS = 2 * 60 * 1000;
const QUERY_CACHE_TTL_MS = 60 * 1000;

const userSavedCache = new Map<string, CacheEntry<SavedArticleRecord[]>>();
const queryCache = new Map<string, CacheEntry<Record<string, any>>>();

function setPrivateCache(res: Response, maxAgeSeconds = 45, staleSeconds = 120) {
  res.set("Cache-Control", `private, max-age=${maxAgeSeconds}, stale-while-revalidate=${staleSeconds}`);
}

function getCachedValue<T>(cache: Map<string, CacheEntry<T>>, key: string): T | null {
  const entry = cache.get(key);
  if (!entry) return null;
  if (Date.now() >= entry.expiresAtMs) {
    cache.delete(key);
    return null;
  }
  return entry.value;
}

function setCachedValue<T>(cache: Map<string, CacheEntry<T>>, key: string, value: T, ttlMs: number) {
  cache.set(key, {
    value,
    expiresAtMs: Date.now() + ttlMs,
  });
}

function invalidateUserCaches(userId: string) {
  userSavedCache.delete(userId);
  for (const key of queryCache.keys()) {
    if (key.startsWith(`${userId}|`)) {
      queryCache.delete(key);
    }
  }
}

async function getUserSavedRecords(userId: string): Promise<SavedArticleRecord[]> {
  const cached = getCachedValue(userSavedCache, userId);
  if (cached) return cached;

  const snapshot = await savedArticlesCollection
    .where("userId", "==", userId)
    .orderBy("savedAt", "desc")
    .get();

  const records = snapshot.docs.map((doc) => {
    const data = doc.data() as any;
    return {
      id: doc.id,
      userId: data.userId,
      articleId: data.articleId,
      articleData: data.articleData ?? null,
      savedAt: data.savedAt instanceof Timestamp ? data.savedAt : Timestamp.now(),
    } as SavedArticleRecord;
  });

  setCachedValue(userSavedCache, userId, records, USER_SAVED_CACHE_TTL_MS);
  return records;
}

function toArticleDate(value: unknown): number {
  if (!value) return 0;
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? 0 : parsed;
  }
  return 0;
}

function toQueryString(value: unknown): string {
  if (value == null) return "";
  if (typeof value === "string") return value;
  if (Array.isArray(value)) {
    return toQueryString(value[0]);
  }
  return "";
}

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
    invalidateUserCaches(userId);

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
    invalidateUserCaches(userId);

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
    const userId = toQueryString(req.params.userId);
    setPrivateCache(res, 45, 120);

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const includeArticles = toQueryString(req.query.includeArticles) !== "false";
    const category = toQueryString(req.query.category).trim().toLowerCase();
    const search = toQueryString(req.query.search).trim().toLowerCase();
    const sort = (toQueryString(req.query.sort) || "recent").trim().toLowerCase();
    const limit = Math.min(100, Math.max(1, parseInt(toQueryString(req.query.limit) || "50", 10)));
    const offset = Math.max(0, parseInt(toQueryString(req.query.offset) || "0", 10));

    const queryKey = `${userId}|${includeArticles}|${category}|${search}|${sort}|${limit}|${offset}`;
    const cachedResponse = getCachedValue(queryCache, queryKey);
    if (cachedResponse) {
      return res.status(200).json(cachedResponse);
    }

    let records = await getUserSavedRecords(userId);

    if (category) {
      records = records.filter((item) => {
        const categories = Array.isArray(item.articleData?.category)
          ? (item.articleData?.category as unknown[])
          : [];
        return categories.some((c) => String(c).toLowerCase() == category);
      });
    }

    if (search) {
      records = records.filter((item) => {
        const title = (item.articleData?.title || "").toString().toLowerCase();
        const description = (item.articleData?.description || "").toString().toLowerCase();
        const sourceName = (item.articleData?.source_name || "").toString().toLowerCase();
        return title.includes(search) || description.includes(search) || sourceName.includes(search);
      });
    }

    switch (sort) {
      case "oldest":
        records = records.sort(
          (a, b) => a.savedAt.toDate().getTime() - b.savedAt.toDate().getTime(),
        );
        break;
      case "source":
        records = records.sort((a, b) => {
          const aSource = (a.articleData?.source_name || "").toString().toLowerCase();
          const bSource = (b.articleData?.source_name || "").toString().toLowerCase();
          return aSource.localeCompare(bSource);
        });
        break;
      case "published":
        records = records.sort((a, b) => {
          const aDate = toArticleDate(a.articleData?.pubDate);
          const bDate = toArticleDate(b.articleData?.pubDate);
          return bDate - aDate;
        });
        break;
      case "recent":
      default:
        records = records.sort(
          (a, b) => b.savedAt.toDate().getTime() - a.savedAt.toDate().getTime(),
        );
        break;
    }

    const total = records.length;
    const paginated = records.slice(offset, offset + limit);
    const articleIds = paginated.map((item) => item.articleId);
    const articles = includeArticles
      ? paginated
          .map((item) => item.articleData)
          .filter((item): item is Record<string, any> => !!item)
      : [];

    const responsePayload = {
      success: true,
      articleIds,
      articles,
      total,
      count: articleIds.length,
      offset,
      limit,
      source: "database",
    };
    setCachedValue(queryCache, queryKey, responsePayload, QUERY_CACHE_TTL_MS);

    return res.status(200).json({
      ...responsePayload,
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
