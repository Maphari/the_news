import { Router } from "express";
import {
  cacheResponse,
  extractScopedUserIds,
  invalidateCache,
} from "../middleware/cache.middleware";
import {
  getFollowedPublishers,
  followPublisher,
  unfollowPublisher,
  checkFollowStatus,
  getPublisherFollowCount,
} from "../controllers/followed-publishers.controller";

const followedPublishersRouter = Router();
const followedPublishersReadCache = cacheResponse({
  namespace: "followed-publishers",
  ttlSeconds: 180,
});
const invalidateFollowedPublishersCache = invalidateCache((req) => {
  const userIds = extractScopedUserIds(req);
  if (userIds.length === 0) {
    return ["followed-publishers:uid:_:"];
  }
  return [
    "followed-publishers:uid:_:",
    ...userIds.map((id) => `followed-publishers:uid:${id}:`),
  ];
});

// Get all publishers followed by a user
followedPublishersRouter.get(
  "/followed-publishers/:userId",
  followedPublishersReadCache,
  getFollowedPublishers
);

// Follow a publisher
followedPublishersRouter.post(
  "/followed-publishers/follow",
  invalidateFollowedPublishersCache,
  followPublisher
);

// Unfollow a publisher
followedPublishersRouter.delete(
  "/followed-publishers/follow",
  invalidateFollowedPublishersCache,
  unfollowPublisher
);

// Check if user is following a publisher
followedPublishersRouter.get(
  "/followed-publishers/check/:userId/:publisherName",
  followedPublishersReadCache,
  checkFollowStatus
);

// Get follow count for a publisher
followedPublishersRouter.get(
  "/followed-publishers/count/:publisherName",
  followedPublishersReadCache,
  getPublisherFollowCount
);

export default followedPublishersRouter;
