import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class ExploreSearchBar extends StatelessWidget {
  const ExploreSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KAppColors.primary.withValues(alpha: 0.08),
            KAppColors.tertiary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KAppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: KAppColors.primary.withValues(alpha: 0.7),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: KAppTextStyles.bodyLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search articles, topics, sources...',
                hintStyle: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: KAppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: KAppColors.primary,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
