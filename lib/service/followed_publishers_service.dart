import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:the_news/core/network/api_client.dart';

/// Service to manage followed publishers
/// Uses ApiClient for all network requests following clean architecture
class FollowedPublishersService extends ChangeNotifier {
  static final FollowedPublishersService instance = FollowedPublishersService._init();
  FollowedPublishersService._init();

  final _api = ApiClient.instance;
  Set<String> _followedPublisherNames = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  Set<String> get followedPublisherNames => _followedPublisherNames;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get followedCount => _followedPublisherNames.length;

  /// Check if a publisher is followed
  bool isPublisherFollowed(String publisherName) {
    return _followedPublisherNames.contains(publisherName);
  }

  /// Load followed publishers for a user
  Future<void> loadFollowedPublishers(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      log('📥 Fetching followed publishers for user: $userId');

      final response = await _api.get('followed-publishers/$userId');

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final List<dynamic> publishers = data['publishers'] ?? [];
          _followedPublisherNames = publishers.map((name) => name.toString()).toSet();
          log('✅ Loaded ${_followedPublisherNames.length} followed publishers');
        } else {
          throw Exception(data['message'] ?? 'Failed to load followed publishers');
        }
      } else {
        throw Exception(_api.getErrorMessage(response));
      }
    } catch (e) {
      _error = e.toString();
      log('⚠️ Error loading followed publishers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Follow a publisher
  Future<bool> followPublisher(String userId, String publisherName) async {
    try {
      log('➕ Following publisher: $publisherName for user: $userId');

      final response = await _api.post(
        'followed-publishers/follow',
        body: {
          'userId': userId,
          'publisherName': publisherName,
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          _followedPublisherNames.add(publisherName);
          notifyListeners();
          log('✅ Publisher followed successfully: $publisherName');
          return true;
        }
      }

      log('⚠️ Failed to follow publisher: ${_api.getErrorMessage(response)}');
      return false;
    } catch (e) {
      log('⚠️ Error following publisher: $e');
      return false;
    }
  }

  /// Unfollow a publisher
  Future<bool> unfollowPublisher(String userId, String publisherName) async {
    try {
      log('➖ Unfollowing publisher: $publisherName for user: $userId');

      final response = await _api.delete(
        'followed-publishers/follow',
        body: {
          'userId': userId,
          'publisherName': publisherName,
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          _followedPublisherNames.remove(publisherName);
          notifyListeners();
          log('✅ Publisher unfollowed successfully: $publisherName');
          return true;
        }
      }

      log('⚠️ Failed to unfollow publisher: ${_api.getErrorMessage(response)}');
      return false;
    } catch (e) {
      log('⚠️ Error unfollowing publisher: $e');
      return false;
    }
  }

  /// Toggle follow status for a publisher
  Future<bool> toggleFollow(String userId, String publisherName) async {
    if (isPublisherFollowed(publisherName)) {
      return await unfollowPublisher(userId, publisherName);
    } else {
      return await followPublisher(userId, publisherName);
    }
  }

  /// Clear all followed publishers (local state only)
  void clearFollowedPublishers() {
    _followedPublisherNames.clear();
    notifyListeners();
    log('🧹 Cleared followed publishers from local state');
  }
}
