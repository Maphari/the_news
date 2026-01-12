//? Model for successful registration response
class RegisterLoginUserSuccessModel {
  final String name;
  final String email;
  final String message;
  final bool success;
  final String userId;
  final String token;
  final String createdAt;
  final String updatedAt;
  final String lastLogin;

  RegisterLoginUserSuccessModel({
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLogin,
    required this.token,
    required this.name,
    required this.email,
    required this.message,
    required this.success,
  });

  //? Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': {
        'id': userId,
        'name': name,
        'email': email,
        'success': success,
        'message': message,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'lastLogin': lastLogin,
      },
    };
  }

  factory RegisterLoginUserSuccessModel.empty() {
    return RegisterLoginUserSuccessModel(
      userId: '',
      createdAt: '',
      updatedAt: '',
      lastLogin: '',
      token: '',
      name: '',
      email: '',
      message: '',
      success: false,
    );
  }

  //? Create model from JSON - matches the backend structure
  factory RegisterLoginUserSuccessModel.fromJson(Map<String, dynamic> json) {
    return RegisterLoginUserSuccessModel(
      token: json['token'] ?? '',
      userId: json['user']['id'] ?? '',
      name: json['user']['name'] ?? '',
      email: json['user']['email'] ?? '',
      success: json['user']['success'] ?? false,
      message: json['user']['message'] ?? '',
      createdAt: _parseTimestamp(json['user']['createdAt']),
      updatedAt: _parseTimestamp(json['user']['updatedAt']),
      lastLogin: json['user']['lastLogin']?.toString() ?? '',
    );
  }

  //? Helper method to parse Firestore timestamp or string
  static String _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    //? If it's already a string, return it
    if (timestamp is String) return timestamp;

    //? If it's a Map (Firestore Timestamp format)
    if (timestamp is Map) {
      final seconds = timestamp['_seconds'];
      if (seconds != null) {
        //? Convert seconds to DateTime and format as ISO string
        final dateTime = DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
          isUtc: true,
        );
        return dateTime.toIso8601String();
      }
    }

    //? Fallback to string representation
    return timestamp.toString();
  }
}
