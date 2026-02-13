import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/model/analytics_summary_model.dart';
import 'package:the_news/model/reading_goal_model.dart';
import 'package:the_news/service/advanced_analytics_service.dart';
import 'package:the_news/view/analytics/widgets/category_pie_chart.dart';
import 'package:the_news/view/analytics/widgets/reading_heatmap_calendar.dart';
import 'package:the_news/view/analytics/widgets/topics_word_cloud.dart';
import 'package:the_news/view/analytics/widgets/month_comparison_card.dart';
import 'package:the_news/view/analytics/widgets/streak_display_card.dart';
import 'package:the_news/view/analytics/widgets/goals_section.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_news/utils/share_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  final AdvancedAnalyticsService _analyticsService = AdvancedAnalyticsService.instance;
  AnalyticsSummaryModel? _summary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _analyticsService.getAnalyticsSummary();
      await _analyticsService.updateGoalProgress();

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load analytics: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final csv = await _analyticsService.exportToCSV();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/reading_analytics_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      if (mounted) {
        await ShareUtils.shareFiles(
          context,
          [XFile(file.path)],
          text: 'My reading analytics data from The News app',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Analytics exported successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  void _showCreateGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateGoalDialog(
        onGoalCreated: () {
          _loadAnalytics();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KAppBar(
        title: const Text('Reading Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToCSV,
            tooltip: 'Export to CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: KDesignConstants.spacing16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: KDesignConstants.spacing16),
                      FilledButton.icon(
                        onPressed: _loadAnalytics,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    padding: KDesignConstants.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Streak Card
                        StreakDisplayCard(streak: _summary!.streak),
                        const SizedBox(height: KDesignConstants.spacing16),

                        // Quick Stats Row
                        _buildQuickStatsRow(),
                        const SizedBox(height: KDesignConstants.spacing24),

                        // Goals Section
                        GoalsSection(
                          goals: _summary!.activeGoals,
                          onCreateGoal: _showCreateGoalDialog,
                          onRefresh: _loadAnalytics,
                        ),
                        const SizedBox(height: KDesignConstants.spacing24),

                        // Month Comparison
                        if (_summary!.monthComparison != null)
                          MonthComparisonCard(
                            comparison: _summary!.monthComparison!,
                          ),
                        const SizedBox(height: KDesignConstants.spacing24),

                        // Category Distribution Pie Chart
                        Text(
                          'Reading by Category',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: KDesignConstants.spacing12),
                        CategoryPieChart(
                          categoryDistribution: _summary!.categoryDistribution,
                        ),
                        const SizedBox(height: KDesignConstants.spacing24),

                        // Reading Heatmap Calendar
                        Text(
                          'Reading Activity Heatmap',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: KDesignConstants.spacing12),
                        ReadingHeatmapCalendar(
                          heatmapData: _summary!.readingHeatmap,
                        ),
                        const SizedBox(height: KDesignConstants.spacing24),

                        // Topics Word Cloud
                        Text(
                          'Top Topics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: KDesignConstants.spacing12),
                        TopicsWordCloud(
                          topics: _summary!.topTopics,
                        ),
                        const SizedBox(height: KDesignConstants.spacing24),

                        // Additional Stats
                        _buildAdditionalStats(),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: _summary != null
          ? FloatingActionButton.extended(
              onPressed: _showCreateGoalDialog,
              icon: const Icon(Icons.flag),
              label: const Text('New Goal'),
            )
          : null,
    );
  }

  Widget _buildQuickStatsRow() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatCard(
          'Articles Read',
          _summary!.stats.totalArticlesRead.toString(),
          Icons.article,
          colorScheme.primary,
        ),
        const SizedBox(height: KDesignConstants.spacing12),
        _buildStatCard(
          'Total Time',
          _summary!.stats.formattedTotalTime,
          Icons.schedule,
          colorScheme.tertiary,
        ),
        const SizedBox(height: KDesignConstants.spacing12),
        _buildStatCard(
          'This Week',
          '${_summary!.articlesThisWeek} articles',
          Icons.calendar_today,
          colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: KDesignConstants.cardPadding,
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
        borderRadius: KBorderRadius.md,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: KDesignConstants.spacing4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: KAppColors.getOnBackground(context),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalStats() {
    return Card(
      child: Padding(
        padding: KDesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: KDesignConstants.spacing16),
            _buildStatRow('Average Reading Time', '${_summary!.stats.averageReadingTimeMinutes.toStringAsFixed(1)} min'),
            const SizedBox(height: KDesignConstants.spacing8),
            _buildStatRow('Articles Today', '${_summary!.stats.articlesReadToday}'),
            const SizedBox(height: KDesignConstants.spacing8),
            _buildStatRow('Reading Time Today', _summary!.stats.formattedTodayTime),
            const SizedBox(height: KDesignConstants.spacing8),
            _buildStatRow('Good News Ratio', _summary!.stats.goodNewsRatioPercent),
            const SizedBox(height: KDesignConstants.spacing8),
            _buildStatRow('Top Category', _summary!.topCategory),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}

class _CreateGoalDialog extends StatefulWidget {
  final VoidCallback onGoalCreated;

  const _CreateGoalDialog({required this.onGoalCreated});

  @override
  State<_CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<_CreateGoalDialog> {
  final AdvancedAnalyticsService _analyticsService = AdvancedAnalyticsService.instance;
  final _targetController = TextEditingController();

  GoalType _selectedType = GoalType.articlesCount;
  GoalPeriod _selectedPeriod = GoalPeriod.daily;
  bool _isCreating = false;

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _createGoal() async {
    final target = int.tryParse(_targetController.text);
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target value')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      ReadingGoalModel goal;

      switch (_selectedPeriod) {
        case GoalPeriod.daily:
          goal = ReadingGoalModel.daily(type: _selectedType, targetValue: target);
          break;
        case GoalPeriod.weekly:
          goal = ReadingGoalModel.weekly(type: _selectedType, targetValue: target);
          break;
        case GoalPeriod.monthly:
          goal = ReadingGoalModel.monthly(type: _selectedType, targetValue: target);
          break;
      }

      await _analyticsService.saveGoal(goal);

      if (mounted) {
        Navigator.pop(context);
        widget.onGoalCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create goal: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Reading Goal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal Type',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: KDesignConstants.spacing8),
            SegmentedButton<GoalType>(
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(
                  Size(0, KDesignConstants.tabHeight),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: GoalType.articlesCount,
                  label: Text('Articles'),
                  icon: Icon(Icons.article),
                ),
                ButtonSegment(
                  value: GoalType.readingTime,
                  label: Text('Minutes'),
                  icon: Icon(Icons.schedule),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<GoalType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: KDesignConstants.spacing16),
            Text(
              'Period',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: KDesignConstants.spacing8),
            SegmentedButton<GoalPeriod>(
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(
                  Size(0, KDesignConstants.tabHeight),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: GoalPeriod.daily,
                  label: Text('Daily'),
                ),
                ButtonSegment(
                  value: GoalPeriod.weekly,
                  label: Text('Weekly'),
                ),
                ButtonSegment(
                  value: GoalPeriod.monthly,
                  label: Text('Monthly'),
                ),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<GoalPeriod> newSelection) {
                setState(() {
                  _selectedPeriod = newSelection.first;
                });
              },
            ),
            const SizedBox(height: KDesignConstants.spacing16),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target ${_selectedType == GoalType.articlesCount ? 'Articles' : 'Minutes'}',
                hintText: 'Enter target value',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isCreating ? null : _createGoal,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
