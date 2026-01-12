import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:the_news/service/user_preferences_sync_service.dart';
import 'package:the_news/service/reading_history_sync_service.dart';
import 'package:the_news/service/saved_articles_service.dart';
import 'package:the_news/service/theme_service.dart';
import 'package:the_news/service/localization_service.dart';

/// Unified sync manager to orchestrate all data synchronization across devices
/// Handles preferences, reading history, saved articles, theme, and language sync
class SyncManagerService extends ChangeNotifier {
  static final SyncManagerService instance = SyncManagerService._init();

  final UserPreferencesSyncService _preferencesSync = UserPreferencesSyncService.instance;
  final ReadingHistorySyncService _historySync = ReadingHistorySyncService.instance;
  final SavedArticlesService _savedArticlesService = SavedArticlesService.instance;
  final ThemeService _themeService = ThemeService.instance;
  final LocalizationService _localizationService = LocalizationService.instance;

  bool _isSyncing = false;
  DateTime? _lastFullSyncTime;
  final Map<String, DateTime> _lastSyncTimes = {};
  final Map<String, String?> _syncErrors = {};

  SyncManagerService._init();

  // Getters
  bool get isSyncing => _isSyncing;
  DateTime? get lastFullSyncTime => _lastFullSyncTime;
  Map<String, DateTime> get lastSyncTimes => _lastSyncTimes;
  Map<String, String?> get syncErrors => _syncErrors;

  /// Initialize all sync services
  /// Note: After refactoring to ApiClient, sync services no longer need
  /// explicit initialization - they auto-initialize on first use
  Future<void> initialize() async {
    log('✅ SyncManager initialized (sync services use lazy initialization)');
  }

  /// Perform full sync of all data
  /// This should be called when:
  /// - User logs in
  /// - App comes to foreground after being in background
  /// - User manually triggers sync
  Future<bool> performFullSync(String userId) async {
    if (_isSyncing) {
      log('⚠️ Sync already in progress');
      return false;
    }

    _isSyncing = true;
    _syncErrors.clear();
    notifyListeners();

    log('🔄 Starting full sync for user: $userId');

    try {
      // Track individual sync results
      final results = <String, bool>{};

      // 1. Sync user preferences (theme, language, notifications, etc.)
      log('📋 Syncing user preferences...');
      results['preferences'] = await _syncPreferences(userId);

      // 2. Sync reading history
      log('📚 Syncing reading history...');
      results['history'] = await _syncReadingHistory(userId);

      // 3. Sync saved articles
      log('🔖 Syncing saved articles...');
      results['savedArticles'] = await _syncSavedArticles(userId);

      // 4. Apply synced theme
      log('🎨 Applying synced theme...');
      results['theme'] = await _syncTheme(userId);

      // 5. Apply synced language
      log('🌍 Applying synced language...');
      results['language'] = await _syncLanguage(userId);

      // Check if all syncs succeeded
      final allSucceeded = results.values.every((success) => success);

      if (allSucceeded) {
        _lastFullSyncTime = DateTime.now();
        log('✅ Full sync completed successfully');
      } else {
        final failed = results.entries.where((e) => !e.value).map((e) => e.key).toList();
        log('⚠️ Some syncs failed: ${failed.join(", ")}');
      }

      notifyListeners();
      return allSucceeded;
    } catch (e) {
      log('❌ Full sync failed: $e');
      _syncErrors['full_sync'] = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync user preferences
  Future<bool> _syncPreferences(String userId) async {
    try {
      final success = await _preferencesSync.syncPreferences(userId);
      if (success) {
        _lastSyncTimes['preferences'] = DateTime.now();
        _syncErrors.remove('preferences');
      } else {
        _syncErrors['preferences'] = 'Failed to sync preferences';
      }
      return success;
    } catch (e) {
      _syncErrors['preferences'] = e.toString();
      log('❌ Preferences sync error: $e');
      return false;
    }
  }

  /// Sync reading history
  Future<bool> _syncReadingHistory(String userId) async {
    try {
      final success = await _historySync.syncHistory(userId);
      if (success) {
        _lastSyncTimes['history'] = DateTime.now();
        _syncErrors.remove('history');
      } else {
        _syncErrors['history'] = 'Failed to sync reading history';
      }
      return success;
    } catch (e) {
      _syncErrors['history'] = e.toString();
      log('❌ Reading history sync error: $e');
      return false;
    }
  }

  /// Sync saved articles
  Future<bool> _syncSavedArticles(String userId) async {
    try {
      await _savedArticlesService.loadSavedArticles(userId);
      _lastSyncTimes['savedArticles'] = DateTime.now();
      _syncErrors.remove('savedArticles');
      return true;
    } catch (e) {
      _syncErrors['savedArticles'] = e.toString();
      log('❌ Saved articles sync error: $e');
      return false;
    }
  }

  /// Sync theme from backend
  Future<bool> _syncTheme(String userId) async {
    try {
      await _themeService.syncFromBackend(userId);
      _lastSyncTimes['theme'] = DateTime.now();
      _syncErrors.remove('theme');
      return true;
    } catch (e) {
      _syncErrors['theme'] = e.toString();
      log('❌ Theme sync error: $e');
      return false;
    }
  }

  /// Sync language from backend
  Future<bool> _syncLanguage(String userId) async {
    try {
      await _localizationService.syncFromBackend(userId);
      _lastSyncTimes['language'] = DateTime.now();
      _syncErrors.remove('language');
      return true;
    } catch (e) {
      _syncErrors['language'] = e.toString();
      log('❌ Language sync error: $e');
      return false;
    }
  }

  /// Sync only preferences (quick sync)
  Future<bool> syncPreferencesOnly(String userId) async {
    if (_isSyncing) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _syncPreferences(userId),
        _syncTheme(userId),
        _syncLanguage(userId),
      ]);

      notifyListeners();
      return results.every((success) => success);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync only reading data (history + saved articles)
  Future<bool> syncReadingDataOnly(String userId) async {
    if (_isSyncing) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _syncReadingHistory(userId),
        _syncSavedArticles(userId),
      ]);

      notifyListeners();
      return results.every((success) => success);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Get sync status for display
  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': _isSyncing,
      'lastFullSync': _lastFullSyncTime?.toIso8601String(),
      'lastSyncTimes': _lastSyncTimes.map((key, value) => MapEntry(key, value.toIso8601String())),
      'errors': _syncErrors,
      'hasErrors': _syncErrors.isNotEmpty,
    };
  }

  /// Check if sync is needed (based on time elapsed)
  bool shouldSync() {
    if (_lastFullSyncTime == null) return true;

    final hoursSinceLastSync = DateTime.now().difference(_lastFullSyncTime!).inHours;
    return hoursSinceLastSync >= 1; // Sync every hour
  }

  /// Handle conflict resolution for offline changes
  /// This is called when both local and remote data changed while offline
  Future<void> resolveConflicts(String userId, ConflictResolutionStrategy strategy) async {
    log('🔄 Resolving conflicts with strategy: $strategy');

    switch (strategy) {
      case ConflictResolutionStrategy.useLocal:
        // Force push local to remote
        await _forceUploadLocal(userId);
        break;

      case ConflictResolutionStrategy.useRemote:
        // Force pull remote to local
        await _forceDownloadRemote(userId);
        break;

      case ConflictResolutionStrategy.merge:
        // Use merge strategy (already implemented in individual services)
        await performFullSync(userId);
        break;

      case ConflictResolutionStrategy.keepBoth:
        // For reading history, we can keep both
        // For preferences, merge with timestamp priority
        await performFullSync(userId);
        break;
    }
  }

  /// Force upload local data to remote (overwrite remote)
  Future<void> _forceUploadLocal(String userId) async {
    log('⬆️ Force uploading local data to remote');

    // This would require backend endpoints that accept a force flag
    // For now, just do normal sync which uses merge strategy
    await performFullSync(userId);
  }

  /// Force download remote data to local (overwrite local)
  Future<void> _forceDownloadRemote(String userId) async {
    log('⬇️ Force downloading remote data to local');

    await _preferencesSync.forceSyncFromRemote(userId);
    await _themeService.syncFromBackend(userId);
    await _localizationService.syncFromBackend(userId);
    await _syncReadingHistory(userId);
    await _syncSavedArticles(userId);
  }

  /// Clear all sync data
  void clearSyncData() {
    _lastFullSyncTime = null;
    _lastSyncTimes.clear();
    _syncErrors.clear();
    _preferencesSync.clearCache();
    notifyListeners();
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'totalSyncs': _lastSyncTimes.length,
      'failedSyncs': _syncErrors.length,
      'successRate': _lastSyncTimes.isEmpty
          ? 0.0
          : ((_lastSyncTimes.length - _syncErrors.length) / _lastSyncTimes.length * 100),
      'lastFullSync': _lastFullSyncTime,
      'preferencesSyncTime': _preferencesSync.lastSyncTime,
      'historySyncTime': _historySync.lastSyncTime,
    };
  }
}

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  /// Use local data, discard remote changes
  useLocal,

  /// Use remote data, discard local changes
  useRemote,

  /// Merge local and remote intelligently (default)
  merge,

  /// Keep both versions (for reading history)
  keepBoth,
}
