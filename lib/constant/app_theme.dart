import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

/// App theme configuration with light and dark modes
/// Light mode colors have been adjusted for WCAG accessibility (visibility on white).
//? App Theme - Complete implementation
class AppTheme {
  // ============================================================================
  // LIGHT THEME - Clean, professional, high contrast
  // ============================================================================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'SpaceGrotesk',

    colorScheme: ColorScheme.light(
      primary: KAppColors.lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: KAppColors.lightPrimary.withValues(alpha: 0.1),
      onPrimaryContainer: KAppColors.lightPrimary,

      secondary: KAppColors.lightSecondary,
      onSecondary: Colors.white,
      secondaryContainer: KAppColors.lightSecondary.withValues(alpha: 0.1),
      onSecondaryContainer: KAppColors.lightSecondary,

      tertiary: KAppColors.lightTertiary,
      onTertiary: Colors.white,
      tertiaryContainer: KAppColors.lightTertiary.withValues(alpha: 0.1),
      onTertiaryContainer: KAppColors.lightTertiary,

      surface: KAppColors.lightSurface,
      onSurface: KAppColors.lightOnSurface,
      surfaceContainerHighest: const Color(0xFFE2E8F0),

      error: KAppColors.error,
      onError: Colors.white,

      outline: KAppColors.lightOnBackground.withValues(alpha: 0.2),
      outlineVariant: KAppColors.lightOnBackground.withValues(alpha: 0.1),

      shadow: Colors.black.withValues(alpha: 0.1),
      scrim: Colors.black.withValues(alpha: 0.32),
    ),

    scaffoldBackgroundColor: KAppColors.lightBackground,

    textTheme: TextTheme(
      displayLarge: KAppTextStyles.displayLarge.copyWith(color: KAppColors.lightOnBackground),
      displayMedium: KAppTextStyles.displayMedium.copyWith(color: KAppColors.lightOnBackground),
      displaySmall: KAppTextStyles.displaySmall.copyWith(color: KAppColors.lightOnBackground),
      headlineLarge: KAppTextStyles.headlineLarge.copyWith(color: KAppColors.lightOnBackground),
      headlineMedium: KAppTextStyles.headlineMedium.copyWith(color: KAppColors.lightOnBackground),
      headlineSmall: KAppTextStyles.headlineSmall.copyWith(color: KAppColors.lightOnBackground),
      titleLarge: KAppTextStyles.titleLarge.copyWith(color: KAppColors.lightOnSurface),
      titleMedium: KAppTextStyles.titleMedium.copyWith(color: KAppColors.lightOnSurface),
      titleSmall: KAppTextStyles.titleSmall.copyWith(color: KAppColors.lightOnSurface),
      bodyLarge: KAppTextStyles.bodyLarge.copyWith(color: KAppColors.lightOnSurface),
      bodyMedium: KAppTextStyles.bodyMedium.copyWith(color: KAppColors.lightOnSurface),
      bodySmall: KAppTextStyles.bodySmall.copyWith(color: KAppColors.lightOnSurface.withValues(alpha: 0.8)),
      labelLarge: KAppTextStyles.labelLarge.copyWith(color: KAppColors.lightOnSurface),
      labelMedium: KAppTextStyles.labelMedium.copyWith(color: KAppColors.lightOnSurface),
      labelSmall: KAppTextStyles.labelSmall.copyWith(color: KAppColors.lightOnSurface.withValues(alpha: 0.7)),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: KAppColors.lightBackground,
      foregroundColor: KAppColors.lightOnBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: KAppTextStyles.headlineSmall.copyWith(
        color: KAppColors.lightOnBackground,
      ),
      iconTheme: IconThemeData(color: KAppColors.lightOnBackground),
    ),

    cardTheme: CardThemeData(
      color: KAppColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KAppColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KAppColors.lightPrimary,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: BorderSide(color: KAppColors.lightPrimary, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: KAppColors.lightPrimary,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KAppColors.lightPrimary,
        foregroundColor: Colors.white,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KAppColors.lightOnBackground.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KAppColors.lightOnBackground.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KAppColors.lightPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KAppColors.error, width: 2),
      ),
      labelStyle: KAppTextStyles.bodyMedium.copyWith(
        color: KAppColors.lightOnBackground.withValues(alpha: 0.7),
      ),
      hintStyle: KAppTextStyles.bodyMedium.copyWith(
        color: KAppColors.lightOnBackground.withValues(alpha: 0.5),
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: KAppColors.lightPrimary,
      unselectedItemColor: KAppColors.lightOnBackground.withValues(alpha: 0.5),
      selectedLabelStyle: KAppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: KAppTextStyles.labelSmall,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: KAppColors.lightOnBackground,
      unselectedLabelColor: KAppColors.lightOnBackground.withValues(alpha: 0.6),
      labelStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: KAppTextStyles.labelMedium,
      indicator: BoxDecoration(
        color: KAppColors.lightPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      // indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: KAppColors.lightPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dividerTheme: DividerThemeData(
      color: KAppColors.lightOnBackground.withValues(alpha: 0.1),
      thickness: 1,
      space: 1,
    ),

    iconTheme: IconThemeData(
      color: KAppColors.lightOnSurface,
      size: 24,
    ),
  );

  // ============================================================================
  // DARK THEME - Deep blacks, vibrant accents, excellent contrast
  // ============================================================================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'SpaceGrotesk',

    colorScheme: ColorScheme.dark(
      primary: KAppColors.darkPrimary,
      onPrimary: Colors.black,
      primaryContainer: KAppColors.darkPrimary.withValues(alpha: 0.15),
      onPrimaryContainer: KAppColors.darkPrimary,

      secondary: KAppColors.darkSecondary,
      onSecondary: Colors.black,
      secondaryContainer: KAppColors.darkSecondary.withValues(alpha: 0.15),
      onSecondaryContainer: KAppColors.darkSecondary,

      tertiary: KAppColors.darkTertiary,
      onTertiary: Colors.black,
      tertiaryContainer: KAppColors.darkTertiary.withValues(alpha: 0.15),
      onTertiaryContainer: KAppColors.darkTertiary,

      surface: KAppColors.darkSurface,
      onSurface: KAppColors.darkOnSurface,
      surfaceContainerHighest: const Color(0xFF2A2A2A),

      error: KAppColors.error,
      onError: Colors.white,

      outline: Colors.white.withValues(alpha: 0.15),
      outlineVariant: Colors.white.withValues(alpha: 0.08),

      shadow: Colors.black.withValues(alpha: 0.4),
      scrim: Colors.black.withValues(alpha: 0.6),
    ),

    scaffoldBackgroundColor: KAppColors.darkBackground,

    textTheme: TextTheme(
      displayLarge: KAppTextStyles.displayLarge.copyWith(color: KAppColors.darkOnBackground),
      displayMedium: KAppTextStyles.displayMedium.copyWith(color: KAppColors.darkOnBackground),
      displaySmall: KAppTextStyles.displaySmall.copyWith(color: KAppColors.darkOnBackground),
      headlineLarge: KAppTextStyles.headlineLarge.copyWith(color: KAppColors.darkOnBackground),
      headlineMedium: KAppTextStyles.headlineMedium.copyWith(color: KAppColors.darkOnBackground),
      headlineSmall: KAppTextStyles.headlineSmall.copyWith(color: KAppColors.darkOnBackground),
      titleLarge: KAppTextStyles.titleLarge.copyWith(color: KAppColors.darkOnSurface),
      titleMedium: KAppTextStyles.titleMedium.copyWith(color: KAppColors.darkOnSurface),
      titleSmall: KAppTextStyles.titleSmall.copyWith(color: KAppColors.darkOnSurface),
      bodyLarge: KAppTextStyles.bodyLarge.copyWith(color: KAppColors.darkOnSurface),
      bodyMedium: KAppTextStyles.bodyMedium.copyWith(color: KAppColors.darkOnSurface),
      bodySmall: KAppTextStyles.bodySmall.copyWith(color: KAppColors.darkOnSurface.withValues(alpha: 0.8)),
      labelLarge: KAppTextStyles.labelLarge.copyWith(color: KAppColors.darkOnSurface),
      labelMedium: KAppTextStyles.labelMedium.copyWith(color: KAppColors.darkOnSurface),
      labelSmall: KAppTextStyles.labelSmall.copyWith(color: KAppColors.darkOnSurface.withValues(alpha: 0.7)),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: KAppColors.darkBackground,
      foregroundColor: KAppColors.darkOnBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: KAppTextStyles.headlineSmall.copyWith(
        color: KAppColors.darkOnBackground,
      ),
      iconTheme: IconThemeData(color: KAppColors.darkOnBackground),
    ),

    cardTheme: CardThemeData(
      color: KAppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KAppColors.darkPrimary,
        foregroundColor: Colors.black,
        elevation: 0,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KAppColors.darkPrimary,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: BorderSide(color: KAppColors.darkPrimary, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: KAppColors.darkPrimary,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KAppColors.darkPrimary,
        foregroundColor: Colors.black,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KAppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KAppColors.darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KAppColors.error, width: 2),
      ),
      labelStyle: KAppTextStyles.bodyMedium.copyWith(
        color: KAppColors.darkOnBackground.withValues(alpha: 0.7),
      ),
      hintStyle: KAppTextStyles.bodyMedium.copyWith(
        color: KAppColors.darkOnBackground.withValues(alpha: 0.5),
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: KAppColors.darkSurface,
      selectedItemColor: KAppColors.darkPrimary,
      unselectedItemColor: KAppColors.darkOnBackground.withValues(alpha: 0.5),
      selectedLabelStyle: KAppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: KAppTextStyles.labelSmall,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: KAppColors.darkOnBackground,
      unselectedLabelColor: KAppColors.darkOnBackground.withValues(alpha: 0.6),
      labelStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: KAppTextStyles.labelMedium,
      indicator: BoxDecoration(
        color: KAppColors.darkPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      // indicatorPadding: const EdgeInsets.symmetric(horizontal: 8)
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: KAppColors.darkPrimary,
      foregroundColor: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.1),
      thickness: 1,
      space: 1,
    ),

    iconTheme: IconThemeData(
      color: KAppColors.darkOnSurface,
      size: 24,
    ),
  );
}
