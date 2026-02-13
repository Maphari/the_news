import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/reading_session_model.dart';
import 'package:the_news/service/reading_tracker_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/experience_service.dart';
import 'package:the_news/view/profile/widget/streak_card.dart';
import 'package:the_news/view/profile/widget/achievements_grid.dart';
import 'package:the_news/view/profile/widget/weekly_report_card.dart';
import 'package:the_news/view/profile/widget/share_stats_button.dart';

class WellnessDashboard extends StatefulWidget {
  const WellnessDashboard({super.key});

  @override
  State<WellnessDashboard> createState() => _WellnessDashboardState();
}

class _WellnessDashboardState extends State<WellnessDashboard> {
  final ReadingTrackerService _tracker = ReadingTrackerService.instance;
  final AuthService _authService = AuthService.instance;
  final ExperienceService _experienceService = ExperienceService.instance;
  ReadingStatsModel? _stats;
  Map<String, dynamic>? _remoteReport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _tracker.getReadingStats();
    final user = await _authService.getCurrentUser();
    final userId = (user?['id'] ?? user?['userId'])?.toString();
    final report = userId == null || userId.isEmpty
        ? null
        : await _experienceService.fetchWellnessReport(userId);
    if (mounted) {
      setState(() {
        _stats = stats;
        _remoteReport = report;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: KAppColors.getPrimary(context)),
        ),
      );
    }

    if (_stats == null || _stats!.totalArticlesRead == 0) {
      return _buildEmptyState();
    }

    return Padding(
      padding: KDesignConstants.paddingHorizontalMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reading Streak Card
          const StreakCard(),
          const SizedBox(height: KDesignConstants.spacing16),

          // Weekly Wellness Report
          const WeeklyReportCard(),
          const SizedBox(height: KDesignConstants.spacing16),

          // Main stats cards
          _buildMainStatsRow(),
          const SizedBox(height: KDesignConstants.spacing16),

          // Good News Ratio Card
          _buildGoodNewsRatioCard(),
          const SizedBox(height: KDesignConstants.spacing16),

          // Reading Time Breakdown
          _buildReadingTimeBreakdown(),
          const SizedBox(height: KDesignConstants.spacing16),

          if (_remoteReport != null) ...[
            _buildBackendWellnessSummary(),
            const SizedBox(height: KDesignConstants.spacing16),
          ],

          // Category Breakdown
          _buildCategoryBreakdown(),
          const SizedBox(height: KDesignConstants.spacing16),

          // Recent Activity
          _buildRecentActivity(),
          const SizedBox(height: KDesignConstants.spacing24),

          // Achievements Section
          Builder(
            builder: (context) => Text(
              'Achievements',
              style: KAppTextStyles.headlineMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing16),
          const AchievementsGrid(),
          const SizedBox(height: KDesignConstants.spacing24),

          // Share Stats Button
          Center(
            child: ShareStatsButton(),
          ),
          const SizedBox(height: KDesignConstants.spacing40),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 80,
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
              ),
              const SizedBox(height: KDesignConstants.spacing24),
              Text(
                'No Reading Activity Yet',
                style: KAppTextStyles.headlineMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing12),
              Text(
                'Start reading articles to see your\nwellness statistics here',
                textAlign: TextAlign.center,
                style: KAppTextStyles.bodyLarge.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.article_outlined,
            value: _stats!.totalArticlesRead.toString(),
            label: 'Articles Read',
            color: KAppColors.getPrimary(context),
          ),
        ),
        const SizedBox(width: KDesignConstants.spacing12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule_outlined,
            value: _stats!.formattedTotalTime,
            label: 'Total Time',
            color: KAppColors.getTertiary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: KDesignConstants.spacing12),
          Text(
            value,
            style: KAppTextStyles.displaySmall.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing4),
          Text(
            label,
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoodNewsRatioCard() {
    final ratio = _stats!.goodNewsRatio;
    final percentage = (ratio * 100).toStringAsFixed(0);
    final isHealthy = ratio >= 0.4; // 40% or more positive news is healthy

    return Container(
      padding: KDesignConstants.paddingLg,
      decoration: BoxDecoration(
        color: KAppColors.success.withValues(alpha: 0.15),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: KDesignConstants.paddingMd,
            decoration: BoxDecoration(
              color: KAppColors.success.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHealthy ? Icons.wb_sunny : Icons.cloud_outlined,
              color: KAppColors.success,
              size: 32,
            ),
          ),
          const SizedBox(width: KDesignConstants.spacing20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good News Ratio',
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: KDesignConstants.spacing4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$percentage%',
                      style: KAppTextStyles.displaySmall.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w900,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(width: KDesignConstants.spacing8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        isHealthy ? 'Healthy!' : 'Keep it up!',
                        style: KAppTextStyles.bodyMedium.copyWith(
                          color: KAppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KDesignConstants.spacing4),
                Text(
                  'of articles you read are positive',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackendWellnessSummary() {
    final sessions = (_remoteReport?['readingSessions'] as num?)?.toInt() ?? 0;
    final totalMinutes = (_remoteReport?['totalReadMinutes'] as num?)?.toInt() ?? 0;
    final avgMinutes =
        (_remoteReport?['averageSessionMinutes'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context).withValues(alpha: 0.08),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-day wellness snapshot',
            style: KAppTextStyles.titleMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Row(
            children: [
              Expanded(
                child: _buildSmallStat(
                  icon: Icons.event_repeat_outlined,
                  value: '$sessions',
                  label: 'Sessions',
                  color: KAppColors.getPrimary(context),
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing10),
              Expanded(
                child: _buildSmallStat(
                  icon: Icons.timer_outlined,
                  value: '$totalMinutes min',
                  label: 'Total',
                  color: KAppColors.getTertiary(context),
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing10),
              Expanded(
                child: _buildSmallStat(
                  icon: Icons.av_timer_outlined,
                  value: avgMinutes.toStringAsFixed(1),
                  label: 'Avg/session',
                  color: KAppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadingTimeBreakdown() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: KBorderRadius.xl,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Activity',
              style: KAppTextStyles.titleLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: KDesignConstants.spacing16),
          Row(
            children: [
              Expanded(
                child: _buildSmallStat(
                  icon: Icons.article_outlined,
                  value: _stats!.articlesReadToday.toString(),
                  label: 'Articles',
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: _buildSmallStat(
                  icon: Icons.timer_outlined,
                  value: _stats!.formattedTodayTime,
                  label: 'Reading Time',
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSmallStat({
    required IconData icon,
    required String value,
    required String label,
    Color? color,
  }) {
    return Builder(
      builder: (context) => Container(
        padding: KDesignConstants.paddingMd,
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: KBorderRadius.lg,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color ?? KAppColors.getPrimary(context),
              size: 20,
            ),
            const SizedBox(height: KDesignConstants.spacing8),
            Text(
              value,
              style: KAppTextStyles.titleLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing4),
            Text(
              label,
              style: KAppTextStyles.labelSmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_stats!.categoriesRead.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort categories by count
    final sortedCategories = _stats!.categoriesRead.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 categories
    final topCategories = sortedCategories.take(5).toList();

    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: KBorderRadius.xl,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Categories',
              style: KAppTextStyles.titleLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: KDesignConstants.spacing16),
          ...topCategories.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCategoryBar(
                  entry.key,
                  entry.value,
                  sortedCategories.first.value,
                ),
              )),
        ],
      ),
      ),
    );
  }

  Widget _buildCategoryBar(String category, int count, int maxCount) {
    final percentage = maxCount > 0 ? count / maxCount : 0.0;

    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                count.toString(),
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_stats!.recentSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: KBorderRadius.xl,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Reading',
              style: KAppTextStyles.titleLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: KDesignConstants.spacing16),
          ...(_stats!.recentSessions.take(5).map((session) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRecentSessionItem(session),
            );
          })),
        ],
      ),
      ),
    );
  }

  Widget _buildRecentSessionItem(ReadingSessionModel session) {
    final durationMinutes = (session.durationSeconds / 60).ceil();

    return Builder(
      builder: (context) => Row(
        children: [
          Container(
            padding: KDesignConstants.paddingSm,
            decoration: BoxDecoration(
              color: _getSentimentColor(session.sentiment).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getSentimentIcon(session.sentiment),
              color: _getSentimentColor(session.sentiment),
              size: 16,
            ),
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.articleTitle,
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.category} • ${durationMinutes}m read',
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return KAppColors.success;
      case 'negative':
        return KAppColors.error;
      default:
        return KAppColors.getOnBackground(context).withValues(alpha: 0.5);
    }
  }

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Icons.wb_sunny;
      case 'negative':
        return Icons.cloud;
      default:
        return Icons.remove;
    }
  }
}
