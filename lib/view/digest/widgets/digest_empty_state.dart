import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

/// Empty state widget for digest page
class DigestEmptyState extends StatelessWidget {
  const DigestEmptyState({
    super.key,
    required this.onGenerate,
  });

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: KDesignConstants.paddingLg,
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 64,
                color: KAppColors.getPrimary(context),
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing24),
            Text(
              'No Digests Yet',
              style: KAppTextStyles.headlineSmall.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            Text(
              'Get your personalized AI-powered news digest in just a few minutes.',
              textAlign: TextAlign.center,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing32),
            _buildFeatureList(context),
            const SizedBox(height: KDesignConstants.spacing32),
            ElevatedButton.icon(
              onPressed: onGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: KAppColors.getPrimary(context),
                foregroundColor: KAppColors.darkOnBackground,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: KBorderRadius.md,
                ),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'Generate My First Digest',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final features = [
      {'icon': Icons.speed, 'text': '5-minute personalized briefing'},
      {'icon': Icons.star_outline, 'text': 'Top stories from your interests'},
      {'icon': Icons.insights, 'text': 'AI-powered summaries'},
      {'icon': Icons.schedule, 'text': 'Stay informed, save time'},
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                feature['icon'] as IconData,
                color: KAppColors.getPrimary(context),
                size: 20,
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: Text(
                  feature['text'] as String,
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
