import { Request, Response } from "express";
import { db, admin } from "../config/firebase.connection";

const digestsCollection = db.collection("dailyDigests");

/**
 * Get digests for a user
 * GET /api/v1/digests/:userId
 */
export const getDigests = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const limit = Math.min(parseInt(req.query.limit as string) || 30, 50);

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const snapshot = await digestsCollection
      .where("userId", "==", userId)
      .limit(limit)
      .get();

    const digests = snapshot.docs.map((doc) => {
      const data = doc.data() as Record<string, any>;
      return {
        ...data,
        generatedAt: data.generatedAt?.toDate?.()?.toISOString?.() ?? data.generatedAt,
        readAt: data.readAt?.toDate?.()?.toISOString?.() ?? data.readAt,
      };
    }).sort((a, b) => {
      const aDate = new Date(a.generatedAt ?? 0).getTime();
      const bDate = new Date(b.generatedAt ?? 0).getTime();
      return bDate - aDate;
    }).slice(0, limit);

    return res.status(200).json({
      success: true,
      digests,
      count: digests.length,
    });
  } catch (error: any) {
    console.error("❌ Get digests error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to fetch digests",
      error: error.message,
    });
  }
};

/**
 * Create or update a digest
 * POST /api/v1/digests
 */
export const createDigest = async (req: Request, res: Response) => {
  try {
    const digest = req.body as Record<string, any>;
    const { digestId, userId, generatedAt } = digest;

    if (!digestId || !userId) {
      return res.status(400).json({
        success: false,
        message: "digestId and userId are required",
      });
    }

    const docId = `${userId}_${digestId}`;
    const payload = {
      ...digest,
      generatedAt: generatedAt
        ? admin.firestore.Timestamp.fromDate(new Date(generatedAt))
        : admin.firestore.Timestamp.now(),
      readAt: digest.readAt
        ? admin.firestore.Timestamp.fromDate(new Date(digest.readAt))
        : null,
      updatedAt: admin.firestore.Timestamp.now(),
      createdAt: admin.firestore.Timestamp.now(),
    };

    await digestsCollection.doc(docId).set(payload, { merge: true });

    return res.status(201).json({
      success: true,
      message: "Digest saved",
    });
  } catch (error: any) {
    console.error("❌ Create digest error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to save digest",
      error: error.message,
    });
  }
};

/**
 * Delete a digest
 * DELETE /api/v1/digests/:userId/:digestId
 */
export const deleteDigest = async (req: Request, res: Response) => {
  try {
    const { userId, digestId } = req.params;
    if (!userId || !digestId) {
      return res.status(400).json({
        success: false,
        message: "userId and digestId are required",
      });
    }

    const docId = `${userId}_${digestId}`;
    const docRef = digestsCollection.doc(docId);
    const snapshot = await docRef.get();
    if (!snapshot.exists) {
      return res.status(404).json({
        success: false,
        message: "Digest not found",
      });
    }

    await docRef.delete();
    return res.status(200).json({
      success: true,
      message: "Digest deleted",
    });
  } catch (error: any) {
    console.error("❌ Delete digest error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to delete digest",
      error: error.message,
    });
  }
};
