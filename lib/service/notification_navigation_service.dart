import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/saved_articles_service.dart';
import 'package:the_news/service/social_sharing_service.dart';
import 'package:the_news/service/text_to_speech_service.dart';
import 'package:the_news/model/register_login_success_model.dart';

/// Service for handling notification navigation
class NotificationNavigationService {
  static final NotificationNavigationService instance = NotificationNavigationService._init();
  NotificationNavigationService._init();

  final AuthService _authService = AuthService();
  final ApiClient _api = ApiClient.instance;
  final SavedArticlesService _savedArticlesService = SavedArticlesService.instance;
  final SocialSharingService _socialSharingService = SocialSharingService.instance;
  final TextToSpeechService _ttsService = TextToSpeechService.instance;
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
        userId: userData['id'] ?? userData['userId'] ?? '',
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
          await _navigateToArticle(context, data);
          break;

        case 'publisher_update':
          await _navigateToArticle(context, data);
          break;

        case 'comment_reply':
          await _navigateToArticleComments(context, data);
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
  Future<void> _navigateToArticle(BuildContext context, Map<String, dynamic> data) async {
    final articleId = data['articleId'] as String?;
    if (articleId == null) {
      log('⚠️ No article ID in notification data');
      return;
    }

    log('📍 Navigating to article: $articleId');

    final article = await _fetchArticleById(articleId);
    if (article == null) {
      _showSnackBar('Unable to open article right now');
      return;
    }
    if (!context.mounted) return;

    Navigator.pushNamed(
      context,
      AppRoutes.articleDetail,
      arguments: article,
    );
  }

  /// Navigate to article comments section
  Future<void> _navigateToArticleComments(BuildContext context, Map<String, dynamic> data) async {
    final articleId = data['articleId'] as String?;
    final commentId = data['commentId'] as String?;

    if (articleId == null) {
      log('⚠️ No article ID in notification data');
      return;
    }

    log('📍 Navigating to article comments: article=$articleId, comment=$commentId');

    _showSnackBar('Opening comments...');

    await _navigateToArticle(context, data);
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
          await _handleListenAction(data);
          break;

        case 'save_later':
          final articleId = data['articleId'] as String?;
          if (articleId != null) {
            log('💾 Save for later: $articleId');
            await _handleSaveAction(articleId);
          }
          break;

        case 'share':
          log('📤 Share action triggered');
          await _handleShareAction(data);
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

  Future<ArticleModel?> _fetchArticleById(String articleId) async {
    try {
      final response = await _api.get(
        'articles/$articleId',
        timeout: const Duration(seconds: 15),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        final articleJson = data['article'] as Map<String, dynamic>?;
        if (articleJson != null) {
          return ArticleModel.fromJson(articleJson);
        }
      } else {
        log('⚠️ Failed to fetch article: ${_api.getErrorMessage(response)}');
      }
    } catch (e) {
      log('⚠️ Error fetching article: $e');
    }
    return null;
  }

  Future<void> _handleSaveAction(String articleId) async {
    final userData = await _authService.getCurrentUser();
    final userId = userData?['id'] as String? ?? userData?['userId'] as String?;
    if (userId == null) {
      _showSnackBar('Please sign in to save articles');
      return;
    }

    final success = await _savedArticlesService.saveArticle(userId, articleId);
    if (success) {
      _showSnackBar('Saved for later');
    } else {
      _showSnackBar('Could not save article');
    }
  }

  Future<void> _handleShareAction(Map<String, dynamic> data) async {
    final articleId = data['articleId'] as String?;
    if (articleId == null) return;

    final article = await _fetchArticleById(articleId);
    if (article == null) {
      _showSnackBar('Unable to share article right now');
      return;
    }

    try {
      final context = _navigatorKey?.currentContext;
      if (context == null || !context.mounted) return;
      final canShare = await _socialSharingService.recordShareActivity(
        article,
        platform: 'system',
        shareToFeed: true,
        context: context,
      );
      if (!canShare) return;
      if (!context.mounted) return;
      await _socialSharingService.shareArticle(
        article,
        context: context,
      );
      if (context.mounted) {
        _showSnackBar('Article shared');
      }
    } catch (e) {
      _showSnackBar('Share failed');
    }
  }

  Future<void> _handleListenAction(Map<String, dynamic> data) async {
    final articleId = data['articleId'] as String?;
    if (articleId == null) return;

    final article = await _fetchArticleById(articleId);
    if (article == null) {
      _showSnackBar('Unable to play audio right now');
      return;
    }

    await _ttsService.initialize();
    final text = [
      article.title,
      article.description,
      article.content,
    ].where((part) => part.trim().isNotEmpty).join('\n\n');
    await _ttsService.speak(text);
  }

  void _showSnackBar(String message) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
