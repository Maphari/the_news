import { Router } from "express";
import { cacheResponse, invalidateCache } from "../middleware/cache.middleware";
import {
  createTtsPresign,
  getArticlePerspectives,
  getFeatureAggregate,
  getOfflineManifest,
  getWellnessReport,
  getWellnessSettings,
  updateWellnessSettings,
} from "../controllers/experience.controller";

const experienceRouter: Router = Router();
const experienceReadCache = cacheResponse({
  namespace: "experience",
  ttlSeconds: 300,
});
const invalidateExperienceCache = invalidateCache(["experience:uid:_:"]);

experienceRouter.get("/experience/wellness/:userId", experienceReadCache, getWellnessSettings);
experienceRouter.put(
  "/experience/wellness/:userId",
  invalidateExperienceCache,
  updateWellnessSettings
);
experienceRouter.get(
  "/experience/wellness/:userId/report",
  experienceReadCache,
  getWellnessReport
);

experienceRouter.get(
  "/experience/articles/:articleId/perspectives",
  experienceReadCache,
  getArticlePerspectives
);
experienceRouter.get(
  "/experience/offline/manifest/:userId",
  experienceReadCache,
  getOfflineManifest
);
experienceRouter.post("/experience/tts/presign", createTtsPresign);
experienceRouter.get("/experience/aggregate/:userId", experienceReadCache, getFeatureAggregate);

export default experienceRouter;
