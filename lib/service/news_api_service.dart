import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:the_news/model/news_article_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service to fetch news from NewsData.io API
///
/// Get your API key from: https://newsdata.io/
/// Free tier: 200 requests/day
class NewsApiService {
  static final NewsApiService instance = NewsApiService._init();

  // Get API key from environment variable
  // Add to .env: NEWS_API_KEY=your_key_here
  String _apiKey = '';
  String _baseUrl = '';

  // Cache keys
  static const String _cacheKeyPrefix = 'news_cache_';
  static const String _cacheTimePrefix = 'news_cache_time_';
  static const Duration _cacheExpiration = Duration(minutes: 15);

  NewsApiService._init();

  /// Initialize the service with API key from environment
  Future<void> initialize() async {
    if (_apiKey.isNotEmpty) {
      return; // Already initialized
    }

    if (_baseUrl.isNotEmpty) {
      return; // Already initialized
    }

    await dotenv.load();
    _apiKey = dotenv.env['NEWS_API_KEY'] ?? '';
    _baseUrl = dotenv.env['NEWS_API_BASE_URL'] ?? '';

    if (_apiKey.isEmpty) {
      log('⚠️ WARNING: NEWS_API_KEY not found in .env file');
      log('Add NEWS_API_KEY=your_key to .env to use real news data');
    }

    if (_baseUrl.isEmpty) {
      log('⚠️ WARNING: NEWS_API_BASE_URL not found in .env file');
      log('Add NEWS_API_BASE_URL=your_url to .env to use real news data');
    }
  }

  String _buildCacheKey({
    String? category,
    String? country,
    String? language,
    String? query,
  }) {
    final safeCategory = (category ?? 'all').toLowerCase();
    final safeCountry = (country ?? 'any').toLowerCase();
    final safeLanguage = (language ?? 'en').toLowerCase();
    final safeQuery = (query ?? '').toLowerCase().trim();

    final parts = <String>[
      'cat=$safeCategory',
      'cty=$safeCountry',
      'lang=$safeLanguage',
    ];
    if (safeQuery.isNotEmpty) {
      parts.add('q=$safeQuery');
    }
    return parts.join('|');
  }

  /// Fetch latest news articles
  ///
  /// Parameters:
  /// - category: 'business', 'technology', 'sports', etc.
  /// - country: 'us', 'gb', 'in', etc. (optional)
  /// - language: 'en', 'es', etc. (default: 'en')
  /// - query: Search keywords (optional)
  Future<List<ArticleModel>> fetchNews({
    String? category,
    String? country,
    String language = 'en',
    String? query,
    bool useCache = true,
  }) async {
    final cacheKey = _buildCacheKey(
      category: category,
      country: country,
      language: language,
      query: query,
    );

    // Check cache first
    if (useCache) {
      final cached = await _getCachedNews(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    try {
      // Build query parameters
      final params = {
        'apikey': _apiKey,
        'language': language,
      };

      if (category != null && category.toLowerCase() != 'all') {
        params['category'] = category.toLowerCase();
      }
      if (country != null) {
        params['country'] = country.toLowerCase();
      }
      if (query != null && query.isNotEmpty) {
        params['q'] = query;
      }

      final uri = Uri.parse('$_baseUrl/news').replace(queryParameters: params);

      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your connection');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] != 'success') {
          throw Exception(data['message'] ?? 'API error');
        }

        final results = data['results'] as List;
        final articles = results
            .map((json) => _parseNewsDataArticle(json))
            .where((article) => article != null)
            .cast<ArticleModel>()
            .toList();

        // Cache the results
        await _cacheNews(cacheKey, articles);

        return articles;
      } else if (response.statusCode == 429) {
        throw Exception('API rate limit exceeded. Please try again later.');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your configuration.');
      } else {
        throw Exception('Failed to fetch news: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching news: $e');

      // Try to return cached data even if expired
      final cached = await _getCachedNews(cacheKey, ignoreExpiration: true);
      if (cached != null && cached.isNotEmpty) {
        log('Returning expired cache due to error');
        return cached;
      }

      rethrow;
    }
  }

  /// Search news articles
  Future<List<ArticleModel>> searchNews({
    required String query,
    String? category,
    String language = 'en',
  }) async {
    return fetchNews(
      query: query,
      category: category,
      language: language,
      useCache: false, // Don't cache search results
    );
  }

  /// Fetch top headlines
  Future<List<ArticleModel>> fetchTopHeadlines({
    String? category,
    String language = 'en',
  }) async {
    return fetchNews(
      category: category,
      language: language,
      useCache: true,
    );
  }

  /// Parse NewsData.io article to ArticleModel
  ArticleModel? _parseNewsDataArticle(Map<String, dynamic> json) {
    try {
      return ArticleModel(
        articleId: json['article_id'] ?? _generateId(),
        link: json['link'] ?? '',
        title: json['title'] ?? 'No title',
        description: json['description'] ?? json['title'] ?? '',
        content: json['content'] ?? json['description'] ?? '',
        keywords: _parseStringList(json['keywords']),
        creator: _parseStringList(json['creator'], defaultValue: ['Unknown']),
        language: json['language'] ?? 'en',
        country: _parseStringList(json['country']),
        category: _parseStringList(json['category'], defaultValue: ['general']),
        datatype: 'news',
        pubDate: _parseDate(json['pubDate']),
        pubDateTZ: json['pubDateTZ'] ?? 'UTC',
        imageUrl: json['image_url'],
        videoUrl: json['video_url'],
        sourceId: json['source_id'] ?? 'unknown',
        sourceName: json['source_name'] ?? json['source_id'] ?? 'Unknown',
        sourcePriority: json['source_priority'] ?? 0,
        sourceUrl: json['source_url'] ?? '',
        sourceIcon: json['source_icon'] ?? '',
        sentiment: json['sentiment'] ?? 'neutral',
        sentimentStats: _parseSentimentStats(json['sentiment_stats']),
        aiTag: _parseStringList(json['ai_tag']),
        aiRegion: _parseStringList(json['ai_region']),
        aiOrg: json['ai_org'],
        aiSummary: json['ai_summary'] ?? json['description'] ?? '',
        duplicate: json['duplicate'] ?? false,
      );
    } catch (e) {
      log('Error parsing article: $e');
      return null;
    }
  }

  /// Parse string or list to List&ltString&gt
  List<String> _parseStringList(dynamic value, {List<String>? defaultValue}) {
    if (value == null) return defaultValue ?? [];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    } else if (value is String) {
      // If it's a string, return it as a single-item list
      return [value];
    }

    return defaultValue ?? [];
  }

  /// Parse date from string
  DateTime _parseDate(dynamic dateStr) {
    if (dateStr == null) return DateTime.now();

    try {
      if (dateStr is String) {
        return DateTime.parse(dateStr);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Parse sentiment stats or create default
  SentimentStats _parseSentimentStats(dynamic stats) {
    if (stats == null) {
      return SentimentStats(
        negative: 10.0,
        neutral: 60.0,
        positive: 30.0,
      );
    }

    try {
      return SentimentStats.fromJson(stats as Map<String, dynamic>);
    } catch (e) {
      return SentimentStats(
        negative: 10.0,
        neutral: 60.0,
        positive: 30.0,
      );
    }
  }

  /// Generate a unique ID for articles without one
  String _generateId() {
    return 'article_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Cache news articles
  Future<void> _cacheNews(String key, List<ArticleModel> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$key';
      final timeKey = '$_cacheTimePrefix$key';

      // Convert articles to JSON
      final jsonData = articles.map((a) => {
        'article_id': a.articleId,
        'link': a.link,
        'title': a.title,
        'description': a.description,
        'content': a.content,
        'keywords': a.keywords,
        'creator': a.creator,
        'language': a.language,
        'country': a.country,
        'category': a.category,
        'datatype': a.datatype,
        'pubDate': a.pubDate.toIso8601String(),
        'pubDateTZ': a.pubDateTZ,
        'image_url': a.imageUrl,
        'video_url': a.videoUrl,
        'source_id': a.sourceId,
        'source_name': a.sourceName,
        'source_priority': a.sourcePriority,
        'source_url': a.sourceUrl,
        'source_icon': a.sourceIcon,
        'sentiment': a.sentiment,
        'sentiment_stats': {
          'negative': a.sentimentStats.negative,
          'neutral': a.sentimentStats.neutral,
          'positive': a.sentimentStats.positive,
        },
        'ai_tag': a.aiTag,
        'ai_region': a.aiRegion,
        'ai_org': a.aiOrg,
        'ai_summary': a.aiSummary,
        'duplicate': a.duplicate,
      }).toList();

      await prefs.setString(cacheKey, jsonEncode(jsonData));
      await prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      log('Error caching news: $e');
    }
  }

  /// Get cached news articles
  Future<List<ArticleModel>?> _getCachedNews(
    String key, {
    bool ignoreExpiration = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$key';
      final timeKey = '$_cacheTimePrefix$key';

      final cachedData = prefs.getString(cacheKey);
      final cachedTime = prefs.getInt(timeKey);

      if (cachedData == null || cachedTime == null) {
        return null;
      }

      // Check if cache expired
      if (!ignoreExpiration) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTime;
        if (cacheAge > _cacheExpiration.inMilliseconds) {
          return null; // Cache expired
        }
      }

      final List<dynamic> jsonList = jsonDecode(cachedData);
      return jsonList
          .map((json) => ArticleModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Error reading cache: $e');
      return null;
    }
  }

  /// Clear all cached news
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix) || key.startsWith(_cacheTimePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      log('Error clearing cache: $e');
    }
  }

  /// Check if API is configured
  bool get isConfigured => _apiKey.isNotEmpty;
}
