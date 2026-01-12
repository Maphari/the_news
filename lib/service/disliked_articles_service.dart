import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:the_news/core/network/api_client.dart';

/// Service to manage disliked articles
/// Uses ApiClient for all network requests following clean architecture
class DislikedArticlesService extends ChangeNotifier {
  static final DislikedArticlesService instance = DislikedArticlesService._init();
  DislikedArticlesService._init();

  final _api = ApiClient.instance;
  Set<String> _dislikedArticleIds = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  Set<String> get dislikedArticleIds => _dislikedArticleIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all disliked articles for a user
  Future<void> loadDislikedArticles(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      log('📥 Loading disliked articles for user: $userId');

      final response = await _api.get('disliked-articles/$userId');

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final List<dynamic> articleIds = data['articleIds'] ?? [];
          _dislikedArticleIds = articleIds.map((id) => id.toString()).toSet();
          log('✅ Loaded ${_dislikedArticleIds.length} disliked articles');
        } else {
          throw Exception(data['message'] ?? 'Failed to load disliked articles');
        }
      } else {
        throw Exception(_api.getErrorMessage(response));
      }
    } catch (e) {
      _error = e.toString();
      log('⚠️ Error loading disliked articles: $e');
      _dislikedArticleIds = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark an article as disliked
  Future<bool> dislikeArticle(String userId, String articleId) async {
    // Optimistic update - add to local set immediately
    _dislikedArticleIds.add(articleId);
    notifyListeners();

    try {
      log('👎 Disliking article: $articleId');

      final response = await _api.post(
        'disliked-articles',
        body: {
          'userId': userId,
          'articleId': articleId,
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          log('✅ Article disliked successfully');
          return true;
        }
      }

      // If failed, rollback optimistic update
      log('⚠️ Failed to dislike article: ${_api.getErrorMessage(response)}');
      _dislikedArticleIds.remove(articleId);
      notifyListeners();
      return false;
    } catch (e) {
      log('⚠️ Error disliking article: $e');
      // Rollback optimistic update
      _dislikedArticleIds.remove(articleId);
      notifyListeners();
      return false;
    }
  }

  /// Remove article from disliked list
  Future<bool> undislikeArticle(String userId, String articleId) async {
    // Optimistic update - remove from local set immediately
    _dislikedArticleIds.remove(articleId);
    notifyListeners();

    try {
      log('👍 Undisliking article: $articleId');

      final response = await _api.delete(
        'disliked-articles',
        body: {
          'userId': userId,
          'articleId': articleId,
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          log('✅ Article undisliked successfully');
          return true;
        }
      }

      // If failed, rollback optimistic update
      log('⚠️ Failed to undislike article: ${_api.getErrorMessage(response)}');
      _dislikedArticleIds.add(articleId);
      notifyListeners();
      return false;
    } catch (e) {
      log('⚠️ Error undisliking article: $e');
      // Rollback optimistic update
      _dislikedArticleIds.add(articleId);
      notifyListeners();
      return false;
    }
  }

  /// Check if an article is disliked
  bool isArticleDisliked(String articleId) {
    return _dislikedArticleIds.contains(articleId);
  }

  /// Get count of disliked articles
  int get dislikedCount => _dislikedArticleIds.length;

  /// Clear all disliked articles (local only)
  void clearCache() {
    _dislikedArticleIds.clear();
    notifyListeners();
    log('🧹 Cleared disliked articles cache');
  }
}
