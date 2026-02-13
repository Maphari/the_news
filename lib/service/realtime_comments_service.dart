import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/service/comments_service.dart';

/// Service to manage real-time comment updates from Firestore
class RealtimeCommentsService extends ChangeNotifier {
  static final RealtimeCommentsService instance = RealtimeCommentsService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, StreamSubscription<QuerySnapshot>> _listeners = {};
  final Map<String, Object> _errors = {};
  final CommentsService _commentsService = CommentsService.instance;
  bool _enabled = true;

  RealtimeCommentsService._init();

  static const String _prefsKey = 'realtime_comments_enabled';

  bool get isEnabled => _enabled;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKey) ?? true;
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
    if (!enabled) {
      stopAllListeners();
    }
    notifyListeners();
  }

  /// Start listening to comment changes for an article
  void listenToArticleComments(String articleId, {String? userId}) {
    if (!_enabled) {
      return;
    }

    // Don't create duplicate listeners
    if (_listeners.containsKey(articleId)) {
      return;
    }

    _errors.remove(articleId);
    log('👂 Starting real-time comment listener for article: $articleId');

    final subscription = _firestore
        .collection('comments')
        .where('articleId', isEqualTo: articleId)
        .snapshots()
        .listen(
      (snapshot) {
        log('🔄 Real-time comment update for article: $articleId (${snapshot.docs.length} comments)');

        // Convert Firestore documents to CommentModel
        final comments = snapshot.docs
            .map((doc) {
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
            })
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Update comments cache
        _commentsService.updateCommentsFromRealtime(articleId, comments);
      },
      onError: (error) {
        log('❌ Error in real-time comment listener for $articleId: $error');
        _errors[articleId] = error;
        stopListeningToArticle(articleId);
        if (_isPermissionDenied(error)) {
          setEnabled(false);
        }
        notifyListeners();
      },
    );

    _listeners[articleId] = subscription;
    notifyListeners();
  }

  /// Stop listening to comment changes for an article
  void stopListeningToArticle(String articleId) {
    final subscription = _listeners[articleId];
    if (subscription != null) {
      subscription.cancel();
      _listeners.remove(articleId);
      log('🔇 Stopped real-time comment listener for article: $articleId');
      notifyListeners();
    }
  }

  /// Stop all listeners
  void stopAllListeners() {
    for (final subscription in _listeners.values) {
      subscription.cancel();
    }
    _listeners.clear();
    log('🔇 Stopped all real-time comment listeners');
    notifyListeners();
  }

  bool isListening(String articleId) => _listeners.containsKey(articleId);

  Object? getError(String articleId) => _errors[articleId];

  bool _isPermissionDenied(Object error) {
    return error is FirebaseException && error.code == 'permission-denied';
  }

  @override
  void dispose() {
    stopAllListeners();
    super.dispose();
  }
}
