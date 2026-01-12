import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { v4 as uuidv4 } from "uuid";
import dotenv from "dotenv";

dotenv.config();

interface JwtPayload {
  userId: string;
  email: string;
  iat?: number;
  exp?: number;
}

const SALT_ROUNDS: number = 10;
const JWT_SECRET: string = String(process.env.JWT_SECRET);

//? generate UUID
export const generateUUID = (): string => {
  return uuidv4();
};

/**
 * Generate JWT token for user
 */
export const generateToken = (userId: string, email: string): string => {
  const payload: JwtPayload = {
    userId,
    email,
  };

  // Token expires in 30 days (adjust as needed)
  const options: jwt.SignOptions = {
    expiresIn: "30d",
  };

  return jwt.sign(payload, JWT_SECRET, options);
};

/**
 * Verify JWT token
 */
export const verifyJwtToken = (token: string): JwtPayload => {
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as JwtPayload;
    return decoded;
  } catch (error: any) {
    // Re-throw with original error name for proper error handling
    throw error;
  }
};

/**
 * Decode token without verification (useful for debugging)
 */
export const decodeJwtToken = (token: string): JwtPayload | null => {
  try {
    return jwt.decode(token) as JwtPayload;
  } catch (error) {
    console.error("Token decode error:", error);
    return null;
  }
};

/**
 * Hash password using bcrypt
 */
export const hashPassword = async (password: string): Promise<string> => {
  try {
    const salt = await bcrypt.genSalt(SALT_ROUNDS);
    const hashedPassword = await bcrypt.hash(password, salt);
    return hashedPassword;
  } catch (error) {
    console.error("Password hashing error:", error);
    throw new Error("Failed to hash password");
  }
};

/**
 * Compare plain password with hashed password
 */
export const comparePassword = async (
  plainPassword: string,
  hashedPassword: string
): Promise<boolean> => {
  try {
    return await bcrypt.compare(plainPassword, hashedPassword);
  } catch (error) {
    console.error("Password comparison error:", error);
    throw new Error("Failed to compare passwords");
  }
};
