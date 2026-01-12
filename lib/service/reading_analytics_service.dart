import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking reading analytics and patterns
class ReadingAnalyticsService extends ChangeNotifier {
  static final ReadingAnalyticsService instance = ReadingAnalyticsService._init();
  ReadingAnalyticsService._init();

  static const String _analyticsKey = 'reading_analytics';

  Map<String, int> _categoryReadCount = {};
  Map<String, int> _sourceReadCount = {};
  Map<String, int> _dailyReadCount = {};
  int _totalArticlesRead = 0;
  int _totalReadingMinutes = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastReadDate;

  // Getters
  Map<String, int> get categoryReadCount => _categoryReadCount;
  Map<String, int> get sourceReadCount => _sourceReadCount;
  Map<String, int> get dailyReadCount => _dailyReadCount;
  int get totalArticlesRead => _totalArticlesRead;
  int get totalReadingMinutes => _totalReadingMinutes;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  DateTime? get lastReadDate => _lastReadDate;

  /// Initialize analytics
  Future<void> initialize() async {
    try {
      log('📊 Initializing reading analytics...');
      await _loadAnalytics();
      _updateStreak();
      log('✅ Reading analytics initialized');
    } catch (e) {
      log('⚠️ Error initializing analytics: $e');
    }
  }

  /// Load analytics from storage
  Future<void> _loadAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_analyticsKey);

      if (data != null) {
        final json = jsonDecode(data) as Map<String, dynamic>;

        _categoryReadCount = (json['categoryReadCount'] as Map?)?.map(
          (k, v) => MapEntry(k as String, v as int),
        ) ?? {};

        _sourceReadCount = (json['sourceReadCount'] as Map?)?.map(
          (k, v) => MapEntry(k as String, v as int),
        ) ?? {};

        _dailyReadCount = (json['dailyReadCount'] as Map?)?.map(
          (k, v) => MapEntry(k as String, v as int),
        ) ?? {};

        _totalArticlesRead = json['totalArticlesRead'] as int? ?? 0;
        _totalReadingMinutes = json['totalReadingMinutes'] as int? ?? 0;
        _currentStreak = json['currentStreak'] as int? ?? 0;
        _longestStreak = json['longestStreak'] as int? ?? 0;

        if (json['lastReadDate'] != null) {
          _lastReadDate = DateTime.parse(json['lastReadDate'] as String);
        }
      }
    } catch (e) {
      log('⚠️ Error loading analytics: $e');
    }
  }

  /// Save analytics to storage
  Future<void> _saveAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'categoryReadCount': _categoryReadCount,
        'sourceReadCount': _sourceReadCount,
        'dailyReadCount': _dailyReadCount,
        'totalArticlesRead': _totalArticlesRead,
        'totalReadingMinutes': _totalReadingMinutes,
        'currentStreak': _currentStreak,
        'longestStreak': _longestStreak,
        'lastReadDate': _lastReadDate?.toIso8601String(),
      };

      await prefs.setString(_analyticsKey, jsonEncode(data));
      log('💾 Analytics saved');
    } catch (e) {
      log('⚠️ Error saving analytics: $e');
    }
  }

  /// Track article read
  Future<void> trackArticleRead({
    required String articleId,
    required List<String> categories,
    required String source,
    required int readingMinutes,
  }) async {
    try {
      // Update total articles read
      _totalArticlesRead++;

      // Update total reading time
      _totalReadingMinutes += readingMinutes;

      // Update category counts
      for (final category in categories) {
        _categoryReadCount[category] = (_categoryReadCount[category] ?? 0) + 1;
      }

      // Update source counts
      _sourceReadCount[source] = (_sourceReadCount[source] ?? 0) + 1;

      // Update daily count
      final today = _getTodayKey();
      _dailyReadCount[today] = (_dailyReadCount[today] ?? 0) + 1;

      // Update streak
      _lastReadDate = DateTime.now();
      _updateStreak();

      notifyListeners();
      await _saveAnalytics();

      log('📊 Article read tracked: $_totalArticlesRead total');
    } catch (e) {
      log('⚠️ Error tracking article read: $e');
    }
  }

  /// Update reading streak
  void _updateStreak() {
    if (_lastReadDate == null) {
      _currentStreak = 0;
      return;
    }

    final now = DateTime.now();
    final lastRead = _lastReadDate!;

    // Check if last read was today or yesterday
    final daysSinceLastRead = now.difference(lastRead).inDays;

    if (daysSinceLastRead == 0) {
      // Read today, streak continues
      // Don't increment, already counted
    } else if (daysSinceLastRead == 1) {
      // Read yesterday, increment streak
      _currentStreak++;

      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }
    } else {
      // Streak broken
      _currentStreak = 1;
    }
  }

  /// Get today's key for daily counts
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get top categories
  List<MapEntry<String, int>> getTopCategories({int limit = 5}) {
    final entries = _categoryReadCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Get top sources
  List<MapEntry<String, int>> getTopSources({int limit = 5}) {
    final entries = _sourceReadCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Get reading stats for last N days
  Map<String, int> getLastNDaysStats(int days) {
    final stats = <String, int>{};
    final now = DateTime.now();

    for (var i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      stats[key] = _dailyReadCount[key] ?? 0;
    }

    return stats;
  }

  /// Get average articles per day
  double getAverageArticlesPerDay() {
    if (_dailyReadCount.isEmpty) return 0.0;

    final total = _dailyReadCount.values.reduce((a, b) => a + b);
    return total / _dailyReadCount.length;
  }

  /// Reset analytics
  Future<void> resetAnalytics() async {
    _categoryReadCount = {};
    _sourceReadCount = {};
    _dailyReadCount = {};
    _totalArticlesRead = 0;
    _totalReadingMinutes = 0;
    _currentStreak = 0;
    _longestStreak = 0;
    _lastReadDate = null;

    notifyListeners();
    await _saveAnalytics();
    log('🔄 Analytics reset');
  }
}
