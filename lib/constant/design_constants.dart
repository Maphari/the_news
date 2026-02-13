import 'package:flutter/material.dart';

/// Design system constants for consistent spacing, sizing, and layout
/// Following Material Design 3 guidelines with 8dp grid system
class KDesignConstants {
  // Spacing scale (8dp grid)
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // Border radius scale
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2xl = 24.0;
  static const double radiusFull = 999.0;

  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;

  // Common edge insets
  static const EdgeInsets paddingXs = EdgeInsets.all(spacing4);
  static const EdgeInsets paddingSm = EdgeInsets.all(spacing8);
  static const EdgeInsets paddingMd = EdgeInsets.all(spacing16);
  static const EdgeInsets paddingLg = EdgeInsets.all(spacing24);
  static const EdgeInsets paddingXl = EdgeInsets.all(spacing32);

  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: spacing16);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: spacing24);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: spacing16);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: spacing24);

  // Content max widths for readability
  static const double contentMaxWidth = 720.0; // Optimal reading width
  static const double articleMaxWidth = 680.0; // Article content width

  // Animation durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);

  // Elevation levels
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // ==================== CARD DESIGN TOKENS ====================

  /// Standard card border radius
  static const double cardBorderRadius = radiusLg; // 16.0

  /// Compact card border radius (for smaller cards)
  static const double cardBorderRadiusCompact = radiusMd; // 12.0

  /// Standard card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(spacing16);

  /// Compact card padding
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(spacing12);

  /// Standard card margin between items in a list
  static const double cardListSpacing = spacing12;

  // ==================== SECTION DESIGN TOKENS ====================

  /// Standard section header padding
  static const EdgeInsets sectionHeaderPadding = EdgeInsets.symmetric(
    horizontal: spacing16,
    vertical: spacing8,
  );

  /// Space between section header and content
  static const double sectionContentSpacing = spacing16;

  /// Space between sections
  static const double sectionSpacing = spacing24;

  // ==================== IMAGE DESIGN TOKENS ====================

  /// Standard article thumbnail size
  static const Size articleThumbnailSize = Size(120, 80);

  /// Large article image aspect ratio (16:9)
  static const double articleImageAspectRatio = 16 / 9;

  /// Podcast cover art sizes
  static const double podcastCoverSmall = 60.0;
  static const double podcastCoverMedium = 80.0;
  static const double podcastCoverLarge = 150.0;

  /// Source/publisher logo sizes
  static const double sourceLogoSmall = 32.0;
  static const double sourceLogoMedium = 40.0;
  static const double sourceLogoLarge = 50.0;

  /// Avatar sizes
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge = 64.0;

  // ==================== LIST DESIGN TOKENS ====================

  /// Standard list item height
  static const double listItemHeight = 72.0;

  /// Compact list item height
  static const double listItemHeightCompact = 56.0;

  /// Standard tab height
  static const double tabHeight = 40.0;

  /// Horizontal list item width (for carousels)
  static const double horizontalListItemWidth = 160.0;

  /// Horizontal list height
  static const double horizontalListHeight = 220.0;

  // ==================== ANIMATION CURVES ====================

  /// Standard easing curve for UI transitions
  static const Curve curveStandard = Curves.easeInOut;

  /// Emphasized easing for dramatic transitions
  static const Curve curveEmphasized = Curves.easeOutCubic;

  /// Decelerated easing for elements entering
  static const Curve curveDecelerated = Curves.easeOut;

  /// Accelerated easing for elements exiting
  static const Curve curveAccelerated = Curves.easeIn;

  // ==================== OPACITY VALUES ====================

  /// Subtle overlay opacity (for hover states)
  static const double opacitySubtle = 0.05;

  /// Light overlay opacity (for pressed states)
  static const double opacityLight = 0.1;

  /// Medium overlay opacity (for disabled states)
  static const double opacityMedium = 0.3;

  /// High overlay opacity (for modal overlays)
  static const double opacityHigh = 0.6;

  /// Secondary text opacity
  static const double opacitySecondaryText = 0.7;

  /// Tertiary/hint text opacity
  static const double opacityTertiaryText = 0.5;

  /// Disabled content opacity
  static const double opacityDisabled = 0.38;

}

/// Common border radius configurations
class KBorderRadius {
  static BorderRadius get xs => BorderRadius.circular(KDesignConstants.radiusXs);
  static BorderRadius get sm => BorderRadius.circular(KDesignConstants.radiusSm);
  static BorderRadius get md => BorderRadius.circular(KDesignConstants.radiusMd);
  static BorderRadius get lg => BorderRadius.circular(KDesignConstants.radiusLg);
  static BorderRadius get xl => BorderRadius.circular(KDesignConstants.radiusXl);
  static BorderRadius get xxl => BorderRadius.circular(KDesignConstants.radius2xl);
  static BorderRadius get full => BorderRadius.circular(KDesignConstants.radiusFull);
}

/// Common box shadows
class KShadows {
  static List<BoxShadow> low(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> medium(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> high(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.16),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}
