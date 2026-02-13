import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

/// A consistent loading state widget with an optional message.
///
/// Displays a circular progress indicator with optional loading text,
/// centered in the available space.
///
/// ## Usage:
/// ```dart
/// LoadingState()
/// ```
///
/// ## With message:
/// ```dart
/// LoadingState(message: 'Loading articles...')
/// ```
///
/// ## Custom styling:
/// ```dart
/// LoadingState(
///   message: 'Please wait',
///   indicatorSize: 48.0,
///   indicatorColor: Colors.blue,
/// )
/// ```
class LoadingState extends StatelessWidget {
  /// Optional message to display below the loading indicator.
  final String? message;

  /// The size of the loading indicator.
  /// Defaults to 40.0.
  final double indicatorSize;

  /// The color of the loading indicator.
  /// If null, uses the theme's primary color.
  final Color? indicatorColor;

  /// The stroke width of the loading indicator.
  /// Defaults to 3.0.
  final double strokeWidth;

  /// Whether to expand to fill available space.
  /// Defaults to true.
  final bool expand;

  /// Creates a loading state widget.
  const LoadingState({
    super.key,
    this.message,
    this.indicatorSize = 40.0,
    this.indicatorColor,
    this.strokeWidth = 3.0,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = indicatorColor ?? KAppColors.getPrimary(context);

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: KDesignConstants.spacing16),
          Text(
            message!,
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (expand) {
      return Center(child: content);
    }

    return content;
  }
}

/// A compact inline loading indicator.
///
/// ## Usage:
/// ```dart
/// Row(
///   children: [
///     Text('Saving'),
///     const SizedBox(width: KDesignConstants.spacing8),
///     InlineLoadingIndicator(),
///   ],
/// )
/// ```
class InlineLoadingIndicator extends StatelessWidget {
  /// The size of the indicator.
  /// Defaults to 16.0.
  final double size;

  /// The color of the indicator.
  /// If null, uses the theme's primary color.
  final Color? color;

  /// The stroke width of the indicator.
  /// Defaults to 2.0.
  final double strokeWidth;

  /// Creates a compact inline loading indicator.
  const InlineLoadingIndicator({
    super.key,
    this.size = 16.0,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? KAppColors.getPrimary(context);

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
      ),
    );
  }
}
