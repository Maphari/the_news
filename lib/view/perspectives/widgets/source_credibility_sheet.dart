import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/story_cluster_model.dart';
import 'package:the_news/view/perspectives/widgets/bias_indicator_widget.dart';

/// Bottom sheet showing detailed source credibility information
class SourceCredibilitySheet extends StatelessWidget {
  const SourceCredibilitySheet({
    super.key,
    required this.credibility,
  });

  final SourceCredibility credibility;

  static void show(BuildContext context, SourceCredibility credibility) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SourceCredibilitySheet(credibility: credibility),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KAppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding:KDesignConstants.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing24),

          // Source name
          Text(
            credibility.sourceName,
            style: KAppTextStyles.headlineSmall.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing16),

          // Credibility score
          _buildCredibilityScore(context),
          const SizedBox(height: KDesignConstants.spacing24),

          // Bias indicator
          Row(
            children: [
              Text(
                'Political Bias:',
                style: KAppTextStyles.labelMedium.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              BiasIndicatorWidget(bias: credibility.bias),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Text(
            credibility.bias.description,
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing24),

          // Description
          Container(
            padding: KDesignConstants.paddingMd,
            decoration: BoxDecoration(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
              borderRadius: KBorderRadius.md,
            ),
            child: Text(
              credibility.credibilityDescription,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context),
              ),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing24),

          // Strengths
          if (credibility.strengths.isNotEmpty) ...[
            _buildSection(
              context,
              'Strengths',
              Icons.check_circle,
              credibility.strengths,
              KAppColors.success,
            ),
            const SizedBox(height: KDesignConstants.spacing16),
          ],

          // Weaknesses
          if (credibility.weaknesses.isNotEmpty) ...[
            _buildSection(
              context,
              'Weaknesses',
              Icons.warning,
              credibility.weaknesses,
              KAppColors.warning,
            ),
            const SizedBox(height: KDesignConstants.spacing16),
          ],

          // Note
          Container(
            padding: KDesignConstants.paddingSm,
            decoration: BoxDecoration(
              color: KAppColors.getPrimary(context).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: KAppColors.getPrimary(context),
                ),
                const SizedBox(width: KDesignConstants.spacing8),
                Expanded(
                  child: Text(
                    'Ratings are based on journalistic standards, fact-checking, and historical accuracy',
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing24),
        ],
      ),
    );
  }

  Widget _buildCredibilityScore(BuildContext context) {
    final percentage = (credibility.credibilityScore * 100).toInt();
    final color = _getCredibilityColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Credibility Score',
              style: KAppTextStyles.labelMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              credibility.credibilityRating,
              style: KAppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: KDesignConstants.spacing12),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: credibility.credibilityScore,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: KDesignConstants.spacing8),
        Text(
          '$percentage% credibility',
          style: KAppTextStyles.bodySmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Color _getCredibilityColor() {
    if (credibility.credibilityScore >= 0.8) return KAppColors.success;
    if (credibility.credibilityScore >= 0.6) return KAppColors.info;
    if (credibility.credibilityScore >= 0.4) return KAppColors.warning;
    return KAppColors.error;
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<String> items,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(width: KDesignConstants.spacing8),
            Text(
              title,
              style: KAppTextStyles.labelMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: KDesignConstants.spacing8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: Text(
                  item,
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
