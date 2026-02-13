import 'dart:convert';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/content_discovery_model.dart';
import 'package:the_news/model/reading_session_model.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/database_service.dart';

/// Service for content discovery: recommendations, trending, clustering, etc.
class ContentDiscoveryService {
  static final ContentDiscoveryService instance = ContentDiscoveryService._init();
  ContentDiscoveryService._init();

  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  // Cache keys
  static const String _engagementKey = 'article_engagement';
  static const String _trendingKey = 'trending_topics';
  static const String _clustersKey = 'topic_clusters';
  static const String _editorsPicksKey = 'editors_picks';
  static const String _interestProfileKey = 'user_interest_profile';

  // ===== PERSONALIZED RECOMMENDATIONS =====

  /// Get personalized article recommendations for current user
  Future<List<RecommendedArticle>> getPersonalizedRecommendations(
    List<ArticleModel> availableArticles, {
    int limit = 20,
  }) async {
    final userData = await _authService.getCurrentUser();
    if (userData == null) {
      // Return trending for non-logged-in users
      return _getTrendingRecommendations(availableArticles, limit);
    }

    final userId = userData['id'] as String? ?? userData['userId'] as String;
    final interestProfile = await _getUserInterestProfile(userId);
    final readingSessions = await _db.getAllSessions();

    final recommendations = <RecommendedArticle>[];

    for (final article in availableArticles) {
      // Skip already read articles
      final hasRead = readingSessions.any((s) => s.articleId == article.articleId);
      if (hasRead) continue;

      double score = 0.0;
      RecommendationReason? reason;
      String? explanation;

      // Score based on category interest
      if (article.category.isNotEmpty && interestProfile != null) {
        for (final category in article.category) {
          final categoryScore = interestProfile.categoryScores[category] ?? 0.0;
          if (categoryScore > score) {
            score = categoryScore;
            reason = RecommendationReason.basedOnInterests;
            explanation = 'You often read $category articles';
          }
        }
      }

      // Score based on reading history patterns
      final similarScore = _calculateSimilarityScore(article, readingSessions);
      if (similarScore > score) {
        score = similarScore;
        reason = RecommendationReason.basedOnReadingHistory;
        explanation = 'Similar to articles you\'ve read';
      }

      // Boost trending articles
      final trending = await getTrendingTopics();
      final isTrending = trending.any((t) =>
          article.title.toLowerCase().contains(t.topic.toLowerCase()) ||
          article.keywords.any((k) => k.toLowerCase() == t.topic.toLowerCase()));

      if (isTrending) {
        score += 0.3;
        if (reason == null) {
          reason = RecommendationReason.trending;
          explanation = 'Trending topic';
        }
      }

      if (score > 0.1 && reason != null) {
        recommendations.add(RecommendedArticle(
          article: article,
          score: score,
          reason: reason,
          explanation: explanation,
        ));
      }
    }

    // Sort by score and return top recommendations
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  double _calculateSimilarityScore(
    ArticleModel article,
    List<ReadingSessionModel> sessions,
  ) {
    if (sessions.isEmpty) return 0.0;

    double totalScore = 0.0;
    int matches = 0;

    for (final session in sessions.take(50)) {
      // Check category similarity
      if (article.category.contains(session.category)) {
        totalScore += 0.5;
        matches++;
      }

      // Check keyword overlap
      final titleWords = article.title.toLowerCase().split(' ');
      final sessionTitleWords = session.articleTitle.toLowerCase().split(' ');
      final overlap = titleWords.where((w) => sessionTitleWords.contains(w)).length;

      if (overlap > 2) {
        totalScore += 0.3;
        matches++;
      }
    }

    return matches > 0 ? totalScore / matches : 0.0;
  }

  List<RecommendedArticle> _getTrendingRecommendations(
    List<ArticleModel> articles,
    int limit,
  ) {
    // For non-logged-in users, return most recent articles
    final sorted = List<ArticleModel>.from(articles)
      ..sort((a, b) => b.pubDate.compareTo(a.pubDate));

    return sorted.take(limit).map((a) => RecommendedArticle(
      article: a,
      score: 0.5,
      reason: RecommendationReason.trending,
      explanation: 'Latest news',
    )).toList();
  }

  /// Update user interest profile based on reading behavior
  Future<void> updateUserInterests(String articleId, List<String> categories) async {
    final userData = await _authService.getCurrentUser();
    if (userData == null) return;

    final userId = userData['id'] as String? ?? userData['userId'] as String;
    var profile = await _getUserInterestProfile(userId);

    profile ??= UserInterestProfile(
      userId: userId,
      lastUpdated: DateTime.now(),
    );

    // Update category scores (decay old scores, boost new ones)
    final categoryScores = Map<String, double>.from(profile.categoryScores);

    // Decay all scores by 1%
    categoryScores.updateAll((key, value) => value * 0.99);

    // Boost read categories
    for (final category in categories) {
      categoryScores[category] = (categoryScores[category] ?? 0.0) + 0.1;
      categoryScores[category] = categoryScores[category]!.clamp(0.0, 1.0);
    }

    // Save updated profile
    final updatedProfile = UserInterestProfile(
      userId: userId,
      categoryScores: categoryScores,
      topicScores: profile.topicScores,
      preferredPublishers: profile.preferredPublishers,
      lastUpdated: DateTime.now(),
    );

    await _saveUserInterestProfile(updatedProfile);
  }

  Future<UserInterestProfile?> _getUserInterestProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('${_interestProfileKey}_$userId');
      if (data != null) {
        return UserInterestProfile.fromMap(jsonDecode(data));
      }
    } catch (e) {
      dev.log('⚠️ Error loading interest profile: $e');
    }
    return null;
  }

  Future<void> _saveUserInterestProfile(UserInterestProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_interestProfileKey}_${profile.userId}',
        jsonEncode(profile.toMap()),
      );
    } catch (e) {
      dev.log('⚠️ Error saving interest profile: $e');
    }
  }

  // ===== TRENDING TOPICS =====

  /// Get currently trending topics
  Future<List<TrendingTopic>> getTrendingTopics({int limit = 10}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_trendingKey);

      if (data != null) {
        final topics = (jsonDecode(data) as List)
            .map((t) => TrendingTopic.fromMap(t))
            .toList();

        // Sort by trend score
        topics.sort((a, b) => b.trendScore.compareTo(a.trendScore));
        return topics.take(limit).toList();
      }
    } catch (e) {
      dev.log('⚠️ Error loading trending topics: $e');
    }
    return [];
  }

  /// Update trending topics based on recent activity
  Future<void> updateTrendingTopics(List<ArticleModel> recentArticles) async {
    try {
      // Count topic frequency in last 24 hours
      final topicCounts = <String, int>{};
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      for (final article in recentArticles) {
        if (article.pubDate.isAfter(yesterday)) {
          // Extract topics from keywords and categories
          for (final keyword in article.keywords) {
            topicCounts[keyword] = (topicCounts[keyword] ?? 0) + 1;
          }
          for (final category in article.category) {
            topicCounts[category] = (topicCounts[category] ?? 0) + 1;
          }
        }
      }

      // Create trending topics
      final trendingTopics = <TrendingTopic>[];
      for (final entry in topicCounts.entries) {
        if (entry.value >= 3) {
          // Require at least 3 mentions
          trendingTopics.add(TrendingTopic(
            topic: entry.key,
            articleCount: entry.value,
            readCount: 0,
            trendScore: entry.value.toDouble(),
            lastUpdated: DateTime.now(),
          ));
        }
      }

      // Save trending topics
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _trendingKey,
        jsonEncode(trendingTopics.map((t) => t.toMap()).toList()),
      );

      dev.log('✅ Updated trending topics: ${trendingTopics.length} topics');
    } catch (e) {
      dev.log('⚠️ Error updating trending topics: $e');
    }
  }

  // ===== TOPIC CLUSTERING =====

  /// Create topic clusters from articles
  Future<List<TopicCluster>> clusterArticles(List<ArticleModel> articles) async {
    try {
      // Group articles by primary category
      final categoryGroups = <String, List<String>>{};

      for (final article in articles) {
        if (article.category.isNotEmpty) {
          final category = article.category.first;
          categoryGroups[category] = categoryGroups[category] ?? [];
          categoryGroups[category]!.add(article.articleId);
        }
      }

      // Create clusters
      final clusters = <TopicCluster>[];
      for (final entry in categoryGroups.entries) {
        if (entry.value.length >= 2) {
          // Require at least 2 articles
          clusters.add(TopicCluster(
            id: _uuid.v4(),
            mainTopic: entry.key,
            keywords: [entry.key],
            articleIds: entry.value,
            createdAt: DateTime.now(),
            coherenceScore: 0.8,
          ));
        }
      }

      // Save clusters
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _clustersKey,
        jsonEncode(clusters.map((c) => c.toMap()).toList()),
      );

      dev.log('✅ Created ${clusters.length} topic clusters');
      return clusters;
    } catch (e) {
      dev.log('⚠️ Error clustering articles: $e');
      return [];
    }
  }

  /// Get existing topic clusters
  Future<List<TopicCluster>> getTopicClusters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_clustersKey);

      if (data != null) {
        return (jsonDecode(data) as List)
            .map((c) => TopicCluster.fromMap(c))
            .toList();
      }
    } catch (e) {
      dev.log('⚠️ Error loading clusters: $e');
    }
    return [];
  }

  // ===== EDITOR'S PICKS =====

  /// Add an editor's pick
  Future<void> addEditorsPick({
    required String articleId,
    required String reason,
    required String pickedBy,
    int priority = 5,
    DateTime? expiresAt,
  }) async {
    try {
      final pick = EditorsPick(
        id: _uuid.v4(),
        articleId: articleId,
        reason: reason,
        pickedBy: pickedBy,
        pickedAt: DateTime.now(),
        priority: priority,
        expiresAt: expiresAt,
      );

      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_editorsPicksKey);

      List<EditorsPick> picks = [];
      if (data != null) {
        picks = (jsonDecode(data) as List)
            .map((p) => EditorsPick.fromMap(p))
            .where((p) => !p.isExpired)
            .toList();
      }

      picks.add(pick);
      await prefs.setString(
        _editorsPicksKey,
        jsonEncode(picks.map((p) => p.toMap()).toList()),
      );

      dev.log('✅ Added editor\'s pick: $articleId');
    } catch (e) {
      dev.log('⚠️ Error adding editor\'s pick: $e');
    }
  }

  /// Get editor's picks
  Future<List<EditorsPick>> getEditorsPicks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_editorsPicksKey);

      if (data != null) {
        final picks = (jsonDecode(data) as List)
            .map((p) => EditorsPick.fromMap(p))
            .where((p) => !p.isExpired)
            .toList();

        // Sort by priority
        picks.sort((a, b) => b.priority.compareTo(a.priority));
        return picks;
      }
    } catch (e) {
      dev.log('⚠️ Error loading editor\'s picks: $e');
    }
    return [];
  }

  // ===== MOST SHARED =====

  /// Track article engagement (views, reads, shares)
  Future<void> trackEngagement(
    String articleId, {
    bool view = false,
    bool read = false,
    bool share = false,
    bool save = false,
    bool comment = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_engagementKey);

      Map<String, ArticleEngagement> engagements = {};
      if (data != null) {
        final map = jsonDecode(data) as Map<String, dynamic>;
        engagements = map.map((key, value) =>
            MapEntry(key, ArticleEngagement.fromMap(value)));
      }

      var engagement = engagements[articleId] ??
          ArticleEngagement(
            articleId: articleId,
            lastUpdated: DateTime.now(),
          );

      engagement = engagement.copyWith(
        viewCount: view ? engagement.viewCount + 1 : engagement.viewCount,
        readCount: read ? engagement.readCount + 1 : engagement.readCount,
        shareCount: share ? engagement.shareCount + 1 : engagement.shareCount,
        saveCount: save ? engagement.saveCount + 1 : engagement.saveCount,
        commentCount: comment ? engagement.commentCount + 1 : engagement.commentCount,
        lastUpdated: DateTime.now(),
      );

      engagements[articleId] = engagement;

      await prefs.setString(
        _engagementKey,
        jsonEncode(engagements.map((key, value) => MapEntry(key, value.toMap()))),
      );
    } catch (e) {
      dev.log('⚠️ Error tracking engagement: $e');
    }
  }

  /// Get most shared articles this week
  Future<List<ArticleModel>> getMostSharedThisWeek(
    List<ArticleModel> articles, {
    int limit = 10,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_engagementKey);

      if (data != null) {
        final engagements = (jsonDecode(data) as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, ArticleEngagement.fromMap(value)));

        // Filter to last 7 days
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        final recentEngagements = engagements.values
            .where((e) => e.lastUpdated.isAfter(weekAgo))
            .toList();

        // Sort by share count
        recentEngagements.sort((a, b) => b.shareCount.compareTo(a.shareCount));

        // Get corresponding articles
        final mostShared = <ArticleModel>[];
        for (final engagement in recentEngagements.take(limit)) {
          final article = articles.firstWhere(
            (a) => a.articleId == engagement.articleId,
            orElse: () => articles.first,
          );
          if (article.articleId == engagement.articleId) {
            mostShared.add(article);
          }
        }

        return mostShared;
      }
    } catch (e) {
      dev.log('⚠️ Error getting most shared: $e');
    }
    return [];
  }

  /// Get engagement stats for an article
  Future<ArticleEngagement?> getArticleEngagement(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_engagementKey);

      if (data != null) {
        final engagements = (jsonDecode(data) as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, ArticleEngagement.fromMap(value)));

        return engagements[articleId];
      }
    } catch (e) {
      dev.log('⚠️ Error getting engagement: $e');
    }
    return null;
  }

  // ===== CLEAR DATA =====

  /// Clear all discovery data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_engagementKey);
      await prefs.remove(_trendingKey);
      await prefs.remove(_clustersKey);
      await prefs.remove(_editorsPicksKey);

      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_interestProfileKey)) {
          await prefs.remove(key);
        }
      }

      dev.log('🗑️ All content discovery data cleared');
    } catch (e) {
      dev.log('⚠️ Error clearing data: $e');
    }
  }
}
