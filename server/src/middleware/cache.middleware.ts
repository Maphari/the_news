import { NextFunction, Request, Response } from "express";
import { cacheService } from "../services/cache.service";

type CacheOptions = {
  namespace: string;
  ttlSeconds: number;
  keyBuilder?: (req: Request) => string;
};

type PrefixBuilder = (req: Request) => string[];

function pickString(value: unknown): string | null {
  if (typeof value === "string" && value.trim().length > 0) {
    return value.trim();
  }
  if (Array.isArray(value) && value.length > 0) {
    const first = value[0];
    if (typeof first === "string" && first.trim().length > 0) {
      return first.trim();
    }
  }
  return null;
}

export function extractScopedUserIds(req: Request): string[] {
  const candidates: unknown[] = [
    req.query?.userId,
    req.params?.userId,
    req.params?.followerId,
    req.params?.followingId,
    (req.body as Record<string, unknown> | undefined)?.userId,
    (req.body as Record<string, unknown> | undefined)?.ownerId,
    (req.body as Record<string, unknown> | undefined)?.followerId,
    (req.body as Record<string, unknown> | undefined)?.followingId,
  ];

  const ids = candidates
    .map(pickString)
    .filter((item): item is string => item !== null);
  return Array.from(new Set(ids));
}

function buildStableQuery(query: Request["query"]): string {
  const pairs = Object.entries(query)
    .filter(([, value]) => value !== undefined && value !== null)
    .flatMap(([key, value]) => {
      if (Array.isArray(value)) {
        return value.map((item) => [key, String(item)] as const);
      }
      return [[key, String(value)] as const];
    })
    .sort(([a], [b]) => a.localeCompare(b));

  return pairs.map(([key, value]) => `${key}=${value}`).join("&");
}

function defaultKeyBuilder(req: Request): string {
  const query = buildStableQuery(req.query);
  return query.length > 0 ? `${req.path}?${query}` : req.path;
}

export function cacheResponse(options: CacheOptions) {
  return async function cacheMiddleware(
    req: Request,
    res: Response,
    next: NextFunction
  ) {
    if (req.method !== "GET") {
      return next();
    }

    const routeKey = (options.keyBuilder || defaultKeyBuilder)(req);
    const scopedUserId = extractScopedUserIds(req)[0] ?? "_";
    const key = `${options.namespace}:uid:${scopedUserId}:${routeKey}`;

    try {
      const cached = await cacheService.get(key);
      if (cached) {
        res.setHeader("x-cache", "HIT");
        return res.status(200).json(JSON.parse(cached));
      }

      const originalJson = res.json.bind(res);
      res.json = (body: unknown) => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          cacheService
            .set(key, JSON.stringify(body), options.ttlSeconds)
            .catch((error) => console.error("Cache set error:", error));
          res.setHeader("x-cache", "MISS");
        }
        return originalJson(body);
      };
    } catch (error) {
      console.error("Cache read error:", error);
    }

    return next();
  };
}

export function invalidateCache(prefixes: string[] | PrefixBuilder) {
  const buildPrefixes: PrefixBuilder = Array.isArray(prefixes)
    ? () => prefixes
    : prefixes;

  return async function invalidateMiddleware(
    req: Request,
    _res: Response,
    next: NextFunction
  ) {
    const resolvedPrefixes = buildPrefixes(req).filter((prefix) => prefix.trim().length > 0);
    if (resolvedPrefixes.length === 0) {
      return next();
    }

    try {
      await cacheService.invalidateByPrefixes(resolvedPrefixes);
    } catch (error) {
      console.error("Cache invalidate error:", error);
    }

    return next();
  };
}
