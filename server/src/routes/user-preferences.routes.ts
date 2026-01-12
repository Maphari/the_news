import { Router } from "express";
import {
  getUserPreferences,
  updateUserPreferences,
  deleteUserPreferences,
} from "../controllers/user-preferences.controller";

const router = Router();

// GET /user/preferences/:userId - Get user preferences
router.get("/preferences/:userId", getUserPreferences);

// PUT /user/preferences - Update user preferences
router.put("/preferences", updateUserPreferences);

// DELETE /user/preferences/:userId - Delete user preferences
router.delete("/preferences/:userId", deleteUserPreferences);

export default router;
