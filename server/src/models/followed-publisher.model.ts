import { Timestamp } from "firebase-admin/firestore";

export interface FollowedPublisher {
  userId: string;
  publisherName: string;
  followedAt: Timestamp;
}

export interface FollowPublisherRequest {
  userId: string;
  publisherName: string;
}

export interface UnfollowPublisherRequest {
  userId: string;
  publisherName: string;
}
