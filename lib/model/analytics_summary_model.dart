import 'reading_session_model.dart';
import 'reading_streak_model.dart';
import 'reading_goal_model.dart';

class AnalyticsSummaryModel {
  final ReadingStreakModel streak;
  final List<ReadingGoalModel> activeGoals;
  final ReadingStatsModel stats;
  final Map<String, int> categoryDistribution; // Category -> Count
  final Map<DateTime, int> readingHeatmap; // Date -> Minutes
  final List<String> topTopics; // Most frequent topics/keywords
  final MonthComparisonModel? monthComparison;

  AnalyticsSummaryModel({
    required this.streak,
    required this.activeGoals,
    required this.stats,
    required this.categoryDistribution,
    required this.readingHeatmap,
    required this.topTopics,
    this.monthComparison,
  });

  // Get total active goals count
  int get activeGoalsCount => activeGoals.where((g) => g.isActive).length;

  // Get completed goals count
  int get completedGoalsCount => activeGoals.where((g) => g.isCompleted).length;

  // Get goals in progress
  List<ReadingGoalModel> get goalsInProgress =>
      activeGoals.where((g) => g.isActive && !g.isCompleted).toList();

  // Get average progress across all active goals
  double get averageGoalProgress {
    final inProgress = goalsInProgress;
    if (inProgress.isEmpty) return 0.0;

    final totalProgress =
        inProgress.fold(0.0, (sum, goal) => sum + goal.progressPercentage);
    return totalProgress / inProgress.length;
  }

  // Get top category by reading count
  String get topCategory {
    if (categoryDistribution.isEmpty) return 'None';

    final sorted = categoryDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  // Get total articles read this week
  int get articlesThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    return stats.recentSessions
        .where((session) => session.startTime.isAfter(weekStartDate))
        .length;
  }

  // Get total reading time this week (in minutes)
  int get readingTimeThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final sessions = stats.recentSessions
        .where((session) => session.startTime.isAfter(weekStartDate));

    final totalSeconds = sessions.fold(0, (sum, session) => sum + session.durationSeconds);
    return (totalSeconds / 60).round();
  }
}

class MonthComparisonModel {
  final int currentMonthArticles;
  final int previousMonthArticles;
  final int currentMonthMinutes;
  final int previousMonthMinutes;
  final Map<String, int> currentMonthCategories;
  final Map<String, int> previousMonthCategories;

  MonthComparisonModel({
    required this.currentMonthArticles,
    required this.previousMonthArticles,
    required this.currentMonthMinutes,
    required this.previousMonthMinutes,
    required this.currentMonthCategories,
    required this.previousMonthCategories,
  });

  // Calculate article count change percentage
  double get articlesChangePercent {
    if (previousMonthArticles == 0) return 100.0;
    return ((currentMonthArticles - previousMonthArticles) / previousMonthArticles) * 100;
  }

  // Calculate reading time change percentage
  double get minutesChangePercent {
    if (previousMonthMinutes == 0) return 100.0;
    return ((currentMonthMinutes - previousMonthMinutes) / previousMonthMinutes) * 100;
  }

  // Check if articles increased
  bool get articlesIncreased => currentMonthArticles > previousMonthArticles;

  // Check if reading time increased
  bool get minutesIncreased => currentMonthMinutes > previousMonthMinutes;

  // Get comparison message for articles
  String get articlesComparisonMessage {
    if (articlesIncreased) {
      return '+${articlesChangePercent.toStringAsFixed(0)}% from last month';
    } else if (currentMonthArticles < previousMonthArticles) {
      return '${articlesChangePercent.toStringAsFixed(0)}% from last month';
    } else {
      return 'Same as last month';
    }
  }

  // Get comparison message for reading time
  String get minutesComparisonMessage {
    if (minutesIncreased) {
      return '+${minutesChangePercent.toStringAsFixed(0)}% from last month';
    } else if (currentMonthMinutes < previousMonthMinutes) {
      return '${minutesChangePercent.toStringAsFixed(0)}% from last month';
    } else {
      return 'Same as last month';
    }
  }

  // Get top category change
  String? get topCategoryChange {
    if (currentMonthCategories.isEmpty) return null;
    if (previousMonthCategories.isEmpty) return 'New categories explored';

    final currentTop = currentMonthCategories.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    final previousTop = previousMonthCategories.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    if (currentTop == previousTop) {
      return 'Still loving $currentTop';
    } else {
      return 'Switched from $previousTop to $currentTop';
    }
  }
}
