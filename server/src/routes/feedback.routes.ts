import { Router } from "express";
import {
  submitFeedback,
  getUserFeedback,
  getAllFeedback,
  updateFeedbackStatus,
} from "../controllers/feedback.controller";

const feedbackRouter = Router();

// Submit feedback
feedbackRouter.post("/feedback", submitFeedback);

// Get feedback history for a user
feedbackRouter.get("/feedback/user/:userId", getUserFeedback);

// Get all feedback (admin)
feedbackRouter.get("/feedback", getAllFeedback);

// Update feedback status (admin)
feedbackRouter.put("/feedback/:feedbackId/status", updateFeedbackStatus);

export default feedbackRouter;
