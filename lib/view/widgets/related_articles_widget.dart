import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/related_articles_service.dart';
import 'package:the_news/service/article_access_service.dart';
import 'package:the_news/utils/reading_time_calculator.dart';

/// Widget that displays related articles in a horizontal scrollable list
class RelatedArticlesWidget extends StatelessWidget {
  const RelatedArticlesWidget({
    super.key,
    required this.currentArticle,
    this.limit = 5,
  });

  final ArticleModel currentArticle;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final relatedArticlesService = RelatedArticlesService.instance;
    final relatedArticles = relatedArticlesService.getRelatedArticles(
      currentArticle,
      limit: limit,
    );

    if (relatedArticles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: KAppColors.getBackground(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 24,
                  color: KAppColors.getPrimary(context),
                ),
                const SizedBox(width: 12),
                Text(
                  'You might also like',
                  style: KAppTextStyles.titleLarge.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal scrollable list
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: relatedArticles.length,
              itemBuilder: (context, index) {
                final article = relatedArticles[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < relatedArticles.length - 1 ? 16 : 0,
                  ),
                  child: RelatedArticleCard(article: article),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Individual card for a related article
class RelatedArticleCard extends StatelessWidget {
  const RelatedArticleCard({
    super.key,
    required this.article,
  });

  final ArticleModel article;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await ArticleAccessService.instance.navigateToArticle(context, article);
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: KAppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  article.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      KAppColors.getPrimary(context).withValues(alpha: 0.3),
                      KAppColors.getPrimary(context).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Icon(
                  Icons.article_outlined,
                  size: 48,
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.5),
                ),
              ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    if (article.category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.category.first.toUpperCase(),
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: KAppColors.getPrimary(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Title
                    Expanded(
                      child: Text(
                        article.title,
                        style: KAppTextStyles.titleSmall.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Meta info (source + reading time)
                    Row(
                      children: [
                        // Source
                        Expanded(
                          child: Text(
                            article.sourceName,
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reading time
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 12,
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alternative compact list view for related articles
class RelatedArticlesListWidget extends StatelessWidget {
  const RelatedArticlesListWidget({
    super.key,
    required this.currentArticle,
    this.limit = 3,
  });

  final ArticleModel currentArticle;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final relatedArticlesService = RelatedArticlesService.instance;
    final relatedArticles = relatedArticlesService.getRelatedArticles(
      currentArticle,
      limit: limit,
    );

    if (relatedArticles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: KAppColors.getBackground(context),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 20,
                color: KAppColors.getPrimary(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Related Articles',
                style: KAppTextStyles.titleMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List items
          ...relatedArticles.map((article) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompactArticleItem(article: article),
              )),
        ],
      ),
    );
  }
}

class _CompactArticleItem extends StatelessWidget {
  const _CompactArticleItem({required this.article});

  final ArticleModel article;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await ArticleAccessService.instance.navigateToArticle(context, article);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: KAppColors.getSurface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  article.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.article_outlined,
                        size: 24,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(width: 12),

            // Content
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        article.sourceName,
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ReadingTimeCalculator.calculateReadingTime(article.content),
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          fontSize: 11,
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
    );
  }
}
