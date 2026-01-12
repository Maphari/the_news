import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import {
  FollowedPublisher,
  FollowPublisherRequest,
  UnfollowPublisherRequest,
} from "../models/followed-publisher.model";
import { Timestamp } from "firebase-admin/firestore";

const followedPublishersCollection = db.collection("followedPublishers");

/**
 * Get all publishers followed by a user
 * GET /api/v1/followed-publishers/:userId
 */
export const getFollowedPublishers = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const followedQuery = await followedPublishersCollection
      .where("userId", "==", userId)
      .get();

    const publishers: string[] = [];
    followedQuery.forEach((doc) => {
      const data = doc.data() as FollowedPublisher;
      publishers.push(data.publisherName);
    });

    return res.status(200).json({
      success: true,
      publishers,
      count: publishers.length,
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
