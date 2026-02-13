import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/clickbait_detector_service.dart';
import 'package:the_news/service/solution_detector_service.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

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
      return KAppColors.success;
    } else if (sourcePriority >= 500000) {
      return KAppColors.warning;
    } else {
      return KAppColors.error;
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

  Color _getCategoryColor({required BuildContext context}) {
    final category = article.category.toString().toLowerCase();
    switch (category) {
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
          color: KAppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: KAppColors.success.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wb_sunny_outlined,
              size: 9,
              color: KAppColors.success,
            ),
            const SizedBox(width: 3),
            Text(
              'GOOD',
              style: KAppTextStyles.labelSmall.copyWith(
                color: KAppColors.success,
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
    const color = KAppColors.success;

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
      color = KAppColors.error;
    } else {
      label = 'SENS';
      color = KAppColors.warning;
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
    final categoryColor = _getCategoryColor(context: context);

    return InkWell(
      onTap: () => _navigateToArticleDetail(context),
      borderRadius: KBorderRadius.lg,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: KDesignConstants.paddingSm,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withValues(alpha: 0.08),
              categoryColor.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: KBorderRadius.lg,
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
                  borderRadius: KBorderRadius.md,
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: KBorderRadius.md,
                  child: SafeNetworkImage(
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
            const SizedBox(width: KDesignConstants.spacing12),

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
                  const SizedBox(height: KDesignConstants.spacing4),

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
