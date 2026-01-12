import { Router } from "express";
import { registerUserController } from "../controllers/register.controller";

//? Initialize the router
const registerUserRouter: Router = Router();

registerUserRouter.post("/register", registerUserController);

export default registerUserRouter;
