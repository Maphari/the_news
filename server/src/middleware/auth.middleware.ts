import { Request, Response, NextFunction } from "express";
import { db } from "../config/firebase.connection";
import { verifyJwtToken } from "../utils/account.utils";

interface DecodedToken {
  userId: string;
  email: string;
  iat?: number;
  exp?: number;
}

export const verifyToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void | Response> => {
  try {
    //? Get token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        error: "No token provided",
        message: "Authentication required",
      });
    }

    const token = authHeader.split(" ")[1];

    //? Verify JWT token
    let decoded: DecodedToken;
    try {
      decoded = verifyJwtToken(token) as DecodedToken;
    } catch (error: any) {
      if (error.name === "JsonWebTokenError") {
        return res.status(401).json({
          error: "Invalid token",
          message: "Authentication failed",
        });
      }
      
      if (error.name === "TokenExpiredError") {
        return res.status(401).json({
          error: "Token expired",
          message: "Please login again",
        });
      }
      
      throw error;
    }

    //? Verify userId exists in decoded token
    if (!decoded.userId || !decoded.email) {
      return res.status(401).json({
        error: "Invalid token payload",
        message: "Token is missing required information",
      });
    }

    //? Check if the user exists in Firestore
    const userDoc = await db.collection('users').doc(decoded.userId).get();
    
    if (!userDoc.exists) {
      return res.status(401).json({
        error: "User not found",
        message: "Invalid token - user does not exist",
      });
    }

    const userData = userDoc.data();

    //? Attach user data to request
    req.user = {
      userId: decoded.userId,
      email: decoded.email,
      ...userData,
    };

    next();
  } catch (error: any) {
    console.error("Token verification error:", error);
    return res.status(500).json({
      error: "Internal server error",
      message: "Failed to authenticate token",
    });
  }
};