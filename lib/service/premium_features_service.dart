import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_service.dart';

/// Premium features service for controlling access to paid features
/// Integrates with PaymentService to check subscription status
class PremiumFeaturesService extends ChangeNotifier {
  static final PremiumFeaturesService instance = PremiumFeaturesService._init();
  PremiumFeaturesService._init();

  final PaymentService _paymentService = PaymentService.instance;

  // Free tier limits
  static const int freeAiRequestsPerDay = 5;
  static const int freeBookmarksLimit = 50;
  static const int freeDigestsPerWeek = 2;

  // Usage tracking
  int _aiRequestsToday = 0;
  DateTime _lastAiRequestReset = DateTime.now();
  int _digestsThisWeek = 0;
  DateTime _lastDigestReset = DateTime.now();

  // Getters
  int get aiRequestsToday => _aiRequestsToday;
  int get remainingAiRequests =>
      _paymentService.isPremium ? -1 : (freeAiRequestsPerDay - _aiRequestsToday);
  int get digestsThisWeek => _digestsThisWeek;
  int get remainingDigests =>
      _paymentService.isPremium ? -1 : (freeDigestsPerWeek - _digestsThisWeek);

  /// Initialize and load usage data
  Future<void> initialize() async {
    await _loadUsageData();
    _resetCountersIfNeeded();
    log('✅ Premium features service initialized');
  }

  /// Check if user can use AI features
  Future<bool> canUseAI() async {
    if (_paymentService.isPremium) {
      return true; // Premium users have unlimited AI
    }

    _resetCountersIfNeeded();

    if (_aiRequestsToday >= freeAiRequestsPerDay) {
      log('❌ AI request limit reached for free tier');
      return false;
    }

    return true;
  }

  /// Track AI usage (call after successful AI request)
  Future<void> trackAiUsage() async {
    if (_paymentService.isPremium) {
      return; // Don't track for premium users
    }

    _aiRequestsToday++;
    await _saveUsageData();
    notifyListeners();
    log('📊 AI requests today: $_aiRequestsToday/$freeAiRequestsPerDay');
  }

  /// Check if user has ad-free experience
  bool isAdFree() {
    return _paymentService.isPremium;
  }

  /// Check if user can create custom digests
  Future<bool> canCreateCustomDigest() async {
    if (_paymentService.isPremium) {
      return true; // Premium users have unlimited digests
    }

    _resetCountersIfNeeded();

    if (_digestsThisWeek >= freeDigestsPerWeek) {
      log('❌ Custom digest limit reached for free tier');
      return false;
    }

    return true;
  }

  /// Track digest creation (call after creating digest)
  Future<void> trackDigestCreation() async {
    if (_paymentService.isPremium) {
      return; // Don't track for premium users
    }

    _digestsThisWeek++;
    await _saveUsageData();
    notifyListeners();
    log('📊 Digests this week: $_digestsThisWeek/$freeDigestsPerWeek');
  }

  /// Check if user can access advanced analytics
  bool canAccessAdvancedAnalytics() {
    return _paymentService.isPremium;
  }

  /// Check if user can access unlimited bookmarks
  Future<bool> canAddBookmark(int currentBookmarkCount) async {
    if (_paymentService.isPremium) {
      return true; // Premium users have unlimited bookmarks
    }

    if (currentBookmarkCount >= freeBookmarksLimit) {
      log('❌ Bookmark limit reached for free tier');
      return false;
    }

    return true;
  }

  /// Check if user can customize AI model
  bool canCustomizeAiModel() {
    return _paymentService.isPremium;
  }

  /// Check if user can download articles for offline reading
  bool canDownloadForOffline() {
    return _paymentService.isPremium;
  }

  /// Check if user can access premium news sources
  bool canAccessPremiumSources() {
    return _paymentService.isPremium;
  }

  /// Get feature limit message for UI display
  String getFeatureLimitMessage(String featureName) {
    if (!_paymentService.isPremium) {
      switch (featureName) {
        case 'ai':
          return 'Free tier: $remainingAiRequests AI requests remaining today';
        case 'digest':
          return 'Free tier: $remainingDigests custom digests remaining this week';
        case 'bookmarks':
          return 'Free tier: Maximum $freeBookmarksLimit bookmarks';
        case 'analytics':
          return 'Premium feature: Advanced analytics requires subscription';
        case 'offline':
          return 'Premium feature: Offline downloads require subscription';
        case 'sources':
          return 'Premium feature: Premium news sources require subscription';
        default:
          return 'This is a premium feature';
      }
    }
    return '';
  }

  /// Get upgrade prompt message
  String getUpgradePromptMessage(String featureName) {
    switch (featureName) {
      case 'ai':
        return 'Upgrade to Premium for unlimited AI summaries and translations!';
      case 'digest':
        return 'Upgrade to Premium for unlimited custom news digests!';
      case 'bookmarks':
        return 'Upgrade to Premium for unlimited bookmarks!';
      case 'analytics':
        return 'Upgrade to Premium to access advanced reading analytics!';
      case 'offline':
        return 'Upgrade to Premium to download articles for offline reading!';
      case 'sources':
        return 'Upgrade to Premium to access exclusive news sources!';
      case 'ads':
        return 'Upgrade to Premium for an ad-free experience!';
      default:
        return 'Upgrade to Premium to unlock all features!';
    }
  }

  /// Reset daily/weekly counters if needed
  void _resetCountersIfNeeded() {
    final now = DateTime.now();

    // Reset AI counter if it's a new day
    if (!_isSameDay(_lastAiRequestReset, now)) {
      _aiRequestsToday = 0;
      _lastAiRequestReset = now;
      log('🔄 Reset AI request counter (new day)');
    }

    // Reset digest counter if it's a new week
    if (!_isSameWeek(_lastDigestReset, now)) {
      _digestsThisWeek = 0;
      _lastDigestReset = now;
      log('🔄 Reset digest counter (new week)');
    }
  }

  /// Check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Check if two dates are in the same week (Monday-Sunday)
  bool _isSameWeek(DateTime date1, DateTime date2) {
    // Get Monday of each week
    final monday1 = date1.subtract(Duration(days: date1.weekday - 1));
    final monday2 = date2.subtract(Duration(days: date2.weekday - 1));

    return _isSameDay(monday1, monday2);
  }

  /// Save usage data to local storage
  Future<void> _saveUsageData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('aiRequestsToday', _aiRequestsToday);
      await prefs.setString('lastAiRequestReset', _lastAiRequestReset.toIso8601String());
      await prefs.setInt('digestsThisWeek', _digestsThisWeek);
      await prefs.setString('lastDigestReset', _lastDigestReset.toIso8601String());
    } catch (e) {
      log('❌ Error saving usage data: $e');
    }
  }

  /// Load usage data from local storage
  Future<void> _loadUsageData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _aiRequestsToday = prefs.getInt('aiRequestsToday') ?? 0;
      final aiResetStr = prefs.getString('lastAiRequestReset');
      if (aiResetStr != null) {
        _lastAiRequestReset = DateTime.parse(aiResetStr);
      }

      _digestsThisWeek = prefs.getInt('digestsThisWeek') ?? 0;
      final digestResetStr = prefs.getString('lastDigestReset');
      if (digestResetStr != null) {
        _lastDigestReset = DateTime.parse(digestResetStr);
      }

      log('✅ Loaded usage data: AI=$_aiRequestsToday, Digests=$_digestsThisWeek');
    } catch (e) {
      log('❌ Error loading usage data: $e');
    }
  }

  /// Clear all usage data (for testing or logout)
  Future<void> clearUsageData() async {
    _aiRequestsToday = 0;
    _lastAiRequestReset = DateTime.now();
    _digestsThisWeek = 0;
    _lastDigestReset = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('aiRequestsToday');
    await prefs.remove('lastAiRequestReset');
    await prefs.remove('digestsThisWeek');
    await prefs.remove('lastDigestReset');

    notifyListeners();
    log('🗑️ Cleared all usage data');
  }

  /// Get feature status summary for settings/profile page
  Map<String, dynamic> getFeatureStatus() {
    return {
      'isPremium': _paymentService.isPremium,
      'subscriptionType': _paymentService.subscriptionType,
      'subscriptionEndDate': _paymentService.subscriptionEndDate,
      'aiRequests': {
        'used': _aiRequestsToday,
        'limit': _paymentService.isPremium ? 'unlimited' : freeAiRequestsPerDay,
        'remaining': remainingAiRequests,
      },
      'digests': {
        'used': _digestsThisWeek,
        'limit': _paymentService.isPremium ? 'unlimited' : freeDigestsPerWeek,
        'remaining': remainingDigests,
      },
      'bookmarksLimit': _paymentService.isPremium ? 'unlimited' : freeBookmarksLimit,
      'features': {
        'adFree': isAdFree(),
        'advancedAnalytics': canAccessAdvancedAnalytics(),
        'customAiModel': canCustomizeAiModel(),
        'offlineDownload': canDownloadForOffline(),
        'premiumSources': canAccessPremiumSources(),
      },
    };
  }

  /// Show upgrade dialog helper (returns true if user should be prompted)
  bool shouldShowUpgradePrompt(String featureName) {
    return !_paymentService.isPremium;
  }
}
