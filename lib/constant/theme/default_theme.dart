import 'package:flutter/material.dart';

//? App Colors - Based on Design System
class KAppColors {
  // Dark mode colors (from design)
  static const Color darkPrimary      = Color(0xFFFFF2C5); // #FFF2C5 - Light yellow
  static const Color darkSecondary    = Color(0xFFFFE8E5); // #FFE8E5 - Soft pink
  static const Color darkTertiary     = Color(0xFFE0F1FF); // #E0F1FF - Light blue
  static const Color darkBackground   = Color(0xFF111111); // #111111 - Dark background
  static const Color darkSurface      = Color(0xFF1E1E1E); // Surface color for cards
  static const Color darkOnBackground = Color(0xFFFFFFFF); // #FFFFFF - White text

  // Light mode colors (inverted/complementary palette)
  static const Color lightPrimary      = Color(0xFFFFCA28); // Amber (inverted from yellow) 
  static const Color lightSecondary    = Color(0xFFFF8A80); // Coral red (inverted from pink)
  static const Color lightTertiary     = Color(0xFF4FC3F7); // Light blue (inverted from light blue)
  static const Color lightBackground   = Color(0xFFFAFAFA); // Almost white
  static const Color lightSurface      = Color(0xFFFFFFFF); // Pure white for cards
  static const Color lightOnBackground = Color(0xFF111111); // #111111 - Dark text

  // Legacy static colors for backwards compatibility
  static const Color primary      = darkPrimary;
  static const Color secondary    = darkSecondary;
  static const Color tertiary     = darkTertiary;

  // Static getters for legacy code (default to dark theme colors)
  static const Color background   = darkBackground;
  static const Color surface      = darkSurface;
  static const Color onPrimary    = darkBackground;
  static const Color onSecondary  = darkBackground;
  static const Color onTertiary   = darkBackground;
  static const Color onBackground = darkOnBackground;
  static const Color onSurface    = darkOnBackground;

  // Theme-aware getters (these detect dark/light mode automatically)
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkPrimary : lightPrimary;
  }

  static Color getSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSecondary : lightSecondary;
  }

  static Color getTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTertiary : lightTertiary;
  }

  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBackground : lightBackground;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;
  }

  static Color getOnBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkOnBackground : lightOnBackground;
  }

  static Color getOnPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBackground : lightOnBackground;
  }

  static Color getOnSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBackground : lightOnBackground;
  }

  static Color getOnSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkOnBackground : lightOnBackground;
  }

  // Semantic colors for features and categories
  static const Color blue = Color(0xFF2196F3);
  static const Color green = Color(0xFF4CAF50);
  static const Color purple = Color(0xFF9C27B0);
  static const Color orange = Color(0xFFFF9800);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color red = Color(0xFFFF5722);
  static const Color pink = Color(0xFFE91E63);
}

//? Text Styles using Nexa-Trail and Outfit fonts
class KAppTextStyles {
  //? Nexa-Trail styles (for headings/display text) - Bold and impactful
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'NexaTrail',
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'NexaTrail',
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'NexaTrail',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.22,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'NexaTrail',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'NexaTrail',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'NexaTrail',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
  );

  //? Outfit styles (for body text, labels, and UI elements) - Clean and readable
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );
}

//? App Theme - Complete from scratch
class AppTheme {
  //? LIGHT THEME - Fresh, bright, energetic
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    //? Color Scheme
    colorScheme: ColorScheme.light(
      primary: KAppColors.lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: KAppColors.lightPrimary.withValues(alpha: 0.15),
      onPrimaryContainer: KAppColors.lightPrimary,

      secondary: KAppColors.lightSecondary,
      onSecondary: KAppColors.lightOnBackground,
      secondaryContainer: KAppColors.lightSecondary.withValues(alpha: 0.15),
      onSecondaryContainer: KAppColors.lightOnBackground,

      tertiary: KAppColors.lightTertiary,
      onTertiary: Colors.white,
      tertiaryContainer: KAppColors.lightTertiary.withValues(alpha: 0.15),
      onTertiaryContainer: KAppColors.lightTertiary,

      surface: KAppColors.lightSurface,
      onSurface: KAppColors.lightOnBackground,
      surfaceContainerHighest: const Color(0xFFE0E0E0),

      error: const Color(0xFFD32F2F),
      onError: Colors.white,

      outline: KAppColors.lightOnBackground.withValues(alpha: 0.12),
      outlineVariant: KAppColors.lightOnBackground.withValues(alpha: 0.08),

      shadow: Colors.black.withValues(alpha: 0.12),
      scrim: Colors.black.withValues(alpha: 0.32),
    ),

    scaffoldBackgroundColor: KAppColors.lightBackground,

    //? Typography
    textTheme: TextTheme(
      displayLarge: KAppTextStyles.displayLarge.copyWith(color: KAppColors.lightOnBackground),
      displayMedium: KAppTextStyles.displayMedium.copyWith(color: KAppColors.lightOnBackground),
      displaySmall: KAppTextStyles.displaySmall.copyWith(color: KAppColors.lightOnBackground),
      headlineLarge: KAppTextStyles.headlineLarge.copyWith(color: KAppColors.lightOnBackground),
      headlineMedium: KAppTextStyles.headlineMedium.copyWith(color: KAppColors.lightOnBackground),
      headlineSmall: KAppTextStyles.headlineSmall.copyWith(color: KAppColors.lightOnBackground),
      titleLarge: KAppTextStyles.titleLarge.copyWith(color: KAppColors.lightOnBackground),
      titleMedium: KAppTextStyles.titleMedium.copyWith(color: KAppColors.lightOnBackground),
      titleSmall: KAppTextStyles.titleSmall.copyWith(color: KAppColors.lightOnBackground),
      bodyLarge: KAppTextStyles.bodyLarge.copyWith(color: KAppColors.lightOnBackground),
      bodyMedium: KAppTextStyles.bodyMedium.copyWith(color: KAppColors.lightOnBackground),
      bodySmall: KAppTextStyles.bodySmall.copyWith(color: KAppColors.lightOnBackground),
      labelLarge: KAppTextStyles.labelLarge.copyWith(color: KAppColors.lightOnBackground),
      labelMedium: KAppTextStyles.labelMedium.copyWith(color: KAppColors.lightOnBackground),
      labelSmall: KAppTextStyles.labelSmall.copyWith(color: KAppColors.lightOnBackground),
    ),

    //? AppBar
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

    //? Card
    cardTheme: CardThemeData(
      color: KAppColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),

    //? Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KAppColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KAppColors.lightPrimary,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: BorderSide(color: KAppColors.lightPrimary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    //? Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KAppColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KAppColors.lightOnBackground.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KAppColors.lightOnBackground.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KAppColors.lightPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
      ),
      labelStyle: KAppTextStyles.bodyMedium.copyWith(color: KAppColors.lightOnBackground.withValues(alpha: 0.7)),
      hintStyle: KAppTextStyles.bodyMedium.copyWith(color: KAppColors.lightOnBackground.withValues(alpha: 0.5)),
    ),

    //? Bottom Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: KAppColors.lightSurface,
      selectedItemColor: KAppColors.lightPrimary,
      unselectedItemColor: KAppColors.lightOnBackground.withValues(alpha: 0.6),
      selectedLabelStyle: KAppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: KAppTextStyles.labelSmall,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    //? Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: KAppColors.lightPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    //? Divider
    dividerTheme: DividerThemeData(
      color: KAppColors.lightOnBackground.withValues(alpha: 0.08),
      thickness: 1,
      space: 1,
    ),

    //? Icon Theme
    iconTheme: IconThemeData(
      color: KAppColors.lightOnBackground,
      size: 24,
    ),
  );

  //? DARK THEME - Based on your exact design system colors
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    //? Color Scheme
    colorScheme: ColorScheme.dark(
      primary: KAppColors.darkPrimary,
      onPrimary: KAppColors.darkBackground,
      primaryContainer: KAppColors.darkPrimary.withValues(alpha: 0.15),
      onPrimaryContainer: KAppColors.darkPrimary,

      secondary: KAppColors.darkSecondary,
      onSecondary: KAppColors.darkBackground,
      secondaryContainer: KAppColors.darkSecondary.withValues(alpha: 0.15),
      onSecondaryContainer: KAppColors.darkSecondary,

      tertiary: KAppColors.darkTertiary,
      onTertiary: KAppColors.darkBackground,
      tertiaryContainer: KAppColors.darkTertiary.withValues(alpha: 0.15),
      onTertiaryContainer: KAppColors.darkTertiary,

      surface: KAppColors.darkSurface,
      onSurface: KAppColors.darkOnBackground,
      surfaceContainerHighest: const Color(0xFF2A2A2A),

      error: const Color(0xFFEF5350),
      onError: KAppColors.darkBackground,

      outline: KAppColors.darkOnBackground.withValues(alpha: 0.12),
      outlineVariant: KAppColors.darkOnBackground.withValues(alpha: 0.08),

      shadow: Colors.black.withValues(alpha: 0.24),
      scrim: Colors.black.withValues(alpha: 0.48),
    ),

    scaffoldBackgroundColor: KAppColors.darkBackground,

    //? Typography
    textTheme: TextTheme(
      displayLarge: KAppTextStyles.displayLarge.copyWith(color: KAppColors.darkOnBackground),
      displayMedium: KAppTextStyles.displayMedium.copyWith(color: KAppColors.darkOnBackground),
      displaySmall: KAppTextStyles.displaySmall.copyWith(color: KAppColors.darkOnBackground),
      headlineLarge: KAppTextStyles.headlineLarge.copyWith(color: KAppColors.darkOnBackground),
      headlineMedium: KAppTextStyles.headlineMedium.copyWith(color: KAppColors.darkOnBackground),
      headlineSmall: KAppTextStyles.headlineSmall.copyWith(color: KAppColors.darkOnBackground),
      titleLarge: KAppTextStyles.titleLarge.copyWith(color: KAppColors.darkOnBackground),
      titleMedium: KAppTextStyles.titleMedium.copyWith(color: KAppColors.darkOnBackground),
      titleSmall: KAppTextStyles.titleSmall.copyWith(color: KAppColors.darkOnBackground),
      bodyLarge: KAppTextStyles.bodyLarge.copyWith(color: KAppColors.darkOnBackground),
      bodyMedium: KAppTextStyles.bodyMedium.copyWith(color: KAppColors.darkOnBackground),
      bodySmall: KAppTextStyles.bodySmall.copyWith(color: KAppColors.darkOnBackground),
      labelLarge: KAppTextStyles.labelLarge.copyWith(color: KAppColors.darkOnBackground),
      labelMedium: KAppTextStyles.labelMedium.copyWith(color: KAppColors.darkOnBackground),
      labelSmall: KAppTextStyles.labelSmall.copyWith(color: KAppColors.darkOnBackground),
    ),

    //? AppBar
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

    //? Card
    cardTheme: CardThemeData(
      color: KAppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    ),

    //? Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KAppColors.darkPrimary,
        foregroundColor: KAppColors.darkBackground,
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KAppColors.darkPrimary,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: BorderSide(color: KAppColors.darkPrimary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        foregroundColor: KAppColors.darkBackground,
        textStyle: KAppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    //? Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KAppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KAppColors.darkOnBackground.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KAppColors.darkOnBackground.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: KAppColors.darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
      ),
      labelStyle: KAppTextStyles.bodyMedium.copyWith(color: KAppColors.darkOnBackground.withValues(alpha: 0.7)),
      hintStyle: KAppTextStyles.bodyMedium.copyWith(color: KAppColors.darkOnBackground.withValues(alpha: 0.5)),
    ),

    //? Bottom Navigation Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: KAppColors.darkSurface,
      selectedItemColor: KAppColors.darkPrimary,
      unselectedItemColor: KAppColors.darkOnBackground.withValues(alpha: 0.6),
      selectedLabelStyle: KAppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: KAppTextStyles.labelSmall,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    //? Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: KAppColors.darkPrimary,
      foregroundColor: KAppColors.darkBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    //? Divider
    dividerTheme: DividerThemeData(
      color: KAppColors.darkOnBackground.withValues(alpha: 0.08),
      thickness: 1,
      space: 1,
    ),

    //? Icon Theme
    iconTheme: IconThemeData(
      color: KAppColors.darkOnBackground,
      size: 24,
    ),
  );
}
