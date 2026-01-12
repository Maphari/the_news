import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/model/reading_list_model.dart';
import 'package:the_news/model/activity_feed_model.dart';
import 'package:the_news/service/auth_service.dart';

/// ✅ ACTIVE SERVICE - NOW CONNECTED TO UI
///
/// Service for managing social features: profiles, follows, lists, and activity feed
///
/// STATUS: Fully implemented with UI pages accessible via Profile → Social Hub
/// This service provides:
/// - User profiles
/// - Follow/unfollow system
/// - Reading lists management (create, view, collaborate)
/// - Activity feed tracking
///
/// UI Access: Profile Page → Social Section → "Social Hub" tile
class SocialFeaturesService {
  static final SocialFeaturesService instance = SocialFeaturesService._init();
  SocialFeaturesService._init();

  final AuthService _authService = AuthService();
  final Uuid _uuid = const Uuid();

  // Cache keys
  static const String _profilesKey = 'user_profiles';
  static const String _followsKey = 'user_follows';
  static const String _listsKey = 'reading_lists';
  static const String _activitiesKey = 'activity_feed';

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
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_profilesKey);

      if (data != null) {
        final profiles = jsonDecode(data) as Map<String, dynamic>;
        if (profiles.containsKey(userId)) {
          return UserProfile.fromMap(profiles[userId] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      log('⚠️ Error loading user profile: $e');
    }
    return null;
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_profilesKey);

      Map<String, dynamic> profiles = {};
      if (data != null) {
        profiles = Map<String, dynamic>.from(jsonDecode(data));
      }

      profiles[profile.userId] = profile.toMap();
      await prefs.setString(_profilesKey, jsonEncode(profiles));

      log('✅ User profile updated: ${profile.username}');
    } catch (e) {
      log('⚠️ Error updating user profile: $e');
      rethrow;
    }
  }

  /// Search users by username
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_profilesKey);

      if (data != null) {
        final profiles = jsonDecode(data) as Map<String, dynamic>;
        return profiles.values
            .map((p) => UserProfile.fromMap(p as Map<String, dynamic>))
            .where((p) =>
                p.username.toLowerCase().contains(query.toLowerCase()) ||
                p.displayName.toLowerCase().contains(query.toLowerCase()))
            .toList();
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
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_followsKey);

      List<UserFollow> follows = [];
      if (data != null) {
        final list = jsonDecode(data) as List;
        follows = list.map((f) => UserFollow.fromMap(f)).toList();
      }

      // Check if already following
      final existing = follows.any(
        (f) => f.followerId == currentUserId && f.followingId == targetUserId,
      );

      if (existing) {
        throw Exception('Already following this user');
      }

      // Add new follow
      follows.add(UserFollow(
        id: _uuid.v4(),
        followerId: currentUserId,
        followingId: targetUserId,
        followedAt: DateTime.now(),
      ));

      await prefs.setString(_followsKey, jsonEncode(follows.map((f) => f.toMap()).toList()));

      // Update follower/following counts
      await _updateFollowCounts(currentUserId, targetUserId);

      // Add activity
      final currentProfile = await getUserProfile(currentUserId);
      final targetProfile = await getUserProfile(targetUserId);

      if (currentProfile != null && targetProfile != null) {
        await _addActivity(ActivityFeedItem.followUser(
          userId: currentUserId,
          username: currentProfile.username,
          userAvatarUrl: currentProfile.avatarUrl,
          followedUserId: targetUserId,
          followedUsername: targetProfile.username,
        ));
      }

      log('✅ User followed: $targetUserId');
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
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_followsKey);

      if (data != null) {
        List<UserFollow> follows = (jsonDecode(data) as List)
            .map((f) => UserFollow.fromMap(f))
            .toList();

        follows.removeWhere(
          (f) => f.followerId == currentUserId && f.followingId == targetUserId,
        );

        await prefs.setString(_followsKey, jsonEncode(follows.map((f) => f.toMap()).toList()));

        // Update follower/following counts
        await _updateFollowCounts(currentUserId, targetUserId);

        log('✅ User unfollowed: $targetUserId');
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
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_followsKey);

      if (data != null) {
        final follows = (jsonDecode(data) as List)
            .map((f) => UserFollow.fromMap(f))
            .toList();

        return follows.any(
          (f) => f.followerId == currentUserId && f.followingId == targetUserId,
        );
      }
    } catch (e) {
      log('⚠️ Error checking follow status: $e');
    }
    return false;
  }

  /// Get followers of a user
  Future<List<UserProfile>> getFollowers(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_followsKey);

      if (data != null) {
        final follows = (jsonDecode(data) as List)
            .map((f) => UserFollow.fromMap(f))
            .where((f) => f.followingId == userId)
            .toList();

        final followerProfiles = <UserProfile>[];
        for (final follow in follows) {
          final profile = await getUserProfile(follow.followerId);
          if (profile != null) {
            followerProfiles.add(profile);
          }
        }

        return followerProfiles;
      }
    } catch (e) {
      log('⚠️ Error getting followers: $e');
    }
    return [];
  }

  /// Get users that a user follows
  Future<List<UserProfile>> getFollowing(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_followsKey);

      if (data != null) {
        final follows = (jsonDecode(data) as List)
            .map((f) => UserFollow.fromMap(f))
            .where((f) => f.followerId == userId)
            .toList();

        final followingProfiles = <UserProfile>[];
        for (final follow in follows) {
          final profile = await getUserProfile(follow.followingId);
          if (profile != null) {
            followingProfiles.add(profile);
          }
        }

        return followingProfiles;
      }
    } catch (e) {
      log('⚠️ Error getting following: $e');
    }
    return [];
  }

  Future<void> _updateFollowCounts(String followerId, String followingId) async {
    final followerProfile = await getUserProfile(followerId);
    final followingProfile = await getUserProfile(followingId);

    if (followerProfile != null && followingProfile != null) {
      final followers = await getFollowers(followingId);
      final following = await getFollowing(followerId);

      await updateUserProfile(
        followerProfile.copyWith(followingCount: following.length),
      );

      await updateUserProfile(
        followingProfile.copyWith(followersCount: followers.length),
      );
    }
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
    final profile = await getUserProfile(userId);

    final list = ReadingList(
      id: _uuid.v4(),
      name: name,
      description: description,
      ownerId: userId,
      ownerName: profile?.username ?? currentUser['email'] as String,
      visibility: visibility,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_listsKey);

      List<ReadingList> lists = [];
      if (data != null) {
        lists = (jsonDecode(data) as List)
            .map((l) => ReadingList.fromMap(l))
            .toList();
      }

      lists.add(list);
      await prefs.setString(_listsKey, jsonEncode(lists.map((l) => l.toMap()).toList()));

      // Add activity
      if (profile != null) {
        await _addActivity(ActivityFeedItem.createList(
          userId: userId,
          username: profile.username,
          userAvatarUrl: profile.avatarUrl,
          listId: list.id,
          listName: list.name,
        ));
      }

      log('✅ Reading list created: ${list.name}');
      return list;
    } catch (e) {
      log('⚠️ Error creating reading list: $e');
      rethrow;
    }
  }

  /// Get all reading lists for a user
  Future<List<ReadingList>> getUserReadingLists(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_listsKey);

      if (data != null) {
        final lists = (jsonDecode(data) as List)
            .map((l) => ReadingList.fromMap(l))
            .where((l) => l.ownerId == userId || l.collaboratorIds.contains(userId))
            .toList();

        return lists;
      }
    } catch (e) {
      log('⚠️ Error loading reading lists: $e');
    }
    return [];
  }

  /// Get public reading lists
  Future<List<ReadingList>> getPublicReadingLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_listsKey);

      if (data != null) {
        final lists = (jsonDecode(data) as List)
            .map((l) => ReadingList.fromMap(l))
            .where((l) => l.isPublic)
            .toList();

        // Sort by most recent
        lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return lists;
      }
    } catch (e) {
      log('⚠️ Error loading public lists: $e');
    }
    return [];
  }

  /// Add article to reading list
  Future<void> addArticleToList(String listId, String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_listsKey);

      if (data != null) {
        List<ReadingList> lists = (jsonDecode(data) as List)
            .map((l) => ReadingList.fromMap(l))
            .toList();

        final index = lists.indexWhere((l) => l.id == listId);
        if (index != -1) {
          final list = lists[index];
          if (!list.articleIds.contains(articleId)) {
            final updatedList = list.copyWith(
              articleIds: [...list.articleIds, articleId],
              updatedAt: DateTime.now(),
            );

            lists[index] = updatedList;
            await prefs.setString(_listsKey, jsonEncode(lists.map((l) => l.toMap()).toList()));

            log('✅ Article added to list: ${list.name}');
          }
        }
      }
    } catch (e) {
      log('⚠️ Error adding article to list: $e');
      rethrow;
    }
  }

  /// Add collaborator to reading list
  Future<void> addCollaborator(String listId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_listsKey);

      if (data != null) {
        List<ReadingList> lists = (jsonDecode(data) as List)
            .map((l) => ReadingList.fromMap(l))
            .toList();

        final index = lists.indexWhere((l) => l.id == listId);
        if (index != -1) {
          final list = lists[index];
          if (!list.collaboratorIds.contains(userId)) {
            final updatedList = list.copyWith(
              collaboratorIds: [...list.collaboratorIds, userId],
              updatedAt: DateTime.now(),
            );

            lists[index] = updatedList;
            await prefs.setString(_listsKey, jsonEncode(lists.map((l) => l.toMap()).toList()));

            log('✅ Collaborator added to list: ${list.name}');
          }
        }
      }
    } catch (e) {
      log('⚠️ Error adding collaborator: $e');
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
      // Get users that current user follows
      final following = await getFollowing(userId);
      final followingIds = following.map((u) => u.userId).toSet();

      // Get all activities
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_activitiesKey);

      if (data != null) {
        final activities = (jsonDecode(data) as List)
            .map((a) => ActivityFeedItem.fromMap(a))
            .where((a) => followingIds.contains(a.userId))
            .toList();

        // Sort by most recent
        activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return activities.take(limit).toList();
      }
    } catch (e) {
      log('⚠️ Error loading activity feed: $e');
    }
    return [];
  }

  Future<void> _addActivity(ActivityFeedItem activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_activitiesKey);

      List<ActivityFeedItem> activities = [];
      if (data != null) {
        activities = (jsonDecode(data) as List)
            .map((a) => ActivityFeedItem.fromMap(a))
            .toList();
      }

      activities.add(activity);

      // Keep only last 1000 activities
      if (activities.length > 1000) {
        activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        activities = activities.take(1000).toList();
      }

      await prefs.setString(_activitiesKey, jsonEncode(activities.map((a) => a.toMap()).toList()));
    } catch (e) {
      log('⚠️ Error adding activity: $e');
    }
  }

  // ===== CLEAR DATA =====

  /// Clear all social data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profilesKey);
      await prefs.remove(_followsKey);
      await prefs.remove(_listsKey);
      await prefs.remove(_activitiesKey);
      log('🗑️ All social data cleared');
    } catch (e) {
      log('⚠️ Error clearing social data: $e');
    }
  }
}
