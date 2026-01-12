import appleSignin from 'apple-signin-auth';
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import { GoogleAppleAuthUserObject } from "../models/user.model";

//? Load environment variables from .env file
dotenv.config();

class AppleAuthService {
  private appleClientId: string;
  private jwtSecret: string;

  constructor(
    appleClientId: string = String(process.env.APPLE_CLIENT_ID),
    jwtSecret: string = String(process.env.JWT_SECRET)
  ) {
    this.appleClientId = appleClientId;
    this.jwtSecret = jwtSecret;
  }

  private generateToken(userId: string, email: string): string {
    return jwt.sign({ userId, email }, this.jwtSecret, { expiresIn: "120d" });
  }

  async authenticate(
    identityToken: string,
    givenName?: string,
    familyName?: string
  ): Promise<GoogleAppleAuthUserObject> {
    try {
      //? Verify Apple token
      const appleData = await appleSignin.verifyIdToken(identityToken, {
        audience: this.appleClientId,
        ignoreExpiration: false,
      });

      const { sub: appleId, email } = appleData;
      const userEmail = email || `${appleId}@privaterelay.appleid.com`;
      const name =
          givenName && familyName ? `${givenName} ${familyName}` : "Apple User";

      const token = this.generateToken(appleId, email);

      return {
        token,
        user: {
          id: appleId,
          email: userEmail,
          name: String(name),
        },
      };
    } catch (error) {
      console.error("Apple auth error:", error);
      throw new Error("Authentication failed");
    }
  }
}
