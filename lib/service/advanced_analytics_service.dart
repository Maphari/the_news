import 'package:the_news/model/reading_session_model.dart';
import 'package:the_news/model/reading_streak_model.dart';
import 'package:the_news/model/reading_goal_model.dart';
import 'package:the_news/model/analytics_summary_model.dart';
import 'package:the_news/service/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdvancedAnalyticsService {
  static final AdvancedAnalyticsService instance = AdvancedAnalyticsService._init();
  final DatabaseService _db = DatabaseService.instance;

  AdvancedAnalyticsService._init();

  // SharedPreferences keys
  static const String _streakKey = 'reading_streak_data';
  static const String _goalsKey = 'reading_goals_data';

  // ===== STREAK CALCULATION =====

  /// Calculate reading streak based on reading sessions
  Future<ReadingStreakModel> calculateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await _db.getAllSessions();

    if (sessions.isEmpty) {
      return ReadingStreakModel(
        currentStreak: 0,
        longestStreak: 0,
      );
    }

    // Get unique reading dates (ignore time)
    final readingDates = <DateTime>{};
    for (final session in sessions) {
      final date = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      readingDates.add(date);
    }

    // Sort dates
    final sortedDates = readingDates.toList()..sort();

    // Calculate current streak
    int currentStreak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Start from most recent date
    DateTime? lastDate = sortedDates.last;
    DateTime? streakStartDate;

    // Check if streak is active (must have read today or yesterday)
    if (lastDate == today || lastDate == yesterday) {
      currentStreak = 1;
      streakStartDate = lastDate;

      // Count backwards
      for (int i = sortedDates.length - 2; i >= 0; i--) {
        final currentDate = sortedDates[i];
        final expectedDate = lastDate!.subtract(const Duration(days: 1));

        if (currentDate == expectedDate) {
          currentStreak++;
          streakStartDate = currentDate;
          lastDate = currentDate;
        } else {
          break;
        }
      }
    }

    // Calculate longest streak
    int longestStreak = currentStreak;
    int tempStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;

      if (diff == 1) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 1;
      }
    }

    final streakModel = ReadingStreakModel(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastReadDate: sortedDates.last,
      streakStartDate: streakStartDate,
      readingDates: sortedDates,
    );

    // Save to preferences
    await prefs.setString(_streakKey, jsonEncode(streakModel.toMap()));

    return streakModel;
  }

  /// Get saved streak data
  Future<ReadingStreakModel> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_streakKey);

    if (data != null) {
      try {
        final map = jsonDecode(data) as Map<String, dynamic>;
        return ReadingStreakModel.fromMap(map);
      } catch (e) {
        // If error, recalculate
        return await calculateStreak();
      }
    }

    // No saved data, calculate fresh
    return await calculateStreak();
  }

  // ===== READING GOALS =====

  /// Save a reading goal
  Future<void> saveGoal(ReadingGoalModel goal) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsData = prefs.getString(_goalsKey);

    List<ReadingGoalModel> goals = [];
    if (goalsData != null) {
      final goalsJson = jsonDecode(goalsData) as List;
      goals = goalsJson.map((g) => ReadingGoalModel.fromMap(g)).toList();
    }

    if (goal.id != null) {
      // Update existing goal
      final index = goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        goals[index] = goal;
      } else {
        goals.add(goal);
      }
    } else {
      // New goal - assign ID
      final newId = goals.isEmpty ? 1 : goals.map((g) => g.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      goals.add(goal.copyWith(id: newId));
    }

    await prefs.setString(_goalsKey, jsonEncode(goals.map((g) => g.toMap()).toList()));
  }

  /// Get all reading goals
  Future<List<ReadingGoalModel>> getGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsData = prefs.getString(_goalsKey);

    if (goalsData != null) {
      try {
        final goalsJson = jsonDecode(goalsData) as List;
        return goalsJson.map((g) => ReadingGoalModel.fromMap(g)).toList();
      } catch (e) {
        return [];
      }
    }

    return [];
  }

  /// Get active goals
  Future<List<ReadingGoalModel>> getActiveGoals() async {
    final goals = await getGoals();
    return goals.where((g) => g.isActive && !g.isCompleted).toList();
  }

  /// Update goal progress
  Future<void> updateGoalProgress() async {
    final goals = await getActiveGoals();

    for (final goal in goals) {
      int progress = 0;

      if (goal.type == GoalType.articlesCount) {
        // Count articles read in the goal period
        final sessions = await _getSessionsInPeriod(goal.startDate, goal.endDate);
        progress = sessions.length;
      } else if (goal.type == GoalType.readingTime) {
        // Calculate minutes read in the goal period
        final sessions = await _getSessionsInPeriod(goal.startDate, goal.endDate);
        final totalSeconds = sessions.fold(0, (sum, s) => sum + s.durationSeconds);
        progress = (totalSeconds / 60).round();
      }

      // Update goal if progress changed
      if (progress != goal.currentProgress) {
        final updatedGoal = goal.copyWith(currentProgress: progress);
        await saveGoal(updatedGoal);
      }

      // Auto-deactivate if period ended
      if (goal.isPeriodEnded && !goal.isCompleted) {
        final updatedGoal = goal.copyWith(isActive: false);
        await saveGoal(updatedGoal);
      }
    }
  }

  /// Mark goal as completed
  Future<void> completeGoal(int goalId) async {
    final goals = await getGoals();
    final index = goals.indexWhere((g) => g.id == goalId);

    if (index != -1) {
      final updatedGoal = goals[index].copyWith(isCompleted: true, isActive: false);
      await saveGoal(updatedGoal);
    }
  }

  /// Delete a goal
  Future<void> deleteGoal(int goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getGoals();
    goals.removeWhere((g) => g.id == goalId);
    await prefs.setString(_goalsKey, jsonEncode(goals.map((g) => g.toMap()).toList()));
  }

  // ===== ANALYTICS SUMMARY =====

  /// Get comprehensive analytics summary
  Future<AnalyticsSummaryModel> getAnalyticsSummary() async {
    final streak = await calculateStreak();
    final activeGoals = await getActiveGoals();
    final stats = await _getReadingStats();
    final categoryDist = await _getCategoryDistribution();
    final heatmap = await _getReadingHeatmap();
    final topTopics = await _getTopTopics();
    final monthComparison = await _getMonthComparison();

    return AnalyticsSummaryModel(
      streak: streak,
      activeGoals: activeGoals,
      stats: stats,
      categoryDistribution: categoryDist,
      readingHeatmap: heatmap,
      topTopics: topTopics,
      monthComparison: monthComparison,
    );
  }

  // ===== HELPER METHODS =====

  Future<List<ReadingSessionModel>> _getSessionsInPeriod(DateTime start, DateTime end) async {
    final allSessions = await _db.getAllSessions();
    return allSessions.where((s) {
      return s.startTime.isAfter(start) && s.startTime.isBefore(end);
    }).toList();
  }

  Future<ReadingStatsModel> _getReadingStats() async {
    final totalArticles = await _db.getTotalArticlesRead();
    final totalTime = await _db.getTotalReadingTime();
    final todayArticles = await _db.getTodayArticlesRead();
    final todayTime = await _db.getTodayReadingTime();
    final goodNewsRatio = await _db.getGoodNewsRatio();
    final categories = await _db.getCategoryBreakdown();
    final recentSessions = await _db.getAllSessions();

    final averageTime = totalArticles > 0 ? (totalTime / totalArticles) / 60.0 : 0.0;

    return ReadingStatsModel(
      totalArticlesRead: totalArticles,
      totalReadingTimeSeconds: totalTime,
      averageReadingTimeMinutes: averageTime,
      articlesReadToday: todayArticles,
      readingTimeToday: todayTime,
      goodNewsRatio: goodNewsRatio,
      categoriesRead: categories,
      recentSessions: recentSessions.take(10).toList(),
    );
  }

  Future<Map<String, int>> _getCategoryDistribution() async {
    return await _db.getCategoryBreakdown();
  }

  Future<Map<DateTime, int>> _getReadingHeatmap() async {
    final sessions = await _db.getAllSessions();
    final heatmap = <DateTime, int>{};

    for (final session in sessions) {
      final date = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );

      final minutes = (session.durationSeconds / 60).round();
      heatmap[date] = (heatmap[date] ?? 0) + minutes;
    }

    return heatmap;
  }

  Future<List<String>> _getTopTopics() async {
    final sessions = await _db.getAllSessions();
    final categories = <String, int>{};

    for (final session in sessions) {
      categories[session.category] = (categories[session.category] ?? 0) + 1;
    }

    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(10).map((e) => e.key).toList();
  }

  Future<MonthComparisonModel?> _getMonthComparison() async {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final previousMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    final currentMonthSessions = await _getSessionsInPeriod(
      currentMonthStart,
      now,
    );

    final previousMonthSessions = await _getSessionsInPeriod(
      previousMonthStart,
      previousMonthEnd,
    );

    final currentMonthArticles = currentMonthSessions.length;
    final previousMonthArticles = previousMonthSessions.length;

    final currentMonthSeconds = currentMonthSessions.fold(0, (sum, s) => sum + s.durationSeconds);
    final previousMonthSeconds = previousMonthSessions.fold(0, (sum, s) => sum + s.durationSeconds);

    final currentMonthCategories = <String, int>{};
    for (final session in currentMonthSessions) {
      currentMonthCategories[session.category] = (currentMonthCategories[session.category] ?? 0) + 1;
    }

    final previousMonthCategories = <String, int>{};
    for (final session in previousMonthSessions) {
      previousMonthCategories[session.category] = (previousMonthCategories[session.category] ?? 0) + 1;
    }

    return MonthComparisonModel(
      currentMonthArticles: currentMonthArticles,
      previousMonthArticles: previousMonthArticles,
      currentMonthMinutes: (currentMonthSeconds / 60).round(),
      previousMonthMinutes: (previousMonthSeconds / 60).round(),
      currentMonthCategories: currentMonthCategories,
      previousMonthCategories: previousMonthCategories,
    );
  }

  // ===== CSV EXPORT =====

  /// Export analytics to CSV format
  Future<String> exportToCSV() async {
    final sessions = await _db.getAllSessions();
    final streak = await getStreak();
    final goals = await getGoals();

    final buffer = StringBuffer();

    // Header
    buffer.writeln('Reading Analytics Export');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    // Streak info
    buffer.writeln('STREAK INFORMATION');
    buffer.writeln('Current Streak,${streak.currentStreak}');
    buffer.writeln('Longest Streak,${streak.longestStreak}');
    buffer.writeln('Last Read Date,${streak.lastReadDate?.toIso8601String() ?? 'N/A'}');
    buffer.writeln('');

    // Goals
    buffer.writeln('READING GOALS');
    buffer.writeln('Type,Period,Target,Progress,Status');
    for (final goal in goals) {
      buffer.writeln('${goal.type.name},${goal.period.name},${goal.targetValue},${goal.currentProgress},${goal.isCompleted ? 'Completed' : 'Active'}');
    }
    buffer.writeln('');

    // Reading sessions
    buffer.writeln('READING SESSIONS');
    buffer.writeln('Date,Title,Category,Duration (seconds),Scroll Depth %,Sentiment');
    for (final session in sessions) {
      buffer.writeln('${session.startTime.toIso8601String()},${_escapeCsv(session.articleTitle)},${session.category},${session.durationSeconds},${session.scrollDepthPercent},${session.sentiment}');
    }

    return buffer.toString();
  }

  String _escapeCsv(String text) {
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}
