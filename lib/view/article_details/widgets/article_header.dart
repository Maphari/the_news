import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/view/widgets/app_back_button.dart';

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
      padding: KDesignConstants.paddingMd,
      child: Row(
        children: [
          AppBackButton(onTap: onBackPressed),
          const Spacer(),
          if (onLibraryPressed != null) ...[
            GestureDetector(
              onTap: onLibraryPressed,
              child: Container(
                padding: KDesignConstants.paddingSm,
                decoration: BoxDecoration(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  borderRadius: KBorderRadius.md,
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
            const SizedBox(width: KDesignConstants.spacing12),
          ],
          if (onPreferencesPressed != null) ...[
            GestureDetector(
              onTap: onPreferencesPressed,
              child: Container(
                padding: KDesignConstants.paddingSm,
                decoration: BoxDecoration(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  borderRadius: KBorderRadius.md,
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
            const SizedBox(width: KDesignConstants.spacing12),
          ],
          GestureDetector(
            onTap: onSharePressed,
            child: Container(
              padding: KDesignConstants.paddingSm,
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                borderRadius: KBorderRadius.md,
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
