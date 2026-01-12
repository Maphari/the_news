import { Router } from "express";
import { enrichArticle, generateAISummary } from "../controllers/article.enrichment.controller";

const router = Router();

// POST /api/v1/articles/enrich - Scrape full article content from URL
router.post("/enrich", enrichArticle);

// POST /api/v1/articles/ai-summary - Generate AI summary (premium feature)
router.post("/ai-summary", generateAISummary);

export default router;
