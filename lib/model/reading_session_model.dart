class ReadingSessionModel {
  final int? id;
  final String articleId;
  final String articleTitle;
  final String category;
  final String sentiment;
  final double sentimentPositive;
  final double sentimentNegative;
  final double sentimentNeutral;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final int scrollDepthPercent;
  final bool wasBookmarked;
  final bool wasShared;

  ReadingSessionModel({
    this.id,
    required this.articleId,
    required this.articleTitle,
    required this.category,
    required this.sentiment,
    required this.sentimentPositive,
    required this.sentimentNegative,
    required this.sentimentNeutral,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.scrollDepthPercent = 0,
    this.wasBookmarked = false,
    this.wasShared = false,
  });

  // Calculate duration in seconds
  int get calculatedDuration {
    if (endTime == null) {
      return DateTime.now().difference(startTime).inSeconds;
    }
    return endTime!.difference(startTime).inSeconds;
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'articleId': articleId,
      'articleTitle': articleTitle,
      'category': category,
      'sentiment': sentiment,
      'sentimentPositive': sentimentPositive,
      'sentimentNegative': sentimentNegative,
      'sentimentNeutral': sentimentNeutral,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'scrollDepthPercent': scrollDepthPercent,
      'wasBookmarked': wasBookmarked ? 1 : 0,
      'wasShared': wasShared ? 1 : 0,
    };
  }

  // Create from Map (database)
  factory ReadingSessionModel.fromMap(Map<String, dynamic> map) {
    return ReadingSessionModel(
      id: map['id'] as int?,
      articleId: map['articleId'] as String,
      articleTitle: map['articleTitle'] as String,
      category: map['category'] as String,
      sentiment: map['sentiment'] as String,
      sentimentPositive: map['sentimentPositive'] as double,
      sentimentNegative: map['sentimentNegative'] as double,
      sentimentNeutral: map['sentimentNeutral'] as double,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
      durationSeconds: map['durationSeconds'] as int,
      scrollDepthPercent: map['scrollDepthPercent'] as int,
      wasBookmarked: (map['wasBookmarked'] as int) == 1,
      wasShared: (map['wasShared'] as int) == 1,
    );
  }

  // Copy with method for updates
  ReadingSessionModel copyWith({
    int? id,
    String? articleId,
    String? articleTitle,
    String? category,
    String? sentiment,
    double? sentimentPositive,
    double? sentimentNegative,
    double? sentimentNeutral,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    int? scrollDepthPercent,
    bool? wasBookmarked,
    bool? wasShared,
  }) {
    return ReadingSessionModel(
      id: id ?? this.id,
      articleId: articleId ?? this.articleId,
      articleTitle: articleTitle ?? this.articleTitle,
      category: category ?? this.category,
      sentiment: sentiment ?? this.sentiment,
      sentimentPositive: sentimentPositive ?? this.sentimentPositive,
      sentimentNegative: sentimentNegative ?? this.sentimentNegative,
      sentimentNeutral: sentimentNeutral ?? this.sentimentNeutral,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      scrollDepthPercent: scrollDepthPercent ?? this.scrollDepthPercent,
      wasBookmarked: wasBookmarked ?? this.wasBookmarked,
      wasShared: wasShared ?? this.wasShared,
    );
  }
}

// Reading statistics model for aggregated data
class ReadingStatsModel {
  final int totalArticlesRead;
  final int totalReadingTimeSeconds;
  final double averageReadingTimeMinutes;
  final int articlesReadToday;
  final int readingTimeToday;
  final double goodNewsRatio; // Percentage of positive articles read
  final Map<String, int> categoriesRead; // Category -> Count
  final List<ReadingSessionModel> recentSessions;

  ReadingStatsModel({
    required this.totalArticlesRead,
    required this.totalReadingTimeSeconds,
    required this.averageReadingTimeMinutes,
    required this.articlesReadToday,
    required this.readingTimeToday,
    required this.goodNewsRatio,
    required this.categoriesRead,
    required this.recentSessions,
  });

  // Format total reading time
  String get formattedTotalTime {
    final hours = totalReadingTimeSeconds ~/ 3600;
    final minutes = (totalReadingTimeSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Format today's reading time
  String get formattedTodayTime {
    final hours = readingTimeToday ~/ 3600;
    final minutes = (readingTimeToday % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get good news ratio as percentage string
  String get goodNewsRatioPercent {
    return '${(goodNewsRatio * 100).toStringAsFixed(0)}%';
  }
}
