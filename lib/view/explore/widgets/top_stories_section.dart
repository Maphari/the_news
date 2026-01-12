import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/service/disliked_articles_service.dart';

class TopStoriesSection extends StatelessWidget {
  const TopStoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final newsProvider = NewsProviderService.instance;
    final dislikedArticles = DislikedArticlesService.instance;
    final topStories = newsProvider.getTrendingArticles(limit: 3)
        .where((article) => !dislikedArticles.isArticleDisliked(article.articleId))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD4A3).withValues(alpha: 0.3),
                      KAppColors.primary.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: const Color(0xFFFFD4A3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Top Stories',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topStories.asMap().entries.map((entry) {
            final index = entry.key;
            final story = entry.value;
            return _TopStoryCard(
              article: story,
              rank: index + 1,
              onTap: () {
                AppRoutes.navigateTo(
                  context,
                  AppRoutes.articleDetail,
                  arguments: story,
                );
              },
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TopStoryCard extends StatelessWidget {
  const _TopStoryCard({
    required this.article,
    required this.rank,
    required this.onTap,
  });

  final ArticleModel article;
  final int rank;
  final VoidCallback onTap;

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD4A3);
      case 2:
        return KAppColors.primary;
      case 3:
        return KAppColors.tertiary;
      default:
        return KAppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(rank);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              rankColor.withValues(alpha: 0.08),
              rankColor.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: rankColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    rankColor.withValues(alpha: 0.3),
                    rankColor.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: rankColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: rankColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: KAppTextStyles.titleMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
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
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTimeAgo(article.pubDate),
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
            // Thumbnail
            if (article.imageUrl != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: rankColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    article.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              rankColor.withValues(alpha: 0.1),
                              rankColor.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.article_outlined,
                          color: rankColor.withValues(alpha: 0.4),
                          size: 28,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
