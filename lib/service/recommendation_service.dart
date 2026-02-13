import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/service/saved_articles_service.dart';

class RecommendationService {
  RecommendationService._privateConstructor();
  static final RecommendationService instance =
      RecommendationService._privateConstructor();

  final NewsProviderService _newsProvider = NewsProviderService.instance;
  final FollowedPublishersService _followedPublishers =
      FollowedPublishersService.instance;
  final SavedArticlesService _savedArticles = SavedArticlesService.instance;

  List<ArticleModel> getRecommendations({int limit = 4}) {
    final allArticles = _newsProvider.articles;
    final followedPublishers = _followedPublishers.followedPublisherNames;
    final savedArticles = _savedArticles.savedArticles;

    if (followedPublishers.isEmpty && savedArticles.isEmpty) {
      // If no data, return most recent articles
      return _newsProvider.getRecentArticles(limit: limit);
    }

    final recommendedArticles = <ArticleModel, double>{};
    final savedCategories = savedArticles
        .expand((article) => article.category)
        .map((category) => category.toLowerCase())
        .toSet();

    for (final article in allArticles) {
      double score = 0;

      // Score based on followed publishers
      if (followedPublishers.contains(article.sourceName)) {
        score += 2.0;
      }

      // Score based on saved categories
      final hasCategoryMatch = article.category
          .map((category) => category.toLowerCase())
          .any(savedCategories.contains);
      if (hasCategoryMatch) {
        score += 1.5;
      }

      // Score based on recency (higher score for newer articles)
      final daysOld = DateTime.now().difference(article.pubDate).inDays;
      if (daysOld < 3) {
        score += 1.0;
      } else if (daysOld < 7) {
        score += 0.5;
      }

      if (score > 0) {
        recommendedArticles[article] = score;
      }
    }

    final sortedArticles = recommendedArticles.keys.toList(growable: false)
      ..sort((a, b) =>
          recommendedArticles[b]!.compareTo(recommendedArticles[a]!));

    return sortedArticles.take(limit).toList();
  }
}
