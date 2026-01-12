import 'package:the_news/model/wellness_report_model.dart';
import 'package:the_news/service/database_service.dart';
import 'package:the_news/service/achievements_service.dart';

class WellnessReportService {
  static final WellnessReportService instance = WellnessReportService._init();
  final DatabaseService _db = DatabaseService.instance;
  final AchievementsService _achievements = AchievementsService.instance;

  WellnessReportService._init();

  // Generate a weekly wellness report
  Future<WeeklyWellnessReport> generateWeeklyReport({DateTime? forDate}) async {
    final date = forDate ?? DateTime.now();
    final weekEnd = date;
    final weekStart = date.subtract(const Duration(days: 7));

    // Gather week statistics
    final sessions = await _db.getSessionsBetweenDates(weekStart, weekEnd);
    final totalArticles = sessions.length;
    final totalTime = sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationSeconds,
    );

    // Calculate days active
    final uniqueDays = sessions.map((s) {
      final date = s.startTime;
      return DateTime(date.year, date.month, date.day);
    }).toSet();
    final daysActive = uniqueDays.length;

    // Category breakdown
    final categoryMap = <String, int>{};
    for (final session in sessions) {
      categoryMap[session.category] = (categoryMap[session.category] ?? 0) + 1;
    }

    // Top 3 categories
    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(3).map((e) => e.key).toList();

    // Good news ratio
    final positiveArticles = sessions.where((s) => s.sentimentPositive > 0.5).length;
    final goodNewsRatio = totalArticles > 0 ? positiveArticles / totalArticles : 0.0;

    // Get current streak
    await _achievements.initialize();
    final streak = _achievements.currentStreak;
    final currentStreakValue = streak.currentStreak;

    // Week-over-week comparison
    final previousWeekStart = weekStart.subtract(const Duration(days: 7));
    final previousWeekSessions = await _db.getSessionsBetweenDates(
      previousWeekStart,
      weekStart,
    );
    final previousWeekArticles = previousWeekSessions.length;
    final previousWeekTime = previousWeekSessions.fold<int>(
      0,
      (sum, session) => sum + session.durationSeconds,
    );

    final articlesChange = totalArticles - previousWeekArticles;
    final timeChange = totalTime - previousWeekTime;

    final weekOverWeek = {
      'articlesChange': articlesChange,
      'articlesChangePercent': previousWeekArticles > 0
          ? ((articlesChange / previousWeekArticles) * 100).toInt()
          : 0,
      'timeChange': timeChange,
      'timeChangePercent': previousWeekTime > 0
          ? ((timeChange / previousWeekTime) * 100).toInt()
          : 0,
    };

    // Generate insights
    final insights = _generateInsights(
      totalArticles: totalArticles,
      totalTime: totalTime,
      daysActive: daysActive,
      goodNewsRatio: goodNewsRatio,
      currentStreak: currentStreakValue,
      articlesChange: articlesChange,
      topCategories: topCategories,
    );

    // Calculate wellness score
    final wellnessScore = _calculateWellnessScore(
      daysActive: daysActive,
      goodNewsRatio: goodNewsRatio,
      averageTimePerDay: totalTime / 7,
      streak: currentStreakValue,
    );

    return WeeklyWellnessReport(
      weekStartDate: weekStart,
      weekEndDate: weekEnd,
      totalArticlesRead: totalArticles,
      totalReadingTimeSeconds: totalTime,
      averageArticlesPerDay: totalArticles / 7,
      averageTimePerDay: totalTime / 7,
      goodNewsRatio: goodNewsRatio,
      currentStreak: currentStreakValue,
      categoryBreakdown: categoryMap,
      topCategories: topCategories,
      daysActive: daysActive,
      weekOverWeekComparison: weekOverWeek,
      insights: insights,
      wellnessScore: wellnessScore,
    );
  }

  // Generate personalized insights
  List<String> _generateInsights({
    required int totalArticles,
    required int totalTime,
    required int daysActive,
    required double goodNewsRatio,
    required int currentStreak,
    required int articlesChange,
    required List<String> topCategories,
  }) {
    final insights = <String>[];

    // Streak insights
    if (currentStreak >= 7) {
      insights.add('Amazing! You maintained a $currentStreak-day reading streak. Keep it up!');
    } else if (currentStreak >= 3) {
      insights.add('You\'re building a great habit with a $currentStreak-day streak!');
    } else if (currentStreak == 0) {
      insights.add('Start a reading streak today to build consistency!');
    }

    // Activity insights
    if (daysActive >= 6) {
      insights.add('Excellent consistency! You read on $daysActive out of 7 days.');
    } else if (daysActive >= 4) {
      insights.add('Good job staying active! Try reading daily to build the habit.');
    } else if (daysActive < 3) {
      insights.add('Try reading more regularly to get the most from your news diet.');
    }

    // Good news ratio insights
    if (goodNewsRatio >= 0.5) {
      insights.add('Great balance! ${(goodNewsRatio * 100).toInt()}% of your reading was positive news.');
    } else if (goodNewsRatio >= 0.3) {
      insights.add('Consider reading more positive stories for better mental wellness.');
    } else {
      insights.add('Your news diet is quite negative. Enable Calm Mode for balance.');
    }

    // Reading time insights
    final avgMinutes = (totalTime / daysActive / 60).toInt();
    if (avgMinutes > 30) {
      insights.add('You spend about $avgMinutes min/day reading. Consider setting a limit.');
    } else if (avgMinutes >= 15) {
      insights.add('Perfect balance at $avgMinutes min/day of reading!');
    }

    // Growth insights
    if (articlesChange > 5) {
      insights.add('You read $articlesChange more articles than last week!');
    } else if (articlesChange < -5) {
      insights.add('Your reading decreased this week. Everything okay?');
    }

    // Category insights
    if (topCategories.isNotEmpty) {
      if (topCategories.length == 1) {
        insights.add('You focused mainly on ${topCategories[0]}. Try exploring other topics!');
      } else {
        insights.add('Great variety! Top interests: ${topCategories.join(", ")}.');
      }
    }

    return insights;
  }

  // Calculate overall wellness score (0-100)
  String _calculateWellnessScore({
    required int daysActive,
    required double goodNewsRatio,
    required double averageTimePerDay,
    required int streak,
  }) {
    int score = 0;

    // Activity score (0-30 points)
    score += (daysActive / 7 * 30).toInt();

    // Good news ratio (0-25 points)
    score += (goodNewsRatio * 25).toInt();

    // Balanced reading time (0-25 points)
    // Optimal: 10-30 minutes per day
    final avgMinutes = averageTimePerDay / 60;
    if (avgMinutes >= 10 && avgMinutes <= 30) {
      score += 25;
    } else if (avgMinutes >= 5 && avgMinutes <= 45) {
      score += 15;
    } else if (avgMinutes > 0) {
      score += 5;
    }

    // Streak bonus (0-20 points)
    if (streak >= 7) {
      score += 20;
    } else if (streak >= 3) {
      score += 15;
    } else if (streak >= 1) {
      score += 10;
    }

    // Convert to grade
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Great';
    if (score >= 55) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  // Get all historical reports (last 4 weeks)
  Future<List<WeeklyWellnessReport>> getHistoricalReports() async {
    final reports = <WeeklyWellnessReport>[];
    final now = DateTime.now();

    for (int i = 0; i < 4; i++) {
      final weekDate = now.subtract(Duration(days: i * 7));
      final report = await generateWeeklyReport(forDate: weekDate);
      reports.add(report);
    }

    return reports;
  }
}
