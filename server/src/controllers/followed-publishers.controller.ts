import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import {
  FollowedPublisher,
  FollowPublisherRequest,
  UnfollowPublisherRequest,
} from "../models/followed-publisher.model";
import { Timestamp } from "firebase-admin/firestore";

const followedPublishersCollection = db.collection("followedPublishers");

const getQueryString = (value: string | string[] | undefined): string | undefined => {
  if (Array.isArray(value)) return value[0];
  return value;
};

const sortFollowedDocs = (docs: any[]): any[] => {
  return [...docs].sort((a, b) => {
    const aFollowedAt = (a.data() as FollowedPublisher).followedAt as any;
    const bFollowedAt = (b.data() as FollowedPublisher).followedAt as any;
    const aMillis = aFollowedAt?.toMillis ? aFollowedAt.toMillis() : 0;
    const bMillis = bFollowedAt?.toMillis ? bFollowedAt.toMillis() : 0;
    return bMillis - aMillis;
  });
};

/**
 * Get all publishers followed by a user
 * GET /api/v1/followed-publishers/:userId
 */
export const getFollowedPublishers = async (req: Request, res: Response) => {
  try {
    const userIdParam = req.params.userId;
    const userId = Array.isArray(userIdParam) ? userIdParam[0] : userIdParam;
    const limitQuery = getQueryString(req.query.limit as string | string[] | undefined);
    const cursorQuery = getQueryString(req.query.cursor as string | string[] | undefined);

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const parsedLimit = limitQuery ? parseInt(limitQuery, 10) : NaN;
    const hasPagination = Number.isFinite(parsedLimit) && parsedLimit > 0;
    const pageLimit = hasPagination ? Math.min(Math.max(parsedLimit, 1), 100) : null;

    let followedDocs;
    let usedOffsetCursor = false;
    if (pageLimit != null) {
      try {
        let query = followedPublishersCollection
          .where("userId", "==", userId)
          .orderBy("followedAt", "desc")
          .limit(pageLimit);
        const cursorMillis = cursorQuery ? parseInt(cursorQuery, 10) : NaN;
        if (Number.isFinite(cursorMillis) && cursorMillis > 0) {
          query = query.startAfter(Timestamp.fromMillis(cursorMillis));
        }
        followedDocs = (await query.get()).docs;
      } catch (pagedQueryError) {
        // Fallback when Firestore index/order is unavailable in an environment.
        const allDocs = (
          await followedPublishersCollection.where("userId", "==", userId).get()
        ).docs;
        const sortedAllDocs = sortFollowedDocs(allDocs);
        const offset = cursorQuery ? parseInt(cursorQuery, 10) : 0;
        const safeOffset = Number.isFinite(offset) ? Math.max(offset, 0) : 0;
        followedDocs = sortedAllDocs.slice(safeOffset, safeOffset + pageLimit);
        usedOffsetCursor = true;
      }
    } else {
      followedDocs = sortFollowedDocs(
        (await followedPublishersCollection.where("userId", "==", userId).get()).docs
      );
    }

    const publishers: string[] = [];
    followedDocs.forEach((doc) => {
      const data = doc.data() as FollowedPublisher;
      publishers.push(data.publisherName);
    });

    let hasMore = false;
    let nextCursor: string | null = null;
    if (pageLimit != null) {
      hasMore = followedDocs.length === pageLimit;
      if (hasMore) {
        if (usedOffsetCursor) {
          const offset = cursorQuery ? parseInt(cursorQuery, 10) : 0;
          const safeOffset = Number.isFinite(offset) ? Math.max(offset, 0) : 0;
          nextCursor = String(safeOffset + followedDocs.length);
        } else {
          const lastFollowedAt = followedDocs[followedDocs.length - 1].data()
            .followedAt as any;
          if (lastFollowedAt && typeof lastFollowedAt.toMillis === "function") {
            nextCursor = String(lastFollowedAt.toMillis());
          } else {
            hasMore = false;
          }
        }
      }
    }

    return res.status(200).json({
      success: true,
      publishers,
      count: publishers.length,
      hasMore,
      nextCursor,
    });
  } catch (error) {
    console.error("Error getting followed publishers:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get followed publishers",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Follow a publisher
 * POST /api/v1/followed-publishers/follow
 */
export const followPublisher = async (req: Request, res: Response) => {
  try {
    const { userId, publisherName }: FollowPublisherRequest = req.body;

    if (!userId || !publisherName) {
      return res.status(400).json({
        success: false,
        message: "userId and publisherName are required",
      });
    }

    // Check if already following
    const existingFollow = await followedPublishersCollection
      .where("userId", "==", userId)
      .where("publisherName", "==", publisherName)
      .limit(1)
      .get();

    if (!existingFollow.empty) {
      return res.status(200).json({
        success: true,
        message: "Already following this publisher",
        alreadyFollowing: true,
      });
    }

    // Add follow
    const followedPublisher: FollowedPublisher = {
      userId,
      publisherName,
      followedAt: Timestamp.now(),
    };
    await followedPublishersCollection.add(followedPublisher);

    return res.status(201).json({
      success: true,
      message: "Publisher followed successfully",
    });
  } catch (error) {
    console.error("Error following publisher:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to follow publisher",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Unfollow a publisher
 * DELETE /api/v1/followed-publishers/follow
 */
export const unfollowPublisher = async (req: Request, res: Response) => {
  try {
    const { userId, publisherName }: UnfollowPublisherRequest = req.body;

    if (!userId || !publisherName) {
      return res.status(400).json({
        success: false,
        message: "userId and publisherName are required",
      });
    }

    // Find and delete the follow
    const followQuery = await followedPublishersCollection
      .where("userId", "==", userId)
      .where("publisherName", "==", publisherName)
      .limit(1)
      .get();

    if (followQuery.empty) {
      return res.status(404).json({
        success: false,
        message: "Follow not found",
      });
    }

    // Delete the follow
    await followQuery.docs[0].ref.delete();

    return res.status(200).json({
      success: true,
      message: "Publisher unfollowed successfully",
    });
  } catch (error) {
    console.error("Error unfollowing publisher:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to unfollow publisher",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Check if user is following a publisher
 * GET /api/v1/followed-publishers/check/:userId/:publisherName
 */
export const checkFollowStatus = async (req: Request, res: Response) => {
  try {
    const { userId, publisherName } = req.params;

    if (!userId || !publisherName) {
      return res.status(400).json({
        success: false,
        message: "userId and publisherName are required",
      });
    }

    const followQuery = await followedPublishersCollection
      .where("userId", "==", userId)
      .where("publisherName", "==", publisherName)
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
 * Get follow count for a publisher
 * GET /api/v1/followed-publishers/count/:publisherName
 */
export const getPublisherFollowCount = async (req: Request, res: Response) => {
  try {
    const { publisherName } = req.params;

    if (!publisherName) {
      return res.status(400).json({
        success: false,
        message: "publisherName is required",
      });
    }

    const followQuery = await followedPublishersCollection
      .where("publisherName", "==", publisherName)
      .get();

    return res.status(200).json({
      success: true,
      publisherName,
      count: followQuery.size,
    });
  } catch (error) {
    console.error("Error getting publisher follow count:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get follow count",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
