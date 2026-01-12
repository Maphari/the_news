import { OAuth2Client } from "google-auth-library";
// import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import { GoogleAppleAuthUserObject } from "../models/user.model";
import axios from "axios";

dotenv.config();

export class GoogleAuthService {
  private googleClient: OAuth2Client;

  constructor(
    googleClientId: string = String(process.env.GOOGLE_CLIENT_ID),
    jwtSecret: string = String(process.env.JWT_SECRET)
  ) {
    this.googleClient = new OAuth2Client(googleClientId);
  }

  //? Method to verify ID token (if you have it)
  async authenticate(idToken: string): Promise<GoogleAppleAuthUserObject> {
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });

      const payload = ticket.getPayload();

      if (!payload) {
        throw new Error("Invalid token payload");
      }

      const { sub: googleId, email, name, picture } = payload;

      if (!email) {
        throw new Error("Email not provided by Google");
      }

      return {
        token: '',
        user: {
          id: googleId,
          email,
          name: String(name || ''),
          picture,
        },
      };
    } catch (error) {
      console.error("Google auth error:", error);
      throw new Error(`Authentication failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  //? Verify access token
  async authenticateWithAccessToken(accessToken: string): Promise<GoogleAppleAuthUserObject> {
    try {
      //? Use Google's tokeninfo endpoint to verify the access token
      const response: Axios.AxiosXHR<any> = await axios.get(
        `https://www.googleapis.com/oauth2/v1/userinfo?access_token=${accessToken}`
      );

      const { id, email, name, picture } = response.data;

      if (!email) {
        throw new Error("Email not provided by Google");
      }

      return {
        token: '',
        user: {
          id,
          email,
          name: String(name || ''),
          picture,
        },
      };
    } catch (error) {
      throw new Error(`Access token verification failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
}