import { Request, Response } from "express";
import { createHash } from "crypto";
import { db } from "../config/firebase.connection";
import { Timestamp, FieldValue } from "firebase-admin/firestore";
import {
  UserProfile,
  UserFollow,
  ReadingList,
  ActivityFeedItem,
  CreateUserProfileRequest,
  UpdateUserProfileRequest,
  FollowUserRequest,
  CreateReadingListRequest,
  UpdateReadingListRequest,
  AddArticleToListRequest,
  AddCollaboratorRequest,
  ReorderListArticlesRequest,
  CreateActivityRequest,
  SearchUsersRequest,
  GetActivityFeedRequest,
  NetworkPost,
  CreateNetworkPostRequest,
} from "../models/social.model";
import { getOptionalString } from "../utils/request.utils";

const userProfilesCollection = db.collection("userProfiles");
const userFollowsCollection = db.collection("userFollows");
const readingListsCollection = db.collection("readingLists");
const activityFeedCollection = db.collection("activityFeed");
const readingHistoryCollection = db.collection("readingHistory");
const articlesCollection = db.collection("articles");
const articleEngagementCollection = db.collection("articleEngagement");
const followedPublishersCollection = db.collection("followedPublishers");
const postsCollection = db.collection("socialPosts");
const postLikesCollection = db.collection("socialPostLikes");
const postCommentsCollection = db.collection("socialPostComments");
const RECOMMENDATION_MAX_LIMIT = 500;
const FEED_SUMMARY_CACHE_TTL_MS = 30 * 1000;
const feedSummaryCache = new Map<
  string,
  { etag: string; body: Record<string, any>; expiresAt: number }
>();
const setPrivateCache = (res: Response, seconds: number) => {
  res.set("Cache-Control", `private, max-age=${seconds}, stale-while-revalidate=${seconds}`);
};

const getQueryString = (value: string | string[] | undefined): string | undefined =>
  getOptionalString(value);

const toMillis = (value: any): number => {
  if (!value) return 0;
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? 0 : parsed;
  }
  if (typeof value?.toMillis === "function") {
    return value.toMillis();
  }
  if (typeof value?.toDate === "function") {
    return value.toDate().getTime();
  }
  return 0;
};

const normalizeUrlForMatch = (value: string): string => {
  const trimmed = value.trim();
  const parsed = new URL(trimmed);
  parsed.hash = "";
  ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "gclid", "fbclid"].forEach(
    (key) => parsed.searchParams.delete(key)
  );
  const normalizedPath = parsed.pathname.replace(/\/+$/, "");
  parsed.pathname = normalizedPath.length > 0 ? normalizedPath : "/";
  return parsed.toString();
};

const NON_NEWS_HOSTS = new Set([
  "facebook.com",
  "instagram.com",
  "x.com",
  "twitter.com",
  "tiktok.com",
  "youtube.com",
  "youtu.be",
  "whatsapp.com",
  "telegram.org",
  "pinterest.com",
  "snapchat.com",
  "reddit.com",
  "bit.ly",
  "tinyurl.com",
  "t.co",
]);

const hasNewsLikeHost = (host: string): boolean => {
  return /(news|times|post|journal|tribune|herald|chronicle|gazette|reuters|bloomberg|cnn|bbc)/.test(
    host
  );
};

const looksLikeNewsLink = (url: string): boolean => {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return false;
  }

  const host = parsed.hostname.toLowerCase();
  if (!host || host === "localhost") return false;
  if (NON_NEWS_HOSTS.has(host) || NON_NEWS_HOSTS.has(host.replace(/^www\./, ""))) return false;

  const path = parsed.pathname.toLowerCase();
  if (!path || path === "/") return false;
  if (/\.(jpg|jpeg|png|gif|webp|svg|pdf|mp4|mov)$/i.test(path)) return false;

  const hasDatePattern = /\/20\d{2}\/\d{1,2}(\/\d{1,2})?\//.test(path);
  const hasArticleHint =
    /\/(news|article|story|world|politics|business|tech|technology|health|science|sports|opinion|analysis)\//.test(
      path
    );
  const hasSlug = path.split("/").filter(Boolean).some((segment) => segment.length >= 18 && segment.includes("-"));

  return hasNewsLikeHost(host) || hasDatePattern || hasArticleHint || hasSlug;
};

const deriveTitleFromUrl = (url: string): string | null => {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return null;
  }
  const parts = parsed.pathname.split("/").filter(Boolean);
  if (parts.length === 0) return null;
  const rawLast = parts[parts.length - 1].replace(/\.[a-z0-9]+$/i, "");
  if (!rawLast || rawLast.length < 6) return null;
  const cleaned = rawLast
    .replace(/[-_]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  if (!cleaned) return null;
  return cleaned
    .split(" ")
    .map((word) => (word.length > 1 ? word[0].toUpperCase() + word.slice(1) : word.toUpperCase()))
    .join(" ")
    .slice(0, 160);
};

// Helper function to convert Firestore Timestamps to ISO strings
const convertTimestampsToISO = (data: any): any => {
  if (!data) return data;

  const converted: any = {};
  for (const key in data) {
    const value = data[key];
    if (value && typeof value === 'object' && '_seconds' in value) {
      // Convert Firestore Timestamp to ISO string
      converted[key] = new Date(value._seconds * 1000).toISOString();
    } else if (value && typeof value === 'object' && value.toDate) {
      // Handle Timestamp objects with toDate method
      converted[key] = value.toDate().toISOString();
    } else if (Array.isArray(value)) {
      converted[key] = value.map(item => convertTimestampsToISO(item));
    } else if (value && typeof value === 'object') {
      converted[key] = convertTimestampsToISO(value);
    } else {
      converted[key] = value;
    }
  }
  return converted;
};

const chunkArray = <T>(items: T[], size: number): T[][] => {
  const chunks: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
};

const normalizeTopic = (value: unknown): string | null => {
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase();
  return normalized.length > 0 ? normalized : null;
};

const appendTopicsFromUnknown = (target: Set<string>, value: unknown): void => {
  if (typeof value === "string") {
    const normalized = normalizeTopic(value);
    if (normalized) target.add(normalized);
    return;
  }

  if (Array.isArray(value)) {
    value.forEach((item) => {
      const normalized = normalizeTopic(item);
      if (normalized) target.add(normalized);
    });
  }
};

const getProfileTopicSet = (profile: Record<string, any>): Set<string> => {
  const topics = new Set<string>();
  appendTopicsFromUnknown(topics, profile.interests);

  const stats = profile.stats as Record<string, any> | undefined;
  if (stats) {
    appendTopicsFromUnknown(topics, stats.topTopics);
    appendTopicsFromUnknown(topics, stats.favoriteTopics);
    appendTopicsFromUnknown(topics, stats.preferredTopics);
    appendTopicsFromUnknown(topics, stats.categories);
  }

  return topics;
};

const getUserReadingCategoryWeights = async (
  userId: string,
  maxHistoryRows = 120
): Promise<Map<string, number>> => {
  const weights = new Map<string, number>();
  const historySnapshot = await readingHistoryCollection
    .where("userId", "==", userId)
    .limit(maxHistoryRows)
    .get();

  const historyRows = historySnapshot.docs.map((doc) => doc.data() as Record<string, any>);
  const uniqueArticleIds: string[] = [];
  const seen = new Set<string>();
  historyRows.forEach((row) => {
    const articleId = row.articleId;
    if (typeof articleId !== "string" || articleId.length === 0) return;
    if (seen.has(articleId)) return;
    seen.add(articleId);
    uniqueArticleIds.push(articleId);
  });

  if (uniqueArticleIds.length === 0) {
    return weights;
  }

  const articleWeight = new Map<string, number>();
  uniqueArticleIds.forEach((articleId, index) => {
    // Bias towards the front of the sample without requiring extra indexes.
    const decay = (uniqueArticleIds.length - index) / uniqueArticleIds.length;
    articleWeight.set(articleId, 1 + decay);
  });

  const articleIdChunks = chunkArray(uniqueArticleIds.slice(0, 80), 10);
  for (const chunk of articleIdChunks) {
    const articleSnapshot = await articlesCollection.where("articleId", "in", chunk).get();
    articleSnapshot.docs.forEach((doc) => {
      const article = doc.data() as Record<string, any>;
      const id = article.articleId as string | undefined;
      const weight = id ? articleWeight.get(id) || 1 : 1;
      const categories = Array.isArray(article.category) ? article.category : [];

      categories.forEach((rawCategory) => {
        const category = normalizeTopic(rawCategory);
        if (!category) return;
        weights.set(category, (weights.get(category) || 0) + weight);
      });
    });
  }

  return weights;
};

const buildProfileInsightsPayload = async (
  userId: string,
  profile: UserProfile
): Promise<Record<string, any>> => {
  const now = new Date();
  const start365 = new Date();
  start365.setDate(start365.getDate() - 365);

  const historySnapshot = await readingHistoryCollection
    .where("userId", "==", userId)
    .where("readAt", ">=", Timestamp.fromDate(start365))
    .orderBy("readAt", "desc")
    .limit(1500)
    .get();

  const readEntries = historySnapshot.docs.map((doc) => doc.data());
  const daySet = new Set<string>();
  let lastReadAt: Date | null = null;

  readEntries.forEach((entry) => {
    const readAt = entry.readAt?.toDate ? entry.readAt.toDate() : new Date(entry.readAt);
    if (!lastReadAt || readAt > lastReadAt) {
      lastReadAt = readAt;
    }
    const dayKey = readAt.toISOString().split("T")[0];
    daySet.add(dayKey);
  });

  let currentStreak = 0;
  let cursor = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  while (true) {
    const key = cursor.toISOString().split("T")[0];
    if (daySet.has(key)) {
      currentStreak += 1;
      cursor.setDate(cursor.getDate() - 1);
    } else {
      break;
    }
  }

  const sortedDays = Array.from(daySet).sort();
  let longestStreak = 0;
  let running = 0;
  let prev: Date | null = null;
  for (const day of sortedDays) {
    const date = new Date(day);
    if (prev) {
      const diff = (date.getTime() - prev.getTime()) / (1000 * 60 * 60 * 24);
      if (diff === 1) {
        running += 1;
      } else {
        running = 1;
      }
    } else {
      running = 1;
    }
    if (running > longestStreak) longestStreak = running;
    prev = date;
  }

  const start30 = new Date();
  start30.setDate(start30.getDate() - 30);
  let totalArticlesRead30 = 0;
  let totalReadingTimeSeconds30 = 0;
  const articlesByDate: { [date: string]: number } = {};

  readEntries.forEach((entry) => {
    const readAt = entry.readAt?.toDate ? entry.readAt.toDate() : new Date(entry.readAt);
    if (readAt >= start30) {
      totalArticlesRead30 += 1;
      totalReadingTimeSeconds30 += entry.readDuration || 0;
      const date = readAt.toISOString().split("T")[0];
      articlesByDate[date] = (articlesByDate[date] || 0) + 1;
    }
  });

  let mostActiveDay = "";
  let maxArticles = 0;
  for (const [date, count] of Object.entries(articlesByDate)) {
    if (count > maxArticles) {
      maxArticles = count;
      mostActiveDay = date;
    }
  }

  const recentReads = readEntries.slice(0, 5).map((entry) => ({
    articleId: entry.articleId,
    articleTitle: entry.articleTitle,
    readAt: entry.readAt?.toDate ? entry.readAt.toDate().toISOString() : entry.readAt,
    readDuration: entry.readDuration || 0,
  }));

  const recentForFavorites = readEntries.slice(0, 50);
  const recentArticleIds = recentForFavorites
    .map((entry) => entry.articleId)
    .filter(Boolean);

  const sourceCounts: Record<string, number> = {};
  const topicCounts: Record<string, number> = {};

  const chunkSize = 10;
  for (let i = 0; i < recentArticleIds.length; i += chunkSize) {
    const chunk = recentArticleIds.slice(i, i + chunkSize);
    const snapshot = await articlesCollection.where("articleId", "in", chunk).get();

    snapshot.docs.forEach((doc) => {
      const article = doc.data();
      if (article.sourceName) {
        sourceCounts[article.sourceName] = (sourceCounts[article.sourceName] || 0) + 1;
      }
      const categories = article.category || [];
      if (Array.isArray(categories) && categories.length > 0) {
        const first = categories[0];
        topicCounts[first] = (topicCounts[first] || 0) + 1;
      }
    });
  }

  const topSources = Object.entries(sourceCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([name]) => name);

  const topTopics = Object.entries(topicCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([name]) => name);

  const badges = [];
  const totalArticles = profile.articlesReadCount || 0;
  const totalMinutes = Math.round(totalReadingTimeSeconds30 / 60);

  if (currentStreak >= 7) badges.push({ id: "streak_7", label: "7-day streak", description: "Read 7 days in a row" });
  if (currentStreak >= 30) badges.push({ id: "streak_30", label: "30-day streak", description: "Read 30 days in a row" });
  if (totalArticles >= 10) badges.push({ id: "articles_10", label: "10 articles", description: "Read 10 articles" });
  if (totalArticles >= 50) badges.push({ id: "articles_50", label: "50 articles", description: "Read 50 articles" });
  if (totalArticles >= 100) badges.push({ id: "articles_100", label: "100 articles", description: "Read 100 articles" });
  if (totalMinutes >= 60) badges.push({ id: "minutes_60", label: "60 minutes", description: "Read 60 minutes this month" });
  if (totalMinutes >= 300) badges.push({ id: "minutes_300", label: "300 minutes", description: "Read 300 minutes this month" });
  if ((profile.collectionsCount || 0) >= 3) badges.push({ id: "collector", label: "Collector", description: "Created 3 lists" });
  if ((profile.followersCount || 0) >= 10) badges.push({ id: "social_10", label: "Connector", description: "Reached 10 followers" });

  const lastReadAtIso = (lastReadAt as any)?.toISOString?.() ?? null;

  return {
    streak: {
      currentDays: currentStreak,
      longestDays: longestStreak,
      lastReadAt: lastReadAtIso,
    },
    stats: {
      totalArticlesRead: totalArticles,
      totalReadingTimeMinutes: totalMinutes,
      last7DaysCount: Object.entries(articlesByDate).reduce((sum, [date, count]) => {
        const day = new Date(date);
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        return day >= sevenDaysAgo ? sum + count : sum;
      }, 0),
      averageArticlesPerDay: Number((totalArticlesRead30 / 30).toFixed(2)),
      mostActiveDay,
    },
    favorites: {
      topics: topTopics,
      publishers: topSources,
    },
    badges,
    recentReads,
  };
};

// ===== USER PROFILES =====

/**
 * Create or update user profile
 * POST /api/v1/social/profile
 */
export const createOrUpdateProfile = async (req: Request, res: Response) => {
  try {
    const {
      userId,
      username,
      displayName,
      bio,
      avatarUrl,
      socialLinks,
      privacySettings,
      featuredListId,
    }: CreateUserProfileRequest = req.body;

    if (!userId || !username || !displayName) {
      return res.status(400).json({
        success: false,
        message: "userId, username, and displayName are required",
      });
    }

    // Check if username is already taken (excluding current user)
    const usernameQuery = await userProfilesCollection
      .where("username", "==", username)
      .limit(1)
      .get();

    // Check if the found profile belongs to a different user
    if (!usernameQuery.empty) {
      const existingProfileId = usernameQuery.docs[0].id;
      if (existingProfileId !== userId) {
        return res.status(400).json({
          success: false,
          message: "Username already taken",
        });
      }
    }

    const profileData: Partial<UserProfile> = {
      userId,
      username,
      displayName,
      bio: bio || "",
      avatarUrl: avatarUrl || "",
      socialLinks: socialLinks || {},
      privacySettings: privacySettings || {
        showStats: true,
        showLists: true,
        showActivity: true,
        showHighlights: true,
      },
      featuredListId: featuredListId ?? null,
      isPublic: true,
      interests: [],
      stats: {},
    };

    // Check if profile exists
    const existingProfile = await userProfilesCollection.doc(userId).get();

    if (existingProfile.exists) {
      // Update existing profile
      await userProfilesCollection.doc(userId).update({
        ...profileData,
        updatedAt: Timestamp.now(),
      });
    } else {
      // Create new profile
      await userProfilesCollection.doc(userId).set({
        ...profileData,
        joinedDate: Timestamp.now(),
        followersCount: 0,
        followingCount: 0,
        articlesReadCount: 0,
        collectionsCount: 0,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });
    }

    return res.status(200).json({
      success: true,
      message: "Profile saved successfully",
    });
  } catch (error) {
    console.error("Error creating/updating profile:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to save profile",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get profile insights (streak, stats, favorites, badges, recent reads)
 * GET /api/v1/social/profile/:userId/insights
 */
export const getProfileInsights = async (req: Request, res: Response) => {
  try {
    const userIdParam = req.params.userId;
    const userId = Array.isArray(userIdParam) ? userIdParam[0] : userIdParam;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const profileDoc = await userProfilesCollection.doc(userId).get();
    if (!profileDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Profile not found",
      });
    }

    const profile = profileDoc.data() as UserProfile;
    const insights = await buildProfileInsightsPayload(userId, profile);

    return res.status(200).json({
      success: true,
      insights,
    });
  } catch (error) {
    console.error("Error fetching profile insights:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch profile insights",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get My Space summary (aggregated counts + insights)
 * GET /api/v1/social/my-space/:userId
 */
export const getMySpaceSummary = async (req: Request, res: Response) => {
  try {
    const userIdParam = req.params.userId;
    const userId = Array.isArray(userIdParam) ? userIdParam[0] : userIdParam;
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const profileDoc = await userProfilesCollection.doc(userId).get();
    if (!profileDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Profile not found",
      });
    }
    const profile = profileDoc.data() as UserProfile;

    const [
      followersSnap,
      followingSnap,
      postsSnap,
      listsSnap,
      sharesSnap,
      followedPublishersSnap,
      recentListsSnap,
      recentPostsSnap,
    ] = await Promise.all([
      userFollowsCollection.where("followingId", "==", userId).get(),
      userFollowsCollection.where("followerId", "==", userId).get(),
      postsCollection.where("userId", "==", userId).get(),
      readingListsCollection.where("ownerId", "==", userId).get(),
      activityFeedCollection
        .where("userId", "==", userId)
        .where("activityType", "==", "shareArticle")
        .get(),
      followedPublishersCollection.where("userId", "==", userId).get(),
      readingListsCollection
        .where("ownerId", "==", userId)
        .orderBy("updatedAt", "desc")
        .limit(3)
        .get(),
      postsCollection
        .where("userId", "==", userId)
        .orderBy("createdAt", "desc")
        .limit(3)
        .get(),
    ]);

    const followingIds = followingSnap.docs.map((doc) => doc.data().followingId as string);
    let networkHighlightsCount = 0;
    if (followingIds.length > 0) {
      const chunks = chunkArray(followingIds, 10);
      const dedup = new Set<string>();
      for (const chunk of chunks) {
        const activitiesSnap = await activityFeedCollection
          .where("userId", "in", chunk)
          .where("activityType", "==", "shareArticle")
          .limit(250)
          .get();
        activitiesSnap.docs.forEach((doc) => {
          const data = doc.data() as Record<string, any>;
          const key =
            (typeof data.articleId === "string" && data.articleId.length > 0
              ? data.articleId
              : `${data.articleTitle || ""}|${data.articleSourceName || ""}`) || "";
          if (key) dedup.add(key);
        });
      }
      networkHighlightsCount = dedup.size;
    }

    const insights = await buildProfileInsightsPayload(userId, profile);

    setPrivateCache(res, 20);
    return res.status(200).json({
      success: true,
      summary: {
        counts: {
          followers: followersSnap.size,
          following: followingSnap.size,
          posts: postsSnap.size,
          shared: sharesSnap.size,
          readingLists: listsSnap.size,
          followedPublishers: followedPublishersSnap.size,
          networkHighlights: networkHighlightsCount,
        },
        insights,
        recent: {
          lists: recentListsSnap.docs.map((doc) => {
            const row = doc.data() as Record<string, any>;
            return {
              id: doc.id,
              name: row.name || "Untitled List",
              articleCount: Array.isArray(row.articleIds) ? row.articleIds.length : 0,
              updatedAt: convertTimestampsToISO({ updatedAt: row.updatedAt }).updatedAt,
            };
          }),
          posts: recentPostsSnap.docs.map((doc) => {
            const row = doc.data() as Record<string, any>;
            return {
              id: doc.id,
              heading: row.heading || null,
              text: row.text || "",
              createdAt: convertTimestampsToISO({ createdAt: row.createdAt }).createdAt,
            };
          }),
        },
      },
    });
  } catch (error) {
    console.error("Error fetching my space summary:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch my space summary",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get feed summary payload (pre-ranked and tab-ready)
 * GET /api/v1/social/feed-summary/:userId
 */
export const getFeedSummary = async (req: Request, res: Response) => {
  try {
    const userIdParam = req.params.userId;
    const userId = Array.isArray(userIdParam) ? userIdParam[0] : userIdParam;
    const activityLimitQuery = getQueryString(req.query.activityLimit as string | string[] | undefined) || "30";
    const highlightsLimitQuery = getQueryString(req.query.highlightsLimit as string | string[] | undefined) || "20";
    const postPreviewLimitQuery = getQueryString(req.query.postPreviewLimit as string | string[] | undefined) || "20";
    const publishersLimitQuery = getQueryString(req.query.publishersLimit as string | string[] | undefined) || "10";
    const topicsLimitQuery = getQueryString(req.query.topicsLimit as string | string[] | undefined) || "8";

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const activityLimit = Math.min(Math.max(parseInt(activityLimitQuery, 10) || 30, 5), 60);
    const highlightsLimit = Math.min(Math.max(parseInt(highlightsLimitQuery, 10) || 20, 5), 40);
    const postPreviewLimit = Math.min(Math.max(parseInt(postPreviewLimitQuery, 10) || 20, 5), 40);
    const publishersLimit = Math.min(Math.max(parseInt(publishersLimitQuery, 10) || 10, 3), 20);
    const topicsLimit = Math.min(Math.max(parseInt(topicsLimitQuery, 10) || 8, 3), 20);
    const cacheKey = [
      userId,
      activityLimit,
      highlightsLimit,
      postPreviewLimit,
      publishersLimit,
      topicsLimit,
    ].join(":");
    const now = Date.now();
    const ifNoneMatch = Array.isArray(req.headers["if-none-match"])
      ? req.headers["if-none-match"][0]
      : req.headers["if-none-match"];
    const cached = feedSummaryCache.get(cacheKey);

    if (cached && cached.expiresAt > now) {
      res.setHeader("ETag", cached.etag);
      res.setHeader("Cache-Control", "private, max-age=0, must-revalidate");
      if (ifNoneMatch && ifNoneMatch === cached.etag) {
        return res.status(304).end();
      }
      return res.status(200).json(cached.body);
    }

    const followingQuery = await userFollowsCollection.where("followerId", "==", userId).get();
    const followingIds = followingQuery.docs.map((doc) => doc.data().followingId as string);
    const followingSet = new Set<string>(followingIds);
    const feedUserIds = [...followingIds, userId];
    const idChunks = chunkArray(feedUserIds, 10);

    const activities: Array<Record<string, any>> = [];
    const shareActivities: Array<Record<string, any>> = [];
    const posts: Array<Record<string, any>> = [];
    const isMissingIndexError = (error: any): boolean => {
      const details = String(error?.details || error?.message || "");
      return error?.code === 9 || details.includes("requires an index");
    };

    for (const chunk of idChunks) {
      const activitiesSnap = await activityFeedCollection
        .where("userId", "in", chunk)
        .orderBy("timestamp", "desc")
        .limit(activityLimit + 15)
        .get();

      activitiesSnap.docs.forEach((doc) => {
        activities.push({ id: doc.id, ...convertTimestampsToISO(doc.data()) });
      });

      try {
        const sharesSnap = await activityFeedCollection
          .where("userId", "in", chunk)
          .where("activityType", "==", "shareArticle")
          .orderBy("timestamp", "desc")
          .limit(Math.max(highlightsLimit * 6, 90))
          .get();

        sharesSnap.docs.forEach((doc) => {
          shareActivities.push({ id: doc.id, ...doc.data() });
        });
      } catch (sharesError) {
        if (!isMissingIndexError(sharesError)) {
          throw sharesError;
        }
        // Index still building: fallback to userId-in query only, then filter/sort in memory.
        const fallbackShares = await activityFeedCollection
          .where("userId", "in", chunk)
          .limit(Math.max(highlightsLimit * 12, 160))
          .get();
        fallbackShares.docs.forEach((doc) => {
          const row = doc.data() as Record<string, any>;
          if (row.activityType === "shareArticle") {
            shareActivities.push({ id: doc.id, ...row });
          }
        });
      }

      try {
        const postsSnap = await postsCollection
          .where("userId", "in", chunk)
          .orderBy("createdAt", "desc")
          .limit(postPreviewLimit + 12)
          .get();
        postsSnap.docs.forEach((doc) => {
          posts.push({ id: doc.id, ...doc.data() });
        });
      } catch {
        const fallbackPosts = await postsCollection
          .where("userId", "in", chunk)
          .limit(Math.max(postPreviewLimit * 4, 80))
          .get();
        fallbackPosts.docs.forEach((doc) => {
          posts.push({ id: doc.id, ...doc.data() });
        });
      }
    }

    const recentActivity = activities
      .filter((a) => a.userId !== userId)
      .sort((a, b) => {
        const aFollowed = followingSet.has(a.userId as string);
        const bFollowed = followingSet.has(b.userId as string);
        if (aFollowed !== bFollowed) return aFollowed ? -1 : 1;
        return toMillis(b.timestamp) - toMillis(a.timestamp);
      })
      .slice(0, activityLimit);

    const sharedActivity = activities
      .filter((a) => a.activityType === "shareArticle")
      .sort((a, b) => toMillis(b.timestamp) - toMillis(a.timestamp))
      .slice(0, activityLimit);

    const highlightsMap = new Map<string, Record<string, any>>();
    shareActivities.forEach((activity) => {
      const articleId = activity.articleId as string | undefined;
      const articleTitle = activity.articleTitle as string | undefined;
      const articleSourceName = activity.articleSourceName as string | undefined;
      const dedupeKey = articleId || `${articleTitle ?? ""}|${articleSourceName ?? ""}`;
      if (!dedupeKey) return;
      const sharedAt = toMillis(activity.timestamp);
      const username = typeof activity.username === "string" ? activity.username : "Reader";

      const existing = highlightsMap.get(dedupeKey);
      if (!existing) {
        highlightsMap.set(dedupeKey, {
          dedupeKey,
          articleId: articleId || null,
          articleTitle: articleTitle || "Shared article",
          articleSourceName: articleSourceName || null,
          articleImageUrl: activity.articleImageUrl || null,
          articleUrl: activity.articleUrl || null,
          articleDescription: activity.articleDescription || null,
          latestSharedAt: convertTimestampsToISO({ timestamp: activity.timestamp }).timestamp,
          shareCount: 1,
          likeCount: 0,
          commentCount: 0,
          sharers: [username],
          _latestMillis: sharedAt,
        });
        return;
      }

      existing.shareCount = (existing.shareCount as number) + 1;
      const sharers = new Set<string>([...(existing.sharers as string[]), username]);
      existing.sharers = Array.from(sharers).slice(0, 4);
      if (sharedAt > (existing._latestMillis as number)) {
        existing._latestMillis = sharedAt;
        existing.latestSharedAt = convertTimestampsToISO({ timestamp: activity.timestamp }).timestamp;
      }
    });

    const networkHighlights = Array.from(highlightsMap.values())
      .sort((a, b) => {
        if ((b.shareCount as number) !== (a.shareCount as number)) {
          return (b.shareCount as number) - (a.shareCount as number);
        }
        return toMillis(b.latestSharedAt) - toMillis(a.latestSharedAt);
      })
      .slice(0, highlightsLimit)
      .map((item) => {
        const { _latestMillis, ...rest } = item;
        return rest;
      });

    const postDedup = new Map<string, Record<string, any>>();
    posts
      .sort((a, b) => toMillis(b.createdAt) - toMillis(a.createdAt))
      .forEach((item) => {
        const id = item.id as string;
        if (!postDedup.has(id)) postDedup.set(id, item);
      });

    const previewPosts = Array.from(postDedup.values())
      .filter((p) => p.userId !== userId)
      .slice(0, postPreviewLimit)
      .map((p) => ({
        ...convertTimestampsToISO(p),
        isLiked: false,
      }));

    const [publishersSnap, topicsSnap] = await Promise.all([
      followedPublishersCollection
        .where("userId", "==", userId)
        .orderBy("followedAt", "desc")
        .limit(publishersLimit)
        .get()
        .catch(async () => followedPublishersCollection.where("userId", "==", userId).limit(publishersLimit).get()),
      articlesCollection.orderBy("pubDate", "desc").limit(180).get(),
    ]);

    const followedPublishers = publishersSnap.docs
      .map((doc) => (doc.data().publisherName as string | undefined) || "")
      .filter((name) => name.trim().length > 0);

    const topicCount = new Map<string, number>();
    topicsSnap.docs.forEach((doc) => {
      const row = doc.data() as Record<string, any>;
      const categories = Array.isArray(row.category) ? row.category : [];
      categories.forEach((c) => {
        if (typeof c !== "string") return;
        const topic = c.trim();
        if (!topic) return;
        topicCount.set(topic, (topicCount.get(topic) || 0) + 1);
      });
    });

    const followedTopics = Array.from(topicCount.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, topicsLimit)
      .map(([name]) => name);

    const body: Record<string, any> = {
      success: true,
      feed: {
        recentActivity,
        sharedActivity,
        networkHighlights,
        previewPosts,
        followedPublishers,
        followedTopics,
      },
    };

    const etag = `"${createHash("sha1").update(JSON.stringify(body)).digest("hex")}"`;
    feedSummaryCache.set(cacheKey, {
      etag,
      body,
      expiresAt: now + FEED_SUMMARY_CACHE_TTL_MS,
    });

    res.setHeader("ETag", etag);
    res.setHeader("Cache-Control", "private, max-age=0, must-revalidate");
    return res.status(200).json(body);
  } catch (error) {
    console.error("Error fetching feed summary:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch feed summary",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get people summary payload (followers/following/recommended)
 * GET /api/v1/social/people-summary/:userId?limit=10
 */
export const getPeopleSummary = async (req: Request, res: Response) => {
  try {
    const userIdParam = req.params.userId;
    const userId = Array.isArray(userIdParam) ? userIdParam[0] : userIdParam;
    const limitQuery = getQueryString(req.query.limit as string | string[] | undefined) || "10";

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const limit = Math.min(Math.max(parseInt(limitQuery, 10) || 10, 3), 20);

    const [currentProfileDoc, followersSnap, followingSnap] = await Promise.all([
      userProfilesCollection.doc(userId).get(),
      userFollowsCollection
        .where("followingId", "==", userId)
        .orderBy("followedAt", "desc")
        .limit(limit)
        .get(),
      userFollowsCollection
        .where("followerId", "==", userId)
        .orderBy("followedAt", "desc")
        .limit(limit)
        .get(),
    ]);

    const followerIds = followersSnap.docs
      .map((doc) => (doc.data() as Record<string, any>).followerId as string)
      .filter((id) => typeof id === "string" && id.length > 0);
    const followingIds = followingSnap.docs
      .map((doc) => (doc.data() as Record<string, any>).followingId as string)
      .filter((id) => typeof id === "string" && id.length > 0);

    const followerDocs = await Promise.all(
      followerIds.map((id) => userProfilesCollection.doc(id).get())
    );
    const followingDocs = await Promise.all(
      followingIds.map((id) => userProfilesCollection.doc(id).get())
    );

    const followers = followerDocs
      .filter((doc) => doc.exists)
      .map((doc) => ({ id: doc.id, ...convertTimestampsToISO(doc.data()) }));
    const following = followingDocs
      .filter((doc) => doc.exists)
      .map((doc) => ({ id: doc.id, ...convertTimestampsToISO(doc.data()) }));

    const currentTopics = currentProfileDoc.exists
      ? getProfileTopicSet((currentProfileDoc.data() || {}) as Record<string, any>)
      : new Set<string>();
    const followingSet = new Set<string>(followingIds);
    const followerSet = new Set<string>(followerIds);

    const publicProfiles = await userProfilesCollection
      .where("isPublic", "==", true)
      .limit(140)
      .get();

    const recommended = publicProfiles.docs
      .map((doc) => ({ id: doc.id, profile: doc.data() as Record<string, any> }))
      .filter((candidate) => {
        if (candidate.id === userId) return false;
        if (followingSet.has(candidate.id)) return false;
        return true;
      })
      .map((candidate) => {
        const candidateTopics = getProfileTopicSet(candidate.profile);
        let overlap = 0;
        currentTopics.forEach((topic) => {
          if (candidateTopics.has(topic)) overlap += 1;
        });
        const followerBoost = followerSet.has(candidate.id) ? 1 : 0;
        return {
          id: candidate.id,
          score: overlap * 2 + followerBoost,
          profile: candidate.profile,
        };
      })
      .sort((a, b) => b.score - a.score)
      .slice(0, limit)
      .map((entry) => ({
        id: entry.id,
        ...convertTimestampsToISO(entry.profile),
      }));

    setPrivateCache(res, 20);
    return res.status(200).json({
      success: true,
      people: {
        followers,
        following,
        recommended,
      },
      counts: {
        followers: followers.length,
        following: following.length,
        recommended: recommended.length,
      },
    });
  } catch (error) {
    console.error("Error loading people summary:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to load people summary",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get user profile by ID
 * GET /api/v1/social/profile/:userId
 */
export const getUserProfile = async (req: Request, res: Response) => {
  try {
    const userId = getOptionalString(req.params.userId);
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const profileDoc = await userProfilesCollection.doc(userId).get();

    if (!profileDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Profile not found",
      });
    }

    const profileData = profileDoc.data();
    const convertedProfile = convertTimestampsToISO(profileData);

    return res.status(200).json({
      success: true,
      profile: { id: profileDoc.id, ...convertedProfile },
    });
  } catch (error) {
    console.error("Error fetching profile:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch profile",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Search users by username or display name
 * GET /api/v1/social/users/search?query=...&limit=20
 */
export const searchUsers = async (req: Request, res: Response) => {
  try {
    const { query, limit = "20" } = req.query as { query?: string; limit?: string };

    if (!query) {
      return res.status(400).json({
        success: false,
        message: "Query parameter is required",
      });
    }

    const searchQuery = query.toLowerCase();
    const limitNum = parseInt(limit as string) || 20;

    // Fetch all profiles (Firestore doesn't support case-insensitive LIKE queries)
    const profilesSnapshot = await userProfilesCollection
      .where("isPublic", "==", true)
      .limit(100) // Limit initial fetch for performance
      .get();

    const matchingProfiles: any[] = [];
    profilesSnapshot.forEach((doc) => {
      const profile = doc.data();
      const username = (profile.username || "").toLowerCase();
      const displayName = (profile.displayName || "").toLowerCase();

      if (username.includes(searchQuery) || displayName.includes(searchQuery)) {
        const convertedProfile = convertTimestampsToISO(profile);
        matchingProfiles.push({ id: doc.id, ...convertedProfile });
      }
    });

    // Sort by relevance (exact matches first) and limit results
    const sortedProfiles = matchingProfiles
      .sort((a, b) => {
        const aUsername = a.username.toLowerCase();
        const bUsername = b.username.toLowerCase();
        const aExact = aUsername === searchQuery ? 1 : 0;
        const bExact = bUsername === searchQuery ? 1 : 0;
        return bExact - aExact;
      })
      .slice(0, limitNum);

    return res.status(200).json({
      success: true,
      users: sortedProfiles,
      count: sortedProfiles.length,
    });
  } catch (error) {
    console.error("Error searching users:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to search users",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get recommended users to follow
 * GET /api/v1/social/users/recommended/:userId?limit=10
 */
export const getRecommendedUsers = async (req: Request, res: Response) => {
  try {
    const userIdParam = req.params.userId;
    const userId = Array.isArray(userIdParam) ? userIdParam[0] : userIdParam;
    const limitQuery = getQueryString(req.query.limit as string | string[] | undefined) || "10";
    const cursorQuery = getQueryString(req.query.cursor as string | string[] | undefined) || "0";

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const parsedLimit = parseInt(limitQuery, 10);
    const parsedCursor = parseInt(cursorQuery, 10);
    const limitNum = Number.isFinite(parsedLimit)
      ? Math.min(Math.max(parsedLimit, 1), RECOMMENDATION_MAX_LIMIT)
      : 10;
    const offsetNum = Number.isFinite(parsedCursor) ? Math.max(parsedCursor, 0) : 0;

    const [currentProfileDoc, followingQuery] = await Promise.all([
      userProfilesCollection.doc(userId).get(),
      userFollowsCollection.where("followerId", "==", userId).get(),
    ]);

    const followingIds = new Set(
      followingQuery.docs.map((doc) => (doc.data() as Record<string, any>).followingId as string)
    );
    const followingList = Array.from(followingIds);
    const currentProfile = currentProfileDoc.exists
      ? (currentProfileDoc.data() as Record<string, any>)
      : null;
    const currentProfileTopics = currentProfile ? getProfileTopicSet(currentProfile) : new Set<string>();
    const readingCategoryWeights = await getUserReadingCategoryWeights(userId);
    const currentReadingTopics = new Set(
      Array.from(readingCategoryWeights.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, 8)
        .map(([topic]) => topic)
    );

    const mutualOverlapMap = new Map<string, number>();
    if (followingList.length > 0) {
      const followingChunks = chunkArray(followingList, 10);
      for (const followChunk of followingChunks) {
        const overlapQuery = await userFollowsCollection
          .where("followingId", "in", followChunk)
          .get();
        overlapQuery.docs.forEach((doc) => {
          const followData = doc.data() as Record<string, any>;
          const candidateId = followData.followerId as string | undefined;
          if (!candidateId || candidateId === userId || followingIds.has(candidateId)) return;
          mutualOverlapMap.set(candidateId, (mutualOverlapMap.get(candidateId) || 0) + 1);
        });
      }
    }

    const profilesSnapshot = await userProfilesCollection
      .where("isPublic", "==", true)
      .get();

    const candidates: Array<{ id: string; profile: Record<string, any> }> = [];
    profilesSnapshot.forEach((doc) => {
      const profile = doc.data() as Record<string, any>;
      const id = doc.id;
      if (id === userId) return;
      if (followingIds.has(id)) return;
      candidates.push({ id, profile });
    });

    const scored = candidates.map((candidate) => {
      const profile = candidate.profile;
      const candidateTopics = getProfileTopicSet(profile);
      const mutualOverlap = mutualOverlapMap.get(candidate.id) || 0;

      let sharedProfileTopics = 0;
      currentProfileTopics.forEach((topic) => {
        if (candidateTopics.has(topic)) sharedProfileTopics += 1;
      });

      let sharedReadingTopics = 0;
      currentReadingTopics.forEach((topic) => {
        if (candidateTopics.has(topic)) sharedReadingTopics += 1;
      });

      const followersCount = Number(profile.followersCount || 0);
      const collectionsCount = Number(profile.collectionsCount || 0);
      const articlesReadCount = Number(profile.articlesReadCount || 0);

      const mutualScore = Math.min(mutualOverlap * 3.5, 14);
      const interestScore = Math.min(sharedProfileTopics * 2.0, 8);
      const readingAlignmentScore = Math.min(sharedReadingTopics * 1.5, 6);
      const popularityScore = Math.min(Math.log1p(followersCount), 4) * 0.7;
      const curationScore = Math.min(collectionsCount, 25) * 0.08;
      const readingScore = Math.min(articlesReadCount, 300) * 0.01;
      const profileCompletenessBoost =
        (typeof profile.avatarUrl === "string" && profile.avatarUrl.trim().length > 0 ? 0.3 : 0) +
        (typeof profile.bio === "string" && profile.bio.trim().length > 0 ? 0.2 : 0);

      const score =
        mutualScore +
        interestScore +
        readingAlignmentScore +
        popularityScore +
        curationScore +
        readingScore +
        profileCompletenessBoost;

      const reasons: string[] = [];
      if (mutualOverlap > 0) reasons.push(`${mutualOverlap} mutual connection${mutualOverlap > 1 ? "s" : ""}`);
      if (sharedProfileTopics > 0) reasons.push(`${sharedProfileTopics} shared interest${sharedProfileTopics > 1 ? "s" : ""}`);
      if (sharedReadingTopics > 0) reasons.push("matches your reading topics");

      return {
        candidate,
        score,
        reasons,
        mutualOverlap,
        sharedProfileTopics,
        followersCount,
        collectionsCount,
      };
    });

    const sorted = scored.sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score;
      if (b.mutualOverlap !== a.mutualOverlap) return b.mutualOverlap - a.mutualOverlap;
      if (b.sharedProfileTopics !== a.sharedProfileTopics) return b.sharedProfileTopics - a.sharedProfileTopics;
      if (b.followersCount !== a.followersCount) return b.followersCount - a.followersCount;
      return b.collectionsCount - a.collectionsCount;
    });

    const pagedEntries = sorted.slice(offsetNum, offsetNum + limitNum);
    const recommended = pagedEntries.map((entry) => {
      const convertedProfile = convertTimestampsToISO(entry.candidate.profile);
      return {
        id: entry.candidate.id,
        ...convertedProfile,
        recommendationScore: Number(entry.score.toFixed(3)),
        recommendationReasons: entry.reasons.slice(0, 2),
      };
    });
    const hasMore = offsetNum + recommended.length < sorted.length;
    const nextCursor = hasMore ? String(offsetNum + recommended.length) : null;

    return res.status(200).json({
      success: true,
      users: recommended,
      count: recommended.length,
      hasMore,
      nextCursor,
    });
  } catch (error) {
    console.error("Error fetching recommended users:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch recommended users",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Update user profile
 * PUT /api/v1/social/profile
 */
export const updateProfile = async (req: Request, res: Response) => {
  try {
    const { userId, ...updates }: UpdateUserProfileRequest = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    // Check if profile exists
    const profileDoc = await userProfilesCollection.doc(userId).get();
    if (!profileDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Profile not found",
      });
    }

    // Update profile
    await userProfilesCollection.doc(userId).update({
      ...updates,
      updatedAt: Timestamp.now(),
    });

    return res.status(200).json({
      success: true,
      message: "Profile updated successfully",
    });
  } catch (error) {
    console.error("Error updating profile:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update profile",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

// ===== FOLLOW SYSTEM =====

/**
 * Follow a user
 * POST /api/v1/social/follow
 */
export const followUser = async (req: Request, res: Response) => {
  try {
    const { followerId, followingId }: FollowUserRequest = req.body;

    if (!followerId || !followingId) {
      return res.status(400).json({
        success: false,
        message: "followerId and followingId are required",
      });
    }

    if (followerId === followingId) {
      return res.status(400).json({
        success: false,
        message: "Cannot follow yourself",
      });
    }

    // Check if already following
    const existingFollow = await userFollowsCollection
      .where("followerId", "==", followerId)
      .where("followingId", "==", followingId)
      .limit(1)
      .get();

    if (!existingFollow.empty) {
      return res.status(200).json({
        success: true,
        message: "Already following this user",
        alreadyFollowing: true,
      });
    }

    // Create follow relationship
    const followData: UserFollow = {
      followerId,
      followingId,
      followedAt: Timestamp.now(),
    };

    await userFollowsCollection.add(followData);

    // Update follower/following counts
    await userProfilesCollection.doc(followerId).update({
      followingCount: FieldValue.increment(1),
    });
    await userProfilesCollection.doc(followingId).update({
      followersCount: FieldValue.increment(1),
    });

    // Create activity
    const followerProfile = await userProfilesCollection.doc(followerId).get();
    const followingProfile = await userProfilesCollection.doc(followingId).get();

    if (followerProfile.exists && followingProfile.exists) {
      const followerData = followerProfile.data() as UserProfile;
      const followingData = followingProfile.data() as UserProfile;

      await activityFeedCollection.add({
        userId: followerId,
        username: followerData.username,
        userAvatarUrl: followerData.avatarUrl || null,
        activityType: 'followUser',
        timestamp: Timestamp.now(),
        followedUserId: followingId,
        followedUsername: followingData.username,
      });
    }

    return res.status(201).json({
      success: true,
      message: "User followed successfully",
    });
  } catch (error) {
    console.error("Error following user:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to follow user",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Unfollow a user
 * DELETE /api/v1/social/follow
 */
export const unfollowUser = async (req: Request, res: Response) => {
  try {
    const { followerId, followingId } = req.body;

    if (!followerId || !followingId) {
      return res.status(400).json({
        success: false,
        message: "followerId and followingId are required",
      });
    }

    // Find and delete follow relationship
    const followQuery = await userFollowsCollection
      .where("followerId", "==", followerId)
      .where("followingId", "==", followingId)
      .limit(1)
      .get();

    if (followQuery.empty) {
      return res.status(404).json({
        success: false,
        message: "Follow relationship not found",
      });
    }

    await followQuery.docs[0].ref.delete();

    // Update follower/following counts
    await userProfilesCollection.doc(followerId).update({
      followingCount: FieldValue.increment(-1),
    });
    await userProfilesCollection.doc(followingId).update({
      followersCount: FieldValue.increment(-1),
    });

    return res.status(200).json({
      success: true,
      message: "User unfollowed successfully",
    });
  } catch (error) {
    console.error("Error unfollowing user:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to unfollow user",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Check if following a user
 * GET /api/v1/social/follow/check/:followerId/:followingId
 */
export const checkFollowing = async (req: Request, res: Response) => {
  try {
    const { followerId, followingId } = req.params;

    const followQuery = await userFollowsCollection
      .where("followerId", "==", followerId)
      .where("followingId", "==", followingId)
      .limit(1)
      .get();

    return res.status(200).json({
      success: true,
      isFollowing: !followQuery.empty,
    });
  } catch (error) {
    console.error("Error checking follow status:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to check follow status",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get followers of a user
 * GET /api/v1/social/followers/:userId
 */
export const getFollowers = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const followersQuery = await userFollowsCollection
      .where("followingId", "==", userId)
      .get();

    const followerIds = followersQuery.docs.map((doc) => doc.data().followerId);

    // Fetch follower profiles
    const followers: any[] = [];
    for (const followerId of followerIds) {
      const profileDoc = await userProfilesCollection.doc(followerId).get();
      if (profileDoc.exists) {
        const profileData = profileDoc.data();
        const convertedProfile = convertTimestampsToISO(profileData);
        followers.push({ id: profileDoc.id, ...convertedProfile });
      }
    }

    setPrivateCache(res, 15);
    return res.status(200).json({
      success: true,
      followers,
      count: followers.length,
    });
  } catch (error) {
    console.error("Error fetching followers:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch followers",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get users that a user follows
 * GET /api/v1/social/following/:userId
 */
export const getFollowing = async (req: Request, res: Response) => {
  try {
    const userIdParam = req.params.userId;
    const userId = Array.isArray(userIdParam) ? userIdParam[0] : userIdParam;
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const limitQuery = getQueryString(req.query.limit as string | string[] | undefined);
    const cursorQuery = getQueryString(req.query.cursor as string | string[] | undefined);

    const parsedLimit = limitQuery ? parseInt(limitQuery, 10) : NaN;
    const hasPagination = Number.isFinite(parsedLimit) && parsedLimit > 0;
    const pageLimit = hasPagination
      ? Math.min(Math.max(parsedLimit, 1), 100)
      : null;

    let followingDocs;
    if (pageLimit != null) {
      let query = userFollowsCollection
        .where("followerId", "==", userId)
        .orderBy("followedAt", "desc")
        .limit(pageLimit);

      const cursorMillis = cursorQuery ? parseInt(cursorQuery, 10) : NaN;
      if (Number.isFinite(cursorMillis) && cursorMillis > 0) {
        query = query.startAfter(Timestamp.fromMillis(cursorMillis));
      }

      followingDocs = (await query.get()).docs;
    } else {
      followingDocs = (
        await userFollowsCollection.where("followerId", "==", userId).get()
      ).docs;
    }

    const followingIds = followingDocs.map((doc) => doc.data().followingId);

    // Fetch following profiles
    const profileDocs = await Promise.all(
      followingIds.map((followingId) => userProfilesCollection.doc(followingId).get())
    );
    const following: any[] = [];
    for (const profileDoc of profileDocs) {
      if (profileDoc.exists) {
        const profileData = profileDoc.data();
        const convertedProfile = convertTimestampsToISO(profileData);
        following.push({ id: profileDoc.id, ...convertedProfile });
      }
    }

    let hasMore = false;
    let nextCursor: string | null = null;
    if (pageLimit != null) {
      hasMore = followingDocs.length == pageLimit;
      if (hasMore) {
        const lastFollowedAt = followingDocs[followingDocs.length - 1].data().followedAt;
        if (lastFollowedAt && typeof lastFollowedAt.toMillis === "function") {
          nextCursor = String(lastFollowedAt.toMillis());
        } else {
          hasMore = false;
        }
      }
    }

    setPrivateCache(res, 15);
    return res.status(200).json({
      success: true,
      following,
      count: following.length,
      hasMore,
      nextCursor,
    });
  } catch (error) {
    console.error("Error fetching following:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch following",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

// ===== READING LISTS =====

const canViewReadingList = async (
  list: ReadingList,
  viewerId?: string
): Promise<boolean> => {
  if (list.visibility === "public") return true;
  if (!viewerId || viewerId.trim().length === 0) return false;
  if (list.ownerId === viewerId) return true;
  if (Array.isArray(list.collaboratorIds) && list.collaboratorIds.includes(viewerId)) return true;

  if (list.visibility === "friendsOnly") {
    const followDoc = await userFollowsCollection
      .where("followerId", "==", viewerId)
      .where("followingId", "==", list.ownerId)
      .limit(1)
      .get();
    return !followDoc.empty;
  }

  return false;
};

const canEditReadingList = (list: ReadingList, userId?: string): boolean => {
  if (!userId || userId.trim().length === 0) return false;
  return (
    list.ownerId === userId ||
    (Array.isArray(list.collaboratorIds) && list.collaboratorIds.includes(userId))
  );
};

/**
 * Create a reading list
 * POST /api/v1/social/reading-lists
 */
export const createReadingList = async (req: Request, res: Response) => {
  try {
    const { ownerId, name, description, visibility = 'public', tags = [] }: CreateReadingListRequest = req.body;

    if (!ownerId || !name) {
      return res.status(400).json({
        success: false,
        message: "ownerId and name are required",
      });
    }

    // Get owner profile
    const ownerProfile = await userProfilesCollection.doc(ownerId).get();
    if (!ownerProfile.exists) {
      return res.status(404).json({
        success: false,
        message: "Owner profile not found",
      });
    }

    const ownerData = ownerProfile.data() as UserProfile;

    const listData: ReadingList = {
      name,
      description: description || "",
      ownerId,
      ownerName: ownerData.username,
      articleIds: [],
      collaboratorIds: [],
      visibility,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      tags,
      isCollaborative: false,
    };

    const docRef = await readingListsCollection.add(listData);

    // Update user's collection count
    await userProfilesCollection.doc(ownerId).update({
      collectionsCount: FieldValue.increment(1),
    });

    // Create activity
    await activityFeedCollection.add({
      userId: ownerId,
      username: ownerData.username,
      userAvatarUrl: ownerData.avatarUrl || null,
      activityType: 'createList',
      timestamp: Timestamp.now(),
      listId: docRef.id,
      listName: name,
    });

    return res.status(201).json({
      success: true,
      message: "Reading list created successfully",
      listId: docRef.id,
    });
  } catch (error) {
    console.error("Error creating reading list:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to create reading list",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get user's reading lists
 * GET /api/v1/social/reading-lists/:userId
 */
export const getUserReadingLists = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const [ownedListsQuery, collaborativeListsQuery] = await Promise.all([
      readingListsCollection.where("ownerId", "==", userId).get(),
      readingListsCollection.where("collaboratorIds", "array-contains", userId).get(),
    ]);

    const merged = new Map<string, Record<string, any>>();
    for (const doc of [...ownedListsQuery.docs, ...collaborativeListsQuery.docs]) {
      const convertedList = convertTimestampsToISO(doc.data());
      merged.set(doc.id, {
        id: doc.id,
        ...convertedList,
      });
    }

    const lists = [...merged.values()].sort((a, b) => {
      const aMs = Date.parse(a.updatedAt as string);
      const bMs = Date.parse(b.updatedAt as string);
      return (Number.isNaN(bMs) ? 0 : bMs) - (Number.isNaN(aMs) ? 0 : aMs);
    });

    setPrivateCache(res, 20);
    return res.status(200).json({
      success: true,
      lists,
      count: lists.length,
    });
  } catch (error) {
    console.error("Error fetching reading lists:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch reading lists",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get public reading lists
 * GET /api/v1/social/reading-lists/public
 */
export const getPublicReadingLists = async (req: Request, res: Response) => {
  try {
    const { limit = "20", cursor, query, tag } = req.query;
    const limitNum = Math.min(50, Math.max(1, parseInt(limit as string) || 20));
    const cursorMs = cursor ? parseInt(cursor as string) : null;
    const normalizedQuery =
      typeof query === "string" ? query.trim().toLowerCase() : "";
    const normalizedTag = typeof tag === "string" ? tag.trim().toLowerCase() : "";

    // Keep query index-light: fetch a bounded slice, then filter/sort in memory.
    const listsQuery = await readingListsCollection
      .where("visibility", "==", "public")
      .limit(200)
      .get();

    let lists = listsQuery.docs.map((doc) => {
      const listData = doc.data();
      const convertedList = convertTimestampsToISO(listData);
      return {
        id: doc.id,
        ...convertedList,
      };
    });

    if (normalizedTag) {
      lists = lists.filter((list) =>
        Array.isArray(list.tags) &&
        list.tags.some((entry: any) =>
          typeof entry === "string" && entry.toLowerCase() === normalizedTag
        )
      );
    }

    if (normalizedQuery) {
      lists = lists.filter((list) => {
        const name = typeof list.name === "string" ? list.name.toLowerCase() : "";
        const description =
          typeof list.description === "string" ? list.description.toLowerCase() : "";
        const ownerName =
          typeof list.ownerName === "string" ? list.ownerName.toLowerCase() : "";
        return (
          name.includes(normalizedQuery) ||
          description.includes(normalizedQuery) ||
          ownerName.includes(normalizedQuery)
        );
      });
    }

    lists.sort((a, b) => Date.parse(b.updatedAt as string) - Date.parse(a.updatedAt as string));

    if (cursorMs != null && !Number.isNaN(cursorMs)) {
      lists = lists.filter((list) => Date.parse(list.updatedAt as string) < cursorMs);
    }

    const page = lists.slice(0, limitNum);
    const hasMore = lists.length > page.length;
    const last = page.length > 0 ? page[page.length - 1] : null;
    const nextCursor = last ? String(Date.parse(last.updatedAt as string)) : null;

    setPrivateCache(res, 30);
    return res.status(200).json({
      success: true,
      lists: page,
      count: page.length,
      hasMore,
      nextCursor,
    });
  } catch (error) {
    console.error("Error fetching public lists:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch public lists",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get reading list by ID
 * GET /api/v1/social/reading-lists/list/:listId
 */
export const getReadingListById = async (req: Request, res: Response) => {
  try {
    const listId = getOptionalString(req.params.listId);
    const viewerId = getQueryString(req.query.viewerId as string | string[] | undefined);

    if (!listId) {
      return res.status(400).json({
        success: false,
        message: "listId is required",
      });
    }

    const listDoc = await readingListsCollection.doc(listId).get();
    if (!listDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Reading list not found",
      });
    }

    const listData = listDoc.data() as ReadingList;
    const allowed = await canViewReadingList(listData, viewerId);
    if (!allowed) {
      return res.status(403).json({
        success: false,
        message: "You do not have permission to view this list",
      });
    }

    const convertedList = convertTimestampsToISO(listData);
    setPrivateCache(res, 20);
    return res.status(200).json({
      success: true,
      list: {
        id: listDoc.id,
        ...convertedList,
      },
    });
  } catch (error) {
    console.error("Error fetching reading list by ID:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch reading list",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Add article to reading list
 * POST /api/v1/social/reading-lists/articles
 */
export const addArticleToList = async (req: Request, res: Response) => {
  try {
    const { listId, articleId, userId }: AddArticleToListRequest & { userId?: string } = req.body;

    if (!listId || !articleId) {
      return res.status(400).json({
        success: false,
        message: "listId and articleId are required",
      });
    }

    const listDoc = await readingListsCollection.doc(listId).get();
    if (!listDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Reading list not found",
      });
    }

    const listData = listDoc.data() as ReadingList;
    const actorId = typeof userId === "string" ? userId : "";
    if (actorId && !canEditReadingList(listData, actorId)) {
      return res.status(403).json({
        success: false,
        message: "You do not have permission to modify this list",
      });
    }

    if (listData.articleIds.includes(articleId)) {
      return res.status(200).json({
        success: true,
        message: "Article already in list",
        alreadyAdded: true,
      });
    }

    await readingListsCollection.doc(listId).update({
      articleIds: FieldValue.arrayUnion(articleId),
      updatedAt: Timestamp.now(),
    });

    if (actorId) {
      const actorProfileDoc = await userProfilesCollection.doc(actorId).get();
      const actorProfile = actorProfileDoc.exists ? (actorProfileDoc.data() as UserProfile) : null;
      await activityFeedCollection.add({
        userId: actorId,
        username: actorProfile?.username || "user",
        userAvatarUrl: actorProfile?.avatarUrl || null,
        activityType: "addToList",
        timestamp: Timestamp.now(),
        listId,
        listName: listData.name,
        articleId,
      });
    }

    return res.status(200).json({
      success: true,
      message: "Article added to list successfully",
    });
  } catch (error) {
    console.error("Error adding article to list:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to add article to list",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Remove article from reading list
 * DELETE /api/v1/social/reading-lists/articles
 */
export const removeArticleFromList = async (req: Request, res: Response) => {
  try {
    const { listId, articleId, userId } = req.body as {
      listId?: string;
      articleId?: string;
      userId?: string;
    };

    if (!listId || !articleId) {
      return res.status(400).json({
        success: false,
        message: "listId and articleId are required",
      });
    }

    const listDoc = await readingListsCollection.doc(listId).get();
    if (!listDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Reading list not found",
      });
    }

    const listData = listDoc.data() as ReadingList;
    const actorId = typeof userId === "string" ? userId : "";
    if (!canEditReadingList(listData, actorId)) {
      return res.status(403).json({
        success: false,
        message: "You do not have permission to modify this list",
      });
    }

    if (!listData.articleIds.includes(articleId)) {
      return res.status(200).json({
        success: true,
        message: "Article is not in this list",
        alreadyRemoved: true,
      });
    }

    await readingListsCollection.doc(listId).update({
      articleIds: FieldValue.arrayRemove(articleId),
      updatedAt: Timestamp.now(),
    });

    return res.status(200).json({
      success: true,
      message: "Article removed from list successfully",
    });
  } catch (error) {
    console.error("Error removing article from reading list:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to remove article from list",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Reorder reading list articles
 * PUT /api/v1/social/reading-lists/order
 */
export const reorderReadingListArticles = async (req: Request, res: Response) => {
  try {
    const { listId, articleIds, userId }: ReorderListArticlesRequest = req.body;

    if (!listId || !Array.isArray(articleIds)) {
      return res.status(400).json({
        success: false,
        message: "listId and articleIds are required",
      });
    }

    const listDoc = await readingListsCollection.doc(listId).get();
    if (!listDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Reading list not found",
      });
    }

    const listData = listDoc.data() as ReadingList;
    if (!canEditReadingList(listData, userId)) {
      return res.status(403).json({
        success: false,
        message: "You do not have permission to reorder this list",
      });
    }

    const uniqueIncoming = [...new Set(articleIds)];
    const existingSet = new Set(listData.articleIds);
    const sameSize = uniqueIncoming.length === listData.articleIds.length;
    const hasSameEntries = uniqueIncoming.every((id) => existingSet.has(id));

    if (!sameSize || !hasSameEntries) {
      return res.status(400).json({
        success: false,
        message: "articleIds must contain the same items already in the list",
      });
    }

    await readingListsCollection.doc(listId).update({
      articleIds: uniqueIncoming,
      updatedAt: Timestamp.now(),
    });

    return res.status(200).json({
      success: true,
      message: "Reading list reordered successfully",
    });
  } catch (error) {
    console.error("Error reordering reading list:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to reorder reading list",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Add collaborator to reading list
 * POST /api/v1/social/reading-lists/collaborators
 */
export const addCollaboratorToList = async (req: Request, res: Response) => {
  try {
    const {
      listId,
      ownerId,
      collaboratorId,
      userId,
    }: AddCollaboratorRequest = req.body;

    const targetUserId = collaboratorId || userId;
    if (!listId || !ownerId || !targetUserId) {
      return res.status(400).json({
        success: false,
        message: "listId, ownerId and collaboratorId are required",
      });
    }

    const listDoc = await readingListsCollection.doc(listId).get();
    if (!listDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Reading list not found",
      });
    }

    const listData = listDoc.data() as ReadingList;
    if (listData.ownerId !== ownerId) {
      return res.status(403).json({
        success: false,
        message: "Only the list owner can add collaborators",
      });
    }

    if (targetUserId === ownerId) {
      return res.status(400).json({
        success: false,
        message: "Owner is already a collaborator",
      });
    }

    const collaboratorProfile = await userProfilesCollection.doc(targetUserId).get();
    if (!collaboratorProfile.exists) {
      return res.status(404).json({
        success: false,
        message: "Collaborator profile not found",
      });
    }

    await readingListsCollection.doc(listId).update({
      collaboratorIds: FieldValue.arrayUnion(targetUserId),
      isCollaborative: true,
      updatedAt: Timestamp.now(),
    });

    return res.status(200).json({
      success: true,
      message: "Collaborator added successfully",
    });
  } catch (error) {
    console.error("Error adding collaborator to reading list:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to add collaborator",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

// ===== NETWORK POSTS =====

/**
 * Create a network post
 * POST /api/v1/social/posts
 */
export const createNetworkPost = async (req: Request, res: Response) => {
  try {
    const {
      userId,
      text,
      heading,
      articleId,
      articleTitle,
      articleImageUrl,
      articleUrl,
    }: CreateNetworkPostRequest = req.body;

    if (!userId || typeof text !== "string") {
      return res.status(400).json({
        success: false,
        message: "userId and text are required",
      });
    }

    const normalizedText = text.trim().slice(0, 600);
    const normalizedHeading =
      typeof heading === "string" ? heading.trim().slice(0, 160) : "";
    const rawArticleUrl =
      typeof articleUrl === "string" ? articleUrl.trim().slice(0, 2000) : "";

    if (!normalizedHeading) {
      return res.status(400).json({
        success: false,
        message: "Heading is required",
      });
    }

    if (!rawArticleUrl) {
      return res.status(400).json({
        success: false,
        message: "Article link is required",
      });
    }

    let normalizedArticleUrl = "";
    try {
      const parsed = new URL(rawArticleUrl);
      if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
        throw new Error("invalid protocol");
      }
      normalizedArticleUrl = normalizeUrlForMatch(rawArticleUrl);
    } catch {
      return res.status(400).json({
        success: false,
        message: "Use a valid http(s) article link",
      });
    }

    let matchedArticle: Record<string, any> | null = null;

    if (articleId && articleId.trim().length > 0) {
      const byIdSnapshot = await articlesCollection
        .where("articleId", "==", articleId.trim())
        .limit(1)
        .get();
      if (!byIdSnapshot.empty) {
        matchedArticle = byIdSnapshot.docs[0].data() as Record<string, any>;
      }
    }

    if (!matchedArticle) {
      const byExactLink = await articlesCollection
        .where("link", "==", normalizedArticleUrl)
        .limit(1)
        .get();
      if (!byExactLink.empty) {
        matchedArticle = byExactLink.docs[0].data() as Record<string, any>;
      }
    }

    if (!matchedArticle) {
      const recentArticlesSnapshot = await articlesCollection
        .orderBy("pubDate", "desc")
        .limit(700)
        .get();

      for (const doc of recentArticlesSnapshot.docs) {
        const row = doc.data() as Record<string, any>;
        const linkValue = typeof row.link === "string" ? row.link : "";
        if (!linkValue) continue;
        try {
          if (normalizeUrlForMatch(linkValue) == normalizedArticleUrl) {
            matchedArticle = row;
            break;
          }
        } catch {
          // Ignore malformed stored links.
        }
      }
    }

    const isExternalNewsLike = looksLikeNewsLink(normalizedArticleUrl);
    if (!matchedArticle && !isExternalNewsLike) {
      return res.status(400).json({
        success: false,
        message: "Link must be a valid news article URL",
      });
    }

    const profileDoc = await userProfilesCollection.doc(userId).get();
    const profile = profileDoc.exists ? (profileDoc.data() as UserProfile) : null;
    const resolvedArticleId =
      typeof matchedArticle?.articleId === "string" && matchedArticle.articleId.length > 0
        ? matchedArticle.articleId
        : articleId || null;
    const resolvedArticleTitle =
      typeof matchedArticle?.title === "string" && matchedArticle.title.length > 0
        ? matchedArticle.title
        : deriveTitleFromUrl(normalizedArticleUrl);
    const resolvedArticleImageUrl =
      typeof matchedArticle?.imageUrl === "string" && matchedArticle.imageUrl.length > 0
        ? matchedArticle.imageUrl
        : articleImageUrl || null;
    const resolvedArticleUrl =
      typeof matchedArticle?.link === "string" && matchedArticle.link.length > 0
        ? matchedArticle.link
        : normalizedArticleUrl;

    const postData: NetworkPost = {
      userId,
      username: profile?.username || "reader",
      userAvatarUrl: profile?.avatarUrl || null,
      heading: normalizedHeading,
      text: normalizedText,
      articleId: resolvedArticleId,
      articleTitle: resolvedArticleTitle,
      articleImageUrl: resolvedArticleImageUrl,
      articleUrl: resolvedArticleUrl,
      shareCount: 1,
      likeCount: 0,
      commentCount: 0,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    };

    const postRef = await postsCollection.add(postData);
    const convertedPost = convertTimestampsToISO(postData);

    return res.status(201).json({
      success: true,
      message: "Post created",
      post: {
        id: postRef.id,
        ...convertedPost,
        isLiked: false,
      },
    });
  } catch (error) {
    console.error("Error creating network post:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to create post",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get network posts for user feed (following + self)
 * GET /api/v1/social/posts/:userId?limit=20&cursor=<millis>
 */
export const getNetworkPosts = async (req: Request, res: Response) => {
  try {
    const userIdParam = req.params.userId;
    const userId = Array.isArray(userIdParam) ? userIdParam[0] : userIdParam;
    const limitQuery = getQueryString(req.query.limit as string | string[] | undefined) || "20";
    const cursorQuery = getQueryString(req.query.cursor as string | string[] | undefined);

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const parsedLimit = parseInt(limitQuery, 10);
    const limitNum = Number.isFinite(parsedLimit) ? Math.min(Math.max(parsedLimit, 1), 50) : 20;

    const followingQuery = await userFollowsCollection.where("followerId", "==", userId).get();
    const followingIds = followingQuery.docs.map((doc) => doc.data().followingId);
    followingIds.push(userId);

    if (followingIds.length === 0) {
      return res.status(200).json({
        success: true,
        posts: [],
        count: 0,
        hasMore: false,
        nextCursor: null,
      });
    }

    const chunks = chunkArray(followingIds, 10);
    const posts: Array<Record<string, any>> = [];
    const cursorMillis = cursorQuery ? parseInt(cursorQuery, 10) : NaN;
    const hasCursor = Number.isFinite(cursorMillis) && cursorMillis > 0;

    const isMissingIndexError = (error: any): boolean => {
      const details = String(error?.details || error?.message || "");
      return error?.code === 9 || details.includes("requires an index");
    };

    for (const chunk of chunks) {
      try {
        let query = postsCollection
          .where("userId", "in", chunk)
          .orderBy("createdAt", "desc")
          .limit(limitNum + 5);

        if (hasCursor) {
          query = query.startAfter(Timestamp.fromMillis(cursorMillis));
        }

        const snap = await query.get();
        snap.docs.forEach((doc) => {
          posts.push({ id: doc.id, ...doc.data() });
        });
      } catch (queryError) {
        if (!isMissingIndexError(queryError)) {
          throw queryError;
        }
        const fallbackSnap = await postsCollection
          .where("userId", "in", chunk)
          .limit(Math.min(limitNum * 4, 100))
          .get();
        fallbackSnap.docs.forEach((doc) => {
          const row: Record<string, any> = { id: doc.id, ...(doc.data() as Record<string, any>) };
          if (hasCursor) {
            if (toMillis(row.createdAt) < cursorMillis) {
              posts.push(row);
            }
            return;
          }
          posts.push(row);
        });
      }
    }

    const sorted = posts.sort((a, b) => toMillis(b.createdAt) - toMillis(a.createdAt));
    const deduped = new Map<string, Record<string, any>>();
    sorted.forEach((item) => {
      if (!deduped.has(item.id as string)) {
        deduped.set(item.id as string, item);
      }
    });

    const all = Array.from(deduped.values());
    const page = all.slice(0, limitNum);
    const hasMore = all.length > page.length;
    const nextCursor = hasMore && page.length > 0 ? String(toMillis(page[page.length - 1].createdAt)) : null;

    const likedIds = new Set<string>();
    if (page.length > 0) {
      await Promise.all(
        page.map(async (post) => {
          try {
            const likeDoc = await postLikesCollection.doc(`${post.id}_${userId}`).get();
            if (likeDoc.exists) likedIds.add(post.id as string);
          } catch {
            // ignore like lookup errors
          }
        })
      );
    }

    const convertedPosts = page.map((post) => {
      const converted = convertTimestampsToISO(post);
      return {
        ...converted,
        isLiked: likedIds.has(post.id as string),
      };
    });

    setPrivateCache(res, 8);
    return res.status(200).json({
      success: true,
      posts: convertedPosts,
      count: convertedPosts.length,
      hasMore,
      nextCursor,
    });
  } catch (error) {
    console.error("Error getting network posts:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch posts",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Like a post
 * POST /api/v1/social/posts/:postId/like
 */
export const likeNetworkPost = async (req: Request, res: Response) => {
  try {
    const postId = getOptionalString(req.params.postId);
    const userId = getOptionalString(req.body?.userId || req.query?.userId);

    if (!postId || !userId) {
      return res.status(400).json({
        success: false,
        message: "postId and userId are required",
      });
    }

    const postRef = postsCollection.doc(postId);
    const postDoc = await postRef.get();
    if (!postDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Post not found",
      });
    }

    const likeRef = postLikesCollection.doc(`${postId}_${userId}`);
    const likeDoc = await likeRef.get();
    if (!likeDoc.exists) {
      await likeRef.set({
        postId,
        userId,
        createdAt: Timestamp.now(),
      });
      await postRef.update({
        likeCount: FieldValue.increment(1),
        updatedAt: Timestamp.now(),
      });
    }

    return res.status(200).json({
      success: true,
      message: "Post liked",
    });
  } catch (error) {
    console.error("Error liking post:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to like post",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Unlike a post
 * DELETE /api/v1/social/posts/:postId/like
 */
export const unlikeNetworkPost = async (req: Request, res: Response) => {
  try {
    const postId = getOptionalString(req.params.postId);
    const userId = getOptionalString(req.body?.userId || req.query?.userId);

    if (!postId || !userId) {
      return res.status(400).json({
        success: false,
        message: "postId and userId are required",
      });
    }

    const postRef = postsCollection.doc(postId);
    const postDoc = await postRef.get();
    if (!postDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Post not found",
      });
    }

    const likeRef = postLikesCollection.doc(`${postId}_${userId}`);
    const likeDoc = await likeRef.get();
    if (likeDoc.exists) {
      await likeRef.delete();
      await postRef.update({
        likeCount: FieldValue.increment(-1),
        updatedAt: Timestamp.now(),
      });
    }

    return res.status(200).json({
      success: true,
      message: "Post unliked",
    });
  } catch (error) {
    console.error("Error unliking post:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to unlike post",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Comment on a post
 * POST /api/v1/social/posts/:postId/comments
 */
export const commentOnNetworkPost = async (req: Request, res: Response) => {
  try {
    const postId = getOptionalString(req.params.postId);
    const { userId, text } = req.body as { userId?: string; text?: string };

    if (!postId || !userId || !text || text.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: "postId, userId and text are required",
      });
    }

    const postRef = postsCollection.doc(postId);
    const postDoc = await postRef.get();
    if (!postDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Post not found",
      });
    }

    const profileDoc = await userProfilesCollection.doc(userId).get();
    const profile = profileDoc.exists ? (profileDoc.data() as UserProfile) : null;

    const comment = {
      postId,
      userId,
      username: profile?.username || "reader",
      userAvatarUrl: profile?.avatarUrl || null,
      text: text.trim().slice(0, 300),
      createdAt: Timestamp.now(),
    };

    const commentRef = await postCommentsCollection.add(comment);
    await postRef.update({
      commentCount: FieldValue.increment(1),
      updatedAt: Timestamp.now(),
    });

    return res.status(201).json({
      success: true,
      message: "Comment added",
      comment: {
        id: commentRef.id,
        ...convertTimestampsToISO(comment),
      },
    });
  } catch (error) {
    console.error("Error commenting on post:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to comment on post",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get activity feed for a user
 * GET /api/v1/social/activity/:userId?limit=50
 */
export const getActivityFeed = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const { limit = "50" } = req.query;
    const limitNum = parseInt(limit as string) || 50;

    // Get users that current user follows
    const followingQuery = await userFollowsCollection
      .where("followerId", "==", userId)
      .get();

    const followingIds = followingQuery.docs.map((doc) => doc.data().followingId);

    // Include user's own activities
    followingIds.push(userId);

    if (followingIds.length === 0) {
      return res.status(200).json({
        success: true,
        activities: [],
        count: 0,
      });
    }

    // Fetch activities from followed users (Firestore 'in' query limits to 10 items)
    const activities: any[] = [];

    // Split into chunks of 10 for Firestore 'in' query limitation
    const chunks = [];
    for (let i = 0; i < followingIds.length; i += 10) {
      chunks.push(followingIds.slice(i, i + 10));
    }

    for (const chunk of chunks) {
      const activitiesQuery = await activityFeedCollection
        .where("userId", "in", chunk)
        .orderBy("timestamp", "desc")
        .limit(limitNum)
        .get();

      activitiesQuery.docs.forEach((doc) => {
        const activityData = doc.data();
        const convertedActivity = convertTimestampsToISO(activityData);
        activities.push({ id: doc.id, ...convertedActivity });
      });
    }

    // Sort all activities by timestamp and limit
    const sortedActivities = activities
      .sort((a, b) => {
        const aTime = a.timestamp.toDate ? a.timestamp.toDate().getTime() : new Date(a.timestamp).getTime();
        const bTime = b.timestamp.toDate ? b.timestamp.toDate().getTime() : new Date(b.timestamp).getTime();
        return bTime - aTime;
      })
      .slice(0, limitNum);

    setPrivateCache(res, 8);
    return res.status(200).json({
      success: true,
      activities: sortedActivities,
      count: sortedActivities.length,
    });
  } catch (error) {
    console.error("Error fetching activity feed:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch activity feed",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get deduplicated network highlights (shared articles)
 * GET /api/v1/social/highlights/:userId?limit=20&cursor=0
 */
export const getNetworkHighlights = async (req: Request, res: Response) => {
  try {
    const userIdParam = req.params.userId;
    const userId = Array.isArray(userIdParam) ? userIdParam[0] : userIdParam;
    const limitQuery = getQueryString(req.query.limit as string | string[] | undefined) || "20";
    const cursorQuery = getQueryString(req.query.cursor as string | string[] | undefined) || "0";

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const limitParsed = parseInt(limitQuery, 10);
    const offsetParsed = parseInt(cursorQuery, 10);
    const limitNum = Number.isFinite(limitParsed) ? Math.min(Math.max(limitParsed, 1), 100) : 20;
    const offsetNum = Number.isFinite(offsetParsed) ? Math.max(offsetParsed, 0) : 0;

    const followingQuery = await userFollowsCollection.where("followerId", "==", userId).get();
    const followingIds = followingQuery.docs.map((doc) => doc.data().followingId);
    followingIds.push(userId);

    if (followingIds.length === 0) {
      return res.status(200).json({
        success: true,
        highlights: [],
        count: 0,
        hasMore: false,
        nextCursor: null,
      });
    }

    const chunks = [];
    for (let i = 0; i < followingIds.length; i += 10) {
      chunks.push(followingIds.slice(i, i + 10));
    }

    const shareActivities: Array<Record<string, any>> = [];
    for (const chunk of chunks) {
      const activitiesQuery = await activityFeedCollection
        .where("userId", "in", chunk)
        .orderBy("timestamp", "desc")
        .limit(120)
        .get();

      activitiesQuery.docs.forEach((doc) => {
        const raw = doc.data() as Record<string, any>;
        if (raw.activityType !== "shareArticle") return;
        shareActivities.push({ id: doc.id, ...raw });
      });
    }

    const sortedShares = shareActivities.sort(
      (a, b) => toMillis(b.timestamp) - toMillis(a.timestamp)
    );

    const grouped = new Map<string, Record<string, any>>();

    sortedShares.forEach((activity) => {
      const articleId = activity.articleId as string | undefined;
      const articleTitle = activity.articleTitle as string | undefined;
      const articleSourceName = activity.articleSourceName as string | undefined;
      const dedupeKey = articleId || `${articleTitle ?? ""}|${articleSourceName ?? ""}`;
      if (!dedupeKey || dedupeKey == "|") return;

      const username = activity.username as string | undefined;
      const existing = grouped.get(dedupeKey);
      if (!existing) {
        grouped.set(dedupeKey, {
          dedupeKey,
          articleId: articleId || null,
          articleTitle: articleTitle || "Shared article",
          articleSourceName: articleSourceName || null,
          articleImageUrl: activity.articleImageUrl || null,
          articleUrl: activity.articleUrl || null,
          articleDescription: activity.articleDescription || null,
          latestSharedAt: convertTimestampsToISO({ timestamp: activity.timestamp }).timestamp,
          shareCount: 1,
          sharers: username ? [username] : [],
        });
      } else {
        existing.shareCount = (existing.shareCount as number) + 1;
        if (username && !(existing.sharers as string[]).includes(username)) {
          (existing.sharers as string[]).push(username);
        }
      }
    });

    const allHighlights = Array.from(grouped.values()).sort((a, b) => {
      if ((b.shareCount as number) !== (a.shareCount as number)) {
        return (b.shareCount as number) - (a.shareCount as number);
      }
      return toMillis(b.latestSharedAt) - toMillis(a.latestSharedAt);
    });

    const page: Array<Record<string, any>> = allHighlights
      .slice(offsetNum, offsetNum + limitNum)
      .map((item) => ({
        ...(item as Record<string, any>),
        sharers: (((item as Record<string, any>).sharers as string[]) || []).slice(0, 3),
      }));

    const articleIds = page
      .map((item) => item.articleId)
      .filter((id): id is string => typeof id === "string" && id.length > 0);
    const engagementByArticleId = new Map<string, { likeCount: number; commentCount: number }>();
    await Promise.all(
      articleIds.map(async (articleId) => {
        try {
          const engagementDoc = await articleEngagementCollection.doc(articleId).get();
          if (!engagementDoc.exists) return;
          const data = engagementDoc.data() as Record<string, any>;
          engagementByArticleId.set(articleId, {
            likeCount: typeof data.likeCount === "number" ? data.likeCount : 0,
            commentCount: typeof data.commentCount === "number" ? data.commentCount : 0,
          });
        } catch {
          engagementByArticleId.set(articleId, { likeCount: 0, commentCount: 0 });
        }
      })
    );

    const enrichedPage = page.map((item: Record<string, any>) => {
      const articleId = item.articleId as string | null;
      const engagement =
        articleId && engagementByArticleId.has(articleId)
          ? engagementByArticleId.get(articleId)
          : null;
      return {
        ...item,
        likeCount: engagement?.likeCount ?? 0,
        commentCount: engagement?.commentCount ?? 0,
      };
    });
    const hasMore = offsetNum + page.length < allHighlights.length;
    const nextCursor = hasMore ? String(offsetNum + page.length) : null;

    setPrivateCache(res, 8);
    return res.status(200).json({
      success: true,
      highlights: enrichedPage,
      count: enrichedPage.length,
      hasMore,
      nextCursor,
    });
  } catch (error) {
    console.error("Error fetching network highlights:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch network highlights",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
