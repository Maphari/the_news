enum GoalPeriod {
  daily,
  weekly,
  monthly,
}

enum GoalType {
  articlesCount, // Number of articles to read
  readingTime, // Minutes of reading time
}

class ReadingGoalModel {
  final int? id;
  final GoalType type;
  final GoalPeriod period;
  final int targetValue; // Articles count or minutes
  final int currentProgress;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isCompleted;

  ReadingGoalModel({
    this.id,
    required this.type,
    required this.period,
    required this.targetValue,
    this.currentProgress = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.isCompleted = false,
  });

  // Calculate progress percentage
  double get progressPercentage {
    if (targetValue == 0) return 0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  // Get progress as percentage string
  String get progressPercentString {
    return '${(progressPercentage * 100).toStringAsFixed(0)}%';
  }

  // Check if goal is achieved
  bool get isAchieved {
    return currentProgress >= targetValue;
  }

  // Get remaining value to achieve goal
  int get remainingValue {
    return (targetValue - currentProgress).clamp(0, targetValue);
  }

  // Get goal description
  String get description {
    final typeText = type == GoalType.articlesCount ? 'articles' : 'minutes';
    final periodText = period == GoalPeriod.daily
        ? 'daily'
        : period == GoalPeriod.weekly
            ? 'weekly'
            : 'monthly';
    return 'Read $targetValue $typeText $periodText';
  }

  // Get goal status message
  String get statusMessage {
    if (isCompleted) {
      return 'Goal completed!';
    } else if (isAchieved) {
      return 'Goal achieved! Mark as complete?';
    } else if (!isActive) {
      return 'Goal inactive';
    } else {
      final typeText = type == GoalType.articlesCount ? 'articles' : 'minutes';
      return '$remainingValue $typeText to go';
    }
  }

  // Check if goal period has ended
  bool get isPeriodEnded {
    return DateTime.now().isAfter(endDate);
  }

  // Days remaining in period
  int get daysRemaining {
    if (isPeriodEnded) return 0;
    return endDate.difference(DateTime.now()).inDays + 1;
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'period': period.name,
      'targetValue': targetValue,
      'currentProgress': currentProgress,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  // Create from Map
  factory ReadingGoalModel.fromMap(Map<String, dynamic> map) {
    return ReadingGoalModel(
      id: map['id'] as int?,
      type: GoalType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GoalType.articlesCount,
      ),
      period: GoalPeriod.values.firstWhere(
        (e) => e.name == map['period'],
        orElse: () => GoalPeriod.daily,
      ),
      targetValue: map['targetValue'] as int,
      currentProgress: map['currentProgress'] as int? ?? 0,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      isActive: (map['isActive'] as int? ?? 1) == 1,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
    );
  }

  // Copy with method
  ReadingGoalModel copyWith({
    int? id,
    GoalType? type,
    GoalPeriod? period,
    int? targetValue,
    int? currentProgress,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isCompleted,
  }) {
    return ReadingGoalModel(
      id: id ?? this.id,
      type: type ?? this.type,
      period: period ?? this.period,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Factory method to create a daily goal
  factory ReadingGoalModel.daily({
    required GoalType type,
    required int targetValue,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return ReadingGoalModel(
      type: type,
      period: GoalPeriod.daily,
      targetValue: targetValue,
      startDate: today,
      endDate: tomorrow,
    );
  }

  // Factory method to create a weekly goal
  factory ReadingGoalModel.weekly({
    required GoalType type,
    required int targetValue,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(Duration(days: 7 - now.weekday));

    return ReadingGoalModel(
      type: type,
      period: GoalPeriod.weekly,
      targetValue: targetValue,
      startDate: today,
      endDate: weekEnd,
    );
  }

  // Factory method to create a monthly goal
  factory ReadingGoalModel.monthly({
    required GoalType type,
    required int targetValue,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return ReadingGoalModel(
      type: type,
      period: GoalPeriod.monthly,
      targetValue: targetValue,
      startDate: today,
      endDate: monthEnd,
    );
  }
}
