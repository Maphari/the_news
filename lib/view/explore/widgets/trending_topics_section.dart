import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/service/news_provider_service.dart';

class TrendingTopicsSection extends StatelessWidget {
  const TrendingTopicsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final newsProvider = NewsProviderService.instance;
    final trendingTopics = newsProvider.getTrendingTopics(limit: 5);

    if (trendingTopics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: KDesignConstants.paddingHorizontalLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: KAppColors.orange, size: 24),
              const SizedBox(width: KDesignConstants.spacing8),
              Text(
                'Trending Topics',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Text(
            'What people are talking about',
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing16),
          Wrap(
            spacing: KDesignConstants.spacing8,
            runSpacing: KDesignConstants.spacing8,
            children: trendingTopics.map((topic) {
              return Chip(
                label: Text(topic),
                backgroundColor:
                    KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                labelStyle: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(context),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
