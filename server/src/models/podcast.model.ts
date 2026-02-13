import { Timestamp } from "firebase-admin/firestore";

/**
 * Podcast model for database storage
 */
export interface Podcast {
  id: string;                        // Unique identifier (from API or generated)
  podcastIndexId?: string;           // Original Podcast Index ID if from API
  title: string;
  description: string;
  publisher: string;                 // Author/Publisher name
  imageUrl: string;
  feedUrl?: string;
  website?: string;
  language: string;
  categories: string[];              // Genre/category names
  searchTokens?: string[];           // Precomputed tokens for prefix search
  totalEpisodes: number;
  rating?: number;
  ratingCount?: number;
  latestEpisodeDate?: Timestamp;
  isExplicit: boolean;
  source: 'podcast_index' | 'podchaser' | 'sample' | 'manual';  // Data source
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

/**
 * Episode model for database storage
 */
export interface Episode {
  id: string;                        // Unique identifier
  podcastIndexId?: string;           // Original Podcast Index episode ID
  podcastId: string;                 // Reference to parent podcast
  podcastTitle: string;
  title: string;
  description: string;
  audioUrl: string;
  imageUrl?: string;
  podcastImageUrl?: string;
  durationSeconds: number;
  publishedDate: Timestamp;
  episodeNumber?: number;
  seasonNumber?: number;
  isExplicit: boolean;
  transcript?: string;
  source: 'podcast_index' | 'podchaser' | 'sample' | 'manual';
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

/**
 * Saved podcast for a user
 */
export interface SavedPodcast {
  userId: string;
  podcastId: string;
  podcastData: Podcast;
  savedAt: Timestamp;
}

/**
 * Listening progress for an episode
 */
export interface ListeningProgress {
  id?: string;
  userId: string;
  episodeId: string;
  podcastId: string;
  progressSeconds: number;
  totalSeconds: number;
  completed: boolean;
  lastListenedAt: Timestamp;
  episodeData?: Episode;
}

/**
 * Request types
 */
export interface SavePodcastRequest {
  userId: string;
  podcast: Podcast;
}

export interface SaveProgressRequest {
  userId: string;
  episodeId: string;
  podcastId: string;
  progressSeconds: number;
  totalSeconds: number;
  completed: boolean;
  episodeData?: Episode;
}
