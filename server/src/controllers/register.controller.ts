import { Request, Response } from "express";
import { db, admin } from "../config/firebase.connection";
import { RegisterLoginAuthUserObject } from "../models/user.model";
import { validateRegistrationInput } from "../utils/register.utils";

async function registerUserController(req: Request, res: Response) {
  try {
    //? Validate and sanitize input
    const validation = validateRegistrationInput(req.body);

    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: "Validation failed",
        errors: validation.errors,
      });
    }

    const { names, email } = validation.sanitizedData!;

    //? Check if user already exists
    const userSnapshot = await db
      .collection("users")
      .where("email", "==", email)
      .limit(1)
      .get();

    if (!userSnapshot.empty) {
      return res.status(409).json({
        success: false,
        message: "Account already exists. Please login",
      });
    }

    //? Generate timestamps
    const now = admin.firestore.Timestamp.now();
    const isoNow = now.toDate().toISOString();

    //? Prepare response (exclude sensitive data)
    const response: RegisterLoginAuthUserObject = {
      token: '',
      user: {
        id: '',
        name: names,
        email,
        success: true,
        message: "Awaiting verification, please verify email",
        createdAt: isoNow,
        updatedAt: isoNow,
        lastLogin: isoNow,
      },
    };

    return res.status(200).json(response);
  } catch (error) {
    //* Log error for debugging (use proper logging service in production)
    console.error("Registration error:", {
      error: error instanceof Error ? error.message : "Unknown error",
      stack: error instanceof Error ? error.stack : undefined,
      timestamp: new Date().toISOString(),
    });

    //* Generic error response (don't expose internal details)
    return res.status(500).json({
      success: false,
      message: "An error occurred during registration. Please try again later.",
      ...(process.env.NODE_ENV === "development" && {
        debug: {
          error: error instanceof Error ? error.message : String(error),
          type: error instanceof Error ? error.constructor.name : typeof error,
        },
      }),
    });
  }
}

export { registerUserController };
