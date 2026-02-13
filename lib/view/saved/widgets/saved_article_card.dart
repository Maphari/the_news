import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class SavedArticleCard extends StatelessWidget {
  const SavedArticleCard({
    super.key,
    required this.article,
    required this.isGridView,
    required this.onRemove,
  });

  final ArticleModel article;
  final bool isGridView;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: KBorderRadius.xl,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to article detail
            },
            child: Padding(
              padding: KDesignConstants.paddingSm,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article Image
                  if (article.imageUrl != null)
                    ClipRRect(
                      borderRadius: KBorderRadius.lg,
                      child: SafeNetworkImage(
                        article.imageUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                              borderRadius: KBorderRadius.lg,
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(width: KDesignConstants.spacing16),
                  
                  // Article Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(context: context).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article.category.toString(),
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: _getCategoryColor(context: context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: KDesignConstants.spacing8),
                        
                        // Title
                        Text(
                          article.title,
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: KDesignConstants.spacing8),
                        
                        // Metadata Row
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: KDesignConstants.spacing4),
                            Expanded(
                              child: Text(
                                article.pubDateTZ,
                                style: KAppTextStyles.bodySmall.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: KDesignConstants.spacing8),
                            // Remove Button
                            InkWell(
                              onTap: onRemove,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: KDesignConstants.paddingXs,
                                child: Icon(
                                  Icons.bookmark,
                                  size: 20,
                                  color: KAppColors.getPrimary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor({required BuildContext context}) {
    switch (article.category.toString().toLowerCase()) {
      case 'technology':
        return KAppColors.getTertiary(context);
      case 'business':
        return KAppColors.getSecondary(context);
      case 'sports':
        return KAppColors.red;
      case 'entertainment':
        return KAppColors.orange;
      case 'science':
        return KAppColors.blue;
      case 'health':
        return KAppColors.pink;
      default:
        return KAppColors.getPrimary(context);
    }
  }
}
