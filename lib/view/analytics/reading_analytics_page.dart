import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/reading_analytics_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_news/utils/share_utils.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:the_news/utils/contrast_check.dart';

/// Analytics dashboard showing reading patterns and statistics
class ReadingAnalyticsPage extends StatefulWidget {
  const ReadingAnalyticsPage({super.key});

  @override
  State<ReadingAnalyticsPage> createState() => _ReadingAnalyticsPageState();
}

class _ReadingAnalyticsPageState extends State<ReadingAnalyticsPage> {
  final ReadingAnalyticsService _analyticsService = ReadingAnalyticsService.instance;
  int _selectedDays = 7;


  Future<void> exportAnalytics() async {
    final stats = _analyticsService.getLastNDaysStats(30);
    final topCategories = _analyticsService.getTopCategories(limit: 10);
    final topSources = _analyticsService.getTopSources(limit: 10);

    final csv = StringBuffer();

    // Header
    csv.writeln('Reading Analytics Export');
    csv.writeln('Generated: ${DateTime.now().toString()}');
    csv.writeln('');

    // Overview
    csv.writeln('OVERVIEW');
    csv.writeln('Total Articles Read,${_analyticsService.totalArticlesRead}');
    csv.writeln('Total Reading Time (minutes),${_analyticsService.totalReadingMinutes}');
    csv.writeln('Current Streak (days),${_analyticsService.currentStreak}');
    csv.writeln('Longest Streak (days),${_analyticsService.longestStreak}');
    csv.writeln('');

    // Daily Stats
    csv.writeln('DAILY READING STATS (Last 30 Days)');
    csv.writeln('Date,Articles Read');
    for (var entry in stats.entries) {
      csv.writeln('${entry.key},${entry.value}');
    }
    csv.writeln('');

    // Top Categories
    csv.writeln('TOP CATEGORIES');
    csv.writeln('Category,Articles Read');
    for (var category in topCategories) {
      csv.writeln('${category.key},${category.value}');
    }
    csv.writeln('');

    // Top Sources
    csv.writeln('TOP SOURCES');
    csv.writeln('Source,Articles Read');
    for (var source in topSources) {
      csv.writeln('${source.key},${source.value}');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reading_analytics_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv.toString());

    await ShareUtils.shareFiles(context, [XFile(file.path)], text: 'My Reading Analytics');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: KAppBar(
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          'Reading Analytics',
          style: KAppTextStyles.titleLarge.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await exportAnalytics();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Analytics exported successfully'),
                    backgroundColor: KAppColors.getPrimary(context),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.download_outlined,
              color: KAppColors.getOnBackground(context),
            ),
            tooltip: 'Export Analytics',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _analyticsService,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCards(),
                const SizedBox(height: KDesignConstants.spacing24),
                _buildStreakSection(),
                const SizedBox(height: KDesignConstants.spacing24),
                _buildReadingTrendChart(),
                const SizedBox(height: KDesignConstants.spacing24),
                _buildCategoryBreakdown(),
                const SizedBox(height: KDesignConstants.spacing24),
                _buildTopSources(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Articles Read',
            _analyticsService.totalArticlesRead.toString(),
            Icons.article,
            KAppColors.getPrimary(context),
          ),
        ),
        const SizedBox(width: KDesignConstants.spacing12),
        Expanded(
          child: _buildStatCard(
            'Reading Time',
            '${_analyticsService.totalReadingMinutes} min',
            Icons.access_time,
            KAppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    debugCheckContrast(
      foreground: KAppColors.getOnBackground(context),
      background: color.withValues(alpha: 0.08),
      contextLabel: 'Analytics stat card ($title)',
    );
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: KDesignConstants.spacing12),
          Text(
            value,
            style: KAppTextStyles.displaySmall.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing4),
          Text(
            title,
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KAppColors.warning.withValues(alpha: 0.08),
        borderRadius: KBorderRadius.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: KAppColors.warning.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: KAppColors.warning,
              size: 32,
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
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: KDesignConstants.spacing8),
                Row(
                  children: [
                    _buildStreakBadge(
                      'Current',
                      _analyticsService.currentStreak.toString(),
                      KAppColors.warning,
                    ),
                    const SizedBox(width: KDesignConstants.spacing12),
                    _buildStreakBadge(
                      'Longest',
                      _analyticsService.longestStreak.toString(),
                      KAppColors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: KDesignConstants.spacing4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingTrendChart() {
    final stats = _analyticsService.getLastNDaysStats(_selectedDays);
    final sortedDates = stats.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reading Trend',
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7d')),
                ButtonSegment(value: 14, label: Text('14d')),
                ButtonSegment(value: 30, label: Text('30d')),
              ],
              selected: {_selectedDays},
              onSelectionChanged: (Set<int> selected) {
                setState(() {
                  _selectedDays = selected.first;
                });
              },
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(
                  Size(0, KDesignConstants.tabHeight),
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return KAppColors.getPrimary(context);
                  }
                  return KAppColors.getBackground(context);
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return KAppColors.darkOnBackground;
                  }
                  return KAppColors.getOnBackground(context);
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: KDesignConstants.spacing16),
        Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          decoration: BoxDecoration(
            color: KAppColors.getBackground(context),
            borderRadius: KBorderRadius.lg,
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            ),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: _selectedDays > 7 ? 3 : 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                        final date = sortedDates[value.toInt()];
                        final parts = date.split('-');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${parts[1]}/${parts[2]}',
                            style: TextStyle(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (sortedDates.length - 1).toDouble(),
              minY: 0,
              maxY: (stats.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: sortedDates.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      stats[entry.value]!.toDouble(),
                    );
                  }).toList(),
                  isCurved: true,
                  color: KAppColors.getPrimary(context),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: KAppColors.getPrimary(context).withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    final topCategories = _analyticsService.getTopCategories(limit: 5);

    if (topCategories.isEmpty) {
      return _buildEmptyState('No category data yet', Icons.category);
    }

    final total = topCategories.fold(0, (sum, entry) => sum + entry.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: KAppTextStyles.titleMedium.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: KDesignConstants.spacing16),
        Container(
          padding: const EdgeInsets.all(20),
          height: 280,
          decoration: BoxDecoration(
            color: KAppColors.getBackground(context),
            borderRadius: KBorderRadius.lg,
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sections: topCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final categoryEntry = entry.value;
                      final percentage = (categoryEntry.value / total * 100);
                      final sliceColor = _getCategoryColor(index);
                      debugCheckContrast(
                        foreground: KAppColors.getOnBackground(context),
                        background: sliceColor,
                        contextLabel: 'Analytics pie slice (${categoryEntry.key})',
                        minRatio: 3.0,
                      );

                      return PieChartSectionData(
                        color: sliceColor,
                        value: categoryEntry.value.toDouble(),
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: KAppColors.getOnBackground(context),
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing20),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: topCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final categoryEntry = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(index),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryEntry.key,
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${categoryEntry.value} articles',
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
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopSources() {
    final topSources = _analyticsService.getTopSources(limit: 5);

    if (topSources.isEmpty) {
      return _buildEmptyState('No source data yet', Icons.source);
    }

    final maxCount = topSources.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Sources',
          style: KAppTextStyles.titleMedium.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: KDesignConstants.spacing16),
        Container(
          decoration: BoxDecoration(
            color: KAppColors.getBackground(context),
            borderRadius: KBorderRadius.lg,
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: topSources.asMap().entries.map((entry) {
              final index = entry.key;
              final sourceEntry = entry.value;
              final percentage = (sourceEntry.value / maxCount);

              return Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                    ),
                  Padding(
                    padding: KDesignConstants.paddingMd,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(index).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: _getCategoryColor(index),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: KDesignConstants.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sourceEntry.key,
                                style: KAppTextStyles.bodyMedium.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: KDesignConstants.spacing8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation(_getCategoryColor(index)),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: KDesignConstants.spacing12),
                        Text(
                          '${sourceEntry.value}',
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: KDesignConstants.paddingXl,
      decoration: BoxDecoration(
        color: KAppColors.getBackground(context),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            Text(
              message,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      KAppColors.blue,
      KAppColors.success,
      KAppColors.warning,
      KAppColors.purple,
      KAppColors.pink,
    ];
    return colors[index % colors.length];
  }
}
