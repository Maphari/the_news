import { Router } from "express";
import { verifyToken } from "../middleware/auth.middleware";
import { authController, authenticatedUserController } from "../controllers/auth.controller";

const authRouter: Router = Router();

authRouter.get('/validate-token', verifyToken, authController);
authRouter.get('/me', verifyToken, authenticatedUserController);

export default authRouter;