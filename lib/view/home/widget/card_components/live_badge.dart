import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'LIVE',
        style: KAppTextStyles.labelSmall.copyWith(
          color: KAppColors.getOnBackground(context),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
