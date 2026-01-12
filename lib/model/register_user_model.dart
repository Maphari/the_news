//? Model for user registration
class RegisterUserModel {
  final String names;
  final String email;
  final String password;
  final String confirmPassword;
  final bool acceptedTerms;

  RegisterUserModel({
    required this.names,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.acceptedTerms,
  });

  //? Convert model to JSON (for sending to Node/Express)
  Map<String, dynamic> toJson() {
    return {
      'names': names,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'acceptedTerms': acceptedTerms,
    };
  }

  factory RegisterUserModel.empty() {
    return RegisterUserModel(
      names: '',
      email: '',
      password: '',
      confirmPassword: '',
      acceptedTerms: false,
    );
  }

  //? Create model from JSON (optional – useful for responses)
  factory RegisterUserModel.fromJson(Map<String, dynamic> json) {
    return RegisterUserModel(
      names: json['names'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      confirmPassword: json['confirmPassword'] ?? '',
      acceptedTerms: json['acceptedTerms'] ?? false,
    );
  }
}
