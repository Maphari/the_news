import 'dart:developer';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/news_provider_service.dart';

/// Service to find and recommend related articles based on multiple factors
class RelatedArticlesService {
  static final RelatedArticlesService instance = RelatedArticlesService._init();
  RelatedArticlesService._init();

  final NewsProviderService _newsProvider = NewsProviderService.instance;

  /// Get related articles for a given article
  /// Returns up to [limit] articles sorted by relevance
  List<ArticleModel> getRelatedArticles(
    ArticleModel currentArticle, {
    int limit = 5,
  }) {
    final allArticles = _newsProvider.articles;

    // Remove current article from candidates
    final candidates = allArticles
        .where((article) => article.articleId != currentArticle.articleId)
        .toList();

    if (candidates.isEmpty) return [];

    // Calculate relevance score for each candidate
    final scoredArticles = candidates.map((article) {
      final score = _calculateRelevanceScore(currentArticle, article);
      return _ScoredArticle(article: article, score: score);
    }).toList();

    // Sort by score (highest first) and take top N
    scoredArticles.sort((a, b) => b.score.compareTo(a.score));

    final topArticles = scoredArticles
        .take(limit)
        .where((scored) => scored.score > 0) // Only include if some relevance
        .map((scored) => scored.article)
        .toList();

    final titlePreview = currentArticle.title.length > 50
        ? '${currentArticle.title.substring(0, 50)}...'
        : currentArticle.title;
    log('🔗 Found ${topArticles.length} related articles for: $titlePreview');

    return topArticles;
  }

  /// Calculate relevance score between two articles
  /// Higher score = more relevant
  /// Score is weighted combination of:
  /// - Category match (40%)
  /// - Keyword overlap (30%)
  /// - Same source (15%)
  /// - Sentiment similarity (10%)
  /// - Recency (5%)
  double _calculateRelevanceScore(ArticleModel current, ArticleModel candidate) {
    double score = 0.0;

    // 1. Category Match (40 points max)
    final categoryScore = _calculateCategoryScore(current.category, candidate.category);
    score += categoryScore * 40;

    // 2. Keyword Overlap (30 points max)
    final keywordScore = _calculateKeywordScore(current.keywords, candidate.keywords);
    score += keywordScore * 30;

    // 3. Same Source (15 points max)
    if (current.sourceName == candidate.sourceName) {
      score += 15;
    }

    // 4. Sentiment Similarity (10 points max)
    final sentimentScore = _calculateSentimentScore(current.sentiment, candidate.sentiment);
    score += sentimentScore * 10;

    // 5. Recency Bonus (5 points max)
    final recencyScore = _calculateRecencyScore(candidate.pubDate);
    score += recencyScore * 5;

    return score;
  }

  /// Calculate category match score (0.0 to 1.0)
  double _calculateCategoryScore(List<String> currentCategories, List<String> candidateCategories) {
    if (currentCategories.isEmpty || candidateCategories.isEmpty) return 0.0;

    final currentSet = currentCategories.map((c) => c.toLowerCase()).toSet();
    final candidateSet = candidateCategories.map((c) => c.toLowerCase()).toSet();

    final intersection = currentSet.intersection(candidateSet);
    final union = currentSet.union(candidateSet);

    if (union.isEmpty) return 0.0;

    // Jaccard similarity
    return intersection.length / union.length;
  }

  /// Calculate keyword overlap score (0.0 to 1.0)
  double _calculateKeywordScore(List<String> currentKeywords, List<String> candidateKeywords) {
    if (currentKeywords.isEmpty || candidateKeywords.isEmpty) return 0.0;

    final currentSet = currentKeywords.map((k) => k.toLowerCase()).toSet();
    final candidateSet = candidateKeywords.map((k) => k.toLowerCase()).toSet();

    final intersection = currentSet.intersection(candidateSet);

    if (intersection.isEmpty) return 0.0;

    // Calculate overlap percentage (using smaller set as denominator for better matching)
    final smallerSetSize = currentSet.length < candidateSet.length
        ? currentSet.length
        : candidateSet.length;

    return intersection.length / smallerSetSize;
  }

  /// Calculate sentiment similarity score (0.0 to 1.0)
  double _calculateSentimentScore(String currentSentiment, String candidateSentiment) {
    // Exact match
    if (currentSentiment.toLowerCase() == candidateSentiment.toLowerCase()) {
      return 1.0;
    }

    // Partial match (neutral is somewhat similar to both positive and negative)
    final current = currentSentiment.toLowerCase();
    final candidate = candidateSentiment.toLowerCase();

    if (current == 'neutral' || candidate == 'neutral') {
      return 0.5;
    }

    // Different sentiments
    return 0.0;
  }

  /// Calculate recency score (0.0 to 1.0)
  /// More recent articles get higher scores
  double _calculateRecencyScore(DateTime pubDate) {
    final now = DateTime.now();
    final difference = now.difference(pubDate);

    // Articles within 24 hours: score 1.0
    if (difference.inHours <= 24) return 1.0;

    // Articles within 7 days: score 0.7
    if (difference.inDays <= 7) return 0.7;

    // Articles within 30 days: score 0.4
    if (difference.inDays <= 30) return 0.4;

    // Older articles: score 0.1
    return 0.1;
  }

  /// Get related articles by category only
  /// Useful for category browsing pages
  List<ArticleModel> getArticlesByCategory(
    String category, {
    int limit = 10,
    String? excludeArticleId,
  }) {
    final articles = _newsProvider.articles
        .where((article) {
          final matches = article.category
              .map((c) => c.toLowerCase())
              .contains(category.toLowerCase());

          final notExcluded = excludeArticleId == null ||
              article.articleId != excludeArticleId;

          return matches && notExcluded;
        })
        .toList();

    // Sort by publish date (most recent first)
    articles.sort((a, b) => b.pubDate.compareTo(a.pubDate));

    return articles.take(limit).toList();
  }

  /// Get related articles by source
  /// Useful for "More from [Source Name]" sections
  List<ArticleModel> getArticlesBySource(
    String sourceName, {
    int limit = 10,
    String? excludeArticleId,
  }) {
    final articles = _newsProvider.articles
        .where((article) {
          final matches = article.sourceName.toLowerCase() == sourceName.toLowerCase();

          final notExcluded = excludeArticleId == null ||
              article.articleId != excludeArticleId;

          return matches && notExcluded;
        })
        .toList();

    // Sort by publish date (most recent first)
    articles.sort((a, b) => b.pubDate.compareTo(a.pubDate));

    return articles.take(limit).toList();
  }

  /// Get personalized recommendations based on user's reading history
  Future<List<ArticleModel>> getPersonalizedRecommendations({
    required String userId,
    required List<Map<String, dynamic>> readingHistory,
    int limit = 10,
  }) async {
    // Analyze user's reading patterns
    final preferences = _analyzeReadingPreferences(readingHistory);

    // Get all available articles
    final availableArticles = List<ArticleModel>.from(_newsProvider.articles);

    // Filter out articles user has already read
    final readArticleIds = readingHistory
        .map((entry) => entry['articleId'] as String?)
        .whereType<String>()
        .toSet();

    final unreadArticles = availableArticles
        .where((article) => !readArticleIds.contains(article.articleId))
        .toList();

    // Score each article based on user preferences
    final scoredArticles = unreadArticles.map((article) {
      double score = 0.0;

      // 1. Category preference (40% weight)
      for (final category in article.category) {
        final categoryLower = category.toLowerCase();
        if (preferences['topCategories'].containsKey(categoryLower)) {
          score += (preferences['topCategories'][categoryLower]! as double) * 0.4;
          break; // Only count first matching category
        }
      }

      // 2. Source preference (25% weight)
      final source = article.sourceName.toLowerCase();
      if (preferences['topSources'].containsKey(source)) {
        score += (preferences['topSources'][source]! as double) * 0.25;
      }

      // 3. Keyword/topic matching (20% weight)
      final topKeywords = preferences['topKeywords'] as Map<String, double>;
      for (final keyword in topKeywords.keys) {
        if (article.title.toLowerCase().contains(keyword) ||
            article.description.toLowerCase().contains(keyword)) {
          score += topKeywords[keyword]! * 0.20;
        }
      }

      // 4. Recency boost (15% weight) - prefer recent articles
      final daysSincePublish = DateTime.now().difference(article.pubDate).inDays;
      if (daysSincePublish < 1) {
        score += 0.15;
      } else if (daysSincePublish < 3) {
        score += 0.10;
      } else if (daysSincePublish < 7) {
        score += 0.05;
      }

      return _ScoredArticle(article: article, score: score);
    }).toList();

    // Sort by score (highest first)
    scoredArticles.sort((a, b) => b.score.compareTo(a.score));

    // Return top N recommendations
    final recommendations = scoredArticles.take(limit).map((sa) => sa.article).toList();

    // If we don't have enough recommendations, fill with trending/recent articles
    if (recommendations.length < limit) {
      final remaining = limit - recommendations.length;
      final additionalArticles = availableArticles
          .where((article) =>
              !recommendations.contains(article) &&
              !readArticleIds.contains(article.articleId))
          .toList();

      additionalArticles.sort((a, b) => b.pubDate.compareTo(a.pubDate));
      recommendations.addAll(additionalArticles.take(remaining));
    }

    return recommendations;
  }

  /// Analyze user's reading preferences from history
  Map<String, dynamic> _analyzeReadingPreferences(
      List<Map<String, dynamic>> history) {
    final categoryCount = <String, int>{};
    final sourceCount = <String, int>{};
    final keywordCount = <String, int>{};

    int totalReadTime = 0;

    // Analyze reading history
    for (final entry in history) {
      final articleTitle = (entry['articleTitle'] as String?)?.toLowerCase() ?? '';
      final readDuration = entry['readDuration'] as int? ?? 0;

      totalReadTime += readDuration;

      // Extract keywords from title (simple word extraction)
      final words = articleTitle
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(' ')
          .where((word) => word.length > 4) // Only meaningful words
          .toList();

      for (final word in words) {
        keywordCount[word] = (keywordCount[word] ?? 0) + 1;
      }

      // Note: We'd need article metadata (category, source) from history
      // For now, we'll work with what we have
    }

    // Normalize counts to scores (0.0 - 1.0)
    final maxCategoryCount = categoryCount.values.isEmpty
        ? 1
        : categoryCount.values.reduce((a, b) => a > b ? a : b);
    final maxSourceCount =
        sourceCount.values.isEmpty ? 1 : sourceCount.values.reduce((a, b) => a > b ? a : b);
    final maxKeywordCount =
        keywordCount.values.isEmpty ? 1 : keywordCount.values.reduce((a, b) => a > b ? a : b);

    final topCategories = <String, double>{};
    categoryCount.forEach((category, count) {
      topCategories[category] = count / maxCategoryCount;
    });

    final topSources = <String, double>{};
    sourceCount.forEach((source, count) {
      topSources[source] = count / maxSourceCount;
    });

    final topKeywords = <String, double>{};
    // Only keep top 20 keywords
    final sortedKeywords = keywordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedKeywords.take(20)) {
      topKeywords[entry.key] = entry.value / maxKeywordCount;
    }

    return {
      'topCategories': topCategories,
      'topSources': topSources,
      'topKeywords': topKeywords,
      'avgReadTime': history.isEmpty ? 0 : totalReadTime ~/ history.length,
    };
  }
}

/// Internal class to store article with its relevance score
class _ScoredArticle {
  final ArticleModel article;
  final double score;

  _ScoredArticle({required this.article, required this.score});
}
