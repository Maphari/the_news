import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/news_article_model.dart';

/// Service to manage saved articles (bookmarks)
/// Uses ApiClient for all network requests following clean architecture
class SavedArticlesService extends ChangeNotifier {
  static final SavedArticlesService instance = SavedArticlesService._init();
  SavedArticlesService._init();

  final _api = ApiClient.instance;
  Set<String> _savedArticleIds = {};
  List<ArticleModel> _savedArticles = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Set<String> get savedArticleIds => _savedArticleIds;
  List<ArticleModel> get savedArticles => _savedArticles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get savedCount => _savedArticleIds.length;

  /// Check if an article is saved
  bool isArticleSaved(String articleId) {
    return _savedArticleIds.contains(articleId);
  }

  /// Load saved article IDs for a user
  Future<void> loadSavedArticles(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch from backend first to ensure cross-device data consistency
      log('📥 Fetching saved articles from backend for user: $userId');

      final response = await _api.get('saved-articles/$userId', queryParams: {
        'includeArticles': 'true', // Request full article data
      });

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          // Parse article IDs
          final List<dynamic> articleIds = data['articleIds'] ?? [];
          _savedArticleIds = articleIds.map((id) => id.toString()).toSet();

          // Parse full article objects if available
          if (data['articles'] != null && data['articles'] is List) {
            final List<dynamic> articlesJson = data['articles'];
            _savedArticles = articlesJson
                .map((json) => ArticleModel.fromJson(json))
                .toList();

            // Save to local storage for offline access
            await _saveToLocalStorage(userId);
            log('✅ Loaded ${_savedArticles.length} saved articles with full data from backend');
          } else if (_savedArticleIds.isNotEmpty) {
            // Backend returned IDs but no articles - try to fetch them
            log('⚠️ Backend returned ${_savedArticleIds.length} IDs but no article data, fetching...');
            await _fetchMissingArticles(_savedArticleIds.toList());
          } else {
            _savedArticles = [];
            log('✅ No saved articles found');
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to load saved articles');
        }
      } else {
        // If backend fails, fall back to local storage
        log('⚠️ Backend unavailable, loading from local cache');
        await _loadFromLocalStorage(userId);
      }
    } catch (e) {
      _error = e.toString();
      log('⚠️ Error loading saved articles from backend, trying local cache: $e');
      // Fall back to local storage on error
      try {
        await _loadFromLocalStorage(userId);
      } catch (localError) {
        log('⚠️ Error loading from local storage: $localError');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch missing article details by article IDs
  Future<void> _fetchMissingArticles(List<String> articleIds) async {
    if (articleIds.isEmpty) return;

    try {
      log('🔄 Fetching details for ${articleIds.length} articles...');

      // Fetch articles in batches to avoid overwhelming the backend
      const batchSize = 20;
      final List<ArticleModel> fetchedArticles = [];

      for (int i = 0; i < articleIds.length; i += batchSize) {
        final batch = articleIds.skip(i).take(batchSize).toList();

        final response = await _api.post(
          'articles/by-ids',
          body: {'articleIds': batch},
          timeout: const Duration(seconds: 10),
        );

        if (_api.isSuccess(response)) {
          final data = _api.parseJson(response);
          if (data['success'] == true && data['articles'] != null) {
            final List<dynamic> articlesJson = data['articles'];
            final articles = articlesJson
                .map((json) => ArticleModel.fromJson(json))
                .toList();
            fetchedArticles.addAll(articles);
          }
        }
      }

      if (fetchedArticles.isNotEmpty) {
        _savedArticles = fetchedArticles;
        log('✅ Fetched ${fetchedArticles.length} articles from backend');
        notifyListeners();
      }
    } catch (e) {
      log('⚠️ Error fetching missing articles: $e');
    }
  }

  /// Load saved articles from local storage
  Future<void> _loadFromLocalStorage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('saved_articles_$userId');

      if (savedJson != null) {
        final List<dynamic> data = json.decode(savedJson);
        _savedArticleIds = data.map((item) => item['articleId'].toString()).toSet();
        _savedArticles = data
            .map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
            .toList();
        log('💾 Loaded ${_savedArticles.length} articles from local storage');
      }
    } catch (e) {
      log('⚠️ Error loading from local storage: $e');
    }
  }

  /// Save articles to local storage
  Future<void> _saveToLocalStorage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _savedArticles.map((article) => article.toJson()).toList();
      await prefs.setString('saved_articles_$userId', json.encode(data));
      log('💾 Saved ${_savedArticles.length} articles to local storage');
    } catch (e) {
      log('⚠️ Error saving to local storage: $e');
    }
  }

  /// Save an article
  Future<bool> saveArticle(String userId, String articleId, {ArticleModel? article}) async {
    try {
      log('💾 Saving article: $articleId for user: $userId');

      // Add to local state immediately for instant feedback
      _savedArticleIds.add(articleId);
      if (article != null && !_savedArticles.any((a) => a.articleId == articleId)) {
        _savedArticles.add(article);
      }
      notifyListeners();

      // Save to local storage immediately
      await _saveToLocalStorage(userId);

      // Then sync to backend with full article data
      final response = await _api.post(
        'saved-articles',
        body: {
          'userId': userId,
          'articleId': articleId,
          'articleData': article?.toJson(), // Include full article data for backend storage
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          log('✅ Article saved to backend');
          return true;
        }
      }

      log('⚠️ Failed to save to backend: ${_api.getErrorMessage(response)}');
      // Still return true since we saved locally
      return true;
    } catch (e) {
      log('⚠️ Error saving article: $e');
      // Still return true since we saved locally
      return true;
    }
  }

  /// Unsave (remove) an article
  Future<bool> unsaveArticle(String userId, String articleId) async {
    try {
      log('🗑️ Unsaving article: $articleId for user: $userId');

      // Remove from local state immediately for instant feedback
      _savedArticleIds.remove(articleId);
      _savedArticles.removeWhere((article) => article.articleId == articleId);
      notifyListeners();

      // Update local storage immediately
      await _saveToLocalStorage(userId);

      // Then sync to backend
      final response = await _api.delete(
        'saved-articles',
        body: {
          'userId': userId,
          'articleId': articleId,
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          log('✅ Article unsaved from backend');
          return true;
        }
      }

      log('⚠️ Failed to unsave from backend: ${_api.getErrorMessage(response)}');
      // Still return true since we removed locally
      return true;
    } catch (e) {
      log('⚠️ Error unsaving article: $e');
      // Still return true since we removed locally
      return true;
    }
  }

  /// Toggle save status of an article
  Future<bool> toggleSaveArticle(String userId, String articleId, {ArticleModel? article}) async {
    if (isArticleSaved(articleId)) {
      return await unsaveArticle(userId, articleId);
    } else {
      return await saveArticle(userId, articleId, article: article);
    }
  }

  /// Clear all saved articles (local state only)
  void clearSavedArticles() {
    _savedArticleIds.clear();
    _savedArticles.clear();
    notifyListeners();
    log('🧹 Cleared saved articles from local state');
  }
}
