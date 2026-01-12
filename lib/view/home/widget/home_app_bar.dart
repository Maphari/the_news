import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showActions = false,
    this.bottom = 12,
    this.viewToggle,
  });

  final String title;
  final String? subtitle;
  final double bottom;
  final bool showActions;
  final Widget? viewToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and optional actions in same row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: KAppTextStyles.headlineLarge.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        height: 1.1,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: KAppTextStyles.bodyMedium.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // View toggle on same row as title (only for home page)
              if (showActions && viewToggle != null) ...[
                const SizedBox(width: 12),
                viewToggle!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
