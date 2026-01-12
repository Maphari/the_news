import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/model/register_login_success_model.dart';

/// Service for handling notification navigation
class NotificationNavigationService {
  static final NotificationNavigationService instance = NotificationNavigationService._init();
  NotificationNavigationService._init();

  final AuthService _authService = AuthService();
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Set the navigator key (should be called in main.dart)
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Handle notification tap and navigate to appropriate screen
  Future<void> handleNotificationTap(String? payload) async {
    if (payload == null || _navigatorKey == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;

      log('📍 Navigating from notification: type=$type');

      // Get current user data for navigation
      final userData = await _authService.getCurrentUser();
      if (userData == null) {
        log('⚠️ User not authenticated, cannot navigate');
        return;
      }

      final user = RegisterLoginUserSuccessModel(
        token: '',
        userId: userData['id'] ?? '',
        name: userData['name'] ?? '',
        email: userData['email'] ?? '',
        message: '',
        success: true,
        createdAt: userData['createdAt'] ?? '',
        updatedAt: userData['updatedAt'] ?? '',
        lastLogin: userData['lastLogin'] ?? '',
      );

      // Get context after async operation
      final context = _navigatorKey!.currentContext;
      if (context == null || !context.mounted) {
        log('⚠️ No context available for navigation');
        return;
      }

      // Handle different notification types
      switch (type) {
        case 'digest':
          _navigateToDigest(context, user, data);
          break;

        case 'breaking_news':
          _navigateToArticle(context, data);
          break;

        case 'publisher_update':
          _navigateToArticle(context, data);
          break;

        case 'comment_reply':
          _navigateToArticleComments(context, data);
          break;

        case 'grouped_breaking_news':
          _navigateToHome(context, user);
          break;

        case 'grouped_publisher_update':
          _navigateToHome(context, user);
          break;

        case 'grouped_comment_replies':
          _navigateToNotificationHistory(context);
          break;

        default:
          log('⚠️ Unknown notification type: $type');
          _navigateToHome(context, user);
      }
    } catch (e) {
      log('⚠️ Error handling notification tap: $e');
    }
  }

  /// Navigate to digest/home page
  void _navigateToDigest(BuildContext context, RegisterLoginUserSuccessModel user, Map<String, dynamic> data) {
    log('📍 Navigating to digest');
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.home,
      arguments: user,
    );
  }

  /// Navigate to article detail
  void _navigateToArticle(BuildContext context, Map<String, dynamic> data) {
    final articleId = data['articleId'] as String?;
    if (articleId == null) {
      log('⚠️ No article ID in notification data');
      return;
    }

    log('📍 Navigating to article: $articleId');

    // Note: We need to fetch the article first before navigating
    // For now, navigate to home and show a message
    // TODO: Implement article fetching and navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening article...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Navigate to article comments section
  void _navigateToArticleComments(BuildContext context, Map<String, dynamic> data) {
    final articleId = data['articleId'] as String?;
    final commentId = data['commentId'] as String?;

    if (articleId == null) {
      log('⚠️ No article ID in notification data');
      return;
    }

    log('📍 Navigating to article comments: article=$articleId, comment=$commentId');

    // Note: We need to fetch the article first before navigating
    // For now, navigate to home and show a message
    // TODO: Implement article fetching and navigation to comments
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening comment...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Navigate to home page
  void _navigateToHome(BuildContext context, RegisterLoginUserSuccessModel user) {
    log('📍 Navigating to home');
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.home,
      arguments: user,
    );
  }

  /// Navigate to notification history page
  void _navigateToNotificationHistory(BuildContext context) {
    log('📍 Navigating to notification history');
    Navigator.pushNamed(context, AppRoutes.notificationHistory);
  }

  /// Handle notification action (for action buttons)
  Future<void> handleNotificationAction(String action, String? payload) async {
    if (payload == null || _navigatorKey == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      log('🔘 Handling notification action: $action');

      switch (action) {
        case 'read_now':
        case 'read_article':
        case 'view_comment':
          handleNotificationTap(payload);
          break;

        case 'listen':
          log('🔊 Listen action triggered');
          // TODO: Implement audio playback
          break;

        case 'save_later':
          final articleId = data['articleId'] as String?;
          if (articleId != null) {
            log('💾 Save for later: $articleId');
            // TODO: Implement save article
          }
          break;

        case 'share':
          log('📤 Share action triggered');
          // TODO: Implement share functionality
          break;

        case 'reply':
          log('💬 Reply action triggered');
          handleNotificationTap(payload);
          break;

        case 'view_all':
          log('👀 View all action triggered');
          handleNotificationTap(payload);
          break;

        case 'mark_read':
        case 'dismiss':
          log('✅ Mark as read/dismiss');
          // Notification will be dismissed automatically
          break;

        default:
          log('⚠️ Unknown action: $action');
      }
    } catch (e) {
      log('⚠️ Error handling notification action: $e');
    }
  }
}
