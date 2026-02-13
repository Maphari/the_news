import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/enriched_article_model.dart';
import 'package:the_news/service/subscription_service.dart';
import 'package:the_news/view/subscription/subscription_paywall_page.dart';
import 'package:the_news/utils/haptic_service.dart';

class AISummarySection extends StatelessWidget {
  const AISummarySection({
    super.key,
    required this.enrichedArticle,
    this.isLoading = false,
  });

  final EnrichedArticle? enrichedArticle;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final subscriptionService = SubscriptionService.instance;
    final hasPremiumAccess = subscriptionService.canAccessPremiumFeatures;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context).withValues(alpha: 0.08),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                  borderRadius: KBorderRadius.md,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: KAppColors.getPrimary(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: Text(
                  'AI Summary',
                  style: KAppTextStyles.titleLarge.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!hasPremiumAccess)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KAppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: KAppColors.warning.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 14,
                        color: KAppColors.warning,
                      ),
                      const SizedBox(width: KDesignConstants.spacing4),
                      Text(
                        'Premium',
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing16),

          // Content
          if (!hasPremiumAccess)
            _buildLockedContent(context)
          else if (isLoading)
            _buildLoadingContent(context)
          else if (enrichedArticle == null || !enrichedArticle!.success)
            _buildErrorContent(context)
          else if (enrichedArticle!.aiSummary != null)
            _buildSummaryContent(context)
          else
            _buildNoSummaryContent(context),
        ],
      ),
    );
  }

  Widget _buildLockedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show preview/teaser benefits
        Text(
          'Unlock AI-powered features:',
          style: KAppTextStyles.bodyMedium.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: KDesignConstants.spacing12),
        _buildBenefitItem(
          context,
          Icons.auto_awesome,
          'Instant article summaries',
        ),
        _buildBenefitItem(
          context,
          Icons.lightbulb_outline,
          'Key insights extraction',
        ),
        _buildBenefitItem(
          context,
          Icons.speed,
          'Save 80% reading time',
        ),
        const SizedBox(height: KDesignConstants.spacing16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticService.medium();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPaywallPage(),
                ),
              );
            },
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Try Premium Free'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KAppColors.getPrimary(context),
              foregroundColor: KAppColors.getOnPrimary(context),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: KBorderRadius.md,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: KAppColors.getPrimary(context),
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: Text(
              text,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: KDesignConstants.spacing12),
        Text(
          'Generating AI summary...',
          style: KAppTextStyles.bodyMedium.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.error.withValues(alpha: 0.1),
        borderRadius: KBorderRadius.md,
        border: Border.all(
          color: KAppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: KAppColors.error,
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: Text(
              'Failed to generate summary. Please try again later.',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(BuildContext context) {
    final summary = enrichedArticle!.aiSummary!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main summary
        if (summary.summary.isNotEmpty) ...[
          Text(
            summary.summary,
            style: KAppTextStyles.bodyLarge.copyWith(
              color: KAppColors.getOnBackground(context),
              height: 1.6,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing16),
        ],

        // Key points
        if (summary.keyPoints.isNotEmpty) ...[
          Text(
            'Key Points:',
            style: KAppTextStyles.titleMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          ...summary.keyPoints.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: KAppColors.getPrimary(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: KDesignConstants.spacing12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildNoSummaryContent(BuildContext context) {
    return Text(
      'No AI summary available for this article.',
      style: KAppTextStyles.bodyMedium.copyWith(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
      ),
    );
  }
}
