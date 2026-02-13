import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/notification_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/service/auth_service.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  final NotificationService _notificationService = NotificationService.instance;
  final AuthService _authService = AuthService();

  String? _userId;

  bool _breakingNews = true;
  bool _dailyDigest = true;
  bool _publisherUpdates = true;
  bool _replies = true;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    final userData = await _authService.getCurrentUser();
    _userId = userData?['id'] as String? ?? userData?['userId'] as String?;

    if (_userId != null) {
      await _notificationService.fetchPreferencesFromBackend(_userId!);
    }

    _loadPreferences();
  }

  void _loadPreferences() {
    final prefs = _notificationService.getPreferences();
    if (!mounted) return;
    setState(() {
      _breakingNews = prefs['breakingNews'] ?? true;
      _dailyDigest = prefs['dailyDigest'] ?? true;
      _publisherUpdates = prefs['publisherUpdates'] ?? true;
      _replies = prefs['commentReplies'] ?? true;
    });
  }

  Future<void> _updatePreference(String key, bool value) async {
    setState(() {
      switch (key) {
        case 'breakingNews':
          _breakingNews = value;
          break;
        case 'dailyDigest':
          _dailyDigest = value;
          break;
        case 'publisherUpdates':
          _publisherUpdates = value;
          break;
        case 'commentReplies':
          _replies = value;
          break;
      }
    });

    // Update the notification service
    await _notificationService.updatePreferences(
      breakingNews: key == 'breakingNews' ? value : null,
      dailyDigest: key == 'dailyDigest' ? value : null,
      publisherUpdates: key == 'publisherUpdates' ? value : null,
      commentReplies: key == 'commentReplies' ? value : null,
      userId: _userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color screenBackgroundColor = KAppColors.getBackground(context);

    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: screenBackgroundColor,
      child: Scaffold(
        backgroundColor: screenBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Back button and title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 16, 16, 0),
                      child: Row(
                        children: [
                          const AppBackButton(),
                          Text(
                            'Notifications',
                            style: KAppTextStyles.headlineMedium.copyWith(
                              color: KAppColors.getOnBackground(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KDesignConstants.spacing8),
                  ],
                ),
              ),
              
              // Notification Types
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push Notifications',
                        style: KAppTextStyles.titleSmall.copyWith(
                          color: KAppColors.getOnBackground(context)
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: KDesignConstants.spacing12),
                    ],
                  ),
                ),
              ),

              // Breaking News Toggle
              SliverToBoxAdapter(
                child: _buildNotificationToggle(
                  icon: Icons.bolt,
                  iconColor: KAppColors.orange,
                  title: 'Breaking News',
                  subtitle: 'Get notified about important news updates',
                  value: _breakingNews,
                  onChanged: (value) => _updatePreference('breakingNews', value),
                ),
              ),

              // Daily Digest Toggle
              SliverToBoxAdapter(
                child: _buildNotificationToggle(
                  icon: Icons.auto_awesome,
                  iconColor: KAppColors.success,
                  title: 'Daily Digest',
                  subtitle: 'Receive your personalized daily summary',
                  value: _dailyDigest,
                  onChanged: (value) => _updatePreference('dailyDigest', value),
                ),
              ),

              // Publisher Updates Toggle
              SliverToBoxAdapter(
                child: _buildNotificationToggle(
                  icon: Icons.source,
                  iconColor: KAppColors.info,
                  title: 'Publisher Updates',
                  subtitle: 'New articles from publishers you follow',
                  value: _publisherUpdates,
                  onChanged: (value) =>
                      _updatePreference('publisherUpdates', value),
                ),
              ),

              // Replies Toggle
              SliverToBoxAdapter(
                child: _buildNotificationToggle(
                  icon: Icons.reply,
                  iconColor: KAppColors.purple,
                  title: 'Replies & Mentions',
                  subtitle: 'When someone replies to your comments',
                  value: _replies,
                  onChanged: (value) => _updatePreference('commentReplies', value),
                ),
              ),

              // Info Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: KDesignConstants.paddingMd,
                    decoration: BoxDecoration(
                      color: KAppColors.getPrimary(context)
                          .withValues(alpha: 0.05),
                      borderRadius: KBorderRadius.lg,
                      border: Border.all(
                        color: KAppColors.getPrimary(context)
                            .withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: KAppColors.getPrimary(context),
                          size: 24,
                        ),
                        const SizedBox(width: KDesignConstants.spacing12),
                        Expanded(
                          child: Text(
                            'You can change these preferences anytime. System notifications must be enabled in your device settings.',
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: KAppColors.getOnBackground(context)
                                  .withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 50),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: KBorderRadius.md,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: KDesignConstants.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KAppTextStyles.titleMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: KAppColors.getPrimary(context),
            ),
          ],
        ),
      ),
    );
  }
}
