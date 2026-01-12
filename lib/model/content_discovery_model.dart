import 'package:the_news/model/news_article_model.dart';

enum RecommendationReason {
  basedOnReadingHistory,
  basedOnInterests,
  trending,
  editorsPick,
  followedPublisher,
  popularInCategory,
  similarToLiked,
}

class RecommendedArticle {
  final ArticleModel article;
  final double score; // 0.0 to 1.0
  final RecommendationReason reason;
  final String? explanation;

  RecommendedArticle({
    required this.article,
    required this.score,
    required this.reason,
    this.explanation,
  });

  String get reasonLabel {
    switch (reason) {
      case RecommendationReason.basedOnReadingHistory:
        return 'Based on your reading history';
      case RecommendationReason.basedOnInterests:
        return 'Matches your interests';
      case RecommendationReason.trending:
        return 'Trending now';
      case RecommendationReason.editorsPick:
        return 'Editor\'s Pick';
      case RecommendationReason.followedPublisher:
        return 'From publishers you follow';
      case RecommendationReason.popularInCategory:
        return 'Popular in this category';
      case RecommendationReason.similarToLiked:
        return 'Similar to articles you liked';
    }
  }
}

class TrendingTopic {
  final String topic;
  final int articleCount;
  final int readCount;
  final double trendScore; // How fast it's growing
  final List<String> relatedTopics;
  final DateTime lastUpdated;

  TrendingTopic({
    required this.topic,
    required this.articleCount,
    required this.readCount,
    required this.trendScore,
    this.relatedTopics = const [],
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'articleCount': articleCount,
      'readCount': readCount,
      'trendScore': trendScore,
      'relatedTopics': relatedTopics,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory TrendingTopic.fromMap(Map<String, dynamic> map) {
    return TrendingTopic(
      topic: map['topic'] as String,
      articleCount: map['articleCount'] as int,
      readCount: map['readCount'] as int,
      trendScore: map['trendScore'] as double,
      relatedTopics: List<String>.from(map['relatedTopics'] ?? []),
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }
}

class TopicCluster {
  final String id;
  final String mainTopic;
  final List<String> keywords;
  final List<String> articleIds;
  final DateTime createdAt;
  final double coherenceScore; // How related the articles are

  TopicCluster({
    required this.id,
    required this.mainTopic,
    required this.keywords,
    required this.articleIds,
    required this.createdAt,
    this.coherenceScore = 0.0,
  });

  int get articleCount => articleIds.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mainTopic': mainTopic,
      'keywords': keywords,
      'articleIds': articleIds,
      'createdAt': createdAt.toIso8601String(),
      'coherenceScore': coherenceScore,
    };
  }

  factory TopicCluster.fromMap(Map<String, dynamic> map) {
    return TopicCluster(
      id: map['id'] as String,
      mainTopic: map['mainTopic'] as String,
      keywords: List<String>.from(map['keywords'] ?? []),
      articleIds: List<String>.from(map['articleIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      coherenceScore: map['coherenceScore'] as double? ?? 0.0,
    );
  }
}

class EditorsPick {
  final String id;
  final String articleId;
  final String reason;
  final String pickedBy;
  final DateTime pickedAt;
  final int priority; // Higher = more important
  final DateTime? expiresAt;

  EditorsPick({
    required this.id,
    required this.articleId,
    required this.reason,
    required this.pickedBy,
    required this.pickedAt,
    this.priority = 5,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'articleId': articleId,
      'reason': reason,
      'pickedBy': pickedBy,
      'pickedAt': pickedAt.toIso8601String(),
      'priority': priority,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory EditorsPick.fromMap(Map<String, dynamic> map) {
    return EditorsPick(
      id: map['id'] as String,
      articleId: map['articleId'] as String,
      reason: map['reason'] as String,
      pickedBy: map['pickedBy'] as String,
      pickedAt: DateTime.parse(map['pickedAt'] as String),
      priority: map['priority'] as int? ?? 5,
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
    );
  }
}

class ArticleEngagement {
  final String articleId;
  final int viewCount;
  final int readCount;
  final int shareCount;
  final int saveCount;
  final int commentCount;
  final DateTime lastUpdated;

  ArticleEngagement({
    required this.articleId,
    this.viewCount = 0,
    this.readCount = 0,
    this.shareCount = 0,
    this.saveCount = 0,
    this.commentCount = 0,
    required this.lastUpdated,
  });

  double get engagementScore {
    return (viewCount * 0.1) +
        (readCount * 1.0) +
        (shareCount * 3.0) +
        (saveCount * 2.0) +
        (commentCount * 2.5);
  }

  Map<String, dynamic> toMap() {
    return {
      'articleId': articleId,
      'viewCount': viewCount,
      'readCount': readCount,
      'shareCount': shareCount,
      'saveCount': saveCount,
      'commentCount': commentCount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ArticleEngagement.fromMap(Map<String, dynamic> map) {
    return ArticleEngagement(
      articleId: map['articleId'] as String,
      viewCount: map['viewCount'] as int? ?? 0,
      readCount: map['readCount'] as int? ?? 0,
      shareCount: map['shareCount'] as int? ?? 0,
      saveCount: map['saveCount'] as int? ?? 0,
      commentCount: map['commentCount'] as int? ?? 0,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }

  ArticleEngagement copyWith({
    int? viewCount,
    int? readCount,
    int? shareCount,
    int? saveCount,
    int? commentCount,
    DateTime? lastUpdated,
  }) {
    return ArticleEngagement(
      articleId: articleId,
      viewCount: viewCount ?? this.viewCount,
      readCount: readCount ?? this.readCount,
      shareCount: shareCount ?? this.shareCount,
      saveCount: saveCount ?? this.saveCount,
      commentCount: commentCount ?? this.commentCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class UserInterestProfile {
  final String userId;
  final Map<String, double> categoryScores; // Category -> interest score (0-1)
  final Map<String, double> topicScores; // Topic -> interest score (0-1)
  final List<String> preferredPublishers;
  final DateTime lastUpdated;

  UserInterestProfile({
    required this.userId,
    this.categoryScores = const {},
    this.topicScores = const {},
    this.preferredPublishers = const [],
    required this.lastUpdated,
  });

  List<String> get topCategories {
    final sorted = categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }

  List<String> get topTopics {
    final sorted = topicScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'categoryScores': categoryScores,
      'topicScores': topicScores,
      'preferredPublishers': preferredPublishers,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserInterestProfile.fromMap(Map<String, dynamic> map) {
    return UserInterestProfile(
      userId: map['userId'] as String,
      categoryScores: Map<String, double>.from(map['categoryScores'] ?? {}),
      topicScores: Map<String, double>.from(map['topicScores'] ?? {}),
      preferredPublishers: List<String>.from(map['preferredPublishers'] ?? []),
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }
}
