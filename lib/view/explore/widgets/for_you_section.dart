import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/service/disliked_articles_service.dart';

class ForYouSection extends StatelessWidget {
  const ForYouSection({super.key});

  @override
  Widget build(BuildContext context) {
    final newsProvider = NewsProviderService.instance;
    final dislikedArticles = DislikedArticlesService.instance;
    final forYouArticles = newsProvider.getRecentArticles(limit: 4)
        .where((article) => !dislikedArticles.isArticleDisliked(article.articleId))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.purple.shade300, size: 24),
              const SizedBox(width: 8),
              Text(
                'For You',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your reading history',
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          ...forYouArticles.map((article) => _ForYouCard(
                article: article,
                onTap: () {
                  AppRoutes.navigateTo(
                    context,
                    AppRoutes.articleDetail,
                    arguments: article,
                  );
                },
              )),
        ],
      ),
    );
  }
}

class _ForYouCard extends StatelessWidget {
  const _ForYouCard({
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      article.imageUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                          child: Center(
                            child: Icon(Icons.image, size: 48, color: KAppColors.getOnBackground(context).withValues(alpha: 0.54)),
                          ),
                        );
                      },
                    ),
                    // Category badge
                    if (article.category.isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            article.category.first.toUpperCase(),
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: KAppColors.getOnBackground(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    article.description,
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue.shade300,
                        child: const Icon(Icons.person, size: 12, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        article.sourceName,
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time, size: 14, color: KAppColors.getOnBackground(context).withValues(alpha: 0.54)),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeAgo(article.pubDate),
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.54),
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}