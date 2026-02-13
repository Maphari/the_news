import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/database_service.dart';

class WellnessSummaryCard extends StatefulWidget {
  const WellnessSummaryCard({super.key});

  @override
  State<WellnessSummaryCard> createState() => _WellnessSummaryCardState();
}

class _WellnessSummaryCardState extends State<WellnessSummaryCard> {
  int _articlesReadToday = 0;
  int _readingTimeToday = 0;
  int _currentStreak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWellnessData();
  }

  Future<void> _loadWellnessData() async {
    final db = DatabaseService.instance;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Get today's sessions
    final sessions = await db.getSessionsByDateRange(todayStart, todayEnd);

    // Calculate stats
    double totalTime = 0;
    for (var session in sessions) {
      totalTime += session.durationSeconds.toDouble();
    }

    // Get streak
    final streak = await db.getCurrentStreak();

    if (mounted) {
      setState(() {
        _articlesReadToday = sessions.length;
        _readingTimeToday = (totalTime / 60).round(); // Convert to minutes
        _currentStreak = streak;
        _isLoading = false;
      });
    }
  }

  String _getWellnessMessage() {
    if (_articlesReadToday == 0) {
      return "Start your mindful reading journey";
    } else if (_articlesReadToday >= 10) {
      return "Time for a break! You've read a lot today";
    } else if (_articlesReadToday >= 5) {
      return "Great progress! Stay balanced";
    } else {
      return "You're on the right track";
    }
  }

  Color _getWellnessColor() {
    if (_articlesReadToday >= 10) {
      return KAppColors.error;
    } else if (_articlesReadToday >= 5) {
      return KAppColors.warning;
    } else {
      return KAppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final wellnessColor = _getWellnessColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: wellnessColor.withValues(alpha: 0.1),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: wellnessColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: KDesignConstants.paddingSm,
                decoration: BoxDecoration(
                  color: wellnessColor.withValues(alpha: 0.2),
                  borderRadius: KBorderRadius.md,
                ),
                child: Icon(
                  Icons.favorite_outline,
                  color: wellnessColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Wellness',
                      style: KAppTextStyles.titleMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getWellnessMessage(),
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing16),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  icon: Icons.article_outlined,
                  value: '$_articlesReadToday',
                  label: 'Read Today',
                  color: KAppColors.getPrimary(context),
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: _buildStat(
                  icon: Icons.schedule_outlined,
                  value: '${_readingTimeToday}m',
                  label: 'Time Spent',
                  color: KAppColors.getTertiary(context),
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: _buildStat(
                  icon: Icons.local_fire_department_outlined,
                  value: '$_currentStreak',
                  label: 'Day Streak',
                  color: KAppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: KDesignConstants.paddingSm,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: KAppTextStyles.titleMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
