import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/enhanced_typography.dart';
import 'package:the_news/model/subscription_model.dart';
import 'package:the_news/service/subscription_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/payment_service.dart';
import 'package:the_news/utils/haptic_service.dart';
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
  bool _isLoading = false;
  bool _hasUsedTrial = false;

  @override
  void initState() {
    super.initState();
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
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Premium gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1A237E).withValues(alpha: 0.3),
                          const Color(0xFF4A148C).withValues(alpha: 0.2),
                          colorScheme.surface,
                        ]
                      : [
                          const Color(0xFF6366F1).withValues(alpha: 0.08),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                          colorScheme.surface,
                        ],
                  stops: const [0.0, 0.3, 0.7],
                ),
              ),
            ),

            // Animated content
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Hero Header
                    SliverToBoxAdapter(
                      child: _buildHeroHeader(context),
                    ),

                    // Trust Indicators
                    SliverToBoxAdapter(
                      child: _buildTrustIndicators(context),
                    ),

                    // Plan Selection
                    SliverToBoxAdapter(
                      child: _buildPlanSelection(context),
                    ),

                    // Premium Features
                    SliverToBoxAdapter(
                      child: _buildPremiumFeatures(context),
                    ),

                    // Social Proof
                    SliverToBoxAdapter(
                      child: _buildSocialProof(context),
                    ),

                    // FAQ Section
                    SliverToBoxAdapter(
                      child: _buildFAQ(context),
                    ),

                    // CTA Section
                    SliverToBoxAdapter(
                      child: _buildCTASection(context),
                    ),

                    // Footer
                    SliverToBoxAdapter(
                      child: _buildFooter(context),
                    ),
                  ],
                ),
              ),
            ),

            // Close Button
            if (widget.showCloseButton)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: colorScheme.surface.withValues(alpha: 0.9),
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: () {
                      HapticService.light();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),

            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
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
                          const SizedBox(height: 20),
                          Text(
                            'Processing your subscription...',
                            style: EnhancedTypography.titleMedium.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
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
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        children: [
          // Premium badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'PREMIUM',
                  style: EnhancedTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Main headline
          Text(
            'Unlock Your\nBest Reading Experience',
            textAlign: TextAlign.center,
            style: EnhancedTypography.displayMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Subheadline
          Text(
            'Join thousands of readers who stay informed\nwithout the overwhelm',
            textAlign: TextAlign.center,
            style: EnhancedTypography.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Hero image/illustration placeholder
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.1),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                Icons.auto_stories_outlined,
                size: 80,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustIndicators(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrustItem(
            context,
            Icons.verified_user,
            '10K+',
            'Active Users',
          ),
          _buildTrustItem(
            context,
            Icons.star_rounded,
            '4.8',
            'App Rating',
          ),
          _buildTrustItem(
            context,
            Icons.security,
            '100%',
            'Secure',
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(BuildContext context, IconData icon, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: EnhancedTypography.titleLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: EnhancedTypography.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanSelection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Plan',
            style: EnhancedTypography.headlineMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cancel anytime. No hidden fees.',
            style: EnhancedTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Display plans from service
          ...(_subscriptionService.paidPlans.asMap().entries.map((entry) {
            final index = entry.key;
            final plan = entry.value;
            final isYearly = plan.billingPeriod == 'yearly';
            return Padding(
              padding: EdgeInsets.only(bottom: index < _subscriptionService.paidPlans.length - 1 ? 16 : 0),
              child: _buildEnhancedPlanCard(
                context,
                plan,
                isRecommended: isYearly,
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildEnhancedPlanCard(BuildContext context, SubscriptionPlan plan, {required bool isRecommended}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedPlan?.id == plan.id;
    final isYearly = plan.billingPeriod == 'yearly';

    final monthlyPrice = isYearly
        ? (PaymentService.yearlyPriceKobo / 100) / 12
        : (PaymentService.monthlyPriceKobo / 100);
    final totalPrice = isYearly
        ? (PaymentService.yearlyPriceKobo / 100)
        : (PaymentService.monthlyPriceKobo / 100);

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        setState(() => _selectedPlan = plan);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.15),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  ],
                )
              : null,
          color: isSelected ? null : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Recommended badge
            if (isRecommended)
              Positioned(
                top: -1,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'BEST VALUE - SAVE ${_paymentService.getYearlySavingsDisplay()}',
                        style: EnhancedTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: EdgeInsets.fromLTRB(20, isRecommended ? 36 : 20, 20, 20),
              child: Row(
                children: [
                  // Radio indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : colorScheme.outline,
                        width: 2,
                      ),
                      color: isSelected ? colorScheme.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Plan details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.billingPeriod,
                          style: EnhancedTypography.titleLarge.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isYearly)
                          Text(
                            'Billed annually at R${totalPrice.toStringAsFixed(2)}',
                            style: EnhancedTypography.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'R',
                              style: EnhancedTypography.titleMedium.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: monthlyPrice.toStringAsFixed(0),
                              style: EnhancedTypography.displaySmall.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '/month',
                        style: EnhancedTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeatures(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Everything Premium Includes',
            style: EnhancedTypography.headlineSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          _buildFeatureItem(
            context,
            Icons.auto_awesome,
            'Unlimited Articles',
            'Read as much as you want with no daily limits',
            const Color(0xFF6366F1),
          ),
          _buildFeatureItem(
            context,
            Icons.favorite,
            'Mental Wellness Tools',
            'Mood tracking, break reminders & wellness insights',
            const Color(0xFFEC4899),
          ),
          _buildFeatureItem(
            context,
            Icons.psychology,
            'AI-Powered Features',
            'Smart summaries, bias detection & fact-checking',
            const Color(0xFF8B5CF6),
          ),
          _buildFeatureItem(
            context,
            Icons.bookmark,
            'Unlimited Bookmarks',
            'Save and organize articles without restrictions',
            const Color(0xFF10B981),
          ),
          _buildFeatureItem(
            context,
            Icons.bar_chart,
            'Advanced Analytics',
            'Deep insights into your reading habits',
            const Color(0xFFF59E0B),
          ),
          _buildFeatureItem(
            context,
            Icons.cloud_download,
            'Offline Reading',
            'Download articles to read anywhere, anytime',
            const Color(0xFF06B6D4),
          ),
          _buildFeatureItem(
            context,
            Icons.people,
            'Social Features',
            'Share lists and follow other readers',
            const Color(0xFFEF4444),
          ),
          _buildFeatureItem(
            context,
            Icons.notifications_off,
            'Ad-Free Experience',
            'Enjoy distraction-free reading',
            const Color(0xFF6366F1),
          ),
        ],
      ),
    );
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
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
        borderRadius: BorderRadius.circular(16),
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
                  color: const Color(0xFFFBBF24),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"This app completely changed how I consume news. The wellness features help me stay informed without feeling overwhelmed."',
            style: EnhancedTypography.bodyLarge.copyWith(
              color: colorScheme.onSurface,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),

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
              const SizedBox(width: 8),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Primary CTA Button
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _hasUsedTrial || _selectedPlan?.trialDays == null
                        ? 'Subscribe Now'
                        : 'Start ${_selectedPlan?.trialDays}-Day Free Trial',
                    style: EnhancedTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Trial info
          if (!_hasUsedTrial && _selectedPlan?.trialDays != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.celebration, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'First ${_selectedPlan?.trialDays} days are FREE',
                    style: EnhancedTypography.bodyMedium.copyWith(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Money-back guarantee
          Text(
            '💳 Secure Payment • 🔒 Cancel Anytime',
            textAlign: TextAlign.center,
            style: EnhancedTypography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'By subscribing, you agree to our Terms of Service and Privacy Policy',
            textAlign: TextAlign.center,
            style: EnhancedTypography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _handleSubscribe() async {
    HapticService.medium();
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID and email from auth service
      final userData = await _authService.getCurrentUser();
      final userId = userData?['id'] as String?;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 36),
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
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: const Text('Oops!'),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                backgroundColor: Colors.red,
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
      appBar: AppBar(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel Payment'),
          ),
        ],
      ),
    );
  }
}
