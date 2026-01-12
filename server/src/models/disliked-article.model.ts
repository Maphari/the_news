import { Timestamp } from "firebase-admin/firestore";

/**
 * Represents a disliked article in the database
 */
export interface DislikedArticle {
  id?: string;
  userId: string;
  articleId: string;
  dislikedAt: Timestamp | Date | string;
}

/**
 * Request body for disliking an article
 */
export interface DislikeArticleRequest {
  userId: string;
  articleId: string;
}

/**
 * Response when getting disliked article IDs
 */
export interface DislikedArticlesResponse {
  success: boolean;
  articleIds: string[];
  count: number;
}
