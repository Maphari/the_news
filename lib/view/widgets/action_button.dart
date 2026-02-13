import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

/// A circular action button with an icon, commonly used for actions like
/// share, bookmark, like, etc.
///
/// Provides consistent styling for circular action buttons across the app
/// with customizable icon, color, size, and tap behavior.
///
/// ## Usage:
/// ```dart
/// ActionButton(
///   icon: Icons.share,
///   color: KAppColors.blue,
///   onPressed: () => print('Share pressed'),
/// )
/// ```
///
/// ## Custom size:
/// ```dart
/// ActionButton(
///   icon: Icons.favorite,
///   color: KAppColors.error,
///   size: 56.0,
///   iconSize: 28.0,
///   onPressed: () {},
/// )
/// ```
class ActionButton extends StatelessWidget {
  /// The icon to display in the button.
  final IconData icon;

  /// The background color of the button.
  final Color color;

  /// Callback when the button is pressed. If null, the button will be disabled.
  final VoidCallback? onPressed;

  /// The size of the button (width and height).
  /// Defaults to 48.0.
  final double size;

  /// The size of the icon inside the button.
  /// Defaults to [KDesignConstants.iconMd] (24.0).
  final double? iconSize;

  /// The color of the icon.
  /// If null, uses [KAppColors.darkOnBackground] for contrast.
  final Color? iconColor;

  /// Whether to show a shadow beneath the button.
  /// Defaults to true.
  final bool hasShadow;

  /// Optional tooltip text for accessibility.
  final String? tooltip;

  /// Creates a circular action button with an icon.
  const ActionButton({
    super.key,
    required this.icon,
    required this.color,
    this.onPressed,
    this.size = 48.0,
    this.iconSize,
    this.iconColor,
    this.hasShadow = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? KDesignConstants.iconMd;
    final effectiveIconColor = iconColor ?? KAppColors.getOnPrimary(context);

    Widget button = AnimatedContainer(
      duration: KDesignConstants.durationFast,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: hasShadow ? KShadows.medium(context) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: KBorderRadius.full,
          splashColor: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
          highlightColor: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          child: Center(
            child: Icon(
              icon,
              size: effectiveIconSize,
              color: onPressed != null
                  ? effectiveIconColor
                  : effectiveIconColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// A row of action buttons with consistent spacing.
///
/// ## Usage:
/// ```dart
/// ActionButtonRow(
///   buttons: [
///     ActionButton(icon: Icons.share, color: KAppColors.blue, onPressed: () {}),
///     ActionButton(icon: Icons.bookmark, color: KAppColors.orange, onPressed: () {}),
///     ActionButton(icon: Icons.favorite, color: KAppColors.error, onPressed: () {}),
///   ],
/// )
/// ```
class ActionButtonRow extends StatelessWidget {
  /// The list of action buttons to display.
  final List<ActionButton> buttons;

  /// The spacing between buttons.
  /// Defaults to [KDesignConstants.spacing12].
  final double spacing;

  /// Alignment of the buttons in the row.
  /// Defaults to [MainAxisAlignment.center].
  final MainAxisAlignment mainAxisAlignment;

  /// Creates a row of action buttons.
  const ActionButtonRow({
    super.key,
    required this.buttons,
    this.spacing = KDesignConstants.spacing12,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: buttons
          .map((button) => Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: button,
              ))
          .toList(),
    );
  }
}
