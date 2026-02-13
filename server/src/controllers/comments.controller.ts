import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import {
  Comment,
  CommentLike,
  AddCommentRequest,
  UpdateCommentRequest,
  DeleteCommentRequest,
  LikeCommentRequest,
  CommentResponse,
} from "../models/comment.model";
import { Timestamp } from "firebase-admin/firestore";
import { getOptionalString } from "../utils/request.utils";

const commentsCollection = db.collection("comments");
const commentLikesCollection = db.collection("commentLikes");
const engagementCollection = db.collection("articleEngagement");

/**
 * Get comments for an article
 * GET /api/v1/comments/:articleId
 */
export const getComments = async (req: Request, res: Response) => {
  try {
    const articleId = getOptionalString(req.params.articleId);
    const userId = getOptionalString(req.query.userId);

    if (!articleId) {
      return res.status(400).json({
        success: false,
        message: "articleId is required",
      });
    }

    // Get all comments for this article
    const commentsQuery = await commentsCollection
      .where("articleId", "==", articleId)
      .get();

    const comments: CommentResponse[] = [];

    const docs = commentsQuery.docs.sort((a, b) => {
      const aTime = (a.data() as Comment).createdAt?.toMillis?.() ?? 0;
      const bTime = (b.data() as Comment).createdAt?.toMillis?.() ?? 0;
      return bTime - aTime;
    });

    for (const doc of docs) {
      const comment = doc.data() as Comment;

      // Check if user liked this comment
      let isLiked = false;
      if (userId) {
        const likeQuery = await commentLikesCollection
          .where("commentId", "==", doc.id)
          .where("userId", "==", userId)
          .limit(1)
          .get();
        isLiked = !likeQuery.empty;
      }

      comments.push({
        id: doc.id,
        articleId: comment.articleId,
        userId: comment.userId,
        userName: comment.userName,
        text: comment.text,
        parentCommentId: comment.parentCommentId,
        likeCount: comment.likeCount,
        isLiked,
        createdAt: comment.createdAt.toDate().toISOString(),
        updatedAt: comment.updatedAt.toDate().toISOString(),
      });
    }

    return res.status(200).json({
      success: true,
      comments,
      count: comments.length,
    });
  } catch (error) {
    console.error("Error getting comments:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get comments",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Add a comment
 * POST /api/v1/comments
 */
export const addComment = async (req: Request, res: Response) => {
  try {
    const {
      articleId,
      userId,
      userName,
      text,
      parentCommentId,
    }: AddCommentRequest = req.body;

    if (!articleId || !userId || !userName || !text) {
      return res.status(400).json({
        success: false,
        message: "articleId, userId, userName, and text are required",
      });
    }

    // Create comment
    const normalizedParentId =
      typeof parentCommentId === "string" && parentCommentId.trim().length > 0
        ? parentCommentId
        : undefined;

    const comment: Comment = {
      articleId,
      userId,
      userName,
      text: text.trim(),
      parentCommentId: normalizedParentId,
      likeCount: 0,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    };

    const commentRef = await commentsCollection.add(comment);

    // Increment comment count in engagement
    const engagementRef = engagementCollection.doc(articleId);
    const engagementDoc = await engagementRef.get();

    if (engagementDoc.exists) {
      await engagementRef.update({
        commentCount: (engagementDoc.data()?.commentCount || 0) + 1,
        updatedAt: Timestamp.now(),
      });
    } else {
      // Create initial engagement record
      await engagementRef.set({
        articleId,
        likeCount: 0,
        commentCount: 1,
        shareCount: 0,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });
    }

    return res.status(201).json({
      success: true,
      message: "Comment added successfully",
      commentId: commentRef.id,
    });
  } catch (error) {
    console.error("Error adding comment:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to add comment",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Update a comment
 * PUT /api/v1/comments/:commentId
 */
export const updateComment = async (req: Request, res: Response) => {
  try {
    const commentId = getOptionalString(req.params.commentId);
    const { userId, text }: UpdateCommentRequest = req.body;

    if (!commentId || !userId || !text) {
      return res.status(400).json({
        success: false,
        message: "commentId, userId, and text are required",
      });
    }

    // Get the comment
    const commentDoc = await commentsCollection.doc(commentId).get();

    if (!commentDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Comment not found",
      });
    }

    const comment = commentDoc.data() as Comment;

    // Check if user owns the comment
    if (comment.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: "You can only edit your own comments",
      });
    }

    // Update comment
    await commentsCollection.doc(commentId).update({
      text: text.trim(),
      updatedAt: Timestamp.now(),
    });

    return res.status(200).json({
      success: true,
      message: "Comment updated successfully",
    });
  } catch (error) {
    console.error("Error updating comment:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update comment",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Delete a comment
 * DELETE /api/v1/comments/:commentId
 */
export const deleteComment = async (req: Request, res: Response) => {
  try {
    const commentId = getOptionalString(req.params.commentId);
    const { userId }: DeleteCommentRequest = req.body;

    if (!commentId || !userId) {
      return res.status(400).json({
        success: false,
        message: "commentId and userId are required",
      });
    }

    // Get the comment
    const commentDoc = await commentsCollection.doc(commentId).get();

    if (!commentDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Comment not found",
      });
    }

    const comment = commentDoc.data() as Comment;

    // Check if user owns the comment
    if (comment.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: "You can only delete your own comments",
      });
    }

    // Delete all likes on this comment
    const likesQuery = await commentLikesCollection
      .where("commentId", "==", commentId)
      .get();
    const deleteLikesPromises = likesQuery.docs.map((doc) => doc.ref.delete());
    await Promise.all(deleteLikesPromises);

    // Delete the comment
    await commentsCollection.doc(commentId).delete();

    // Decrement comment count in engagement
    const engagementRef = engagementCollection.doc(comment.articleId);
    const engagementDoc = await engagementRef.get();

    if (engagementDoc.exists) {
      const currentCount = engagementDoc.data()?.commentCount || 0;
      await engagementRef.update({
        commentCount: Math.max(0, currentCount - 1),
        updatedAt: Timestamp.now(),
      });
    }

    return res.status(200).json({
      success: true,
      message: "Comment deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting comment:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete comment",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Like a comment
 * POST /api/v1/comments/like
 */
export const likeComment = async (req: Request, res: Response) => {
  try {
    const { commentId, userId }: LikeCommentRequest = req.body;

    if (!commentId || !userId) {
      return res.status(400).json({
        success: false,
        message: "commentId and userId are required",
      });
    }

    // Check if already liked
    const existingLike = await commentLikesCollection
      .where("commentId", "==", commentId)
      .where("userId", "==", userId)
      .limit(1)
      .get();

    if (!existingLike.empty) {
      return res.status(200).json({
        success: true,
        message: "Comment already liked",
        alreadyLiked: true,
      });
    }

    // Add like
    const commentLike: CommentLike = {
      commentId,
      userId,
      likedAt: Timestamp.now(),
    };
    await commentLikesCollection.add(commentLike);

    // Increment like count on comment
    const commentRef = commentsCollection.doc(commentId);
    const commentDoc = await commentRef.get();

    if (commentDoc.exists) {
      await commentRef.update({
        likeCount: (commentDoc.data()?.likeCount || 0) + 1,
        updatedAt: Timestamp.now(),
      });
    }

    return res.status(200).json({
      success: true,
      message: "Comment liked successfully",
    });
  } catch (error) {
    console.error("Error liking comment:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to like comment",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Unlike a comment
 * DELETE /api/v1/comments/like
 */
export const unlikeComment = async (req: Request, res: Response) => {
  try {
    const { commentId, userId }: LikeCommentRequest = req.body;

    if (!commentId || !userId) {
      return res.status(400).json({
        success: false,
        message: "commentId and userId are required",
      });
    }

    // Find and delete the like
    const likeQuery = await commentLikesCollection
      .where("commentId", "==", commentId)
      .where("userId", "==", userId)
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

    // Decrement like count on comment
    const commentRef = commentsCollection.doc(commentId);
    const commentDoc = await commentRef.get();

    if (commentDoc.exists) {
      const currentCount = commentDoc.data()?.likeCount || 0;
      await commentRef.update({
        likeCount: Math.max(0, currentCount - 1),
        updatedAt: Timestamp.now(),
      });
    }

    return res.status(200).json({
      success: true,
      message: "Comment unliked successfully",
    });
  } catch (error) {
    console.error("Error unliking comment:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to unlike comment",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
