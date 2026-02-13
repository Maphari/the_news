type MemoryEntry = {
  value: string;
  expiresAt: number;
};

type RedisScanResult = {
  cursor: string;
  keys: string[];
};

type RedisClientLike = {
  on: (event: string, listener: (error: unknown) => void) => void;
  connect: () => Promise<void>;
  get: (key: string) => Promise<string | null>;
  set: (key: string, value: string, options: { EX: number }) => Promise<unknown>;
  scan: (cursor: number, options: { MATCH: string; COUNT: number }) => Promise<RedisScanResult>;
  del: (keys: string[]) => Promise<unknown>;
};

class CacheService {
  private redisClient: RedisClientLike | null = null;
  private redisReady = false;
  private memoryCache = new Map<string, MemoryEntry>();
  private readonly redisUrl = process.env.REDIS_URL?.trim();
  private readonly keyPrefix = process.env.REDIS_KEY_PREFIX?.trim() || "the_news";
  private nextRedisRetryAt = 0;
  private readonly redisRetryDelayMs = 30_000;

  private async initRedis(): Promise<void> {
    if (!this.redisUrl || this.redisClient) {
      return;
    }
    if (Date.now() < this.nextRedisRetryAt) {
      return;
    }

    try {
      // Lazy-load redis so server can still run with in-memory fallback when
      // package/env is unavailable in local/dev setups.
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const redisModule = require("redis") as {
        createClient: (options: { url: string }) => RedisClientLike;
      };

      this.redisClient = redisModule.createClient({
        url: this.redisUrl,
      });

      this.redisClient.on("error", (error: unknown) => {
        this.redisReady = false;
        this.redisClient = null;
        this.nextRedisRetryAt = Date.now() + this.redisRetryDelayMs;
        console.error("Redis cache error:", error);
      });

      await this.redisClient.connect();
      this.redisReady = true;
      console.log("✅ Redis cache connected");
    } catch (error) {
      this.redisReady = false;
      this.redisClient = null;
      this.nextRedisRetryAt = Date.now() + this.redisRetryDelayMs;
      console.warn("⚠️ Redis unavailable, using in-memory cache fallback");
    }
  }

  private prefixedKey(key: string): string {
    return `${this.keyPrefix}:${key}`;
  }

  async get(key: string): Promise<string | null> {
    await this.initRedis();
    const cacheKey = this.prefixedKey(key);

    if (this.redisReady && this.redisClient) {
      return this.redisClient.get(cacheKey);
    }

    const entry = this.memoryCache.get(cacheKey);
    if (!entry) {
      return null;
    }
    if (entry.expiresAt <= Date.now()) {
      this.memoryCache.delete(cacheKey);
      return null;
    }
    return entry.value;
  }

  async set(key: string, value: string, ttlSeconds: number): Promise<void> {
    await this.initRedis();
    const cacheKey = this.prefixedKey(key);

    if (this.redisReady && this.redisClient) {
      await this.redisClient.set(cacheKey, value, {
        EX: Math.max(1, Math.floor(ttlSeconds)),
      });
      return;
    }

    this.memoryCache.set(cacheKey, {
      value,
      expiresAt: Date.now() + Math.max(1, Math.floor(ttlSeconds)) * 1000,
    });
  }

  async invalidateByPrefixes(prefixes: string[]): Promise<void> {
    if (prefixes.length === 0) return;
    await this.initRedis();

    if (this.redisReady && this.redisClient) {
      for (const prefix of prefixes) {
        const scopedPrefix = this.prefixedKey(prefix);
        let cursor = 0;
        do {
          const result = await this.redisClient.scan(cursor, {
            MATCH: `${scopedPrefix}*`,
            COUNT: 100,
          });
          cursor = Number(result.cursor);
          if (result.keys.length > 0) {
            await this.redisClient.del(result.keys);
          }
        } while (cursor !== 0);
      }
      return;
    }

    const keys = Array.from(this.memoryCache.keys());
    for (const key of keys) {
      if (prefixes.some((prefix) => key.startsWith(this.prefixedKey(prefix)))) {
        this.memoryCache.delete(key);
      }
    }
  }
}

export const cacheService = new CacheService();
