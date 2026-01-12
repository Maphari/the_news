import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/service/user_preferences_sync_service.dart';

/// Service for managing app localization with cross-device sync
class LocalizationService extends ChangeNotifier {
  static final LocalizationService instance = LocalizationService._init();
  LocalizationService._init();

  static const String _localeKey = 'app_language';
  final UserPreferencesSyncService _syncService = UserPreferencesSyncService.instance;

  Locale _currentLocale = const Locale('en');
  String? _currentUserId; // ignore: unused_field - Used for state tracking

  Locale get currentLocale => _currentLocale;

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('de'), // German
    Locale('zh'), // Chinese
    Locale('ar'), // Arabic
    Locale('hi'), // Hindi
    Locale('pt'), // Portuguese
    Locale('ru'), // Russian
    Locale('ja'), // Japanese
  ];

  /// Initialize service
  Future<void> initialize() async {
    try {
      log('🌍 Initializing localization service...');
      await _loadLocale();
      log('✅ Localization service initialized: $_currentLocale');
    } catch (e) {
      log('⚠️ Error initializing localization service: $e');
    }
  }

  /// Load saved locale
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localeKey);

      if (languageCode != null) {
        _currentLocale = Locale(languageCode);
      }
    } catch (e) {
      log('⚠️ Error loading locale: $e');
    }
  }

  /// Change app locale
  Future<void> changeLocale(Locale locale, {String? userId}) async {
    try {
      if (!supportedLocales.contains(locale)) {
        log('⚠️ Locale not supported: $locale');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
      await prefs.setString('languageCode', locale.languageCode);

      _currentLocale = locale;
      notifyListeners();

      log('🌍 Locale changed to: $locale');

      // Sync to backend if userId is provided
      if (userId != null) {
        _currentUserId = userId;
        _syncService.updatePreference(userId, 'languageCode', locale.languageCode);
      }
    } catch (e) {
      log('⚠️ Error changing locale: $e');
    }
  }

  /// Sync language with backend (pull latest from server)
  Future<void> syncFromBackend(String userId) async {
    _currentUserId = userId;
    final success = await _syncService.forceSyncFromRemote(userId);

    if (success) {
      // Reload language from local storage after sync
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localeKey);
      if (languageCode != null) {
        _currentLocale = Locale(languageCode);
        notifyListeners();
      }
    }
  }

  /// Get language name
  static String getLanguageName(String languageCode) {
    final names = {
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'zh': '中文',
      'ar': 'العربية',
      'hi': 'हिन्दी',
      'pt': 'Português',
      'ru': 'Русский',
      'ja': '日本語',
    };

    return names[languageCode] ?? languageCode;
  }

  /// Check if locale is RTL (right-to-left)
  static bool isRTL(Locale locale) {
    return ['ar', 'he', 'fa', 'ur'].contains(locale.languageCode);
  }

  /// Get text direction for locale
  static TextDirection getTextDirection(Locale locale) {
    return isRTL(locale) ? TextDirection.rtl : TextDirection.ltr;
  }
}
