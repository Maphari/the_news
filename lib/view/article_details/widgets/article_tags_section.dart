import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class ArticleTagsSection extends StatelessWidget {
  const ArticleTagsSection({
    super.key,
    required this.keywords,
    required this.aiTags,
    required this.aiRegion,
  });

  final List<String> keywords;
  final List<String> aiTags;
  final List<String> aiRegion;

  @override
  Widget build(BuildContext context) {
    final hasKeywords = keywords.isNotEmpty;
    final hasAiTags = aiTags.isNotEmpty;
    final hasRegion = aiRegion.isNotEmpty;

    if (!hasKeywords && !hasAiTags && !hasRegion) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasKeywords) ...[
          Text(
            'Keywords',
            style: KAppTextStyles.titleMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keywords.map((keyword) {
              return _buildTag(keyword, KAppColors.info, context);
            }).toList(),
          ),
          const SizedBox(height: KDesignConstants.spacing24),
        ],
        if (hasAiTags) ...[
          Row(
            children: [
              Icon(Icons.auto_awesome, color: KAppColors.purple, size: 18),
              const SizedBox(width: KDesignConstants.spacing8),
              Text(
                'AI Tags',
                style: KAppTextStyles.titleMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: aiTags.map((tag) {
              return _buildTag(tag, KAppColors.purple, context, hasAI: true);
            }).toList(),
          ),
          const SizedBox(height: KDesignConstants.spacing24),
        ],
        if (hasRegion) ...[
          Row(
            children: [
              Icon(Icons.location_on, color: KAppColors.warning, size: 18),
              const SizedBox(width: KDesignConstants.spacing8),
              Text(
                'Regions',
                style: KAppTextStyles.titleMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: aiRegion.map((region) {
              return _buildTag(region, KAppColors.warning, context);
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTag(String text, Color color, BuildContext context, {bool hasAI = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: KBorderRadius.xl,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasAI) ...[
            Icon(Icons.auto_awesome, size: 12, color: color),
            const SizedBox(width: KDesignConstants.spacing4),
          ],
          Flexible(
            child: Text(
              text,
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
