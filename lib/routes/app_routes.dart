import 'package:flutter/material.dart';
import 'package:the_news/view/main_scaffold/main_scaffold.dart';
import 'package:the_news/view/article_details/article_detail_page.dart';
import 'package:the_news/view/login/login_page.dart';
import 'package:the_news/view/register/register_page.dart';
import 'package:the_news/view/otp/otp_page.dart';
import 'package:the_news/view/subscription/subscription_paywall_page.dart';
import 'package:the_news/view/subscription/subscription_settings_page.dart';
import 'package:the_news/view/category/category_detail_page.dart';
import 'package:the_news/view/notifications/notification_history_page.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/model/register_user_model.dart';
import 'package:the_news/utils/page_transitions.dart';

/// Centralized route names for the app
class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';

  // Main app routes
  static const String home = '/home';
  static const String explore = '/explore';
  static const String saved = '/saved';
  static const String profile = '/profile';
  static const String articleDetail = '/article-detail';
  static const String categoryDetail = '/category-detail';
  static const String socialMedia = '/social';

  // Subscription routes
  static const String subscriptionPaywall = '/subscription-paywall';
  static const String subscriptionSettings = '/subscription-settings';

  // Notification routes
  static const String notificationHistory = '/notification-history';

  // Prevent instantiation
  AppRoutes._();

  /// Generate routes for the app
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );

      case otp:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OtpVerificationPage(
            successUser: args['successUser'] as RegisterLoginUserSuccessModel,
            registerUserModel: args['registerUserModel'] as RegisterUserModel,
          ),
          settings: settings,
        );

      case home:
        final user = settings.arguments as RegisterLoginUserSuccessModel;
        return MaterialPageRoute(
          builder: (_) => MainScaffold(user: user, initialIndex: 0),
          settings: settings,
        );

      case explore:
        final user = settings.arguments as RegisterLoginUserSuccessModel;
        return MaterialPageRoute(
          builder: (_) => MainScaffold(user: user, initialIndex: 1),
          settings: settings,
        );

      case socialMedia:
        final user = settings.arguments as RegisterLoginUserSuccessModel;
        return MaterialPageRoute(
          builder: (_) => MainScaffold(user: user, initialIndex: 2),
          settings: settings,
        );

      case saved:
        final user = settings.arguments as RegisterLoginUserSuccessModel;
        return MaterialPageRoute(
          builder: (_) => MainScaffold(user: user, initialIndex: 3),
          settings: settings,
        );

      case profile:
        final user = settings.arguments as RegisterLoginUserSuccessModel;
        return MaterialPageRoute(
          builder: (_) => MainScaffold(user: user, initialIndex: 4),
          settings: settings,
        );

      case articleDetail:
        final article = settings.arguments as ArticleModel;
        return PageTransitions.fadeSlideTransition(
          ArticleDetailPage(article: article),
        );

      case categoryDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return PageTransitions.fadeSlideTransition(
          CategoryDetailPage(
            category: args['category'] as String,
            categoryColor: args['color'] as Color,
            categoryIcon: args['icon'] as IconData,
          ),
        );

      case subscriptionPaywall:
        return MaterialPageRoute(
          builder: (_) => const SubscriptionPaywallPage(),
          settings: settings,
        );

      case subscriptionSettings:
        return MaterialPageRoute(
          builder: (_) => const SubscriptionSettingsPage(),
          settings: settings,
        );

      case notificationHistory:
        return MaterialPageRoute(
          builder: (_) => const NotificationHistoryPage(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  /// Navigate to a named route
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) {
    if (replace) {
      return Navigator.pushReplacementNamed<T, void>(
        context,
        routeName,
        arguments: arguments,
      );
    }
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and remove all previous routes
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Pop the current route
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }

  /// Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
}
