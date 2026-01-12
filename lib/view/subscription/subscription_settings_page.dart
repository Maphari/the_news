import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/enhanced_typography.dart';
import 'package:the_news/model/subscription_model.dart';
import 'package:the_news/service/subscription_service.dart';
import 'package:the_news/view/subscription/subscription_paywall_page.dart';
import 'package:the_news/view/subscription/payment_history_page.dart';
import 'package:the_news/view/subscription/payment_methods_page.dart';
import 'package:the_news/utils/haptic_service.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            HapticService.light();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Subscription',
          style: EnhancedTypography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSubscription,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCurrentPlanCard(context),
                    const SizedBox(height: Spacing.lg),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPremium
              ? [colorScheme.primaryContainer, colorScheme.primary]
              : [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainerHigh],
        ),
        borderRadius: AppRadius.radiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.workspace_premium : Icons.person_outline,
                color: isPremium ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                plan.name,
                style: EnhancedTypography.headlineMedium.copyWith(
                  color: isPremium ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(context).withAlpha(50),
              borderRadius: AppRadius.radiusSm,
            ),
            child: Text(
              _getStatusText(),
              style: EnhancedTypography.labelSmall.copyWith(
                color: _getStatusColor(context),
              ),
            ),
          ),

          if (!isPremium) ...[
            const SizedBox(height: Spacing.md),
            Text(
              '${_subscriptionService.remainingArticles} articles remaining today',
              style: EnhancedTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          if (_subscription?.subscriptionEndDate != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              'Renews on ${DateFormat.yMMMd().format(_subscription!.subscriptionEndDate!)}',
              style: EnhancedTypography.bodySmall.copyWith(
                color: isPremium
                  ? colorScheme.onPrimary.withValues(alpha: 0.95)
                  : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrialCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final daysRemaining = _subscriptionService.trialDaysRemaining ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: colorScheme.tertiary,
          width: 2,
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
              color: isDark
                ? colorScheme.onTertiaryContainer.withValues(alpha: 0.9)
                : colorScheme.onTertiaryContainer.withValues(alpha: 0.95),
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
        color: colorScheme.primaryContainer,
        borderRadius: AppRadius.radiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome,
            color: colorScheme.primary,
            size: 32,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Upgrade to Premium',
            style: EnhancedTypography.headlineSmall.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Unlimited articles, advanced wellness features, and more.',
            style: EnhancedTypography.bodyMedium.copyWith(
              color: colorScheme.onPrimaryContainer,
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
          ),
        ),
        const SizedBox(height: Spacing.md),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.radiusMd,
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.payment,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: const Text('Payment Methods'),
                subtitle: const Text('Manage your saved payment methods'),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
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
              ListTile(
                leading: Icon(
                  Icons.receipt_long,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: const Text('Billing History'),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
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
              ListTile(
                leading: Icon(
                  Icons.cancel,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Cancel Subscription',
                  style: TextStyle(color: colorScheme.error),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colorScheme.error,
                ),
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
