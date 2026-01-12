import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/model/reading_preferences_model.dart';

/// Service for managing reading preferences
/// Handles font size, font family, line spacing, and reading theme customization
class ReadingPreferencesService extends ChangeNotifier {
  static final ReadingPreferencesService instance = ReadingPreferencesService._init();
  ReadingPreferencesService._init();

  static const String _prefsKey = 'reading_preferences';

  ReadingPreferences _preferences = const ReadingPreferences();

  // Getters
  ReadingPreferences get preferences => _preferences;
  FontSize get fontSize => _preferences.fontSize;
  FontFamily get fontFamily => _preferences.fontFamily;
  LineSpacing get lineSpacing => _preferences.lineSpacing;
  ReadingTheme get readingTheme => _preferences.readingTheme;

  /// Initialize service and load saved preferences
  Future<void> initialize() async {
    try {
      log('📖 Initializing reading preferences service...');
      await _loadPreferences();
      log('✅ Reading preferences loaded: Font: ${_preferences.fontSize.label}, Theme: ${_preferences.readingTheme.label}');
    } catch (e) {
      log('⚠️ Error initializing reading preferences: $e');
    }
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_prefsKey);

      if (prefsJson != null) {
        final Map<String, dynamic> json = jsonDecode(prefsJson);
        _preferences = ReadingPreferences.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      log('⚠️ Error loading reading preferences: $e');
    }
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = jsonEncode(_preferences.toJson());
      await prefs.setString(_prefsKey, prefsJson);
      log('💾 Reading preferences saved');
    } catch (e) {
      log('⚠️ Error saving reading preferences: $e');
    }
  }

  /// Set font size
  Future<void> setFontSize(FontSize fontSize) async {
    _preferences = _preferences.copyWith(fontSize: fontSize);
    notifyListeners();
    await _savePreferences();
    log('📝 Font size updated to: ${fontSize.label}');
  }

  /// Set font family
  Future<void> setFontFamily(FontFamily fontFamily) async {
    _preferences = _preferences.copyWith(fontFamily: fontFamily);
    notifyListeners();
    await _savePreferences();
    log('📝 Font family updated to: ${fontFamily.label}');
  }

  /// Set line spacing
  Future<void> setLineSpacing(LineSpacing lineSpacing) async {
    _preferences = _preferences.copyWith(lineSpacing: lineSpacing);
    notifyListeners();
    await _savePreferences();
    log('📝 Line spacing updated to: ${lineSpacing.label}');
  }

  /// Set reading theme
  Future<void> setReadingTheme(ReadingTheme readingTheme) async {
    _preferences = _preferences.copyWith(readingTheme: readingTheme);
    notifyListeners();
    await _savePreferences();
    log('📝 Reading theme updated to: ${readingTheme.label}');
  }

  /// Reset to default preferences
  Future<void> resetToDefaults() async {
    _preferences = const ReadingPreferences();
    notifyListeners();
    await _savePreferences();
    log('🔄 Reading preferences reset to defaults');
  }

  /// Get text scale factor based on font size
  double getTextScaleFactor() {
    switch (_preferences.fontSize) {
      case FontSize.small:
        return 0.875; // 14/16
      case FontSize.medium:
        return 1.0;
      case FontSize.large:
        return 1.125; // 18/16
      case FontSize.extraLarge:
        return 1.25; // 20/16
      case FontSize.huge:
        return 1.5; // 24/16
    }
  }

  /// Get line height based on line spacing
  double getLineHeight() {
    return _preferences.lineSpacing.height;
  }

  /// Get font family string for TextStyle
  String? getFontFamily() {
    return _preferences.fontFamily.value;
  }
}
