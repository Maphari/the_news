import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/core/network/api_client.dart';

/// Service to sync user preferences across devices
/// Handles theme, language, notification settings, and other user preferences
/// Uses ApiClient for all network requests following clean architecture
class UserPreferencesSyncService extends ChangeNotifier {
  static final UserPreferencesSyncService instance = UserPreferencesSyncService._init();
  UserPreferencesSyncService._init();

  final _api = ApiClient.instance;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  Map<String, dynamic> _cachedPreferences = {};

  // Getters
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Sync all preferences with backend
  Future<bool> syncPreferences(String userId) async {
    _isSyncing = true;
    notifyListeners();

    try {
      // Step 1: Get local preferences
      final localPrefs = await _getLocalPreferences();

      // Step 2: Get remote preferences
      final remotePrefs = await _getRemotePreferences(userId);

      // Step 3: Merge preferences (remote wins for conflicts, unless local is newer)
      final mergedPrefs = _mergePreferences(localPrefs, remotePrefs);

      // Step 4: Upload merged preferences to backend
      final uploadSuccess = await _uploadPreferences(userId, mergedPrefs);

      // Step 5: Save merged preferences locally
      if (uploadSuccess) {
        await _saveLocalPreferences(mergedPrefs);
        _lastSyncTime = DateTime.now();
        _cachedPreferences = mergedPrefs;
        log('✅ Preferences synced successfully');
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      log('⚠️ Error syncing preferences: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Get local preferences from SharedPreferences
  Future<Map<String, dynamic>> _getLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      // Theme settings
      'isDarkMode': prefs.getBool('isDarkMode') ?? true,
      'themeMode': prefs.getString('themeMode') ?? 'dark',

      // Language settings
      'languageCode': prefs.getString('languageCode') ?? 'en',

      // Reading preferences
      'fontSize': prefs.getDouble('fontSize') ?? 16.0,
      'fontFamily': prefs.getString('fontFamily') ?? 'Default',
      'lineHeight': prefs.getDouble('lineHeight') ?? 1.5,

      // Notification settings
      'notificationsEnabled': prefs.getBool('notificationsEnabled') ?? true,
      'digestNotifications': prefs.getBool('digestNotifications') ?? true,
      'breakingNewsNotifications': prefs.getBool('breakingNewsNotifications') ?? false,

      // AI settings
      'aiProvider': prefs.getString('aiProvider') ?? 'none',
      'aiSummaryEnabled': prefs.getBool('aiSummaryEnabled') ?? true,

      // Offline settings
      'autoDownloadOnWiFi': prefs.getBool('autoDownloadOnWiFi') ?? false,
      'downloadImagesOffline': prefs.getBool('downloadImagesOffline') ?? true,

      // Location preferences
      'preferredCountries': prefs.getStringList('preferredCountries') ??
          prefs.getStringList('preferred_countries') ??
          <String>[],
      'currentCountry': prefs.getString('currentCountry') ??
          prefs.getString('current_country'),
      'currentCountryCode': prefs.getString('currentCountryCode') ??
          prefs.getString('current_country_code'),

      // Accessibility
      'highContrast': prefs.getBool('highContrast') ?? false,
      'screenReaderEnabled': prefs.getBool('screenReaderEnabled') ?? false,

      // Metadata
      'lastModified': prefs.getInt('preferencesLastModified') ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Get remote preferences from backend
  Future<Map<String, dynamic>> _getRemotePreferences(String userId) async {
    try {
      log('📥 Fetching remote preferences for user: $userId');

      final response = await _api.get('user/preferences/$userId');

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          log('✅ Loaded remote preferences');
          return data['preferences'] as Map<String, dynamic>;
        }
      } else if (response.statusCode == 404) {
        // No remote preferences yet, return empty
        log('ℹ️ No remote preferences found, using local');
        return {};
      }

      throw Exception(_api.getErrorMessage(response));
    } catch (e) {
      log('⚠️ Error loading remote preferences: $e');
      return {}; // Return empty on error, use local
    }
  }

  /// Merge local and remote preferences
  /// Strategy: Use the most recently modified value for each preference
  Map<String, dynamic> _mergePreferences(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    if (remote.isEmpty) return local;
    if (local.isEmpty) return remote;

    final localTimestamp = local['lastModified'] as int? ?? 0;
    final remoteTimestamp = remote['lastModified'] as int? ?? 0;

    // If remote is newer, use remote as base
    if (remoteTimestamp > localTimestamp) {
      log('🔄 Remote preferences are newer, using remote as base');
      return {
        ...remote,
        'lastModified': DateTime.now().millisecondsSinceEpoch,
      };
    }

    // Local is newer or equal, use local as base
    log('🔄 Local preferences are newer, using local as base');
    return {
      ...local,
      'lastModified': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Upload preferences to backend
  Future<bool> _uploadPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      log('📤 Uploading preferences');

      final response = await _api.put(
        'user/preferences',
        body: {
          'userId': userId,
          'preferences': preferences,
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          log('✅ Preferences uploaded successfully');
          return true;
        }
      }

      log('⚠️ Failed to upload preferences: ${_api.getErrorMessage(response)}');
      return false;
    } catch (e) {
      log('⚠️ Error uploading preferences: $e');
      return false;
    }
  }

  /// Save preferences to local storage
  Future<void> _saveLocalPreferences(Map<String, dynamic> preferences) async {
    final prefs = await SharedPreferences.getInstance();

    // Theme settings
    if (preferences['isDarkMode'] != null) {
      await prefs.setBool('isDarkMode', preferences['isDarkMode'] as bool);
    }
    if (preferences['themeMode'] != null) {
      await prefs.setString('themeMode', preferences['themeMode'] as String);
    }

    // Language settings
    if (preferences['languageCode'] != null) {
      await prefs.setString('languageCode', preferences['languageCode'] as String);
    }

    // Reading preferences
    if (preferences['fontSize'] != null) {
      await prefs.setDouble('fontSize', (preferences['fontSize'] as num).toDouble());
    }
    if (preferences['fontFamily'] != null) {
      await prefs.setString('fontFamily', preferences['fontFamily'] as String);
    }
    if (preferences['lineHeight'] != null) {
      await prefs.setDouble('lineHeight', (preferences['lineHeight'] as num).toDouble());
    }

    // Notification settings
    if (preferences['notificationsEnabled'] != null) {
      await prefs.setBool('notificationsEnabled', preferences['notificationsEnabled'] as bool);
    }
    if (preferences['digestNotifications'] != null) {
      await prefs.setBool('digestNotifications', preferences['digestNotifications'] as bool);
    }
    if (preferences['breakingNewsNotifications'] != null) {
      await prefs.setBool('breakingNewsNotifications', preferences['breakingNewsNotifications'] as bool);
    }

    // AI settings
    if (preferences['aiProvider'] != null) {
      await prefs.setString('aiProvider', preferences['aiProvider'] as String);
    }
    if (preferences['aiSummaryEnabled'] != null) {
      await prefs.setBool('aiSummaryEnabled', preferences['aiSummaryEnabled'] as bool);
    }

    // Offline settings
    if (preferences['autoDownloadOnWiFi'] != null) {
      await prefs.setBool('autoDownloadOnWiFi', preferences['autoDownloadOnWiFi'] as bool);
    }
    if (preferences['downloadImagesOffline'] != null) {
      await prefs.setBool('downloadImagesOffline', preferences['downloadImagesOffline'] as bool);
    }

    // Location preferences
    if (preferences['preferredCountries'] != null) {
      final list = List<String>.from(preferences['preferredCountries'] as List);
      await prefs.setStringList('preferredCountries', list);
    }
    if (preferences['currentCountry'] != null) {
      await prefs.setString('currentCountry', preferences['currentCountry'] as String);
      await prefs.setString('current_country', preferences['currentCountry'] as String);
    }
    if (preferences['currentCountryCode'] != null) {
      await prefs.setString('currentCountryCode', preferences['currentCountryCode'] as String);
      await prefs.setString('current_country_code', preferences['currentCountryCode'] as String);
    }

    // Accessibility
    if (preferences['highContrast'] != null) {
      await prefs.setBool('highContrast', preferences['highContrast'] as bool);
    }
    if (preferences['screenReaderEnabled'] != null) {
      await prefs.setBool('screenReaderEnabled', preferences['screenReaderEnabled'] as bool);
    }

    // Update timestamp
    await prefs.setInt('preferencesLastModified', preferences['lastModified'] as int);

    log('💾 Preferences saved to local storage');
  }

  /// Update a single preference (saves locally and syncs to backend)
  Future<bool> updatePreference(
    String userId,
    String key,
    dynamic value,
  ) async {
    try {
      // Save locally first
      final prefs = await SharedPreferences.getInstance();

      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }

      // Update timestamp
      await prefs.setInt('preferencesLastModified', DateTime.now().millisecondsSinceEpoch);

      // Sync to backend in background
      syncPreferences(userId).catchError((e) {
        log('⚠️ Background sync failed: $e');
        return false;
      });

      notifyListeners();
      return true;
    } catch (e) {
      log('⚠️ Error updating preference: $e');
      return false;
    }
  }

  /// Force sync from remote (overwrites local)
  Future<bool> forceSyncFromRemote(String userId) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final remotePrefs = await _getRemotePreferences(userId);
      if (remotePrefs.isNotEmpty) {
        await _saveLocalPreferences(remotePrefs);
        _lastSyncTime = DateTime.now();
        _cachedPreferences = remotePrefs;
        log('✅ Force synced from remote');
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      log('⚠️ Error force syncing from remote: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Clear all cached preferences
  void clearCache() {
    _cachedPreferences.clear();
    _lastSyncTime = null;
    notifyListeners();
  }
}
