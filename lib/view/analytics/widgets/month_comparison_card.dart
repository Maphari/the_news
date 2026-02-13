import 'package:flutter/material.dart';
import 'package:the_news/model/analytics_summary_model.dart';
import 'package:the_news/constant/design_constants.dart';

class MonthComparisonCard extends StatelessWidget {
  final MonthComparisonModel comparison;

  const MonthComparisonCard({
    super.key,
    required this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: KDesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Month-over-Month Comparison',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: KDesignConstants.spacing16),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonStat(
                    context,
                    'Articles Read',
                    comparison.currentMonthArticles.toString(),
                    comparison.articlesComparisonMessage,
                    comparison.articlesIncreased,
                  ),
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                Expanded(
                  child: _buildComparisonStat(
                    context,
                    'Reading Time',
                    '${comparison.currentMonthMinutes} min',
                    comparison.minutesComparisonMessage,
                    comparison.minutesIncreased,
                  ),
                ),
              ],
            ),
            if (comparison.topCategoryChange != null) ...[
              const SizedBox(height: KDesignConstants.spacing16),
              Container(
                padding: KDesignConstants.cardPaddingCompact,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: KBorderRadius.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.category,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: KDesignConstants.spacing12),
                    Expanded(
                      child: Text(
                        comparison.topCategoryChange!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonStat(
    BuildContext context,
    String label,
    String currentValue,
    String comparison,
    bool increased,
  ) {
    return Container(
      padding: KDesignConstants.cardPaddingCompact,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: KBorderRadius.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Text(
            currentValue,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: KDesignConstants.spacing4),
          Row(
            children: [
              Icon(
                increased ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: increased ? Colors.green : Colors.red,
              ),
              const SizedBox(width: KDesignConstants.spacing4),
              Expanded(
                child: Text(
                  comparison,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: increased ? Colors.green : Colors.red,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
