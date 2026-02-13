import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/achievement_model.dart';
import 'package:the_news/service/achievements_service.dart';

class StreakCard extends StatefulWidget {
  const StreakCard({super.key});

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> {
  final AchievementsService _achievements = AchievementsService.instance;
  ReadingStreak? _streak;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    await _achievements.initialize();
    if (mounted) {
      setState(() {
        _streak = _achievements.currentStreak;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: KAppColors.getPrimary(context)),
      );
    }

    if (_streak == null || _streak!.currentStreak == 0) {
      return _buildEmptyState();
    }

    return Container(
      padding: KDesignConstants.paddingLg,
      decoration: BoxDecoration(
        color: KAppColors.warning.withValues(alpha: 0.15),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Streak icon and title
          Row(
            children: [
              Container(
                padding: KDesignConstants.paddingSm,
                decoration: BoxDecoration(
                  color: KAppColors.orange.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: KAppColors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading Streak',
                      style: KAppTextStyles.titleMedium.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: KDesignConstants.spacing4),
                    Text(
                      '${_streak!.currentStreak} ${_streak!.currentStreak == 1 ? "day" : "days"}',
                      style: KAppTextStyles.displaySmall.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w900,
                        fontSize: 36,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing20),

          // Streak status
          Container(
            padding: KDesignConstants.paddingMd,
            decoration: BoxDecoration(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
              borderRadius: KBorderRadius.md,
            ),
            child: Row(
              children: [
                Icon(
                  _streak!.isActiveToday
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: _streak!.isActiveToday
                      ? KAppColors.success
                      : KAppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                Expanded(
                  child: Text(
                    _streak!.isActiveToday
                        ? 'You\'ve read today! Streak maintained 🔥'
                        : 'Read today to keep your streak alive!',
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing16),

          // Longest streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Longest Streak:',
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
              ),
              Text(
                '${_streak!.longestStreak} ${_streak!.longestStreak == 1 ? "day" : "days"}',
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: KDesignConstants.paddingLg,
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_fire_department_outlined,
            size: 48,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: KDesignConstants.spacing16),
          Text(
            'Start Your Reading Streak!',
            style: KAppTextStyles.titleLarge.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Text(
            'Read an article today to begin building your mindful reading habit',
            textAlign: TextAlign.center,
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
