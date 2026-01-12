import 'package:flutter/foundation.dart';
import 'package:the_news/service/subscription_service.dart';
import 'package:the_news/service/news_api_service.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/service/theme_service.dart';
import 'package:the_news/service/app_rating_service.dart';
import 'package:the_news/service/location_service.dart';
import 'package:the_news/service/payment_service.dart';
import 'package:the_news/config/env_config.dart';

/// Centralized app initialization service
///
/// Initializes all required services when app starts:
/// - Subscription service
/// - News API service
/// - News provider
class AppInitializationService {
  static final AppInitializationService instance = AppInitializationService._init();

  bool _isInitialized = false;
  String? _initializationError;

  AppInitializationService._init();

  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;

  /// Initialize all app services
  ///
  /// Call this early in app lifecycle (in main() or app startup)
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) {
      debugPrint('App already initialized');
      return;
    }

    debugPrint('🚀 Initializing Mindful News app...');

    try {
      // 0. Initialize theme service
      debugPrint('🎨 Initializing theme service...');
      final themeService = ThemeService.instance;
      await themeService.initialize();
      debugPrint('✅ Theme service ready (${themeService.themeModeName} mode)');

      // 1. Initialize subscription service
      debugPrint('📱 Initializing subscription service...');
      final subscriptionService = SubscriptionService.instance;

      if (userId != null) {
        await subscriptionService.initializeForUser(userId);
        debugPrint('✅ Subscription initialized for user: $userId');
      } else {
        debugPrint('⚠️ No userId provided - subscription will initialize on login');
      }

      // 2. Initialize News API service
      debugPrint('📰 Initializing news API service...');
      final newsApiService = NewsApiService.instance;
      await newsApiService.initialize();

      if (newsApiService.isConfigured) {
        debugPrint('✅ News API configured and ready');
      } else {
        debugPrint('⚠️ News API not configured - using dummy data');
        debugPrint('   Add NEWS_API_KEY to .env to enable real news');
      }

      // 3. Initialize news provider and load initial articles
      debugPrint('📚 Loading initial news articles...');
      final newsProvider = NewsProviderService.instance;
      await newsProvider.initialize();
      debugPrint('✅ News articles loaded');

      // Note: The following services no longer require explicit initialization
      // after refactoring to use ApiClient. They initialize automatically on first use.
      // - SavedArticlesService
      // - EngagementService
      // - DislikedArticlesService
      // - FollowedPublishersService
      // - CommentsService

      debugPrint('✅ Backend services ready (auto-initialized on first use)');

      // 9. Initialize app rating service
      debugPrint('⭐ Initializing app rating service...');
      final appRatingService = AppRatingService.instance;
      await appRatingService.initialize();
      debugPrint('✅ App rating service ready');

      // 10. Initialize location service
      debugPrint('📍 Initializing location service...');
      final locationService = LocationService.instance;
      await locationService.initialize();
      debugPrint('✅ Location service ready');

      // 11. Initialize payment service (Paystack)
      debugPrint('💳 Initializing payment service...');
      final paymentService = PaymentService.instance;
      final paystackPublicKey = EnvConfig().get('PAYSTACK_PUBLIC_KEY');
      final backendBaseUrl = EnvConfig().get('API_BASE_URL');

      if (paystackPublicKey != null && backendBaseUrl != null) {
        paymentService.initialize(
          paystackPublicKey: paystackPublicKey,
          backendBaseUrl: backendBaseUrl,
        );
        debugPrint('✅ Payment service ready (Paystack configured)');
      } else {
        debugPrint('⚠️ Payment service not configured - add PAYSTACK_PUBLIC_KEY to .env');
      }

      _isInitialized = true;
      _initializationError = null;

      debugPrint('✨ App initialization complete!');
      _printInitializationSummary();
    } catch (e) {
      _isInitialized = false;
      _initializationError = e.toString();
      debugPrint('❌ App initialization failed: $e');
      rethrow;
    }
  }

  /// Reinitialize subscription for a specific user
  ///
  /// Call this after user login
  Future<void> initializeSubscriptionForUser(String userId) async {
    debugPrint('👤 Initializing subscription for user: $userId');

    try {
      final subscriptionService = SubscriptionService.instance;
      await subscriptionService.initializeForUser(userId);

      debugPrint('✅ User subscription initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize user subscription: $e');
      rethrow;
    }
  }

  /// Print initialization summary
  void _printInitializationSummary() {
    final newsProvider = NewsProviderService.instance;
    final subscriptionService = SubscriptionService.instance;

    debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📊 INITIALIZATION SUMMARY');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('News Source: ${newsProvider.isUsingApi ? "Live API" : "Demo Data"}');
    debugPrint('Articles Loaded: ${newsProvider.articles.length}');
    debugPrint('Subscription Plan: ${subscriptionService.currentPlan.name}');
    debugPrint('Premium Access: ${subscriptionService.canAccessPremiumFeatures ? "Yes" : "No"}');

    if (!subscriptionService.canAccessPremiumFeatures) {
      debugPrint('Articles Remaining Today: ${subscriptionService.remainingArticles}');
    }

    if (subscriptionService.isTrialActive) {
      debugPrint('Trial Days Remaining: ${subscriptionService.trialDaysRemaining}');
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  /// Reset initialization state (for testing)
  void reset() {
    _isInitialized = false;
    _initializationError = null;
  }
}
