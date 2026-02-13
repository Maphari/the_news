import { Request, Response } from "express";
import { db, admin } from "../config/firebase.connection";
import { Article, ArticleBatchRequest, ArticleSaveResponse } from "../models/article.model";

type CacheEntry = {
  expiresAt: number;
  payload: unknown;
};

type PopularSource = {
  name: string;
  articleCount: number;
  iconUrl: string;
};

const responseCache = new Map<string, CacheEntry>();
const CACHE_TTL_MS = 3 * 60 * 1000;

function getCachedPayload<T>(key: string): T | null {
  const entry = responseCache.get(key);
  if (!entry) {
    return null;
  }
  if (entry.expiresAt <= Date.now()) {
    responseCache.delete(key);
    return null;
  }
  return entry.payload as T;
}

function setCachedPayload(key: string, payload: unknown, ttlMs = CACHE_TTL_MS): void {
  responseCache.set(key, {
    expiresAt: Date.now() + ttlMs,
    payload,
  });
}

function clearArticleCache(): void {
  responseCache.clear();
}

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
      clearArticleCache();
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

async function getDislikedArticleIds(userId?: string): Promise<Set<string>> {
  if (!userId || userId.trim().length === 0) {
    return new Set();
  }

  const dislikedSnapshot = await db
    .collection("dislikedArticles")
    .where("userId", "==", userId)
    .select("articleId")
    .get();

  return new Set(
    dislikedSnapshot.docs
      .map((doc) => doc.data().articleId)
      .filter((id): id is string => typeof id === "string" && id.trim().length > 0)
  );
}

function coerceLimit(value: unknown, fallback: number, max: number): number {
  const parsed = parseInt(String(value ?? fallback), 10);
  if (Number.isNaN(parsed)) {
    return fallback;
  }
  return Math.max(1, Math.min(parsed, max));
}

function toSearchTokens(text: string): string[] {
  return text
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((token) => token.length >= 2 && !STOP_WORDS.has(token));
}

function buildSearchScore(article: Record<string, unknown>, query: string): number {
  const normalizedQuery = query.toLowerCase();
  const tokens = toSearchTokens(normalizedQuery);

  const title = String(article.title ?? "").toLowerCase();
  const description = String(article.description ?? "").toLowerCase();
  const sourceName = String(article.sourceName ?? "").toLowerCase();
  const keywordText = Array.isArray(article.keywords)
    ? (article.keywords as unknown[]).map((item) => String(item).toLowerCase()).join(" ")
    : "";

  let score = 0;
  if (title === normalizedQuery) score += 200;
  if (title.startsWith(normalizedQuery)) score += 80;
  if (title.includes(normalizedQuery)) score += 60;
  if (sourceName.includes(normalizedQuery)) score += 30;
  if (description.includes(normalizedQuery)) score += 25;
  if (keywordText.includes(normalizedQuery)) score += 20;

  for (const token of tokens) {
    if (title.includes(token)) score += 12;
    if (description.includes(token)) score += 4;
    if (keywordText.includes(token)) score += 6;
    if (sourceName.includes(token)) score += 5;
  }

  const ageHours = Math.max(
    1,
    (Date.now() - toDate(article.pubDate).getTime()) / (1000 * 60 * 60)
  );
  score += Math.exp(-ageHours / 72) * 10;

  return score;
}

/**
 * Search articles from database with ranking and cache
 * GET /api/v1/articles/search?query=bitcoin&userId=...&limit=20
 */
async function searchArticles(req: Request, res: Response) {
  try {
    const query = String(req.query.query ?? "").trim();
    if (query.length < 2) {
      return res.status(200).json({
        success: true,
        count: 0,
        articles: [],
      });
    }

    const userId = String(req.query.userId ?? "").trim();
    const limit = coerceLimit(req.query.limit, 20, 40);
    const cacheKey = `articles:search:${query.toLowerCase()}:${userId}:${limit}`;
    const cached = getCachedPayload<Record<string, unknown>>(cacheKey);
    if (cached) {
      homeFeedCacheMetrics.hits += 1;
      res.setHeader("x-home-feed-cache", "HIT");
      console.log(
        `Home feed cache hit (${homeFeedCacheMetrics.hits}/${homeFeedCacheMetrics.misses})`
      );
      return res.status(200).json(cached);
    }
    homeFeedCacheMetrics.misses += 1;
    res.setHeader("x-home-feed-cache", "MISS");
    console.log(
      `Home feed cache miss (${homeFeedCacheMetrics.hits}/${homeFeedCacheMetrics.misses})`
    );

    const dislikedIds = await getDislikedArticleIds(userId);
    const snapshot = await db
      .collection("articles")
      .orderBy("pubDate", "desc")
      .limit(220)
      .get();

    const ranked = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() } as Record<string, unknown>))
      .filter((article) => {
        const articleId = article.articleId;
        if (typeof articleId !== "string" || articleId.trim().length === 0) {
          return false;
        }
        if (dislikedIds.has(articleId)) {
          return false;
        }
        return buildSearchScore(article, query) > 0;
      })
      .map((article) => ({
        article,
        score: buildSearchScore(article, query),
      }))
      .sort((a, b) => b.score - a.score)
      .slice(0, limit)
      .map((entry) => transformArticleToSnakeCase(entry.article));

    const payload = {
      success: true,
      count: ranked.length,
      articles: ranked,
      source: "database",
    };
    setCachedPayload(cacheKey, payload);

    return res.status(200).json(payload);
  } catch (error) {
    console.error("Article search error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to search articles",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
}

/**
 * Get top stories for explore with backend-side ranking/caching
 * GET /api/v1/articles/top-stories?limit=6&userId=...
 */
async function getTopStories(req: Request, res: Response) {
  try {
    const limit = coerceLimit(req.query.limit, 6, 12);
    const userId = String(req.query.userId ?? "").trim();
    const cacheKey = `articles:top-stories:${limit}:${userId}`;
    const cached = getCachedPayload<Record<string, unknown>>(cacheKey);
    if (cached) {
      return res.status(200).json(cached);
    }

    const dislikedIds = await getDislikedArticleIds(userId);
    const snapshot = await db
      .collection("articles")
      .orderBy("pubDate", "desc")
      .limit(160)
      .get();

    const scored = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() } as Record<string, unknown>))
      .filter((article) => {
        const articleId = article.articleId;
        if (typeof articleId !== "string" || articleId.trim().length === 0) {
          return false;
        }
        return !dislikedIds.has(articleId);
      })
      .map((article) => {
        const ageHours = Math.max(
          1,
          (Date.now() - toDate(article.pubDate).getTime()) / (1000 * 60 * 60)
        );
        const freshness = Math.exp(-ageHours / 24) * 6;
        const priority = Number(article.sourcePriority ?? 0) * 0.7;
        const richContentBoost =
          String(article.imageUrl ?? "").length > 0 ? 0.8 : 0;
        const summaryBoost = String(article.aiSummary ?? "").length >= 80 ? 0.6 : 0;
        return {
          article,
          score: freshness + priority + richContentBoost + summaryBoost,
        };
      })
      .sort((a, b) => b.score - a.score);

    const sourceCount = new Map<string, number>();
    const categoryCount = new Map<string, number>();
    const selected: Record<string, unknown>[] = [];

    for (const candidate of scored) {
      if (selected.length >= limit) {
        break;
      }

      const source = String(candidate.article.sourceName ?? "Unknown");
      const sourceSeen = sourceCount.get(source) ?? 0;
      if (sourceSeen >= 2) {
        continue;
      }

      const categories = Array.isArray(candidate.article.category)
        ? (candidate.article.category as unknown[]).map((item) => String(item))
        : [];
      const overCategoryCap = categories.some((cat) => (categoryCount.get(cat) ?? 0) >= 3);
      if (overCategoryCap) {
        continue;
      }

      selected.push(candidate.article);
      sourceCount.set(source, sourceSeen + 1);
      for (const category of categories) {
        categoryCount.set(category, (categoryCount.get(category) ?? 0) + 1);
      }
    }

    const payload = {
      success: true,
      count: selected.length,
      articles: selected.map((article) => transformArticleToSnakeCase(article)),
    };
    setCachedPayload(cacheKey, payload);
    return res.status(200).json(payload);
  } catch (error) {
    console.error("Top stories error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get top stories",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
}

/**
 * Get popular sources from recent articles
 * GET /api/v1/articles/popular-sources?limit=8
 */
async function getPopularSources(req: Request, res: Response) {
  try {
    const limit = coerceLimit(req.query.limit, 8, 20);
    const cacheKey = `articles:popular-sources:${limit}`;
    const cached = getCachedPayload<Record<string, unknown>>(cacheKey);
    if (cached) {
      return res.status(200).json(cached);
    }

    const snapshot = await db
      .collection("articles")
      .orderBy("pubDate", "desc")
      .limit(280)
      .get();

    const sources = new Map<string, PopularSource>();

    snapshot.docs.forEach((doc) => {
      const data = doc.data() as Record<string, unknown>;
      const sourceName = String(data.sourceName ?? "").trim();
      if (!sourceName || sourceName.toLowerCase() === "unknown" || sourceName.toLowerCase() === "null") {
        return;
      }

      const current = sources.get(sourceName) ?? {
        name: sourceName,
        articleCount: 0,
        iconUrl: "",
      };
      current.articleCount += 1;
      if (!current.iconUrl) {
        current.iconUrl = String(data.sourceIcon ?? "");
      }
      sources.set(sourceName, current);
    });

    const sorted = Array.from(sources.values())
      .sort((a, b) => b.articleCount - a.articleCount)
      .slice(0, limit);

    const payload = {
      success: true,
      count: sorted.length,
      sources: sorted,
    };
    setCachedPayload(cacheKey, payload);

    return res.status(200).json(payload);
  } catch (error) {
    console.error("Popular sources error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get popular sources",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
}

/**
 * Get explore sections payload for one-shot Explore rendering.
 * GET /api/v1/articles/explore/sections?userId=...&briefsLimit=8&topicsLimit=10&topStoriesLimit=5&forYouLimit=4&sourcesLimit=5
 */
async function getExploreSections(req: Request, res: Response) {
  try {
    const userId = String(req.query.userId ?? "").trim();
    const briefsLimit = coerceLimit(req.query.briefsLimit, 8, 20);
    const topicsLimit = coerceLimit(req.query.topicsLimit, 10, 20);
    const topStoriesLimit = coerceLimit(req.query.topStoriesLimit, 5, 12);
    const forYouLimit = coerceLimit(req.query.forYouLimit, 4, 12);
    const sourcesLimit = coerceLimit(req.query.sourcesLimit, 5, 12);

    const cacheKey = `articles:explore-sections:${userId}:${briefsLimit}:${topicsLimit}:${topStoriesLimit}:${forYouLimit}:${sourcesLimit}`;
    const cached = getCachedPayload<Record<string, unknown>>(cacheKey);
    if (cached) {
      return res.status(200).json(cached);
    }

    const dislikedIds = await getDislikedArticleIds(userId);
    const snapshot = await db
      .collection("articles")
      .orderBy("pubDate", "desc")
      .limit(260)
      .get();

    const recentArticles = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() } as Record<string, unknown>))
      .filter((article) => {
        const articleId = article.articleId;
        if (typeof articleId !== "string" || articleId.trim().length === 0) {
          return false;
        }
        return !dislikedIds.has(articleId);
      });

    const quickBriefs = recentArticles
      .slice(0, briefsLimit)
      .map((article) => transformArticleToSnakeCase(article));

    const signals = await collectHomeSignals(userId);
    const rankedArticles = rankHomeArticles(
      recentArticles,
      signals,
      topStoriesLimit + forYouLimit
    );
    const topStoriesRaw = rankedArticles.slice(0, topStoriesLimit);
    const topStoriesIds = new Set(
      topStoriesRaw
        .map((article) => article.articleId)
        .filter((id): id is string => typeof id === "string" && id.trim().length > 0)
    );
    const forYouRaw = rankedArticles.slice(topStoriesLimit, topStoriesLimit + forYouLimit);
    const forYouFallback = recentArticles
      .filter((article) => !topStoriesIds.has(String(article.articleId ?? "")))
      .slice(0, forYouLimit);

    const topStories = (topStoriesRaw.length > 0 ? topStoriesRaw : recentArticles.slice(0, topStoriesLimit))
      .map((article) => transformArticleToSnakeCase(article));
    const forYou = (forYouRaw.length > 0 ? forYouRaw : forYouFallback)
      .map((article) => transformArticleToSnakeCase(article));

    const topicCounts = new Map<string, number>();
    for (const article of recentArticles.slice(0, 220)) {
      const categories = Array.isArray(article.category)
        ? (article.category as unknown[]).map((item) => String(item).trim().toLowerCase())
        : [];
      const aiTags = Array.isArray(article.aiTag)
        ? (article.aiTag as unknown[]).map((item) => String(item).trim().toLowerCase())
        : [];

      const topicCandidates = [...categories, ...aiTags]
        .map((topic) => topic.replace(/\s+/g, " ").trim())
        .filter((topic) => topic.length >= 3 && topic.length <= 36 && !STOP_WORDS.has(topic));

      for (const topic of topicCandidates) {
        topicCounts.set(topic, (topicCounts.get(topic) ?? 0) + 1);
      }
    }

    const trendingTopics = Array.from(topicCounts.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, topicsLimit)
      .map(([topic, count]) => ({
        topic,
        count,
      }));

    const sourceCounts = new Map<
      string,
      { name: string; articleCount: number; iconUrl: string }
    >();
    for (const article of recentArticles.slice(0, 220)) {
      const sourceName = String(article.sourceName ?? "").trim();
      if (!sourceName) continue;
      const current = sourceCounts.get(sourceName) ?? {
        name: sourceName,
        articleCount: 0,
        iconUrl: "",
      };
      current.articleCount += 1;
      if (!current.iconUrl) {
        current.iconUrl = String(article.sourceIcon ?? "");
      }
      sourceCounts.set(sourceName, current);
    }
    const popularSources = Array.from(sourceCounts.values())
      .sort((a, b) => b.articleCount - a.articleCount)
      .slice(0, sourcesLimit);

    const payload = {
      success: true,
      quickBriefs,
      trendingTopics,
      topStories,
      forYou,
      popularSources,
      quickBriefsCount: quickBriefs.length,
      trendingTopicsCount: trendingTopics.length,
      topStoriesCount: topStories.length,
      forYouCount: forYou.length,
      popularSourcesCount: popularSources.length,
    };
    setCachedPayload(cacheKey, payload);

    return res.status(200).json(payload);
  } catch (error) {
    console.error("Explore sections error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to load explore sections",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
}

/**
 * Convert Firestore Timestamp or any date value to ISO string
 */
function toISOString(value: unknown): string {
  if (!value) {
    return new Date().toISOString();
  }

  // Handle Firestore Timestamp (has toDate method)
  if (typeof value === 'object' && value !== null && 'toDate' in value && typeof (value as { toDate: () => Date }).toDate === 'function') {
    return (value as { toDate: () => Date }).toDate().toISOString();
  }

  // Handle Firestore Timestamp with _seconds (raw format)
  if (typeof value === 'object' && value !== null && '_seconds' in value) {
    const timestamp = value as { _seconds: number; _nanoseconds?: number };
    return new Date(timestamp._seconds * 1000).toISOString();
  }

  // Handle string (already formatted)
  if (typeof value === 'string') {
    // Try to parse and reformat to ensure valid ISO string
    try {
      return new Date(value).toISOString();
    } catch {
      return value;
    }
  }

  // Handle Date object
  if (value instanceof Date) {
    return value.toISOString();
  }

  // Fallback
  return new Date().toISOString();
}

/**
 * Transform article from DB format (camelCase) to API format (snake_case)
 * This matches the format expected by the Flutter ArticleModel.fromJson()
 */
function transformArticleToSnakeCase(article: Record<string, unknown>): Record<string, unknown> {
  return {
    article_id: article.articleId,
    link: article.link,
    title: article.title,
    description: article.description,
    content: article.content,
    keywords: article.keywords,
    creator: article.creator,
    language: article.language,
    country: article.country,
    category: article.category,
    datatype: article.datatype,
    pubDate: toISOString(article.pubDate),
    pubDateTZ: article.pubDateTZ || 'UTC',
    image_url: article.imageUrl,
    video_url: article.videoUrl,
    source_id: article.sourceId,
    source_name: article.sourceName,
    source_priority: article.sourcePriority ?? 0,
    source_url: article.sourceUrl,
    source_icon: article.sourceIcon,
    sentiment: article.sentiment,
    sentiment_stats: article.sentimentStats,
    ai_tag: article.aiTag,
    ai_region: article.aiRegion,
    ai_org: article.aiOrg,
    ai_summary: article.aiSummary,
    duplicate: article.duplicate,
  };
}

/**
 * Get articles with filters
 * GET /api/v1/articles?category=technology&limit=10
 */
async function getArticles(req: Request, res: Response) {
  try {
    const { category, sourceName, limit = 20, offset = 0 } = req.query;
    const limitNum = Number(limit);
    const offsetNum = Number(offset);

    let query = db.collection("articles").orderBy("pubDate", "desc");

    // Apply filters
    if (category) {
      query = query.where("category", "array-contains", category);
    }
    if (sourceName) {
      query = query.where("sourceName", "==", sourceName);
    }

    const isMissingIndexError = (error: any): boolean => {
      const details = String(error?.details || error?.message || "");
      return error?.code === 9 || details.includes("requires an index");
    };

    let snapshot;
    try {
      // Apply pagination
      snapshot = await query
        .limit(limitNum)
        .offset(offsetNum)
        .get();
    } catch (queryError) {
      if (!isMissingIndexError(queryError) || !sourceName) {
        throw queryError;
      }

      // Fallback path when composite index is still building:
      // query by source only, sort in memory by pubDate, then apply offset/limit.
      const fallbackSnapshot = await db
        .collection("articles")
        .where("sourceName", "==", sourceName)
        .limit(Math.max(limitNum + offsetNum + 50, 120))
        .get();

      const sortedDocs = fallbackSnapshot.docs.sort((a, b) => {
        const aDate = Date.parse((a.data().pubDate as string) || "") || 0;
        const bDate = Date.parse((b.data().pubDate as string) || "") || 0;
        return bDate - aDate;
      });
      const pagedDocs = sortedDocs.slice(offsetNum, offsetNum + limitNum);
      snapshot = { docs: pagedDocs } as any;
    }

    // Transform articles to snake_case format for Flutter
    const articles = snapshot.docs.map((doc: any) => {
      const data = doc.data();
      return transformArticleToSnakeCase({
        id: doc.id,
        ...data,
      });
    });

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

    // Transform to snake_case format for Flutter
    const data = snapshot.docs[0].data();
    const article = transformArticleToSnakeCase({
      id: snapshot.docs[0].id,
      ...data,
    });

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

/**
 * Get personalized article recommendations
 * GET /api/v1/articles/recommendations?userId=...&limit=20
 */
async function getArticleRecommendations(req: Request, res: Response) {
  try {
    const userId = (req.query.userId as string) || "";
    const limit = Math.min(parseInt(req.query.limit as string) || 20, 50);
    const fallbackLimit = Math.max(limit, 10);
    const timeoutMs = 7000;

    const articlesCollection = db.collection("articles");
    const engagementCollection = db.collection("articleEngagement");
    const dislikedCollection = db.collection("dislikedArticles");
    const followedPublishersCollection = db.collection("followedPublishers");
    const userLikesCollection = db.collection("userLikes");
    const userSharesCollection = db.collection("userShares");
    const commentsCollection = db.collection("comments");
    const savedArticlesCollection = db.collection("savedArticles");
    const readingHistoryCollection = db.collection("readingHistory");

    // Pull a recent pool of articles to score
    const recentSnapshot = await articlesCollection
      .orderBy("pubDate", "desc")
      .limit(120)
      .get();

    const recentArticles = recentSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as Array<Record<string, any>>;

    if (recentArticles.length === 0) {
      return res.status(200).json({
        success: true,
        articles: [],
        count: 0,
      });
    }

    // If no userId, return recent articles (still sorted by recency)
    if (!userId) {
      const fallback = recentArticles
        .slice(0, fallbackLimit)
        .map((article) => transformArticleToSnakeCase(article));
      return res.status(200).json({
        success: true,
        articles: fallback,
        count: fallback.length,
      });
    }

    const computeRecommendations = async () => {
      // Fetch user signals
      const [
        dislikedSnap,
        followedSnap,
        likesSnap,
        sharesSnap,
        commentsSnap,
        savedSnap,
        historySnap,
      ] = await Promise.all([
        dislikedCollection.where("userId", "==", userId).get(),
        followedPublishersCollection.where("userId", "==", userId).get(),
        userLikesCollection.where("userId", "==", userId).limit(100).get(),
        userSharesCollection.where("userId", "==", userId).limit(100).get(),
        commentsCollection.where("userId", "==", userId).limit(100).get(),
        savedArticlesCollection.where("userId", "==", userId).limit(100).get(),
        readingHistoryCollection.where("userId", "==", userId).limit(120).get(),
      ]);

      const dislikedIds = new Set(
        dislikedSnap.docs.map((doc) => (doc.data() as any).articleId as string)
      );
      const followedPublishers = new Set(
        followedSnap.docs.map((doc) => (doc.data() as any).publisherName as string)
      );

      const likedIds = likesSnap.docs.map((doc) => (doc.data() as any).articleId as string);
      const sharedIds = sharesSnap.docs.map((doc) => (doc.data() as any).articleId as string);
      const commentedIds = commentsSnap.docs.map((doc) => (doc.data() as any).articleId as string);
      const savedIds = savedSnap.docs.map((doc) => (doc.data() as any).articleId as string);
      const readIds = historySnap.docs.map((doc) => (doc.data() as any).articleId as string);
      const readIdSet = new Set(readIds);

      const hasSignals =
        likedIds.length > 0 ||
        sharedIds.length > 0 ||
        commentedIds.length > 0 ||
        savedIds.length > 0 ||
        readIds.length > 0 ||
        followedPublishers.size > 0;

      if (!hasSignals) {
        return recentArticles
          .slice(0, fallbackLimit)
          .map((article) => transformArticleToSnakeCase(article));
      }

      const profileArticleIds = [
        ...new Set([...likedIds, ...sharedIds, ...commentedIds, ...savedIds, ...readIds]),
      ].slice(0, 60);

      const profileArticles =
        profileArticleIds.length > 0 ? await fetchArticlesByIds(profileArticleIds) : [];

      const categoryWeights = new Map<string, number>();
      const sourceWeights = new Map<string, number>();
      const keywordWeights = new Map<string, number>();

      for (const article of profileArticles) {
        const weight = getInteractionWeight(
          likedIds.includes(article.articleId),
          sharedIds.includes(article.articleId),
          commentedIds.includes(article.articleId),
          savedIds.includes(article.articleId),
          readIdSet.has(article.articleId)
        );

        for (const category of article.category || []) {
          categoryWeights.set(category, (categoryWeights.get(category) || 0) + weight);
        }

        if (article.sourceName) {
          sourceWeights.set(
            article.sourceName,
            (sourceWeights.get(article.sourceName) || 0) + weight
          );
        }

        for (const token of extractTokens(article)) {
          keywordWeights.set(token, (keywordWeights.get(token) || 0) + weight);
        }
      }

      // Boost followed publishers
      for (const publisher of followedPublishers) {
        sourceWeights.set(publisher, (sourceWeights.get(publisher) || 0) + 4.0);
      }

      // Engagement map for recent articles (batch fetch)
      const engagementMap = await fetchEngagementMap(
        recentArticles.map((a) => a.articleId).filter(Boolean)
      );

      const scored = recentArticles
        .filter((article) => {
          const articleId = article.articleId as string | undefined;
          if (!articleId) return false;
          if (dislikedIds.has(articleId)) return false;
          if (readIdSet.has(articleId)) return false;
          return true;
        })
        .map((article) => {
          const articleId = article.articleId as string;
          const pubDate = toDate(article.pubDate);
          const ageHours = Math.max(
            1,
            (Date.now() - pubDate.getTime()) / (1000 * 60 * 60)
          );

          const recencyScore = Math.exp(-ageHours / 36) * 3.0;

          const engagement = engagementMap.get(articleId) || {
            likeCount: 0,
            shareCount: 0,
            commentCount: 0,
          };
          const popularityBase =
            engagement.likeCount + engagement.shareCount * 2 + engagement.commentCount * 1.5;
          const popularityScore = Math.log1p(popularityBase) * 0.7;

          let categoryScore = 0;
          for (const category of article.category || []) {
            categoryScore += categoryWeights.get(category) || 0;
          }
          categoryScore = Math.min(categoryScore * 0.4, 3.0);

          let sourceScore = 0;
          if (article.sourceName) {
            sourceScore = (sourceWeights.get(article.sourceName) || 0) * 0.3;
            if (followedPublishers.has(article.sourceName)) {
              sourceScore += 2.0;
            }
          }

          let keywordScore = 0;
          for (const token of extractTokens(article)) {
            keywordScore += keywordWeights.get(token) || 0;
          }
          keywordScore = Math.min(keywordScore * 0.2, 2.0);

          const score = recencyScore + popularityScore + categoryScore + sourceScore + keywordScore;

          return {
            article,
            score,
          };
        })
        .sort((a, b) => b.score - a.score);

      const finalArticles: Array<Record<string, any>> = [];
      const sourceCounts = new Map<string, number>();
      const categoryCounts = new Map<string, number>();

      for (const item of scored) {
        if (finalArticles.length >= limit) break;
        const source = item.article.sourceName as string | undefined;
        const categories = (item.article.category || []) as string[];

        if (source) {
          const count = sourceCounts.get(source) || 0;
          if (count >= 2) continue;
        }

        let blocked = false;
        for (const category of categories) {
          const count = categoryCounts.get(category) || 0;
          if (count >= 3) {
            blocked = true;
            break;
          }
        }
        if (blocked) continue;

        finalArticles.push(item.article);
        if (source) sourceCounts.set(source, (sourceCounts.get(source) || 0) + 1);
        for (const category of categories) {
          categoryCounts.set(category, (categoryCounts.get(category) || 0) + 1);
        }
      }

      const responseArticles = finalArticles.map((article) =>
        transformArticleToSnakeCase(article)
      );

      return responseArticles;
    };

    let responseArticles: Array<Record<string, any>> = [];
    try {
      responseArticles = await withTimeout(computeRecommendations(), timeoutMs);
    } catch (e) {
      const fallback = recentArticles
        .slice(0, fallbackLimit)
        .map((article) => transformArticleToSnakeCase(article));
      return res.status(200).json({
        success: true,
        count: fallback.length,
        articles: fallback,
      });
    }

    return res.status(200).json({
      success: true,
      count: responseArticles.length,
      articles: responseArticles,
    });
  } catch (error) {
    console.error("Recommendations error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get recommendations",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
}

/**
 * Get articles by IDs (preserves requested order)
 * POST /api/v1/articles/by-ids
 */
async function getArticlesByIds(req: Request, res: Response) {
  try {
    const { articleIds } = req.body as { articleIds?: string[] };
    if (!Array.isArray(articleIds) || articleIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: "articleIds array is required",
      });
    }

    const uniqueIds = [...new Set(articleIds.filter((id) => typeof id === "string" && id.trim().length > 0))];
    const articlesCollection = db.collection("articles");
    const byId = new Map<string, Record<string, unknown>>();
    const batchSize = 10;

    for (let i = 0; i < uniqueIds.length; i += batchSize) {
      const batchIds = uniqueIds.slice(i, i + batchSize);
      const snapshot = await articlesCollection.where("articleId", "in", batchIds).get();
      snapshot.docs.forEach((doc) => {
        const data = doc.data() as Record<string, unknown>;
        const articleId = data.articleId;
        if (typeof articleId === "string" && articleId.trim().length > 0) {
          byId.set(articleId, {
            id: doc.id,
            ...data,
          });
        }
      });
    }

    const orderedArticles = uniqueIds
      .map((id) => byId.get(id))
      .filter((entry): entry is Record<string, unknown> => Boolean(entry))
      .map(transformArticleToSnakeCase);

    return res.status(200).json({
      success: true,
      articles: orderedArticles,
      count: orderedArticles.length,
    });
  } catch (error) {
    console.error("Error fetching articles by IDs:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch articles",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
}

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("timeout")), ms);
    promise
      .then((value) => {
        clearTimeout(timer);
        resolve(value);
      })
      .catch((err) => {
        clearTimeout(timer);
        reject(err);
      });
  });
}

function toDate(value: unknown): Date {
  if (!value) return new Date();
  if (value instanceof Date) return value;
  if (typeof value === "object" && value !== null && "toDate" in value) {
    return (value as { toDate: () => Date }).toDate();
  }
  if (typeof value === "object" && value !== null && "_seconds" in value) {
    const timestamp = value as { _seconds: number };
    return new Date(timestamp._seconds * 1000);
  }
  return new Date(value as string);
}

function getInteractionWeight(
  liked: boolean,
  shared: boolean,
  commented: boolean,
  saved: boolean,
  read: boolean
): number {
  let weight = 0;
  if (read) weight += 0.5;
  if (saved) weight += 1.5;
  if (liked) weight += 2.5;
  if (shared) weight += 2.0;
  if (commented) weight += 2.0;
  return Math.max(0.5, weight);
}

function extractTokens(article: Record<string, any>): string[] {
  const tokens: string[] = [];
  const text = [
    article.title,
    article.description,
    ...(article.keywords || []),
    ...(article.aiTag || []),
    article.aiOrg,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  const words = text.split(/[^a-z0-9]+/).filter(Boolean);
  for (const word of words) {
    if (word.length < 3) continue;
    if (STOP_WORDS.has(word)) continue;
    tokens.push(word);
  }
  return tokens.slice(0, 20);
}

async function fetchArticlesByIds(articleIds: string[]) {
  if (articleIds.length === 0) return [];
  const articlesCollection = db.collection("articles");
  const results: Array<Record<string, any>> = [];
  const batchSize = 10;

  for (let i = 0; i < articleIds.length; i += batchSize) {
    const batchIds = articleIds.slice(i, i + batchSize);
    const snapshot = await articlesCollection
      .where("articleId", "in", batchIds)
      .get();
    snapshot.docs.forEach((doc) => {
      results.push(doc.data() as Record<string, any>);
    });
  }

  return results;
}

async function fetchEngagementMap(articleIds: string[]) {
  const engagementCollection = db.collection("articleEngagement");
  const engagementMap = new Map<
    string,
    { likeCount: number; shareCount: number; commentCount: number }
  >();
  const batchSize = 10;

  for (let i = 0; i < articleIds.length; i += batchSize) {
    const batchIds = articleIds.slice(i, i + batchSize);
    const refs = batchIds.map((id) => engagementCollection.doc(id));
    const docs = await db.getAll(...refs);
    docs.forEach((doc) => {
      if (!doc.exists) return;
      const data = doc.data() as any;
      engagementMap.set(doc.id, {
        likeCount: data?.likeCount || 0,
        shareCount: data?.shareCount || 0,
        commentCount: data?.commentCount || 0,
      });
    });
  }

  return engagementMap;
}

type HomeSignals = {
  dislikedIds: Set<string>;
  followedPublishers: Set<string>;
};

async function collectHomeSignals(userId: string): Promise<HomeSignals> {
  if (!userId) {
    return {
      dislikedIds: new Set(),
      followedPublishers: new Set(),
    };
  }

  const [dislikedSnap, followedSnap] = await Promise.all([
    db
      .collection("dislikedArticles")
      .where("userId", "==", userId)
      .get(),
    db
      .collection("followedPublishers")
      .where("userId", "==", userId)
      .get(),
  ]);

  return {
    dislikedIds: new Set(
      dislikedSnap.docs
        .map((doc) => doc.data().articleId)
        .filter((id): id is string => typeof id === "string" && id.trim().length > 0)
    ),
    followedPublishers: new Set(
      followedSnap.docs
        .map((doc) => doc.data().publisherName)
        .filter((name): name is string => typeof name === "string" && name.trim().length > 0)
    ),
  };
}

function buildHomeTrendingTopics(
  articles: Array<Record<string, unknown>>,
  limit: number
): Array<{ topic: string; count: number }> {
  const counters = new Map<string, number>();

  for (const article of articles) {
    const metadata = [
      ...(Array.isArray(article.category) ? article.category : []),
      ...(Array.isArray(article.aiTag) ? article.aiTag : []),
    ]
      .map((item) => String(item).trim().toLowerCase())
      .filter((item) => item.length >= 3 && !STOP_WORDS.has(item));

    for (const topic of metadata) {
      counters.set(topic, (counters.get(topic) || 0) + 1);
    }
  }

  return Array.from(counters.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, limit)
    .map(([topic, count]) => ({ topic, count }));
}

function rankHomeArticles(
  articles: Array<Record<string, unknown>>,
  signals: HomeSignals,
  limit: number
): Array<Record<string, unknown>> {
  const scored = articles
    .filter((article) => {
      const articleId = article.articleId;
      if (!articleId || typeof articleId !== "string") return false;
      return !signals.dislikedIds.has(articleId);
    })
    .map((article) => {
      const recencyHours = Math.max(
        1,
        (Date.now() - toDate(article.pubDate).getTime()) / (1000 * 60 * 60)
      );
      const baseScore = Math.exp(-recencyHours / 24) * 4;
      let sourceBoost = 0;
      const sourceName = String(article.sourceName || "");
      if (signals.followedPublishers.has(sourceName)) {
        sourceBoost += 2.0;
      }
      const keywordBoost = extractTokens(article).length * 0.2;
      const engagementData = (article.engagement as Record<string, number> | undefined) ?? {};
      const engagementScore =
        Math.log1p(
          (engagementData.likeCount ?? 0) +
            (engagementData.shareCount ?? 0) * 1.5 +
            (engagementData.commentCount ?? 0)
        ) * 0.5;

      return {
        article,
        score: baseScore + sourceBoost + keywordBoost + engagementScore,
      };
    })
    .sort((a, b) => b.score - a.score);

  return scored.slice(0, limit).map((item) => item.article);
}

async function getHomeFeed(req: Request, res: Response) {
  try {
    const userId = String(req.query.userId ?? "").trim();
    const briefsLimit = coerceLimit(req.query.briefsLimit, 6, 12);
    const focusLimit = coerceLimit(req.query.focusLimit, 4, 8);
    const recommendedLimit = coerceLimit(req.query.recommendedLimit, 8, 16);

    const cacheKey = `articles:home-feed:${userId}:${briefsLimit}:${focusLimit}:${recommendedLimit}`;
    const cached = getCachedPayload<Record<string, unknown>>(cacheKey);
    if (cached) {
      return res.status(200).json(cached);
    }

    const recentSnapshot = await db
      .collection("articles")
      .orderBy("pubDate", "desc")
      .limit(240)
      .get();

    const recentArticles = recentSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as Array<Record<string, unknown>>;

    if (recentArticles.length === 0) {
      return res.status(200).json({
        success: true,
        hero: null,
        focus: [],
        recommended: [],
        trendingTopics: [],
        timestamp: new Date().toISOString(),
      });
    }

    const signals = await collectHomeSignals(userId);
    const scored = rankHomeArticles(recentArticles, signals, focusLimit + recommendedLimit);

    if (scored.length === 0) {
      const fallbackHero = recentArticles[0];
      return res.status(200).json({
        success: true,
        hero: transformArticleToSnakeCase(fallbackHero),
        focus: [],
        recommended: [],
        trendingTopics: buildHomeTrendingTopics(recentArticles, 6),
        timestamp: new Date().toISOString(),
      });
    }

    const hero = scored[0];
    const focusArticles = scored.slice(0, focusLimit);
    const recommendedArticles = scored.slice(focusLimit, focusLimit + recommendedLimit);

    const payload = {
      success: true,
      hero: transformArticleToSnakeCase(hero),
      focus: focusArticles.map((article) => transformArticleToSnakeCase(article)),
      recommended: recommendedArticles.map((article) => transformArticleToSnakeCase(article)),
      trendingTopics: buildHomeTrendingTopics(recentArticles, 6),
      timestamp: new Date().toISOString(),
    };
    setCachedPayload(cacheKey, payload);

    return res.status(200).json(payload);
  } catch (error) {
    console.error("Home feed error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to load home feed",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
}

const homeFeedCacheMetrics = { hits: 0, misses: 0 };

const STOP_WORDS = new Set([
  "the",
  "and",
  "for",
  "with",
  "that",
  "this",
  "from",
  "are",
  "was",
  "were",
  "has",
  "have",
  "had",
  "but",
  "not",
  "you",
  "your",
  "about",
  "into",
  "after",
  "over",
  "new",
  "its",
  "our",
  "their",
  "they",
  "she",
  "him",
  "her",
  "his",
  "who",
  "what",
  "when",
  "where",
  "why",
  "how",
  "will",
  "can",
  "could",
  "would",
  "should",
  "than",
  "then",
  "just",
  "more",
  "most",
  "also",
  "over",
  "been",
]);

export {
  saveArticlesBatch,
  getArticles,
  getArticleById,
  searchArticles,
  getTopStories,
  getPopularSources,
  getExploreSections,
  getHomeFeed,
  getArticleRecommendations,
  getArticlesByIds,
};
