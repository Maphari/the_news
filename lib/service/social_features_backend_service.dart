import 'dart:developer';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/model/reading_list_model.dart';
import 'package:the_news/model/activity_feed_model.dart';
import 'package:the_news/service/auth_service.dart';

/// Service for managing social features via backend API
/// Uses ApiClient for all network requests following clean architecture
class SocialFeaturesBackendService {
  static final SocialFeaturesBackendService instance = SocialFeaturesBackendService._init();
  SocialFeaturesBackendService._init();

  final _api = ApiClient.instance;
  final AuthService _authService = AuthService();

  // ===== USER PROFILES =====

  /// Get current user's profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final userData = await _authService.getCurrentUser();
    if (userData == null) return null;

    final userId = userData['id'] as String;
    return await getUserProfile(userId);
  }

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _api.get('social/profile/$userId');

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true && data['profile'] != null) {
          return UserProfile.fromMap(data['profile']);
        }
      } else if (response.statusCode == 404) {
        log('📭 Profile not found for user: $userId');
        return null;
      }
    } catch (e) {
      log('⚠️ Error loading user profile: $e');
    }
    return null;
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final response = await _api.post('social/profile', body: {
        'userId': profile.userId,
        'username': profile.username,
        'displayName': profile.displayName,
        'bio': profile.bio,
        'avatarUrl': profile.avatarUrl,
      });

      if (_api.isSuccess(response)) {
        log('✅ User profile updated: ${profile.username}');
      } else {
        throw Exception(_api.getErrorMessage(response));
      }
    } catch (e) {
      log('⚠️ Error updating user profile: $e');
      rethrow;
    }
  }

  /// Search users by username
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final response = await _api.get(
        'social/users/search',
        queryParams: {'query': query, 'limit': '50'},
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true && data['users'] != null) {
          final List<dynamic> usersJson = data['users'];
          return usersJson.map((json) => UserProfile.fromMap(json)).toList();
        }
      }
    } catch (e) {
      log('⚠️ Error searching users: $e');
    }
    return [];
  }

  // ===== FOLLOW SYSTEM =====

  /// Follow a user
  Future<void> followUser(String targetUserId) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) throw Exception('User not logged in');

    final currentUserId = currentUser['id'] as String;
    if (currentUserId == targetUserId) {
      throw Exception('Cannot follow yourself');
    }

    try {
      final response = await _api.post('social/follow', body: {
        'followerId': currentUserId,
        'followingId': targetUserId,
      });

      if (_api.isSuccess(response)) {
        log('✅ User followed: $targetUserId');
      } else {
        throw Exception(_api.getErrorMessage(response));
      }
    } catch (e) {
      log('⚠️ Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) throw Exception('User not logged in');

    final currentUserId = currentUser['id'] as String;

    try {
      final response = await _api.delete('social/follow', body: {
        'followerId': currentUserId,
        'followingId': targetUserId,
      });

      if (_api.isSuccess(response)) {
        log('✅ User unfollowed: $targetUserId');
      } else {
        throw Exception(_api.getErrorMessage(response));
      }
    } catch (e) {
      log('⚠️ Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Check if current user follows target user
  Future<bool> isFollowing(String targetUserId) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) return false;

    final currentUserId = currentUser['id'] as String;

    try {
      final response = await _api.get('social/follow/check/$currentUserId/$targetUserId');

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        return data['isFollowing'] ?? false;
      }
    } catch (e) {
      log('⚠️ Error checking follow status: $e');
    }
    return false;
  }

  /// Get followers of a user
  Future<List<UserProfile>> getFollowers(String userId) async {
    try {
      final response = await _api.get('social/followers/$userId');

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true && data['followers'] != null) {
          final List<dynamic> followersJson = data['followers'];
          return followersJson.map((json) => UserProfile.fromMap(json)).toList();
        }
      }
    } catch (e) {
      log('⚠️ Error getting followers: $e');
    }
    return [];
  }

  /// Get users that a user follows
  Future<List<UserProfile>> getFollowing(String userId) async {
    try {
      final response = await _api.get('social/following/$userId');

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true && data['following'] != null) {
          final List<dynamic> followingJson = data['following'];
          return followingJson.map((json) => UserProfile.fromMap(json)).toList();
        }
      }
    } catch (e) {
      log('⚠️ Error getting following: $e');
    }
    return [];
  }

  // ===== READING LISTS =====

  /// Create a reading list
  Future<ReadingList> createReadingList({
    required String name,
    String? description,
    ListVisibility visibility = ListVisibility.public,
    List<String> tags = const [],
  }) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) throw Exception('User not logged in');

    final userId = currentUser['id'] as String;

    try {
      final response = await _api.post('social/reading-lists', body: {
        'ownerId': userId,
        'name': name,
        'description': description,
        'visibility': visibility.toString().split('.').last,
        'tags': tags,
      });

      if (response.statusCode == 201) {
        final data = _api.parseJson(response);
        final listId = data['listId'];

        // Return the created list (fetch it to get full data)
        final lists = await getUserReadingLists(userId);
        return lists.firstWhere((list) => list.id == listId);
      } else {
        throw Exception(_api.getErrorMessage(response));
      }
    } catch (e) {
      log('⚠️ Error creating reading list: $e');
      rethrow;
    }
  }

  /// Get all reading lists for a user
  Future<List<ReadingList>> getUserReadingLists(String userId) async {
    try {
      final response = await _api.get('social/reading-lists/$userId');

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true && data['lists'] != null) {
          final List<dynamic> listsJson = data['lists'];
          return listsJson.map((json) => ReadingList.fromMap(json)).toList();
        }
      }
    } catch (e) {
      log('⚠️ Error loading reading lists: $e');
    }
    return [];
  }

  /// Get public reading lists
  Future<List<ReadingList>> getPublicReadingLists() async {
    try {
      final response = await _api.get(
        'social/reading-lists/public',
        queryParams: {'limit': '50'},
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true && data['lists'] != null) {
          final List<dynamic> listsJson = data['lists'];
          return listsJson.map((json) => ReadingList.fromMap(json)).toList();
        }
      }
    } catch (e) {
      log('⚠️ Error loading public lists: $e');
    }
    return [];
  }

  /// Add article to reading list
  Future<void> addArticleToList(String listId, String articleId) async {
    try {
      final response = await _api.post('social/reading-lists/articles', body: {
        'listId': listId,
        'articleId': articleId,
      });

      if (_api.isSuccess(response)) {
        log('✅ Article added to list');
      } else {
        throw Exception(_api.getErrorMessage(response));
      }
    } catch (e) {
      log('⚠️ Error adding article to list: $e');
      rethrow;
    }
  }

  // ===== ACTIVITY FEED =====

  /// Get activity feed for current user (from followed users)
  Future<List<ActivityFeedItem>> getActivityFeed({int limit = 50}) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) return [];

    final userId = currentUser['id'] as String;

    try {
      final response = await _api.get(
        'social/activity/$userId',
        queryParams: {'limit': limit.toString()},
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true && data['activities'] != null) {
          final List<dynamic> activitiesJson = data['activities'];
          return activitiesJson.map((json) => ActivityFeedItem.fromMap(json)).toList();
        }
      }
    } catch (e) {
      log('⚠️ Error loading activity feed: $e');
    }
    return [];
  }
}
