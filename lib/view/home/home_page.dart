import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';
import 'package:the_news/view/home/widget/home_content.dart';
import 'package:the_news/service/disliked_articles_service.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/service/saved_articles_service.dart';
import 'package:the_news/service/calm_mode_service.dart';
import 'package:the_news/service/achievements_service.dart';
import 'package:the_news/view/home/widget/view_toggle_button.dart';
import 'package:the_news/view/widgets/pill_tab.dart';
import 'package:the_news/service/notification_service.dart';
import 'package:the_news/view/notifications/notification_history_page.dart';
import 'package:the_news/view/profile/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.user,
    required this.viewModeNotifier,
    this.onProfileTap,
  });

  final RegisterLoginUserSuccessModel user;
  final ValueNotifier<ViewMode> viewModeNotifier;
  final VoidCallback? onProfileTap;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _streakCount = 0;
  int _unreadCount = 0;
  final NotificationService _notificationService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    StatusBarHelper.setLightStatusBar();
    // Load user data when home page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DislikedArticlesService.instance.loadDislikedArticles(widget.user.userId);
      SavedArticlesService.instance.loadSavedArticles(widget.user.userId);
      FollowedPublishersService.instance.loadFollowedPublishers(
        widget.user.userId,
      );
    });
    _loadStreak();
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    final count =
        await _notificationService.getUnreadNotificationCount(widget.user.userId);
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NotificationHistoryPage(),
      ),
    );
    _refreshUnreadCount();
  }

  void _openProfile() {
    if (widget.onProfileTap != null) {
      widget.onProfileTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(user: widget.user),
      ),
    );
  }

  Widget _buildHomeHeader({required bool showExtras}) {
    return ListenableBuilder(
      listenable: CalmModeService.instance,
      builder: (context, _) {
        return HomeHeader(
          title: 'Home',
          subtitle: null,
          leading: null,
          showActions: true,
          viewToggle: Row(
            children: [
              InkWell(
                onTap: _openNotifications,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: KAppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing8),
              InkWell(
                onTap: _openProfile,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _profileInitial(),
                    style: KAppTextStyles.labelMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          footer: showExtras
              ? Column(
                  children: [
                    const SizedBox(height: KDesignConstants.spacing12),
                    _buildHomePills(),
                  ],
                )
              : null,
        );
      },
    );
  }

  String _profileInitial() {
    final displayName = widget.user.name.isNotEmpty ? widget.user.name : widget.user.email;
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  }

  Widget _buildHomePills() {
    return ListenableBuilder(
      listenable: CalmModeService.instance,
      builder: (context, _) {
        final calmMode = CalmModeService.instance;
        final date = DateTime.now();
        final dayLabel = '${_weekdayName(date.weekday)} · ${date.day}/${date.month}';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HomePill(
                  icon: Icons.today_outlined,
                  label: dayLabel,
                ),
                const SizedBox(width: KDesignConstants.spacing8),
                _HomePill(
                  icon: Icons.local_fire_department_outlined,
                  label: _streakCount > 0 ? '$_streakCount day streak' : 'Start a streak',
                  highlight: _streakCount > 0,
                ),
                const SizedBox(width: KDesignConstants.spacing8),
                _HomePill(
                  icon: calmMode.isCalmModeEnabled ? Icons.spa : Icons.flash_on,
                  label: calmMode.isCalmModeEnabled ? 'Calm Mode' : 'Focus Mode',
                  highlight: calmMode.isCalmModeEnabled,
                ),
                const SizedBox(width: KDesignConstants.spacing8),
                _HomePill(
                  icon: Icons.timer_outlined,
                  label: '${calmMode.dailyReadingLimit} min',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadStreak() async {
    await AchievementsService.instance.initialize();
    if (!mounted) return;
    setState(() {
      _streakCount = AchievementsService.instance.currentStreak.currentStreak;
    });
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: KAppColors.getBackground(context),
      child: Container(
        color: KAppColors.getBackground(context),
        child: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<ViewMode>(
            valueListenable: widget.viewModeNotifier,
            builder: (context, viewMode, _) {
              return Column(
                children: [
                  _buildHomeHeader(showExtras: viewMode == ViewMode.compactList),
                  Expanded(
                    child: HomeContent(user: widget.user, viewMode: viewMode),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomePill extends StatelessWidget {
  const _HomePill({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final textColor = highlight
        ? KAppColors.getOnPrimary(context)
        : KAppColors.getOnBackground(context).withValues(alpha: 0.75);

    return PillTabContainer(
      selected: highlight,
      borderRadius: KBorderRadius.xl,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: KAppTextStyles.labelMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// (removed unused helper widgets)
