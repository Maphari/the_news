import { Router } from "express";
import { logUserController } from "../controllers/login.controller";


//? Initialize the router
const loginUserRouter: Router = Router();

loginUserRouter.post("/login", logUserController);

export default loginUserRouter;