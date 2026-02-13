import 'package:flutter/foundation.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/clickbait_detector_service.dart';

class ContentIntensityService extends ChangeNotifier {
  static final ContentIntensityService instance = ContentIntensityService._init();

  IntensityLevel _currentFilter = IntensityLevel.all;
  final ClickbaitDetectorService _clickbaitDetector = ClickbaitDetectorService.instance;

  ContentIntensityService._init();

  // Get current filter setting
  IntensityLevel get currentFilter => _currentFilter;

  // Set filter level
  void setFilter(IntensityLevel level) {
    _currentFilter = level;
    notifyListeners();
  }

  // Calculate intensity of an article based on sentiment
  IntensityLevel calculateArticleIntensity(ArticleModel article) {
    final sentiment = article.sentiment.toLowerCase();
    final negativeScore = article.sentimentStats.negative;
    final positiveScore = article.sentimentStats.positive;

    // Check for clickbait (high intensity)
    if (_clickbaitDetector.isClickbait(article.title)) {
      return IntensityLevel.high;
    }

    // Calculate based on sentiment scores
    if (sentiment == 'negative' || negativeScore > 0.7) {
      return IntensityLevel.high;
    } else if (sentiment == 'positive' && positiveScore > 0.7) {
      return IntensityLevel.low;
    } else if (negativeScore > 0.4) {
      return IntensityLevel.medium;
    } else {
      return IntensityLevel.low;
    }
  }

  // Filter articles based on current intensity setting
  List<ArticleModel> filterArticles(List<ArticleModel> articles) {
    if (_currentFilter == IntensityLevel.all) {
      return articles;
    }

    return articles.where((article) {
      final intensity = calculateArticleIntensity(article);

      switch (_currentFilter) {
        case IntensityLevel.low:
          return intensity == IntensityLevel.low;
        case IntensityLevel.medium:
          return intensity == IntensityLevel.low ||
                 intensity == IntensityLevel.medium;
        case IntensityLevel.high:
        case IntensityLevel.all:
          return true;
      }
    }).toList();
  }

  // Get article count for each intensity level
  Map<IntensityLevel, int> getIntensityBreakdown(List<ArticleModel> articles) {
    final breakdown = {
      IntensityLevel.low: 0,
      IntensityLevel.medium: 0,
      IntensityLevel.high: 0,
    };

    for (var article in articles) {
      final intensity = calculateArticleIntensity(article);
      breakdown[intensity] = (breakdown[intensity] ?? 0) + 1;
    }

    return breakdown;
  }

  // Get recommendation for wellness
  String getWellnessRecommendation(IntensityLevel level) {
    switch (level) {
      case IntensityLevel.low:
        return 'Gentle news - Good for mindful reading';
      case IntensityLevel.medium:
        return 'Balanced content - Moderate emotional impact';
      case IntensityLevel.high:
        return 'Intense news - May be emotionally demanding';
      case IntensityLevel.all:
        return 'All news - Full range of content';
    }
  }
}

enum IntensityLevel {
  low,     // Positive, neutral, low negative score
  medium,  // Some negative content but not extreme
  high,    // High negative content, clickbait
  all,     // No filter
}

extension IntensityLevelExtension on IntensityLevel {
  String get label {
    switch (this) {
      case IntensityLevel.low:
        return 'Gentle';
      case IntensityLevel.medium:
        return 'Balanced';
      case IntensityLevel.high:
        return 'All Intensity';
      case IntensityLevel.all:
        return 'No Filter';
    }
  }

  String get description {
    switch (this) {
      case IntensityLevel.low:
        return 'Positive and neutral stories';
      case IntensityLevel.medium:
        return 'Mix of positive and thoughtful content';
      case IntensityLevel.high:
        return 'Includes emotionally intense content';
      case IntensityLevel.all:
        return 'All content regardless of intensity';
    }
  }

  String get icon {
    switch (this) {
      case IntensityLevel.low:
        return '😌';
      case IntensityLevel.medium:
        return '🤔';
      case IntensityLevel.high:
        return '🔥';
      case IntensityLevel.all:
        return '📰';
    }
  }
}
