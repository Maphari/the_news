/**
 * Podchaser API Service (GraphQL)
 *
 * Sign up for API access at: https://features.podchaser.com/api/
 *
 * Add these to your .env file:
 * PODCHASER_CLIENT_ID=your_client_id
 * PODCHASER_CLIENT_SECRET=your_client_secret
 * PODCHASER_SCOPES=public
 * PODCHASER_ACCESS_TOKEN=optional_static_token
 */

interface PodchaserConfig {
  clientId: string;
  clientSecret: string;
  scopes: string;
  accessToken: string;
  baseUrl: string;
}

type GraphQLResponse<T> = {
  data?: T;
  errors?: Array<{ message?: string }>;
};

interface PodchaserPodcast {
  id: string;
  title: string;
  description?: string;
  imageUrl?: string;
  website?: string;
  webUrl?: string;
  rssUrl?: string;
  language?: string;
  numberOfEpisodes?: number;
  author?: {
    name?: string;
  };
  ratingAverage?: number;
  ratingCount?: number;
  categories?: Array<{
    title?: string;
    slug?: string;
  }>;
}

interface PodchaserEpisode {
  id: string;
  title: string;
  description?: string;
  audioUrl?: string;
  length?: number;
  airDate?: string;
  imageUrl?: string;
  explicit?: boolean;
  podcast?: {
    id?: string;
    title?: string;
    imageUrl?: string;
  };
}

interface PodcastListResponse {
  podcasts: {
    data: PodchaserPodcast[];
  };
}

interface PodcastResponse {
  podcast: PodchaserPodcast | null;
}

interface EpisodesResponse {
  podcast: {
    episodes: {
      data: PodchaserEpisode[];
    };
  } | null;
}

class PodchaserService {
  private config: PodchaserConfig;
  private cachedToken: string | null = null;
  private tokenExpiresAt: number | null = null;

  constructor() {
    this.config = {
      clientId: process.env.PODCHASER_CLIENT_ID || "",
      clientSecret: process.env.PODCHASER_CLIENT_SECRET || "",
      scopes: process.env.PODCHASER_SCOPES || "public",
      accessToken: process.env.PODCHASER_ACCESS_TOKEN || "",
      baseUrl: "https://api.podchaser.com/graphql",
    };
  }

  isConfigured(): boolean {
    return !!(
      this.config.accessToken ||
      (this.config.clientId && this.config.clientSecret)
    );
  }

  private async getAccessToken(): Promise<string | null> {
    if (this.config.accessToken) {
      return this.config.accessToken;
    }

    if (this.cachedToken && this.tokenExpiresAt && Date.now() < this.tokenExpiresAt) {
      return this.cachedToken;
    }

    if (!this.config.clientId || !this.config.clientSecret) {
      console.warn("Podchaser API not configured. Add PODCHASER_CLIENT_ID and PODCHASER_CLIENT_SECRET to .env");
      return null;
    }

    const mutation = `
      mutation RequestAccessToken($clientId: String!, $clientSecret: String!, $grantType: GrantType!, $scopes: String!) {
        requestAccessToken(input: {
          client_id: $clientId,
          client_secret: $clientSecret,
          grant_type: $grantType,
          scopes: $scopes
        }) {
          access_token
          expires_in
        }
      }
    `;

    const response = await this.makeRequest<{ requestAccessToken: { access_token: string; expires_in: number } }>(
      mutation,
      {
        clientId: this.config.clientId,
        clientSecret: this.config.clientSecret,
        grantType: "CLIENT_CREDENTIALS",
        scopes: this.config.scopes,
      },
      false,
    );

    const token = response?.requestAccessToken?.access_token;
    const expiresIn = response?.requestAccessToken?.expires_in;

    if (!token || !expiresIn) {
      console.error("Failed to acquire Podchaser access token");
      return null;
    }

    this.cachedToken = token;
    this.tokenExpiresAt = Date.now() + (expiresIn - 30) * 1000;

    return token;
  }

  private async makeRequest<T>(
    query: string,
    variables: Record<string, unknown> = {},
    includeAuth: boolean = true,
  ): Promise<T | null> {
    try {
      const headers: Record<string, string> = {
        "Content-Type": "application/json",
      };

      if (includeAuth) {
        const token = await this.getAccessToken();
        if (!token) return null;
        headers.Authorization = `Bearer ${token}`;
      }

      const response = await fetch(this.config.baseUrl, {
        method: "POST",
        headers,
        body: JSON.stringify({ query, variables }),
      });

      if (!response.ok) {
        console.error(`Podchaser API error: ${response.status} ${response.statusText}`);
        return null;
      }

      const result = (await response.json()) as GraphQLResponse<T>;
      if (result.errors && result.errors.length > 0) {
        console.error("Podchaser API GraphQL errors:", result.errors);
        return null;
      }

      return result.data ?? null;
    } catch (error) {
      console.error("Podchaser API request failed:", error);
      return null;
    }
  }

  private mapCategoryToSlug(category: string): string {
    const normalized = category.trim().toLowerCase();
    const map: Record<string, string> = {
      "news": "news",
      "daily news": "daily-news",
      "world news": "world-news",
      "current events": "current-events",
      "politics": "politics",
      "government": "politics",
      "news & politics": "politics",
      "news commentary": "politics",
      "business": "business",
      "business news": "business",
      "finance": "finance",
      "economy": "economics",
      "economics": "economics",
      "entrepreneurship": "business",
      "investing": "finance",
      "technology": "technology",
      "tech news": "technology",
      "science": "science",
      "science & technology": "science",
      "natural sciences": "science",
      "health": "health",
      "health & fitness": "health",
      "mental health": "health",
      "medicine": "health",
      "sports": "sports",
      "entertainment": "entertainment",
      "tv & film": "entertainment",
      "music": "entertainment",
      "education": "education",
      "culture": "culture",
      "environment": "environment",
      "world": "world-news",
      "top": "news",
    };

    const mapped = map[normalized] ?? normalized.replace(/\s+/g, "-");
    return this.getNewsCategorySlugs().includes(mapped) ? mapped : "news";
  }

  private getNewsCategorySlugs(): string[] {
    return [
      "news",
      "daily-news",
      "world-news",
      "current-events",
      "politics",
      "business",
      "finance",
      "economics",
      "technology",
      "science",
      "health",
      "sports",
      "entertainment",
      "education",
      "culture",
      "environment",
    ];
  }

  async searchNewsPodcasts(query: string = "", max: number = 20): Promise<PodchaserPodcast[]> {
    const gql = `
      query SearchPodcasts($first: Int!, $searchTerm: String!, $categories: [String!]) {
        podcasts(
          first: $first
          searchTerm: $searchTerm
          filters: { categories: $categories }
        ) {
          data {
            id
            title
            description
            imageUrl
            rssUrl
            webUrl
            language
            numberOfEpisodes
            author { name }
            ratingAverage
            ratingCount
            categories { title slug }
          }
        }
      }
    `;

    const categories = this.getNewsCategorySlugs();
    const response = await this.makeRequest<PodcastListResponse>(gql, {
      first: max,
      searchTerm: query || "news",
      categories,
    });

    if (response?.podcasts?.data) {
      return response.podcasts.data;
    }

    // Fallback: try without category filter if Podchaser errors
    const fallbackGql = `
      query SearchPodcastsFallback($first: Int!, $searchTerm: String!) {
        podcasts(
          first: $first
          searchTerm: $searchTerm
        ) {
          data {
            id
            title
            description
            imageUrl
            rssUrl
            webUrl
            language
            numberOfEpisodes
            author { name }
            ratingAverage
            ratingCount
            categories { title slug }
          }
        }
      }
    `;

    const fallbackResponse = await this.makeRequest<PodcastListResponse>(fallbackGql, {
      first: max,
      searchTerm: query || "news",
    });

    return fallbackResponse?.podcasts?.data || [];
  }

  async getTrendingPodcasts(max: number = 20, category?: string): Promise<PodchaserPodcast[]> {
    const gql = `
      query TrendingPodcasts($first: Int!, $categories: [String!]) {
        podcasts(
          first: $first
          filters: { categories: $categories }
          sort: { sortBy: FOLLOWER_COUNT, direction: DESCENDING }
        ) {
          data {
            id
            title
            description
            imageUrl
            rssUrl
            webUrl
            language
            numberOfEpisodes
            author { name }
            ratingAverage
            ratingCount
            categories { title slug }
          }
        }
      }
    `;

    const slug = category ? this.mapCategoryToSlug(category) : "news";
    const response = await this.makeRequest<PodcastListResponse>(gql, {
      first: max,
      categories: [slug],
    });

    if (response?.podcasts?.data) {
      return response.podcasts.data;
    }

    // Fallback: try without category filter if Podchaser errors
    const fallbackGql = `
      query TrendingPodcastsFallback($first: Int!) {
        podcasts(
          first: $first
          sort: { sortBy: FOLLOWER_COUNT, direction: DESCENDING }
        ) {
          data {
            id
            title
            description
            imageUrl
            rssUrl
            webUrl
            language
            numberOfEpisodes
            author { name }
            ratingAverage
            ratingCount
            categories { title slug }
          }
        }
      }
    `;

    const fallbackResponse = await this.makeRequest<PodcastListResponse>(fallbackGql, {
      first: max,
    });

    return fallbackResponse?.podcasts?.data || [];
  }

  async getPodcastById(id: string): Promise<PodchaserPodcast | null> {
    const gql = `
      query PodcastById($id: String!) {
        podcast(identifier: { id: $id, type: PODCHASER }) {
          id
          title
          description
          imageUrl
          rssUrl
          webUrl
          language
          numberOfEpisodes
          author { name }
          ratingAverage
          ratingCount
          categories { title slug }
        }
      }
    `;

    const response = await this.makeRequest<PodcastResponse>(gql, { id });
    return response?.podcast ?? null;
  }

  async getEpisodes(podcastId: string, max: number = 20): Promise<PodchaserEpisode[]> {
    const gql = `
      query PodcastEpisodes($id: String!, $first: Int!) {
        podcast(identifier: { id: $id, type: PODCHASER }) {
          episodes(first: $first, sort: { sortBy: AIR_DATE, direction: DESCENDING }) {
            data {
              id
              title
              description
              audioUrl
              length
              airDate
              imageUrl
              explicit
              podcast { id title imageUrl }
            }
          }
        }
      }
    `;

    const response = await this.makeRequest<EpisodesResponse>(gql, {
      id: podcastId,
      first: max,
    });

    if (response?.podcast?.episodes?.data?.length) {
      return response.podcast.episodes.data;
    }

    // Fallback: resolve by search term if the ID doesn't match
    const fallbackResults = await this.searchNewsPodcasts(podcastId, 1);
    if (fallbackResults.length > 0 && fallbackResults[0].id !== podcastId) {
      const resolved = await this.makeRequest<EpisodesResponse>(gql, {
        id: fallbackResults[0].id,
        first: max,
      });
      return resolved?.podcast?.episodes?.data || [];
    }

    return [];
  }

  transformPodcast(podcast: PodchaserPodcast): {
    id: string;
    title: string;
    description: string;
    publisher: string;
    imageUrl: string;
    categories: string[];
    totalEpisodes: number;
    website?: string;
    language: string;
    rating?: number;
    ratingCount?: number;
  } {
    const categories = podcast.categories
      ?.map((category) => category?.title || category?.slug || "")
      .filter((name) => name && name.length > 0) || [];

    return {
      id: podcast.id,
      title: podcast.title || "",
      description: podcast.description || "",
      publisher: podcast.author?.name || "",
      imageUrl: podcast.imageUrl || "",
      categories,
      totalEpisodes: podcast.numberOfEpisodes || 0,
      website: podcast.website || podcast.webUrl,
      language: podcast.language || "",
      rating: podcast.ratingAverage ?? undefined,
      ratingCount: podcast.ratingCount ?? undefined,
    };
  }

  transformEpisode(episode: PodchaserEpisode): {
    id: string;
    podcastId: string;
    podcastTitle: string;
    title: string;
    description: string;
    audioUrl: string;
    durationSeconds: number;
    publishedDate: string;
    imageUrl?: string;
    podcastImageUrl?: string;
    isExplicit: boolean;
  } {
    return {
      id: episode.id,
      podcastId: episode.podcast?.id || "",
      podcastTitle: episode.podcast?.title || "",
      title: episode.title || "",
      description: episode.description || "",
      audioUrl: episode.audioUrl || "",
      durationSeconds: episode.length || 0,
      publishedDate: episode.airDate || new Date().toISOString(),
      imageUrl: episode.imageUrl,
      podcastImageUrl: episode.podcast?.imageUrl,
      isExplicit: episode.explicit ?? false,
    };
  }
}

export const podchaserService = new PodchaserService();
export default podchaserService;
