import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/enhanced_typography.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/subscription_model.dart';
import 'package:the_news/service/subscription_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/payment_service.dart';
import 'package:the_news/utils/haptic_service.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SubscriptionPaywallPage extends StatefulWidget {
  final bool showCloseButton;
  final VoidCallback? onSubscribed;

  const SubscriptionPaywallPage({
    super.key,
    this.showCloseButton = true,
    this.onSubscribed,
  });

  @override
  State<SubscriptionPaywallPage> createState() => _SubscriptionPaywallPageState();
}

class _SubscriptionPaywallPageState extends State<SubscriptionPaywallPage>
    with SingleTickerProviderStateMixin {
  final _subscriptionService = SubscriptionService.instance;
  final _paymentService = PaymentService.instance;
  final _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  SubscriptionPlan? _selectedPlan;
  String _selectedPlanKey = 'annual';
  late final PageController _tierController;
  int _tierIndex = 1;
  final bool _showAllFeatures = false;
  bool _isLoading = false;
  bool _hasUsedTrial = false;

  @override
  void initState() {
    super.initState();
    _tierController = PageController(viewportFraction: 0.9, initialPage: 1);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    // Load plans first
    await _subscriptionService.loadSubscriptionPlans();

    // Load subscription status
    final subscription = await _subscriptionService.getCurrentSubscription();

    if (mounted) {
      setState(() {
        _hasUsedTrial = subscription?.trialStartDate != null;
        // Select yearly plan by default (or first paid plan)
        final paidPlans = _subscriptionService.paidPlans;
        if (paidPlans.isNotEmpty) {
          _selectedPlan = paidPlans.firstWhere(
            (p) => p.billingPeriod == 'yearly',
            orElse: () => paidPlans.first,
          );
          _selectedPlanKey = _selectedPlan?.billingPeriod == 'yearly' ? 'annual' : 'monthly';
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = KAppColors.getBackground(context);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: ColoredBox(
          color: background,
          child: Stack(
            children: [
              // Premium background
              Container(
                decoration: BoxDecoration(
                  color: background,
                ),
              ),

              // Animated content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPricingHeader(context),
                          const SizedBox(height: KDesignConstants.spacing16),
                          _buildPricingCarousel(context),
                          const SizedBox(height: KDesignConstants.spacing16),
                          _buildFooter(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Loading Overlay
            if (_isLoading)
              Container(
                color: KAppColors.darkBackground.withValues(alpha: 0.7),
                child: Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: KBorderRadius.xl,
                    ),
                    child: Padding(
                      padding: KDesignConstants.paddingXl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: KDesignConstants.spacing20),
                          Text(
                            'Processing your subscription...',
                            style: EnhancedTypography.titleMedium.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: KDesignConstants.spacing8),
                          Text(
                            'Please wait',
                            style: EnhancedTypography.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildPricingHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: KAppColors.getOnBackground(context)),
            onPressed: () {
              HapticService.light();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pricing',
              style: EnhancedTypography.headlineSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ),
          _buildBillingToggle(context),
        ],
      ),
    );
  }

  Widget _buildBillingToggle(BuildContext context) {
    final isAnnual = _selectedPlanKey == 'annual';

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
        borderRadius: KBorderRadius.full,
      ),
      child: Row(
        children: [
          _buildToggleChip(
            context,
            label: 'Annual',
            selected: isAnnual,
            onTap: () {
              final yearlyPlan = _subscriptionService.paidPlans.firstWhere(
                (plan) => plan.billingPeriod == 'yearly',
                orElse: () => _subscriptionService.paidPlans.first,
              );
              setState(() {
                _selectedPlan = yearlyPlan;
                _selectedPlanKey = 'annual';
              });
              if (_tierController.hasClients) {
                _tierController.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
          _buildToggleChip(
            context,
            label: 'Monthly',
            selected: !isAnnual,
            onTap: () {
              final monthlyPlan = _subscriptionService.paidPlans.firstWhere(
                (plan) => plan.billingPeriod == 'monthly',
                orElse: () => _subscriptionService.paidPlans.first,
              );
              setState(() {
                _selectedPlan = monthlyPlan;
                _selectedPlanKey = 'monthly';
              });
              if (_tierController.hasClients) {
                _tierController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? KAppColors.getPrimary(context) : Colors.transparent,
          borderRadius: KBorderRadius.full,
        ),
        child: Text(
          label,
          style: EnhancedTypography.labelSmall.copyWith(
            color: selected
                ? KAppColors.getOnPrimary(context)
                : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTrustIndicators(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildTrustPill(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: KBorderRadius.full,
        border: Border.all(color: KAppColors.getOnBackground(context).withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: EnhancedTypography.labelMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCarousel(BuildContext context) {
    final features = _getAllFeatures();
    final freeIncluded = SubscriptionPlan.free.features;
    final premiumIncluded = features.take(8).toList();
    final freeExcluded = features.where((item) => !freeIncluded.contains(item)).toList();
    final premiumExcluded = features.where((item) => !premiumIncluded.contains(item)).toList();

    final paidPlans = _subscriptionService.paidPlans.isNotEmpty
        ? _subscriptionService.paidPlans
        : SubscriptionPlan.paidPlans;
    if (paidPlans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: KDesignConstants.paddingMd,
          decoration: BoxDecoration(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
            borderRadius: KBorderRadius.lg,
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            'Plans are loading. Please try again in a moment.',
            style: EnhancedTypography.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    final fallbackPlan = paidPlans.first;
    final monthlyPlan = paidPlans.firstWhere(
      (plan) => plan.billingPeriod == 'monthly',
      orElse: () => fallbackPlan,
    );
    final yearlyPlan = paidPlans.firstWhere(
      (plan) => plan.billingPeriod == 'yearly',
      orElse: () => fallbackPlan,
    );

    final monthlyPrice = (PaymentService.monthlyPriceKobo / 100);
    final yearlyPrice = (PaymentService.yearlyPriceKobo / 100);

    final cardHeight = (MediaQuery.of(context).size.height * 0.64).clamp(520.0, 640.0);

    Widget buildCard(int index) {
      if (index == 0) {
        return _buildPricingCard(
          context,
          title: 'The News Basic',
          badge: 'Free',
          priceText: 'Free',
          billedText: 'Basic access',
          description: 'Get started with the essentials.',
          included: freeIncluded,
          excluded: freeExcluded,
          highlighted: index == _tierIndex,
          onSelect: () {
            if (_tierController.hasClients) {
              _tierController.animateToPage(
                0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
              );
            }
          },
          ctaLabel: 'Current Plan',
          ctaEnabled: false,
        );
      }

      if (index == 1) {
        return _buildPricingCard(
          context,
          title: 'The News Pro',
          badge: null,
          priceText: 'R${monthlyPrice.toStringAsFixed(0)}',
          billedText: '/month (ZAR)\nR${monthlyPrice.toStringAsFixed(0)} billed monthly',
          description: 'A premium reading experience with advanced tools.',
          included: premiumIncluded,
          excluded: premiumExcluded,
          highlighted: index == _tierIndex,
          onSelect: () {
            setState(() {
              _selectedPlanKey = 'monthly';
              _selectedPlan = monthlyPlan;
            });
            if (_tierController.hasClients) {
              _tierController.animateToPage(
                1,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
              );
            }
          },
          ctaLabel: _hasUsedTrial || monthlyPlan.trialDays == null
              ? 'Start Monthly'
              : 'Start ${monthlyPlan.trialDays}-days Free Trial',
          ctaEnabled: true,
        );
      }

      return _buildPricingCard(
        context,
        title: 'The News Ultimate',
        badge: 'Best value',
        priceText: 'R${(yearlyPrice / 12).toStringAsFixed(0)}',
        billedText: '/month (ZAR)\nR${yearlyPrice.toStringAsFixed(0)} billed yearly',
        description: 'Everything in The News — unlocked.',
        included: features,
        excluded: const [],
        highlighted: index == _tierIndex,
        onSelect: () {
          setState(() {
            _selectedPlanKey = 'annual';
            _selectedPlan = yearlyPlan;
          });
          if (_tierController.hasClients) {
            _tierController.animateToPage(
              2,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            );
          }
        },
        ctaLabel: _hasUsedTrial || yearlyPlan.trialDays == null
            ? 'Start Annual'
            : 'Start ${yearlyPlan.trialDays}-days Free Trial',
        ctaEnabled: true,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: _tierController,
            itemCount: 3,
            onPageChanged: (index) {
              setState(() {
                _tierIndex = index;
                if (index == 1) {
                  _selectedPlanKey = 'monthly';
                  _selectedPlan = monthlyPlan;
                } else if (index == 2) {
                  _selectedPlanKey = 'annual';
                  _selectedPlan = yearlyPlan;
                }
              });
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _tierController,
                builder: (context, child) {
                  double scale = 1.0;
                  double opacity = 1.0;
                  if (_tierController.position.hasContentDimensions) {
                    final page = _tierController.page ?? _tierController.initialPage.toDouble();
                    final diff = (page - index).abs();
                    scale = (1 - (diff * 0.08)).clamp(0.9, 1.0);
                    opacity = (1 - (diff * 0.2)).clamp(0.7, 1.0);
                  }
                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: child,
                      ),
                    ),
                  );
                },
                child: buildCard(index),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _tierIndex == index ? 18 : 6,
              decoration: BoxDecoration(
                color: _tierIndex == index
                    ? KAppColors.getPrimary(context)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.25),
                borderRadius: KBorderRadius.full,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String? badge,
    required String priceText,
    required String billedText,
    required String description,
    required List<String> included,
    required List<String> excluded,
    required bool highlighted,
    required VoidCallback onSelect,
    required String ctaLabel,
    required bool ctaEnabled,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = highlighted
        ? KAppColors.getPrimary(context)
        : KAppColors.getOnBackground(context).withValues(alpha: 0.12);

    return GestureDetector(
      onTap: onSelect,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
              borderRadius: KBorderRadius.xl,
              border: Border.all(
                color: borderColor,
                width: highlighted ? 2 : 1,
              ),
            ),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: EnhancedTypography.titleLarge.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: KAppColors.warning.withValues(alpha: 0.15),
                            borderRadius: KBorderRadius.full,
                            border: Border.all(
                              color: KAppColors.warning.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            badge,
                            style: EnhancedTypography.labelSmall.copyWith(
                              color: KAppColors.warning,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: priceText,
                          style: EnhancedTypography.displaySmall.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                        TextSpan(
                          text: ' $billedText',
                          style: EnhancedTypography.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: EnhancedTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...included.map(
                            (feature) => _featureRow(context, feature, true),
                          ),
                          if (excluded.isNotEmpty) const SizedBox(height: 8),
                          ...excluded.map(
                            (feature) => _featureRow(context, feature, false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: ctaEnabled ? _handleSubscribe : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KAppColors.getPrimary(context),
                        foregroundColor: KAppColors.getOnPrimary(context),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: KBorderRadius.full,
                        ),
                      ),
                      child: Text(
                        ctaLabel,
                        style: EnhancedTypography.labelLarge.copyWith(
                          color: KAppColors.getOnPrimary(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _featureRow(BuildContext context, String label, bool included) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle : Icons.close,
            size: 18,
            color: included
                ? KAppColors.success
                : KAppColors.getOnBackground(context).withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: EnhancedTypography.bodySmall.copyWith(
                color: included
                    ? KAppColors.getOnBackground(context)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description, Color color) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: KBorderRadius.md,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: KDesignConstants.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: EnhancedTypography.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: KDesignConstants.spacing4),
                Text(
                  description,
                  style: EnhancedTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialProof(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: KBorderRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  Icons.star_rounded,
                  color: KAppColors.yellow,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Text(
            '"This app completely changed how I consume news. The wellness features help me stay informed without feeling overwhelmed."',
            style: EnhancedTypography.bodyLarge.copyWith(
              color: colorScheme.onSurface,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Text(
            '- Sarah M., Premium Member',
            style: EnhancedTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: EnhancedTypography.headlineSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing16),

          _buildFAQItem(
            context,
            'Can I cancel anytime?',
            'Yes! Cancel your subscription at any time from your profile settings. No questions asked.',
          ),
          _buildFAQItem(
            context,
            'Is my payment secure?',
            'Absolutely. We use Paystack, a trusted payment processor with bank-level security.',
          ),
          _buildFAQItem(
            context,
            'What happens after the trial?',
            'If you don\'t cancel before the trial ends, you\'ll be charged for your selected plan.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline, color: colorScheme.primary, size: 20),
              const SizedBox(width: KDesignConstants.spacing8),
              Expanded(
                child: Text(
                  question,
                  style: EnhancedTypography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              answer,
              style: EnhancedTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          _hasUsedTrial || _selectedPlan?.trialDays == null
              ? 'Cancel anytime. Manage in Settings.'
              : 'First ${_selectedPlan?.trialDays} days are free. Cancel anytime.',
          textAlign: TextAlign.center,
          style: EnhancedTypography.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<String> _getAllFeatures() {
    final premiumFeatures = <String>{
      ...SubscriptionPlan.premium.features,
      ...SubscriptionPlan.premiumYearly.features,
    };

    return premiumFeatures
        .where((item) => item.trim().isNotEmpty)
        .where((item) => !item.toLowerCase().contains('trial'))
        .where((item) => !item.toLowerCase().contains('save'))
        .where((item) => !item.toLowerCase().contains('year'))
        .where((item) => !item.toLowerCase().contains('off'))
        .toList();
  }

  Future<void> _handleSubscribe() async {
    HapticService.medium();
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID and email from auth service
      final userData = await _authService.getCurrentUser();
      final userId = userData?['id'] as String? ?? userData?['userId'] as String?;
      final email = userData?['email'] as String?;

      if (userId == null || email == null) {
        if (mounted) {
          await HapticService.error();
          _showErrorDialog('Please sign in to continue');
        }
        return;
      }

      // Initialize payment with Paystack
      final isYearly = _selectedPlan?.billingPeriod == 'yearly';
      final Map<String, dynamic> result;

      if (isYearly) {
        result = await _paymentService.subscribeYearly(
          userId: userId,
          email: email,
        );
      } else {
        result = await _paymentService.subscribeMonthly(
          userId: userId,
          email: email,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (!result['success']) {
        if (mounted) {
          await HapticService.error();
          _showErrorDialog(result['message'] ?? 'Payment initialization failed');
        }
        return;
      }

      // Open Paystack payment page in WebView
      final authUrl = result['authorizationUrl'] as String;
      final reference = result['reference'] as String;

      if (mounted) {
        final paymentSuccess = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PaystackPaymentPage(
              authorizationUrl: authUrl,
              reference: reference,
            ),
          ),
        );

        if (paymentSuccess == true) {
          // Verify payment
          final verified = await _paymentService.verifyPayment(reference);

          if (verified) {
            await HapticService.success();
            _showPaymentSuccessDialog();
          } else {
            await HapticService.error();
            _showErrorDialog('Payment verification failed');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        await HapticService.error();
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: KBorderRadius.xl),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: KAppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: KAppColors.onImage, size: 36),
        ),
        title: const Text('Welcome to Premium!'),
        content: const Text(
          'Your subscription is now active. Enjoy unlimited access to all premium features and start your mindful news journey!',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close paywall
                widget.onSubscribed?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: KAppColors.darkOnBackground,
                padding: KDesignConstants.paddingVerticalMd,
                shape: RoundedRectangleBorder(
                  borderRadius: KBorderRadius.md,
                ),
              ),
              child: const Text('Start Reading'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: KBorderRadius.xl),
        icon: const Icon(Icons.error_outline, color: KAppColors.error, size: 48),
        title: const Text('Oops!'),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: KDesignConstants.paddingVerticalMd,
                shape: RoundedRectangleBorder(
                  borderRadius: KBorderRadius.md,
                ),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
}

/// WebView page for Paystack payment
class PaystackPaymentPage extends StatefulWidget {
  final String authorizationUrl;
  final String reference;

  const PaystackPaymentPage({
    super.key,
    required this.authorizationUrl,
    required this.reference,
  });

  @override
  State<PaystackPaymentPage> createState() => _PaystackPaymentPageState();
}

class _PaystackPaymentPageState extends State<PaystackPaymentPage> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            // Check if payment was successful (redirect contains reference)
            if (url.contains('success') || url.contains('callback')) {
              Navigator.pop(context, true); // Return success
            } else if (url.contains('cancel') || url.contains('failed')) {
              Navigator.pop(context, false); // Return failure
            }
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading payment page: ${error.description}'),
                backgroundColor: KAppColors.error,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: KAppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showCancelDialog();
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: KBorderRadius.xl),
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to cancel this payment? Your subscription will not be activated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Payment'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, false); // Close payment page
            },
            style: TextButton.styleFrom(
              foregroundColor: KAppColors.error,
            ),
            child: const Text('Cancel Payment'),
          ),
        ],
      ),
    );
  }

}
