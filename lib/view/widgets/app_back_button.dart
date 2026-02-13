import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.padding,
    this.iconSize = 20,
  });

  final VoidCallback? onPressed;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? onTap ?? () => Navigator.maybePop(context),
      icon: Icon(
        Icons.arrow_back,
        color: iconColor ?? KAppColors.getOnBackground(context),
        size: iconSize,
      ),
      splashRadius: 20,
      padding: padding ?? EdgeInsets.zero,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}
