import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

/// A consistent error state widget with icon, message, and retry action.
///
/// Displays an error message with an optional retry button when something
/// goes wrong, such as a failed network request.
///
/// ## Usage:
/// ```dart
/// ErrorState(
///   message: 'Failed to load articles',
///   onRetry: () => fetchArticles(),
/// )
/// ```
///
/// ## Without retry action:
/// ```dart
/// ErrorState(
///   message: 'Something went wrong',
/// )
/// ```
///
/// ## Custom styling:
/// ```dart
/// ErrorState(
///   message: 'Network error',
///   icon: Icons.wifi_off,
///   iconColor: Colors.orange,
///   retryLabel: 'Try Again',
///   onRetry: () => retry(),
/// )
/// ```
class ErrorState extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Callback when the retry button is pressed.
  final VoidCallback? onRetry;

  /// The icon to display.
  /// Defaults to [Icons.error_outline].
  final IconData icon;

  /// The size of the icon.
  /// Defaults to 64.0.
  final double iconSize;

  /// The color of the icon.
  /// If null, uses the theme's error color.
  final Color? iconColor;

  /// The label for the retry button.
  /// Defaults to 'Retry'.
  final String retryLabel;

  /// Whether to expand to fill available space.
  /// Defaults to true.
  final bool expand;

  /// Optional additional details about the error.
  final String? details;

  /// Creates an error state widget.
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconSize = 64.0,
    this.iconColor,
    this.retryLabel = 'Retry',
    this.expand = true,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.error;

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

          // Error message
          Text(
            message,
            style: KAppTextStyles.titleMedium.copyWith(
              color: KAppColors.getOnBackground(context),
            ),
            textAlign: TextAlign.center,
          ),

          // Optional details
          if (details != null) ...[
            const SizedBox(height: KDesignConstants.spacing8),
            Text(
              details!,
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // Retry button
          if (onRetry != null) ...[
            const SizedBox(height: KDesignConstants.spacing24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: KAppColors.getPrimary(context),
                side: BorderSide(
                  color: KAppColors.getPrimary(context),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: KDesignConstants.spacing24,
                  vertical: KDesignConstants.spacing12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: KBorderRadius.md,
                ),
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

/// A compact inline error message for use in smaller spaces.
///
/// ## Usage:
/// ```dart
/// InlineErrorMessage(
///   message: 'Failed to load',
///   onRetry: () => retry(),
/// )
/// ```
class InlineErrorMessage extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Callback when the retry button is pressed.
  final VoidCallback? onRetry;

  /// Creates a compact inline error message.
  const InlineErrorMessage({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Padding(
      padding: KDesignConstants.paddingMd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: KDesignConstants.iconSm,
            color: errorColor,
          ),
          const SizedBox(width: KDesignConstants.spacing8),
          Flexible(
            child: Text(
              message,
              style: KAppTextStyles.bodySmall.copyWith(
                color: errorColor,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: KDesignConstants.spacing8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: KDesignConstants.spacing8,
                  vertical: KDesignConstants.spacing4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: KAppTextStyles.labelSmall.copyWith(
                  color: KAppColors.getPrimary(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// An error banner that can be shown at the top or bottom of a screen.
///
/// ## Usage:
/// ```dart
/// ErrorBanner(
///   message: 'No internet connection',
///   onDismiss: () => hideError(),
///   onRetry: () => retry(),
/// )
/// ```
class ErrorBanner extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Callback when the dismiss button is pressed.
  final VoidCallback? onDismiss;

  /// Callback when the retry button is pressed.
  final VoidCallback? onRetry;

  /// Creates an error banner.
  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KDesignConstants.spacing16,
        vertical: KDesignConstants.spacing12,
      ),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: errorColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: KDesignConstants.iconSm,
            color: errorColor,
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: Text(
              message,
              style: KAppTextStyles.bodySmall.copyWith(
                color: errorColor,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: KDesignConstants.spacing8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: KAppTextStyles.labelSmall.copyWith(
                  color: KAppColors.getPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                size: KDesignConstants.iconSm,
                color: errorColor,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
