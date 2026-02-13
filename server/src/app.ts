import express, { Application } from "express";
import helmet from "helmet";
import morgan from "morgan";
import cors from "cors";

import { errorHandler } from "./middleware/errorHandling";

//? Routes
import registerUserRoutes from "./routes/register.routes";
import loginUserRouter from "./routes/login.routes";
import googleRouter from "./routes/google.routes";
import appleRouter from "./routes/apple.routes";
import otpRouter from "./routes/otp.routes";
import authRouter from "./routes/auth.routes";
import articleRouter from "./routes/article.routes";
import savedArticlesRouter from "./routes/saved-articles.routes";
import engagementRouter from "./routes/engagement.routes";
import dislikedArticlesRouter from "./routes/disliked-articles.routes";
import followedPublishersRouter from "./routes/followed-publishers.routes";
import commentsRouter from "./routes/comments.routes";
import digestRouter from "./routes/daily-digest.routes";
import userPreferencesRouter from "./routes/user-preferences.routes";
import readingHistoryRouter from "./routes/reading-history.routes";
import subscriptionsRouter from "./routes/subscriptions.routes";
import notificationsRouter from "./routes/notifications.routes";
import socialRouter from "./routes/social.routes";
import feedbackRouter from "./routes/feedback.routes";
import podcastRouter from "./routes/podcast.routes";
import aiRouter from "./routes/ai.routes";
import usersRouter from "./routes/users.routes";
import experienceRouter from "./routes/experience.routes";

//? Initialize Express Application
const app: Application = express();

const BASE_API_PATH: string = "/api/v1";
const AUTH_BASE_API_PATH: string = `${BASE_API_PATH}/auth`;

//? Middleware Setup
app.use(helmet());
app.use(cors());

//? Logging Middleware
if (process.env.NODE_ENV === "development") {
  app.use(morgan("dev"));
} else {
  app.use(morgan("combined"));
}

//? Body Parsing Middleware
app.use(express.json());

//? To handle URL-encoded data
app.use(express.urlencoded({ extended: true }));

//? Register Routes
app.use(BASE_API_PATH, registerUserRoutes);
app.use(BASE_API_PATH, loginUserRouter);
app.use(AUTH_BASE_API_PATH, googleRouter);
app.use(AUTH_BASE_API_PATH, appleRouter);
app.use(AUTH_BASE_API_PATH, otpRouter);
app.use(AUTH_BASE_API_PATH, authRouter);
app.use(BASE_API_PATH, articleRouter);
app.use(BASE_API_PATH, savedArticlesRouter);
app.use(BASE_API_PATH, engagementRouter);
app.use(BASE_API_PATH, dislikedArticlesRouter);
app.use(BASE_API_PATH, followedPublishersRouter);
app.use(BASE_API_PATH, commentsRouter);
app.use(BASE_API_PATH, digestRouter);
app.use(`${BASE_API_PATH}/user`, userPreferencesRouter);
app.use(`${BASE_API_PATH}/user`, readingHistoryRouter);
app.use(`${BASE_API_PATH}/subscriptions`, subscriptionsRouter);
app.use(`${BASE_API_PATH}/notifications`, notificationsRouter);
app.use(BASE_API_PATH, socialRouter);
app.use(BASE_API_PATH, feedbackRouter);
app.use(`${BASE_API_PATH}/podcasts`, podcastRouter);
app.use(`${BASE_API_PATH}/ai`, aiRouter);
app.use(BASE_API_PATH, usersRouter);
app.use(BASE_API_PATH, experienceRouter);

//? Handling Errors
app.use(errorHandler);

export default app;
