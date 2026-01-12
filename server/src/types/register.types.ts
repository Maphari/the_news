export type OtpRegisterRequestBody = {
  userOtp: string;
  generatedOtp: string;
  names: string;
  email: string;
  password: string;
  confirmPassword: string;
  acceptedTerms: boolean;
};

export type ValidationError = {
  field: string;
  message: string;
};

export type RegisterRequestBody = {
  names: string;
  email: string;
  password: string;
  confirmPassword: string;
  acceptedTerms: boolean;
};