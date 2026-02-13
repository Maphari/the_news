import { Request, Response } from "express";
import { db } from "../config/firebase.connection";
import { Timestamp } from "firebase-admin/firestore";
import {
  Podcast,
  Episode,
  SavedPodcast,
  ListeningProgress,
} from "../models/podcast.model";
import podchaserService from "../services/podchaser.service";

// Firestore collections
const podcastsCollection = db.collection("podcasts");
const episodesCollection = db.collection("episodes");
const savedPodcastsCollection = db.collection("savedPodcasts");
const listeningProgressCollection = db.collection("listeningProgress");
const followedPublishersCollection = db.collection("followedPublishers");

// Check if Podchaser API is configured
const USE_REAL_API = podchaserService.isConfigured();

const NEWS_CATEGORIES = [
  "News",
  "Daily News",
  "World News",
  "Politics",
  "Business",
  "Finance",
  "Economy",
  "Technology",
  "Science",
  "Education",
  "Culture",
  "Environment",
  "Government",
  "Current Events",
  "News & Politics",
  "Business News",
  "Entrepreneurship",
  "Investing",
  "Tech News",
  "Science & Technology",
  "Health & Fitness",
  "Mental Health",
  "Medicine",
  "Natural Sciences",
  "TV & Film",
  "Music",
  "News Commentary",
];

const NEWS_CATEGORY_SET = new Set(NEWS_CATEGORIES.map((category) => category.toLowerCase()));
const ALLOWED_SOURCES = new Set(["podchaser", "manual"]);
const LEGACY_SOURCES = ["podcast_index", "sample"];

type CacheEntry<T> = {
  value: T;
  expiresAtMs: number;
};

const RESPONSE_TTLS_MS = {
  trending: 3 * 60 * 1000,
  search: 2 * 60 * 1000,
  podcastById: 10 * 60 * 1000,
  episodes: 5 * 60 * 1000,
};

const FALLBACK_COOLDOWNS_MS = {
  trending: 10 * 60 * 1000,
  searchMiss: 2 * 60 * 1000,
  podcastByIdMiss: 10 * 60 * 1000,
  episodesMiss: 10 * 60 * 1000,
};

const trendingCache = new Map<string, CacheEntry<Podcast[]>>();
const podcastSearchCache = new Map<string, CacheEntry<Podcast[]>>();
const podcastByIdCache = new Map<string, CacheEntry<Podcast | null>>();
const podcastEpisodesCache = new Map<string, CacheEntry<Episode[]>>();
const apiFallbackCooldownUntil = new Map<string, number>();

const trendingApiInFlight = new Map<string, Promise<Podcast[]>>();
const searchApiInFlight = new Map<string, Promise<Podcast[]>>();
const podcastByIdApiInFlight = new Map<string, Promise<Podcast | null>>();
const episodesApiInFlight = new Map<string, Promise<Episode[]>>();
let backgroundSyncInFlight: Promise<{ totalSynced: number; categories: string[] }> | null = null;

function getCachedValue<T>(cache: Map<string, CacheEntry<T>>, key: string): T | null {
  const entry = cache.get(key);
  if (!entry) return null;
  if (Date.now() >= entry.expiresAtMs) {
    cache.delete(key);
    return null;
  }
  return entry.value;
}

function setCachedValue<T>(cache: Map<string, CacheEntry<T>>, key: string, value: T, ttlMs: number) {
  cache.set(key, {
    value,
    expiresAtMs: Date.now() + ttlMs,
  });
}

function isApiFallbackCoolingDown(key: string): boolean {
  const until = apiFallbackCooldownUntil.get(key);
  if (!until) return false;
  if (Date.now() >= until) {
    apiFallbackCooldownUntil.delete(key);
    return false;
  }
  return true;
}

function setApiFallbackCooldown(key: string, durationMs: number) {
  apiFallbackCooldownUntil.set(key, Date.now() + durationMs);
}

function normalizeSearchText(input: string): string {
  return input.trim().toLowerCase().replace(/\s+/g, " ");
}

function makeSearchCacheKey(query: string, genres: string[], limit: number, offset: number): string {
  return `${query}|${genres.map((g) => g.toLowerCase()).sort().join(",")}|${limit}|${offset}`;
}

function makeTrendingCacheKey(genres: string[], limit: number): string {
  return `${genres.map((g) => g.toLowerCase()).sort().join(",")}|${limit}`;
}

function normalizeTokenSource(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function buildSearchTokensFromPodcast(podcast: Omit<Podcast, "createdAt" | "updatedAt">): string[] {
  const sourceParts = [
    podcast.title || "",
    podcast.publisher || "",
    ...(podcast.categories || []),
  ];
  const tokens = new Set<string>();

  for (const part of sourceParts) {
    const normalized = normalizeTokenSource(part);
    if (!normalized) continue;
    const words = normalized.split(" ").filter((word) => word.length >= 2);

    for (const word of words) {
      const maxPrefixLength = Math.min(word.length, 24);
      for (let i = 2; i <= maxPrefixLength; i += 1) {
        tokens.add(word.slice(0, i));
        if (tokens.size >= 300) break;
      }
      if (tokens.size >= 300) break;
    }
    if (tokens.size >= 300) break;
  }

  return [...tokens];
}

function buildSearchQueryTokens(query: string): string[] {
  const normalized = normalizeTokenSource(query);
  if (!normalized) return [];
  const words = normalized.split(" ").filter((word) => word.length >= 2);
  return [...new Set(words.map((word) => word.slice(0, Math.min(word.length, 24))))].slice(0, 10);
}

function timestampToIso(value: Timestamp | undefined): string | null {
  if (!value) return null;
  return value.toDate().toISOString();
}

function scorePodcastForQuery(podcast: Podcast, query: string, queryTokens: string[]): number {
  const title = podcast.title.toLowerCase();
  const publisher = podcast.publisher.toLowerCase();
  const description = podcast.description.toLowerCase();
  const categories = (podcast.categories || []).map((c) => c.toLowerCase());
  let score = 0;

  if (title === query) score += 120;
  if (title.startsWith(query)) score += 80;
  if (title.includes(query)) score += 35;
  if (publisher.startsWith(query)) score += 30;
  if (publisher.includes(query)) score += 15;
  if (description.includes(query)) score += 8;

  for (const token of queryTokens) {
    if (title.includes(token)) score += 10;
    if (publisher.includes(token)) score += 6;
    if (categories.some((category) => category.includes(token))) score += 4;
  }

  const rating = podcast.rating || 0;
  const ratingCount = podcast.ratingCount || 0;
  score += rating * 2;
  score += Math.log10(ratingCount + 1) * 2.5;

  return score;
}

function setPublicCache(res: Response, maxAgeSeconds = 180, staleSeconds = 900) {
  res.set("Cache-Control", `public, max-age=${maxAgeSeconds}, stale-while-revalidate=${staleSeconds}`);
}

function setPrivateCache(res: Response, maxAgeSeconds = 60, staleSeconds = 180) {
  res.set("Cache-Control", `private, max-age=${maxAgeSeconds}, stale-while-revalidate=${staleSeconds}`);
}

/**
 * Transform podcast from database format to API response format
 */
function transformPodcastForResponse(podcast: Podcast): Record<string, unknown> {
  return {
    id: podcast.id,
    title: podcast.title,
    description: podcast.description,
    publisher: podcast.publisher,
    imageUrl: podcast.imageUrl,
    categories: podcast.categories,
    totalEpisodes: podcast.totalEpisodes,
    website: podcast.website,
    rssUrl: podcast.feedUrl,
    rating: podcast.rating,
    ratingCount: podcast.ratingCount,
    language: podcast.language,
  };
}

/**
 * Transform episode from database format to API response format
 */
function transformEpisodeForResponse(episode: Episode): Record<string, unknown> {
  return {
    id: episode.id,
    podcastId: episode.podcastId,
    podcastTitle: episode.podcastTitle,
    title: episode.title,
    description: episode.description,
    audioUrl: episode.audioUrl,
    durationSeconds: episode.durationSeconds,
    publishedDate: episode.publishedDate instanceof Timestamp
      ? episode.publishedDate.toDate().toISOString()
      : new Date().toISOString(),
    imageUrl: episode.imageUrl,
    podcastImageUrl: episode.podcastImageUrl,
    isExplicit: episode.isExplicit,
  };
}

function isNewsPodcast(podcast: Podcast | Omit<Podcast, "createdAt" | "updatedAt">): boolean {
  if (!podcast.categories || podcast.categories.length === 0) {
    return true;
  }

  return podcast.categories.some((category) => NEWS_CATEGORY_SET.has(category.toLowerCase()));
}

function isAllowedSource(podcast: Podcast | Omit<Podcast, "createdAt" | "updatedAt">): boolean {
  const source = (podcast as Podcast).source ?? "";
  return ALLOWED_SOURCES.has(source);
}

async function deleteCollectionDocs(query: FirebaseFirestore.Query) {
  const snapshot = await query.get();
  if (snapshot.empty) return 0;

  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  return snapshot.size;
}

function getEffectiveGenres(genres: string[]): string[] {
  if (genres.length === 0) {
    return NEWS_CATEGORIES;
  }

  const filtered = genres.filter((genre) => NEWS_CATEGORY_SET.has(genre.toLowerCase()));
  return filtered;
}

/**
 * Save podcasts to database (batch operation)
 */
async function savePodcastsToDatabase(podcasts: Omit<Podcast, 'createdAt' | 'updatedAt'>[]): Promise<number> {
  const filteredPodcasts = podcasts.filter(isNewsPodcast);
  if (filteredPodcasts.length === 0) return 0;

  const now = Timestamp.now();
  const batch = db.batch();
  let upsertCount = 0;

  // Get existing podcast refs by podcast ID
  const existingRefsByPodcastId = new Map<string, FirebaseFirestore.DocumentReference>();
  const ids = filteredPodcasts.map((p) => p.id);
  for (let i = 0; i < ids.length; i += 10) {
    const chunk = ids.slice(i, i + 10);
    const existingSnapshot = await podcastsCollection
      .where("id", "in", chunk)
      .select("id")
      .get();
    existingSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      if (data.id) existingRefsByPodcastId.set(data.id, doc.ref);
    });
  }

  for (const podcast of filteredPodcasts) {
    const searchTokens = buildSearchTokensFromPodcast(podcast);
    const existingRef = existingRefsByPodcastId.get(podcast.id);

    if (existingRef) {
      batch.set(existingRef, {
        ...podcast,
        searchTokens,
        updatedAt: now,
      }, { merge: true });
      upsertCount++;
      continue;
    }

    const podcastData: Podcast = {
      ...podcast,
      searchTokens,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = podcastsCollection.doc();
    batch.set(docRef, podcastData);
    upsertCount++;
  }

  if (upsertCount > 0) {
    await batch.commit();
  }

  return upsertCount;
}

/**
 * Save episodes to database (batch operation)
 */
async function saveEpisodesToDatabase(episodes: Omit<Episode, 'createdAt' | 'updatedAt'>[]): Promise<number> {
  if (episodes.length === 0) return 0;

  const now = Timestamp.now();
  const batch = db.batch();
  let savedCount = 0;

  for (const episode of episodes) {
    const episodeData: Episode = {
      ...episode,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = episodesCollection.doc();
    batch.set(docRef, episodeData);
    savedCount++;
  }

  if (savedCount > 0) {
    await batch.commit();
  }

  return savedCount;
}


/**
 * Fetch podcasts from API and save to database
 */
async function syncPodcastsFromApi(category?: string, limit: number = 20): Promise<Podcast[]> {
  if (!USE_REAL_API) {
    console.log("Podchaser API not configured");
    return [];
  }

  try {
    const effectiveCategory = category && NEWS_CATEGORY_SET.has(category.toLowerCase())
      ? category
      : "News";
    const apiPodcasts = await podchaserService.getTrendingPodcasts(limit, effectiveCategory);

    if (!apiPodcasts || apiPodcasts.length === 0) {
      console.warn("Podchaser API returned empty results");
      return [];
    }

    // Transform API podcasts to our format
    const podcasts: Omit<Podcast, 'createdAt' | 'updatedAt'>[] = apiPodcasts.map(p => {
      const transformed = podchaserService.transformPodcast(p);
      return {
        id: transformed.id,
        podcastIndexId: transformed.id,
        title: transformed.title,
        description: transformed.description,
        publisher: transformed.publisher,
        imageUrl: transformed.imageUrl,
        categories: transformed.categories,
        totalEpisodes: transformed.totalEpisodes,
        website: transformed.website,
        language: transformed.language,
        isExplicit: false,
        source: "podchaser" as const,
      };
    }).filter(isNewsPodcast);

    // Save to database
    const savedCount = await savePodcastsToDatabase(podcasts);
    console.log(`✅ Synced ${savedCount} podcasts from Podchaser API`);

    return podcasts as Podcast[];
  } catch (error) {
    console.error("Error syncing podcasts from API:", error);
    return [];
  }
}

// ==================== API ENDPOINTS ====================

/**
 * Get trending podcasts
 * GET /api/v1/podcasts/trending
 *
 * Strategy: Load from database first, sync from API if empty
 */
export const getTrendingPodcasts = async (req: Request, res: Response) => {
  try {
    setPublicCache(res, 180, 900);
    const { genres, limit = "20" } = req.query;
    const genreList = genres ? (genres as string).split(",") : [];
    const limitNum = parseInt(limit as string, 10);
    const effectiveGenres = getEffectiveGenres(genreList);
    const cacheKey = makeTrendingCacheKey(effectiveGenres, limitNum);

    if (genreList.length > 0 && effectiveGenres.length === 0) {
      return res.status(200).json({
        success: true,
        podcasts: [],
        count: 0,
        source: "database",
      });
    }

    const cached = getCachedValue(trendingCache, cacheKey);
    if (cached) {
      const transformedPodcasts = cached.map(transformPodcastForResponse);
      return res.status(200).json({
        success: true,
        podcasts: transformedPodcasts,
        count: transformedPodcasts.length,
        source: "cache",
      });
    }

    const genreSet = new Set(effectiveGenres.map((genre) => genre.toLowerCase()));
    const matchesGenre = (podcast: { categories?: string[] }) =>
      !podcast.categories || podcast.categories.length === 0
        ? true
        : podcast.categories.some((category) => genreSet.has(category.toLowerCase()));

    // 1. Try to load from database first
    let query = podcastsCollection.orderBy("rating", "desc").limit(limitNum);

    // Filter by category if specified
    if (effectiveGenres.length > 0) {
      query = podcastsCollection
        .where("categories", "array-contains-any", effectiveGenres.slice(0, 10))
        .orderBy("rating", "desc")
        .limit(limitNum);
    }

    let podcasts: Podcast[] = [];
    try {
      const snapshot = await query.get();
      podcasts = snapshot.docs.map(doc => doc.data() as Podcast);
      podcasts = podcasts.filter((podcast) => matchesGenre(podcast) && isAllowedSource(podcast));
    } catch (error: any) {
      if (error?.code === 9) {
        console.warn("⚠️ Missing Firestore index for podcasts query. Falling back to API.");
        podcasts = [];
      } else {
        throw error;
      }
    }

    // 2. If database is empty, try API data
    if (podcasts.length === 0 && USE_REAL_API) {
      const fallbackKey = `trending:${cacheKey}`;
      if (!isApiFallbackCoolingDown(fallbackKey)) {
        console.log("📚 No podcasts in database, syncing...");
        if (!trendingApiInFlight.has(cacheKey)) {
          trendingApiInFlight.set(cacheKey, syncPodcastsFromApi(effectiveGenres[0], limitNum));
        }

        try {
          const apiPodcasts = await trendingApiInFlight.get(cacheKey)!;
          if (apiPodcasts.length > 0) {
            podcasts = apiPodcasts.filter(matchesGenre);
          } else {
            setApiFallbackCooldown(fallbackKey, FALLBACK_COOLDOWNS_MS.trending);
          }
        } finally {
          trendingApiInFlight.delete(cacheKey);
        }
      } else {
        console.log("⏳ Skipping trending API fallback due to active cooldown");
      }
    }

    // Transform for response
    setCachedValue(trendingCache, cacheKey, podcasts, RESPONSE_TTLS_MS.trending);
    const transformedPodcasts = podcasts.map(transformPodcastForResponse);

    return res.status(200).json({
      success: true,
      podcasts: transformedPodcasts,
      count: transformedPodcasts.length,
      source: "database",
    });
  } catch (error) {
    console.error("Error getting trending podcasts:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get trending podcasts",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Search podcasts
 * GET /api/v1/podcasts/search
 *
 * Strategy: Search database first, fall back to API if no results
 */
export const searchPodcasts = async (req: Request, res: Response) => {
  try {
    setPublicCache(res, 120, 600);
    const { q, genres, limit = "20", offset = "0" } = req.query;
    const query = normalizeSearchText((q as string) || "");
    const genreList = genres ? (genres as string).split(",") : [];
    const limitNum = parseInt(limit as string, 10);
    const offsetNum = parseInt(offset as string, 10);
    const effectiveGenres = getEffectiveGenres(genreList);
    const searchCacheKey = makeSearchCacheKey(query, effectiveGenres, limitNum, offsetNum);

    if (genreList.length > 0 && effectiveGenres.length === 0) {
      return res.status(200).json({
        success: true,
        podcasts: [],
        total: 0,
        offset: offsetNum,
        limit: limitNum,
        source: "database",
      });
    }

    const genreSet = new Set(effectiveGenres.map((genre) => genre.toLowerCase()));
    const matchesGenre = (podcast: { categories?: string[] }) =>
      !podcast.categories || podcast.categories.length === 0
        ? true
        : podcast.categories.some((category) => genreSet.has(category.toLowerCase()));

    if (!query) {
      // If no search query, return trending
      return getTrendingPodcasts(req, res);
    }

    if (query.length < 2) {
      return res.status(200).json({
        success: true,
        podcasts: [],
        total: 0,
        offset: offsetNum,
        limit: limitNum,
        source: "database",
      });
    }

    const cached = getCachedValue(podcastSearchCache, searchCacheKey);
    if (cached) {
      const transformedPodcasts = cached.map(transformPodcastForResponse);
      return res.status(200).json({
        success: true,
        podcasts: transformedPodcasts,
        total: cached.length,
        offset: offsetNum,
        limit: limitNum,
        source: "cache",
      });
    }

    // 1. Search in database first using token index
    const queryTokens = buildSearchQueryTokens(query);
    if (queryTokens.length === 0) {
      return res.status(200).json({
        success: true,
        podcasts: [],
        total: 0,
        offset: offsetNum,
        limit: limitNum,
        source: "database",
      });
    }

    let podcasts: Podcast[] = [];
    try {
      const snapshot = await podcastsCollection
        .where("searchTokens", "array-contains-any", queryTokens)
        .limit(Math.max(limitNum * 5, 50))
        .get();

      podcasts = snapshot.docs
        .map((doc) => doc.data() as Podcast)
        .filter((podcast) =>
          podcast.title.toLowerCase().includes(query) ||
          podcast.description.toLowerCase().includes(query) ||
          podcast.publisher.toLowerCase().includes(query)
        );
    } catch (error: any) {
      if (error?.code === 9) {
        console.warn("⚠️ Missing Firestore index for podcast token search. Falling back to API.");
      } else {
        throw error;
      }
    }

    podcasts = podcasts.filter((podcast) => matchesGenre(podcast) && isAllowedSource(podcast));
    podcasts = podcasts
      .map((podcast) => ({
        podcast,
        score: scorePodcastForQuery(podcast, query, queryTokens),
      }))
      .sort((a, b) => b.score - a.score)
      .map(({ podcast }) => podcast);

    // 2. If no results in database, try API
    if (podcasts.length === 0 && USE_REAL_API) {
      const fallbackKey = `search:${query}:${effectiveGenres.join(",")}`;
      if (!isApiFallbackCoolingDown(fallbackKey)) {
        console.log(`🔍 No database results for "${query}", searching API...`);

        if (!searchApiInFlight.has(searchCacheKey)) {
          searchApiInFlight.set(
            searchCacheKey,
            (async () => {
              const apiPodcasts = await podchaserService.searchNewsPodcasts(query, limitNum);
              if (!apiPodcasts || apiPodcasts.length === 0) return [];
              return apiPodcasts.map((p) => {
                const transformed = podchaserService.transformPodcast(p);
                return {
                  id: transformed.id,
                  podcastIndexId: transformed.id,
                  title: transformed.title,
                  description: transformed.description,
                  publisher: transformed.publisher,
                  imageUrl: transformed.imageUrl,
                  categories: transformed.categories,
                  totalEpisodes: transformed.totalEpisodes,
                  website: transformed.website,
                  language: transformed.language,
                  isExplicit: false,
                  source: "podchaser" as const,
                } as Omit<Podcast, "createdAt" | "updatedAt">;
              }).filter(matchesGenre) as Podcast[];
            })(),
          );
        }

        try {
          const transformedPodcasts = await searchApiInFlight.get(searchCacheKey)!;
          if (transformedPodcasts.length > 0) {
            await savePodcastsToDatabase(transformedPodcasts as Omit<Podcast, "createdAt" | "updatedAt">[]);
            podcasts = transformedPodcasts;
            console.log(`✅ Found ${podcasts.length} podcasts from API, saved to database`);
          } else {
            setApiFallbackCooldown(fallbackKey, FALLBACK_COOLDOWNS_MS.searchMiss);
          }
        } catch (apiError) {
          console.warn("Podchaser API search failed:", apiError);
          setApiFallbackCooldown(fallbackKey, FALLBACK_COOLDOWNS_MS.searchMiss);
        } finally {
          searchApiInFlight.delete(searchCacheKey);
        }
      } else {
        console.log(`⏳ Skipping API search fallback for "${query}" due to cooldown`);
      }
    }

    // Apply pagination
    const paginatedPodcasts = podcasts.slice(offsetNum, offsetNum + limitNum);
    setCachedValue(podcastSearchCache, searchCacheKey, paginatedPodcasts, RESPONSE_TTLS_MS.search);
    const transformedPodcasts = paginatedPodcasts.map(transformPodcastForResponse);

    return res.status(200).json({
      success: true,
      podcasts: transformedPodcasts,
      total: podcasts.length,
      offset: offsetNum,
      limit: limitNum,
      source: "database",
    });
  } catch (error) {
    console.error("Error searching podcasts:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to search podcasts",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get podcast by ID
 * GET /api/v1/podcasts/:podcastId
 */
export const getPodcastById = async (req: Request, res: Response) => {
  try {
    setPublicCache(res, 600, 1800);
    const podcastId = req.params.podcastId as string;
    const cached = getCachedValue(podcastByIdCache, podcastId);
    if (cached) {
      return res.status(200).json({
        success: true,
        podcast: transformPodcastForResponse(cached),
        source: "cache",
      });
    }

    // 1. Search in database first
    const snapshot = await podcastsCollection.where("id", "==", podcastId).limit(1).get();

    if (!snapshot.empty) {
      const podcast = snapshot.docs[0].data() as Podcast;
      if (!isNewsPodcast(podcast)) {
        return res.status(404).json({
          success: false,
          message: "Podcast not found",
        });
      }
      setCachedValue(podcastByIdCache, podcastId, podcast, RESPONSE_TTLS_MS.podcastById);
      return res.status(200).json({
        success: true,
        podcast: transformPodcastForResponse(podcast),
        source: "database",
      });
    }

    // 2. Try API if not in database
    const fallbackKey = `podcastById:${podcastId}`;
    if (USE_REAL_API && !isApiFallbackCoolingDown(fallbackKey)) {
      if (!podcastByIdApiInFlight.has(podcastId)) {
        podcastByIdApiInFlight.set(
          podcastId,
          (async () => {
            const apiPodcast = await podchaserService.getPodcastById(podcastId);
            if (!apiPodcast) return null;
            const transformed = podchaserService.transformPodcast(apiPodcast);
            const podcastData: Omit<Podcast, "createdAt" | "updatedAt"> = {
              id: transformed.id,
              podcastIndexId: transformed.id,
              title: transformed.title,
              description: transformed.description,
              publisher: transformed.publisher,
              imageUrl: transformed.imageUrl,
              categories: transformed.categories,
              totalEpisodes: transformed.totalEpisodes,
              website: transformed.website,
              language: transformed.language,
              isExplicit: false,
              source: "podchaser",
            };
            if (!isNewsPodcast(podcastData)) return null;
            await savePodcastsToDatabase([podcastData]);
            return podcastData as Podcast;
          })(),
        );
      }

      try {
        const podcast = await podcastByIdApiInFlight.get(podcastId)!;
        if (podcast) {
          setCachedValue(podcastByIdCache, podcastId, podcast, RESPONSE_TTLS_MS.podcastById);
          return res.status(200).json({
            success: true,
            podcast: transformPodcastForResponse(podcast),
            source: "podchaser",
          });
        }
        setApiFallbackCooldown(fallbackKey, FALLBACK_COOLDOWNS_MS.podcastByIdMiss);
      } catch (apiError) {
        console.warn("Podchaser API error:", apiError);
        setApiFallbackCooldown(fallbackKey, FALLBACK_COOLDOWNS_MS.podcastByIdMiss);
      } finally {
        podcastByIdApiInFlight.delete(podcastId);
      }
    } else if (USE_REAL_API) {
      console.log(`⏳ Skipping podcast API fallback for ${podcastId} due to cooldown`);
    }

    return res.status(404).json({
      success: false,
      message: "Podcast not found",
    });
  } catch (error) {
    console.error("Error getting podcast:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get podcast",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get episodes for a podcast
 * GET /api/v1/podcasts/:podcastId/episodes
 */
export const getPodcastEpisodes = async (req: Request, res: Response) => {
  try {
    setPublicCache(res, 300, 1200);
    const podcastId = req.params.podcastId as string;
    const { limit = "20", offset = "0", cursor } = req.query;
    const limitNum = parseInt(limit as string, 10);
    const offsetNum = parseInt(offset as string, 10);
    const cursorValue = (cursor as string | undefined)?.trim();
    const useCursor = !!cursorValue;
    let cursorTimestamp: Timestamp | null = null;

    if (useCursor) {
      const parsed = new Date(cursorValue!);
      if (Number.isNaN(parsed.getTime())) {
        return res.status(400).json({
          success: false,
          message: "Invalid cursor format. Expected ISO timestamp.",
        });
      }
      cursorTimestamp = Timestamp.fromDate(parsed);
    }

    const cacheKey = `${podcastId}:${limitNum}:${useCursor ? `cursor:${cursorValue}` : `offset:${offsetNum}`}`;
    const cached = getCachedValue(podcastEpisodesCache, cacheKey);
    if (cached) {
      const transformedEpisodes = cached.map(transformEpisodeForResponse);
      const nextCursor = cached.length === limitNum && cached.length > 0
        ? timestampToIso(cached[cached.length - 1].publishedDate)
        : null;
      return res.status(200).json({
        success: true,
        episodes: transformedEpisodes,
        total: transformedEpisodes.length,
        offset: useCursor ? undefined : offsetNum,
        limit: limitNum,
        nextCursor,
        source: "cache",
      });
    }

    // 1. Search in database first (order by publishedDate desc)
    let episodes: Episode[] = [];
    try {
      let query = episodesCollection
        .where("podcastId", "==", podcastId)
        .orderBy("publishedDate", "desc")
        .limit(limitNum);

      if (useCursor && cursorTimestamp) {
        query = query.startAfter(cursorTimestamp);
      } else if (offsetNum > 0) {
        query = query.offset(offsetNum);
      }

      const snapshot = await query.get();

      episodes = snapshot.docs.map(doc => doc.data() as Episode);
    } catch (error: any) {
      // Firestore composite index missing (code 9)
      if (error?.code === 9) {
        console.warn("⚠️ Missing Firestore index for episodes query. Falling back to in-memory sort.");
        const fallbackSnapshot = await episodesCollection
          .where("podcastId", "==", podcastId)
          .get();

        episodes = fallbackSnapshot.docs.map(doc => doc.data() as Episode);
        episodes.sort((a, b) => {
          const aDate = a.publishedDate instanceof Timestamp
            ? a.publishedDate.toDate().getTime()
            : new Date().getTime();
          const bDate = b.publishedDate instanceof Timestamp
            ? b.publishedDate.toDate().getTime()
            : new Date().getTime();
          return bDate - aDate;
        });

        if (useCursor && cursorTimestamp) {
          const cursorDateMs = cursorTimestamp.toDate().getTime();
          episodes = episodes.filter((episode) => {
            const publishedMs = episode.publishedDate instanceof Timestamp
              ? episode.publishedDate.toDate().getTime()
              : 0;
            return publishedMs < cursorDateMs;
          });
          episodes = episodes.slice(0, limitNum);
        } else {
          episodes = episodes.slice(offsetNum, offsetNum + limitNum);
        }
      } else {
        throw error;
      }
    }

    // 2. If no episodes in database, try API
    if (episodes.length === 0 && USE_REAL_API) {
      const fallbackKey = `episodes:${podcastId}:${limitNum}`;
      if (!isApiFallbackCoolingDown(fallbackKey)) {
        if (!episodesApiInFlight.has(fallbackKey)) {
          episodesApiInFlight.set(
            fallbackKey,
            (async () => {
              const apiEpisodes = await podchaserService.getEpisodes(podcastId, limitNum);
              if (!apiEpisodes || apiEpisodes.length === 0) return [];
              const transformedEpisodes: Omit<Episode, "createdAt" | "updatedAt">[] = apiEpisodes.map((e) => {
                const transformed = podchaserService.transformEpisode(e);
                return {
                  id: transformed.id,
                  podcastIndexId: transformed.id,
                  podcastId: transformed.podcastId,
                  podcastTitle: transformed.podcastTitle,
                  title: transformed.title,
                  description: transformed.description,
                  audioUrl: transformed.audioUrl,
                  durationSeconds: transformed.durationSeconds,
                  publishedDate: Timestamp.fromDate(new Date(transformed.publishedDate)),
                  imageUrl: transformed.imageUrl,
                  podcastImageUrl: transformed.podcastImageUrl,
                  isExplicit: transformed.isExplicit,
                  source: "podchaser" as const,
                };
              });
              await saveEpisodesToDatabase(transformedEpisodes);
              return transformedEpisodes as Episode[];
            })(),
          );
        }

        try {
          episodes = await episodesApiInFlight.get(fallbackKey)!;
          if (episodes.length > 0) {
            console.log(`✅ Loaded ${episodes.length} episodes from API`);
          } else {
            setApiFallbackCooldown(fallbackKey, FALLBACK_COOLDOWNS_MS.episodesMiss);
          }
        } catch (apiError) {
          console.warn("Podchaser API episodes error:", apiError);
          setApiFallbackCooldown(fallbackKey, FALLBACK_COOLDOWNS_MS.episodesMiss);
        } finally {
          episodesApiInFlight.delete(fallbackKey);
        }
      } else {
        console.log(`⏳ Skipping episodes API fallback for ${podcastId} due to cooldown`);
      }
    }

    setCachedValue(podcastEpisodesCache, cacheKey, episodes, RESPONSE_TTLS_MS.episodes);
    const transformedEpisodes = episodes.map(transformEpisodeForResponse);
    const nextCursor = episodes.length === limitNum
      ? timestampToIso(episodes[episodes.length - 1]?.publishedDate)
      : null;

    return res.status(200).json({
      success: true,
      episodes: transformedEpisodes,
      total: transformedEpisodes.length,
      offset: useCursor ? undefined : offsetNum,
      limit: limitNum,
      nextCursor,
      source: "database",
    });
  } catch (error) {
    console.error("Error getting episodes:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get episodes",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Search episodes
 * GET /api/v1/podcasts/episodes/search
 */
export const searchEpisodes = async (req: Request, res: Response) => {
  try {
    setPublicCache(res, 120, 600);
    const { q, limit = "20", offset = "0" } = req.query;
    const query = (q as string || "").toLowerCase();
    const limitNum = parseInt(limit as string, 10);
    const offsetNum = parseInt(offset as string, 10);

    // Search in database
    const snapshot = await episodesCollection.get();
    let episodes = snapshot.docs
      .map(doc => doc.data() as Episode)
      .filter(episode =>
        episode.title.toLowerCase().includes(query) ||
        episode.description.toLowerCase().includes(query)
      );

    // Apply pagination
    const paginatedEpisodes = episodes.slice(offsetNum, offsetNum + limitNum);
    const transformedEpisodes = paginatedEpisodes.map(transformEpisodeForResponse);

    return res.status(200).json({
      success: true,
      episodes: transformedEpisodes,
      total: episodes.length,
      offset: offsetNum,
      limit: limitNum,
    });
  } catch (error) {
    console.error("Error searching episodes:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to search episodes",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get recommendations based on genres
 * GET /api/v1/podcasts/recommendations
 */
export const getRecommendations = async (req: Request, res: Response) => {
  try {
    const { genres, limit = "10" } = req.query;
    const userId = (req.query.userId as string) || (req.headers["x-user-id"] as string);
    if (userId) {
      setPrivateCache(res, 90, 300);
    } else {
      setPublicCache(res, 120, 600);
    }
    const limitNum = parseInt(limit as string, 10);

    if (!userId) {
      const genreList = genres ? (genres as string).split(",") : ["News"];
      const effectiveGenres = getEffectiveGenres(genreList);

      if (genreList.length > 0 && effectiveGenres.length === 0) {
        return res.status(200).json({
          success: true,
          podcasts: [],
        });
      }

      const snapshot = await podcastsCollection
        .where("categories", "array-contains-any", effectiveGenres.slice(0, 10))
        .limit(limitNum * 2)
        .get();

      let podcasts = snapshot.docs.map(doc => doc.data() as Podcast);
      const genreSet = new Set(effectiveGenres.map((genre) => genre.toLowerCase()));
      podcasts = podcasts.filter((podcast) =>
        podcast.categories?.some((category) => genreSet.has(category.toLowerCase()))
      );

      podcasts = podcasts.sort(() => Math.random() - 0.5).slice(0, limitNum);
      const transformedPodcasts = podcasts.map(transformPodcastForResponse);

      return res.status(200).json({
        success: true,
        podcasts: transformedPodcasts,
      });
    }

    const [
      progressSnap,
      savedSnap,
      followedSnap,
    ] = await Promise.all([
      listeningProgressCollection.where("userId", "==", userId).get(),
      savedPodcastsCollection.where("userId", "==", userId).get(),
      followedPublishersCollection.where("userId", "==", userId).get(),
    ]);

    const progress = progressSnap.docs.map((doc) => doc.data() as ListeningProgress);
    const saved = savedSnap.docs.map((doc) => doc.data() as SavedPodcast);
    const followedPublishers = new Set(
      followedSnap.docs.map((doc) => (doc.data() as any).publisherName as string),
    );

    const categoryScores = new Map<string, number>();
    const publisherScores = new Map<string, number>();
    const listenedPodcastIds = new Set<string>();
    const savedPodcastIds = new Set<string>();

    const now = Date.now();

    const progressWeightsByPodcast = new Map<string, number>();
    for (const item of progress) {
      listenedPodcastIds.add(item.podcastId);
      const ratio = item.totalSeconds > 0 ? item.progressSeconds / item.totalSeconds : 0;
      const base = Math.min(1, ratio) + (item.completed ? 0.5 : 0);
      const last = item.lastListenedAt?.toDate
        ? item.lastListenedAt.toDate().getTime()
        : now;
      const ageDays = Math.max(0, (now - last) / (1000 * 60 * 60 * 24));
      const decay = Math.exp(-ageDays / 14);
      const weight = base * decay;
      if (item.podcastId) {
        progressWeightsByPodcast.set(
          item.podcastId,
          (progressWeightsByPodcast.get(item.podcastId) || 0) + weight,
        );
      }
    }

    if (progressWeightsByPodcast.size > 0) {
      const ids = [...progressWeightsByPodcast.keys()];
      for (let i = 0; i < ids.length; i += 10) {
        const chunk = ids.slice(i, i + 10);
        const snap = await podcastsCollection.where("id", "in", chunk).get();
        snap.docs.forEach((doc) => {
          const podcast = doc.data() as Podcast;
          const weight = progressWeightsByPodcast.get(podcast.id) || 0;
          if (podcast.categories) {
            for (const category of podcast.categories) {
              const key = category.toLowerCase();
              categoryScores.set(key, (categoryScores.get(key) || 0) + weight);
            }
          }
          if (podcast.publisher) {
            const key = podcast.publisher.toLowerCase();
            publisherScores.set(key, (publisherScores.get(key) || 0) + weight * 0.6);
          }
        });
      }
    }

    for (const savedItem of saved) {
      savedPodcastIds.add(savedItem.podcastId);
      const podcast = savedItem.podcastData;
      if (podcast?.categories) {
        for (const category of podcast.categories) {
          const key = category.toLowerCase();
          categoryScores.set(key, (categoryScores.get(key) || 0) + 2.0);
        }
      }
      if (podcast?.publisher) {
        const key = podcast.publisher.toLowerCase();
        publisherScores.set(key, (publisherScores.get(key) || 0) + 2.0);
      }
    }

    for (const publisher of followedPublishers) {
      const key = publisher.toLowerCase();
      publisherScores.set(key, (publisherScores.get(key) || 0) + 1.5);
    }

    const topCategories = [...categoryScores.entries()]
      .sort((a, b) => b[1] - a[1])
      .map(([key]) => key)
      .slice(0, 10);

    const topPublishers = [...publisherScores.entries()]
      .sort((a, b) => b[1] - a[1])
      .map(([key]) => key)
      .slice(0, 10);

    const candidates = new Map<string, Podcast>();

    if (topCategories.length > 0) {
      const snap = await podcastsCollection
        .where("categories", "array-contains-any", topCategories)
        .limit(limitNum * 8)
        .get();
      snap.docs.forEach((doc) => candidates.set(doc.id, doc.data() as Podcast));
    }

    if (topPublishers.length > 0) {
      const snap = await podcastsCollection
        .where("publisher", "in", topPublishers)
        .limit(limitNum * 5)
        .get();
      snap.docs.forEach((doc) => candidates.set(doc.id, doc.data() as Podcast));
    }

    if (candidates.size < limitNum * 5) {
      const snap = await podcastsCollection
        .orderBy("latestEpisodeDate", "desc")
        .limit(limitNum * 6)
        .get();
      snap.docs.forEach((doc) => candidates.set(doc.id, doc.data() as Podcast));
    }

    const scored = [...candidates.values()]
      .filter((podcast) => !savedPodcastIds.has(podcast.id))
      .filter((podcast) => !listenedPodcastIds.has(podcast.id))
      .map((podcast) => {
        const categories = podcast.categories?.map((c) => c.toLowerCase()) || [];
        const categoryScore = categories.reduce(
          (sum, cat) => sum + (categoryScores.get(cat) || 0),
          0,
        );
        const publisherScore =
          publisherScores.get(podcast.publisher?.toLowerCase() || "") || 0;
        const ratingScore = (podcast.rating || 0) / 5;
        const ratingCount = podcast.ratingCount || 0;
        const popularity = ratingScore + Math.log10(ratingCount + 1) / 3;
        const latest = podcast.latestEpisodeDate?.toDate
          ? podcast.latestEpisodeDate.toDate().getTime()
          : now;
        const ageDays = Math.max(0, (now - latest) / (1000 * 60 * 60 * 24));
        const recency = Math.exp(-ageDays / 30);

        const score =
          categoryScore * 1.4 +
          publisherScore * 1.2 +
          popularity * 0.6 +
          recency * 0.4;

        return { podcast, score };
      })
      .sort((a, b) => b.score - a.score)
      .slice(0, limitNum);

    const transformedPodcasts = scored.map(({ podcast }) =>
      transformPodcastForResponse(podcast)
    );

    return res.status(200).json({
      success: true,
      podcasts: transformedPodcasts,
    });
  } catch (error) {
    console.error("Error getting recommendations:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get recommendations",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Sync/refresh podcasts from API
 * POST /api/v1/podcasts/sync
 */
export const syncPodcasts = async (req: Request, res: Response) => {
  try {
    const { category, limit = 20 } = req.body;

    // Try to sync from API
    const apiPodcasts = await syncPodcastsFromApi(category, limit);

    if (apiPodcasts.length > 0) {
      return res.status(200).json({
        success: true,
        message: `Synced ${apiPodcasts.length} podcasts from API`,
        count: apiPodcasts.length,
        source: "podchaser",
      });
    }

    return res.status(200).json({
      success: true,
      message: "No podcasts synced (API unavailable or returned empty)",
      count: 0,
      source: "podchaser",
    });
  } catch (error) {
    console.error("Error syncing podcasts:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to sync podcasts",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

export async function syncPodcastsInBackground(options?: {
  categories?: string[];
  limitPerCategory?: number;
}): Promise<{ totalSynced: number; categories: string[] }> {
  if (backgroundSyncInFlight) {
    return backgroundSyncInFlight;
  }

  const categories = (options?.categories && options.categories.length > 0)
    ? options.categories
    : ["News", "Politics", "Business", "Technology", "Science", "Health", "World News"];
  const limitPerCategory = Math.max(5, Math.min(40, options?.limitPerCategory ?? 12));

  backgroundSyncInFlight = (async () => {
    let totalSynced = 0;
    const successfulCategories: string[] = [];

    for (const category of categories) {
      try {
        const synced = await syncPodcastsFromApi(category, limitPerCategory);
        if (synced.length > 0) {
          totalSynced += synced.length;
          successfulCategories.push(category);
        }
      } catch (error) {
        console.warn(`Background podcast sync failed for category "${category}":`, error);
      }
    }

    return {
      totalSynced,
      categories: successfulCategories,
    };
  })();

  try {
    return await backgroundSyncInFlight;
  } finally {
    backgroundSyncInFlight = null;
  }
}

/**
 * Trigger background sync manually
 * POST /api/v1/podcasts/sync/background
 */
export const triggerBackgroundPodcastSync = async (req: Request, res: Response) => {
  try {
    const categories = Array.isArray(req.body?.categories)
      ? (req.body.categories as string[])
      : undefined;
    const limitPerCategory = Number(req.body?.limitPerCategory || 12);
    const summary = await syncPodcastsInBackground({
      categories,
      limitPerCategory,
    });

    return res.status(200).json({
      success: true,
      message: "Background podcast sync completed",
      ...summary,
    });
  } catch (error) {
    console.error("Error triggering background podcast sync:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to trigger background podcast sync",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Reindex podcast search tokens for existing podcast documents
 * POST /api/v1/podcasts/reindex-search
 */
export const reindexPodcastSearchTokens = async (_req: Request, res: Response) => {
  try {
    const pageSize = 200;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    let totalUpdated = 0;

    while (true) {
      let query: FirebaseFirestore.Query = podcastsCollection.limit(pageSize);
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      if (snapshot.empty) break;

      const batch = db.batch();
      let batchUpdates = 0;

      for (const doc of snapshot.docs) {
        const podcast = doc.data() as Podcast;
        const basePodcast: Omit<Podcast, "createdAt" | "updatedAt"> = {
          id: podcast.id,
          podcastIndexId: podcast.podcastIndexId,
          title: podcast.title,
          description: podcast.description,
          publisher: podcast.publisher,
          imageUrl: podcast.imageUrl,
          feedUrl: podcast.feedUrl,
          website: podcast.website,
          language: podcast.language,
          categories: podcast.categories || [],
          totalEpisodes: podcast.totalEpisodes || 0,
          rating: podcast.rating,
          ratingCount: podcast.ratingCount,
          latestEpisodeDate: podcast.latestEpisodeDate,
          isExplicit: podcast.isExplicit ?? false,
          source: podcast.source,
        };

        const nextTokens = buildSearchTokensFromPodcast(basePodcast);
        const currentTokens = podcast.searchTokens || [];
        const unchanged = currentTokens.length === nextTokens.length &&
          currentTokens.every((token) => nextTokens.includes(token));

        if (unchanged) continue;

        batch.set(doc.ref, {
          searchTokens: nextTokens,
          updatedAt: Timestamp.now(),
        }, { merge: true });
        batchUpdates++;
      }

      if (batchUpdates > 0) {
        await batch.commit();
        totalUpdated += batchUpdates;
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];
      if (snapshot.size < pageSize) break;
    }

    return res.status(200).json({
      success: true,
      message: "Podcast search tokens reindexed",
      updated: totalUpdated,
    });
  } catch (error) {
    console.error("Error reindexing podcast search tokens:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to reindex podcast search tokens",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

// ==================== SAVED PODCASTS ====================

/**
 * Get saved podcasts for a user
 * GET /api/v1/podcasts/saved
 */
export const getSavedPodcasts = async (req: Request, res: Response) => {
  try {
    setPrivateCache(res, 45, 120);
    const userId = req.query.userId as string || req.headers["x-user-id"] as string;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const query = await savedPodcastsCollection
      .where("userId", "==", userId)
      .orderBy("savedAt", "desc")
      .get();

    const podcasts = query.docs.map((doc) => {
      const data = doc.data() as SavedPodcast;
      return data.podcastData;
    });

    return res.status(200).json({
      success: true,
      podcasts,
    });
  } catch (error) {
    console.error("Error getting saved podcasts:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get saved podcasts",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Save a podcast
 * POST /api/v1/podcasts/saved
 */
export const savePodcast = async (req: Request, res: Response) => {
  try {
    const { userId, podcast } = req.body;

    if (!userId || !podcast) {
      return res.status(400).json({
        success: false,
        message: "userId and podcast are required",
      });
    }

    // Check if already saved
    const existingQuery = await savedPodcastsCollection
      .where("userId", "==", userId)
      .where("podcastId", "==", podcast.id)
      .limit(1)
      .get();

    if (!existingQuery.empty) {
      return res.status(200).json({
        success: true,
        message: "Podcast already saved",
        alreadySaved: true,
      });
    }

    const savedPodcast: SavedPodcast = {
      userId,
      podcastId: podcast.id,
      podcastData: podcast,
      savedAt: Timestamp.now(),
    };

    await savedPodcastsCollection.add(savedPodcast);

    return res.status(201).json({
      success: true,
      message: "Podcast saved successfully",
    });
  } catch (error) {
    console.error("Error saving podcast:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to save podcast",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Unsave a podcast
 * DELETE /api/v1/podcasts/saved/:podcastId
 */
export const unsavePodcast = async (req: Request, res: Response) => {
  try {
    const podcastId = req.params.podcastId as string;
    const userId = req.query.userId as string || req.headers["x-user-id"] as string;

    if (!userId || !podcastId) {
      return res.status(400).json({
        success: false,
        message: "userId and podcastId are required",
      });
    }

    const query = await savedPodcastsCollection
      .where("userId", "==", userId)
      .where("podcastId", "==", podcastId)
      .limit(1)
      .get();

    if (query.empty) {
      return res.status(404).json({
        success: false,
        message: "Saved podcast not found",
      });
    }

    await query.docs[0].ref.delete();

    return res.status(200).json({
      success: true,
      message: "Podcast unsaved successfully",
    });
  } catch (error) {
    console.error("Error unsaving podcast:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to unsave podcast",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Cleanup legacy podcast data (non-Podchaser)
 * POST /api/v1/podcasts/cleanup
 */
export const cleanupLegacyPodcasts = async (req: Request, res: Response) => {
  try {
    const adminKey = process.env.PODCAST_CLEANUP_KEY;
    if (adminKey) {
      const providedKey = req.headers["x-admin-key"] as string | undefined;
      if (!providedKey || providedKey !== adminKey) {
        return res.status(401).json({
          success: false,
          message: "Unauthorized",
        });
      }
    }

    let totalPodcastsDeleted = 0;
    let totalEpisodesDeleted = 0;
    let totalSavedDeleted = 0;

    while (true) {
      const snapshot = await podcastsCollection
        .where("source", "in", LEGACY_SOURCES)
        .limit(50)
        .get();

      if (snapshot.empty) break;

      const podcastIds = snapshot.docs.map((doc) => (doc.data() as Podcast).id);

      totalPodcastsDeleted += await deleteCollectionDocs(
        podcastsCollection.where("source", "in", LEGACY_SOURCES).limit(50),
      );

      // Delete episodes for those podcasts in chunks of 10 (Firestore 'in' limit)
      for (let i = 0; i < podcastIds.length; i += 10) {
        const chunk = podcastIds.slice(i, i + 10);
        totalEpisodesDeleted += await deleteCollectionDocs(
          episodesCollection.where("podcastId", "in", chunk),
        );
        totalSavedDeleted += await deleteCollectionDocs(
          savedPodcastsCollection.where("podcastId", "in", chunk),
        );
      }
    }

    return res.status(200).json({
      success: true,
      deleted: {
        podcasts: totalPodcastsDeleted,
        episodes: totalEpisodesDeleted,
        savedPodcasts: totalSavedDeleted,
      },
    });
  } catch (error) {
    console.error("Error cleaning up legacy podcasts:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to cleanup legacy podcasts",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

// ==================== LISTENING PROGRESS ====================

/**
 * Get listening progress for a user
 * GET /api/v1/podcasts/progress
 */
export const getListeningProgress = async (req: Request, res: Response) => {
  try {
    setPrivateCache(res, 30, 90);
    const userId = req.query.userId as string || req.headers["x-user-id"] as string;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const query = await listeningProgressCollection
      .where("userId", "==", userId)
      .orderBy("lastListenedAt", "desc")
      .get();

    const progress = query.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return res.status(200).json({
      success: true,
      progress,
    });
  } catch (error) {
    console.error("Error getting listening progress:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get listening progress",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Save listening progress
 * POST /api/v1/podcasts/progress
 */
export const saveListeningProgress = async (req: Request, res: Response) => {
  try {
    const {
      userId,
      episodeId,
      podcastId,
      progressSeconds,
      totalSeconds,
      completed,
      episodeData,
    } = req.body;

    if (!userId || !episodeId || !podcastId) {
      return res.status(400).json({
        success: false,
        message: "userId, episodeId, and podcastId are required",
      });
    }

    // Check if progress exists
    const existingQuery = await listeningProgressCollection
      .where("userId", "==", userId)
      .where("episodeId", "==", episodeId)
      .limit(1)
      .get();

    const progressData: Omit<ListeningProgress, "id"> = {
      userId,
      episodeId,
      podcastId,
      progressSeconds: progressSeconds || 0,
      totalSeconds: totalSeconds || 0,
      completed: completed || false,
      lastListenedAt: Timestamp.now(),
      episodeData,
    };

    if (existingQuery.empty) {
      await listeningProgressCollection.add(progressData);
    } else {
      await existingQuery.docs[0].ref.update(progressData);
    }

    return res.status(200).json({
      success: true,
      message: "Progress saved successfully",
    });
  } catch (error) {
    console.error("Error saving progress:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to save progress",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};

/**
 * Get continue listening episodes
 * GET /api/v1/podcasts/continue-listening
 */
export const getContinueListening = async (req: Request, res: Response) => {
  try {
    setPrivateCache(res, 30, 90);
    const userId = req.query.userId as string || req.headers["x-user-id"] as string;
    const { limit = "10" } = req.query;
    const limitNum = parseInt(limit as string, 10);

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const query = await listeningProgressCollection
      .where("userId", "==", userId)
      .where("completed", "==", false)
      .orderBy("lastListenedAt", "desc")
      .limit(limitNum)
      .get();

    const episodes = query.docs
      .map((doc) => {
        const data = doc.data() as ListeningProgress;
        return data.episodeData;
      })
      .filter((ep) => ep != null);

    return res.status(200).json({
      success: true,
      episodes,
    });
  } catch (error) {
    console.error("Error getting continue listening:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get continue listening",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
};
