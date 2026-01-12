import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage dialog show frequency
class DialogFrequencyService {
  static final DialogFrequencyService instance = DialogFrequencyService._init();

  DialogFrequencyService._init();

  static const String _articleLimitDialogKey = 'article_limit_dialog_last_shown';
  static const String _articleLimitDialogCountKey = 'article_limit_dialog_count';
  static const String _moodCheckInDialogKey = 'mood_checkin_dialog_last_shown';
  static const String _moodCheckInDialogCountKey = 'mood_checkin_dialog_count';
  static const int _maxShowsPerDay = 2;

  /// Check if the article limit dialog should be shown
  /// Returns true if the dialog can be shown (hasn't reached 2 times today)
  Future<bool> shouldShowArticleLimitDialog() async {
    final prefs = await SharedPreferences.getInstance();

    // Get last shown date
    final lastShownString = prefs.getString(_articleLimitDialogKey);
    final showCount = prefs.getInt(_articleLimitDialogCountKey) ?? 0;

    // Get today's date as string (YYYY-MM-DD)
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // If no last shown date or it's a different day, reset counter
    if (lastShownString == null || lastShownString != todayString) {
      await prefs.setString(_articleLimitDialogKey, todayString);
      await prefs.setInt(_articleLimitDialogCountKey, 0);
      return true;
    }

    // Same day - check if under limit
    return showCount < _maxShowsPerDay;
  }

  /// Track that the article limit dialog was shown
  Future<void> trackArticleLimitDialogShown() async {
    final prefs = await SharedPreferences.getInstance();

    // Get current count
    final showCount = prefs.getInt(_articleLimitDialogCountKey) ?? 0;

    // Increment counter
    await prefs.setInt(_articleLimitDialogCountKey, showCount + 1);

    // Update last shown date
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await prefs.setString(_articleLimitDialogKey, todayString);
  }

  /// Reset the dialog counter (for testing purposes)
  Future<void> resetArticleLimitDialogCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_articleLimitDialogKey);
    await prefs.remove(_articleLimitDialogCountKey);
  }

  /// Get remaining shows for today
  Future<int> getRemainingShowsToday() async {
    final prefs = await SharedPreferences.getInstance();

    final lastShownString = prefs.getString(_articleLimitDialogKey);
    final showCount = prefs.getInt(_articleLimitDialogCountKey) ?? 0;

    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // If different day, all shows available
    if (lastShownString == null || lastShownString != todayString) {
      return _maxShowsPerDay;
    }

    // Same day - return remaining
    final remaining = _maxShowsPerDay - showCount;
    return remaining > 0 ? remaining : 0;
  }

  // ===== MOOD CHECK-IN DIALOG METHODS =====

  /// Check if the mood check-in dialog should be shown
  /// Returns true if the dialog can be shown (hasn't reached 2 times today)
  Future<bool> shouldShowMoodCheckInDialog() async {
    final prefs = await SharedPreferences.getInstance();

    // Get last shown date
    final lastShownString = prefs.getString(_moodCheckInDialogKey);
    final showCount = prefs.getInt(_moodCheckInDialogCountKey) ?? 0;

    // Get today's date as string (YYYY-MM-DD)
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // If no last shown date or it's a different day, reset counter
    if (lastShownString == null || lastShownString != todayString) {
      await prefs.setString(_moodCheckInDialogKey, todayString);
      await prefs.setInt(_moodCheckInDialogCountKey, 0);
      return true;
    }

    // Same day - check if under limit
    return showCount < _maxShowsPerDay;
  }

  /// Track that the mood check-in dialog was shown
  Future<void> trackMoodCheckInDialogShown() async {
    final prefs = await SharedPreferences.getInstance();

    // Get current count
    final showCount = prefs.getInt(_moodCheckInDialogCountKey) ?? 0;

    // Increment counter
    await prefs.setInt(_moodCheckInDialogCountKey, showCount + 1);

    // Update last shown date
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await prefs.setString(_moodCheckInDialogKey, todayString);
  }

  /// Reset the mood check-in dialog counter (for testing purposes)
  Future<void> resetMoodCheckInDialogCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_moodCheckInDialogKey);
    await prefs.remove(_moodCheckInDialogCountKey);
  }
}
