import { Router } from "express";
import {
  getFollowedPublishers,
  followPublisher,
  unfollowPublisher,
  checkFollowStatus,
} from "../controllers/followed-publishers.controller";

const followedPublishersRouter = Router();

// Get all publishers followed by a user
followedPublishersRouter.get("/followed-publishers/:userId", getFollowedPublishers);

// Follow a publisher
followedPublishersRouter.post("/followed-publishers/follow", followPublisher);

// Unfollow a publisher
followedPublishersRouter.delete("/followed-publishers/follow", unfollowPublisher);

// Check if user is following a publisher
followedPublishersRouter.get("/followed-publishers/check/:userId/:publisherName", checkFollowStatus);

export default followedPublishersRouter;
