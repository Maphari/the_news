import { Timestamp } from "firebase-admin/firestore";

/**
 * Saved Article Model
 * Represents a user's saved/bookmarked article
 */
export interface SavedArticle {
  id?: string; // Firestore document ID
  userId: string; // User who saved the article
  articleId: string; // Article ID reference
  savedAt: Timestamp | Date | string; // When the article was saved
}

/**
 * Request to save an article
 */
export interface SaveArticleRequest {
  userId: string;
  articleId: string;
}

/**
 * Request to unsave an article
 */
export interface UnsaveArticleRequest {
  userId: string;
  articleId: string;
}

/**
 * Response with saved article IDs
 */
export interface SavedArticleIdsResponse {
  articleIds: string[];
}
