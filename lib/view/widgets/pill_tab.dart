import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class PillTabContainer extends StatelessWidget {
  const PillTabContainer({
    super.key,
    required this.child,
    required this.selected,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.height = KDesignConstants.tabHeight,
    this.borderRadius,
  });

  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? KAppColors.getPrimary(context)
        : KAppColors.getOnBackground(context).withValues(alpha: 0.06);
    final borderColor = selected
        ? KAppColors.getPrimary(context).withValues(alpha: 0.6)
        : KAppColors.getOnBackground(context).withValues(alpha: 0.12);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius ?? KBorderRadius.xl,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? KBorderRadius.xl,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        alignment: Alignment.center,
        padding: padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius ?? KBorderRadius.xl,
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: child,
      ),
    ));
  }
}

class PillTab extends StatelessWidget {
  const PillTab({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.padding,
    this.textStyle,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final EdgeInsets? padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final fgColor = selected
        ? KAppColors.getOnPrimary(context)
        : KAppColors.getOnBackground(context).withValues(alpha: 0.7);

    return PillTabContainer(
      selected: selected,
      onTap: onTap,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fgColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: textStyle ??
                KAppTextStyles.labelMedium.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
