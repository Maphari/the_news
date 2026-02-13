import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

/// A consistent empty state widget with icon, title, and optional action.
///
/// Displays an informative empty state when there's no content to show,
/// with an optional call-to-action button.
///
/// ## Usage:
/// ```dart
/// EmptyState(
///   icon: Icons.inbox,
///   title: 'No articles',
/// )
/// ```
///
/// ## With subtitle and action:
/// ```dart
/// EmptyState(
///   icon: Icons.bookmark_border,
///   title: 'No saved articles',
///   subtitle: 'Articles you save will appear here',
///   actionLabel: 'Browse Articles',
///   onAction: () => navigateToHome(),
/// )
/// ```
///
/// ## Custom styling:
/// ```dart
/// EmptyState(
///   icon: Icons.search_off,
///   title: 'No results found',
///   iconSize: 80.0,
///   iconColor: Colors.grey,
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// The icon to display at the top.
  final IconData icon;

  /// The main title text.
  final String title;

  /// Optional subtitle/description text.
  final String? subtitle;

  /// Optional action button label.
  final String? actionLabel;

  /// Callback when the action button is pressed.
  final VoidCallback? onAction;

  /// The size of the icon.
  /// Defaults to [KDesignConstants.iconXl] (40.0).
  final double iconSize;

  /// The color of the icon.
  /// If null, uses a semi-transparent version of the on-background color.
  final Color? iconColor;

  /// Whether to expand to fill available space.
  /// Defaults to true.
  final bool expand;

  /// Optional custom widget to display instead of the default action button.
  final Widget? customAction;

  /// Creates an empty state widget.
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64.0,
    this.iconColor,
    this.expand = true,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? KAppColors.getOnBackground(context).withValues(alpha: 0.3);

    Widget content = Padding(
      padding: KDesignConstants.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with subtle background
          Container(
            width: iconSize + KDesignConstants.spacing32,
            height: iconSize + KDesignConstants.spacing32,
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: effectiveIconColor,
              ),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing24),

          // Title
          Text(
            title,
            style: KAppTextStyles.titleLarge.copyWith(
              color: KAppColors.getOnBackground(context),
            ),
            textAlign: TextAlign.center,
          ),

          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: KDesignConstants.spacing8),
            Text(
              subtitle!,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // Action button or custom action
          if (customAction != null) ...[
            const SizedBox(height: KDesignConstants.spacing24),
            customAction!,
          ] else if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: KDesignConstants.spacing24),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: KAppColors.getPrimary(context),
                foregroundColor: KAppColors.getOnPrimary(context),
                padding: const EdgeInsets.symmetric(
                  horizontal: KDesignConstants.spacing24,
                  vertical: KDesignConstants.spacing12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: KBorderRadius.md,
                ),
              ),
              child: Text(
                actionLabel!,
                style: KAppTextStyles.labelLarge,
              ),
            ),
          ],
        ],
      ),
    );

    if (expand) {
      return Center(child: content);
    }

    return content;
  }
}

/// A compact empty state for use in smaller spaces like list items.
///
/// ## Usage:
/// ```dart
/// CompactEmptyState(
///   icon: Icons.comment_outlined,
///   message: 'No comments yet',
/// )
/// ```
class CompactEmptyState extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The message to display.
  final String message;

  /// The size of the icon.
  /// Defaults to [KDesignConstants.iconMd] (24.0).
  final double iconSize;

  /// Creates a compact empty state widget.
  const CompactEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.iconSize = KDesignConstants.iconMd,
  });

  @override
  Widget build(BuildContext context) {
    final subtleColor =
        KAppColors.getOnBackground(context).withValues(alpha: 0.5);

    return Padding(
      padding: KDesignConstants.paddingMd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: subtleColor,
          ),
          const SizedBox(width: KDesignConstants.spacing8),
          Text(
            message,
            style: KAppTextStyles.bodySmall.copyWith(
              color: subtleColor,
            ),
          ),
        ],
      ),
    );
  }
}
