import 'package:the_news/model/news_article_model.dart';

/// Represents a group of articles covering the same story from different sources/perspectives
class StoryCluster {
  final String clusterId;
  final String storyTitle;
  final String storyDescription;
  final List<ArticleModel> articles;
  final DateTime firstPublished;
  final DateTime lastUpdated;
  final List<String> keywords;
  final StoryCategory category;

  const StoryCluster({
    required this.clusterId,
    required this.storyTitle,
    required this.storyDescription,
    required this.articles,
    required this.firstPublished,
    required this.lastUpdated,
    required this.keywords,
    required this.category,
  });

  /// Get articles grouped by their perspective/bias
  Map<BiasIndicator, List<ArticleModel>> getArticlesByBias() {
    final grouped = <BiasIndicator, List<ArticleModel>>{};

    for (final article in articles) {
      final bias = _determineBias(article);
      grouped[bias] = [...(grouped[bias] ?? []), article];
    }

    return grouped;
  }

  /// Determine the bias of an article based on source credibility
  BiasIndicator _determineBias(ArticleModel article) {
    final credibility = SourceCredibility.getForSource(article.sourceName);
    return credibility.bias;
  }

  /// Get the diversity score (how many different perspectives are represented)
  double getDiversityScore() {
    final uniqueBiases = getArticlesByBias().keys.length;
    return uniqueBiases / BiasIndicator.values.length;
  }

  /// Get the number of articles in this cluster
  int get articleCount => articles.length;

  /// Check if this cluster has multiple perspectives
  bool get hasMultiplePerspectives => getArticlesByBias().keys.length > 1;

  /// Get the most recent article in this cluster
  ArticleModel get latestArticle {
    return articles.reduce((a, b) =>
      a.pubDate.isAfter(b.pubDate) ? a : b
    );
  }

  /// Get the oldest article in this cluster
  ArticleModel get firstArticle {
    return articles.reduce((a, b) =>
      a.pubDate.isBefore(b.pubDate) ? a : b
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clusterId': clusterId,
      'storyTitle': storyTitle,
      'storyDescription': storyDescription,
      'articleIds': articles.map((a) => a.articleId).toList(),
      'firstPublished': firstPublished.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'keywords': keywords,
      'category': category.name,
    };
  }

  factory StoryCluster.fromJson(Map<String, dynamic> json, List<ArticleModel> allArticles) {
    final articleIds = (json['articleIds'] as List).cast<String>();
    final clusterArticles = allArticles
        .where((article) => articleIds.contains(article.articleId))
        .toList();

    return StoryCluster(
      clusterId: json['clusterId'] as String,
      storyTitle: json['storyTitle'] as String,
      storyDescription: json['storyDescription'] as String,
      articles: clusterArticles,
      firstPublished: DateTime.parse(json['firstPublished'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      keywords: (json['keywords'] as List).cast<String>(),
      category: StoryCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => StoryCategory.general,
      ),
    );
  }
}

/// Categories for story clusters
enum StoryCategory {
  politics('Politics', 'Political news and government'),
  business('Business', 'Business and economy'),
  technology('Technology', 'Tech and innovation'),
  health('Health', 'Health and medicine'),
  science('Science', 'Scientific discoveries'),
  entertainment('Entertainment', 'Entertainment and culture'),
  sports('Sports', 'Sports and athletics'),
  world('World', 'International news'),
  general('General', 'General news');

  final String label;
  final String description;

  const StoryCategory(this.label, this.description);
}

/// Bias indicators for news sources
enum BiasIndicator {
  leftLeaning('Left-Leaning', 'Tends to favor progressive perspectives', 0xFFE91E63),
  centerLeft('Center-Left', 'Slightly left of center', 0xFF9C27B0),
  center('Center', 'Balanced and neutral reporting', 0xFF2196F3),
  centerRight('Center-Right', 'Slightly right of center', 0xFFFF9800),
  rightLeaning('Right-Leaning', 'Tends to favor conservative perspectives', 0xFFF44336),
  unknown('Unknown', 'Bias not yet determined', 0xFF9E9E9E);

  final String label;
  final String description;
  final int colorValue;

  const BiasIndicator(this.label, this.description, this.colorValue);
}

/// Source credibility and bias information
class SourceCredibility {
  final String sourceName;
  final BiasIndicator bias;
  final double credibilityScore; // 0.0 to 1.0
  final String credibilityDescription;
  final List<String> strengths;
  final List<String> weaknesses;

  const SourceCredibility({
    required this.sourceName,
    required this.bias,
    required this.credibilityScore,
    required this.credibilityDescription,
    required this.strengths,
    required this.weaknesses,
  });

  /// Get credibility rating label
  String get credibilityRating {
    if (credibilityScore >= 0.8) return 'Very High';
    if (credibilityScore >= 0.6) return 'High';
    if (credibilityScore >= 0.4) return 'Medium';
    if (credibilityScore >= 0.2) return 'Low';
    return 'Very Low';
  }

  /// Database of source credibility ratings
  /// In a real app, this would come from an API or database
  static SourceCredibility getForSource(String sourceName) {
    final sourceMap = _credibilityDatabase[sourceName.toLowerCase()];
    if (sourceMap != null) {
      return sourceMap;
    }

    // Default for unknown sources
    return SourceCredibility(
      sourceName: sourceName,
      bias: BiasIndicator.unknown,
      credibilityScore: 0.5,
      credibilityDescription: 'Credibility not yet assessed',
      strengths: [],
      weaknesses: [],
    );
  }

  /// Static database of source credibility
  static final Map<String, SourceCredibility> _credibilityDatabase = {
    'bbc news': const SourceCredibility(
      sourceName: 'BBC News',
      bias: BiasIndicator.centerLeft,
      credibilityScore: 0.85,
      credibilityDescription: 'Highly credible with rigorous fact-checking',
      strengths: ['Fact-checking', 'Global coverage', 'Transparency'],
      weaknesses: ['Slight UK-centric bias'],
    ),
    'reuters': const SourceCredibility(
      sourceName: 'Reuters',
      bias: BiasIndicator.center,
      credibilityScore: 0.9,
      credibilityDescription: 'One of the most trusted news agencies',
      strengths: ['Objectivity', 'Fact-based reporting', 'Global reach'],
      weaknesses: ['Can be dry', 'Business focus'],
    ),
    'associated press': const SourceCredibility(
      sourceName: 'Associated Press',
      bias: BiasIndicator.center,
      credibilityScore: 0.9,
      credibilityDescription: 'Highly reliable wire service',
      strengths: ['Neutral tone', 'Wide coverage', 'Fast reporting'],
      weaknesses: ['Limited analysis'],
    ),
    'the guardian': const SourceCredibility(
      sourceName: 'The Guardian',
      bias: BiasIndicator.centerLeft,
      credibilityScore: 0.75,
      credibilityDescription: 'Quality journalism with progressive lean',
      strengths: ['Investigative reporting', 'Opinion diversity'],
      weaknesses: ['Editorial bias', 'UK focus'],
    ),
    'cnn': const SourceCredibility(
      sourceName: 'CNN',
      bias: BiasIndicator.centerLeft,
      credibilityScore: 0.7,
      credibilityDescription: 'Major news network with some bias',
      strengths: ['Breaking news', 'Global presence'],
      weaknesses: ['Sensationalism', 'Political lean'],
    ),
    'fox news': const SourceCredibility(
      sourceName: 'Fox News',
      bias: BiasIndicator.rightLeaning,
      credibilityScore: 0.65,
      credibilityDescription: 'Conservative-leaning news network',
      strengths: ['Conservative perspective', 'Political coverage'],
      weaknesses: ['Editorial bias', 'Fact-checking issues'],
    ),
    'the wall street journal': const SourceCredibility(
      sourceName: 'The Wall Street Journal',
      bias: BiasIndicator.centerRight,
      credibilityScore: 0.8,
      credibilityDescription: 'Reputable business journalism',
      strengths: ['Business coverage', 'Investigative work'],
      weaknesses: ['Paywall', 'Conservative editorial'],
    ),
    'the new york times': const SourceCredibility(
      sourceName: 'The New York Times',
      bias: BiasIndicator.centerLeft,
      credibilityScore: 0.8,
      credibilityDescription: 'Prestigious with liberal lean',
      strengths: ['Investigative journalism', 'Quality writing'],
      weaknesses: ['Paywall', 'Urban bias'],
    ),
    'npr': const SourceCredibility(
      sourceName: 'NPR',
      bias: BiasIndicator.centerLeft,
      credibilityScore: 0.85,
      credibilityDescription: 'Public radio with high standards',
      strengths: ['In-depth reporting', 'Multiple perspectives'],
      weaknesses: ['Perceived liberal bias'],
    ),
    'al jazeera': const SourceCredibility(
      sourceName: 'Al Jazeera',
      bias: BiasIndicator.center,
      credibilityScore: 0.75,
      credibilityDescription: 'International perspective on global news',
      strengths: ['Middle East coverage', 'Different viewpoint'],
      weaknesses: ['State funding concerns', 'Regional bias'],
    ),
  };

  Map<String, dynamic> toJson() {
    return {
      'sourceName': sourceName,
      'bias': bias.name,
      'credibilityScore': credibilityScore,
      'credibilityDescription': credibilityDescription,
      'strengths': strengths,
      'weaknesses': weaknesses,
    };
  }

  factory SourceCredibility.fromJson(Map<String, dynamic> json) {
    return SourceCredibility(
      sourceName: json['sourceName'] as String,
      bias: BiasIndicator.values.firstWhere(
        (e) => e.name == json['bias'],
        orElse: () => BiasIndicator.unknown,
      ),
      credibilityScore: json['credibilityScore'] as double,
      credibilityDescription: json['credibilityDescription'] as String,
      strengths: (json['strengths'] as List).cast<String>(),
      weaknesses: (json['weaknesses'] as List).cast<String>(),
    );
  }
}

/// Represents a perspective comparison between articles on the same story
class PerspectiveComparison {
  final String comparisonId;
  final StoryCluster cluster;
  final ArticleModel leftPerspective;
  final ArticleModel centerPerspective;
  final ArticleModel rightPerspective;
  final List<String> commonPoints;
  final List<String> divergentPoints;
  final Map<String, List<String>> uniqueAngles;

  const PerspectiveComparison({
    required this.comparisonId,
    required this.cluster,
    required this.leftPerspective,
    required this.centerPerspective,
    required this.rightPerspective,
    required this.commonPoints,
    required this.divergentPoints,
    required this.uniqueAngles,
  });

  /// Get all articles in this comparison
  List<ArticleModel> get allArticles => [
    leftPerspective,
    centerPerspective,
    rightPerspective,
  ];

  /// Get the bias diversity score
  double get diversityScore {
    final uniqueBiases = <BiasIndicator>{};
    for (final article in allArticles) {
      final credibility = SourceCredibility.getForSource(article.sourceName);
      uniqueBiases.add(credibility.bias);
    }
    return uniqueBiases.length / 3.0; // Max is 3 (left, center, right)
  }

  Map<String, dynamic> toJson() {
    return {
      'comparisonId': comparisonId,
      'cluster': cluster.toJson(),
      'leftPerspectiveId': leftPerspective.articleId,
      'centerPerspectiveId': centerPerspective.articleId,
      'rightPerspectiveId': rightPerspective.articleId,
      'commonPoints': commonPoints,
      'divergentPoints': divergentPoints,
      'uniqueAngles': uniqueAngles,
    };
  }

  factory PerspectiveComparison.fromJson(
    Map<String, dynamic> json,
    List<ArticleModel> allArticles,
  ) {
    final leftArticle = allArticles.firstWhere(
      (a) => a.articleId == json['leftPerspectiveId'],
    );
    final centerArticle = allArticles.firstWhere(
      (a) => a.articleId == json['centerPerspectiveId'],
    );
    final rightArticle = allArticles.firstWhere(
      (a) => a.articleId == json['rightPerspectiveId'],
    );

    return PerspectiveComparison(
      comparisonId: json['comparisonId'] as String,
      cluster: StoryCluster.fromJson(
        json['cluster'] as Map<String, dynamic>,
        allArticles,
      ),
      leftPerspective: leftArticle,
      centerPerspective: centerArticle,
      rightPerspective: rightArticle,
      commonPoints: (json['commonPoints'] as List).cast<String>(),
      divergentPoints: (json['divergentPoints'] as List).cast<String>(),
      uniqueAngles: (json['uniqueAngles'] as Map).map(
        (key, value) => MapEntry(key as String, (value as List).cast<String>()),
      ),
    );
  }
}
