import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, int> categoryDistribution;

  const CategoryPieChart({
    super.key,
    required this.categoryDistribution,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryDistribution.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: KDesignConstants.spacing16),
              Text(
                'No reading data yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: KDesignConstants.spacing8),
              Text(
                'Start reading articles to see your category distribution',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Sort categories by count and take top 6
    final sortedCategories = categoryDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(6).toList();
    final total = topCategories.fold<int>(0, (sum, entry) => sum + entry.value);

    // Colors for pie chart
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      KAppColors.blue,
      KAppColors.green,
      KAppColors.orange,
    ];

    return Card(
      child: Padding(
        padding: KDesignConstants.cardPadding,
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: topCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    final percentage = (category.value / total * 100);

                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: category.value.toDouble(),
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 100,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing16),
            Wrap(
              spacing: KDesignConstants.spacing12,
              runSpacing: KDesignConstants.spacing8,
              alignment: WrapAlignment.center,
              children: topCategories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;

                return _buildLegendItem(
                  context,
                  category.key,
                  category.value,
                  colors[index % colors.length],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: KDesignConstants.spacing4),
        Text(
          '$label ($count)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
