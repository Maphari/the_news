import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/clickbait_detector_service.dart';
import 'package:the_news/service/solution_detector_service.dart';
import 'package:the_news/routes/app_routes.dart';

class CompactArticleItem extends StatelessWidget {
  const CompactArticleItem({
    super.key,
    required this.article,
  });

  final ArticleModel article;

  void _navigateToArticleDetail(BuildContext context) {
    AppRoutes.navigateTo(
      context,
      AppRoutes.articleDetail,
      arguments: article,
    );
  }

  String _getTimeAgo(DateTime publishDate) {
    final now = DateTime.now();
    final difference = now.difference(publishDate);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  int _estimateReadTime(String content) {
    final wordCount = content.split(' ').length;
    final minutes = (wordCount / 225).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  Color _getCredibilityColor(int sourcePriority) {
    if (sourcePriority >= 800000) {
      return const Color(0xFF4CAF50);
    } else if (sourcePriority >= 500000) {
      return const Color(0xFFFFA726);
    } else {
      return const Color(0xFFEF5350);
    }
  }

  String _getCredibilityLabel(int sourcePriority) {
    if (sourcePriority >= 800000) {
      return 'High';
    } else if (sourcePriority >= 500000) {
      return 'Med';
    } else {
      return 'Low';
    }
  }

  Color _getCategoryColor() {
    final category = article.category.toString().toLowerCase();
    switch (category) {
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

  Widget _buildCredibilityIndicator() {
    final color = _getCredibilityColor(article.sourcePriority);
    final label = _getCredibilityLabel(article.sourcePriority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: KAppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentBadge() {
    if (article.sentiment.toLowerCase() == 'positive' &&
        article.sentimentStats.positive >= 0.6) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wb_sunny_outlined,
              size: 9,
              color: Color(0xFF4CAF50),
            ),
            const SizedBox(width: 3),
            Text(
              'GOOD',
              style: KAppTextStyles.labelSmall.copyWith(
                color: const Color(0xFF4CAF50),
                fontWeight: FontWeight.w700,
                fontSize: 8,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSolutionBadge() {
    final solutionDetector = SolutionDetectorService.instance;
    final badgeType = solutionDetector.getSolutionBadgeType(article);

    if (badgeType == null) {
      return const SizedBox.shrink();
    }

    final label = solutionDetector.getBadgeLabel(badgeType);
    final icon = solutionDetector.getBadgeIcon(badgeType);
    const color = Color(0xFF4CAF50); // Green for solution-focused

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 9),
          ),
          const SizedBox(width: 3),
          Text(
            label.toUpperCase(),
            style: KAppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 8,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClickbaitWarning() {
    final detector = ClickbaitDetectorService.instance;
    if (!detector.isClickbait(article.title)) {
      return const SizedBox.shrink();
    }

    final score = detector.getClickbaitScore(article.title);
    String label;
    Color color;

    if (score >= 70) {
      label = 'CLICK';
      color = const Color(0xFFEF5350);
    } else {
      label = 'SENS';
      color = const Color(0xFFFFA726);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 9,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: KAppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayTitle() {
    final detector = ClickbaitDetectorService.instance;
    return detector.getNeutralTitle(article.title, article.description);
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(article.pubDate);
    final readTime = _estimateReadTime(article.content);
    final categoryColor = _getCategoryColor();

    return InkWell(
      onTap: () => _navigateToArticleDetail(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withValues(alpha: 0.08),
              categoryColor.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article thumbnail
            if (article.imageUrl != null)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.2),
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
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              categoryColor.withValues(alpha: 0.1),
                              categoryColor.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.article_outlined,
                          color: categoryColor.withValues(alpha: 0.4),
                          size: 28,
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(width: 12),

            // Article content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row with Wrap to prevent overflow
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      // Category badge
                      if (article.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: categoryColor.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            article.category.first.toUpperCase(),
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: categoryColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      _buildCredibilityIndicator(),
                      _buildSentimentBadge(),
                      _buildSolutionBadge(),
                      _buildClickbaitWarning(),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title (rewritten if clickbait)
                  Text(
                    _getDisplayTitle(),
                    style: KAppTextStyles.titleMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    article.description,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      height: 1.3,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Bottom metadata row
                  Row(
                    children: [
                      // Source name
                      Flexible(
                        child: Text(
                          article.sourceName,
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Time ago
                      Text(
                        timeAgo,
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '•',
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 3),
                      // Read time
                      Icon(
                        Icons.schedule_outlined,
                        size: 10,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${readTime}m',
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          fontSize: 10,
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
