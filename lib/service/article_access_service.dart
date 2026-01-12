import 'package:flutter/material.dart';
import 'package:the_news/service/subscription_service.dart';
import 'package:the_news/service/dialog_frequency_service.dart';
import 'package:the_news/view/subscription/article_limit_dialog.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/utils/haptic_service.dart';

/// Service to manage article access based on subscription status
class ArticleAccessService {
  static final ArticleAccessService instance = ArticleAccessService._init();
  final _subscriptionService = SubscriptionService.instance;
  final _dialogFrequencyService = DialogFrequencyService.instance;

  ArticleAccessService._init();

  /// Check if user can access an article and navigate if allowed
  /// Returns true if navigation occurred, false if blocked
  Future<bool> navigateToArticle(
    BuildContext context,
    ArticleModel article,
  ) async {
    // Check if user can read more articles
    final canRead = await _subscriptionService.trackArticleRead();

    if (!canRead) {
      // Check if we should show the dialog (max 2 times per day)
      final shouldShowDialog = await _dialogFrequencyService.shouldShowArticleLimitDialog();

      if (shouldShowDialog) {
        // Show limit dialog and track that it was shown
        await HapticService.error();
        if (context.mounted) {
          await ArticleLimitDialog.show(context);
          await _dialogFrequencyService.trackArticleLimitDialogShown();
        }
      } else {
        // Dialog already shown 2 times today - just show haptic feedback
        HapticService.light();
      }
      return false;
    }

    // User can read - navigate to article
    if (context.mounted) {
      await AppRoutes.navigateTo(
        context,
        AppRoutes.articleDetail,
        arguments: article,
      );
      return true;
    }

    return false;
  }

  /// Check subscription status without tracking
  Future<bool> canAccessArticle() async {
    if (_subscriptionService.canAccessPremiumFeatures) {
      return true;
    }

    return !_subscriptionService.hasReachedLimit;
  }

  /// Get remaining article count for display
  int get remainingArticles => _subscriptionService.remainingArticles;

  /// Check if user has premium access
  bool get hasPremiumAccess => _subscriptionService.canAccessPremiumFeatures;

  /// Get subscription status text for UI
  String getSubscriptionStatusText() {
    if (_subscriptionService.isPremium) {
      return 'Premium';
    } else if (_subscriptionService.isTrialActive) {
      final daysRemaining = _subscriptionService.trialDaysRemaining;
      return 'Trial: $daysRemaining days left';
    } else {
      return 'Free: $remainingArticles articles left today';
    }
  }
}
