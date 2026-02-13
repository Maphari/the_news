import 'dart:developer';

import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/offline_reading_service.dart';

class ExperiencePerspective {
  const ExperiencePerspective({
    required this.articleId,
    required this.title,
    required this.sourceName,
    required this.biasDirection,
    required this.sentiment,
    required this.isSameSource,
  });

  final String articleId;
  final String title;
  final String sourceName;
  final String biasDirection;
  final String sentiment;
  final bool isSameSource;

  factory ExperiencePerspective.fromJson(Map<String, dynamic> json) {
    return ExperiencePerspective(
      articleId: (json['articleId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      sourceName: (json['sourceName'] ?? '').toString(),
      biasDirection: (json['biasDirection'] ?? 'center').toString(),
      sentiment: (json['sentiment'] ?? 'neutral').toString(),
      isSameSource: json['isSameSource'] == true,
    );
  }
}

class ExperienceAggregate {
  const ExperienceAggregate({
    required this.topStoriesArticleIds,
    required this.trendingTopics,
    required this.digestCards,
  });

  final List<String> topStoriesArticleIds;
  final Map<String, int> trendingTopics;
  final List<Map<String, dynamic>> digestCards;
}

class ExperienceService {
  static final ExperienceService instance = ExperienceService._init();
  ExperienceService._init();

  final ApiClient _api = ApiClient.instance;

  Future<ExperienceAggregate?> fetchAggregate(
    String userId, {
    String surface = 'home',
  }) async {
    try {
      final response = await _api.get(
        'experience/aggregate/$userId',
        queryParams: {'surface': surface},
        timeout: const Duration(seconds: 10),
      );
      if (!_api.isSuccess(response)) return null;
      final data = _api.parseJson(response);
      if (data['success'] != true) return null;
      final aggregate = data['aggregate'] as Map<String, dynamic>? ?? const {};
      final topStories = (aggregate['topStories'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .map((item) => (item['articleId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();

      final topics = <String, int>{};
      final rawTopics = aggregate['trendingTopics'];
      if (rawTopics is Map) {
        for (final entry in rawTopics.entries) {
          topics[entry.key.toString()] = (entry.value as num?)?.toInt() ?? 0;
        }
      }

      final digests =
          (aggregate['digestCards'] as List<dynamic>? ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();

      return ExperienceAggregate(
        topStoriesArticleIds: topStories,
        trendingTopics: topics,
        digestCards: digests,
      );
    } catch (e) {
      log('⚠️ Experience aggregate error: $e');
      return null;
    }
  }

  Future<List<ExperiencePerspective>> fetchPerspectives(String articleId) async {
    try {
      final response = await _api.get(
        'experience/articles/$articleId/perspectives',
        timeout: const Duration(seconds: 10),
      );
      if (!_api.isSuccess(response)) return const [];
      final data = _api.parseJson(response);
      if (data['success'] != true) return const [];
      return (data['perspectives'] as List<dynamic>? ?? const [])
          .map((item) => ExperiencePerspective.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('⚠️ Experience perspectives error: $e');
      return const [];
    }
  }

  Future<Map<String, dynamic>?> fetchWellnessSettings(String userId) async {
    try {
      final response = await _api.get('experience/wellness/$userId');
      if (!_api.isSuccess(response)) return null;
      final data = _api.parseJson(response);
      if (data['success'] != true) return null;
      return Map<String, dynamic>.from(data['settings'] ?? const {});
    } catch (e) {
      log('⚠️ Wellness settings error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateWellnessSettings(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _api.put(
        'experience/wellness/$userId',
        body: updates,
      );
      if (!_api.isSuccess(response)) return null;
      final data = _api.parseJson(response);
      if (data['success'] != true) return null;
      return Map<String, dynamic>.from(data['settings'] ?? const {});
    } catch (e) {
      log('⚠️ Wellness settings update error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchWellnessReport(String userId) async {
    try {
      final response = await _api.get('experience/wellness/$userId/report');
      if (!_api.isSuccess(response)) return null;
      final data = _api.parseJson(response);
      if (data['success'] != true) return null;
      return Map<String, dynamic>.from(data['report'] ?? const {});
    } catch (e) {
      log('⚠️ Wellness report error: $e');
      return null;
    }
  }

  Future<List<String>> fetchOfflineManifestArticleIds(String userId) async {
    try {
      final response = await _api.get('experience/offline/manifest/$userId');
      if (!_api.isSuccess(response)) return const [];
      final data = _api.parseJson(response);
      if (data['success'] != true) return const [];
      return (data['manifest'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .map((item) => (item['articleId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      log('⚠️ Offline manifest error: $e');
      return const [];
    }
  }

  Future<int> syncOfflineManifest(
    String userId, {
    int maxItems = 20,
  }) async {
    final articleIds = await fetchOfflineManifestArticleIds(userId);
    if (articleIds.isEmpty) return 0;

    try {
      final subset = articleIds.take(maxItems).toList();
      final response = await _api.post(
        'articles/by-ids',
        body: {'articleIds': subset},
      );
      if (!_api.isSuccess(response)) return 0;
      final data = _api.parseJson(response);
      if (data['success'] != true) return 0;

      final rawArticles = (data['articles'] as List<dynamic>? ?? const []);
      final articles = rawArticles
          .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
          .toList();

      int queued = 0;
      for (final article in articles) {
        if (OfflineReadingService.instance.isArticleCached(article.articleId)) {
          continue;
        }
        final ok = await OfflineReadingService.instance.addToQueue(article);
        if (ok) queued += 1;
      }
      return queued;
    } catch (e) {
      log('⚠️ Offline manifest sync error: $e');
      return 0;
    }
  }

  Future<bool> createTtsPresign({
    required String userId,
    required String articleId,
    String? voice,
    String? language,
  }) async {
    try {
      final response = await _api.post(
        'experience/tts/presign',
        body: {
          'userId': userId,
          'articleId': articleId,
          if (voice != null) 'voice': voice,
          if (language != null) 'language': language,
        },
        timeout: const Duration(seconds: 8),
      );
      return _api.isSuccess(response);
    } catch (e) {
      log('⚠️ TTS presign error: $e');
      return false;
    }
  }
}
