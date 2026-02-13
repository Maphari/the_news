import 'dart:developer';

import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/experience_service.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/service/recommendation_service.dart';
import 'package:the_news/service/content_discovery_service.dart';

class HomeFeedTopic {
  const HomeFeedTopic({required this.topic, required this.count});

  final String topic;
  final int count;

  factory HomeFeedTopic.fromJson(Map<String, dynamic> json) {
    return HomeFeedTopic(
      topic: json['topic']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeFeedModel {
  const HomeFeedModel({
    required this.hero,
    required this.focus,
    required this.recommended,
    required this.trendingTopics,
    required this.timestamp,
  });

  final ArticleModel hero;
  final List<ArticleModel> focus;
  final List<ArticleModel> recommended;
  final List<HomeFeedTopic> trendingTopics;
  final DateTime timestamp;

  factory HomeFeedModel.fromJson(Map<String, dynamic> json) {
    return HomeFeedModel(
      hero: ArticleModel.fromJson(json['hero'] ?? {}),
      focus: (json['focus'] as List<dynamic>? ?? const [])
          .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      recommended: (json['recommended'] as List<dynamic>? ?? const [])
          .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      trendingTopics: (json['trendingTopics'] as List<dynamic>? ?? const [])
          .map((item) => HomeFeedTopic.fromJson(item as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class HomeFeedService {
  static final HomeFeedService instance = HomeFeedService._init();
  HomeFeedService._init();

  final ApiClient _api = ApiClient.instance;
  final ExperienceService _experience = ExperienceService.instance;
  final Map<String, HomeFeedModel> _cache = {};

  Future<HomeFeedModel?> fetchHomeFeed({
    required String userId,
    int briefsLimit = 6,
    int focusLimit = 4,
    int recommendedLimit = 8,
  }) async {
    final key = '$userId:$briefsLimit:$focusLimit:$recommendedLimit';
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    try {
      final response = await _api.get(
        'articles/home-feed',
        queryParams: {
          'userId': userId,
          'briefsLimit': briefsLimit.toString(),
          'focusLimit': focusLimit.toString(),
          'recommendedLimit': recommendedLimit.toString(),
        },
        timeout: const Duration(seconds: 15),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true && data['hero'] != null) {
          final model = HomeFeedModel.fromJson(data);
          _cache[key] = model;
          return model;
        }
      }
    } catch (e) {
      log('⚠️ Home feed error: $e');
    }
    final fallback = await _buildBackendFirstFallback(userId: userId);
    if (fallback != null) {
      _cache[key] = fallback;
    }
    return fallback;
  }

  void clearCache() => _cache.clear();

  Future<HomeFeedModel?> _buildBackendFirstFallback({
    required String userId,
  }) async {
    try {
      final aggregate = await _experience.fetchAggregate(userId);
      List<ArticleModel> articles = const [];

      if (aggregate != null && aggregate.topStoriesArticleIds.isNotEmpty) {
        final byIdsResponse = await _api.post(
          'articles/by-ids',
          body: {'articleIds': aggregate.topStoriesArticleIds},
        );
        if (_api.isSuccess(byIdsResponse)) {
          final payload = _api.parseJson(byIdsResponse);
          if (payload['success'] == true) {
            final raw = (payload['articles'] as List<dynamic>? ?? const []);
            articles = raw
                .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
      }

      if (articles.isEmpty) {
        final providerArticles = NewsProviderService.instance.articles;
        if (providerArticles.isEmpty) return null;
        articles = providerArticles.take(12).toList();
      }

      final hero = articles.first;
      final focus = articles.skip(1).take(4).toList();
      var recommended = articles.skip(5).take(8).toList();
      if (recommended.isEmpty) {
        recommended = RecommendationService.instance.getRecommendations(limit: 8);
      }

      final trending = <HomeFeedTopic>[];
      if (aggregate != null && aggregate.trendingTopics.isNotEmpty) {
        aggregate.trendingTopics.forEach((topic, count) {
          trending.add(HomeFeedTopic(topic: topic, count: count));
        });
      } else {
        final localTrending = await ContentDiscoveryService.instance.getTrendingTopics(limit: 8);
        trending.addAll(
          localTrending
              .map((item) => HomeFeedTopic(topic: item.topic, count: item.articleCount)),
        );
      }

      return HomeFeedModel(
        hero: hero,
        focus: focus,
        recommended: recommended,
        trendingTopics: trending,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      log('⚠️ Home feed fallback error: $e');
      return null;
    }
  }
}
