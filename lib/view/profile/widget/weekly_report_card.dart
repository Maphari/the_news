import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/wellness_report_model.dart';
import 'package:the_news/service/wellness_report_service.dart';

class WeeklyReportCard extends StatefulWidget {
  const WeeklyReportCard({super.key});

  @override
  State<WeeklyReportCard> createState() => _WeeklyReportCardState();
}

class _WeeklyReportCardState extends State<WeeklyReportCard> {
  final WellnessReportService _reportService = WellnessReportService.instance;
  WeeklyWellnessReport? _currentReport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final report = await _reportService.generateWeeklyReport();
    if (mounted) {
      setState(() {
        _currentReport = report;
        _isLoading = false;
      });
    }
  }

  Color _getScoreColor(String score) {
    switch (score) {
      case 'Excellent':
        return const Color(0xFF4CAF50);
      case 'Great':
        return const Color(0xFF8BC34A);
      case 'Good':
        return const Color(0xFFFFA726);
      case 'Fair':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFFEF5350);
    }
  }

  IconData _getScoreIcon(String score) {
    switch (score) {
      case 'Excellent':
        return Icons.emoji_events;
      case 'Great':
        return Icons.thumb_up;
      case 'Good':
        return Icons.trending_up;
      case 'Fair':
        return Icons.info_outline;
      default:
        return Icons.warning_amber_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: KAppColors.primary),
      );
    }

    if (_currentReport == null) {
      return const SizedBox.shrink();
    }

    final report = _currentReport!;
    final scoreColor = _getScoreColor(report.wellnessScore);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withValues(alpha: 0.2),
            scoreColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with score
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getScoreIcon(report.wellnessScore),
                  color: scoreColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Wellness Score',
                      style: KAppTextStyles.labelMedium.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.wellnessScore,
                      style: KAppTextStyles.headlineMedium.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                report.weekLabel,
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Articles',
                  report.totalArticlesRead.toString(),
                  Icons.article_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Reading Time',
                  '${report.totalReadingTimeMinutes} min',
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Active Days',
                  '${report.daysActive}/7',
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Week over week comparison
          if (report.weekOverWeekComparison['articlesChange'] != 0) ...[
            _buildWeekOverWeekComparison(report),
            const SizedBox(height: 20),
          ],

          // Insights
          if (report.insights.isNotEmpty) ...[
            Text(
              'Key Insights',
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...report.insights.take(3).map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: KAppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight,
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: KAppColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: KAppTextStyles.titleMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
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

  Widget _buildWeekOverWeekComparison(WeeklyWellnessReport report) {
    final articlesChange = report.weekOverWeekComparison['articlesChange'] as int;
    final articlesPercent = report.weekOverWeekComparison['articlesChangePercent'] as int;
    final isPositive = articlesChange > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isPositive
                  ? 'Read $articlesChange more articles than last week'
                  : 'Read ${articlesChange.abs()} fewer articles than last week',
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
              ),
            ),
          ),
          if (articlesPercent.abs() > 0)
            Text(
              '${isPositive ? '+' : ''}$articlesPercent%',
              style: KAppTextStyles.labelMedium.copyWith(
                color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
