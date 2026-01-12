import 'dart:async';
import 'package:flutter/material.dart';
import 'package:the_news/config/env_config.dart';
import 'package:the_news/model/otp_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/model/register_user_model.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/subscription_service.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/view/widgets/show_message_widget.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

final _authService = AuthService();
final _subscriptionService = SubscriptionService.instance;
final env = EnvConfig();
final String? baseUrl = env.get('API_BASE_URL');

class OtpController {
  final RegisterLoginUserSuccessModel user;
  final RegisterUserModel registerUserModel;

  static const int otpLength = 6;
  static const int timeoutSeconds = 60;

  Timer? _timer;

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<bool> canResend = ValueNotifier(false);
  final ValueNotifier<bool> hasError = ValueNotifier<bool>(false);
  final ValueNotifier<int> secondsRemaining = ValueNotifier(timeoutSeconds);

  final List<TextEditingController> textControllers = List.generate(
    otpLength,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(
    otpLength,
    (_) => FocusNode(),
  );

  OtpController({required this.user, required this.registerUserModel});

  String get otp => textControllers.map((c) => c.text).join();

  String get timerText {
    final s = secondsRemaining.value;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  Future<(String, String)> sendOtp({
    required String email,
    required String names,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/send-otp');
    late String message;
    late String otpCode;

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{'Content-Type': 'application/json'},
        body: convert.jsonEncode({'email': email, 'name': names}),
      );
      if (response.statusCode == 200) {
        final otpModel = _populateData(body: response.body);
        message = otpModel.message;
        otpCode = otpModel.otp;
      } else {
        final otpModel = _populateData(body: response.body);
        message = otpModel.message;
        otpCode = '';
      }
    } catch (e) {
      message = 'Internal sever error while sending OTP';
      otpCode = '';
    }

    return (message, otpCode);
  }

  OtpModel _populateData({required String body}) {
    final otpJson = convert.jsonDecode(body);
    return OtpModel.fromJson(otpJson);
  }

  Future<void> verifyOtpCodeAndSaveUser({
    required BuildContext context,
    required String userOtp,
  }) async {
    if (otp.length != 6) {
      errorMessage(context: context, message: 'Please enter all 6 digits');
      return;
    }

    isLoading.value = true;
    hasError.value = false;
    final uri = Uri.parse('$baseUrl/auth/verify-otp_save-user');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: convert.jsonEncode({
          'userOtp': userOtp,
          'generatedOtp': otp,
          'names': user.name,
          'email': user.email,
          'password': registerUserModel.password,
          'confirmPassword': registerUserModel.confirmPassword,
          'acceptedTerms': registerUserModel.acceptedTerms,
        }),
      );

      if (response.statusCode == 201) {
        RegisterLoginUserSuccessModel data =
            RegisterLoginUserSuccessModel.fromJson(
              convert.jsonDecode(response.body),
            );

        //? STORE TOKEN AND USER DATA using AuthService
        await _authService.saveAuthData(
          token: data.token,
          userData: {
            'id': data.userId,
            'name': data.name,
            'email': data.email,
            'createdAt': data.createdAt,
            'updatedAt': data.updatedAt,
            'lastLogin': data.lastLogin,
          },
        );

        //? START 7-DAY FREE TRIAL FOR NEW USERS
        try {
          await _subscriptionService.initializeForUser(data.userId);
          final trialStarted = await _subscriptionService.startFreeTrial(data.userId);

          if (!context.mounted) return;

          if (trialStarted) {
            successMessage(
              context: context,
              message: 'Email verified! Your 7-day premium trial has started.',
            );
          } else {
            successMessage(
              context: context,
              message: 'Email verified successfully!',
            );
          }
        } catch (e) {
          // If trial fails, still proceed but with basic success message
          if (!context.mounted) return;
          successMessage(
            context: context,
            message: 'Email verified successfully!',
          );
        }

        if (!context.mounted) return;
        AppRoutes.navigateTo(
          context,
          AppRoutes.home,
          arguments: data,
          replace: true,
        );
      } else {
        // Handle error response
        hasError.value = true; // Set error state

        if (!context.mounted) return;

        try {
          final errorData = convert.jsonDecode(response.body);
          final errorMsg = errorData['message'] ?? 'Verification failed';
          errorMessage(context: context, message: errorMsg);
        } catch (_) {
          errorMessage(
            context: context,
            message: 'Verification failed. Please try again.',
          );
        }
      }
    } catch (_) {
      hasError.value = true; // Set error state
      if (!context.mounted) return;
      errorMessage(context: context, message: 'Invalid OTP. Try again.');
    } finally {
      if (context.mounted) isLoading.value = false;
    }
  }

  void startTimer() {
    _timer?.cancel();
    secondsRemaining.value = timeoutSeconds;
    canResend.value = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  void onChanged(String value, int index) {
    if (value.isNotEmpty && index < otpLength - 1) {
      focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  void resend() {
    for (final c in textControllers) {
      c.clear();
    }
    focusNodes.first.requestFocus();
    startTimer();
    sendOtp(email: user.email, names: user.name);
  }

  void dispose() {
    _timer?.cancel();
    for (final c in textControllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    isLoading.dispose();
    canResend.dispose();
    secondsRemaining.dispose();
  }
}
