class ReadingStreakModel {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReadDate;
  final DateTime? streakStartDate;
  final List<DateTime> readingDates; // All dates with reading activity

  ReadingStreakModel({
    required this.currentStreak,
    required this.longestStreak,
    this.lastReadDate,
    this.streakStartDate,
    this.readingDates = const [],
  });

  // Check if streak is active (read today or yesterday)
  bool get isStreakActive {
    if (lastReadDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastRead = DateTime(
      lastReadDate!.year,
      lastReadDate!.month,
      lastReadDate!.day,
    );

    return lastRead == today || lastRead == yesterday;
  }

  // Check if user read today
  bool get readToday {
    if (lastReadDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastRead = DateTime(
      lastReadDate!.year,
      lastReadDate!.month,
      lastReadDate!.day,
    );

    return lastRead == today;
  }

  // Calculate streak status message
  String get streakStatusMessage {
    if (!isStreakActive) {
      return 'Start a new streak by reading today!';
    } else if (readToday) {
      return 'Great! Keep your streak going tomorrow!';
    } else {
      return 'Read an article today to maintain your streak!';
    }
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastReadDate': lastReadDate?.toIso8601String(),
      'streakStartDate': streakStartDate?.toIso8601String(),
      'readingDates': readingDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  // Create from Map
  factory ReadingStreakModel.fromMap(Map<String, dynamic> map) {
    return ReadingStreakModel(
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      lastReadDate: map['lastReadDate'] != null
          ? DateTime.parse(map['lastReadDate'] as String)
          : null,
      streakStartDate: map['streakStartDate'] != null
          ? DateTime.parse(map['streakStartDate'] as String)
          : null,
      readingDates: map['readingDates'] != null
          ? (map['readingDates'] as List)
              .map((d) => DateTime.parse(d as String))
              .toList()
          : [],
    );
  }

  // Copy with method
  ReadingStreakModel copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastReadDate,
    DateTime? streakStartDate,
    List<DateTime>? readingDates,
  }) {
    return ReadingStreakModel(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      readingDates: readingDates ?? this.readingDates,
    );
  }
}
