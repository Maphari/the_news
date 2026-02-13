import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/news_api_service.dart';
import 'package:the_news/service/location_service.dart';
import 'package:the_news/service/calm_mode_service.dart';

/// News provider that handles fetching from API with backend fallback
/// Uses ApiClient for all network requests following clean architecture
class NewsProviderService extends ChangeNotifier {
  static final NewsProviderService instance = NewsProviderService._init();
  NewsProviderService._init();

  final _api = ApiClient.instance;
  final _apiService = NewsApiService.instance;

  /// Map country names to country codes (matches CountrySelectionPage)
  static const Map<String, String> _countryNameToCode = {
    'United States': 'us',
    'United Kingdom': 'gb',
    'Canada': 'ca',
    'Australia': 'au',
    'Germany': 'de',
    'France': 'fr',
    'Italy': 'it',
    'Spain': 'es',
    'Japan': 'jp',
    'China': 'cn',
    'India': 'in',
    'Brazil': 'br',
    'Mexico': 'mx',
    'Russia': 'ru',
    'South Korea': 'kr',
    'Netherlands': 'nl',
    'Switzerland': 'ch',
    'Sweden': 'se',
    'Norway': 'no',
    'Denmark': 'dk',
    'Finland': 'fi',
    'Belgium': 'be',
    'Austria': 'at',
    'Poland': 'pl',
    'Ireland': 'ie',
    'Portugal': 'pt',
    'Greece': 'gr',
    'Turkey': 'tr',
    'South Africa': 'za',
    'Nigeria': 'ng',
    'Egypt': 'eg',
    'Saudi Arabia': 'sa',
    'UAE': 'ae',
    'Israel': 'il',
    'Singapore': 'sg',
    'Malaysia': 'my',
    'Thailand': 'th',
    'Indonesia': 'id',
    'Philippines': 'ph',
    'Vietnam': 'vn',
    'New Zealand': 'nz',
    'Argentina': 'ar',
    'Chile': 'cl',
    'Colombia': 'co',
    'Peru': 'pe',
  };

  List<ArticleModel> _articles = [];
  List<ArticleModel> _apiArticles = []; // Fresh articles from API (shown on top)
  List<ArticleModel> _dbArticles = []; // Older articles from database (shown below)
  String _currentCategory = 'All';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _isUsingApi = false;
  int _dbOffset = 0; // For pagination of database articles
  static const int _pageSize = 20;

  /// Normalize title for comparison
  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
  }

  /// Deduplicate articles by title similarity
  List<ArticleModel> _deduplicateByTitle(List<ArticleModel> articles) {
    final seen = <String>{};
    final unique = <ArticleModel>[];

    for (final article in articles) {
      final normalizedTitle = _normalizeTitle(article.title);

      // Only add if we haven't seen a similar title
      if (!seen.contains(normalizedTitle)) {
        seen.add(normalizedTitle);
        unique.add(article);
      }
    }

    return unique;
  }

  // Getters
  List<ArticleModel> get articles => _applyCalmFilter(_articles);
  List<ArticleModel> get apiArticles => _applyCalmFilter(_apiArticles);
  List<ArticleModel> get dbArticles => _applyCalmFilter(_dbArticles);
  String get currentCategory => _currentCategory;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get isUsingApi => _isUsingApi;
  bool get hasMoreArticles => _dbArticles.length >= _pageSize;

  /// Initialize news service
  Future<void> initialize() async {
    await _apiService.initialize();
    await loadArticles();
  }

  /// Load articles for current category
  /// Fetches from both API (latest news on top) and database (older news below)
  Future<void> loadArticles({String? category, bool refresh = false}) async {
    if (category != null) {
      _currentCategory = category;
    }

    // Reset pagination on new load
    if (refresh || category != null) {
      _dbOffset = 0;
      _apiArticles = [];
      _dbArticles = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final locationService = LocationService.instance;
      String? countryCode;
      if (locationService.preferredCountries.isNotEmpty) {
        countryCode = _countryNameToCode[locationService.preferredCountries.first];
      }

      // Fetch from both sources in parallel
      final futures = await Future.wait([
        // 1. Fetch fresh articles from API (latest news)
        _fetchFromApi(countryCode),
        // 2. Fetch older articles from database
        _fetchArticlesFromBackend(offset: 0, limit: _pageSize),
      ]);

      final freshApiArticles = futures[0];
      final olderDbArticles = futures[1];

      // Deduplicate each source
      _apiArticles = _deduplicateByTitle(freshApiArticles);

      // Remove any DB articles that duplicate API articles
      final apiTitles = _apiArticles.map((a) => _normalizeTitle(a.title)).toSet();
      _dbArticles = _deduplicateByTitle(olderDbArticles)
          .where((a) => !apiTitles.contains(_normalizeTitle(a.title)))
          .toList();

      // Combine: API articles first (fresh), then DB articles (older)
      _articles = [..._apiArticles, ..._dbArticles];
      _isUsingApi = _apiArticles.isNotEmpty;

      // Save API articles to backend database for future use (non-blocking)
      if (_apiArticles.isNotEmpty) {
        _saveArticlesToBackend(_apiArticles);
      }

      debugPrint('📰 Loaded ${_apiArticles.length} fresh articles from API');
      debugPrint('📚 Loaded ${_dbArticles.length} older articles from database');
      debugPrint('📊 Total: ${_articles.length} articles (API on top, DB below)');

      if (_articles.isEmpty) {
        _error = 'No articles available. Please check your internet connection.';
      }
    } catch (e) {
      debugPrint('Error loading articles: $e');
      _error = e.toString();
      _articles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more older articles from database (pagination)
  Future<void> loadMoreArticles() async {
    if (_isLoadingMore || !hasMoreArticles) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _dbOffset += _pageSize;
      final moreDbArticles = await _fetchArticlesFromBackend(
        offset: _dbOffset,
        limit: _pageSize,
      );

      if (moreDbArticles.isNotEmpty) {
        // Remove duplicates with existing articles
        final existingTitles = _articles.map((a) => _normalizeTitle(a.title)).toSet();
        final uniqueNewArticles = moreDbArticles
            .where((a) => !existingTitles.contains(_normalizeTitle(a.title)))
            .toList();

        _dbArticles.addAll(uniqueNewArticles);
        _articles = [..._apiArticles, ..._dbArticles];

        debugPrint('📚 Loaded ${uniqueNewArticles.length} more articles from database');
      }
    } catch (e) {
      debugPrint('Error loading more articles: $e');
      _dbOffset -= _pageSize; // Revert offset on error
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Fetch fresh articles from API
  Future<List<ArticleModel>> _fetchFromApi(String? countryCode) async {
    if (!_apiService.isConfigured) return [];

    try {
      final apiArticles = await _apiService.fetchNews(
        category: _currentCategory == 'All' ? null : _currentCategory,
        country: countryCode,
        language: 'en',
      );
      return apiArticles;
    } catch (e) {
      debugPrint('⚠️ API fetch failed: $e');
      return [];
    }
  }

  /// Fetch articles from backend database with pagination
  /// [offset] - Number of articles to skip (for pagination)
  /// [limit] - Maximum number of articles to fetch
  Future<List<ArticleModel>> _fetchArticlesFromBackend({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        'sort': 'pubDate', // Sort by publication date
        'order': 'desc', // Newest first within DB results
      };

      if (_currentCategory != 'All') {
        queryParams['category'] = _currentCategory.toLowerCase();
      }

      // Add country filter if user has preferred countries
      final locationService = LocationService.instance;
      if (locationService.preferredCountries.isNotEmpty) {
        // Convert country names to country codes
        final countryCodes = locationService.preferredCountries
            .map((name) => _countryNameToCode[name])
            .where((code) => code != null)
            .cast<String>()
            .toList();

        if (countryCodes.isNotEmpty) {
          queryParams['country'] = countryCodes.join(',');
          debugPrint('🌍 Filtering by countries: ${locationService.preferredCountries.join(", ")}');
        }
      }

      final response = await _api.get(
        'articles',
        queryParams: queryParams,
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final articlesJson = data['articles'] as List;
          final articles = articlesJson
              .map((json) => ArticleModel.fromJson(json as Map<String, dynamic>))
              .toList();

          debugPrint('✅ Fetched ${articles.length} articles from backend (offset: $offset, limit: $limit)');
          return articles;
        }
      }

      return [];
    } catch (e) {
      debugPrint('⚠️ Error fetching articles from backend: $e');
      return [];
    }
  }

  /// Search articles (checks database first, then API)
  Future<List<ArticleModel>> searchArticles(String query) async {
    if (query.isEmpty) return [];

    try {
      // 1. First, search in database (current loaded articles)
      log('🔍 Searching database for: $query');
      final dbResults = _articles
          .where((article) =>
              article.title.toLowerCase().contains(query.toLowerCase()) ||
              article.description.toLowerCase().contains(query.toLowerCase()) ||
              article.content.toLowerCase().contains(query.toLowerCase()))
          .toList();

      // If found results in database, return them
      if (dbResults.isNotEmpty) {
        log('✅ Found ${dbResults.length} results in database');
        return _applyCalmFilter(dbResults);
      }

      // 2. If no results in database, search via API
      if (_apiService.isConfigured) {
        log('📡 No database results, searching API...');
        final apiResults = await _apiService.searchNews(query: query);

        if (apiResults.isNotEmpty) {
          log('✅ Found ${apiResults.length} results from API');
          // Save API results to backend for future searches
          _saveArticlesToBackend(apiResults);
          return _applyCalmFilter(apiResults);
        }
      }

      // 3. No results found anywhere
      log('⚠️ No results found for query: $query');
      return [];
    } catch (e) {
      log('⚠️ Error searching articles: $e');

      // Fallback to searching in current loaded articles
      return _applyCalmFilter(_articles
          .where((article) =>
              article.title.toLowerCase().contains(query.toLowerCase()) ||
              article.description.toLowerCase().contains(query.toLowerCase()))
          .toList());
    }
  }

  List<ArticleModel> _applyCalmFilter(List<ArticleModel> articles) {
    final calmMode = CalmModeService.instance;
    if (!calmMode.isCalmModeEnabled) return articles;
    return calmMode.filterArticles(articles);
  }

  /// Refresh current articles (fetches fresh from both API and database)
  Future<void> refresh() async {
    await loadArticles(refresh: true);
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _apiService.clearCache();
    await loadArticles();
  }

  /// Get articles by category (for category tabs)
  List<ArticleModel> getArticlesByCategory(String category) {
    if (category == 'All') {
      return _applyCalmFilter(_articles); // Already deduplicated in loadArticles
    }

    return _applyCalmFilter(_articles
        .where((article) => article.category
            .any((cat) => cat.toLowerCase() == category.toLowerCase()))
        .toList());
  }

  /// Get trending articles (sorted by source priority)
  List<ArticleModel> getTrendingArticles({int limit = 10}) {
    final sorted = List<ArticleModel>.from(_applyCalmFilter(_articles));
    sorted.sort((a, b) => b.sourcePriority.compareTo(a.sourcePriority));
    return sorted.take(limit).toList();
  }

  /// Get trending topics from articles (extracts common keywords from titles)
  List<String> getTrendingTopics({int limit = 5}) {
    if (_articles.isEmpty) return [];

    // Extract words from article titles and count frequency
    final wordFrequency = <String, int>{};

    // Common words to exclude
    final stopWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'been',
      'be', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'should',
      'could', 'may', 'might', 'must', 'can', 'this', 'that', 'these', 'those',
      'i', 'you', 'he', 'she', 'it', 'we', 'they', 'what', 'which', 'who',
      'when', 'where', 'why', 'how', 'all', 'each', 'every', 'both', 'few',
      'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only',
      'own', 'same', 'so', 'than', 'too', 'very', 's', 't', 'just', 'don',
      'now', 'says', 'new', 'after', 'over', 'into', 'about', 'up', 'out'
    };

    for (final article in _articles) {
      final words = article.title.toLowerCase().split(RegExp(r'[\s,.\-:;!?()]+'));
      for (final word in words) {
        // Only count words longer than 3 characters and not in stop words
        if (word.length > 3 && !stopWords.contains(word)) {
          wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
        }
      }
    }

    // Sort by frequency and get top topics
    final sortedTopics = wordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Capitalize first letter of each topic
    return sortedTopics
        .take(limit)
        .map((e) => e.key[0].toUpperCase() + e.key.substring(1))
        .toList();
  }

  /// Get recent articles (sorted by publication date)
  List<ArticleModel> getRecentArticles({int limit = 10}) {
    final sorted = List<ArticleModel>.from(_articles);
    sorted.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return sorted.take(limit).toList();
  }

  /// Get articles by sentiment
  List<ArticleModel> getArticlesBySentiment(String sentiment) {
    return _articles
        .where((article) =>
            article.sentiment.toLowerCase() == sentiment.toLowerCase())
        .toList();
  }

  /// Save articles to backend database
  Future<void> _saveArticlesToBackend(List<ArticleModel> articles) async {
    try {
      final articlesJson = articles.map((article) => {
        'articleId': article.articleId,
        'link': article.link,
        'title': article.title,
        'description': article.description,
        'content': article.content,
        'keywords': article.keywords,
        'creator': article.creator,
        'language': article.language,
        'country': article.country,
        'category': article.category,
        'datatype': article.datatype,
        'pubDate': article.pubDate.toIso8601String(),
        'pubDateTZ': article.pubDateTZ,
        'imageUrl': article.imageUrl,
        'videoUrl': article.videoUrl,
        'sourceId': article.sourceId,
        'sourceName': article.sourceName,
        'sourcePriority': article.sourcePriority,
        'sourceUrl': article.sourceUrl,
        'sourceIcon': article.sourceIcon,
        'sentiment': article.sentiment,
        'sentimentStats': {
          'negative': article.sentimentStats.negative,
          'neutral': article.sentimentStats.neutral,
          'positive': article.sentimentStats.positive,
        },
        'aiTag': article.aiTag,
        'aiRegion': article.aiRegion,
        'aiOrg': article.aiOrg,
        'aiSummary': article.aiSummary,
        'duplicate': article.duplicate,
      }).toList();

      final response = await _api.post(
        'articles/batch',
        body: {'articles': articlesJson},
        timeout: const Duration(seconds: 10),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        debugPrint('✅ Saved ${data['savedCount']} articles to backend, skipped ${data['skippedCount']}');
      } else {
        debugPrint('⚠️ Backend save failed: ${_api.getErrorMessage(response)}');
      }
    } catch (e) {
      debugPrint('⚠️ Error saving articles to backend: $e');
      // Don't throw - this is a non-critical background operation
    }
  }
}
