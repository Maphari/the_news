import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class ArticleMetaInfo extends StatelessWidget {
  const ArticleMetaInfo({
    super.key,
    required this.authorName,
    this.sourceIcon,
    required this.onFollowPressed,
    required this.isFollowing,
    this.isLoading = false,
  });

  final String authorName;
  final String? sourceIcon;
  final VoidCallback onFollowPressed;
  final bool isFollowing;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: KBorderRadius.lg,
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
              borderRadius: KBorderRadius.md,
            ),
            child: sourceIcon != null && sourceIcon!.isNotEmpty && sourceIcon!.startsWith('http')
                ? ClipRRect(
                    borderRadius: KBorderRadius.md,
                    child: SafeNetworkImage(
                      sourceIcon!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.newspaper,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? KAppColors.darkBackground
                              : KAppColors.darkOnBackground,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.newspaper,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? KAppColors.darkBackground
                        : KAppColors.darkOnBackground,
                  ),
          ),
          const SizedBox(width: KDesignConstants.spacing12),
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
            onPressed: isLoading ? null : onFollowPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing
                  ? KAppColors.getPrimary(context).withValues(alpha: 0.15)
                  : KAppColors.getPrimary(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).brightness == Brightness.dark
                            ? KAppColors.darkBackground
                            : KAppColors.darkOnBackground,
                      ),
                    ),
                  )
                : Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: KAppTextStyles.labelLarge.copyWith(
                      color: isFollowing
                          ? KAppColors.getPrimary(context)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? KAppColors.darkBackground
                              : KAppColors.darkOnBackground),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
