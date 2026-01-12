import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/reading_session_model.dart';
import 'package:the_news/service/reading_tracker_service.dart';
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
  ReadingStatsModel? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _tracker.getReadingStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: KAppColors.primary),
        ),
      );
    }

    if (_stats == null || _stats!.totalArticlesRead == 0) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reading Streak Card
          const StreakCard(),
          const SizedBox(height: 16),

          // Weekly Wellness Report
          const WeeklyReportCard(),
          const SizedBox(height: 16),

          // Main stats cards
          _buildMainStatsRow(),
          const SizedBox(height: 16),

          // Good News Ratio Card
          _buildGoodNewsRatioCard(),
          const SizedBox(height: 16),

          // Reading Time Breakdown
          _buildReadingTimeBreakdown(),
          const SizedBox(height: 16),

          // Category Breakdown
          _buildCategoryBreakdown(),
          const SizedBox(height: 16),

          // Recent Activity
          _buildRecentActivity(),
          const SizedBox(height: 24),

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
          const SizedBox(height: 16),
          const AchievementsGrid(),
          const SizedBox(height: 24),

          // Share Stats Button
          Center(
            child: ShareStatsButton(),
          ),
          const SizedBox(height: 40),
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
              const SizedBox(height: 24),
              Text(
                'No Reading Activity Yet',
                style: KAppTextStyles.headlineMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
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
            color: KAppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule_outlined,
            value: _stats!.formattedTotalTime,
            label: 'Total Time',
            color: KAppColors.tertiary,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: KAppTextStyles.displaySmall.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.2),
            const Color(0xFF8BC34A).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHealthy ? Icons.wb_sunny : Icons.cloud_outlined,
              color: const Color(0xFF4CAF50),
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
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
                const SizedBox(height: 4),
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
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        isHealthy ? 'Healthy!' : 'Keep it up!',
                        style: KAppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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

  Widget _buildReadingTimeBreakdown() {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSmallStat(
                  icon: Icons.article_outlined,
                  value: _stats!.articlesReadToday.toString(),
                  label: 'Articles',
                ),
              ),
              const SizedBox(width: 12),
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
  }) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: KAppColors.getPrimary(context), size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: KAppTextStyles.titleLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
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
          borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 16),
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
                gradient: LinearGradient(
                  colors: [
                    KAppColors.getPrimary(context),
                    KAppColors.getTertiary(context),
                  ],
                ),
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
          borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 16),
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
            padding: const EdgeInsets.all(8),
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
          const SizedBox(width: 12),
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
        return const Color(0xFF4CAF50);
      case 'negative':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
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
