import 'package:the_news/constant/theme/default_theme.dart';
import 'package:flutter/material.dart';
import 'package:the_news/service/reading_tracker_service.dart';

class ReadingStatsWidget extends StatefulWidget {
  const ReadingStatsWidget({super.key});

  @override
  State<ReadingStatsWidget> createState() => _ReadingStatsWidgetState();
}

class _ReadingStatsWidgetState extends State<ReadingStatsWidget> {
  final ReadingTrackerService _tracker = ReadingTrackerService.instance;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _tracker.getQuickStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  String _formatReadingTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  String _formatGoodNewsRatio(double ratio) {
    return '${(ratio * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.38),
        ),
      );
    }

    final articlesReadToday = _stats['articlesReadToday'] as int? ?? 0;
    final readingTimeToday = _stats['readingTimeToday'] as int? ?? 0;
    final goodNewsRatio = _stats['goodNewsRatio'] as double? ?? 0.0;

    // Don't show if no reading activity yet
    if (articlesReadToday == 0 && readingTimeToday == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KAppColors.primary.withValues(alpha: 0.15),
            KAppColors.tertiary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KAppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.article_outlined,
            value: articlesReadToday.toString(),
            label: 'Read Today',
            color: KAppColors.primary,
          ),
          Container(
            width: 1,
            height: 40,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
          ),
          _buildStatItem(
            icon: Icons.schedule_outlined,
            value: _formatReadingTime(readingTimeToday),
            label: 'Time Today',
            color: KAppColors.tertiary,
          ),
          if (articlesReadToday > 0) ...[
            Container(
              width: 1,
              height: 40,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
            ),
            _buildStatItem(
              icon: Icons.wb_sunny_outlined,
              value: _formatGoodNewsRatio(goodNewsRatio),
              label: 'Good News',
              color: const Color(0xFF4CAF50),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
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
            style: KAppTextStyles.labelSmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
