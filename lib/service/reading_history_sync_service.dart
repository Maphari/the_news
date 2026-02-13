import 'dart:developer';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/core/network/api_client.dart';

/// Model for a reading history entry
class ReadingHistoryEntry {
  final String articleId;
  final String articleTitle;
  final DateTime readAt;
  final int readDuration; // seconds spent reading

  const ReadingHistoryEntry({
    required this.articleId,
    required this.articleTitle,
    required this.readAt,
    required this.readDuration,
  });

  Map<String, dynamic> toJson() => {
        'articleId': articleId,
        'articleTitle': articleTitle,
        'readAt': readAt.toIso8601String(),
        'readDuration': readDuration,
      };

  factory ReadingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ReadingHistoryEntry(
      articleId: json['articleId'] as String,
      articleTitle: json['articleTitle'] as String,
      readAt: DateTime.parse(json['readAt'] as String),
      readDuration: json['readDuration'] as int,
    );
  }
}

/// Service to sync reading history across devices
/// Uses ApiClient for all network requests following clean architecture
class ReadingHistorySyncService extends ChangeNotifier {
  static final ReadingHistorySyncService instance = ReadingHistorySyncService._init();
  ReadingHistorySyncService._init();

  final _api = ApiClient.instance;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  List<ReadingHistoryEntry> _cachedHistory = [];

  // Getters
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<ReadingHistoryEntry> get cachedHistory => _cachedHistory;

  /// Track an article read
  Future<bool> trackArticleRead({
    required String userId,
    required String articleId,
    required String articleTitle,
    required int readDuration,
  }) async {
    try {
      final entry = ReadingHistoryEntry(
        articleId: articleId,
        articleTitle: articleTitle,
        readAt: DateTime.now(),
        readDuration: readDuration,
      );

      // Save locally first
      await _saveToLocalHistory(entry);

      // Update in-memory cache for immediate UI updates
      _cachedHistory = [entry, ..._cachedHistory];
      if (_cachedHistory.length > 1000) {
        _cachedHistory = _cachedHistory.sublist(0, 1000);
      }

      // Sync to backend in background
      _uploadReadingHistory(userId, [entry]).catchError((e) {
        log('⚠️ Background upload failed: $e');
        return false;
      });

      notifyListeners();
      return true;
    } catch (e) {
      log('⚠️ Error tracking article read: $e');
      return false;
    }
  }

  /// Save reading entry to local storage
  Future<void> _saveToLocalHistory(ReadingHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('readingHistory') ?? '[]';
    final List<dynamic> history = json.decode(historyJson);

    // Add new entry
    history.add(entry.toJson());

    // Keep only last 1000 entries
    if (history.length > 1000) {
      history.removeRange(0, history.length - 1000);
    }

    await prefs.setString('readingHistory', json.encode(history));
    log('💾 Saved reading entry to local storage');
  }

  /// Get local reading history
  Future<List<ReadingHistoryEntry>> _getLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('readingHistory') ?? '[]';
    final List<dynamic> history = json.decode(historyJson);

    return history
        .map((json) => ReadingHistoryEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Upload reading history to backend
  Future<bool> _uploadReadingHistory(
    String userId,
    List<ReadingHistoryEntry> entries,
  ) async {
    try {
      log('📤 Uploading ${entries.length} reading entries');

      final response = await _api.post(
        'user/reading-history',
        body: {
          'userId': userId,
          'entries': entries.map((e) => e.toJson()).toList(),
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          log('✅ Reading history uploaded successfully');
          return true;
        }
      }

      log('⚠️ Failed to upload reading history: ${_api.getErrorMessage(response)}');
      return false;
    } catch (e) {
      log('⚠️ Error uploading reading history: $e');
      return false;
    }
  }

  /// Get reading history from backend
  Future<List<ReadingHistoryEntry>> _getRemoteHistory(String userId) async {
    try {
      log('📥 Fetching remote reading history');

      final response = await _api.get('user/reading-history/$userId');

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final List<dynamic> entries = data['entries'] ?? [];
          final history = entries
              .map((json) => ReadingHistoryEntry.fromJson(json as Map<String, dynamic>))
              .toList();
          log('✅ Loaded ${history.length} entries from remote');
          return history;
        }
      } else if (response.statusCode == 404) {
        log('ℹ️ No remote reading history found');
        return [];
      }

      throw Exception(_api.getErrorMessage(response));
    } catch (e) {
      log('⚠️ Error loading remote reading history: $e');
      return [];
    }
  }

  /// Sync reading history with backend
  Future<bool> syncHistory(String userId) async {
    _isSyncing = true;
    notifyListeners();

    try {
      // Get local and remote history
      final localHistory = await _getLocalHistory();
      final remoteHistory = await _getRemoteHistory(userId);

      // Merge histories
      final mergedHistory = _mergeHistories(localHistory, remoteHistory);

      // Upload merged history to backend
      final uploadSuccess = await _uploadReadingHistory(userId, mergedHistory);

      // Save merged history locally regardless of upload result
      await _saveFullHistory(mergedHistory);
      _cachedHistory = mergedHistory;
      _lastSyncTime = DateTime.now();

      if (uploadSuccess) {
        log('✅ Reading history synced successfully');
      } else {
        log('⚠️ Reading history saved locally; remote sync failed');
      }
      notifyListeners();
      return uploadSuccess;
    } catch (e) {
      log('⚠️ Error syncing reading history: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Merge local and remote histories
  /// Strategy: Combine both, remove duplicates, keep most recent 1000
  List<ReadingHistoryEntry> _mergeHistories(
    List<ReadingHistoryEntry> local,
    List<ReadingHistoryEntry> remote,
  ) {
    // Create a map to track unique articles (by articleId + readAt)
    final Map<String, ReadingHistoryEntry> uniqueEntries = {};

    // Add local entries
    for (final entry in local) {
      final key = '${entry.articleId}_${entry.readAt.millisecondsSinceEpoch}';
      uniqueEntries[key] = entry;
    }

    // Add remote entries (will overwrite if duplicate key exists)
    for (final entry in remote) {
      final key = '${entry.articleId}_${entry.readAt.millisecondsSinceEpoch}';
      uniqueEntries[key] = entry;
    }

    // Convert to list and sort by readAt (newest first)
    final merged = uniqueEntries.values.toList()
      ..sort((a, b) => b.readAt.compareTo(a.readAt));

    // Keep only last 1000 entries
    if (merged.length > 1000) {
      return merged.sublist(0, 1000);
    }

    log('🔄 Merged ${local.length} local + ${remote.length} remote = ${merged.length} total entries');
    return merged;
  }

  /// Save full history to local storage
  Future<void> _saveFullHistory(List<ReadingHistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = history.map((e) => e.toJson()).toList();
    await prefs.setString('readingHistory', json.encode(historyJson));
    log('💾 Saved full reading history to local storage');
  }

  /// Get reading analytics
  Future<Map<String, dynamic>> getAnalytics(String userId) async {
    // First sync to get latest data
    await syncHistory(userId);

    final history = _cachedHistory.isNotEmpty ? _cachedHistory : await _getLocalHistory();
    if (_cachedHistory.isEmpty && history.isNotEmpty) {
      _cachedHistory = history;
      notifyListeners();
    }

    // Calculate stats
    final totalArticlesRead = history.length;
    final totalReadingTime = history.fold<int>(0, (sum, entry) => sum + entry.readDuration);

    // Group by date
    final Map<String, int> articlesByDate = {};
    for (final entry in history) {
      final date = '${entry.readAt.year}-${entry.readAt.month.toString().padLeft(2, '0')}-${entry.readAt.day.toString().padLeft(2, '0')}';
      articlesByDate[date] = (articlesByDate[date] ?? 0) + 1;
    }

    // Most active day
    String? mostActiveDay;
    int maxArticles = 0;
    articlesByDate.forEach((date, count) {
      if (count > maxArticles) {
        maxArticles = count;
        mostActiveDay = date;
      }
    });

    return {
      'totalArticlesRead': totalArticlesRead,
      'totalReadingTimeMinutes': (totalReadingTime / 60).round(),
      'averageReadingTimeMinutes': totalArticlesRead > 0 ? (totalReadingTime / 60 / totalArticlesRead).round() : 0,
      'articlesByDate': articlesByDate,
      'mostActiveDay': mostActiveDay,
      'maxArticlesInDay': maxArticles,
      'last7DaysCount': _getLast7DaysCount(history),
      'last30DaysCount': _getLast30DaysCount(history),
    };
  }

  int _getLast7DaysCount(List<ReadingHistoryEntry> history) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return history.where((entry) => entry.readAt.isAfter(sevenDaysAgo)).length;
  }

  int _getLast30DaysCount(List<ReadingHistoryEntry> history) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return history.where((entry) => entry.readAt.isAfter(thirtyDaysAgo)).length;
  }

  /// Clear all reading history
  Future<bool> clearHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('readingHistory');

      // Also clear on backend
      final _ = await _api.delete('user/reading-history/$userId');

      _cachedHistory.clear();
      notifyListeners();
      log('🗑️ Reading history cleared');
      return true;
    } catch (e) {
      log('⚠️ Error clearing reading history: $e');
      return false;
    }
  }
}
