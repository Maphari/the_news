import { Timestamp } from "firebase-admin/firestore";

/**
 * User Profile Model
 * Represents a user's social profile
 */
export interface UserProfile {
  userId: string;
  username: string;
  displayName: string;
  bio?: string;
  avatarUrl?: string;
  coverImageUrl?: string;
  joinedDate: Timestamp | Date | string;
  followersCount: number;
  followingCount: number;
  articlesReadCount: number;
  collectionsCount: number;
  isPublic: boolean;
  interests: string[];
  stats: {
    [key: string]: any;
  };
}

/**
 * User Follow Model
 * Represents a follow relationship between users
 */
export interface UserFollow {
  id?: string; // Firestore document ID
  followerId: string; // User who follows
  followingId: string; // User being followed
  followedAt: Timestamp | Date | string;
}

/**
 * Reading List Model
 * Represents a curated list of articles
 */
export interface ReadingList {
  id?: string; // Firestore document ID
  name: string;
  description?: string;
  ownerId: string;
  ownerName: string;
  articleIds: string[];
  collaboratorIds: string[];
  visibility: 'public' | 'private' | 'friendsOnly';
  createdAt: Timestamp | Date | string;
  updatedAt: Timestamp | Date | string;
  tags: string[];
  isCollaborative: boolean;
}

/**
 * Activity Feed Item Model
 * Represents an activity in the user's feed
 */
export interface ActivityFeedItem {
  id?: string; // Firestore document ID
  userId: string;
  username: string;
  userAvatarUrl?: string;
  activityType: 'readArticle' | 'createList' | 'updateList' | 'addToList' | 'followUser' | 'shareList' | 'commentArticle' | 'likeArticle';
  timestamp: Timestamp | Date | string;

  // Optional fields depending on activity type
  articleId?: string;
  articleTitle?: string;
  listId?: string;
  listName?: string;
  followedUserId?: string;
  followedUsername?: string;
  commentId?: string;
  commentText?: string;
}

// Request/Response types

export interface CreateUserProfileRequest {
  userId: string;
  username: string;
  displayName: string;
  bio?: string;
  avatarUrl?: string;
}

export interface UpdateUserProfileRequest {
  userId: string;
  username?: string;
  displayName?: string;
  bio?: string;
  avatarUrl?: string;
  coverImageUrl?: string;
  isPublic?: boolean;
  interests?: string[];
}

export interface FollowUserRequest {
  followerId: string;
  followingId: string;
}

export interface CreateReadingListRequest {
  ownerId: string;
  name: string;
  description?: string;
  visibility?: 'public' | 'private' | 'friendsOnly';
  tags?: string[];
}

export interface UpdateReadingListRequest {
  listId: string;
  name?: string;
  description?: string;
  visibility?: 'public' | 'private' | 'friendsOnly';
  tags?: string[];
}

export interface AddArticleToListRequest {
  listId: string;
  articleId: string;
}

export interface AddCollaboratorRequest {
  listId: string;
  userId: string;
}

export interface CreateActivityRequest {
  userId: string;
  activityType: ActivityFeedItem['activityType'];
  articleId?: string;
  articleTitle?: string;
  listId?: string;
  listName?: string;
  followedUserId?: string;
  followedUsername?: string;
}

export interface SearchUsersRequest {
  query: string;
  limit?: number;
}

export interface GetActivityFeedRequest {
  userId: string;
  limit?: number;
}
