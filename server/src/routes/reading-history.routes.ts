import { Router } from "express";
import {
  getReadingHistory,
  addReadingHistory,
  getReadingAnalytics,
  clearReadingHistory,
} from "../controllers/reading-history.controller";

const router = Router();

// GET /user/reading-history/:userId - Get reading history
router.get("/reading-history/:userId", getReadingHistory);

// POST /user/reading-history - Add reading history entries
router.post("/reading-history", addReadingHistory);

// GET /user/analytics/:userId - Get reading analytics
router.get("/analytics/:userId", getReadingAnalytics);

// DELETE /user/reading-history/:userId - Clear reading history
router.delete("/reading-history/:userId", clearReadingHistory);

export default router;
