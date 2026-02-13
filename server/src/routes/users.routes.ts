import { Router } from "express";
import { cacheResponse } from "../middleware/cache.middleware";
import { exportUserData } from "../controllers/user-export.controller";
import { verifyToken } from "../middleware/auth.middleware";

const usersRouter: Router = Router();
const userExportReadCache = cacheResponse({
  namespace: "user-export",
  ttlSeconds: 60,
});

// Export user data
usersRouter.get("/users/:userId/export", verifyToken, userExportReadCache, exportUserData);

export default usersRouter;
