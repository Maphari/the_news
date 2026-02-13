import 'dart:developer';
import 'dart:async';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/model/reading_list_model.dart';
import 'package:the_news/model/activity_feed_model.dart';
import 'package:the_news/model/network_highlight_model.dart';
import 'package:the_news/model/social_post_model.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/social_features_service.dart';

/// Service for managing social features via backend API
/// Uses ApiClient for all network requests following clean architecture
class SocialFeaturesBackendService {
  static final SocialFeaturesBackendService instance =
      SocialFeaturesBackendService._init();
  SocialFeaturesBackendService._init();

  final _api = ApiClient.instance;
  final AuthService _authService = AuthService();
  final SocialFeaturesService _localSocial = SocialFeaturesService.instance;

  static const int defaultPeoplePageSize = 20;
  static const Duration _defaultTtl = Duration(seconds: 20);
  static const Duration _shortTtl = Duration(seconds: 8);
  final Map<String, _MemoryCacheEntry<dynamic>> _cache = {};
  final Map<String, Future<dynamic>> _inFlight = {};

  Future<T> _cachedRequest<T>({
    required String key,
    required Future<T> Function() loader,
    Duration ttl = _defaultTtl,
    bool forceRefresh = false,
  }) {
    if (!forceRefresh) {
      final cached = _cache[key];
      if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
        return Future<T>.value(cached.value as T);
      }

      final pending = _inFlight[key];
      if (pending != null) {
        return pending.then((value) => value as T);
      }
    }

    final future = loader();
    _inFlight[key] = future;
    return future.then((value) {
      _cache[key] = _MemoryCacheEntry<dynamic>(
        value: value,
        expiresAt: DateTime.now().add(ttl),
      );
      _inFlight.remove(key);
      return value;
    }).catchError((error) {
      _inFlight.remove(key);
      throw error;
    });
  }

  void _invalidateCacheByPrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
    _inFlight.removeWhere((key, _) => key.startsWith(prefix));
  }

  void _invalidateSocialReadCaches() {
    _invalidateCacheByPrefix('profile:');
    _invalidateCacheByPrefix('insights:');
    _invalidateCacheByPrefix('myspace:');
    _invalidateCacheByPrefix('feed:');
    _invalidateCacheByPrefix('followers:');
    _invalidateCacheByPrefix('following:');
    _invalidateCacheByPrefix('recommended:');
    _invalidateCacheByPrefix('readinglists:');
    _invalidateCacheByPrefix('publiclists:');
    _invalidateCacheByPrefix('list:');
    _invalidateCacheByPrefix('activity:');
    _invalidateCacheByPrefix('highlights:');
    _invalidateCacheByPrefix('posts:');
    _invalidateCacheByPrefix('articlesByIds:');
  }

  // ===== USER PROFILES =====

  /// Get current user's profile
  Future<UserProfile?> getCurrentUserProfile({bool forceRefresh = false}) async {
    final userData = await _authService.getCurrentUser();
    if (userData == null) return null;

    final userId = userData['id'] as String? ?? userData['userId'] as String;
    return await getUserProfile(userId, forceRefresh: forceRefresh);
  }

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return _cachedRequest<UserProfile?>(
      key: 'profile:$userId',
      forceRefresh: forceRefresh,
      ttl: _defaultTtl,
      loader: () async {
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
        try {
          return await _localSocial.getUserProfile(userId);
        } catch (_) {
          return null;
        }
      },
    );
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final response = await _api.post(
        'social/profile',
        body: {
          'userId': profile.userId,
          'username': profile.username,
          'displayName': profile.displayName,
          'bio': profile.bio,
          'avatarUrl': profile.avatarUrl,
          'socialLinks': profile.socialLinks,
          'privacySettings': profile.privacySettings,
          'featuredListId': profile.featuredListId,
        },
      );

      if (_api.isSuccess(response)) {
        log('✅ User profile updated: ${profile.username}');
        _invalidateSocialReadCaches();
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
    try {
      return await _localSocial.searchUsers(query);
    } catch (_) {
      return [];
    }
  }

  /// Get recommended users to follow
  Future<List<UserProfile>> getRecommendedUsers(
    String userId, {
    int limit = 10,
  }) async {
    final page = await getRecommendedUsersPaginated(userId, limit: limit);
    return page.users;
  }

  /// Get paginated recommended users
  Future<PaginatedUsersPage> getRecommendedUsersPaginated(
    String userId, {
    int limit = defaultPeoplePageSize,
    String? cursor,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'recommended:$userId:$limit:${cursor ?? ''}';
    return _cachedRequest<PaginatedUsersPage>(
      key: cacheKey,
      forceRefresh: forceRefresh,
      ttl: _defaultTtl,
      loader: () async {
        try {
          final response = await _api.get(
            'social/users/recommended/$userId',
            queryParams: {
              'limit': limit.toString(),
              if (cursor != null) 'cursor': cursor,
            },
          );

          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['users'] != null) {
              final List<dynamic> usersJson = data['users'];
              return PaginatedUsersPage(
                users: usersJson.map((json) => UserProfile.fromMap(json)).toList(),
                hasMore: data['hasMore'] as bool? ?? false,
                nextCursor: data['nextCursor'] as String?,
              );
            }
          }
        } catch (e) {
          log('⚠️ Error loading recommended users: $e');
        }
        return const PaginatedUsersPage(users: []);
      },
    );
  }

  // ===== PROFILE INSIGHTS =====

  Future<Map<String, dynamic>?> getProfileInsights(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return _cachedRequest<Map<String, dynamic>?>(
      key: 'insights:$userId',
      forceRefresh: forceRefresh,
      ttl: _defaultTtl,
      loader: () async {
        try {
          final response = await _api.get('social/profile/$userId/insights');

          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['insights'] != null) {
              return Map<String, dynamic>.from(data['insights']);
            }
          }
        } catch (e) {
          log('⚠️ Error loading profile insights: $e');
        }
        return null;
      },
    );
  }

  Future<Map<String, dynamic>?> getMySpaceSummary(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return _cachedRequest<Map<String, dynamic>?>(
      key: 'myspace:$userId',
      forceRefresh: forceRefresh,
      ttl: _defaultTtl,
      loader: () async {
        try {
          final response = await _api.get('social/my-space/$userId');
          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['summary'] != null) {
              return Map<String, dynamic>.from(data['summary']);
            }
          }
        } catch (e) {
          log('⚠️ Error loading My Space summary: $e');
        }
        return null;
      },
    );
  }

  Future<FeedSummaryPage?> getFeedSummary(
    String userId, {
    int activityLimit = 30,
    int highlightsLimit = 20,
    int postPreviewLimit = 20,
    bool forceRefresh = false,
  }) async {
    final key = 'feed:$userId:$activityLimit:$highlightsLimit:$postPreviewLimit';
    return _cachedRequest<FeedSummaryPage?>(
      key: key,
      forceRefresh: forceRefresh,
      ttl: _shortTtl,
      loader: () async {
        try {
          final response = await _api.get(
            'social/feed-summary/$userId',
            queryParams: {
              'activityLimit': activityLimit.toString(),
              'highlightsLimit': highlightsLimit.toString(),
              'postPreviewLimit': postPreviewLimit.toString(),
            },
          );
          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['feed'] != null) {
              final feed = Map<String, dynamic>.from(data['feed'] as Map);
              final recent = (feed['recentActivity'] as List? ?? const [])
                  .map((e) => ActivityFeedItem.fromMap(Map<String, dynamic>.from(e)))
                  .toList();
              final shared = (feed['sharedActivity'] as List? ?? const [])
                  .map((e) => ActivityFeedItem.fromMap(Map<String, dynamic>.from(e)))
                  .toList();
              final highlights = (feed['networkHighlights'] as List? ?? const [])
                  .map((e) => NetworkHighlight.fromMap(Map<String, dynamic>.from(e)))
                  .toList();
              final previewPosts = (feed['previewPosts'] as List? ?? const [])
                  .map((e) => SocialPost.fromMap(Map<String, dynamic>.from(e)))
                  .toList();
              final publishers = (feed['followedPublishers'] as List? ?? const [])
                  .whereType<String>()
                  .toList();
              final topics =
                  (feed['followedTopics'] as List? ?? const []).whereType<String>().toList();

              return FeedSummaryPage(
                recentActivity: recent,
                sharedActivity: shared,
                networkHighlights: highlights,
                previewPosts: previewPosts,
                followedPublishers: publishers,
                followedTopics: topics,
              );
            }
          }
        } catch (e) {
          log('⚠️ Error loading feed summary: $e');
        }
        return null;
      },
    );
  }

  Future<PeopleSummaryPage?> getPeopleSummary(
    String userId, {
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final key = 'people-summary:$userId:$limit';
    return _cachedRequest<PeopleSummaryPage?>(
      key: key,
      forceRefresh: forceRefresh,
      ttl: _shortTtl,
      loader: () async {
        try {
          final response = await _api.get(
            'social/people-summary/$userId',
            queryParams: {'limit': limit.toString()},
          );
          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['people'] != null) {
              final people = Map<String, dynamic>.from(data['people'] as Map);
              final followers = (people['followers'] as List? ?? const [])
                  .map((e) => UserProfile.fromMap(Map<String, dynamic>.from(e)))
                  .toList();
              final following = (people['following'] as List? ?? const [])
                  .map((e) => UserProfile.fromMap(Map<String, dynamic>.from(e)))
                  .toList();
              final recommended = (people['recommended'] as List? ?? const [])
                  .map((e) => UserProfile.fromMap(Map<String, dynamic>.from(e)))
                  .toList();
              return PeopleSummaryPage(
                followers: followers,
                following: following,
                recommended: recommended,
              );
            }
          }
        } catch (e) {
          log('⚠️ Error loading people summary: $e');
        }
        return null;
      },
    );
  }

  // ===== FOLLOW SYSTEM =====

  /// Follow a user
  Future<void> followUser(String targetUserId) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) throw Exception('User not logged in');

    final currentUserId =
        currentUser['id'] as String? ?? currentUser['userId'] as String;
    if (currentUserId == targetUserId) {
      throw Exception('Cannot follow yourself');
    }

    try {
      final response = await _api.post(
        'social/follow',
        body: {'followerId': currentUserId, 'followingId': targetUserId},
      );

      if (_api.isSuccess(response)) {
        log('✅ User followed: $targetUserId');
        _invalidateSocialReadCaches();
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

    final currentUserId =
        currentUser['id'] as String? ?? currentUser['userId'] as String;

    try {
      final response = await _api.delete(
        'social/follow',
        body: {'followerId': currentUserId, 'followingId': targetUserId},
      );

      if (_api.isSuccess(response)) {
        log('✅ User unfollowed: $targetUserId');
        _invalidateSocialReadCaches();
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

    final currentUserId =
        currentUser['id'] as String? ?? currentUser['userId'] as String;

    try {
      final response = await _api.get(
        'social/follow/check/$currentUserId/$targetUserId',
      );

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
  Future<List<UserProfile>> getFollowers(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return _cachedRequest<List<UserProfile>>(
      key: 'followers:$userId',
      forceRefresh: forceRefresh,
      ttl: _defaultTtl,
      loader: () async {
        try {
          final response = await _api.get('social/followers/$userId');

          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['followers'] != null) {
              final List<dynamic> followersJson = data['followers'];
              return followersJson
                  .map((json) => UserProfile.fromMap(json))
                  .toList();
            }
          }
        } catch (e) {
          log('⚠️ Error getting followers: $e');
        }
        try {
          return await _localSocial.getFollowers(userId);
        } catch (_) {
          return [];
        }
      },
    );
  }

  /// Get users that a user follows
  Future<List<UserProfile>> getFollowing(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return _cachedRequest<List<UserProfile>>(
      key: 'following:$userId',
      forceRefresh: forceRefresh,
      ttl: _defaultTtl,
      loader: () async {
        try {
          final response = await _api.get('social/following/$userId');

          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['following'] != null) {
              final List<dynamic> followingJson = data['following'];
              return followingJson
                  .map((json) => UserProfile.fromMap(json))
                  .toList();
            }
          }
        } catch (e) {
          log('⚠️ Error getting following: $e');
        }
        try {
          return await _localSocial.getFollowing(userId);
        } catch (_) {
          return [];
        }
      },
    );
  }

  /// Get paginated list of users that a user follows
  Future<PaginatedUsersPage> getFollowingPaginated(
    String userId, {
    int limit = defaultPeoplePageSize,
    String? cursor,
    bool forceRefresh = false,
  }) async {
    final key = 'followingPaged:$userId:$limit:${cursor ?? ''}';
    return _cachedRequest<PaginatedUsersPage>(
      key: key,
      forceRefresh: forceRefresh,
      ttl: _defaultTtl,
      loader: () async {
        try {
          final response = await _api.get(
            'social/following/$userId',
            queryParams: {
              'limit': limit.toString(),
              if (cursor != null) 'cursor': cursor,
            },
          );

          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['following'] != null) {
              final List<dynamic> followingJson = data['following'];
              return PaginatedUsersPage(
                users: followingJson
                    .map((json) => UserProfile.fromMap(json))
                    .toList(),
                hasMore: data['hasMore'] as bool? ?? false,
                nextCursor: data['nextCursor'] as String?,
              );
            }
          }
        } catch (e) {
          log('⚠️ Error getting paginated following: $e');
        }
        return const PaginatedUsersPage(users: []);
      },
    );
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
      final response = await _api.post(
        'social/reading-lists',
        body: {
          'ownerId': userId,
          'name': name,
          'description': description,
          'visibility': visibility.toString().split('.').last,
          'tags': tags,
        },
      );

      if (response.statusCode == 201) {
        final data = _api.parseJson(response);
        final listId = data['listId'];
        _invalidateCacheByPrefix('readinglists:$userId');
        _invalidateSocialReadCaches();

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
  Future<List<ReadingList>> getUserReadingLists(
    String userId, {
    bool forceRefresh = false,
  }) async {
    return _cachedRequest<List<ReadingList>>(
      key: 'readinglists:$userId',
      forceRefresh: forceRefresh,
      ttl: _defaultTtl,
      loader: () async {
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
      },
    );
  }

  /// Get public reading lists
  Future<List<ReadingList>> getPublicReadingLists() async {
    final page = await getPublicReadingListsPaginated(limit: 50);
    return page.lists;
  }

  /// Get paginated public reading lists for discover.
  Future<PaginatedReadingListsPage> getPublicReadingListsPaginated({
    int limit = 20,
    String? cursor,
    String? query,
    String? tag,
    bool forceRefresh = false,
  }) async {
    final key = 'publiclists:$limit:${cursor ?? ''}:${query ?? ''}:${tag ?? ''}';
    return _cachedRequest<PaginatedReadingListsPage>(
      key: key,
      forceRefresh: forceRefresh,
      ttl: _defaultTtl,
      loader: () async {
        try {
          final response = await _api.get(
            'social/reading-lists/public',
            queryParams: {
              'limit': limit.toString(),
              if (cursor != null) 'cursor': cursor,
              if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
              if (tag != null && tag.trim().isNotEmpty) 'tag': tag.trim(),
            },
          );

          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['lists'] != null) {
              final List<dynamic> listsJson = data['lists'];
              return PaginatedReadingListsPage(
                lists: listsJson.map((json) => ReadingList.fromMap(json)).toList(),
                hasMore: data['hasMore'] as bool? ?? false,
                nextCursor: data['nextCursor'] as String?,
              );
            }
          }
        } catch (e) {
          log('⚠️ Error loading public lists: $e');
        }
        return const PaginatedReadingListsPage(lists: []);
      },
    );
  }

  /// Add article to reading list
  Future<void> addArticleToList(String listId, String articleId) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      final userId = currentUser?['id'] as String? ?? currentUser?['userId'] as String?;

      final response = await _api.post(
        'social/reading-lists/articles',
        body: {
          'listId': listId,
          'articleId': articleId,
          if (userId != null && userId.isNotEmpty) 'userId': userId,
        },
      );

      if (_api.isSuccess(response)) {
        log('✅ Article added to list');
        _invalidateSocialReadCaches();
      } else {
        throw Exception(_api.getErrorMessage(response));
      }
    } catch (e) {
      log('⚠️ Error adding article to list: $e');
      rethrow;
    }
  }

  /// Add collaborator to a list. Caller must be list owner.
  Future<void> addCollaboratorToList({
    required String listId,
    required String collaboratorId,
    required String ownerId,
  }) async {
    try {
      final response = await _api.post(
        'social/reading-lists/collaborators',
        body: {
          'listId': listId,
          'ownerId': ownerId,
          'collaboratorId': collaboratorId,
        },
      );

      if (_api.isSuccess(response)) {
        log('✅ Collaborator added to list');
        _invalidateSocialReadCaches();
      } else {
        throw Exception(_api.getErrorMessage(response));
      }
    } catch (e) {
      log('⚠️ Error adding collaborator to list: $e');
      rethrow;
    }
  }

  /// Get reading list by id
  Future<ReadingList?> getReadingListById(
    String listId, {
    bool forceRefresh = false,
  }) async {
    final currentUser = await _authService.getCurrentUser();
    final viewerId = currentUser?['id'] as String? ?? currentUser?['userId'] as String?;
    final key = 'list:$listId:${viewerId ?? ''}';
    return _cachedRequest<ReadingList?>(
      key: key,
      forceRefresh: forceRefresh,
      ttl: _defaultTtl,
      loader: () async {
        try {
          final response = await _api.get(
            'social/reading-lists/list/$listId',
            queryParams: {
              if (viewerId != null && viewerId.isNotEmpty) 'viewerId': viewerId,
            },
          );

          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['list'] != null) {
              return ReadingList.fromMap(data['list']);
            }
          }
        } catch (e) {
          log('⚠️ Error loading reading list: $e');
        }
        return null;
      },
    );
  }

  /// Remove an article from list
  Future<void> removeArticleFromList(String listId, String articleId) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      final userId = currentUser?['id'] as String? ?? currentUser?['userId'] as String?;

      final response = await _api.delete(
        'social/reading-lists/articles',
        body: {
          'listId': listId,
          'articleId': articleId,
          if (userId != null && userId.isNotEmpty) 'userId': userId,
        },
      );

      if (!_api.isSuccess(response)) {
        throw Exception(_api.getErrorMessage(response));
      }
      _invalidateSocialReadCaches();
    } catch (e) {
      log('⚠️ Error removing article from list: $e');
      rethrow;
    }
  }

  /// Reorder list articles by article ids
  Future<void> reorderListArticles(String listId, List<String> articleIds) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      final userId = currentUser?['id'] as String? ?? currentUser?['userId'] as String?;

      final response = await _api.put(
        'social/reading-lists/order',
        body: {
          'listId': listId,
          'articleIds': articleIds,
          if (userId != null && userId.isNotEmpty) 'userId': userId,
        },
      );

      if (!_api.isSuccess(response)) {
        throw Exception(_api.getErrorMessage(response));
      }
      _invalidateSocialReadCaches();
    } catch (e) {
      log('⚠️ Error reordering list articles: $e');
      rethrow;
    }
  }

  /// Fetch article previews by ids in backend order
  Future<List<ArticleModel>> getArticlesByIds(
    List<String> articleIds, {
    bool forceRefresh = false,
  }) async {
    if (articleIds.isEmpty) return [];
    final key = 'articlesByIds:${articleIds.join(",")}';
    return _cachedRequest<List<ArticleModel>>(
      key: key,
      forceRefresh: forceRefresh,
      ttl: _defaultTtl,
      loader: () async {
        try {
          final response = await _api.post(
            'articles/by-ids',
            body: {'articleIds': articleIds},
          );

          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['articles'] != null) {
              final List<dynamic> articlesJson = data['articles'];
              return articlesJson.map((json) => ArticleModel.fromJson(json)).toList();
            }
          }
        } catch (e) {
          log('⚠️ Error loading articles by ids: $e');
        }
        return [];
      },
    );
  }

  // ===== ACTIVITY FEED =====

  /// Get activity feed for current user (from followed users)
  Future<List<ActivityFeedItem>> getActivityFeed({
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) return [];

    final userId =
        currentUser['id'] as String? ?? currentUser['userId'] as String?;
    if (userId == null || userId.isEmpty) return [];

    final key = 'activity:$userId:$limit';
    return _cachedRequest<List<ActivityFeedItem>>(
      key: key,
      forceRefresh: forceRefresh,
      ttl: _shortTtl,
      loader: () async {
        try {
          final response = await _api.get(
            'social/activity/$userId',
            queryParams: {'limit': limit.toString()},
          );

          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['activities'] != null) {
              final List<dynamic> activitiesJson = data['activities'];
              return activitiesJson
                  .map((json) => ActivityFeedItem.fromMap(json))
                  .toList();
            }
          }
        } catch (e) {
          log('⚠️ Error loading activity feed: $e');
        }
        return [];
      },
    );
  }

  // ===== NETWORK HIGHLIGHTS =====

  Future<PaginatedNetworkHighlightsPage> getNetworkHighlightsPaginated({
    int limit = 20,
    String? cursor,
    bool forceRefresh = false,
  }) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      return const PaginatedNetworkHighlightsPage(highlights: []);
    }
    final userId =
        currentUser['id'] as String? ?? currentUser['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      return const PaginatedNetworkHighlightsPage(highlights: []);
    }

    final key = 'highlights:$userId:$limit:${cursor ?? ''}';
    return _cachedRequest<PaginatedNetworkHighlightsPage>(
      key: key,
      forceRefresh: forceRefresh,
      ttl: _shortTtl,
      loader: () async {
        try {
          final response = await _api.get(
            'social/highlights/$userId',
            queryParams: {
              'limit': limit.toString(),
              if (cursor != null) 'cursor': cursor,
            },
          );

          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['highlights'] != null) {
              final List<dynamic> highlightsJson = data['highlights'];
              return PaginatedNetworkHighlightsPage(
                highlights: highlightsJson
                    .map(
                      (json) =>
                          NetworkHighlight.fromMap(Map<String, dynamic>.from(json)),
                    )
                    .toList(),
                hasMore: data['hasMore'] as bool? ?? false,
                nextCursor: data['nextCursor'] as String?,
              );
            }
          }
        } catch (e) {
          log('⚠️ Error loading network highlights: $e');
        }
        return const PaginatedNetworkHighlightsPage(highlights: []);
      },
    );
  }

  // ===== NETWORK POSTS =====

  Future<PaginatedPostsPage> getNetworkPostsPaginated({
    int limit = 20,
    String? cursor,
    bool forceRefresh = false,
  }) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      return const PaginatedPostsPage(posts: [], loadFailed: true);
    }
    final userId =
        currentUser['id'] as String? ?? currentUser['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      return const PaginatedPostsPage(posts: [], loadFailed: true);
    }

    final key = 'posts:$userId:$limit:${cursor ?? ''}';
    return _cachedRequest<PaginatedPostsPage>(
      key: key,
      forceRefresh: forceRefresh,
      ttl: _shortTtl,
      loader: () async {
        try {
          final response = await _api.get(
            'social/posts/$userId',
            queryParams: {
              'limit': limit.toString(),
              if (cursor != null) 'cursor': cursor,
            },
          );

          if (_api.isSuccess(response)) {
            final data = _api.parseJson(response);
            if (data['success'] == true && data['posts'] != null) {
              final List<dynamic> postsJson = data['posts'];
              return PaginatedPostsPage(
                posts: postsJson
                    .map(
                      (json) => SocialPost.fromMap(Map<String, dynamic>.from(json)),
                    )
                    .toList(),
                hasMore: data['hasMore'] as bool? ?? false,
                nextCursor: data['nextCursor'] as String?,
              );
            }
          }
        } catch (e) {
          log('⚠️ Error loading network posts: $e');
        }
        return const PaginatedPostsPage(posts: [], loadFailed: true);
      },
    );
  }

  Future<SocialPost?> createNetworkPost({
    required String text,
    String? heading,
    String? articleId,
    String? articleTitle,
    String? articleImageUrl,
    String? articleUrl,
  }) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) return null;
    final userId =
        currentUser['id'] as String? ?? currentUser['userId'] as String?;
    if (userId == null || userId.isEmpty) return null;

    try {
      final response = await _api.post(
        'social/posts',
        body: {
          'userId': userId,
          'text': text,
          if (heading != null) 'heading': heading,
          if (articleId != null) 'articleId': articleId,
          if (articleTitle != null) 'articleTitle': articleTitle,
          if (articleImageUrl != null) 'articleImageUrl': articleImageUrl,
          if (articleUrl != null) 'articleUrl': articleUrl,
        },
      );
      if (_api.isSuccess(response)) {
        _invalidateSocialReadCaches();
        final data = _api.parseJson(response);
        if (data['success'] == true && data['post'] != null) {
          return SocialPost.fromMap(Map<String, dynamic>.from(data['post']));
        }
      }
      throw Exception(_api.getErrorMessage(response));
    } catch (e) {
      log('⚠️ Error creating post: $e');
      rethrow;
    }
  }

  Future<bool> likeNetworkPost(String postId) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) return false;
    final userId =
        currentUser['id'] as String? ?? currentUser['userId'] as String?;
    if (userId == null || userId.isEmpty) return false;

    try {
      final response = await _api.post(
        'social/posts/$postId/like',
        body: {'userId': userId},
      );
      if (_api.isSuccess(response)) _invalidateCacheByPrefix('posts:');
      return _api.isSuccess(response);
    } catch (e) {
      log('⚠️ Error liking post: $e');
      return false;
    }
  }

  Future<bool> unlikeNetworkPost(String postId) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) return false;
    final userId =
        currentUser['id'] as String? ?? currentUser['userId'] as String?;
    if (userId == null || userId.isEmpty) return false;

    try {
      final response = await _api.delete(
        'social/posts/$postId/like',
        body: {'userId': userId},
      );
      if (_api.isSuccess(response)) _invalidateCacheByPrefix('posts:');
      return _api.isSuccess(response);
    } catch (e) {
      log('⚠️ Error unliking post: $e');
      return false;
    }
  }

  Future<bool> commentOnNetworkPost(String postId, String text) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) return false;
    final userId =
        currentUser['id'] as String? ?? currentUser['userId'] as String?;
    if (userId == null || userId.isEmpty) return false;

    try {
      final response = await _api.post(
        'social/posts/$postId/comments',
        body: {'userId': userId, 'text': text},
      );
      if (response.statusCode == 201 || _api.isSuccess(response)) {
        _invalidateCacheByPrefix('posts:');
      }
      return response.statusCode == 201 || _api.isSuccess(response);
    } catch (e) {
      log('⚠️ Error commenting on post: $e');
      return false;
    }
  }
}

class PaginatedUsersPage {
  const PaginatedUsersPage({
    required this.users,
    this.hasMore = false,
    this.nextCursor,
  });

  final List<UserProfile> users;
  final bool hasMore;
  final String? nextCursor;
}

class PaginatedReadingListsPage {
  const PaginatedReadingListsPage({
    required this.lists,
    this.hasMore = false,
    this.nextCursor,
  });

  final List<ReadingList> lists;
  final bool hasMore;
  final String? nextCursor;
}

class PaginatedNetworkHighlightsPage {
  const PaginatedNetworkHighlightsPage({
    required this.highlights,
    this.hasMore = false,
    this.nextCursor,
  });

  final List<NetworkHighlight> highlights;
  final bool hasMore;
  final String? nextCursor;
}

class PaginatedPostsPage {
  const PaginatedPostsPage({
    required this.posts,
    this.hasMore = false,
    this.nextCursor,
    this.loadFailed = false,
  });

  final List<SocialPost> posts;
  final bool hasMore;
  final String? nextCursor;
  final bool loadFailed;
}

class FeedSummaryPage {
  const FeedSummaryPage({
    required this.recentActivity,
    required this.sharedActivity,
    required this.networkHighlights,
    required this.previewPosts,
    required this.followedPublishers,
    required this.followedTopics,
  });

  final List<ActivityFeedItem> recentActivity;
  final List<ActivityFeedItem> sharedActivity;
  final List<NetworkHighlight> networkHighlights;
  final List<SocialPost> previewPosts;
  final List<String> followedPublishers;
  final List<String> followedTopics;
}

class PeopleSummaryPage {
  const PeopleSummaryPage({
    required this.followers,
    required this.following,
    required this.recommended,
  });

  final List<UserProfile> followers;
  final List<UserProfile> following;
  final List<UserProfile> recommended;
}

class _MemoryCacheEntry<T> {
  const _MemoryCacheEntry({
    required this.value,
    required this.expiresAt,
  });

  final T value;
  final DateTime expiresAt;
}
