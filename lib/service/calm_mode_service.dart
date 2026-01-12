import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:the_news/model/news_article_model.dart';

class CalmModeService {
  static final CalmModeService instance = CalmModeService._init();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _calmModeKey = 'calm_mode_enabled';
  static const String _readingLimitKey = 'daily_reading_limit_minutes';

  bool _isCalmModeEnabled = false;
  int _dailyReadingLimit = 30; // Default 30 minutes

  CalmModeService._init();

  // Initialize and load saved preferences
  Future<void> initialize() async {
    final calmModeValue = await _storage.read(key: _calmModeKey);
    _isCalmModeEnabled = calmModeValue == 'true';

    final limitValue = await _storage.read(key: _readingLimitKey);
    if (limitValue != null) {
      _dailyReadingLimit = int.tryParse(limitValue) ?? 30;
    }
  }

  // Calm Mode getters and setters
  bool get isCalmModeEnabled => _isCalmModeEnabled;

  Future<void> setCalmMode(bool enabled) async {
    _isCalmModeEnabled = enabled;
    await _storage.write(key: _calmModeKey, value: enabled.toString());
  }

  Future<void> toggleCalmMode() async {
    await setCalmMode(!_isCalmModeEnabled);
  }

  // Reading limit getters and setters
  int get dailyReadingLimit => _dailyReadingLimit;

  Future<void> setDailyReadingLimit(int minutes) async {
    _dailyReadingLimit = minutes;
    await _storage.write(key: _readingLimitKey, value: minutes.toString());
  }

  // Filter articles based on Calm Mode settings
  List<ArticleModel> filterArticles(List<ArticleModel> articles) {
    if (!_isCalmModeEnabled) {
      return articles;
    }

    return articles.where((article) {
      // Filter out negative sentiment articles
      if (article.sentiment.toLowerCase() == 'negative') {
        return false;
      }

      // Filter out crisis/doom keywords in title and description
      final combinedText =
          '${article.title} ${article.description}'.toLowerCase();

      final doomKeywords = [
        'crisis',
        'disaster',
        'catastrophe',
        'tragedy',
        'death',
        'killed',
        'murder',
        'attack',
        'war',
        'violence',
        'crash',
        'collapse',
        'destruction',
        'terror',
        'panic',
        'fear',
        'threat',
        'danger',
        'warning',
        'emergency',
        'outbreak',
        'epidemic',
        'pandemic',
      ];

      for (final keyword in doomKeywords) {
        if (combinedText.contains(keyword)) {
          return false;
        }
      }

      // Keep the article if it passes all filters
      return true;
    }).toList();
  }

  // Check if article is considered "doom content"
  bool isDoomContent(ArticleModel article) {
    if (article.sentiment.toLowerCase() == 'negative') {
      return true;
    }

    final combinedText =
        '${article.title} ${article.description}'.toLowerCase();

    final doomKeywords = [
      'crisis',
      'disaster',
      'catastrophe',
      'tragedy',
      'death',
      'killed',
      'murder',
      'attack',
      'war',
      'violence',
      'crash',
      'collapse',
      'destruction',
      'terror',
      'panic',
      'fear',
      'threat',
      'danger',
      'warning',
      'emergency',
      'outbreak',
      'epidemic',
      'pandemic',
    ];

    for (final keyword in doomKeywords) {
      if (combinedText.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  // Get article wellness score (0-100)
  int getArticleWellnessScore(ArticleModel article) {
    int score = 50; // Start neutral

    // Sentiment contribution (40 points max)
    if (article.sentiment.toLowerCase() == 'positive') {
      score += 30;
    } else if (article.sentiment.toLowerCase() == 'negative') {
      score -= 30;
    }

    // Sentiment stats contribution (10 points max)
    score += (article.sentimentStats.positive * 10).toInt();
    score -= (article.sentimentStats.negative * 10).toInt();

    // Check for doom keywords (-20 points)
    if (isDoomContent(article)) {
      score -= 20;
    }

    // Check for positive keywords (+10 points)
    final combinedText =
        '${article.title} ${article.description}'.toLowerCase();

    final positiveKeywords = [
      'success',
      'achievement',
      'innovation',
      'breakthrough',
      'progress',
      'improvement',
      'growth',
      'solution',
      'hope',
      'recovery',
      'win',
      'celebration',
      'victory',
      'inspiring',
      'uplifting',
    ];

    for (final keyword in positiveKeywords) {
      if (combinedText.contains(keyword)) {
        score += 5;
        break;
      }
    }

    // Clamp between 0-100
    return score.clamp(0, 100);
  }

  // Get suggested articles (balanced for wellness)
  List<ArticleModel> getSuggestedArticles(
    List<ArticleModel> articles,
    int limit,
  ) {
    // Sort by wellness score
    final sortedArticles = List<ArticleModel>.from(articles);
    sortedArticles.sort((a, b) {
      final scoreA = getArticleWellnessScore(a);
      final scoreB = getArticleWellnessScore(b);
      return scoreB.compareTo(scoreA);
    });

    // Return top articles
    return sortedArticles.take(limit).toList();
  }
}
