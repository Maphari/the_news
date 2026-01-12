import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:the_news/service/comments_service.dart';

/// Service to manage real-time comment updates from Firestore
class RealtimeCommentsService extends ChangeNotifier {
  static final RealtimeCommentsService instance = RealtimeCommentsService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, StreamSubscription<QuerySnapshot>> _listeners = {};
  final CommentsService _commentsService = CommentsService.instance;

  RealtimeCommentsService._init();

  /// Start listening to comment changes for an article
  void listenToArticleComments(String articleId, {String? userId}) {
    // Don't create duplicate listeners
    if (_listeners.containsKey(articleId)) {
      return;
    }

    log('👂 Starting real-time comment listener for article: $articleId');

    final subscription = _firestore
        .collection('comments')
        .where('articleId', isEqualTo: articleId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        log('🔄 Real-time comment update for article: $articleId (${snapshot.docs.length} comments)');

        // Convert Firestore documents to CommentModel
        final comments = snapshot.docs.map((doc) {
          final data = doc.data();
          return CommentModel(
            id: doc.id,
            articleId: data['articleId'] ?? '',
            userId: data['userId'] ?? '',
            userName: data['userName'] ?? '',
            text: data['text'] ?? '',
            parentCommentId: data['parentCommentId'],
            likeCount: data['likeCount'] ?? 0,
            isLiked: false, // Will be checked separately if needed
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          );
        }).toList();

        // Update comments cache
        _commentsService.updateCommentsFromRealtime(articleId, comments);
      },
      onError: (error) {
        log('❌ Error in real-time comment listener for $articleId: $error');
      },
    );

    _listeners[articleId] = subscription;
  }

  /// Stop listening to comment changes for an article
  void stopListeningToArticle(String articleId) {
    final subscription = _listeners[articleId];
    if (subscription != null) {
      subscription.cancel();
      _listeners.remove(articleId);
      log('🔇 Stopped real-time comment listener for article: $articleId');
    }
  }

  /// Stop all listeners
  void stopAllListeners() {
    for (final subscription in _listeners.values) {
      subscription.cancel();
    }
    _listeners.clear();
    log('🔇 Stopped all real-time comment listeners');
  }

  @override
  void dispose() {
    stopAllListeners();
    super.dispose();
  }
}
