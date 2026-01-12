import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:the_news/core/network/api_client.dart';

/// Engagement data for an article
class ArticleEngagement {
  final String articleId;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;

  ArticleEngagement({
    required this.articleId,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.isLiked,
  });

  factory ArticleEngagement.fromJson(Map<String, dynamic> json) {
    return ArticleEngagement(
      articleId: json['articleId'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
    );
  }
}

/// Service to manage article engagement (likes, comments, shares)
/// Uses ApiClient for all network requests following clean architecture
class EngagementService extends ChangeNotifier {
  static final EngagementService instance = EngagementService._init();
  EngagementService._init();

  final _api = ApiClient.instance;
  final Map<String, ArticleEngagement> _engagementCache = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get engagement data for an article
  Future<ArticleEngagement?> getEngagement(String articleId, {String? userId}) async {
    // Check cache first
    if (_engagementCache.containsKey(articleId)) {
      return _engagementCache[articleId];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = userId != null ? {'userId': userId} : null;
      final response = await _api.get(
        'engagement/$articleId',
        queryParams: queryParams,
        timeout: const Duration(seconds: 10),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final engagement = ArticleEngagement.fromJson(data['engagement']);
          _engagementCache[articleId] = engagement;
          log('✅ Loaded engagement for article: $articleId');
          return engagement;
        } else {
          throw Exception(data['message'] ?? 'Failed to load engagement');
        }
      } else {
        throw Exception(_api.getErrorMessage(response));
      }
    } catch (e) {
      _error = e.toString();
      log('⚠️ Error loading engagement: $e');
      return _getDefaultEngagement(articleId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Like an article
  Future<bool> likeArticle(String userId, String articleId) async {
    // Optimistically update cache immediately
    final current = _engagementCache[articleId] ?? _getDefaultEngagement(articleId);
    _engagementCache[articleId] = ArticleEngagement(
      articleId: current.articleId,
      likeCount: current.likeCount + 1,
      commentCount: current.commentCount,
      shareCount: current.shareCount,
      isLiked: true,
    );
    notifyListeners();

    try {
      log('❤️ Liking article: $articleId');

      final response = await _api.post(
        'engagement/like',
        body: {
          'userId': userId,
          'articleId': articleId,
        },
        timeout: const Duration(seconds: 10),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          log('✅ Article liked successfully');
          return true;
        }
      }

      // Rollback on failure
      log('⚠️ Failed to like article: ${_api.getErrorMessage(response)}');
      _engagementCache[articleId] = current;
      notifyListeners();
      return false;
    } catch (e) {
      log('⚠️ Error liking article: $e');
      // Rollback on error
      _engagementCache[articleId] = current;
      notifyListeners();
      return false;
    }
  }

  /// Unlike an article
  Future<bool> unlikeArticle(String userId, String articleId) async {
    // Optimistically update cache immediately
    final current = _engagementCache[articleId] ?? _getDefaultEngagement(articleId);
    _engagementCache[articleId] = ArticleEngagement(
      articleId: current.articleId,
      likeCount: current.likeCount > 0 ? current.likeCount - 1 : 0,
      commentCount: current.commentCount,
      shareCount: current.shareCount,
      isLiked: false,
    );
    notifyListeners();

    try {
      log('💔 Unliking article: $articleId');

      final response = await _api.delete(
        'engagement/like',
        body: {
          'userId': userId,
          'articleId': articleId,
        },
        timeout: const Duration(seconds: 10),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          log('✅ Article unliked successfully');
          return true;
        }
      }

      // Rollback on failure
      log('⚠️ Failed to unlike article: ${_api.getErrorMessage(response)}');
      _engagementCache[articleId] = current;
      notifyListeners();
      return false;
    } catch (e) {
      log('⚠️ Error unliking article: $e');
      // Rollback on error
      _engagementCache[articleId] = current;
      notifyListeners();
      return false;
    }
  }

  /// Toggle like status of an article
  Future<bool> toggleLike(String userId, String articleId) async {
    if (_engagementCache.containsKey(articleId)) {
      final isLiked = _engagementCache[articleId]!.isLiked;
      if (isLiked) {
        return await unlikeArticle(userId, articleId);
      } else {
        return await likeArticle(userId, articleId);
      }
    } else {
      // If not in cache, fetch first
      await getEngagement(articleId, userId: userId);
      if (_engagementCache.containsKey(articleId)) {
        return await toggleLike(userId, articleId);
      }
      return false;
    }
  }

  /// Share an article
  Future<bool> shareArticle(String userId, String articleId, {String? platform}) async {
    try {
      log('📤 Sharing article: $articleId');

      final response = await _api.post(
        'engagement/share',
        body: {
          'userId': userId,
          'articleId': articleId,
          'platform': platform ?? 'unknown',
        },
        timeout: const Duration(seconds: 10),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          // Update cache
          if (_engagementCache.containsKey(articleId)) {
            final current = _engagementCache[articleId]!;
            _engagementCache[articleId] = ArticleEngagement(
              articleId: current.articleId,
              likeCount: current.likeCount,
              commentCount: current.commentCount,
              shareCount: current.shareCount + 1,
              isLiked: current.isLiked,
            );
          }
          notifyListeners();
          log('✅ Article shared successfully');
          return true;
        }
      }

      log('⚠️ Failed to share article: ${_api.getErrorMessage(response)}');
      return false;
    } catch (e) {
      log('⚠️ Error sharing article: $e');
      return false;
    }
  }

  /// Get engagement from cache
  ArticleEngagement? getCachedEngagement(String articleId) {
    return _engagementCache[articleId];
  }

  /// Check if article is liked (from cache)
  bool isArticleLiked(String articleId) {
    return _engagementCache[articleId]?.isLiked ?? false;
  }

  /// Get default engagement (fallback when backend unavailable)
  ArticleEngagement _getDefaultEngagement(String articleId) {
    return ArticleEngagement(
      articleId: articleId,
      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
      isLiked: false,
    );
  }

  /// Get like count for an article
  int getLikeCount(String articleId) {
    return _engagementCache[articleId]?.likeCount ?? 0;
  }

  /// Get comment count for an article
  int getCommentCount(String articleId) {
    return _engagementCache[articleId]?.commentCount ?? 0;
  }

  /// Get share count for an article
  int getShareCount(String articleId) {
    return _engagementCache[articleId]?.shareCount ?? 0;
  }

  /// Format count for display (1.2K, 45, etc.)
  String formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  /// Load engagement data for multiple articles
  Future<void> loadEngagementBatch(List<String> articleIds, {String? userId}) async {
    for (final articleId in articleIds) {
      if (!_engagementCache.containsKey(articleId)) {
        await getEngagement(articleId, userId: userId);
      }
    }
  }

  /// Update engagement from real-time listener (called by RealtimeEngagementService)
  void updateEngagementFromRealtime(ArticleEngagement engagement) {
    _engagementCache[engagement.articleId] = engagement;
    notifyListeners();
    log('🔄 Updated engagement from real-time: ${engagement.articleId}');
  }

  /// Clear engagement cache
  void clearCache() {
    _engagementCache.clear();
    notifyListeners();
    log('🧹 Cleared engagement cache');
  }
}
