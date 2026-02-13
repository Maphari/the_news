import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:the_news/service/engagement_service.dart';

/// Service to manage real-time engagement updates from Firestore
class RealtimeEngagementService extends ChangeNotifier {
  static final RealtimeEngagementService instance = RealtimeEngagementService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, StreamSubscription<DocumentSnapshot>> _listeners = {};
  final EngagementService _engagementService = EngagementService.instance;

  RealtimeEngagementService._init();

  /// Start listening to engagement changes for an article
  void listenToArticleEngagement(String articleId, {String? userId}) {
    // Don't create duplicate listeners
    if (_listeners.containsKey(articleId)) {
      return;
    }

    log('👂 Starting real-time listener for article: $articleId');

    final subscription = _firestore
        .collection('articleEngagement')
        .doc(articleId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists) {
          log('⚠️ Engagement document does not exist for: $articleId');
          return;
        }

        final data = snapshot.data();
        if (data == null) return;

        log('🔄 Real-time update for article: $articleId');

        // Check if user liked this article
        _checkUserLikeStatus(articleId, userId).then((isLiked) {
          // Update engagement cache
          final engagement = ArticleEngagement(
            articleId: articleId,
            likeCount: data['likeCount'] ?? 0,
            commentCount: data['commentCount'] ?? 0,
            shareCount: data['shareCount'] ?? 0,
            isLiked: isLiked,
          );

          _engagementService.updateEngagementFromRealtime(engagement);
        });
      },
      onError: (error) {
        // Permission errors are expected if Firestore rules aren't configured
        // Fall back to HTTP-only engagement silently
        if (error.toString().contains('permission-denied')) {
          log('ℹ️ Firestore real-time disabled for $articleId (using HTTP fallback)');
        } else {
          log('❌ Error in real-time listener for $articleId: $error');
        }
        // Clean up failed listener
        _listeners.remove(articleId);
      },
    );

    _listeners[articleId] = subscription;
  }

  /// Check if user has liked an article
  Future<bool> _checkUserLikeStatus(String articleId, String? userId) async {
    if (userId == null) return false;

    try {
      final querySnapshot = await _firestore
          .collection('userLikes')
          .where('userId', isEqualTo: userId)
          .where('articleId', isEqualTo: articleId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      log('⚠️ Error checking like status: $e');
      return false;
    }
  }

  /// Stop listening to engagement changes for an article
  void stopListeningToArticle(String articleId) {
    final subscription = _listeners[articleId];
    if (subscription != null) {
      subscription.cancel();
      _listeners.remove(articleId);
      log('🔇 Stopped real-time listener for article: $articleId');
    }
  }

  /// Stop all listeners
  void stopAllListeners() {
    for (final subscription in _listeners.values) {
      subscription.cancel();
    }
    _listeners.clear();
    log('🔇 Stopped all real-time listeners');
  }

  @override
  void dispose() {
    stopAllListeners();
    super.dispose();
  }
}
