import 'package:flutter/material.dart';

//? App Colors - Redesigned for Better Visibility & Contrast
class KAppColors {
  // ============================================================================
  // DARK MODE COLORS - High contrast, vibrant accents
  // ============================================================================
  static const Color darkPrimary = Color.fromARGB(196, 77, 127, 255); // Warm amber/orange
  static const Color darkSecondary = Color(0xFFFF6B9D); // Vibrant pink
  static const Color darkTertiary = Color(0xFF4DD4FF); // Bright cyan
  static const Color darkBackground = Color(0xFF0A0A0A); // True deep black
  static const Color darkSurface = Color(
    0xFF1A1A1A,
  ); // Slightly lighter surface
  static const Color darkOnBackground = Color(
    0xFFF5F5F5,
  ); // Off-white for less strain
  static const Color darkOnSurface = Color(0xFFE8E8E8); // Slightly dimmed white

  // ============================================================================
  // LIGHT MODE COLORS - WCAG AA+ compliant, excellent visibility
  // ============================================================================
  static const Color lightPrimary = Color(
    0xFFD97706,
  ); // Deep amber (high contrast)
  static const Color lightSecondary = Color(
    0xFFDC2626,
  ); // Deep red (high contrast)
  static const Color lightTertiary = Color(
    0xFF0891B2,
  ); // Deep cyan (high contrast)
  static const Color lightBackground = Color(0xFFFFFFFF); // Pure white
  static const Color lightSurface = Color(0xFFF8F9FA); // Very light gray
  static const Color lightOnBackground = Color(
    0xFF0F172A,
  ); // Near black (slate)
  static const Color lightOnSurface = Color(0xFF1E293B); // Dark slate

  // ============================================================================
  // LEGACY SUPPORT - Default to dark theme
  // ============================================================================
  static const Color primary = darkPrimary;
  static const Color secondary = darkSecondary;
  static const Color tertiary = darkTertiary;
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color onPrimary = Color(0xFF000000);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onTertiary = Color(0xFF000000);
  static const Color onBackground = darkOnBackground;
  static const Color onSurface = darkOnSurface;

  // ============================================================================
  // THEME-AWARE GETTERS - Auto-detect light/dark mode
  // ============================================================================
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPrimary
        : lightPrimary;
  }

  static Color getSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSecondary
        : lightSecondary;
  }

  static Color getTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTertiary
        : lightTertiary;
  }

  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  static Color getOnBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkOnBackground
        : lightOnBackground;
  }

  static Color getOnSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkOnSurface
        : lightOnSurface;
  }

  static Color getOnPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
  }

  static Color getOnSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
  }

  // ============================================================================
  // SEMANTIC COLORS - Consistent across themes
  // ============================================================================
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color onImage = Color(0xFFFFFFFF); // Text/icons on image scrims
  static const Color imageScrim = Color(0xFF000000); // Overlay scrim on images

  // Category/Feature colors
  static const Color blue = Color(0xFF3B82F6);
  static const Color green = Color(0xFF10B981);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color orange = Color(0xFFF97316);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color red = Color(0xFFEF4444);
  static const Color pink = Color(0xFFEC4899);
  static const Color yellow = Color(0xFFF59E0B);
}

//? Text Styles - Space Grotesk for headings, Outfit for body
class KAppTextStyles {
  // Space Grotesk for headings
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 57,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 45,
    fontWeight: FontWeight.w900,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 36,
    fontWeight: FontWeight.w900,
    height: 1.22,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.33,
  );

  // Space Grotesk for body text and UI
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );
}
