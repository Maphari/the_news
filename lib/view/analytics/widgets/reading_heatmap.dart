import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';

/// Heatmap calendar showing reading activity over time
class ReadingHeatmap extends StatelessWidget {
  const ReadingHeatmap({
    super.key,
    required this.data,
    this.startDate,
  });

  /// Map of date strings to reading counts
  final Map<String, int> data;

  /// Optional start date (defaults to 12 weeks ago)
  final DateTime? startDate;

  @override
  Widget build(BuildContext context) {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 84));
    final weeks = _generateWeeks(start);
    final maxValue = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: KDesignConstants.cardPadding,
          child: Text(
            'Reading Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: KAppColors.getOnBackground(context),
            ),
          ),
        ),

        // Heatmap grid
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: KDesignConstants.paddingHorizontalMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
              Row(
                children: [
                  const SizedBox(width: KDesignConstants.spacing32),
                  ...List.generate(weeks.length, (index) {
                    if (index % 4 == 0) {
                      final weekStart = weeks[index][0];
                      return SizedBox(
                        width: 52,
                        child: Text(
                          _getMonthLabel(weekStart),
                          style: TextStyle(
                            fontSize: 11,
                            color: KAppColors.getOnBackground(context)
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }
                    return const SizedBox(width: 52);
                  }),
                ],
              ),
              const SizedBox(height: KDesignConstants.spacing8),

              // Heatmap rows (one per weekday)
              ...List.generate(7, (dayIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: KDesignConstants.spacing4),
                  child: Row(
                    children: [
                      // Day label
                      SizedBox(
                        width: KDesignConstants.spacing32,
                        child: Text(
                          _getDayLabel(dayIndex),
                          style: TextStyle(
                            fontSize: 11,
                            color: KAppColors.getOnBackground(context)
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),

                      // Week cells
                      ...weeks.map((week) {
                        final date = week[dayIndex];
                        final dateKey = _formatDate(date);
                        final count = data[dateKey] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(right: KDesignConstants.spacing4),
                          child: _HeatmapCell(
                            date: date,
                            count: count,
                            maxValue: maxValue,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),

              const SizedBox(height: KDesignConstants.spacing16),

              // Legend
              Row(
                children: [
                  Text(
                    'Less',
                    style: TextStyle(
                      fontSize: 11,
                      color: KAppColors.getOnBackground(context)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: KDesignConstants.spacing8),
                  ...[0.0, 0.25, 0.5, 0.75, 1.0].map((intensity) {
                    return Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: KDesignConstants.spacing4),
                      decoration: BoxDecoration(
                        color: _getColorForIntensity(intensity, context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                  const SizedBox(width: KDesignConstants.spacing8),
                  Text(
                    'More',
                    style: TextStyle(
                      fontSize: 11,
                      color: KAppColors.getOnBackground(context)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<List<DateTime>> _generateWeeks(DateTime start) {
    final weeks = <List<DateTime>>[];
    final now = DateTime.now();

    // Find the start of the week (Monday)
    var current = start.subtract(Duration(days: start.weekday - 1));

    while (current.isBefore(now)) {
      final week = List.generate(7, (i) => current.add(Duration(days: i)));
      weeks.add(week);
      current = current.add(const Duration(days: 7));
    }

    return weeks;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayLabel(int dayIndex) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayIndex];
  }

  String _getMonthLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[date.month - 1];
  }

  Color _getColorForIntensity(double intensity, BuildContext context) {
    if (intensity == 0.0) {
      return KAppColors.getOnBackground(context).withValues(alpha: 0.1);
    }
    return KAppColors.getPrimary(context).withValues(alpha: 0.2 + (intensity * 0.8));
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({
    required this.date,
    required this.count,
    required this.maxValue,
  });

  final DateTime date;
  final int count;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final intensity = maxValue > 0 ? count / maxValue : 0.0;
    final isToday = _isToday(date);
    final isFuture = date.isAfter(DateTime.now());

    return Tooltip(
      message: '${_formatDate(date)}: $count article${count == 1 ? '' : 's'}',
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: isFuture
              ? Colors.transparent
              : _getColorForIntensity(intensity, context),
          borderRadius: BorderRadius.circular(2),
          border: isToday
              ? Border.all(
                  color: KAppColors.getPrimary(context),
                  width: 1.5,
                )
              : null,
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getColorForIntensity(double intensity, BuildContext context) {
    if (intensity == 0.0) {
      return KAppColors.getOnBackground(context).withValues(alpha: 0.1);
    }
    return KAppColors.getPrimary(context).withValues(alpha: 0.2 + (intensity * 0.8));
  }
}
