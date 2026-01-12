import { Request, Response } from "express";
import { EmailService } from "../services/email.service";
import { generateOtpCode } from "../utils/otp.generate.utils";
import {
  generateToken,
  generateUUID,
  hashPassword,
} from "../utils/account.utils";
import { db, admin } from "../config/firebase.connection";
import { RegisterLoginAuthUserObject } from "../models/user.model";
import { validateRequestBody } from "../utils/otp.utils";
import { OtpRegisterRequestBody } from "../types/register.types";
import { ensureUserProfile } from "../utils/profile.utils";

export async function verifyOtpCodeAndSaveUser(req: Request, res: Response) {
  try {
    //? Validate request body
    const validationErrors = validateRequestBody(req);

    if (validationErrors.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Validation failed",
        errors: validationErrors,
      });
    }

    //? Type assertion is safe here because validation passed
    const { names, email, password, acceptedTerms } =
      req.body as OtpRegisterRequestBody;

    //? Generate UUID
    const userId = generateUUID();

    //? Hash the password before storing it
    const hashedPassword = await hashPassword(password);

    //? User object to be created
    const now = new Date().toISOString();

    await db.collection("users").add({
      id: userId,
      names,
      email,
      password: hashedPassword,
      acceptedTerms,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    //? Auto-create user profile for social features
    await ensureUserProfile(userId, names, email);

    //? Generate JWT token
    const token = generateToken(userId, email);

    const results: RegisterLoginAuthUserObject = {
      token,
      user: {
        id: userId,
        name: names,
        email,
        success: true,
        message: "Account created successfully",
        createdAt: now,
        updatedAt: now,
        lastLogin: now,
      },
    };

    return res.status(201).json(results);
  } catch (error) {
    console.error("Error in verifyOtpCodeAndSaveUser:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
}

export async function sendOtpCode(req: Request, res: Response) {
  const { email, name } = req.body;

  if (!email) {
    return res.status(400).json({
      success: false,
      message: "Email is required",
    });
  }

  const otpCode = generateOtpCode();
  const emailService = new EmailService();
  const username = name ?? "Unknown";

  try {
    await emailService.sendOTP(email, username, otpCode);
    console.log(otpCode);
    return res.status(200).json({
      success: true,
      otp: otpCode,
      message: "Otp sent Successufully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to send OTP email",
    });
  }
}
