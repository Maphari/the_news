import { Router } from "express";
import { registerUserWithGoogleController } from "../controllers/google.controller";

//? Initialize the router
const googleRouter: Router = Router();

googleRouter.post("/google", registerUserWithGoogleController);

export default googleRouter;
