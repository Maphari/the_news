import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class ArticleMetaInfo extends StatelessWidget {
  const ArticleMetaInfo({
    super.key,
    required this.authorName,
    this.sourceIcon,
    required this.onFollowPressed,
  });

  final String authorName;
  final String? sourceIcon;
  final VoidCallback onFollowPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: KAppColors.getPrimary(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: sourceIcon != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      sourceIcon!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.newspaper,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.newspaper,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Published by',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.54),
                  ),
                ),
                Text(
                  authorName,
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onFollowPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: KAppColors.getPrimary(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Follow',
              style: KAppTextStyles.labelLarge.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}