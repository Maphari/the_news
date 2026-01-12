import { Request, Response } from "express";
import { db, admin } from "../config/firebase.connection";
import { RegisterLoginAuthUserObject } from "../models/user.model";
import { generateToken, generateUUID } from "../utils/account.utils";
import { GoogleAuthService } from "../services/google.service";
import { ensureUserProfile } from "../utils/profile.utils";

const googleAuthService = new GoogleAuthService();

async function registerUserWithGoogleController(req: Request, res: Response) {
  try {
    //? Extract data from request body
    const { accessToken, provider, email, name, photoUrl, userId: googleUserId } = req.body;
    
    let userId: string;
    let userName: string;
    const now = new Date().toISOString();

    // Validate accessToken presence
    if (!accessToken) {
      return res.status(400).json({
        success: false,
        message: "Access token is required",
      });
    }

    //? Authenticate with Google using ACCESS TOKEN (not ID token)
    const authResult = await googleAuthService.authenticateWithAccessToken(accessToken);
    console.log('✅ Google auth result:', authResult);

    const { user: googleUser } = authResult;

    //? Check if user already exists in Firebase
    const userSnapshot = await db
      .collection("users")
      .where("email", "==", googleUser.email)
      .limit(1)
      .get();

    if (!userSnapshot.empty) {
      //? User exists - update last login and return existing user
      const existingUserDoc = userSnapshot.docs[0];
      const existingUserData = existingUserDoc.data();
      
      userId = existingUserData.id;
      userName = existingUserData.names || existingUserData.name || googleUser.name;

      //? Update last login timestamp
      await existingUserDoc.ref.update({
        lastLogin: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        //? Optionally update profile picture if changed
        picture: googleUser.picture,
      });
      
      console.log(`✅ Existing user logged in: ${userName}`);
    } else {
      //? New user - create account
      userId = generateUUID();
      userName = googleUser.name;

      await db.collection("users").add({
        id: userId,
        names: userName,
        email: googleUser.email,
        googleId: googleUser.id,
        picture: googleUser.picture,
        acceptedTerms: true, //? Auto-accept for OAuth users
        authProvider: provider || 'Google',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`✅ New user registered: ${userName}`);
    }

    //? Ensure user profile exists for social features
    await ensureUserProfile(userId, userName, googleUser.email);

    //? Generate JWT token for your app
    const token = generateToken(userId, googleUser.email);

    //? Prepare response object
    const results: RegisterLoginAuthUserObject = {
      token,
      user: {
        id: userId,
        name: userName,
        email: googleUser.email,
        photoUrl: googleUser.picture,
        success: true,
        message: userSnapshot.empty 
          ? "User registered successfully with Google" 
          : "Successfully signed in with Google",
        createdAt: now,
        updatedAt: now,
        lastLogin: now,
      },
    };

    return res.status(200).json(results);
    
  } catch (error) {
    console.error("Google authentication error:", error);
    return res.status(500).json({
      success: false,
      message: error instanceof Error ? error.message : "Authentication failed",
      error: process.env.NODE_ENV === "development" ? String(error) : undefined,
    });
  }
}

export { registerUserWithGoogleController };