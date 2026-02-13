import { Router } from "express";
import {
  cacheResponse,
  extractScopedUserIds,
  invalidateCache,
} from "../middleware/cache.middleware";
import {
  searchPodcasts,
  getTrendingPodcasts,
  getPodcastById,
  getPodcastEpisodes,
  searchEpisodes,
  getRecommendations,
  getSavedPodcasts,
  savePodcast,
  unsavePodcast,
  getListeningProgress,
  saveListeningProgress,
  getContinueListening,
  cleanupLegacyPodcasts,
  syncPodcasts,
  triggerBackgroundPodcastSync,
  reindexPodcastSearchTokens,
} from "../controllers/podcast.controller";

const podcastRouter = Router();
const podcastReadCache = cacheResponse({
  namespace: "podcasts",
  ttlSeconds: 120,
});
const invalidatePodcastUserCache = invalidateCache((req) => {
  const userIds = extractScopedUserIds(req);
  if (userIds.length === 0) {
    return [];
  }
  return userIds.map((id) => `podcasts:uid:${id}:`);
});
const invalidatePodcastGlobalCache = invalidateCache(["podcasts:uid:_:"]);

// Search and discovery
podcastRouter.get("/search", podcastReadCache, searchPodcasts);
podcastRouter.get("/trending", podcastReadCache, getTrendingPodcasts);
podcastRouter.get("/recommendations", podcastReadCache, getRecommendations);
podcastRouter.get("/episodes/search", podcastReadCache, searchEpisodes);

// Saved podcasts
podcastRouter.get("/saved", podcastReadCache, getSavedPodcasts);
podcastRouter.post("/saved", invalidatePodcastUserCache, savePodcast);
podcastRouter.delete("/saved/:podcastId", invalidatePodcastUserCache, unsavePodcast);

// Listening progress
podcastRouter.get("/progress", podcastReadCache, getListeningProgress);
podcastRouter.post("/progress", invalidatePodcastUserCache, saveListeningProgress);
podcastRouter.get("/continue-listening", podcastReadCache, getContinueListening);

// Maintenance
podcastRouter.post("/cleanup", invalidatePodcastGlobalCache, cleanupLegacyPodcasts);
podcastRouter.post("/sync", invalidatePodcastGlobalCache, syncPodcasts);
podcastRouter.post("/sync/background", invalidatePodcastGlobalCache, triggerBackgroundPodcastSync);
podcastRouter.post("/reindex-search", invalidatePodcastGlobalCache, reindexPodcastSearchTokens);

// Podcast details and episodes
podcastRouter.get("/:podcastId", podcastReadCache, getPodcastById);
podcastRouter.get("/:podcastId/episodes", podcastReadCache, getPodcastEpisodes);

export default podcastRouter;
