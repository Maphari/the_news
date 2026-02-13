import { Request, Response } from "express";
import { db, admin } from "../config/firebase.connection";
import { comparePassword, hashPassword } from "../utils/account.utils";
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

//? POST /auth/change-password - Change password for authenticated user
export const changePasswordController = async (
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

    const { currentPassword, newPassword, confirmPassword } = req.body ?? {};

    if (
      typeof currentPassword !== "string" ||
      typeof newPassword !== "string" ||
      typeof confirmPassword !== "string"
    ) {
      return res.status(400).json({
        error: "Validation failed",
        message: "Current password, new password and confirmation are required",
      });
    }

    if (newPassword !== confirmPassword) {
      return res.status(400).json({
        error: "Validation failed",
        message: "Passwords do not match",
      });
    }

    if (currentPassword === newPassword) {
      return res.status(400).json({
        error: "Validation failed",
        message: "New password must be different from current password",
      });
    }

    const PASSWORD_MIN_LENGTH = 8;
    const PASSWORD_MAX_LENGTH = 128;
    if (
      newPassword.length < PASSWORD_MIN_LENGTH ||
      newPassword.length > PASSWORD_MAX_LENGTH
    ) {
      return res.status(400).json({
        error: "Validation failed",
        message: `Password must be ${PASSWORD_MIN_LENGTH}-${PASSWORD_MAX_LENGTH} characters`,
      });
    }

    const hasUpperCase = /[A-Z]/.test(newPassword);
    const hasLowerCase = /[a-z]/.test(newPassword);
    const hasNumber = /[0-9]/.test(newPassword);
    const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(newPassword);

    if (!hasUpperCase || !hasLowerCase || !hasNumber || !hasSpecialChar) {
      return res.status(400).json({
        error: "Validation failed",
        message:
          "Password must include uppercase, lowercase, number, and special character",
      });
    }

    const userDoc = await db.collection("users").doc(req.user.userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({
        error: "User not found",
        message: "User data not found",
      });
    }

    const userData = userDoc.data();
    if (!userData?.password) {
      return res.status(400).json({
        error: "Unsupported",
        message: "Password change is not available for social login accounts",
      });
    }

    const isPasswordValid = await comparePassword(
      currentPassword,
      userData.password
    );

    if (!isPasswordValid) {
      return res.status(401).json({
        error: "Invalid credentials",
        message: "Current password is incorrect",
      });
    }

    const hashedPassword = await hashPassword(newPassword);

    await db.collection("users").doc(req.user.userId).update({
      password: hashedPassword,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).json({
      success: true,
      message: "Password updated successfully",
    });
  } catch (error) {
    console.error("Change password error:", error);
    return res.status(500).json({
      error: "Internal server error",
      message: "Failed to update password",
    });
  }
};
