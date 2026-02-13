import { Router } from "express";
import { cacheResponse, invalidateCache } from "../middleware/cache.middleware";
import {
  saveArticlesBatch,
  getArticles,
  getArticleById,
  searchArticles,
  getTopStories,
  getPopularSources,
  getExploreSections,
  getArticleRecommendations,
  getArticlesByIds,
  getHomeFeed,
} from "../controllers/article.controller";

//? Initialize the router
const articleRouter: Router = Router();
const articleReadCache = cacheResponse({
  namespace: "articles",
  ttlSeconds: 180,
});
const articleSearchReadCache = cacheResponse({
  namespace: "articles-search",
  ttlSeconds: 120,
});
const invalidateArticleCache = invalidateCache(["articles:uid:_:", "articles-search:uid:_:"]);

//? Save batch of articles
articleRouter.post("/articles/batch", invalidateArticleCache, saveArticlesBatch);
articleRouter.post("/articles/by-ids", getArticlesByIds);

//? Get articles with filters
articleRouter.get("/articles", articleReadCache, getArticles);
articleRouter.get("/articles/search", articleSearchReadCache, searchArticles);
articleRouter.get("/articles/top-stories", articleReadCache, getTopStories);
articleRouter.get("/articles/popular-sources", articleReadCache, getPopularSources);
articleRouter.get("/articles/explore/sections", articleReadCache, getExploreSections);
articleRouter.get("/articles/home-feed", articleReadCache, getHomeFeed);

//? Get personalized recommendations
articleRouter.get("/articles/recommendations", articleReadCache, getArticleRecommendations);

//? Get single article by ID
articleRouter.get("/articles/:articleId", articleReadCache, getArticleById);

export default articleRouter;
