import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/service/user_preferences_sync_service.dart';

/// Service to manage app theme (light/dark mode) with cross-device sync
class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._init();

  static const String _themePreferenceKey = 'theme_mode';
  final UserPreferencesSyncService _syncService = UserPreferencesSyncService.instance;

  ThemeMode _themeMode = ThemeMode.dark; // Default to dark mode
  bool _isInitialized = false;
  String? _currentUserId; // ignore: unused_field - Used for state tracking

  ThemeService._init();

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isInitialized => _isInitialized;

  /// Initialize theme service and load saved preference
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePreferenceKey);

    if (savedTheme != null) {
      _themeMode = _parseThemeMode(savedTheme);
    } else {
      // No saved preference, use default dark mode and save it
      await prefs.setString(_themePreferenceKey, 'dark');
    }

    _isInitialized = true;
    debugPrint('🎨 Theme initialized: ${_themeMode == ThemeMode.dark ? "dark" : "light"} mode');
    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode, {String? userId}) async {
    _themeMode = mode;
    notifyListeners();

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, _themeModeName(mode));
    await prefs.setBool('isDarkMode', mode == ThemeMode.dark);
    await prefs.setString('themeMode', _themeModeName(mode));

    // Sync to backend if userId is provided
    if (userId != null) {
      _currentUserId = userId;
      _syncService.updatePreference(userId, 'themeMode', _themeModeName(mode));
      _syncService.updatePreference(userId, 'isDarkMode', mode == ThemeMode.dark);
    }
  }

  /// Set dark mode
  Future<void> setDarkMode({String? userId}) async {
    await setThemeMode(ThemeMode.dark, userId: userId);
  }

  /// Set light mode
  Future<void> setLightMode({String? userId}) async {
    await setThemeMode(ThemeMode.light, userId: userId);
  }

  /// Sync theme with backend (pull latest from server)
  Future<void> syncFromBackend(String userId) async {
    _currentUserId = userId;
    final success = await _syncService.forceSyncFromRemote(userId);

    if (success) {
      // Reload theme from local storage after sync
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePreferenceKey);
      if (savedTheme != null) {
        _themeMode = _parseThemeMode(savedTheme);
        notifyListeners();
      }
    }
  }

  /// Parse theme mode from string
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  /// Get theme mode name
  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Get theme mode display name
  String get themeModeName {
    return _themeModeName(_themeMode);
  }
}
