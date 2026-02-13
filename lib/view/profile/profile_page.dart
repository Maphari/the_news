
import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/subscription_service.dart';
import 'package:the_news/service/app_rating_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';
import 'package:the_news/view/profile/widget/wellness_dashboard.dart';
import 'package:the_news/view/profile/widget/account_management_section.dart';
import 'package:the_news/view/profile/notification_preferences_page.dart';
import 'package:the_news/view/analytics/analytics_dashboard_page.dart';
import 'package:the_news/view/offline/offline_reading_page.dart';
import 'package:the_news/view/reading_history/reading_history_page.dart';
import 'package:the_news/view/wellness/break_reminder_settings_page.dart';
import 'package:the_news/view/notifications/notification_history_page.dart';
import 'package:the_news/view/social/social_hub_page.dart';
import 'package:the_news/view/subscription/subscription_paywall_page.dart';
import 'package:the_news/view/feedback/feedback_form_page.dart';
import 'package:the_news/view/profile/country_selection_page.dart';
import 'package:the_news/view/profile/followed_publishers_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.user});

   final RegisterLoginUserSuccessModel user;
   
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SubscriptionService _subscriptionService = SubscriptionService.instance;
  bool _isWellnessExpanded = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    final subscription = await _subscriptionService.getCurrentSubscription();
    if (mounted) {
      setState(() {
        _isPremium = subscription?.isActive ?? false;
      });
    }
  }

  Widget _buildPremiumUpgradeCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionPaywallPage(
                showCloseButton: true,
              ),
            ),
          );
        },
        borderRadius: KBorderRadius.lg,
        child: Container(
          padding: KDesignConstants.paddingMd,
          decoration: BoxDecoration(
            color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
            borderRadius: KBorderRadius.lg,
            border: Border.all(
              color: KAppColors.getPrimary(context).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                  borderRadius: KBorderRadius.lg,
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: KAppColors.getPrimary(context),
                  size: 32,
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade to Premium',
                      style: KAppTextStyles.titleMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: KDesignConstants.spacing4),
                    Text(
                      'Unlock exclusive features and ad-free experience',
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: KAppColors.getPrimary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color screenBackgroundColor = KAppColors.getBackground(context);

    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: screenBackgroundColor,
      child: Container(
        color: screenBackgroundColor,
        child: SafeArea(
          bottom: false, // Don't add bottom padding - MainScaffold has bottom nav
          child: Material(
            color: screenBackgroundColor,
            child: CustomScrollView(
              slivers: [
              // Header
              MeasuredPinnedHeaderSliver(
                height: HomeHeader.estimatedHeight(
                  title: 'Profile',
                  subtitle: 'Manage your account and preferences',
                  bottom: 15,
                ),
                child: HomeHeader(
                  title: 'Profile',
                  subtitle: 'Manage your account and preferences',
                  showActions: false,
                  bottom: 15,
                  useSafeArea: false,
                ),
              ),

              // Account Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    'Account',
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Account Management Section
              const SliverToBoxAdapter(
                child: AccountManagementSection(),
              ),

              // Premium Upgrade Card (only show for non-premium users)
              if (!_isPremium)
                SliverToBoxAdapter(
                  child: _buildPremiumUpgradeCard(context),
                ),

              // Wellness Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Wellness',
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Wellness Dashboard Tile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing4),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isWellnessExpanded = !_isWellnessExpanded;
                          });
                        },
                        borderRadius: KBorderRadius.lg,
                        child: Container(
                          padding: KDesignConstants.paddingMd,
                          decoration: BoxDecoration(
                            color: KAppColors.getPrimary(context).withValues(alpha: 0.05),
                            borderRadius: KBorderRadius.lg,
                            border: Border.all(
                              color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                                  borderRadius: KBorderRadius.md,
                                ),
                                child: Icon(
                                  Icons.spa_outlined,
                                  color: KAppColors.getPrimary(context),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: KDesignConstants.spacing16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Wellness Dashboard',
                                      style: KAppTextStyles.titleMedium.copyWith(
                                        color: KAppColors.getOnBackground(context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Track your mindful reading journey',
                                      style: KAppTextStyles.bodySmall.copyWith(
                                        color: KAppColors.getOnBackground(context)
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _isWellnessExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isWellnessExpanded) ...[
                        const SizedBox(height: KDesignConstants.spacing16),
                        const WellnessDashboard(),
                      ],
                    ],
                  ),
                ),
              ),

              // Break Reminders Tile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BreakReminderSettingsPage(),
                        ),
                      );
                    },
                    borderRadius: KBorderRadius.lg,
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: KAppColors.cyan.withValues(alpha: 0.15),
                              borderRadius: KBorderRadius.md,
                            ),
                            child: const Icon(
                              Icons.self_improvement_outlined,
                              color: KAppColors.cyan,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Break Reminders',
                                  style: KAppTextStyles.titleMedium.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Configure mindful reading break intervals',
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Insights Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Insights',
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Analytics Dashboard Tile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsDashboardPage(),
                        ),
                      );
                    },
                    borderRadius: KBorderRadius.lg,
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: KAppColors.blue.withValues(alpha: 0.15),
                              borderRadius: KBorderRadius.md,
                            ),
                            child: const Icon(
                              Icons.analytics_outlined,
                              color: KAppColors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reading Analytics',
                                  style: KAppTextStyles.titleMedium.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Track your reading habits and stats',
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Reading History Tile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReadingHistoryPage(userId: widget.user.userId),
                        ),
                      );
                    },
                    borderRadius: KBorderRadius.lg,
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: KAppColors.orange.withValues(alpha: 0.15),
                              borderRadius: KBorderRadius.md,
                            ),
                            child: const Icon(
                              Icons.history,
                              color: KAppColors.orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reading History',
                                  style: KAppTextStyles.titleMedium.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'View your reading activity and stats',
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Notification History Tile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationHistoryPage(),
                        ),
                      );
                    },
                    borderRadius: KBorderRadius.lg,
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: KAppColors.purple.withValues(alpha: 0.15),
                              borderRadius: KBorderRadius.md,
                            ),
                            child: const Icon(
                              Icons.history,
                              color: KAppColors.purple,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notification History',
                                  style: KAppTextStyles.titleMedium.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'View all your notifications',
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Social Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Social',
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Social Hub Tile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SocialHubPage(
                            user: widget.user,
                          ),
                        ),
                      );
                    },
                    borderRadius: KBorderRadius.lg,
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: KAppColors.pink.withValues(alpha: 0.15),
                              borderRadius: KBorderRadius.md,
                            ),
                            child: const Icon(
                              Icons.people_outline,
                              color: KAppColors.pink,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Social Hub',
                                  style: KAppTextStyles.titleMedium.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Connect, share lists, and follow readers',
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Preferences Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Preferences',
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              // Offline Reading Tile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OfflineReadingPage(),
                        ),
                      );
                    },
                    borderRadius: KBorderRadius.lg,
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: KAppColors.success.withValues(alpha: 0.15),
                              borderRadius: KBorderRadius.md,
                            ),
                            child: const Icon(
                              Icons.offline_pin_outlined,
                              color: KAppColors.success,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Offline Reading',
                                  style: KAppTextStyles.titleMedium.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manage your offline article library',
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Followed Publishers Tile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FollowedPublishersPage(),
                        ),
                      );
                    },
                    borderRadius: KBorderRadius.lg,
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: KAppColors.purple.withValues(alpha: 0.15),
                              borderRadius: KBorderRadius.md,
                            ),
                            child: const Icon(
                              Icons.rss_feed,
                              color: KAppColors.purple,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Followed Publishers',
                                  style: KAppTextStyles.titleMedium.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manage publishers you follow for priority news',
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Country Preferences Tile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CountrySelectionPage(),
                        ),
                      );
                    },
                    borderRadius: KBorderRadius.lg,
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: KAppColors.cyan.withValues(alpha: 0.15),
                              borderRadius: KBorderRadius.md,
                            ),
                            child: const Icon(
                              Icons.public,
                              color: KAppColors.cyan,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Country Preferences',
                                  style: KAppTextStyles.titleMedium.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Select countries for localized news content',
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Notification Preferences Tile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationPreferencesPage(),
                        ),
                      );
                    },
                    borderRadius: KBorderRadius.lg,
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: KAppColors.warning.withValues(alpha: 0.15),
                              borderRadius: KBorderRadius.md,
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: KAppColors.warning,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notification Preferences',
                                  style: KAppTextStyles.titleMedium.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manage your notification preferences',
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Support Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Support',
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Rate App Tile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing4),
                  child: InkWell(
                    onTap: () async {
                      await AppRatingService.instance.promptUserForRating();
                    },
                    borderRadius: KBorderRadius.lg,
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: KAppColors.yellow.withValues(alpha: 0.15),
                              borderRadius: KBorderRadius.md,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: KAppColors.yellow,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rate Our App',
                                  style: KAppTextStyles.titleMedium.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Share your experience with us',
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Feedback Tile
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbackFormPage(),
                        ),
                      );
                    },
                    borderRadius: KBorderRadius.lg,
                    child: Container(
                      padding: KDesignConstants.paddingMd,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                        borderRadius: KBorderRadius.lg,
                        border: Border.all(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: KAppColors.blue.withValues(alpha: 0.15),
                              borderRadius: KBorderRadius.md,
                            ),
                            child: const Icon(
                              Icons.feedback_outlined,
                              color: KAppColors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Send Feedback',
                                  style: KAppTextStyles.titleMedium.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Help us improve your experience',
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
