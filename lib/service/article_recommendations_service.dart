import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/news_article_model.dart';

class ArticleRecommendationsService extends ChangeNotifier {
  static final ArticleRecommendationsService instance =
      ArticleRecommendationsService._init();
  ArticleRecommendationsService._init();

  final ApiClient _api = ApiClient.instance;
  final Map<String, List<ArticleModel>> _cache = {};
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<List<ArticleModel>> getRecommendations({
    required String userId,
    int limit = 4,
  }) async {
    final cacheKey = '$userId:$limit';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(
        'articles/recommendations',
        queryParams: {
          'userId': userId,
          'limit': limit.toString(),
        },
        timeout: const Duration(seconds: 12),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final List<dynamic> rawArticles = data['articles'] ?? [];
          final articles = rawArticles
              .map((json) => ArticleModel.fromJson(json))
              .toList();
          _cache[cacheKey] = articles;
          log('✅ Loaded ${articles.length} article recommendations');
          return articles;
        }
      }

      _error = _api.getErrorMessage(response);
      log('⚠️ Failed to load recommendations: ${_error ?? 'unknown error'}');
      return [];
    } catch (e) {
      _error = e.toString();
      log('⚠️ Error loading recommendations: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _cache.clear();
    notifyListeners();
  }
}
