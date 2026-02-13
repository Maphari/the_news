import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import {
  ArticleEngagement,
  UserLike,
  UserShare,
  LikeArticleRequest,
  UnlikeArticleRequest,
  ShareArticleRequest,
  EngagementResponse,
} from "../models/engagement.model";
import { Timestamp } from "firebase-admin/firestore";
import { getOptionalString } from "../utils/request.utils";

const engagementCollection = db.collection("articleEngagement");
const likesCollection = db.collection("userLikes");
const sharesCollection = db.collection("userShares");
const userProfilesCollection = db.collection("userProfiles");
const articlesCollection = db.collection("articles");
const activityFeedCollection = db.collection("activityFeed");

/**
 * Get engagement data for an article
 * GET /api/v1/engagement/:articleId
 */
export const getEngagement = async (req: Request, res: Response) => {
  try {
    const articleId = getOptionalString(req.params.articleId);
    const userId = getOptionalString(req.query.userId);

    if (!articleId) {
      return res.status(400).json({
        success: false,
        message: "articleId is required",
      });
    }

    // Get engagement data
    const engagementDoc = await engagementCollection.doc(articleId).get();

    let engagement: ArticleEngagement;
    if (engagementDoc.exists) {
      engagement = engagementDoc.data() as ArticleEngagement;
    } else {
      // Create initial engagement record
      engagement = {
        articleId,
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      };
      await engagementCollection.doc(articleId).set(engagement);
    }

    // Check if user liked this article
    let isLiked = false;
    if (userId) {
      const likeQuery = await likesCollection
        .where("userId", "==", userId)
        .where("articleId", "==", articleId)
        .limit(1)
        .get();
      isLiked = !likeQuery.empty;
    }

    const response: EngagementResponse = {
      articleId: engagement.articleId,
      likeCount: engagement.likeCount,
      commentCount: engagement.commentCount,
      shareCount: engagement.shareCount,
      isLiked,
    };

    return res.status(200).json({
      success: true,
      engagement: response,
    });
  } catch (error) {
    console.error("Error getting engagement:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get engagement data",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Like an article
 * POST /api/v1/engagement/like
 */
export const likeArticle = async (req: Request, res: Response) => {
  try {
    const { userId, articleId }: LikeArticleRequest = req.body;

    if (!userId || !articleId) {
      return res.status(400).json({
        success: false,
        message: "userId and articleId are required",
      });
    }

    // Check if already liked
    const existingLike = await likesCollection
      .where("userId", "==", userId)
      .where("articleId", "==", articleId)
      .limit(1)
      .get();

    if (!existingLike.empty) {
      return res.status(200).json({
        success: true,
        message: "Article already liked",
        alreadyLiked: true,
      });
    }

    // Add like
    const userLike: UserLike = {
      userId,
      articleId,
      likedAt: Timestamp.now(),
    };
    await likesCollection.add(userLike);

    // Increment like count in engagement
    const engagementRef = engagementCollection.doc(articleId);
    const engagementDoc = await engagementRef.get();

    if (engagementDoc.exists) {
      await engagementRef.update({
        likeCount: (engagementDoc.data()?.likeCount || 0) + 1,
        updatedAt: Timestamp.now(),
      });
    } else {
      // Create initial engagement record
      await engagementRef.set({
        articleId,
        likeCount: 1,
        commentCount: 0,
        shareCount: 0,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });
    }

    return res.status(200).json({
      success: true,
      message: "Article liked successfully",
    });
  } catch (error) {
    console.error("Error liking article:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to like article",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Unlike an article
 * DELETE /api/v1/engagement/like
 */
export const unlikeArticle = async (req: Request, res: Response) => {
  try {
    const { userId, articleId }: UnlikeArticleRequest = req.body;

    if (!userId || !articleId) {
      return res.status(400).json({
        success: false,
        message: "userId and articleId are required",
      });
    }

    // Find and delete the like
    const likeQuery = await likesCollection
      .where("userId", "==", userId)
      .where("articleId", "==", articleId)
      .limit(1)
      .get();

    if (likeQuery.empty) {
      return res.status(404).json({
        success: false,
        message: "Like not found",
      });
    }

    // Delete the like
    await likeQuery.docs[0].ref.delete();

    // Decrement like count in engagement
    const engagementRef = engagementCollection.doc(articleId);
    const engagementDoc = await engagementRef.get();

    if (engagementDoc.exists) {
      const currentCount = engagementDoc.data()?.likeCount || 0;
      await engagementRef.update({
        likeCount: Math.max(0, currentCount - 1),
        updatedAt: Timestamp.now(),
      });
    }

    return res.status(200).json({
      success: true,
      message: "Article unliked successfully",
    });
  } catch (error) {
    console.error("Error unliking article:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to unlike article",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Share an article
 * POST /api/v1/engagement/share
 */
export const shareArticle = async (req: Request, res: Response) => {
  try {
    const {
      userId,
      articleId,
      platform,
      shareToFeed = true,
      forceReshare = false,
    }: ShareArticleRequest = req.body;

    if (!userId || !articleId) {
      return res.status(400).json({
        success: false,
        message: "userId and articleId are required",
      });
    }

    const existingShareQuery = await sharesCollection
      .where("userId", "==", userId)
      .where("articleId", "==", articleId)
      .limit(1)
      .get();
    const alreadySharedByUser = !existingShareQuery.empty;

    if (alreadySharedByUser && !forceReshare) {
      return res.status(200).json({
        success: false,
        alreadyShared: true,
        message: "You already shared this article",
      });
    }

    // Record the share
    const userShare: UserShare = {
      userId,
      articleId,
      platform: platform || "unknown",
      sharedAt: Timestamp.now(),
    };
    await sharesCollection.add(userShare);

    // Increment share count in engagement
    const engagementRef = engagementCollection.doc(articleId);
    const engagementDoc = await engagementRef.get();

    if (engagementDoc.exists) {
      await engagementRef.update({
        shareCount: (engagementDoc.data()?.shareCount || 0) + 1,
        updatedAt: Timestamp.now(),
      });
    } else {
      // Create initial engagement record
      await engagementRef.set({
        articleId,
        likeCount: 0,
        commentCount: 0,
        shareCount: 1,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });
    }

    // Create social activity feed entry for shared article
    if (shareToFeed) {
      try {
        const profileDoc = await userProfilesCollection.doc(userId).get();
        const profileData = profileDoc.exists ? (profileDoc.data() as any) : null;
        const showActivity = profileData?.privacySettings?.showActivity ?? true;
        if (showActivity) {
          let articleData: any | null = null;
          const articleSnap = await articlesCollection
            .where("articleId", "==", articleId)
            .limit(1)
            .get();
          if (!articleSnap.empty) {
            articleData = articleSnap.docs[0].data();
          }

          await activityFeedCollection.add({
            userId,
            username: profileData?.username || profileData?.displayName || userId,
            userAvatarUrl: profileData?.avatarUrl || null,
            activityType: "shareArticle",
            timestamp: Timestamp.now(),
            articleId,
            articleTitle: articleData?.title || "an article",
            articleSourceName: articleData?.sourceName || null,
            articleImageUrl: articleData?.imageUrl || null,
            articleUrl: articleData?.link || null,
            articleDescription: articleData?.description || null,
          });
        }
      } catch (activityError) {
        console.warn("⚠️ Failed to create share activity:", activityError);
      }
    }

    return res.status(200).json({
      success: true,
      alreadyShared: alreadySharedByUser,
      message: "Article shared successfully",
    });
  } catch (error) {
    console.error("Error sharing article:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to share article",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Update comment count (to be called when comments are added/removed)
 * PUT /api/v1/engagement/comments/:articleId
 */
export const updateCommentCount = async (req: Request, res: Response) => {
  try {
    const articleId = getOptionalString(req.params.articleId);
    const { increment } = req.body; // +1 or -1

    if (!articleId) {
      return res.status(400).json({
        success: false,
        message: "articleId is required",
      });
    }

    const engagementRef = engagementCollection.doc(articleId);
    const engagementDoc = await engagementRef.get();

    if (engagementDoc.exists) {
      const currentCount = engagementDoc.data()?.commentCount || 0;
      await engagementRef.update({
        commentCount: Math.max(0, currentCount + (increment || 1)),
        updatedAt: Timestamp.now(),
      });
    } else {
      // Create initial engagement record
      await engagementRef.set({
        articleId,
        likeCount: 0,
        commentCount: Math.max(0, increment || 1),
        shareCount: 0,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });
    }

    return res.status(200).json({
      success: true,
      message: "Comment count updated successfully",
    });
  } catch (error) {
    console.error("Error updating comment count:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update comment count",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
