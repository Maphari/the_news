import { Router } from "express";
import {
  sendOtpCode,
  verifyOtpCodeAndSaveUser,
} from "../controllers/otp.controller";

//? Initialize the router
const otpRouter: Router = Router();

otpRouter.post("/send-otp", sendOtpCode);
otpRouter.post("/verify-otp_save-user", verifyOtpCodeAndSaveUser);

export default otpRouter;
