import { Request } from "express";

//? Extend Express Request interface to include user property
declare global {
  namespace Express {
    interface Request {
      user?: {
        userId: string;
        email: string;
        name?: string;
        names?: string;
        photoUrl?: string;
        provider?: string;
        createdAt?: string;
        updatedAt?: string;
        lastLogin?: string;
        [key: string]: any;
      };
    }
  }
}

export {};