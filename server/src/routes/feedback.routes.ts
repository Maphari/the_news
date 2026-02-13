import { Router } from "express";
import {
  cacheResponse,
  extractScopedUserIds,
  invalidateCache,
} from "../middleware/cache.middleware";
import {
  submitFeedback,
  getUserFeedback,
  getAllFeedback,
  updateFeedbackStatus,
} from "../controllers/feedback.controller";

const feedbackRouter = Router();
const feedbackReadCache = cacheResponse({
  namespace: "feedback",
  ttlSeconds: 300,
});
const invalidateFeedbackCache = invalidateCache((req) => {
  const userIds = extractScopedUserIds(req);
  if (userIds.length === 0) {
    return ["feedback:uid:_:"];
  }
  return ["feedback:uid:_:", ...userIds.map((id) => `feedback:uid:${id}:`)];
});

// Submit feedback
feedbackRouter.post("/feedback", invalidateFeedbackCache, submitFeedback);

// Get feedback history for a user
feedbackRouter.get("/feedback/user/:userId", feedbackReadCache, getUserFeedback);

// Get all feedback (admin)
feedbackRouter.get("/feedback", feedbackReadCache, getAllFeedback);

// Update feedback status (admin)
feedbackRouter.put(
  "/feedback/:feedbackId/status",
  invalidateFeedbackCache,
  updateFeedbackStatus
);

export default feedbackRouter;
