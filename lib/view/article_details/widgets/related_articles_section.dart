import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/related_articles_service.dart';
import 'package:the_news/utils/reading_time_calculator.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class RelatedArticlesSection extends StatelessWidget {
  const RelatedArticlesSection({super.key, required this.currentArticle});

  final ArticleModel currentArticle;

  @override
  Widget build(BuildContext context) {
    final relatedArticlesService = RelatedArticlesService.instance;

    // Get smart recommendations using our algorithm
    final relatedArticles = relatedArticlesService.getRelatedArticles(
      currentArticle,
      limit: 5,
    );

    if (relatedArticles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              color: KAppColors.getPrimary(context),
              size: 22,
            ),
            const SizedBox(width: KDesignConstants.spacing12),
            Text(
              'You might also like',
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: KDesignConstants.spacing16),
        ...relatedArticles.map((article) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _RelatedArticleCard(
                article: article,
                onTap: () {
                  AppRoutes.navigateTo(
                    context,
                    AppRoutes.articleDetail,
                    arguments: article,
                  );
                },
              ),
            )),
      ],
    );
  }
}

class _RelatedArticleCard extends StatelessWidget {
  const _RelatedArticleCard({
    required this.article,
    required this.onTap,
  });

  final ArticleModel article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: KDesignConstants.paddingSm,
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: KBorderRadius.md,
                child: SafeNetworkImage(
                  article.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                        borderRadius: KBorderRadius.md,
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(width: KDesignConstants.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KDesignConstants.spacing4),
                  Text(
                    article.sourceName,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.54),
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 12,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: KDesignConstants.spacing4),
                      Text(
                        ReadingTimeCalculator.calculateReadingTime(article.content),
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
