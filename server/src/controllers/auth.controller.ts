import { Request, Response } from "express";
import { db, admin } from "../config/firebase.connection";
import dotenv from "dotenv";

dotenv.config();

//? GET /auth/me - Get authenticated user data
export const authenticatedUserController = async (
  req: Request,
  res: Response
): Promise<Response> => {
  try {
    if (!req.user || !req.user.userId) {
      return res.status(401).json({
        error: "Unauthorized",
        message: "User not authenticated",
      });
    }
    //? Find user by email
    const userSnapshot = await db
      .collection("users")
      .where("userId", "==", req.user.userId)
      .limit(1)
      .get();

    //? Get user data from Firebase Realtime Database
    const userDoc = userSnapshot.docs[0];
    const userData = userDoc.data();

    if (!userSnapshot.empty) {
      return res.status(404).json({
        error: "User not found",
        message: "User data not found",
      });
    }

    //? Update last login
    await db.collection("users").doc(req.user.userId).update({
      lastAccessed: admin.firestore.FieldValue.serverTimestamp(),
    });
    //? Return user data (exclude sensitive fields like password)
    const { password, ...safeUserData } = userData;

    return res.status(200).json({
      id: req.user.userId,
      name: userData.names || userData.name || "",
      email: userData.email,
      photoUrl: userData.photoUrl || null,
      provider: userData.provider || null,
      createdAt: userData.createdAt || null,
      updatedAt: userData.updatedAt || null,
      lastLogin: userData.lastLogin || null,
      lastAccessed: new Date().toISOString(),
    });
  } catch (error) {
    console.error("Get user data error:", error);
    return res.status(500).json({
      error: "Internal server error",
      message: "Failed to retrieve user data",
    });
  }
};

//? GET /auth/validate-token - Validate JWT token
export const authController = async (
  req: Request,
  res: Response
): Promise<Response> => {
  try {
    if (!req.user || !req.user.userId) {
      return res.status(401).json({
        valid: false,
        error: "Unauthorized",
        message: "User not authenticated",
      });
    }

    // If middleware passes, token is valid
    return res.status(200).json({
      valid: true,
      message: "Token is valid",
      userId: req.user.userId,
      email: req.user.email,
    });
  } catch (error) {
    console.error("Token validation error:", error);
    return res.status(500).json({
      valid: false,
      error: "Internal server error",
      message: "Failed to validate token",
    });
  }
};
