import { RegisterRequestBody, ValidationError } from "../types/register.types";

//? Validation utilities
const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const PASSWORD_MIN_LENGTH = 8;
const PASSWORD_MAX_LENGTH = 128;
const NAME_MIN_LENGTH = 2;
const NAME_MAX_LENGTH = 100;

function sanitizeString(input: string): string {
  return input.trim().replace(/\s+/g, " ");
}

function isValidEmail(email: string): boolean {
  if (!email || email.length > 254) return false;
  return EMAIL_REGEX.test(email);
}

function isValidPassword(password: string): boolean {
  if (
    password.length < PASSWORD_MIN_LENGTH ||
    password.length > PASSWORD_MAX_LENGTH
  ) {
    return false;
  }

  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

  return hasUpperCase && hasLowerCase && hasNumber && hasSpecialChar;
}

function isValidName(name: string): boolean {
  const sanitized = sanitizeString(name);
  if (
    sanitized.length < NAME_MIN_LENGTH ||
    sanitized.length > NAME_MAX_LENGTH
  ) {
    return false;
  }

  //? Only allow letters, spaces, hyphens, and apostrophes
  const nameRegex = /^[a-zA-Z\s'-]+$/;
  return nameRegex.test(sanitized);
}

export function validateRegistrationInput(body: any): {
  isValid: boolean;
  errors: ValidationError[];
  sanitizedData?: RegisterRequestBody;
} {
  const errors: ValidationError[] = [];

  //? Type checking
  if (!body || typeof body !== "object") {
    return {
      isValid: false,
      errors: [{ field: "body", message: "Invalid request body" }],
    };
  }

  const { names, email, password, confirmPassword, acceptedTerms } = body;

  //? Check required fields
  if (!names || typeof names !== "string") {
    errors.push({ field: "names", message: "Name is required" });
  }
  if (!email || typeof email !== "string") {
    errors.push({ field: "email", message: "Email is required" });
  }
  if (!password || typeof password !== "string") {
    errors.push({ field: "password", message: "Password is required" });
  }
  if (!confirmPassword || typeof confirmPassword !== "string") {
    errors.push({
      field: "confirmPassword",
      message: "Password confirmation is required",
    });
  }
  if (typeof acceptedTerms !== "boolean") {
    errors.push({
      field: "acceptedTerms",
      message: "Terms acceptance is required",
    });
  }

  //? Early return if basic validation fails
  if (errors.length > 0) {
    return { isValid: false, errors };
  }

  //? Sanitize inputs
  const sanitizedNames = sanitizeString(names);
  const sanitizedEmail = sanitizeString(email).toLowerCase();

  //? Validate name
  if (!isValidName(sanitizedNames)) {
    errors.push({
      field: "names",
      message: `Name must be ${NAME_MIN_LENGTH}-${NAME_MAX_LENGTH} characters and contain only letters, spaces, hyphens, and apostrophes`,
    });
  }

  //? Validate email
  if (!isValidEmail(sanitizedEmail)) {
    errors.push({
      field: "email",
      message: "Invalid email format",
    });
  }

  //? Validate password
  if (!isValidPassword(password)) {
    errors.push({
      field: "password",
      message: `Password must be ${PASSWORD_MIN_LENGTH}-${PASSWORD_MAX_LENGTH} characters and include uppercase, lowercase, number, and special character`,
    });
  }

  //? Check password match
  if (password !== confirmPassword) {
    errors.push({
      field: "confirmPassword",
      message: "Passwords do not match",
    });
  }

  //? Validate terms acceptance
  if (acceptedTerms !== true) {
    errors.push({
      field: "acceptedTerms",
      message: "You must accept the terms and conditions",
    });
  }

  if (errors.length > 0) {
    return { isValid: false, errors };
  }

  return {
    isValid: true,
    errors: [],
    sanitizedData: {
      names: sanitizedNames,
      email: sanitizedEmail,
      password,
      confirmPassword,
      acceptedTerms,
    },
  };
}
