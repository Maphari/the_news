import { Router } from "express";
import {
  getEngagement,
  likeArticle,
  unlikeArticle,
  shareArticle,
  updateCommentCount,
} from "../controllers/engagement.controller";

const engagementRouter = Router();

// Get engagement data for an article
engagementRouter.get("/engagement/:articleId", getEngagement);

// Like an article
engagementRouter.post("/engagement/like", likeArticle);

// Unlike an article
engagementRouter.delete("/engagement/like", unlikeArticle);

// Share an article
engagementRouter.post("/engagement/share", shareArticle);

// Update comment count
engagementRouter.put("/engagement/comments/:articleId", updateCommentCount);

export default engagementRouter;
