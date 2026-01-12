//? Model for user registration
class LoginUserModel {
  final String email;
  final String password;

  LoginUserModel({required this.email, required this.password});

  //? Convert model to JSON (for sending to Node/Express)
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }

  //? Create model from JSON (optional – useful for responses)
  factory LoginUserModel.fromJson(Map<String, dynamic> json) {
    return LoginUserModel(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
    );
  }
}
