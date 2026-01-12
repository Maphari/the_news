import { Request, Response } from "express";
import { OtpRegisterRequestBody, ValidationError } from "../types/register.types";

//? Type guard to check if body matches RegisterRequestBody structure
function isRegisterRequestBody(body: any): body is OtpRegisterRequestBody {
  return (
    typeof body === "object" &&
    body !== null &&
    typeof body.userOtp === "string" &&
    typeof body.generatedOtp === "string" &&
    typeof body.names === "string" &&
    typeof body.email === "string" &&
    typeof body.password === "string" &&
    typeof body.confirmPassword === "string" &&
    typeof body.acceptedTerms === "boolean"
  );
}

//? Validate email format
function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}


//? Validate password strength (example: min 8 chars, 1 uppercase, 1 number)
function isValidPassword(password: string): boolean {
  return (
    password.length >= 8 && /[A-Z]/.test(password) && /[0-9]/.test(password)
  );
}

export function validateRequestBody(req: Request): ValidationError[] {
  const errors: ValidationError[] = [];

  // Check if body exists
  if (!req.body) {
    errors.push({ field: "body", message: "Request body is required" });
    return errors;
  }

  // Type check
  if (!isRegisterRequestBody(req.body)) {
    errors.push({ field: "body", message: "Invalid request body structure" });
    return errors;
  }

  const {
    userOtp,
    generatedOtp,
    names,
    email,
    password,
    confirmPassword,
    acceptedTerms,
  } = req.body;

  //? Validate userOtp
  if (!userOtp || userOtp.trim() === "") {
    errors.push({ field: "userOtp", message: "OTP is required" });
  } else if (!/^\d{4,6}$/.test(userOtp)) {
    errors.push({ field: "userOtp", message: "OTP must be 4-6 digits" });
  }

  //? Validate generatedOtp
  if (!generatedOtp || generatedOtp.trim() === "") {
    errors.push({
      field: "generatedOtp",
      message: "Generated OTP is required",
    });
  }

  //? Validate OTP match
  if (userOtp && generatedOtp && userOtp !== generatedOtp) {
    errors.push({ field: "userOtp", message: "OTP does not match" });
  }

  //? Validate names
  if (!names || names.trim() === "") {
    errors.push({ field: "names", message: "Name is required" });
  } else if (names.trim().length < 2) {
    errors.push({
      field: "names",
      message: "Name must be at least 2 characters",
    });
  }

  //? Validate email
  if (!email || email.trim() === "") {
    errors.push({ field: "email", message: "Email is required" });
  } else if (!isValidEmail(email)) {
    errors.push({ field: "email", message: "Invalid email format" });
  }

  //? Validate password
  if (!password || password.trim() === "") {
    errors.push({ field: "password", message: "Password is required" });
  } else if (!isValidPassword(password)) {
    errors.push({
      field: "password",
      message:
        "Password must be at least 8 characters with 1 uppercase and 1 number",
    });
  }

  //? Validate confirmPassword
  if (!confirmPassword || confirmPassword.trim() === "") {
    errors.push({
      field: "confirmPassword",
      message: "Password confirmation is required",
    });
  } else if (password !== confirmPassword) {
    errors.push({
      field: "confirmPassword",
      message: "Passwords do not match",
    });
  }

  //? Validate acceptedTerms
  if (acceptedTerms !== true) {
    errors.push({
      field: "acceptedTerms",
      message: "You must accept the terms and conditions",
    });
  }

  return errors;
}