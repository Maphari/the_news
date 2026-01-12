import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class ArticleHeader extends StatelessWidget {
  const ArticleHeader({
    super.key,
    required this.onBackPressed,
    required this.onSharePressed,
    this.onPreferencesPressed,
    this.onLibraryPressed,
  });

  final VoidCallback onBackPressed;
  final VoidCallback onSharePressed;
  final VoidCallback? onPreferencesPressed;
  final VoidCallback? onLibraryPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackPressed,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: KAppColors.getOnBackground(context),
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          if (onLibraryPressed != null) ...[
            GestureDetector(
              onTap: onLibraryPressed,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.bookmark_outline,
                  color: KAppColors.getOnBackground(context),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (onPreferencesPressed != null) ...[
            GestureDetector(
              onTap: onPreferencesPressed,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.text_fields_rounded,
                  color: KAppColors.getOnBackground(context),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          GestureDetector(
            onTap: onSharePressed,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons.ios_share,
                color: KAppColors.getOnBackground(context),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
