import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/achievement_model.dart';
import 'package:the_news/service/achievements_service.dart';

class AchievementsGrid extends StatefulWidget {
  const AchievementsGrid({super.key});

  @override
  State<AchievementsGrid> createState() => _AchievementsGridState();
}

class _AchievementsGridState extends State<AchievementsGrid> {
  final AchievementsService _achievements = AchievementsService.instance;
  List<Achievement> _allAchievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    await _achievements.initialize();
    if (mounted) {
      setState(() {
        _allAchievements = _achievements.allAchievements;
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

    final unlocked = _allAchievements.where((a) => a.isUnlocked).toList();
    final inProgress = _allAchievements
        .where((a) => !a.isUnlocked && a.currentValue > 0)
        .toList();
    final locked = _allAchievements
        .where((a) => !a.isUnlocked && a.currentValue == 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Unlocked',
                unlocked.length.toString(),
                Icons.emoji_events,
                const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(width: KDesignConstants.spacing12),
            Expanded(
              child: _buildStatCard(
                'In Progress',
                inProgress.length.toString(),
                Icons.trending_up,
                KAppColors.getPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: KDesignConstants.spacing24),

        // Unlocked achievements
        if (unlocked.isNotEmpty) ...[
          Text(
            'Unlocked',
            style: KAppTextStyles.titleLarge.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          _buildAchievementsList(unlocked, isUnlocked: true),
          const SizedBox(height: KDesignConstants.spacing24),
        ],

        // In progress achievements
        if (inProgress.isNotEmpty) ...[
          Text(
            'In Progress',
            style: KAppTextStyles.titleLarge.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          _buildAchievementsList(inProgress, isUnlocked: false),
          const SizedBox(height: KDesignConstants.spacing24),
        ],

        // Locked achievements
        if (locked.isNotEmpty) ...[
          Text(
            'Locked',
            style: KAppTextStyles.titleLarge.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          _buildAchievementsList(locked, isUnlocked: false, isLocked: true),
        ],
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: KDesignConstants.spacing8),
          Text(
            value,
            style: KAppTextStyles.displaySmall.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.w900,
              fontSize: 28,
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
    );
  }

  Widget _buildAchievementsList(
    List<Achievement> achievements, {
    required bool isUnlocked,
    bool isLocked = false,
  }) {
    return Column(
      children: achievements.map((achievement) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAchievementCard(achievement, isUnlocked, isLocked),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementCard(
    Achievement achievement,
    bool isUnlocked,
    bool isLocked,
  ) {
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: isUnlocked
            ? achievement.color.withValues(alpha: 0.15)
            : KAppColors.darkOnBackground.withValues(alpha: 0.05),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: isUnlocked
              ? achievement.color.withValues(alpha: 0.3)
              : KAppColors.darkOnBackground.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: KDesignConstants.paddingSm,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? achievement.color.withValues(alpha: 0.3)
                  : KAppColors.darkOnBackground.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              color: isUnlocked
                  ? achievement.color
                  : KAppColors.darkOnBackground.withValues(alpha: 0.3),
              size: 24,
            ),
          ),
          const SizedBox(width: KDesignConstants.spacing16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: KAppTextStyles.titleMedium.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: KDesignConstants.spacing4),
                Text(
                  achievement.description,
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                ),
                if (!isUnlocked && !isLocked) ...[
                  const SizedBox(height: KDesignConstants.spacing8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: achievement.progress,
                      backgroundColor: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        achievement.color,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing4),
                  Text(
                    '${achievement.currentValue}/${achievement.targetValue} (${achievement.progressPercent}%)',
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
