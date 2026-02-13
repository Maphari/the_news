import { Router } from "express";
import { cacheResponse, invalidateCache } from "../middleware/cache.middleware";
import {
  getDigests,
  createDigest,
  deleteDigest,
} from "../controllers/daily-digest.controller";

const digestRouter = Router();
const digestReadCache = cacheResponse({
  namespace: "digests",
  ttlSeconds: 300,
});
const invalidateDigestCache = invalidateCache(["digests:uid:_:"]);

// Get digests for a user
digestRouter.get("/digests/:userId", digestReadCache, getDigests);

// Create or update a digest
digestRouter.post("/digests", invalidateDigestCache, createDigest);

// Delete a digest
digestRouter.delete("/digests/:userId/:digestId", invalidateDigestCache, deleteDigest);

export default digestRouter;
