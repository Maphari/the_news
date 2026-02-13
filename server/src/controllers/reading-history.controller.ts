import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import { Timestamp } from "firebase-admin/firestore";

const readingHistoryCollection = db.collection("readingHistory");

const toValidMillis = (value: unknown): number | null => {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.trunc(value);
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const numeric = Number(value);
    if (Number.isFinite(numeric)) {
      return Math.trunc(numeric);
    }
    const parsed = Date.parse(value);
    if (!Number.isNaN(parsed)) {
      return Math.trunc(parsed);
    }
  }
  return null;
};

/**
 * Get reading history for a user
 * GET /api/v1/user/reading-history/:userId
 */
export const getReadingHistory = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const limit = parseInt(req.query.limit as string) || 1000;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    // Get reading history entries for this user
    let query = readingHistoryCollection
      .where("userId", "==", userId)
      .orderBy("readAt", "desc");

    if (limit > 0) {
      query = query.limit(limit);
    }

    const snapshot = await query.get();

    const entries = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        articleId: data.articleId,
        articleTitle: data.articleTitle,
        readAt: data.readAt?.toMillis() || Date.now(),
        readDuration: data.readDuration || 0,
      };
    });

    return res.status(200).json({
      success: true,
      entries,
      total: entries.length,
    });
  } catch (error) {
    console.error("Error fetching reading history:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch reading history",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Add reading history entries (batch)
 * POST /api/v1/user/reading-history
 */
export const addReadingHistory = async (req: Request, res: Response) => {
  try {
    const { userId, entries } = req.body;

    if (!userId || !entries || !Array.isArray(entries)) {
      return res.status(400).json({
        success: false,
        message: "userId and entries array are required",
      });
    }

    // Add each entry to Firestore
    const batch = db.batch();
    let addedCount = 0;

    for (const entry of entries) {
      if (!entry.articleId || !entry.articleTitle) {
        continue; // Skip invalid entries
      }

      const docRef = readingHistoryCollection.doc();
      const readAtMillis = toValidMillis(entry.readAt);
      batch.set(docRef, {
        userId,
        articleId: entry.articleId,
        articleTitle: entry.articleTitle,
        readAt: readAtMillis != null ? Timestamp.fromMillis(readAtMillis) : Timestamp.now(),
        readDuration: entry.readDuration || 0,
        createdAt: Timestamp.now(),
      });

      addedCount++;
    }

    await batch.commit();

    return res.status(201).json({
      success: true,
      message: "Reading history entries added successfully",
      entriesAdded: addedCount,
    });
  } catch (error) {
    console.error("Error adding reading history:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to add reading history",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get reading analytics for a user
 * GET /api/v1/user/analytics/:userId
 */
export const getReadingAnalytics = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const days = parseInt(req.query.days as string) || 30;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    // Calculate date range
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    // Get reading history within date range
    const snapshot = await readingHistoryCollection
      .where("userId", "==", userId)
      .where("readAt", ">=", Timestamp.fromDate(startDate))
      .where("readAt", "<=", Timestamp.fromDate(endDate))
      .get();

    // Calculate analytics
    let totalArticlesRead = 0;
    let totalReadingTimeSeconds = 0;
    const articlesByDate: { [date: string]: number } = {};

    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      totalArticlesRead++;
      totalReadingTimeSeconds += data.readDuration || 0;

      // Group by date
      const date = new Date(data.readAt.toMillis()).toISOString().split("T")[0];
      articlesByDate[date] = (articlesByDate[date] || 0) + 1;
    });

    // Find most active day
    let mostActiveDay = "";
    let maxArticles = 0;
    for (const [date, count] of Object.entries(articlesByDate)) {
      if (count > maxArticles) {
        maxArticles = count;
        mostActiveDay = date;
      }
    }

    // Calculate recent reading (last 7 and 30 days)
    const last7Days = new Date();
    last7Days.setDate(last7Days.getDate() - 7);
    const last7DaysCount = snapshot.docs.filter(
      (doc) => doc.data().readAt.toMillis() >= last7Days.getTime()
    ).length;

    const analytics = {
      totalArticlesRead,
      totalReadingTimeMinutes: Math.round(totalReadingTimeSeconds / 60),
      articlesByDate,
      mostActiveDay,
      maxArticlesInDay: maxArticles,
      last7DaysCount,
      last30DaysCount: totalArticlesRead,
      averageArticlesPerDay: totalArticlesRead / days,
    };

    return res.status(200).json({
      success: true,
      analytics,
    });
  } catch (error) {
    console.error("Error fetching reading analytics:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch reading analytics",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Clear reading history for a user
 * DELETE /api/v1/user/reading-history/:userId
 */
export const clearReadingHistory = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    // Get all reading history entries for this user
    const snapshot = await readingHistoryCollection
      .where("userId", "==", userId)
      .get();

    // Delete in batches (Firestore allows max 500 operations per batch)
    const batch = db.batch();
    let count = 0;

    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      count++;
    });

    await batch.commit();

    return res.status(200).json({
      success: true,
      message: "Reading history cleared successfully",
      deletedCount: count,
    });
  } catch (error) {
    console.error("Error clearing reading history:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to clear reading history",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
