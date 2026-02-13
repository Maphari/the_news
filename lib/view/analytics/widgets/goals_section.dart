import 'package:flutter/material.dart';
import 'package:the_news/model/reading_goal_model.dart';
import 'package:the_news/service/advanced_analytics_service.dart';
import 'package:the_news/constant/design_constants.dart';

class GoalsSection extends StatelessWidget {
  final List<ReadingGoalModel> goals;
  final VoidCallback onCreateGoal;
  final VoidCallback onRefresh;

  const GoalsSection({
    super.key,
    required this.goals,
    required this.onCreateGoal,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reading Goals',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (goals.isEmpty)
              TextButton.icon(
                onPressed: onCreateGoal,
                icon: const Icon(Icons.add),
                label: const Text('Create Goal'),
              ),
          ],
        ),
        const SizedBox(height: KDesignConstants.spacing12),
        if (goals.isEmpty)
          Card(
            child: Padding(
              padding: KDesignConstants.paddingLg,
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: KDesignConstants.spacing12),
                    Text(
                      'No active goals',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: KDesignConstants.spacing8),
                    Text(
                      'Create a goal to track your reading progress',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...goals.map((goal) => _GoalCard(
                goal: goal,
                onRefresh: onRefresh,
              )),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final ReadingGoalModel goal;
  final VoidCallback onRefresh;

  const _GoalCard({
    required this.goal,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: KDesignConstants.spacing12),
      child: Padding(
        padding: KDesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  goal.type == GoalType.articlesCount
                      ? Icons.article
                      : Icons.schedule,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.description,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: KDesignConstants.spacing4),
                      Text(
                        goal.statusMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: goal.isAchieved
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (goal.isAchieved && !goal.isCompleted)
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _completeGoal(context),
                  ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: KDesignConstants.spacing8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteGoal(context);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${goal.currentProgress} / ${goal.targetValue}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      goal.progressPercentString,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: KDesignConstants.spacing8),
                LinearProgressIndicator(
                  value: goal.progressPercentage,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            if (goal.isActive && !goal.isPeriodEnded) ...[
              const SizedBox(height: KDesignConstants.spacing8),
              Text(
                '${goal.daysRemaining} days remaining',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _completeGoal(BuildContext context) async {
    try {
      await AdvancedAnalyticsService.instance.completeGoal(goal.id!);
      onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal completed! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteGoal(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdvancedAnalyticsService.instance.deleteGoal(goal.id!);
        onRefresh();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }
}
