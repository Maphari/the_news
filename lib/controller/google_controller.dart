import 'package:flutter/material.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/view/widgets/show_message_widget.dart';

final _authService = AuthService();

Future<bool> handleGoogleSignIn(BuildContext context) async {
  try {
    final result = await _authService.signInWithGoogle();

    if (!context.mounted) {
      return false;
    }

    if (result.success) {
      successMessage(
        context: context,
        message: 'Successfully signed in with Google',
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
        message: result.error ?? 'Google sign in failed',
      );
      return false;
    }
  } catch (e) {
    if (!context.mounted) return false;
    errorMessage(context: context, message: 'An error occurred: $e');
    return false;
  }
}
