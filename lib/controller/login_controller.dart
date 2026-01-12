import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:the_news/config/env_config.dart';
import 'package:the_news/model/login_user_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/rememberme_service.dart';
import 'dart:convert' as convert;
import 'package:the_news/state/form_state.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/view/widgets/show_message_widget.dart';

final _authService = AuthService();
final _rememberMeService = RememberMeService();
final env = EnvConfig();
final String? baseUrl = env.get('API_BASE_URL');

//? Handle login action
Future<bool> handleLogin({
  required GlobalKey<FormState> formKey,
  required BuildContext context,
  required LoginUserModel loginUserModel,
}) async {
  if (formKey.currentState!.validate()) {
    isLoginPageLoading.value = true;
    final uri = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: convert.jsonEncode({
          'email': loginUserModel.email,
          'password': loginUserModel.password,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final jsonResponse = convert.jsonDecode(response.body);
          RegisterLoginUserSuccessModel data =
              RegisterLoginUserSuccessModel.fromJson(jsonResponse);

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

          if (!context.mounted) return false;
          successMessage(context: context, message: data.message);

          AppRoutes.navigateTo(
            context,
            AppRoutes.home,
            arguments: data,
            replace: true,
          );

          return true;
        } catch (e) {
          if (!context.mounted) return false;
          errorMessage(context: context, message: 'Error parsing response');
          return false;
        }
      } else {
        //? Handle error responses
        String serverErrorMessage = 'Failed to login';

        try {
          final errorResponse = convert.jsonDecode(response.body);

          if (errorResponse['error'] != null) {
            serverErrorMessage = errorResponse['error'];
          } else if (errorResponse['message'] != null) {
            serverErrorMessage = errorResponse['message'];
          }
        } catch (e) {
          serverErrorMessage = 'Failed to login: ${response.reasonPhrase}';
        }

        if (!context.mounted) return false;
        errorMessage(context: context, message: serverErrorMessage);
        return false;
      }
    } catch (e) {
      if (!context.mounted) return false;
      errorMessage(context: context, message: 'An error occurred: $e');
      return false;
    } finally {
      isLoginPageLoading.value = false;
    }
  }
  return false;
}

//? Load saved credentials on app start
Future<void> loadSavedCredentials({required bool mounted}) async {
  try {
    final credentials = await _rememberMeService.getSavedCredentials();
    final rememberMe = await _rememberMeService.getRememberMe();

    if (mounted) {
      isLoginPageRememberMe.value = rememberMe;
      emailTextController.value.text = credentials['email'] ?? '';
      passwordTextController.value.text = credentials['password'] ?? '';
    }
  } catch (e) {
    log('Error loading saved credentials: $e');
  }
}

//? Handle remember me checkbox
Future<bool> handleRememberMeToggle(
  bool? value, {
  required String email,
  required String password,
}) async {
  final newValue = value ?? false;
  isLoginPageRememberMe.value = newValue;

  try {
    await _rememberMeService.saveRememberMe(
      rememberMe: newValue,
      email: newValue ? email : null,
      password: newValue ? password : null,
    );
    return true;
  } catch (e) {
    debugPrint('Error saving remember me preference: $e');
    return false;
  }
}

//? Handle login with remember me
Future<void> handleLoginWithRememberMe({
  required BuildContext context,
  required String email,
  required String password,
  required GlobalKey<FormState> formKey,
}) async {
  if (formKey.currentState?.validate() ?? false) {
    //? Save credentials if remember me is checked
    if (isLoginPageRememberMe.value) {
      try {
        await _rememberMeService.saveRememberMe(
          rememberMe: true,
          email: email,
          password: password,
        );
      } catch (e) {
        debugPrint('Error saving credentials: $e');
      }
    }

    //? Proceed with login
    LoginUserModel loginUserModel = LoginUserModel(
      email: email,
      password: password,
    );

    if (context.mounted) {
      handleLogin(
        formKey: formKey,
        context: context,
        loginUserModel: loginUserModel,
      );
    }
  }
}

//? Handle remember me action
Future<void> handleRememberMe({
  required BuildContext context,
  required bool rememberMe,
  String? email,
  String? password,
}) async {
  final rememberMeService = RememberMeService();

  try {
    await rememberMeService.saveRememberMe(
      rememberMe: rememberMe,
      email: email,
      password: password,
    );
  } catch (e) {
    //? Handle errors
    if (context.mounted) {
      errorMessage(context: context, message: 'Error saving preferences: $e');
    }
  }
}
