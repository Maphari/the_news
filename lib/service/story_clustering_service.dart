import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/story_cluster_model.dart';
import 'package:the_news/service/news_provider_service.dart';

/// Service for clustering articles into stories and identifying different perspectives
class StoryClusteringService extends ChangeNotifier {
  static final StoryClusteringService instance = StoryClusteringService._init();
  StoryClusteringService._init();

  final NewsProviderService _newsProvider = NewsProviderService.instance;
  List<StoryCluster> _storyClusters = [];
  bool _isProcessing = false;

  // Configuration
  static const double _similarityThreshold = 0.4; // Minimum similarity to cluster
  static const int _minArticlesForCluster = 2; // Minimum articles to form a cluster
  static const int _maxClusterAge = 7; // Days to keep clusters active

  List<StoryCluster> get storyClusters => _storyClusters;
  bool get isProcessing => _isProcessing;

  /// Get story clusters sorted by recency
  List<StoryCluster> get recentClusters {
    return _storyClusters
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  }

  /// Get clusters with multiple perspectives
  List<StoryCluster> get multiPerspectiveClusters {
    return _storyClusters
        .where((cluster) => cluster.hasMultiplePerspectives)
        .toList()
      ..sort((a, b) => b.getDiversityScore().compareTo(a.getDiversityScore()));
  }

  /// Initialize and cluster articles
  Future<void> initialize() async {
    try {
      log('🔄 Initializing story clustering...');
      await clusterArticles();
      log('✅ Story clustering complete: ${_storyClusters.length} clusters found');
    } catch (e) {
      log('⚠️ Error initializing story clustering: $e');
    }
  }

  /// Cluster articles into stories based on similarity
  Future<void> clusterArticles() async {
    if (_isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final articles = _newsProvider.articles;
      if (articles.isEmpty) {
        _storyClusters = [];
        _isProcessing = false;
        notifyListeners();
        return;
      }

      log('📊 Clustering ${articles.length} articles...');

      // Filter out old articles
      final recentArticles = _filterRecentArticles(articles);
      log('📅 Processing ${recentArticles.length} recent articles');

      // Create initial clusters using similarity matrix
      final clusters = _createClusters(recentArticles);

      // Enhance clusters with metadata
      _storyClusters = _enhanceClusters(clusters);

      log('🎯 Created ${_storyClusters.length} story clusters');
      log('📰 Multi-perspective clusters: ${multiPerspectiveClusters.length}');

    } catch (e) {
      log('⚠️ Error clustering articles: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Filter articles to only include recent ones
  List<ArticleModel> _filterRecentArticles(List<ArticleModel> articles) {
    final cutoffDate = DateTime.now().subtract(Duration(days: _maxClusterAge));
    return articles
        .where((article) => article.pubDate.isAfter(cutoffDate))
        .toList();
  }

  /// Create clusters using similarity-based algorithm
  List<List<ArticleModel>> _createClusters(List<ArticleModel> articles) {
    final clusters = <List<ArticleModel>>[];
    final processed = <String>{};

    for (var i = 0; i < articles.length; i++) {
      final article = articles[i];

      // Skip if already in a cluster
      if (processed.contains(article.articleId)) continue;

      // Create new cluster starting with this article
      final cluster = <ArticleModel>[article];
      processed.add(article.articleId);

      // Find similar articles
      for (var j = i + 1; j < articles.length; j++) {
        final candidate = articles[j];

        // Skip if already processed
        if (processed.contains(candidate.articleId)) continue;

        // Calculate similarity
        final similarity = _calculateSimilarity(article, candidate);

        // Add to cluster if similar enough
        if (similarity >= _similarityThreshold) {
          cluster.add(candidate);
          processed.add(candidate.articleId);
        }
      }

      // Only keep clusters with minimum articles
      if (cluster.length >= _minArticlesForCluster) {
        clusters.add(cluster);
      }
    }

    return clusters;
  }

  /// Calculate similarity between two articles
  double _calculateSimilarity(ArticleModel a, ArticleModel b) {
    double score = 0.0;
    double totalWeight = 0.0;

    // Title similarity (40% weight)
    const titleWeight = 0.4;
    final titleSimilarity = _calculateTextSimilarity(
      a.title.toLowerCase(),
      b.title.toLowerCase(),
    );
    score += titleSimilarity * titleWeight;
    totalWeight += titleWeight;

    // Keyword overlap (30% weight)
    const keywordWeight = 0.3;
    final keywordSimilarity = _calculateListSimilarity(a.keywords, b.keywords);
    score += keywordSimilarity * keywordWeight;
    totalWeight += keywordWeight;

    // Category overlap (15% weight)
    const categoryWeight = 0.15;
    final categorySimilarity = _calculateListSimilarity(a.category, b.category);
    score += categorySimilarity * categoryWeight;
    totalWeight += categoryWeight;

    // Description similarity (10% weight)
    const descriptionWeight = 0.1;
    final descriptionSimilarity = _calculateTextSimilarity(
      a.description.toLowerCase(),
      b.description.toLowerCase(),
    );
    score += descriptionSimilarity * descriptionWeight;
    totalWeight += descriptionWeight;

    // Time proximity (5% weight) - articles published close together are more likely related
    const timeWeight = 0.05;
    final timeSimilarity = _calculateTimeProximity(a.pubDate, b.pubDate);
    score += timeSimilarity * timeWeight;
    totalWeight += timeWeight;

    return totalWeight > 0 ? score / totalWeight : 0.0;
  }

  /// Calculate text similarity using word overlap
  double _calculateTextSimilarity(String text1, String text2) {
    final words1 = text1.split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();
    final words2 = text2.split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    return union > 0 ? intersection / union : 0.0;
  }

  /// Calculate Jaccard similarity for lists
  double _calculateListSimilarity(List<String> list1, List<String> list2) {
    final set1 = list1.map((s) => s.toLowerCase()).toSet();
    final set2 = list2.map((s) => s.toLowerCase()).toSet();

    if (set1.isEmpty || set2.isEmpty) return 0.0;

    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    return union > 0 ? intersection / union : 0.0;
  }

  /// Calculate time proximity (closer = more similar)
  double _calculateTimeProximity(DateTime date1, DateTime date2) {
    final difference = date1.difference(date2).abs().inHours;

    // Articles within 24 hours: high similarity
    if (difference <= 24) return 1.0;

    // Articles within 48 hours: medium similarity
    if (difference <= 48) return 0.7;

    // Articles within 72 hours: low similarity
    if (difference <= 72) return 0.4;

    // Older: very low similarity
    return 0.1;
  }

  /// Enhance clusters with metadata and story information
  List<StoryCluster> _enhanceClusters(List<List<ArticleModel>> clusters) {
    return clusters.asMap().entries.map((entry) {
      final index = entry.key;
      final articles = entry.value;

      // Generate story title from most common words
      final storyTitle = _generateStoryTitle(articles);

      // Generate story description
      final storyDescription = _generateStoryDescription(articles);

      // Extract common keywords
      final keywords = _extractCommonKeywords(articles);

      // Determine story category
      final category = _determineStoryCategory(articles);

      // Find first and last publication dates
      final sortedByDate = List<ArticleModel>.from(articles)
        ..sort((a, b) => a.pubDate.compareTo(b.pubDate));
      final firstPublished = sortedByDate.first.pubDate;
      final lastUpdated = sortedByDate.last.pubDate;

      return StoryCluster(
        clusterId: 'cluster_${DateTime.now().millisecondsSinceEpoch}_$index',
        storyTitle: storyTitle,
        storyDescription: storyDescription,
        articles: articles,
        firstPublished: firstPublished,
        lastUpdated: lastUpdated,
        keywords: keywords,
        category: category,
      );
    }).toList();
  }

  /// Generate a story title from common words in article titles
  String _generateStoryTitle(List<ArticleModel> articles) {
    // Get all title words
    final allWords = <String>[];
    for (final article in articles) {
      final words = article.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 3)
          .toList();
      allWords.addAll(words);
    }

    // Count word frequency
    final wordFrequency = <String, int>{};
    for (final word in allWords) {
      wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
    }

    // Get most common words (appearing in at least 2 articles)
    final commonWords = wordFrequency.entries
        .where((e) => e.value >= 2)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (commonWords.isEmpty) {
      return articles.first.title.length > 60
          ? '${articles.first.title.substring(0, 60)}...'
          : articles.first.title;
    }

    // Build title from common words
    final titleWords = commonWords.take(5).map((e) => e.key).toList();
    final title = titleWords.join(' ').toUpperCase();

    return title.length > 60 ? '${title.substring(0, 60)}...' : title;
  }

  /// Generate story description
  String _generateStoryDescription(List<ArticleModel> articles) {
    // Use the description from the most recent article
    final latest = articles.reduce((a, b) =>
      a.pubDate.isAfter(b.pubDate) ? a : b
    );

    return latest.description.length > 200
        ? '${latest.description.substring(0, 200)}...'
        : latest.description;
  }

  /// Extract common keywords across articles
  List<String> _extractCommonKeywords(List<ArticleModel> articles) {
    final keywordFrequency = <String, int>{};

    for (final article in articles) {
      for (final keyword in article.keywords) {
        final key = keyword.toLowerCase();
        keywordFrequency[key] = (keywordFrequency[key] ?? 0) + 1;
      }
    }

    // Get keywords that appear in at least 40% of articles
    final threshold = (articles.length * 0.4).ceil();
    return keywordFrequency.entries
        .where((e) => e.value >= threshold)
        .map((e) => e.key)
        .take(10)
        .toList();
  }

  /// Determine the primary category for the story
  StoryCategory _determineStoryCategory(List<ArticleModel> articles) {
    final categoryFrequency = <String, int>{};

    for (final article in articles) {
      for (final category in article.category) {
        final key = category.toLowerCase();
        categoryFrequency[key] = (categoryFrequency[key] ?? 0) + 1;
      }
    }

    if (categoryFrequency.isEmpty) return StoryCategory.general;

    // Get most common category
    final mostCommon = categoryFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Map to StoryCategory enum
    if (mostCommon.contains('politic')) return StoryCategory.politics;
    if (mostCommon.contains('business') || mostCommon.contains('econom')) {
      return StoryCategory.business;
    }
    if (mostCommon.contains('tech')) return StoryCategory.technology;
    if (mostCommon.contains('health')) return StoryCategory.health;
    if (mostCommon.contains('science')) return StoryCategory.science;
    if (mostCommon.contains('entertainment')) return StoryCategory.entertainment;
    if (mostCommon.contains('sport')) return StoryCategory.sports;
    if (mostCommon.contains('world')) return StoryCategory.world;

    return StoryCategory.general;
  }

  /// Get a specific cluster by ID
  StoryCluster? getClusterById(String clusterId) {
    try {
      return _storyClusters.firstWhere((c) => c.clusterId == clusterId);
    } catch (e) {
      return null;
    }
  }

  /// Get clusters for a specific category
  List<StoryCluster> getClustersByCategory(StoryCategory category) {
    return _storyClusters
        .where((cluster) => cluster.category == category)
        .toList()
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  }

  /// Create perspective comparison for a cluster
  PerspectiveComparison? createPerspectiveComparison(StoryCluster cluster) {
    if (!cluster.hasMultiplePerspectives) return null;

    final articlesByBias = cluster.getArticlesByBias();

    // Try to get one article from each bias category
    ArticleModel? leftArticle;
    ArticleModel? centerArticle;
    ArticleModel? rightArticle;

    // Get left-leaning article
    leftArticle = articlesByBias[BiasIndicator.leftLeaning]?.first ??
        articlesByBias[BiasIndicator.centerLeft]?.first;

    // Get center article
    centerArticle = articlesByBias[BiasIndicator.center]?.first;

    // Get right-leaning article
    rightArticle = articlesByBias[BiasIndicator.rightLeaning]?.first ??
        articlesByBias[BiasIndicator.centerRight]?.first;

    // Need at least 2 different perspectives
    if ([leftArticle, centerArticle, rightArticle]
        .where((a) => a != null)
        .length < 2) {
      return null;
    }

    // Use fallbacks if needed
    leftArticle ??= cluster.articles.first;
    centerArticle ??= cluster.articles[cluster.articles.length ~/ 2];
    rightArticle ??= cluster.articles.last;

    // Analyze common and divergent points
    final commonPoints = _findCommonPoints([leftArticle, centerArticle, rightArticle]);
    final divergentPoints = _findDivergentPoints([leftArticle, centerArticle, rightArticle]);
    final uniqueAngles = _findUniqueAngles({
      'left': leftArticle,
      'center': centerArticle,
      'right': rightArticle,
    });

    return PerspectiveComparison(
      comparisonId: 'comparison_${cluster.clusterId}',
      cluster: cluster,
      leftPerspective: leftArticle,
      centerPerspective: centerArticle,
      rightPerspective: rightArticle,
      commonPoints: commonPoints,
      divergentPoints: divergentPoints,
      uniqueAngles: uniqueAngles,
    );
  }

  /// Find common points across perspectives
  List<String> _findCommonPoints(List<ArticleModel> articles) {
    // Find keywords that appear in all articles
    final allKeywords = articles.map((a) =>
      a.keywords.map((k) => k.toLowerCase()).toSet()
    ).toList();

    if (allKeywords.isEmpty) return [];

    final commonKeywords = allKeywords.first;
    for (var i = 1; i < allKeywords.length; i++) {
      commonKeywords.retainAll(allKeywords[i]);
    }

    return commonKeywords.take(5).map((k) =>
      'All sources mention: ${k.toUpperCase()}'
    ).toList();
  }

  /// Find divergent points across perspectives
  List<String> _findDivergentPoints(List<ArticleModel> articles) {
    final points = <String>[];

    // Check sentiment differences
    final sentiments = articles.map((a) => a.sentiment).toSet();
    if (sentiments.length > 1) {
      points.add('Different emotional tones across sources');
    }

    // Check for unique keywords
    for (var i = 0; i < articles.length; i++) {
      final uniqueToThis = articles[i].keywords
          .where((k) => !articles[(i + 1) % articles.length].keywords.contains(k))
          .toList();

      if (uniqueToThis.length > 2) {
        points.add('${articles[i].sourceName} emphasizes different aspects');
      }
    }

    return points.take(5).toList();
  }

  /// Find unique angles from each perspective
  Map<String, List<String>> _findUniqueAngles(Map<String, ArticleModel> perspectives) {
    final uniqueAngles = <String, List<String>>{};

    perspectives.forEach((perspective, article) {
      final otherArticles = perspectives.values
          .where((a) => a.articleId != article.articleId)
          .toList();

      final uniqueKeywords = article.keywords.where((keyword) {
        return !otherArticles.any((other) =>
          other.keywords.any((k) =>
            k.toLowerCase() == keyword.toLowerCase()
          )
        );
      }).take(3).toList();

      if (uniqueKeywords.isNotEmpty) {
        uniqueAngles[perspective] = uniqueKeywords;
      }
    });

    return uniqueAngles;
  }

  /// Refresh clusters
  Future<void> refresh() async {
    await clusterArticles();
  }
}
