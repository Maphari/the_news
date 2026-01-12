import 'package:flutter/material.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/view/widgets/show_message_widget.dart';

final _authService = AuthService();

//? APPLE SIGN IN HANDLER
Future<bool> handleAppleSignIn(BuildContext context) async {
  try {
    final result = await _authService.signInWithApple();

    if (!context.mounted) return false;

    if (result.success) {
      successMessage(
        context: context,
        message: 'Successfully signed in with Apple',
      );

      AppRoutes.navigateTo(
        context,
        AppRoutes.home,
        arguments: result.user,
        replace: true,
      );
      
      return true;
    } else {
      errorMessage(
        context: context,
        message: result.error ?? 'Apple sign in failed',
      );
      
      return false;
    }
  } catch (e) {
    if (!context.mounted) return false;
    errorMessage(context: context, message: 'An error occurred: $e');
    return false;
  }
}
