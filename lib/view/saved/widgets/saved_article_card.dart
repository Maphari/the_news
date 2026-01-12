import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to article detail
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article Image
                  if (article.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
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
                              borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(width: 16),
                  
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
                            color: _getCategoryColor().withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article.category.toString(),
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: _getCategoryColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
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
                        const SizedBox(height: 8),
                        
                        // Metadata Row
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
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
                            const SizedBox(width: 8),
                            // Remove Button
                            InkWell(
                              onTap: onRemove,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.bookmark,
                                  size: 20,
                                  color: KAppColors.primary,
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

  Color _getCategoryColor() {
    switch (article.category.toString().toLowerCase()) {
      case 'technology':
        return KAppColors.tertiary;
      case 'business':
        return KAppColors.secondary;
      case 'sports':
        return const Color(0xFFFFC5C9);
      case 'entertainment':
        return const Color(0xFFFFD4A3);
      case 'science':
        return const Color(0xFFC5D9FF);
      case 'health':
        return const Color(0xFFFFB8B8);
      default:
        return KAppColors.primary;
    }
  }
}