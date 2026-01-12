import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

/// App theme configuration with light and dark modes
/// Light mode colors have been adjusted for WCAG accessibility (visibility on white).
class AppTheme {
  // Dark Theme Colors (High Contrast - Kept Original)
  static const Color darkBackground = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkPrimary = Color(0xFFFFE8E5);
  static const Color darkSecondary = Color(0xFFFFF2C5);
  static const Color darkTertiary = Color(0xFFE0F1FF);
  static const Color darkOnBackground = Colors.white;
  static const Color darkOnSurface = Colors.white;

  // Light Theme Colors (Adjusted for Visibility)
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFFE55B5B);   // Deeper Coral
  static const Color lightSecondary = Color(0xFFC79100); // Golden Amber
  static const Color lightTertiary = Color(0xFF2E8B57);  // Sea Green
  static const Color lightOnBackground = Color(0xFF111111);
  static const Color lightOnSurface = Color(0xFF111111);

  /// Dark Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        tertiary: darkTertiary,
        surface: darkBackground,
        onPrimary: Color(0xFF111111),
        onSecondary: Color(0xFF111111),
        onSurface: darkOnSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      dividerColor: Colors.white.withValues(alpha: 0.1),

      textTheme: _buildTextTheme(darkOnBackground),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkOnBackground,
        elevation: 0,
      ),

      iconTheme: const IconThemeData(
        color: darkOnBackground,
      ),
    );
  }

  /// Light Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        tertiary: lightTertiary,
        surface: lightBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white, // White text on Golden Amber
        onSurface: lightOnSurface,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      dividerColor: Colors.black.withValues(alpha: 0.1),

      textTheme: _buildTextTheme(lightOnBackground),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightOnBackground,
        elevation: 0,
      ),

      iconTheme: const IconThemeData(
        color: lightOnBackground,
      ),
    );
  }

  /// Helper to avoid code repetition in TextTheme
  static TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      displayLarge: KAppTextStyles.displayLarge.copyWith(color: color),
      displayMedium: KAppTextStyles.displayMedium.copyWith(color: color),
      displaySmall: KAppTextStyles.displaySmall.copyWith(color: color),
      headlineLarge: KAppTextStyles.headlineLarge.copyWith(color: color),
      headlineMedium: KAppTextStyles.headlineMedium.copyWith(color: color),
      headlineSmall: KAppTextStyles.headlineSmall.copyWith(color: color),
      titleLarge: KAppTextStyles.titleLarge.copyWith(color: color),
      titleMedium: KAppTextStyles.titleMedium.copyWith(color: color),
      titleSmall: KAppTextStyles.titleSmall.copyWith(color: color),
      bodyLarge: KAppTextStyles.bodyLarge.copyWith(color: color),
      bodyMedium: KAppTextStyles.bodyMedium.copyWith(color: color),
      bodySmall: KAppTextStyles.bodySmall.copyWith(color: color),
      labelLarge: KAppTextStyles.labelLarge.copyWith(color: color),
      labelMedium: KAppTextStyles.labelMedium.copyWith(color: color),
      labelSmall: KAppTextStyles.labelSmall.copyWith(color: color),
    );
  }

  // Helper methods...
  static Color getBackgroundColor(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color getTextColor(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color getSurfaceColor(BuildContext context) => Theme.of(context).colorScheme.surface;
  static bool isDarkMode(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
}