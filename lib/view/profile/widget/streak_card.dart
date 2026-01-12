import 'package:flutter/material.dart';
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
      return const Center(
        child: CircularProgressIndicator(color: KAppColors.primary),
      );
    }

    if (_streak == null || _streak!.currentStreak == 0) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF5722).withValues(alpha: 0.2),
            const Color(0xFFFF9800).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF5722).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Streak icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFF5722),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
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
          const SizedBox(height: 20),

          // Streak status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _streak!.isActiveToday
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: _streak!.isActiveToday
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFFA726),
                  size: 20,
                ),
                const SizedBox(width: 12),
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
          const SizedBox(height: 16),

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
                  color: const Color(0xFFFF5722),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 16),
          Text(
            'Start Your Reading Streak!',
            style: KAppTextStyles.titleLarge.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
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
