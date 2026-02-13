import { Request, Response } from "express";
import { admin, db } from "../config/firebase.connection";

type WellnessSettings = {
  calmModeEnabled: boolean;
  breakReminderEnabled: boolean;
  breakIntervalMinutes: number;
  intensityLevel: "low" | "balanced" | "high";
  moodTrackingEnabled: boolean;
  updatedAt: FirebaseFirestore.Timestamp;
};

const defaultWellnessSettings = (): WellnessSettings => ({
  calmModeEnabled: false,
  breakReminderEnabled: false,
  breakIntervalMinutes: 30,
  intensityLevel: "balanced",
  moodTrackingEnabled: false,
  updatedAt: admin.firestore.Timestamp.now(),
});

function asString(value: unknown): string {
  if (typeof value === "string") return value.trim();
  if (Array.isArray(value) && value.length > 0 && typeof value[0] === "string") {
    return value[0].trim();
  }
  return "";
}

function toDate(value: unknown): Date {
  if (!value) return new Date(0);
  if (value instanceof Date) return value;
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? new Date(0) : parsed;
  }
  if (
    typeof value === "object" &&
    value !== null &&
    "toDate" in value &&
    typeof (value as { toDate: () => Date }).toDate === "function"
  ) {
    return (value as { toDate: () => Date }).toDate();
  }
  if (
    typeof value === "object" &&
    value !== null &&
    "_seconds" in value &&
    typeof (value as { _seconds: unknown })._seconds === "number"
  ) {
    return new Date(((value as { _seconds: number })._seconds ?? 0) * 1000);
  }
  return new Date(0);
}

function dayKey(date: Date): string {
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, "0")}-${String(
    date.getUTCDate()
  ).padStart(2, "0")}`;
}

function computeStreakFromDates(dates: Date[]): number {
  if (dates.length === 0) return 0;
  const uniqueDays = Array.from(new Set(dates.map((date) => dayKey(date))))
    .map((key) => new Date(`${key}T00:00:00.000Z`))
    .sort((a, b) => b.getTime() - a.getTime());
  if (uniqueDays.length === 0) return 0;

  let streak = 1;
  let cursor = uniqueDays[0];
  for (let i = 1; i < uniqueDays.length; i += 1) {
    const next = uniqueDays[i];
    const diffDays = Math.round((cursor.getTime() - next.getTime()) / (24 * 60 * 60 * 1000));
    if (diffDays === 1) {
      streak += 1;
      cursor = next;
      continue;
    }
    if (diffDays > 1) {
      break;
    }
  }
  return streak;
}

export async function getWellnessSettings(req: Request, res: Response) {
  try {
    const userId = asString(req.params.userId);
    if (!userId) {
      return res.status(400).json({ success: false, message: "userId is required" });
    }

    const ref = db.collection("wellnessSettings").doc(userId);
    const snapshot = await ref.get();
    if (!snapshot.exists) {
      const settings = defaultWellnessSettings();
      await ref.set(settings, { merge: true });
      return res.status(200).json({ success: true, settings });
    }

    return res.status(200).json({ success: true, settings: snapshot.data() });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to load wellness settings",
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

export async function updateWellnessSettings(req: Request, res: Response) {
  try {
    const userId = asString(req.params.userId);
    if (!userId) {
      return res.status(400).json({ success: false, message: "userId is required" });
    }

    const payload = req.body as Partial<WellnessSettings>;
    const updates: Partial<WellnessSettings> = {
      ...payload,
      updatedAt: admin.firestore.Timestamp.now(),
    };

    const ref = db.collection("wellnessSettings").doc(userId);
    await ref.set(updates, { merge: true });
    const updated = await ref.get();

    return res.status(200).json({ success: true, settings: updated.data() });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update wellness settings",
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

export async function getWellnessReport(req: Request, res: Response) {
  try {
    const userId = asString(req.params.userId);
    if (!userId) {
      return res.status(400).json({ success: false, message: "userId is required" });
    }

    const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    );

    const [historySnapshot, settingsSnapshot] = await Promise.all([
      db
        .collection("readingHistory")
        .where("userId", "==", userId)
        .where("createdAt", ">=", sevenDaysAgo)
        .get(),
      db.collection("wellnessSettings").doc(userId).get(),
    ]);

    const sessions = historySnapshot.docs.map((doc) => doc.data());
    const totalReadMinutes = sessions.reduce((sum, item) => {
      const value = Number(item.readingTimeMinutes ?? item.readingTime ?? 0);
      return sum + (Number.isFinite(value) ? value : 0);
    }, 0);
    const readingSessions = sessions.length;
    const averageSessionMinutes =
      readingSessions > 0 ? Math.round((totalReadMinutes / readingSessions) * 10) / 10 : 0;

    return res.status(200).json({
      success: true,
      report: {
        userId,
        periodDays: 7,
        readingSessions,
        totalReadMinutes,
        averageSessionMinutes,
        settings: settingsSnapshot.exists
          ? settingsSnapshot.data()
          : defaultWellnessSettings(),
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to build wellness report",
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

export async function getArticlePerspectives(req: Request, res: Response) {
  try {
    const articleId = asString(req.params.articleId);
    if (!articleId) {
      return res.status(400).json({ success: false, message: "articleId is required" });
    }

    const baseSnapshot = await db
      .collection("articles")
      .where("articleId", "==", articleId)
      .limit(1)
      .get();

    if (baseSnapshot.empty) {
      return res.status(404).json({ success: false, message: "Article not found" });
    }

    const base = baseSnapshot.docs[0].data() as Record<string, unknown>;
    const category = asString(base.category);
    const sourceName = asString(base.sourceName);

    const relatedSnapshot = await db
      .collection("articles")
      .where("category", "==", category || "general")
      .orderBy("pubDate", "desc")
      .limit(12)
      .get();

    const perspectives = relatedSnapshot.docs
      .map((doc) => doc.data() as Record<string, unknown>)
      .filter((item) => asString(item.articleId) !== articleId)
      .slice(0, 6)
      .map((item) => ({
        articleId: asString(item.articleId),
        title: asString(item.title),
        sourceName: asString(item.sourceName),
        biasDirection: asString(item.biasDirection) || "center",
        sentiment: asString(item.sentiment) || "neutral",
        isSameSource: asString(item.sourceName) === sourceName,
      }));

    return res.status(200).json({
      success: true,
      articleId,
      perspectives,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to load perspectives",
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

export async function getOfflineManifest(req: Request, res: Response) {
  try {
    const userId = asString(req.params.userId);
    if (!userId) {
      return res.status(400).json({ success: false, message: "userId is required" });
    }

    const savedSnapshot = await db
      .collection("savedArticles")
      .where("userId", "==", userId)
      .limit(100)
      .get();

    const articleIds = savedSnapshot.docs
      .map((doc) => asString(doc.data().articleId))
      .filter((id) => id.length > 0)
      .slice(0, 50);

    const chunks: string[][] = [];
    for (let i = 0; i < articleIds.length; i += 10) {
      chunks.push(articleIds.slice(i, i + 10));
    }

    const articles: Record<string, unknown>[] = [];
    for (const chunk of chunks) {
      const snapshot = await db
        .collection("articles")
        .where("articleId", "in", chunk)
        .get();
      for (const doc of snapshot.docs) {
        articles.push(doc.data() as Record<string, unknown>);
      }
    }

    const manifest = articles.map((item) => ({
      articleId: asString(item.articleId),
      title: asString(item.title),
      sourceName: asString(item.sourceName),
      pubDate: item.pubDate ?? null,
      contentHash: asString(item.contentHash) || null,
    }));

    return res.status(200).json({
      success: true,
      manifest,
      generatedAt: new Date().toISOString(),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to generate offline manifest",
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

export async function createTtsPresign(req: Request, res: Response) {
  try {
    const body = req.body as {
      userId?: string;
      articleId?: string;
      voice?: string;
      language?: string;
    };

    const userId = asString(body.userId);
    const articleId = asString(body.articleId);
    if (!userId || !articleId) {
      return res.status(400).json({
        success: false,
        message: "userId and articleId are required",
      });
    }

    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    const ttsRequestId = `${userId}_${articleId}_${Date.now()}`;

    return res.status(200).json({
      success: true,
      ttsRequestId,
      expiresAt,
      voice: asString(body.voice) || "default",
      language: asString(body.language) || "en",
      uploadUrl: null,
      streamUrl: null,
      message: "Presign generated. Integrate storage provider URL signing next.",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to generate TTS presign payload",
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

export async function getFeatureAggregate(req: Request, res: Response) {
  try {
    const userId = asString(req.params.userId);
    const surface = asString(req.query.surface) || "home";
    if (!userId) {
      return res.status(400).json({ success: false, message: "userId is required" });
    }

    const [topStoriesSnapshot, trendingSnapshot, digestSnapshot] = await Promise.all([
      db.collection("articles").orderBy("pubDate", "desc").limit(12).get(),
      db.collection("articles").orderBy("createdAt", "desc").limit(12).get(),
      db.collection("digests").where("userId", "==", userId).limit(5).get(),
    ]);

    const topStories = topStoriesSnapshot.docs.slice(0, 8).map((doc) => {
      const item = doc.data() as Record<string, unknown>;
      return {
        articleId: asString(item.articleId),
        title: asString(item.title),
        sourceName: asString(item.sourceName),
        category: asString(item.category) || "general",
      };
    });

    const trendingTopics = trendingSnapshot.docs
      .map((doc) => asString(doc.data().category))
      .filter((value) => value.length > 0)
      .reduce<Record<string, number>>((acc, category) => {
        acc[category] = (acc[category] || 0) + 1;
        return acc;
      }, {});

    const digestCards = digestSnapshot.docs.map((doc) => {
      const item = doc.data() as Record<string, unknown>;
      return {
        digestId: asString(item.digestId),
        title: asString(item.title),
        createdAt: item.createdAt ?? null,
      };
    });

    return res.status(200).json({
      success: true,
      surface,
      userId,
      aggregate: {
        topStories,
        trendingTopics,
        digestCards,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to load aggregate payload",
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

export async function getHomeViewModel(req: Request, res: Response) {
  try {
    const userId = asString(req.params.userId);
    if (!userId) {
      return res.status(400).json({ success: false, message: "userId is required" });
    }

    const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    );

    const [unreadSnapshot, readingSnapshot, wellnessSnapshot] = await Promise.all([
      db
        .collection("notificationHistory")
        .where("userId", "==", userId)
        .where("isRead", "==", false)
        .limit(200)
        .get(),
      db
        .collection("readingHistory")
        .where("userId", "==", userId)
        .orderBy("createdAt", "desc")
        .limit(120)
        .get(),
      db.collection("wellnessSettings").doc(userId).get(),
    ]);

    const readingDates = readingSnapshot.docs.map((doc) => toDate(doc.data().createdAt));
    const streakCount = computeStreakFromDates(readingDates);
    const last7Count = readingSnapshot.docs.filter((doc) => {
      const createdAt = doc.data().createdAt;
      const createdDate = toDate(createdAt);
      return createdDate.getTime() >= sevenDaysAgo.toDate().getTime();
    }).length;
    const wellness =
      (wellnessSnapshot.exists ? wellnessSnapshot.data() : null) ?? defaultWellnessSettings();

    return res.status(200).json({
      success: true,
      userId,
      generatedAt: new Date().toISOString(),
      header: {
        unreadCount: unreadSnapshot.size,
        streakCount,
        last7DaysReadCount: last7Count,
        calmModeEnabled: wellness.calmModeEnabled === true,
        dailyReadingLimit: 20,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to build home view model",
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

export async function getMySpaceViewModel(req: Request, res: Response) {
  try {
    const userId = asString(req.params.userId);
    const listsLimit = Math.min(Math.max(parseInt(asString(req.query.listsLimit) || "3", 10) || 3, 1), 6);
    const publishersLimit = Math.min(
      Math.max(parseInt(asString(req.query.publishersLimit) || "10", 10) || 10, 3),
      20
    );
    if (!userId) {
      return res.status(400).json({ success: false, message: "userId is required" });
    }

    const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    );

    const [
      profileDoc,
      followersSnap,
      followingSnap,
      postsSnap,
      listsSnap,
      sharesSnap,
      followedPublishersSnap,
      recentListsSnap,
      readingHistorySnap,
    ] = await Promise.all([
      db.collection("userProfiles").doc(userId).get(),
      db.collection("userFollows").where("followingId", "==", userId).get(),
      db.collection("userFollows").where("followerId", "==", userId).get(),
      db.collection("socialPosts").where("userId", "==", userId).get(),
      db.collection("readingLists").where("ownerId", "==", userId).get(),
      db
        .collection("activityFeed")
        .where("userId", "==", userId)
        .where("activityType", "==", "shareArticle")
        .get(),
      db.collection("followedPublishers").where("userId", "==", userId).get(),
      db
        .collection("readingLists")
        .where("ownerId", "==", userId)
        .orderBy("updatedAt", "desc")
        .limit(listsLimit)
        .get(),
      db
        .collection("readingHistory")
        .where("userId", "==", userId)
        .orderBy("createdAt", "desc")
        .limit(160)
        .get(),
    ]);

    const followedPublishers = followedPublishersSnap.docs
      .map((doc) => asString(doc.data().publisherName))
      .filter((name) => name.length > 0)
      .slice(0, publishersLimit);
    const readingDates = readingHistorySnap.docs.map((doc) => toDate(doc.data().createdAt));
    const streakCount = computeStreakFromDates(readingDates);
    const last7DaysCount = readingHistorySnap.docs.filter((doc) => {
      const createdAt = toDate(doc.data().createdAt);
      return createdAt.getTime() >= sevenDaysAgo.toDate().getTime();
    }).length;

    const profileData = (profileDoc.exists ? profileDoc.data() : null) as
      | Record<string, unknown>
      | null;
    const profileTopics = Array.isArray(profileData?.interests)
      ? (profileData?.interests as unknown[])
          .map((item) => asString(item))
          .filter((item) => item.length > 0)
      : [];

    const recentLists = recentListsSnap.docs.map((doc) => {
      const row = doc.data() as Record<string, unknown>;
      const articleIds = Array.isArray(row.articleIds)
        ? (row.articleIds as unknown[]).map((id) => asString(id)).filter((id) => id.length > 0)
        : [];
      return {
        id: doc.id,
        name: asString(row.name) || "Untitled List",
        description: asString(row.description) || null,
        ownerId: asString(row.ownerId) || userId,
        ownerName: asString(row.ownerName) || asString(profileData?.displayName) || "You",
        visibility: asString(row.visibility) || "public",
        articleIds,
        collaboratorIds: Array.isArray(row.collaboratorIds)
          ? (row.collaboratorIds as unknown[])
              .map((id) => asString(id))
              .filter((id) => id.length > 0)
          : [],
        createdAt: toDate(row.createdAt).toISOString(),
        updatedAt: toDate(row.updatedAt).toISOString(),
        coverImageUrl: asString(row.coverImageUrl) || null,
        tags: Array.isArray(row.tags)
          ? (row.tags as unknown[]).map((tag) => asString(tag)).filter((tag) => tag.length > 0)
          : [],
        viewCount: Number(row.viewCount ?? 0) || 0,
        saveCount: Number(row.saveCount ?? 0) || 0,
      };
    });

    return res.status(200).json({
      success: true,
      userId,
      generatedAt: new Date().toISOString(),
      summary: {
        counts: {
          followers: followersSnap.size,
          following: followingSnap.size,
          posts: postsSnap.size,
          shared: sharesSnap.size,
          readingLists: listsSnap.size,
          followedPublishers: followedPublishersSnap.size,
          networkHighlights: 0,
        },
      },
      insights: {
        stats: {
          last7DaysCount,
          averageArticlesPerDay:
            Math.round(((last7DaysCount / 7) * 10 + Number.EPSILON)) / 10,
        },
        streak: {
          currentDays: streakCount,
        },
        favorites: {
          topics: profileTopics.slice(0, 5),
          publishers: followedPublishers.slice(0, 5),
        },
      },
      followedPublishers,
      recentLists,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to build my space view model",
      error: error instanceof Error ? error.message : String(error),
    });
  }
}
