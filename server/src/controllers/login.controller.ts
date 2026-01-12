import { Request, Response } from "express";
import { db, admin } from "../config/firebase.connection";
import { RegisterLoginAuthUserObject } from "../models/user.model";
import { comparePassword, generateToken } from "../utils/account.utils";
import { ensureUserProfile } from "../utils/profile.utils";

async function logUserController(req: Request, res: Response) {
  try {
    const { email, password } = req.body;

    //? Validate input
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    //? Find user by email
    const userSnapshot = await db.collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (userSnapshot.empty) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const userDoc = userSnapshot.docs[0];
    const userData = userDoc.data();
    
    //? Check if password exists in user data
    if (!userData.password) {
      console.error('Password not found in user document');
      return res.status(500).json({ error: 'User data is incomplete' });
    }

    //? Compare passwords
    const isPasswordValid = await comparePassword(password, userData.password);
    
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    //? Use the document ID
    const userId = userDoc.id;

    //? Generate jsonweb token
    const token = generateToken(userId, email);

    //? Update last login
    await db.collection('users').doc(userId).update({
      lastLogin: admin.firestore.FieldValue.serverTimestamp()
    });

    //? Ensure user profile exists for social features
    await ensureUserProfile(userId, userData.names || userData.name || '', email);

    //? Created user object
    const results: RegisterLoginAuthUserObject = {
      token,
      user: {
        id: userId,
        name: userData.names || userData.name || '',
        email,
        success: true,
        message: "User logged in successfully",
        createdAt: userData.createdAt,
        updatedAt: userData.updatedAt,
        lastLogin: new Date(),
      },
    };

    return res.status(200).json(results);
    
  } catch (error) {
    console.error('Login error:', error);
    
    //? Send a more descriptive error message
    return res.status(500).json({ 
      error: 'Error logging in user',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}

export { logUserController };