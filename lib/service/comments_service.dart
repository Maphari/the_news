import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:the_news/core/network/api_client.dart';

/// Comment model
class CommentModel {
  final String id;
  final String articleId;
  final String userId;
  final String userName;
  final String text;
  final String? parentCommentId;
  final int likeCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommentModel({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.userName,
    required this.text,
    this.parentCommentId,
    required this.likeCount,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      articleId: json['articleId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      text: json['text'] ?? '',
      parentCommentId: json['parentCommentId'],
      likeCount: json['likeCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Get replies (comments with this comment as parent)
  List<CommentModel> getReplies(List<CommentModel> allComments) {
    return allComments
        .where((comment) => comment.parentCommentId == id)
        .toList();
  }

  /// Check if this is a top-level comment (no parent)
  bool get isTopLevel => parentCommentId == null;
}

/// Service to manage comments
/// Uses ApiClient for all network requests following clean architecture
class CommentsService extends ChangeNotifier {
  static final CommentsService instance = CommentsService._init();
  CommentsService._init();

  final _api = ApiClient.instance;
  final Map<String, List<CommentModel>> _commentsCache = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get comments for an article
  Future<List<CommentModel>> getComments(String articleId, {String? userId}) async {
    // Check cache first
    if (_commentsCache.containsKey(articleId)) {
      return _commentsCache[articleId]!;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = userId != null ? {'userId': userId} : null;
      final response = await _api.get('comments/$articleId', queryParams: queryParams);

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final List<dynamic> commentsJson = data['comments'] ?? [];
          final comments = commentsJson
              .map((json) => CommentModel.fromJson(json))
              .toList();
          _commentsCache[articleId] = comments;
          log('✅ Loaded ${comments.length} comments');
          return comments;
        } else {
          throw Exception(data['message'] ?? 'Failed to load comments');
        }
      } else {
        throw Exception(_api.getErrorMessage(response));
      }
    } catch (e) {
      _error = e.toString();
      log('⚠️ Error loading comments: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a comment
  Future<bool> addComment({
    required String articleId,
    required String userId,
    required String userName,
    required String text,
    String? parentCommentId,
  }) async {
    try {
      log('💬 Adding comment to article: $articleId');

      final response = await _api.post(
        'comments',
        body: {
          'articleId': articleId,
          'userId': userId,
          'userName': userName,
          'text': text,
          if (parentCommentId != null) 'parentCommentId': parentCommentId,
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          // Clear cache to force reload
          _commentsCache.remove(articleId);
          notifyListeners();
          log('✅ Comment added successfully');
          return true;
        }
      }

      log('⚠️ Failed to add comment: ${_api.getErrorMessage(response)}');
      return false;
    } catch (e) {
      log('⚠️ Error adding comment: $e');
      return false;
    }
  }

  /// Update a comment
  Future<bool> updateComment({
    required String commentId,
    required String userId,
    required String text,
  }) async {
    try {
      log('✏️ Updating comment: $commentId');

      final response = await _api.put(
        'comments/$commentId',
        body: {
          'userId': userId,
          'text': text,
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          // Clear cache to force reload
          _commentsCache.clear();
          notifyListeners();
          log('✅ Comment updated successfully');
          return true;
        }
      }

      log('⚠️ Failed to update comment: ${_api.getErrorMessage(response)}');
      return false;
    } catch (e) {
      log('⚠️ Error updating comment: $e');
      return false;
    }
  }

  /// Delete a comment
  Future<bool> deleteComment({
    required String commentId,
    required String userId,
    required String articleId,
  }) async {
    try {
      log('🗑️ Deleting comment: $commentId');

      final response = await _api.delete(
        'comments/$commentId',
        body: {
          'userId': userId,
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          // Remove from cache
          _commentsCache.remove(articleId);
          notifyListeners();
          log('✅ Comment deleted successfully');
          return true;
        }
      }

      log('⚠️ Failed to delete comment: ${_api.getErrorMessage(response)}');
      return false;
    } catch (e) {
      log('⚠️ Error deleting comment: $e');
      return false;
    }
  }

  /// Like a comment
  Future<bool> likeComment(String commentId, String userId, String articleId) async {
    try {
      log('❤️ Liking comment: $commentId (user: $userId)');

      final response = await _api.post(
        'comments/like',
        body: {
          'commentId': commentId,
          'userId': userId,
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          // Clear cache to force reload
          _commentsCache.remove(articleId);
          notifyListeners();
          log('✅ Comment liked successfully');
          return true;
        }
      }

      log('⚠️ Failed to like comment: ${_api.getErrorMessage(response)}');
      return false;
    } catch (e) {
      log('⚠️ Error liking comment: $e');
      return false;
    }
  }

  /// Unlike a comment
  Future<bool> unlikeComment(String commentId, String userId, String articleId) async {
    try {
      log('💔 Unliking comment: $commentId (user: $userId)');

      final response = await _api.delete(
        'comments/like',
        body: {
          'commentId': commentId,
          'userId': userId,
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          // Clear cache to force reload
          _commentsCache.remove(articleId);
          notifyListeners();
          log('✅ Comment unliked successfully');
          return true;
        }
      }

      log('⚠️ Failed to unlike comment: ${_api.getErrorMessage(response)}');
      return false;
    } catch (e) {
      log('⚠️ Error unliking comment: $e');
      return false;
    }
  }

  /// Update comments from real-time listener (called by RealtimeCommentsService)
  void updateCommentsFromRealtime(String articleId, List<CommentModel> comments) {
    _commentsCache[articleId] = comments;
    notifyListeners();
    log('🔄 Updated ${comments.length} comments from real-time for article: $articleId');
  }

  /// Get cached comments for an article
  List<CommentModel>? getCachedComments(String articleId) {
    return _commentsCache[articleId];
  }

  /// Clear comments cache
  void clearCache() {
    _commentsCache.clear();
    notifyListeners();
    log('🧹 Cleared comments cache');
  }
}
