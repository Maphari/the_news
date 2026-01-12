import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/story_cluster_model.dart';
import 'package:the_news/view/perspectives/perspective_comparison_page.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Card displaying a story cluster with multiple perspectives
class StoryClusterCard extends StatelessWidget {
  const StoryClusterCard({
    super.key,
    required this.cluster,
  });

  final StoryCluster cluster;

  @override
  Widget build(BuildContext context) {
    final articlesByBias = cluster.getArticlesByBias();
    final diversityScore = cluster.getDiversityScore();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PerspectiveComparisonPage(cluster: cluster),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: KAppColors.getBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category and diversity score
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cluster.category.label,
                      style: KAppTextStyles.labelSmall.copyWith(
                        color: KAppColors.getPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Diversity indicator
                  _buildDiversityIndicator(context, diversityScore),
                ],
              ),
            ),

            // Story content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Story title
                  Text(
                    cluster.storyTitle,
                    style: KAppTextStyles.titleLarge.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Story description
                  Text(
                    cluster.storyDescription,
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Metadata row
                  Row(
                    children: [
                      // Article count
                      Icon(
                        Icons.article_outlined,
                        size: 16,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${cluster.articleCount} articles',
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Last updated
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeago.format(cluster.lastUpdated),
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bias distribution
                  _buildBiasDistribution(context, articlesByBias),
                ],
              ),
            ),

            // View button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Compare perspectives',
                    style: KAppTextStyles.labelMedium.copyWith(
                      color: KAppColors.getPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: KAppColors.getPrimary(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiversityIndicator(BuildContext context, double score) {
    final percentage = (score * 100).toInt();
    final color = _getDiversityColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bubble_chart,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage% diverse',
            style: KAppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDiversityColor(double score) {
    if (score >= 0.7) return const Color(0xFF4CAF50); // Green - high diversity
    if (score >= 0.4) return const Color(0xFFFF9800); // Orange - medium diversity
    return const Color(0xFFE91E63); // Pink - low diversity
  }

  Widget _buildBiasDistribution(
    BuildContext context,
    Map<BiasIndicator, List<dynamic>> articlesByBias,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perspectives:',
          style: KAppTextStyles.labelMedium.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: articlesByBias.entries.map((entry) {
            final bias = entry.key;
            final count = entry.value.length;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Color(bias.colorValue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(bias.colorValue).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(bias.colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${bias.label} ($count)',
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
