import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import {
  Feedback,
  FeedbackType,
  FeedbackStatus,
  SubmitFeedbackRequest,
  FeedbackResponse,
} from "../models/feedback.model";
import { Timestamp } from "firebase-admin/firestore";
import { getOptionalString } from "../utils/request.utils";

const feedbackCollection = db.collection("feedback");

/**
 * Submit feedback
 * POST /api/v1/feedback
 */
export const submitFeedback = async (req: Request, res: Response) => {
  try {
    const {
      userId,
      userEmail,
      type,
      title,
      description,
      platform,
    }: SubmitFeedbackRequest = req.body;

    if (!userId || !userEmail || !type || !title || !description) {
      return res.status(400).json({
        success: false,
        message: "userId, userEmail, type, title, and description are required",
      });
    }

    // Validate feedback type
    const validTypes = Object.values(FeedbackType);
    if (!validTypes.includes(type as FeedbackType)) {
      return res.status(400).json({
        success: false,
        message: `Invalid feedback type. Must be one of: ${validTypes.join(", ")}`,
      });
    }

    // Create feedback
    const feedback: Feedback = {
      userId,
      userEmail,
      type: type as FeedbackType,
      title: title.trim(),
      description: description.trim(),
      platform: platform || "mobile",
      status: FeedbackStatus.NEW,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    };

    const feedbackRef = await feedbackCollection.add(feedback);

    console.log(`✅ Feedback submitted: ${feedbackRef.id} (${type})`);

    return res.status(201).json({
      success: true,
      message: "Feedback submitted successfully",
      feedbackId: feedbackRef.id,
    });
  } catch (error) {
    console.error("Error submitting feedback:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to submit feedback",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get feedback history for a user
 * GET /api/v1/feedback/user/:userId
 */
export const getUserFeedback = async (req: Request, res: Response) => {
  try {
    const userId = getOptionalString(req.params.userId);

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const feedbackQuery = await feedbackCollection
      .where("userId", "==", userId)
      .orderBy("createdAt", "desc")
      .get();

    const feedback: FeedbackResponse[] = feedbackQuery.docs.map((doc) => {
      const data = doc.data() as Feedback;
      return {
        id: doc.id,
        userId: data.userId,
        userEmail: data.userEmail,
        type: data.type,
        title: data.title,
        description: data.description,
        platform: data.platform,
        status: data.status,
        createdAt:
          data.createdAt instanceof Timestamp
            ? data.createdAt.toDate().toISOString()
            : data.createdAt.toString(),
        updatedAt:
          data.updatedAt instanceof Timestamp
            ? data.updatedAt.toDate().toISOString()
            : data.updatedAt.toString(),
      };
    });

    return res.status(200).json({
      success: true,
      feedback,
      count: feedback.length,
    });
  } catch (error) {
    console.error("Error getting user feedback:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get feedback",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get all feedback (admin only)
 * GET /api/v1/feedback
 */
export const getAllFeedback = async (req: Request, res: Response) => {
  try {
    const { type, status, limit = 100 } = req.query;

    let query = feedbackCollection.orderBy("createdAt", "desc");

    // Filter by type
    if (type) {
      const validTypes = Object.values(FeedbackType);
      if (!validTypes.includes(type as FeedbackType)) {
        return res.status(400).json({
          success: false,
          message: `Invalid feedback type. Must be one of: ${validTypes.join(", ")}`,
        });
      }
      query = query.where("type", "==", type) as any;
    }

    // Filter by status
    if (status) {
      const validStatuses = Object.values(FeedbackStatus);
      if (!validStatuses.includes(status as FeedbackStatus)) {
        return res.status(400).json({
          success: false,
          message: `Invalid status. Must be one of: ${validStatuses.join(", ")}`,
        });
      }
      query = query.where("status", "==", status) as any;
    }

    // Limit results
    query = query.limit(Number(limit)) as any;

    const feedbackQuery = await query.get();

    const feedback: FeedbackResponse[] = feedbackQuery.docs.map((doc) => {
      const data = doc.data() as Feedback;
      return {
        id: doc.id,
        userId: data.userId,
        userEmail: data.userEmail,
        type: data.type,
        title: data.title,
        description: data.description,
        platform: data.platform,
        status: data.status,
        createdAt:
          data.createdAt instanceof Timestamp
            ? data.createdAt.toDate().toISOString()
            : data.createdAt.toString(),
        updatedAt:
          data.updatedAt instanceof Timestamp
            ? data.updatedAt.toDate().toISOString()
            : data.updatedAt.toString(),
      };
    });

    return res.status(200).json({
      success: true,
      feedback,
      count: feedback.length,
    });
  } catch (error) {
    console.error("Error getting all feedback:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get feedback",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Update feedback status (admin only)
 * PUT /api/v1/feedback/:feedbackId/status
 */
export const updateFeedbackStatus = async (req: Request, res: Response) => {
  try {
    const feedbackId = getOptionalString(req.params.feedbackId);
    const { status } = req.body;

    if (!feedbackId || !status) {
      return res.status(400).json({
        success: false,
        message: "feedbackId and status are required",
      });
    }

    // Validate status
    const validStatuses = Object.values(FeedbackStatus);
    if (!validStatuses.includes(status as FeedbackStatus)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(", ")}`,
      });
    }

    const feedbackDoc = await feedbackCollection.doc(feedbackId).get();

    if (!feedbackDoc.exists) {
      return res.status(404).json({
        success: false,
        message: "Feedback not found",
      });
    }

    await feedbackCollection.doc(feedbackId).update({
      status,
      updatedAt: Timestamp.now(),
    });

    console.log(`✅ Feedback ${feedbackId} status updated to: ${status}`);

    return res.status(200).json({
      success: true,
      message: "Feedback status updated successfully",
    });
  } catch (error) {
    console.error("Error updating feedback status:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to update feedback status",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
