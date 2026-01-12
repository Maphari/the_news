import 'package:flutter/material.dart';

//? Validate form field name 
String? valiadateName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your name';
  }
  
  // Remove leading/trailing whitespace for validation
  final trimmedValue = value.trim();
  
  if (trimmedValue.isEmpty) {
    return 'Name cannot be empty';
  }
  
  if (trimmedValue.length < 2) {
    return 'Name must be at least 2 characters';
  }
  
  if (trimmedValue.length > 50) {
    return 'Name must be less than 50 characters';
  }
  
  // Check if name contains only letters, spaces, hyphens, and apostrophes
  final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
  if (!nameRegex.hasMatch(trimmedValue)) {
    return 'Name can only contain letters, spaces, hyphens, and apostrophes';
  }
  
  // Check if name contains at least one letter
  if (!RegExp(r'[a-zA-Z]').hasMatch(trimmedValue)) {
    return 'Name must contain at least one letter';
  }
  
  return null;
}

//? Validate form field email
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }
  
  final trimmedValue = value.trim();
  
  if (trimmedValue.isEmpty) {
    return 'Email cannot be empty';
  }
  
  // Comprehensive email regex pattern
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  if (!emailRegex.hasMatch(trimmedValue)) {
    return 'Please enter a valid email address';
  }
  
  // Check for common typos
  if (trimmedValue.contains('..') || 
      trimmedValue.startsWith('.') || 
      trimmedValue.endsWith('.')) {
    return 'Email format is invalid';
  }
  
  // Check email length
  if (trimmedValue.length > 254) {
    return 'Email is too long';
  }
  
  return null;
}

//? Validate form field password
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a password';
  }
  
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  
  if (value.length > 128) {
    return 'Password must be less than 128 characters';
  }
  
  // Check for at least one uppercase letter
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Password must contain at least one uppercase letter';
  }
  
  // Check for at least one lowercase letter
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return 'Password must contain at least one lowercase letter';
  }
  
  // Check for at least one digit
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'Password must contain at least one number';
  }
  
  // Check for at least one special character
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
    return 'Password must contain at least one special character (!@#\$%^&*...)';
  }
  
  // Check for common weak passwords
  final weakPasswords = [
    'password', 'Password1', '12345678', 'Qwerty123', 
    'Abc12345', 'Password123', 'Welcome1'
  ];
  
  if (weakPasswords.any((weak) => value.toLowerCase().contains(weak.toLowerCase()))) {
    return 'Password is too common. Please choose a stronger password';
  }
  
  return null;
}

//? Validate form field confirm password
String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Please confirm your password';
  }
  
  if (value != password) {
    return 'Passwords do not match';
  }
  
  return null;
}

//? Validate accept terms checkbox
bool validateAcceptTerms(bool acceptTerms, {required BuildContext context}) {
  if (!acceptTerms) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You must accept the terms and conditions to continue'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    return false;
  }
  
  return true;
}

//? Optional: Get password strength for UI feedback
PasswordStrength getPasswordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.none;
  
  int strength = 0;
  
  // Length check
  if (password.length >= 8) strength++;
  if (password.length >= 12) strength++;
  if (password.length >= 16) strength++;
  
  // Character variety checks
  if (RegExp(r'[a-z]').hasMatch(password)) strength++;
  if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
  if (RegExp(r'[0-9]').hasMatch(password)) strength++;
  if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
  
  if (strength <= 2) return PasswordStrength.weak;
  if (strength <= 4) return PasswordStrength.medium;
  if (strength <= 6) return PasswordStrength.strong;
  return PasswordStrength.veryStrong;
}

enum PasswordStrength {
  none,
  weak,
  medium,
  strong,
  veryStrong,
}