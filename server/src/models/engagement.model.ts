import { Timestamp } from "firebase-admin/firestore";

/**
 * Article Engagement Model
 * Tracks likes, comments, and shares for each article
 */
export interface ArticleEngagement {
  id?: string; // Firestore document ID
  articleId: string; // Article being engaged with
  likeCount: number; // Total likes
  commentCount: number; // Total comments
  shareCount: number; // Total shares
  createdAt?: Timestamp | Date | string;
  updatedAt?: Timestamp | Date | string;
}

/**
 * User Like Model
 * Tracks which users liked which articles
 */
export interface UserLike {
  id?: string;
  userId: string;
  articleId: string;
  likedAt: Timestamp | Date | string;
}

/**
 * User Share Model
 * Tracks when users share articles
 */
export interface UserShare {
  id?: string;
  userId: string;
  articleId: string;
  sharedAt: Timestamp | Date | string;
  platform?: string; // e.g., "twitter", "facebook", "copy_link"
}

/**
 * Request to like an article
 */
export interface LikeArticleRequest {
  userId: string;
  articleId: string;
}

/**
 * Request to unlike an article
 */
export interface UnlikeArticleRequest {
  userId: string;
  articleId: string;
}

/**
 * Request to share an article
 */
export interface ShareArticleRequest {
  userId: string;
  articleId: string;
  platform?: string;
}

/**
 * Response with engagement data
 */
export interface EngagementResponse {
  articleId: string;
  likeCount: number;
  commentCount: number;
  shareCount: number;
  isLiked: boolean; // Whether current user liked it
}
