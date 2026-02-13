import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

/// A standard card wrapper with consistent styling across the app.
///
/// Provides a consistent look and feel for card-based UI elements with
/// customizable padding, border, shadow, and tap behavior.
///
/// ## Usage:
/// ```dart
/// StandardCard(
///   child: Text('Card content'),
///   onTap: () => print('Card tapped'),
///   padding: KDesignConstants.paddingMd,
/// )
/// ```
///
/// ## With custom styling:
/// ```dart
/// StandardCard(
///   child: MyWidget(),
///   hasBorder: true,
///   hasShadow: false,
///   borderRadius: KBorderRadius.xl,
/// )
/// ```
class StandardCard extends StatelessWidget {
  /// The widget to display inside the card.
  final Widget child;

  /// Callback when the card is tapped. If null, the card won't respond to taps.
  final VoidCallback? onTap;

  /// Padding around the child widget.
  /// Defaults to [KDesignConstants.paddingMd] (16.0 on all sides).
  final EdgeInsets? padding;

  /// Whether to show a border around the card.
  /// Defaults to false.
  final bool hasBorder;

  /// Whether to show a shadow beneath the card.
  /// Defaults to true.
  final bool hasShadow;

  /// Custom border radius for the card.
  /// Defaults to [KBorderRadius.lg] (16.0).
  final BorderRadius? borderRadius;

  /// Custom background color for the card.
  /// If null, uses the theme's surface color.
  final Color? backgroundColor;

  /// Custom border color when [hasBorder] is true.
  /// If null, uses the theme's outline color.
  final Color? borderColor;

  /// Creates a standard card with consistent styling.
  const StandardCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.hasBorder = false,
    this.hasShadow = true,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = borderRadius ?? KBorderRadius.lg;
    final effectivePadding = padding ?? KDesignConstants.paddingMd;
    final effectiveBackgroundColor =
        backgroundColor ?? KAppColors.getSurface(context);

    return AnimatedContainer(
      duration: KDesignConstants.durationFast,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        border: hasBorder
            ? Border.all(
                color: borderColor ?? theme.colorScheme.outline,
                width: 1.0,
              )
            : null,
        boxShadow: hasShadow ? KShadows.low(context) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        ),
      ),
    );
  }
}
