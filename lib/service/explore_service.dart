import 'dart:developer';

import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/experience_service.dart';

class PopularSourceModel {
  const PopularSourceModel({
    required this.name,
    required this.articleCount,
    this.iconUrl,
  });

  final String name;
  final int articleCount;
  final String? iconUrl;

  factory PopularSourceModel.fromJson(Map<String, dynamic> json) {
    final parsedIcon = json['iconUrl']?.toString().trim();

    return PopularSourceModel(
      name: (json['name'] ?? '').toString(),
      articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
      iconUrl: (parsedIcon?.isEmpty ?? true) ? null : parsedIcon,
    );
  }
}

class ExploreService {
  static final ExploreService instance = ExploreService._init();
  ExploreService._init();

  final ApiClient _api = ApiClient.instance;
  final ExperienceService _experience = ExperienceService.instance;

  final Map<String, List<ArticleModel>> _searchCache =
      <String, List<ArticleModel>>{};
  final Map<String, List<ArticleModel>> _topStoriesCache =
      <String, List<ArticleModel>>{};
  final Map<int, List<PopularSourceModel>> _popularSourcesCache =
      <int, List<PopularSourceModel>>{};
  final Map<String, ExploreSectionsModel> _exploreSectionsCache =
      <String, ExploreSectionsModel>{};

  Future<ExploreSectionsModel> getExploreSections({
    String? userId,
    int briefsLimit = 8,
    int topicsLimit = 10,
    int topStoriesLimit = 5,
    int forYouLimit = 4,
    int sourcesLimit = 5,
  }) async {
    final cacheKey =
        '${userId ?? ''}:$briefsLimit:$topicsLimit:$topStoriesLimit:$forYouLimit:$sourcesLimit';
    final cached = _exploreSectionsCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _api.get(
        'articles/explore/sections',
        queryParams: {
          'briefsLimit': briefsLimit.toString(),
          'topicsLimit': topicsLimit.toString(),
          'topStoriesLimit': topStoriesLimit.toString(),
          'forYouLimit': forYouLimit.toString(),
          'sourcesLimit': sourcesLimit.toString(),
          if (userId != null && userId.isNotEmpty) 'userId': userId,
        },
        timeout: const Duration(seconds: 12),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final quickBriefs = (data['quickBriefs'] as List<dynamic>? ?? const [])
              .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
              .toList();
          final topics = (data['trendingTopics'] as List<dynamic>? ?? const [])
              .map(
                (item) =>
                    ExploreTopicModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          final topStories = (data['topStories'] as List<dynamic>? ?? const [])
              .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
              .toList();
          final forYou = (data['forYou'] as List<dynamic>? ?? const [])
              .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
              .toList();
          final popularSources = (data['popularSources'] as List<dynamic>? ?? const [])
              .map(
                (item) => PopularSourceModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();

          final payload = ExploreSectionsModel(
            quickBriefs: quickBriefs,
            trendingTopics: topics,
            topStories: topStories,
            forYou: forYou,
            popularSources: popularSources,
          );
          _exploreSectionsCache[cacheKey] = payload;
          return payload;
        }
      }
    } catch (e) {
      log('⚠️ Explore sections error: $e');
    }

    final fallback = await _buildAggregateFallback(userId: userId);
    if (fallback != null) {
      _exploreSectionsCache[cacheKey] = fallback;
      return fallback;
    }

      return const ExploreSectionsModel(
      quickBriefs: [],
      trendingTopics: [],
      topStories: [],
      forYou: [],
      popularSources: [],
    );
  }

  Future<List<ArticleModel>> searchArticles({
    required String query,
    String? userId,
    int limit = 20,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return const [];

    final cacheKey = '$normalized:${userId ?? ''}:$limit';
    final cached = _searchCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _api.get(
        'articles/search',
        queryParams: {
          'query': normalized,
          'limit': limit.toString(),
          if (userId != null && userId.isNotEmpty) 'userId': userId,
        },
        timeout: const Duration(seconds: 12),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final rawArticles = (data['articles'] as List<dynamic>? ?? const []);
          final parsed = rawArticles
              .map((json) => ArticleModel.fromJson(json as Map<String, dynamic>))
              .toList();
          _searchCache[cacheKey] = parsed;
          return parsed;
        }
      }
      return const [];
    } catch (e) {
      log('⚠️ Explore search error: $e');
      return const [];
    }
  }

  Future<List<ArticleModel>> getTopStories({
    String? userId,
    int limit = 6,
  }) async {
    final cacheKey = '${userId ?? ''}:$limit';
    final cached = _topStoriesCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _api.get(
        'articles/top-stories',
        queryParams: {
          'limit': limit.toString(),
          if (userId != null && userId.isNotEmpty) 'userId': userId,
        },
        timeout: const Duration(seconds: 12),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final rawArticles = (data['articles'] as List<dynamic>? ?? const []);
          final parsed = rawArticles
              .map((json) => ArticleModel.fromJson(json as Map<String, dynamic>))
              .toList();
          _topStoriesCache[cacheKey] = parsed;
          return parsed;
        }
      }
      return const [];
    } catch (e) {
      log('⚠️ Top stories error: $e');
      return const [];
    }
  }

  Future<List<PopularSourceModel>> getPopularSources({int limit = 8}) async {
    final cached = _popularSourcesCache[limit];
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _api.get(
        'articles/popular-sources',
        queryParams: {'limit': limit.toString()},
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final sources = (data['sources'] as List<dynamic>? ?? const [])
              .map(
                (item) => PopularSourceModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
          _popularSourcesCache[limit] = sources;
          return sources;
        }
      }
      return const [];
    } catch (e) {
      log('⚠️ Popular sources error: $e');
      return const [];
    }
  }

  void clearCache() {
    _searchCache.clear();
    _topStoriesCache.clear();
    _popularSourcesCache.clear();
    _exploreSectionsCache.clear();
  }

  Future<ExploreSectionsModel?> _buildAggregateFallback({String? userId}) async {
    if (userId == null || userId.isEmpty) return null;
    try {
      final aggregate = await _experience.fetchAggregate(userId, surface: 'explore');
      if (aggregate == null || aggregate.topStoriesArticleIds.isEmpty) return null;

      final byIdsResponse = await _api.post(
        'articles/by-ids',
        body: {'articleIds': aggregate.topStoriesArticleIds},
      );
      if (!_api.isSuccess(byIdsResponse)) return null;
      final payload = _api.parseJson(byIdsResponse);
      if (payload['success'] != true) return null;

      final quickBriefs = (payload['articles'] as List<dynamic>? ?? const [])
          .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
          .toList();
      final topics = aggregate.trendingTopics.entries
          .map((entry) => ExploreTopicModel(topic: entry.key, count: entry.value))
          .toList();

      return ExploreSectionsModel(
        quickBriefs: quickBriefs,
        trendingTopics: topics,
        topStories: quickBriefs.take(5).toList(),
        forYou: quickBriefs.skip(5).take(4).toList(),
        popularSources: const [],
      );
    } catch (e) {
      log('⚠️ Explore aggregate fallback error: $e');
      return null;
    }
  }
}

class ExploreTopicModel {
  const ExploreTopicModel({
    required this.topic,
    required this.count,
  });

  final String topic;
  final int count;

  factory ExploreTopicModel.fromJson(Map<String, dynamic> json) {
    return ExploreTopicModel(
      topic: (json['topic'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExploreSectionsModel {
  const ExploreSectionsModel({
    required this.quickBriefs,
    required this.trendingTopics,
    required this.topStories,
    required this.forYou,
    required this.popularSources,
  });

  final List<ArticleModel> quickBriefs;
  final List<ExploreTopicModel> trendingTopics;
  final List<ArticleModel> topStories;
  final List<ArticleModel> forYou;
  final List<PopularSourceModel> popularSources;
}
