import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/podcast_model.dart';
import 'package:the_news/service/auth_service.dart';

class PodcastEpisodesPage {
  const PodcastEpisodesPage({
    required this.episodes,
    this.nextCursor,
  });

  final List<Episode> episodes;
  final String? nextCursor;
}

/// Service for managing podcast data
/// Follows GEMINI.md rules - uses ApiClient for all network requests
class PodcastService extends ChangeNotifier {
  static final PodcastService instance = PodcastService._init();
  PodcastService._init();

  final ApiClient _api = ApiClient.instance;
  final AuthService _authService = AuthService.instance;

  // Cache
  List<Podcast> _trendingPodcasts = [];
  List<Podcast> _savedPodcasts = [];
  final Map<String, List<Episode>> _episodesCache = {};
  final Map<String, DateTime> _episodesFetchedAt = {};
  final Map<String, Podcast> _podcastCache = {};
  final Map<String, List<Podcast>> _trendingCache = {};
  final Map<String, DateTime> _trendingFetchedAt = {};
  final Map<String, List<Podcast>> _recommendationsCache = {};
  final Map<String, DateTime> _recommendationsFetchedAt = {};
  Map<String, ListeningProgress> _listeningProgress = {};
  DateTime? _savedFetchedAt;
  DateTime? _progressFetchedAt;
  Future<void>? _initializeInFlight;
  final Map<String, Future<PodcastEpisodesPage>> _episodePagesInFlight = {};
  final Map<String, Future<List<Podcast>>> _recommendationsInFlight = {};
  final Map<String, Future<List<Podcast>>> _trendingInFlight = {};

  // State
  bool _isLoading = false;
  String? _error;

  // TTLs
  static const Duration _trendingTtl = Duration(minutes: 10);
  static const Duration _episodesTtl = Duration(minutes: 15);
  static const Duration _recommendationsTtl = Duration(minutes: 5);
  static const Duration _savedTtl = Duration(minutes: 2);
  static const Duration _progressTtl = Duration(minutes: 2);

  // Getters
  List<Podcast> get trendingPodcasts => _trendingPodcasts;
  List<Podcast> get savedPodcasts => _savedPodcasts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// News category to podcast genre mapping
  static const Map<String, List<String>> categoryToGenres = {
    'politics': ['Politics', 'Government', 'News & Politics'],
    'business': ['Business', 'Business News', 'Entrepreneurship', 'Investing'],
    'finance': ['Finance', 'Business', 'Investing', 'Economy'],
    'technology': ['Technology', 'Tech News', 'Science & Technology'],
    'sports': ['Sports', 'Sports News'],
    'health': ['Health', 'Health & Fitness', 'Mental Health', 'Medicine'],
    'science': ['Science', 'Natural Sciences'],
    'education': ['Education'],
    'culture': ['Culture'],
    'environment': ['Environment'],
    'entertainment': ['Entertainment', 'TV & Film', 'Music'],
    'world': ['News', 'Daily News', 'World News'],
    'top': ['News', 'Daily News', 'News Commentary'],
  };

  bool _isCacheFresh(DateTime? fetchedAt, Duration ttl) {
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt) < ttl;
  }

  String _trendingKey({String? category, int limit = 20}) =>
      '${(category ?? 'all').toLowerCase()}:$limit';

  Future<String?> _resolveUserId() async {
    final userData = await _authService.getCurrentUser();
    final userId = (userData?['id'] ?? userData?['userId'])?.toString();
    if (userId == null || userId.isEmpty) return null;
    return userId;
  }

  /// Initialize podcast service
  Future<void> initialize({bool forceRefresh = false}) async {
    if (!forceRefresh && _initializeInFlight != null) {
      return _initializeInFlight!;
    }

    final future = Future.wait([
      loadTrendingPodcasts(forceRefresh: forceRefresh),
      loadSavedPodcasts(forceRefresh: forceRefresh),
      loadListeningProgress(forceRefresh: forceRefresh),
    ]);
    _initializeInFlight = future.then((_) {});

    try {
      await _initializeInFlight;
    } finally {
      _initializeInFlight = null;
    }
  }

  /// Search for podcasts
  Future<List<Podcast>> searchPodcasts({
    required String query,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final queryParams = <String, String>{
        'q': query,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (category != null && categoryToGenres.containsKey(category.toLowerCase())) {
        queryParams['genres'] = categoryToGenres[category.toLowerCase()]!.join(',');
      }

      final response = await _api.get(
        'podcasts/search',
        queryParams: queryParams,
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final podcastsJson = data['podcasts'] as List? ?? [];
          final podcasts = podcastsJson
              .map((json) => Podcast.fromJson(json as Map<String, dynamic>))
              .toList();

          // Cache podcasts
          for (final podcast in podcasts) {
            _podcastCache[podcast.id] = podcast;
          }

          log('✅ Found ${podcasts.length} podcasts for query: $query');
          return podcasts;
        }
      }

      return [];
    } catch (e) {
      log('❌ Error searching podcasts: $e');
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get trending/popular podcasts
  Future<List<Podcast>> loadTrendingPodcasts({
    String? category,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _trendingKey(category: category, limit: limit);
    if (!forceRefresh &&
        _trendingCache.containsKey(cacheKey) &&
        _isCacheFresh(_trendingFetchedAt[cacheKey], _trendingTtl)) {
      _trendingPodcasts = _trendingCache[cacheKey]!;
      return _trendingPodcasts;
    }

    if (!forceRefresh && _trendingInFlight.containsKey(cacheKey)) {
      return _trendingInFlight[cacheKey]!;
    }

    final request = () async {
      try {
        _isLoading = true;
        notifyListeners();

        final queryParams = <String, String>{
          'limit': limit.toString(),
        };

        if (category != null &&
            categoryToGenres.containsKey(category.toLowerCase())) {
          queryParams['genres'] =
              categoryToGenres[category.toLowerCase()]!.join(',');
        }

        final response = await _api.get(
          'podcasts/trending',
          queryParams: queryParams,
          timeout: const Duration(seconds: 30),
        );

        if (_api.isSuccess(response)) {
          final data = _api.parseJson(response);
          if (data['success'] == true) {
            final podcastsJson = data['podcasts'] as List? ?? [];
            final parsed = podcastsJson
                .map((json) => Podcast.fromJson(json as Map<String, dynamic>))
                .toList();

            _trendingPodcasts = parsed;
            _trendingCache[cacheKey] = parsed;
            _trendingFetchedAt[cacheKey] = DateTime.now();
            _error = null;

            // Cache podcasts
            for (final podcast in _trendingPodcasts) {
              _podcastCache[podcast.id] = podcast;
            }

            log('✅ Loaded ${_trendingPodcasts.length} trending podcasts');
            return _trendingPodcasts;
          }
        }

        return <Podcast>[];
      } catch (e) {
        log('❌ Error loading trending podcasts: $e');
        _error = e.toString();
        return <Podcast>[];
      } finally {
        _isLoading = false;
        _trendingInFlight.remove(cacheKey);
        notifyListeners();
      }
    }();

    _trendingInFlight[cacheKey] = request;
    return request;
  }

  /// Get podcast by ID
  Future<Podcast?> getPodcastById(String podcastId) async {
    // Check cache first
    if (_podcastCache.containsKey(podcastId)) {
      return _podcastCache[podcastId];
    }

    try {
      final response = await _api.get(
        'podcasts/$podcastId',
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true && data['podcast'] != null) {
          final podcast = Podcast.fromJson(data['podcast']);
          _podcastCache[podcastId] = podcast;
          return podcast;
        }
      }

      return null;
    } catch (e) {
      log('❌ Error getting podcast $podcastId: $e');
      return null;
    }
  }

  /// Get episodes for a podcast
  Future<List<Episode>> getPodcastEpisodes(
    String podcastId, {
    int offset = 0,
    int limit = 20,
    String? cursor,
    bool forceRefresh = false,
  }) async {
    final page = await getPodcastEpisodesPage(
      podcastId,
      offset: offset,
      limit: limit,
      cursor: cursor,
      forceRefresh: forceRefresh,
    );
    return page.episodes;
  }

  /// Get a page of episodes for a podcast
  Future<PodcastEpisodesPage> getPodcastEpisodesPage(
    String podcastId, {
    int offset = 0,
    int limit = 20,
    String? cursor,
    bool forceRefresh = false,
  }) async {
    final cursorValue = cursor?.trim();
    final cacheKey = '$podcastId:${cursorValue ?? 'offset:$offset'}:$limit';

    // Check cache first for the initial page only.
    if (!forceRefresh &&
        cursorValue == null &&
        offset == 0 &&
        _episodesCache.containsKey(podcastId) &&
        _isCacheFresh(_episodesFetchedAt[podcastId], _episodesTtl)) {
      return PodcastEpisodesPage(
        episodes: _episodesCache[podcastId]!,
      );
    }

    if (!forceRefresh && _episodePagesInFlight.containsKey(cacheKey)) {
      return _episodePagesInFlight[cacheKey]!;
    }

    final request = () async {
      try {
        final queryParams = <String, String>{
          'limit': limit.toString(),
        };

        if (cursorValue != null && cursorValue.isNotEmpty) {
          queryParams['cursor'] = cursorValue;
        } else {
          queryParams['offset'] = offset.toString();
        }

        final response = await _api.get(
          'podcasts/$podcastId/episodes',
          queryParams: queryParams,
          timeout: const Duration(seconds: 30),
        );

        if (_api.isSuccess(response)) {
          final data = _api.parseJson(response);
          if (data['success'] == true) {
            final episodesJson = data['episodes'] as List? ?? [];
            final episodes = episodesJson
                .map((json) => Episode.fromJson(json as Map<String, dynamic>))
                .toList();
            final nextCursor = data['nextCursor']?.toString();

            // Cache only the initial page for quick page reloads.
            if (cursorValue == null && offset == 0) {
              _episodesCache[podcastId] = episodes;
              _episodesFetchedAt[podcastId] = DateTime.now();
            } else if (cursorValue == null && offset > 0) {
              _episodesCache[podcastId] = [
                ...(_episodesCache[podcastId] ?? []),
                ...episodes,
              ];
            }

            log('✅ Loaded ${episodes.length} episodes for podcast $podcastId');
            return PodcastEpisodesPage(
              episodes: episodes,
              nextCursor: nextCursor,
            );
          }
        }

        return const PodcastEpisodesPage(episodes: <Episode>[]);
      } catch (e) {
        log('❌ Error getting episodes for podcast $podcastId: $e');
        return const PodcastEpisodesPage(episodes: <Episode>[]);
      } finally {
        _episodePagesInFlight.remove(cacheKey);
      }
    }();

    _episodePagesInFlight[cacheKey] = request;
    return request;
  }

  /// Search episodes
  Future<List<Episode>> searchEpisodes({
    required String query,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (category != null && categoryToGenres.containsKey(category.toLowerCase())) {
        queryParams['genres'] = categoryToGenres[category.toLowerCase()]!.join(',');
      }

      final response = await _api.get(
        'podcasts/episodes/search',
        queryParams: queryParams,
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final episodesJson = data['episodes'] as List? ?? [];
          return episodesJson
              .map((json) => Episode.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } catch (e) {
      log('❌ Error searching episodes: $e');
      return [];
    }
  }

  /// Get personalized recommendations for current user
  Future<List<Podcast>> getRecommendations({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final userData = await _authService.getCurrentUser();
    final userId = (userData?['id'] ?? userData?['userId'])?.toString() ?? '';
    final cacheKey = '$userId:$limit';

    if (!forceRefresh &&
        _recommendationsCache.containsKey(cacheKey) &&
        _isCacheFresh(_recommendationsFetchedAt[cacheKey], _recommendationsTtl)) {
      return _recommendationsCache[cacheKey]!;
    }

    if (!forceRefresh && _recommendationsInFlight.containsKey(cacheKey)) {
      return _recommendationsInFlight[cacheKey]!;
    }

    final request = () async {
      try {
        final response = await _api.get(
          'podcasts/recommendations',
          queryParams: {
            if (userId.isNotEmpty) 'userId': userId,
            'limit': limit.toString(),
          },
          timeout: const Duration(seconds: 30),
        );

        if (_api.isSuccess(response)) {
          final data = _api.parseJson(response);
          if (data['success'] == true) {
            final podcastsJson = data['podcasts'] as List? ?? [];
            final podcasts = podcastsJson
                .map((json) => Podcast.fromJson(json as Map<String, dynamic>))
                .toList();
            _recommendationsCache[cacheKey] = podcasts;
            _recommendationsFetchedAt[cacheKey] = DateTime.now();
            return podcasts;
          }
        }

        return <Podcast>[];
      } catch (e) {
        log('❌ Error getting recommendations: $e');
        return <Podcast>[];
      } finally {
        _recommendationsInFlight.remove(cacheKey);
      }
    }();

    _recommendationsInFlight[cacheKey] = request;
    return request;
  }

  // ==================== SAVED PODCASTS ====================

  /// Load saved podcasts from backend
  Future<void> loadSavedPodcasts({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheFresh(_savedFetchedAt, _savedTtl)) return;
    try {
      final userId = await _resolveUserId();
      if (userId == null) {
        _savedPodcasts = [];
        return;
      }

      final response = await _api.get(
        'podcasts/saved',
        queryParams: {'userId': userId},
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final podcastsJson = data['podcasts'] as List? ?? [];
          _savedPodcasts = podcastsJson
              .map((json) => Podcast.fromJson(json as Map<String, dynamic>))
              .toList();

          // Cache podcasts
          for (final podcast in _savedPodcasts) {
            _podcastCache[podcast.id] = podcast;
          }

          _savedFetchedAt = DateTime.now();
          notifyListeners();
        }
      }
    } catch (e) {
      log('❌ Error loading saved podcasts: $e');
    }
  }

  /// Save a podcast
  Future<bool> savePodcast(Podcast podcast) async {
    try {
      final userId = await _resolveUserId();
      if (userId == null) return false;

      final response = await _api.post(
        'podcasts/saved',
        body: {
          'userId': userId,
          'podcast': podcast.toJson(),
        },
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        if (!_savedPodcasts.any((p) => p.id == podcast.id)) {
          _savedPodcasts.insert(0, podcast);
          notifyListeners();
        }
        log('✅ Saved podcast: ${podcast.title}');
        return true;
      }

      return false;
    } catch (e) {
      log('❌ Error saving podcast: $e');
      return false;
    }
  }

  /// Unsave a podcast
  Future<bool> unsavePodcast(String podcastId) async {
    try {
      final userId = await _resolveUserId();
      if (userId == null) return false;

      final response = await _api.delete(
        'podcasts/saved/$podcastId?userId=$userId',
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        _savedPodcasts.removeWhere((p) => p.id == podcastId);
        notifyListeners();
        log('✅ Unsaved podcast: $podcastId');
        return true;
      }

      return false;
    } catch (e) {
      log('❌ Error unsaving podcast: $e');
      return false;
    }
  }

  /// Check if podcast is saved
  bool isPodcastSaved(String podcastId) {
    return _savedPodcasts.any((p) => p.id == podcastId);
  }

  // ==================== LISTENING PROGRESS ====================

  /// Load listening progress from backend
  Future<void> loadListeningProgress({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheFresh(_progressFetchedAt, _progressTtl)) return;
    try {
      final userId = await _resolveUserId();
      if (userId == null) {
        _listeningProgress = {};
        return;
      }

      final response = await _api.get(
        'podcasts/progress',
        queryParams: {'userId': userId},
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final progressJson = data['progress'] as List? ?? [];
          _listeningProgress = {
            for (final raw in progressJson)
              if ((((raw as Map<String, dynamic>)['episodeId'] ??
                          raw['episode_id'])
                      ?.toString() ??
                  '')
                  .isNotEmpty)
                ((raw['episodeId'] ?? raw['episode_id']).toString()):
                    ListeningProgress.fromJson(raw)
          };
          _progressFetchedAt = DateTime.now();
          notifyListeners();
        }
      }
    } catch (e) {
      log('❌ Error loading listening progress: $e');
    }
  }

  /// Save listening progress
  Future<void> saveProgress(ListeningProgress progress) async {
    try {
      _listeningProgress[progress.episodeId] = progress;
      notifyListeners();

      final userData = await _authService.getCurrentUser();
      final userId = userData?['id'] ?? userData?['userId'];
      if (userId == null || userId.toString().isEmpty) {
        log('⚠️ Cannot save podcast progress: userId missing');
        return;
      }

      await _api.post(
        'podcasts/progress',
        body: {
          ...progress.toJson(),
          'userId': userId,
        },
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      log('❌ Error saving progress: $e');
    }
  }

  /// Get listening progress for an episode
  ListeningProgress? getProgress(String episodeId) {
    return _listeningProgress[episodeId];
  }

  /// Get recent listening progress entries (most recently listened first)
  List<ListeningProgress> getRecentProgress({int limit = 10}) {
    final items = _listeningProgress.values.toList()
      ..sort((a, b) => b.lastListenedAt.compareTo(a.lastListenedAt));
    if (items.length <= limit) return items;
    return items.take(limit).toList();
  }

  /// Get continue listening episodes (in progress, not completed)
  Future<List<Episode>> getContinueListening({int limit = 10}) async {
    try {
      final userId = await _resolveUserId();
      if (userId == null) return [];

      final response = await _api.get(
        'podcasts/continue-listening',
        queryParams: {
          'limit': limit.toString(),
          'userId': userId,
        },
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final episodesJson = data['episodes'] as List? ?? [];
          return episodesJson
              .map((json) => Episode.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } catch (e) {
      log('❌ Error getting continue listening: $e');
      return [];
    }
  }

  /// Clear cache
  void clearCache() {
    _episodesCache.clear();
    _episodesFetchedAt.clear();
    _podcastCache.clear();
    _trendingCache.clear();
    _trendingFetchedAt.clear();
    _recommendationsCache.clear();
    _recommendationsFetchedAt.clear();
    _savedFetchedAt = null;
    _progressFetchedAt = null;
    notifyListeners();
  }
}
