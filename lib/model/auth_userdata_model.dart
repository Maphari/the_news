class AuthUserdataModel {
  final String id;
  final String email;
  final String name;
  final String? picture;
  
  AuthUserdataModel({
    required this.id,
    required this.email,
    required this.name,
    this.picture,
  });
  
  factory AuthUserdataModel.fromJson(Map<String, dynamic> json) {
    return AuthUserdataModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      picture: json['picture'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'picture': picture,
    };
  }
}