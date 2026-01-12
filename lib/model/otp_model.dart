class OtpModel {
  final bool success;
  final String otp;
  final String message;

  OtpModel({required this.success, required this.otp, required this.message});

  Map<String, dynamic> toJson() {
    return {'opt': otp, 'success': success, 'message': message};
  }

  //? Create model from JSON (optional – useful for responses)
  factory OtpModel.fromJson(Map<String, dynamic> json) {
    return OtpModel(
      otp: json['otp'] ?? '',
      success: json['success'] ?? '',
      message: json['message'] ?? ''
    );
  }
}
