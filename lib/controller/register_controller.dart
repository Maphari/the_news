import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:the_news/config/env_config.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/model/register_user_model.dart';
import 'dart:convert' as convert;
import 'package:the_news/state/form_state.dart';
import 'package:the_news/utils/form_validations_utils.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/view/widgets/show_message_widget.dart';

final env = EnvConfig();
final String? baseUrl = env.get('API_BASE_URL');
final String alreadyExists = 'Account already exists. Please login';

Future<(bool, RegisterLoginUserSuccessModel)> handleRegister({
  required GlobalKey<FormState> formKey,
  required BuildContext context,
  required bool acceptTerms,
  required RegisterUserModel registerUserModel,
}) async {
  if (formKey.currentState!.validate()) {
    if (!validateAcceptTerms(acceptTerms, context: context)) {
      return (false, RegisterLoginUserSuccessModel.empty());
    }

    isRegisterPageLoading.value = true;
    final uri = Uri.parse('$baseUrl/register');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: convert.jsonEncode({
          'names': registerUserModel.names,
          'email': registerUserModel.email,
          'password': registerUserModel.password,
          'confirmPassword': registerUserModel.confirmPassword,
          'acceptedTerms': registerUserModel.acceptedTerms,
        }),
      );

      if (response.statusCode == 200) {
        RegisterLoginUserSuccessModel data =
            RegisterLoginUserSuccessModel.fromJson(
              convert.jsonDecode(response.body),
            );

        if (!context.mounted) {
          return (false, RegisterLoginUserSuccessModel.empty());
        }
        successMessage(context: context, message: data.message);

        return (false, data);
      } else {
        //? Handle error responses
        String serverErrorMessage = 'Failed to Register Account';

        try {
          final errorResponse = convert.jsonDecode(response.body);
          if (errorResponse['error'] != null) {
            serverErrorMessage = errorResponse['error'];
          } else if (errorResponse['message'] != null) {
            serverErrorMessage = errorResponse['message'];
          }
        } catch (e) {
          serverErrorMessage = 'Failed to register: ${response.reasonPhrase}';
        }

        if (!context.mounted) {
          return (false, RegisterLoginUserSuccessModel.empty());
        }
        errorMessage(context: context, message: serverErrorMessage);
        message.value = serverErrorMessage;
        return (false, RegisterLoginUserSuccessModel.empty());
      }
    } catch (e) {
      if (!context.mounted) {
        return (false, RegisterLoginUserSuccessModel.empty());
      }
      errorMessage(context: context, message: 'An error occurred: $e');
      return (false, RegisterLoginUserSuccessModel.empty());
    } finally {
      isRegisterPageLoading.value = false;
    }
  }
  return (false, RegisterLoginUserSuccessModel.empty());
}

void handleAuthButtonPress({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required bool isLoading,
  required String names,
  required String email,
  required String password,
  required String confirmPassword,
  required bool acceptedTerms,
}) async {
  if (isLoading) {
    return;
  } else {
    //? Give model data from the form
    RegisterUserModel registerUserModel = RegisterUserModel(
      names: names,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      acceptedTerms: acceptedTerms,
    );

    //? check if user is autheticated or not
    final (_, data) = await handleRegister(
      formKey: formKey,
      context: context,
      acceptTerms: acceptedTerms,
      registerUserModel: registerUserModel,
    );

    if (!context.mounted) return;
    if (formKey.currentState!.validate()) {
      //? Navigate to login if account exists else to opt screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (message.value == alreadyExists) {
          AppRoutes.navigateTo(context, AppRoutes.login);
        } else {
          AppRoutes.navigateTo(
            context,
            AppRoutes.otp,
            arguments: {
              'successUser': data,
              'registerUserModel': registerUserModel,
            },
          );
        }
      });
    }
  }
}
