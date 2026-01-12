import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReadingHeatmapCalendar extends StatelessWidget {
  final Map<DateTime, int> heatmapData;

  const ReadingHeatmapCalendar({
    super.key,
    required this.heatmapData,
  });

  @override
  Widget build(BuildContext context) {
    if (heatmapData.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No reading activity yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Get last 60 days
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 59));

    // Find max reading time for color scaling
    final maxMinutes = heatmapData.values.isEmpty ? 1 : heatmapData.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Less',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 4),
                _buildColorBox(context, 0.0),
                const SizedBox(width: 2),
                _buildColorBox(context, 0.25),
                const SizedBox(width: 2),
                _buildColorBox(context, 0.5),
                const SizedBox(width: 2),
                _buildColorBox(context, 0.75),
                const SizedBox(width: 2),
                _buildColorBox(context, 1.0),
                const SizedBox(width: 4),
                Text(
                  'More',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Heatmap grid
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildWeekColumns(context, startDate, now, maxMinutes),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeekColumns(BuildContext context, DateTime start, DateTime end, int maxMinutes) {
    final List<Widget> columns = [];
    DateTime currentDate = start;

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      final weekDays = <Widget>[];

      // Add day boxes for this week (up to 7 days)
      for (int i = 0; i < 7 && currentDate.isBefore(end.add(const Duration(days: 1))); i++) {
        final date = DateTime(currentDate.year, currentDate.month, currentDate.day);
        final minutes = heatmapData[date] ?? 0;
        final intensity = maxMinutes > 0 ? (minutes / maxMinutes) : 0.0;

        weekDays.add(
          Padding(
            padding: const EdgeInsets.all(1),
            child: _buildDayBox(context, date, minutes, intensity),
          ),
        );

        currentDate = currentDate.add(const Duration(days: 1));
      }

      columns.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: weekDays,
        ),
      );
    }

    return columns;
  }

  Widget _buildDayBox(BuildContext context, DateTime date, int minutes, double intensity) {
    final color = _getColorForIntensity(context, intensity);

    return Tooltip(
      message: '${DateFormat('MMM d').format(date)}: $minutes min',
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(50),
            width: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildColorBox(BuildContext context, double intensity) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _getColorForIntensity(context, intensity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getColorForIntensity(BuildContext context, double intensity) {
    if (intensity == 0) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }

    final baseColor = Theme.of(context).colorScheme.primary;

    if (intensity < 0.25) {
      return baseColor.withAlpha(50);
    } else if (intensity < 0.5) {
      return baseColor.withAlpha(100);
    } else if (intensity < 0.75) {
      return baseColor.withAlpha(180);
    } else {
      return baseColor;
    }
  }
}
