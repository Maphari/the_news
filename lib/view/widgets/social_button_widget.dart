import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class SocialButtonWidget extends StatelessWidget {
  const SocialButtonWidget({
    super.key,
    required this.buttonText,
    required this.imagePath,
    required this.onPressed,
    this.imageHeight = 24,
    this.imageWidth = 24,
    required this.iconData,
  });

  final String buttonText;
  final String imagePath;
  final VoidCallback onPressed;
  final double imageHeight;
  final double imageWidth;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Image.asset(
          imagePath,
          height: imageHeight,
          width: imageWidth,
          errorBuilder: (context, error, stackTrace) {
            return Icon(iconData, size: imageWidth, color: KAppColors.getOnBackground(context).withValues(alpha: 0.6));
          },
        ),
        label: Text(buttonText, style: TextStyle(color: KAppColors.getOnBackground(context).withValues(alpha: 0.3))),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: KAppColors.getOnBackground(context).withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: KBorderRadius.md,
          ),
        ),
      ),
    );
  }
}
