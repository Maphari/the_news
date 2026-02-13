import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

/// A consistent section header widget used across all pages.
///
/// Provides a standardized section header with icon, title, and optional
/// "View All" action button. Use this for sections like "Trending Now",
/// "Your Library", "Popular Sources", etc.
///
/// ## Basic Usage:
/// ```dart
/// SectionHeader(
///   title: 'Trending Now',
///   icon: Icons.trending_up,
/// )
/// ```
///
/// ## With action button:
/// ```dart
/// SectionHeader(
///   title: 'Popular Sources',
///   icon: Icons.newspaper_outlined,
///   actionLabel: 'View All',
///   onAction: () => navigateToAllSources(),
/// )
/// ```
///
/// ## Custom styling:
/// ```dart
/// SectionHeader(
///   title: 'Your Library',
///   icon: Icons.bookmark,
///   iconColor: Colors.amber,
///   showGradientIcon: true,
/// )
/// ```
class SectionHeader extends StatelessWidget {
  /// The title text for the section.
  final String title;

  /// The icon to display before the title.
  final IconData icon;

  /// Optional action button label (e.g., "View All", "See More").
  final String? actionLabel;

  /// Callback when the action button is pressed.
  final VoidCallback? onAction;

  /// The color of the icon.
  /// If null, uses the theme's primary color.
  final Color? iconColor;

  /// Whether to show the icon in a gradient container.
  /// Defaults to false.
  final bool showGradientIcon;

  /// The size of the icon.
  /// Defaults to [KDesignConstants.iconMd] (24.0).
  final double iconSize;

  /// Whether to use large title style.
  /// Defaults to true.
  final bool useLargeTitle;

  /// Custom padding for the header.
  /// Defaults to horizontal padding with spacing16.
  final EdgeInsets? padding;

  /// Creates a section header widget.
  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.showGradientIcon = false,
    this.iconSize = KDesignConstants.iconMd,
    this.useLargeTitle = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? KAppColors.getPrimary(context);
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: KDesignConstants.spacing16,
          vertical: KDesignConstants.spacing8,
        );

    return Padding(
      padding: effectivePadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Icon (with optional gradient container)
                if (showGradientIcon)
                  _buildGradientIcon(context, effectiveIconColor)
                else
                  Icon(
                    icon,
                    color: effectiveIconColor,
                    size: iconSize,
                  ),
                const SizedBox(width: KDesignConstants.spacing12),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: useLargeTitle
                        ? KAppTextStyles.titleLarge.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w800,
                          )
                        : KAppTextStyles.titleMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.bold,
                          ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Action button
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: KDesignConstants.spacing12,
                  vertical: KDesignConstants.spacing8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradientIcon(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.all(KDesignConstants.spacing8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            KAppColors.getTertiary(context).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: KBorderRadius.md,
      ),
      child: Icon(
        icon,
        color: color,
        size: iconSize - 4, // Slightly smaller inside container
      ),
    );
  }
}

/// A sliver version of SectionHeader for use in CustomScrollView.
///
/// ## Usage:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverSectionHeader(
///       title: 'Trending',
///       icon: Icons.trending_up,
///     ),
///     SliverList(...),
///   ],
/// )
/// ```
class SliverSectionHeader extends StatelessWidget {
  /// The title text for the section.
  final String title;

  /// The icon to display before the title.
  final IconData icon;

  /// Optional action button label.
  final String? actionLabel;

  /// Callback when the action button is pressed.
  final VoidCallback? onAction;

  /// The color of the icon.
  final Color? iconColor;

  /// Whether to show the icon in a gradient container.
  final bool showGradientIcon;

  /// The size of the icon.
  final double iconSize;

  /// Whether to use large title style.
  final bool useLargeTitle;

  /// Custom padding for the header.
  final EdgeInsets? padding;

  /// Creates a sliver section header widget.
  const SliverSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.showGradientIcon = false,
    this.iconSize = KDesignConstants.iconMd,
    this.useLargeTitle = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SectionHeader(
        title: title,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        iconColor: iconColor,
        showGradientIcon: showGradientIcon,
        iconSize: iconSize,
        useLargeTitle: useLargeTitle,
        padding: padding,
      ),
    );
  }
}
