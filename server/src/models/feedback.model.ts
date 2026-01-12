import { Timestamp } from "firebase-admin/firestore";

/**
 * Feedback types
 */
export enum FeedbackType {
  BUG = "bug",
  FEATURE = "feature",
  IMPROVEMENT = "improvement",
  GENERAL = "general",
}

/**
 * Feedback status
 */
export enum FeedbackStatus {
  NEW = "new",
  REVIEWING = "reviewing",
  PLANNED = "planned",
  IN_PROGRESS = "in_progress",
  COMPLETED = "completed",
  CLOSED = "closed",
}

/**
 * User Feedback Model
 */
export interface Feedback {
  id?: string;
  userId: string;
  userEmail: string;
  type: FeedbackType;
  title: string;
  description: string;
  platform: string; // e.g., "mobile", "web"
  status: FeedbackStatus;
  createdAt: Timestamp | Date | string;
  updatedAt: Timestamp | Date | string;
}

/**
 * Submit feedback request
 */
export interface SubmitFeedbackRequest {
  userId: string;
  userEmail: string;
  type: string;
  title: string;
  description: string;
  platform: string;
}

/**
 * Feedback response
 */
export interface FeedbackResponse {
  id: string;
  userId: string;
  userEmail: string;
  type: FeedbackType;
  title: string;
  description: string;
  platform: string;
  status: FeedbackStatus;
  createdAt: string;
  updatedAt: string;
}
