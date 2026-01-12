import { Timestamp } from "firebase-admin/firestore";

export interface Comment {
  id?: string;
  articleId: string;
  userId: string;
  userName: string;
  text: string;
  parentCommentId?: string; // For replies
  likeCount: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface AddCommentRequest {
  articleId: string;
  userId: string;
  userName: string;
  text: string;
  parentCommentId?: string;
}

export interface UpdateCommentRequest {
  commentId: string;
  userId: string;
  text: string;
}

export interface DeleteCommentRequest {
  commentId: string;
  userId: string;
}

export interface LikeCommentRequest {
  commentId: string;
  userId: string;
}

export interface CommentLike {
  commentId: string;
  userId: string;
  likedAt: Timestamp;
}

export interface CommentResponse {
  id: string;
  articleId: string;
  userId: string;
  userName: string;
  text: string;
  parentCommentId?: string;
  likeCount: number;
  isLiked: boolean;
  createdAt: string;
  updatedAt: string;
}
