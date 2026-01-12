import { Router } from "express";
import { registerUserWithAppleController } from "../controllers/apple.controller";


//? Initialize the router
const appleRouter: Router = Router();

appleRouter.post("/apple", registerUserWithAppleController);

export default appleRouter;
