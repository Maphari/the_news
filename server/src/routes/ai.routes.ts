import { Router } from "express";
import { cacheResponse } from "../middleware/cache.middleware";
import { generateText, healthCheck, getMetadata } from "../controllers/ai.controller";

const router = Router();
const aiStatusReadCache = cacheResponse({
  namespace: "ai-status",
  ttlSeconds: 300,
});

// GET /api/v1/ai/health - Check server AI availability
router.get("/health", aiStatusReadCache, healthCheck);

// GET /api/v1/ai/metadata - AI pricing and cache settings
router.get("/metadata", aiStatusReadCache, getMetadata);

// POST /api/v1/ai/generate - Generate text with server AI
router.post("/generate", generateText);

export default router;
