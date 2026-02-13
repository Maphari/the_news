import 'package:flutter/material.dart';
import 'package:the_news/constant/enhanced_typography.dart';
import 'package:the_news/service/subscription_service.dart';
import 'package:the_news/view/subscription/subscription_paywall_page.dart';
import 'package:the_news/utils/haptic_service.dart';

class ArticleLimitDialog extends StatelessWidget {
  const ArticleLimitDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ArticleLimitDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subscriptionService = SubscriptionService.instance;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
      ),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 48,
                color: colorScheme.error,
              ),
            ),

            const SizedBox(height: Spacing.md),

            // Title
            Text(
              'Daily Limit Reached',
              style: EnhancedTypography.headlineMedium.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: Spacing.sm),

            // Message
            Text(
              'You\'ve read all 10 articles available today on the free plan.',
              style: EnhancedTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: Spacing.lg),

            // Premium features
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: AppRadius.radiusMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Benefits:',
                    style: EnhancedTypography.titleSmall.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  _buildBenefit(
                    context,
                    Icons.check_circle,
                    'Unlimited articles daily',
                  ),
                  _buildBenefit(
                    context,
                    Icons.check_circle,
                    'Advanced wellness features',
                  ),
                  _buildBenefit(
                    context,
                    Icons.check_circle,
                    'Offline reading',
                  ),
                  _buildBenefit(
                    context,
                    Icons.check_circle,
                    '7-day free trial',
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.lg),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      HapticService.light();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Spacing.md,
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: EnhancedTypography.labelLarge.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticService.medium();
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionPaywallPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: Spacing.md,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusMd,
                      ),
                    ),
                    child: Text(
                      subscriptionService.hasUsedTrial
                          ? 'Go Premium'
                          : 'Start Free Trial',
                      style: EnhancedTypography.labelLarge.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              text,
              style: EnhancedTypography.bodySmall.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
