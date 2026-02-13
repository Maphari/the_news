import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/enhanced_typography.dart';
import 'package:the_news/service/premium_features_service.dart';
import 'package:the_news/view/subscription/subscription_paywall_page.dart';

/// Shows a premium upgrade prompt dialog
class PremiumUpgradeDialog {
  /// Show upgrade dialog for a specific feature
  static Future<bool> show(
    BuildContext context, {
    required String featureName,
    String? customTitle,
    String? customMessage,
  }) async {
    final premiumService = PremiumFeaturesService.instance;
    final colorScheme = Theme.of(context).colorScheme;

    final shouldUpgrade = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.star,
          size: 48,
          color: colorScheme.primary,
        ),
        title: Text(
          customTitle ?? 'Premium Feature',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              customMessage ??
                  premiumService.getUpgradePromptMessage(featureName),
              textAlign: TextAlign.center,
              style: EnhancedTypography.bodyLarge,
            ),
            const SizedBox(height: Spacing.md),
            _buildLimitInfo(featureName, premiumService, colorScheme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );

    if (shouldUpgrade == true && context.mounted) {
      // Navigate to subscription page
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SubscriptionPaywallPage(),
        ),
      );
      return true;
    }

    return false;
  }

  static Widget _buildLimitInfo(
    String featureName,
    PremiumFeaturesService service,
    ColorScheme colorScheme,
  ) {
    final limitMessage = service.getFeatureLimitMessage(featureName);
    if (limitMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: KBorderRadius.md,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              limitMessage,
              style: EnhancedTypography.bodySmall.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a bottom sheet with premium features overview
  static Future<void> showFeaturesSheet(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: Spacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        'Unlock Premium Features',
                        style: EnhancedTypography.headlineSmall.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Features list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  children: [
                    _buildFeatureCard(
                      context,
                      Icons.psychology_outlined,
                      'Unlimited AI Features',
                      'Generate unlimited summaries, translations, and key points with advanced AI models',
                      colorScheme,
                    ),
                    _buildFeatureCard(
                      context,
                      Icons.block_outlined,
                      'Ad-Free Experience',
                      'Enjoy reading without any interruptions or advertisements',
                      colorScheme,
                    ),
                    _buildFeatureCard(
                      context,
                      Icons.offline_bolt_outlined,
                      'Offline Downloads',
                      'Download articles with full content for reading offline',
                      colorScheme,
                    ),
                    _buildFeatureCard(
                      context,
                      Icons.bookmark_border,
                      'Unlimited Bookmarks',
                      'Save as many articles as you want without limits',
                      colorScheme,
                    ),
                    _buildFeatureCard(
                      context,
                      Icons.assessment_outlined,
                      'Advanced Analytics',
                      'Track your reading habits with detailed insights and statistics',
                      colorScheme,
                    ),
                    _buildFeatureCard(
                      context,
                      Icons.newspaper_outlined,
                      'Custom Digests',
                      'Create unlimited personalized news digests tailored to your interests',
                      colorScheme,
                    ),
                    const SizedBox(height: Spacing.lg),
                  ],
                ),
              ),

              // Upgrade button
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SubscriptionPaywallPage(),
                        ),
                      );
                    },
                    child: const Text('Upgrade to Premium'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: KBorderRadius.md,
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EnhancedTypography.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing4),
                  Text(
                    description,
                    style: EnhancedTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show a simple snackbar for premium features
  static void showSnackBar(
    BuildContext context,
    String featureName,
  ) {
    final premiumService = PremiumFeaturesService.instance;
    final message = premiumService.getUpgradePromptMessage(featureName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Upgrade',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionPaywallPage(),
              ),
            );
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
