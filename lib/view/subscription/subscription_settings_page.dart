import 'package:flutter/material.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/constant/enhanced_typography.dart';
import 'package:the_news/model/subscription_model.dart';
import 'package:the_news/service/subscription_service.dart';
import 'package:the_news/view/subscription/subscription_paywall_page.dart';
import 'package:the_news/view/subscription/payment_history_page.dart';
import 'package:the_news/view/subscription/payment_methods_page.dart';
import 'package:the_news/utils/haptic_service.dart';
import 'package:intl/intl.dart';
import 'package:the_news/view/widgets/app_back_button.dart';

class SubscriptionSettingsPage extends StatefulWidget {
  const SubscriptionSettingsPage({super.key});

  @override
  State<SubscriptionSettingsPage> createState() => _SubscriptionSettingsPageState();
}

class _SubscriptionSettingsPageState extends State<SubscriptionSettingsPage> {
  final _subscriptionService = SubscriptionService.instance;
  UserSubscription? _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() => _isLoading = true);
    final subscription = await _subscriptionService.getCurrentSubscription();
    if (mounted) {
      setState(() {
        _subscription = subscription;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: KAppBar(
        title: Text(
          'Subscription',
          style: EnhancedTypography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(
          onTap: () {
            HapticService.light();
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSubscription,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCurrentPlanCard(context),
                    const SizedBox(height: Spacing.md),
                    if (_subscription?.isPremium != true)
                      _buildUsageCard(context),
                    const SizedBox(height: Spacing.md),
                    if (_subscription?.status == SubscriptionStatus.trial)
                      _buildTrialCard(context),
                    if (_subscription?.planId == 'free')
                      _buildUpgradeCard(context),
                    if (_subscription?.isPremium == true &&
                        _subscription?.status == SubscriptionStatus.active)
                      _buildManagementSection(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlanCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final plan = _subscriptionService.currentPlan;
    final isPremium = _subscription?.isPremium == true;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: isPremium
            ? colorScheme.primary.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isPremium
              ? colorScheme.primary.withValues(alpha: 0.35)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPremium
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Icon(
                  isPremium ? Icons.workspace_premium : Icons.person_outline,
                  color: isPremium ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: 26,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: EnhancedTypography.headlineSmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium ? 'Premium membership' : 'Free membership',
                      style: EnhancedTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(context),
            ],
          ),

          const SizedBox(height: Spacing.md),

          if (_subscription?.subscriptionEndDate != null) ...[
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Renews on ${DateFormat.yMMMd().format(_subscription!.subscriptionEndDate!)}',
                  style: EnhancedTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final color = _getStatusColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _getStatusText(),
        style: EnhancedTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUsageCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = _subscriptionService.remainingArticles;
    final limit = 10;
    final used = (limit - remaining).clamp(0, limit);
    final progress = limit > 0 ? used / limit : 0.0;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily article limit',
            style: EnhancedTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '$remaining of $limit remaining today',
            style: EnhancedTypography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: AppRadius.radiusSm,
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final daysRemaining = _subscriptionService.trialDaysRemaining ?? 0;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: colorScheme.tertiary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'Free Trial Active',
                style: EnhancedTypography.titleMedium.copyWith(
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            '$daysRemaining days remaining',
            style: EnhancedTypography.bodyMedium.copyWith(
              color: colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Subscribe now to continue premium access after your trial ends.',
            style: EnhancedTypography.bodySmall.copyWith(
              color: colorScheme.onTertiaryContainer.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticService.medium();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPaywallPage(
                      showCloseButton: true,
                    ),
                  ),
                ).then((_) => _loadSubscription());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusMd,
                ),
              ),
              child: const Text('Subscribe Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'Upgrade to Premium',
                style: EnhancedTypography.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Unlimited articles, advanced wellness features, and more.',
            style: EnhancedTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticService.medium();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionPaywallPage(),
                      ),
                    ).then((_) => _loadSubscription());
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
                    _subscriptionService.hasUsedTrial
                        ? 'See Plans'
                        : 'Start Free Trial',
                    style: EnhancedTypography.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Manage Subscription',
          style: EnhancedTypography.titleMedium.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.radiusLg,
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildManageTile(
                context,
                icon: Icons.payment,
                title: 'Payment Methods',
                subtitle: 'Manage your saved payment methods',
                onTap: () {
                  HapticService.light();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodsPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildManageTile(
                context,
                icon: Icons.receipt_long,
                title: 'Billing History',
                subtitle: 'View invoices and receipts',
                onTap: () {
                  HapticService.light();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentHistoryPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildManageTile(
                context,
                icon: Icons.cancel,
                title: 'Cancel Subscription',
                subtitle: 'You’ll keep access until period ends',
                danger: true,
                onTap: () {
                  HapticService.light();
                  _showCancelDialog(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManageTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = danger ? colorScheme.error : colorScheme.onSurfaceVariant;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: danger
              ? colorScheme.error.withValues(alpha: 0.12)
              : colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: AppRadius.radiusSm,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: EnhancedTypography.titleSmall.copyWith(
          color: danger ? colorScheme.error : colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: EnhancedTypography.bodySmall.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: color,
      ),
      onTap: onTap,
    );
  }

  String _getStatusText() {
    switch (_subscription?.status) {
      case SubscriptionStatus.trial:
        return 'Free Trial';
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.inactive:
      default:
        return 'Free Plan';
    }
  }

  Color _getStatusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (_subscription?.status) {
      case SubscriptionStatus.trial:
        return colorScheme.tertiary;
      case SubscriptionStatus.active:
        return colorScheme.primary;
      case SubscriptionStatus.expired:
      case SubscriptionStatus.cancelled:
        return colorScheme.error;
      case SubscriptionStatus.inactive:
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'You will continue to have premium access until the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () async {
              await _subscriptionService.cancelSubscription();
              if (context.mounted) {
                Navigator.pop(context);
                _loadSubscription();
                HapticService.success();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
