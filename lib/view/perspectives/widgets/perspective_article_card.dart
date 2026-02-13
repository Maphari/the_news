import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/story_cluster_model.dart';
import 'package:the_news/view/perspectives/widgets/source_credibility_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:the_news/view/widgets/safe_network_image.dart';

/// Card displaying an article in perspective comparison view
class PerspectiveArticleCard extends StatelessWidget {
  const PerspectiveArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  final ArticleModel article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final credibility = SourceCredibility.getForSource(article.sourceName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: KAppColors.getBackground(context),
          borderRadius: KBorderRadius.md,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if available
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: SafeNetworkImage(
                  article.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ],

            // Content
            Padding(
              padding: KDesignConstants.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source info
                  Row(
                    children: [
                      if (article.sourceIcon.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SafeNetworkImage(
                            article.sourceIcon,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: KDesignConstants.spacing8),
                      ],
                      Expanded(
                        child: Text(
                          article.sourceName,
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: KAppColors.getPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildCredibilityBadge(context, credibility),
                    ],
                  ),
                  const SizedBox(height: KDesignConstants.spacing12),

                  // Title
                  Text(
                    article.title,
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KDesignConstants.spacing8),

                  // Description
                  Text(
                    article.description,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KDesignConstants.spacing12),

                  // Metadata
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: KDesignConstants.spacing4),
                      Text(
                        timeago.format(article.pubDate),
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: KDesignConstants.spacing12),
                      _buildSentimentIndicator(context, article.sentiment),
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

  Widget _buildCredibilityBadge(BuildContext context, SourceCredibility credibility) {
    final color = _getCredibilityColor(credibility.credibilityScore);

    return GestureDetector(
      onTap: () {
        SourceCredibilitySheet.show(context, credibility);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCredibilityIcon(credibility.credibilityScore),
              size: 12,
              color: color,
            ),
            const SizedBox(width: KDesignConstants.spacing4),
            Text(
              credibility.credibilityRating,
              style: KAppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCredibilityColor(double score) {
    if (score >= 0.8) return KAppColors.success;
    if (score >= 0.6) return KAppColors.info;
    if (score >= 0.4) return KAppColors.warning;
    return KAppColors.error;
  }

  IconData _getCredibilityIcon(double score) {
    if (score >= 0.8) return Icons.verified;
    if (score >= 0.6) return Icons.check_circle;
    if (score >= 0.4) return Icons.info;
    return Icons.warning;
  }

  Widget _buildSentimentIndicator(BuildContext context, String sentiment) {
    IconData icon;
    Color color;

    switch (sentiment.toLowerCase()) {
      case 'positive':
        icon = Icons.sentiment_satisfied;
        color = KAppColors.success;
        break;
      case 'negative':
        icon = Icons.sentiment_dissatisfied;
        color = KAppColors.error;
        break;
      default:
        icon = Icons.sentiment_neutral;
        color = KAppColors.getOnBackground(context).withValues(alpha: 0.5);
    }

    return Tooltip(
      message: 'Sentiment: $sentiment',
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }
}
