import { Router } from "express";
import { saveArticlesBatch, getArticles, getArticleById } from "../controllers/article.controller";

//? Initialize the router
const articleRouter: Router = Router();

//? Save batch of articles
articleRouter.post("/articles/batch", saveArticlesBatch);

//? Get articles with filters
articleRouter.get("/articles", getArticles);

//? Get single article by ID
articleRouter.get("/articles/:articleId", getArticleById);

export default articleRouter;
