import { Router } from "express";
import { verifyToken } from "../middleware/auth.middleware";
import {
  authController,
  authenticatedUserController,
  changePasswordController,
} from "../controllers/auth.controller";

const authRouter: Router = Router();

authRouter.get('/validate-token', verifyToken, authController);
authRouter.get('/me', verifyToken, authenticatedUserController);
authRouter.post('/change-password', verifyToken, changePasswordController);

export default authRouter;
