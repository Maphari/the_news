class WeeklyWellnessReport {
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final int totalArticlesRead;
  final int totalReadingTimeSeconds;
  final double averageArticlesPerDay;
  final double averageTimePerDay;
  final double goodNewsRatio;
  final int currentStreak;
  final Map<String, int> categoryBreakdown;
  final List<String> topCategories;
  final int daysActive;
  final Map<String, dynamic> weekOverWeekComparison;
  final List<String> insights;
  final String wellnessScore;

  const WeeklyWellnessReport({
    required this.weekStartDate,
    required this.weekEndDate,
    required this.totalArticlesRead,
    required this.totalReadingTimeSeconds,
    required this.averageArticlesPerDay,
    required this.averageTimePerDay,
    required this.goodNewsRatio,
    required this.currentStreak,
    required this.categoryBreakdown,
    required this.topCategories,
    required this.daysActive,
    required this.weekOverWeekComparison,
    required this.insights,
    required this.wellnessScore,
  });

  int get totalReadingTimeMinutes => totalReadingTimeSeconds ~/ 60;

  String get weekLabel {
    final start = '${weekStartDate.month}/${weekStartDate.day}';
    final end = '${weekEndDate.month}/${weekEndDate.day}';
    return '$start - $end';
  }

  Map<String, dynamic> toMap() {
    return {
      'weekStartDate': weekStartDate.toIso8601String(),
      'weekEndDate': weekEndDate.toIso8601String(),
      'totalArticlesRead': totalArticlesRead,
      'totalReadingTimeSeconds': totalReadingTimeSeconds,
      'averageArticlesPerDay': averageArticlesPerDay,
      'averageTimePerDay': averageTimePerDay,
      'goodNewsRatio': goodNewsRatio,
      'currentStreak': currentStreak,
      'categoryBreakdown': categoryBreakdown,
      'topCategories': topCategories,
      'daysActive': daysActive,
      'weekOverWeekComparison': weekOverWeekComparison,
      'insights': insights,
      'wellnessScore': wellnessScore,
    };
  }

  factory WeeklyWellnessReport.fromMap(Map<String, dynamic> map) {
    return WeeklyWellnessReport(
      weekStartDate: DateTime.parse(map['weekStartDate']),
      weekEndDate: DateTime.parse(map['weekEndDate']),
      totalArticlesRead: map['totalArticlesRead'],
      totalReadingTimeSeconds: map['totalReadingTimeSeconds'],
      averageArticlesPerDay: map['averageArticlesPerDay'],
      averageTimePerDay: map['averageTimePerDay'],
      goodNewsRatio: map['goodNewsRatio'],
      currentStreak: map['currentStreak'],
      categoryBreakdown: Map<String, int>.from(map['categoryBreakdown']),
      topCategories: List<String>.from(map['topCategories']),
      daysActive: map['daysActive'],
      weekOverWeekComparison: Map<String, dynamic>.from(map['weekOverWeekComparison']),
      insights: List<String>.from(map['insights']),
      wellnessScore: map['wellnessScore'],
    );
  }
}
