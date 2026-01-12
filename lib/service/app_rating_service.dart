import 'dart:developer';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app store ratings and reviews
class AppRatingService {
  static final AppRatingService instance = AppRatingService._init();
  AppRatingService._init();

  final InAppReview _inAppReview = InAppReview.instance;

  // SharedPreferences keys
  static const String _keyLaunchCount = 'app_launch_count';
  static const String _keyLastRatingPrompt = 'last_rating_prompt_date';
  static const String _keyHasRated = 'has_rated_app';
  static const String _keyArticlesRead = 'articles_read_count';
  static const String _keyListsCreated = 'lists_created_count';
  static const String _keyNeverAskAgain = 'never_ask_rating_again';

  // Thresholds for prompting
  static const int _minLaunchCount = 5; // Show after 5 app launches
  static const int _minArticlesRead = 10; // Or after reading 10 articles
  static const int _minListsCreated = 2; // Or after creating 2 lists
  static const int _daysBetweenPrompts = 30; // Wait 30 days between prompts

  /// Initialize the rating service
  Future<void> initialize() async {
    try {
      // Increment launch count
      await _incrementLaunchCount();
      log('✅ AppRatingService initialized');
    } catch (e) {
      log('⚠️ Error initializing AppRatingService: $e');
    }
  }

  /// Check if we should show the rating prompt
  Future<bool> shouldShowRatingPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Don't show if user said never
      final neverAskAgain = prefs.getBool(_keyNeverAskAgain) ?? false;
      if (neverAskAgain) {
        log('🔕 User opted out of rating prompts');
        return false;
      }

      // Don't show if already rated
      final hasRated = prefs.getBool(_keyHasRated) ?? false;
      if (hasRated) {
        log('⭐ User has already rated the app');
        return false;
      }

      // Check if enough time has passed since last prompt
      final lastPromptDate = prefs.getString(_keyLastRatingPrompt);
      if (lastPromptDate != null) {
        final daysSinceLastPrompt = DateTime.now()
            .difference(DateTime.parse(lastPromptDate))
            .inDays;

        if (daysSinceLastPrompt < _daysBetweenPrompts) {
          log('⏰ Too soon since last prompt ($daysSinceLastPrompt days)');
          return false;
        }
      }

      // Check if user has engaged enough with the app
      final launchCount = prefs.getInt(_keyLaunchCount) ?? 0;
      final articlesRead = prefs.getInt(_keyArticlesRead) ?? 0;
      final listsCreated = prefs.getInt(_keyListsCreated) ?? 0;

      // Show if any threshold is met
      final meetsLaunchThreshold = launchCount >= _minLaunchCount;
      final meetsArticleThreshold = articlesRead >= _minArticlesRead;
      final meetsListThreshold = listsCreated >= _minListsCreated;

      final shouldShow = meetsLaunchThreshold || meetsArticleThreshold || meetsListThreshold;

      if (shouldShow) {
        log('✅ Rating prompt conditions met: launches=$launchCount, articles=$articlesRead, lists=$listsCreated');
      }

      return shouldShow;
    } catch (e) {
      log('⚠️ Error checking rating prompt conditions: $e');
      return false;
    }
  }

  /// Request the native in-app review dialog
  Future<void> requestReview() async {
    try {
      // Check if in-app review is available
      if (await _inAppReview.isAvailable()) {
        log('📝 Requesting in-app review');

        // Update last prompt date
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _keyLastRatingPrompt,
          DateTime.now().toIso8601String(),
        );

        // Request the review
        await _inAppReview.requestReview();

        log('✅ In-app review requested');
      } else {
        log('⚠️ In-app review not available on this device');

        // Fall back to opening the store
        await openStoreListing();
      }
    } catch (e) {
      log('⚠️ Error requesting review: $e');
    }
  }

  /// Open the app's store listing for manual review
  Future<void> openStoreListing() async {
    try {
      log('🏪 Opening app store listing');
      await _inAppReview.openStoreListing(
        appStoreId: '6738471749', // Replace with actual App Store ID
      );
    } catch (e) {
      log('⚠️ Error opening store listing: $e');
    }
  }

  /// Mark that the user has rated the app
  Future<void> markAsRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasRated, true);
      log('✅ Marked app as rated');
    } catch (e) {
      log('⚠️ Error marking as rated: $e');
    }
  }

  /// Mark that the user never wants to be asked again
  Future<void> neverAskAgain() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNeverAskAgain, true);
      log('🔕 User opted out of rating prompts');
    } catch (e) {
      log('⚠️ Error setting never ask again: $e');
    }
  }

  /// Increment the app launch counter
  Future<void> _incrementLaunchCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_keyLaunchCount) ?? 0;
      await prefs.setInt(_keyLaunchCount, currentCount + 1);
      log('📱 App launch count: ${currentCount + 1}');
    } catch (e) {
      log('⚠️ Error incrementing launch count: $e');
    }
  }

  /// Track when a user reads an article
  Future<void> trackArticleRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_keyArticlesRead) ?? 0;
      await prefs.setInt(_keyArticlesRead, currentCount + 1);
      log('📰 Articles read count: ${currentCount + 1}');

      // Check if we should prompt for rating
      await _checkAndPromptIfReady();
    } catch (e) {
      log('⚠️ Error tracking article read: $e');
    }
  }

  /// Track when a user creates a reading list
  Future<void> trackListCreated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_keyListsCreated) ?? 0;
      await prefs.setInt(_keyListsCreated, currentCount + 1);
      log('📚 Lists created count: ${currentCount + 1}');

      // Check if we should prompt for rating
      await _checkAndPromptIfReady();
    } catch (e) {
      log('⚠️ Error tracking list created: $e');
    }
  }

  /// Check if conditions are met and prompt for rating
  Future<void> _checkAndPromptIfReady() async {
    if (await shouldShowRatingPrompt()) {
      // Add a small delay to avoid interrupting the user
      await Future.delayed(const Duration(seconds: 2));
      await requestReview();
    }
  }

  /// Manually trigger a rating prompt (for settings or specific user actions)
  Future<void> promptUserForRating() async {
    try {
      log('👆 Manual rating prompt triggered');
      await requestReview();
    } catch (e) {
      log('⚠️ Error in manual rating prompt: $e');
    }
  }

  /// Reset all rating data (for testing purposes)
  Future<void> resetRatingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLaunchCount);
      await prefs.remove(_keyLastRatingPrompt);
      await prefs.remove(_keyHasRated);
      await prefs.remove(_keyArticlesRead);
      await prefs.remove(_keyListsCreated);
      await prefs.remove(_keyNeverAskAgain);
      log('🔄 Rating data reset');
    } catch (e) {
      log('⚠️ Error resetting rating data: $e');
    }
  }

  /// Get current rating statistics
  Future<Map<String, dynamic>> getRatingStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'launchCount': prefs.getInt(_keyLaunchCount) ?? 0,
        'articlesRead': prefs.getInt(_keyArticlesRead) ?? 0,
        'listsCreated': prefs.getInt(_keyListsCreated) ?? 0,
        'hasRated': prefs.getBool(_keyHasRated) ?? false,
        'neverAskAgain': prefs.getBool(_keyNeverAskAgain) ?? false,
        'lastPromptDate': prefs.getString(_keyLastRatingPrompt),
      };
    } catch (e) {
      log('⚠️ Error getting rating stats: $e');
      return {};
    }
  }

  /// Check if the in-app review is available on this device
  Future<bool> isReviewAvailable() async {
    try {
      return await _inAppReview.isAvailable();
    } catch (e) {
      log('⚠️ Error checking review availability: $e');
      return false;
    }
  }
}
