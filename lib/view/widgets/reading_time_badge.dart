import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/utils/reading_time_calculator.dart';

/// A badge widget that displays estimated reading time for an article
class ReadingTimeBadge extends StatelessWidget {
  const ReadingTimeBadge({
    super.key,
    required this.text,
    this.showIcon = true,
    this.compact = false,
  });

  final String text;
  final bool showIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final readingTime = ReadingTimeCalculator.calculateReadingTime(text);

    if (compact) {
      return _buildCompactBadge(context, readingTime);
    }

    return _buildFullBadge(context, readingTime);
  }

  Widget _buildFullBadge(BuildContext context, String readingTime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        borderRadius: KBorderRadius.xl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.schedule_outlined,
              size: 14,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            readingTime,
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBadge(BuildContext context, String readingTime) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.schedule_outlined,
            size: 12,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
          ),
          const SizedBox(width: KDesignConstants.spacing4),
        ],
        Text(
          readingTime,
          style: KAppTextStyles.bodySmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// A badge for card-based layouts with custom styling
class ReadingTimeCardBadge extends StatelessWidget {
  const ReadingTimeCardBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
  });

  final String text;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final readingTime = ReadingTimeCalculator.calculateReadingTime(text);
    final bgColor = backgroundColor ?? KAppColors.darkBackground.withValues(alpha: 0.1);
    final txtColor = textColor ?? KAppColors.darkBackground.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: KBorderRadius.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 12,
            color: txtColor,
          ),
          const SizedBox(width: KDesignConstants.spacing4),
          Text(
            readingTime,
            style: KAppTextStyles.labelSmall.copyWith(
              color: txtColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
