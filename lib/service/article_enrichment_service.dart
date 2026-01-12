import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/enriched_article_model.dart';
import 'package:the_news/service/subscription_service.dart';

/// Service to enrich articles with full content from source URLs
/// Uses backend web scraper to extract full article text, images, and videos
class ArticleEnrichmentService extends ChangeNotifier {
  static final ArticleEnrichmentService instance = ArticleEnrichmentService._init();
  ArticleEnrichmentService._init();

  final _api = ApiClient.instance;
  final Map<String, EnrichedArticle> _cache = {};
  final Map<String, bool> _loading = {};

  /// Get enriched article by ID
  EnrichedArticle? getEnrichedArticle(String articleId) {
    return _cache[articleId];
  }

  /// Check if article is currently being enriched
  bool isEnriching(String articleId) {
    return _loading[articleId] ?? false;
  }

  /// Check if article has been enriched (cached)
  bool isEnriched(String articleId) {
    return _cache.containsKey(articleId);
  }

  /// Enrich an article by fetching full content from source URL
  Future<EnrichedArticle> enrichArticle(String articleId, String sourceUrl) async {
    // Return cached if available
    if (_cache.containsKey(articleId)) {
      log('✅ Returning cached enriched article: $articleId');
      return _cache[articleId]!;
    }

    // Check if already loading
    if (_loading[articleId] == true) {
      log('⏳ Article already being enriched: $articleId');
      // Wait for it to finish (poll every 100ms for up to 10 seconds)
      for (int i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_cache.containsKey(articleId)) {
          return _cache[articleId]!;
        }
        if (_loading[articleId] != true) {
          break;
        }
      }
    }

    _loading[articleId] = true;
    notifyListeners();

    try {
      // Try to load from local storage first
      final cached = await _loadFromCache(articleId);
      if (cached != null) {
        _cache[articleId] = cached;
        _loading[articleId] = false;
        notifyListeners();
        log('💾 Loaded enriched article from cache: $articleId');
        return cached;
      }

      // Fetch from backend scraper
      log('📥 Enriching article from backend: $articleId');

      final response = await _api.post(
        'articles/enrich',
        body: {
          'articleId': articleId,
          'sourceUrl': sourceUrl,
        },
        timeout: const Duration(seconds: 30), // Scraping can take time
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          var enriched = EnrichedArticle.fromJson(data);

          // If user has premium access, generate AI summary
          final subscriptionService = SubscriptionService.instance;
          if (subscriptionService.canAccessPremiumFeatures && enriched.textContent != null) {
            final aiSummary = await _generateAISummary(articleId, enriched.textContent!);
            if (aiSummary != null) {
              // Create new enriched article with AI summary
              enriched = EnrichedArticle(
                articleId: enriched.articleId,
                sourceUrl: enriched.sourceUrl,
                title: enriched.title,
                content: enriched.content,
                textContent: enriched.textContent,
                excerpt: enriched.excerpt,
                author: enriched.author,
                publishedDate: enriched.publishedDate,
                images: enriched.images,
                videos: enriched.videos,
                readingTimeMinutes: enriched.readingTimeMinutes,
                aiSummary: aiSummary,
                success: enriched.success,
                error: enriched.error,
              );
            }
          }

          _cache[articleId] = enriched;

          // Save to local storage
          await _saveToCache(articleId, enriched);

          _loading[articleId] = false;
          notifyListeners();
          log('✅ Article enriched successfully: $articleId');
          return enriched;
        }
      }

      // If backend fails, return error enrichment
      final errorEnrichment = EnrichedArticle(
        articleId: articleId,
        sourceUrl: sourceUrl,
        success: false,
        error: 'Failed to enrich article from backend',
      );

      _cache[articleId] = errorEnrichment;
      _loading[articleId] = false;
      notifyListeners();
      log('⚠️ Backend enrichment failed for: $articleId');
      return errorEnrichment;
    } catch (e) {
      log('⚠️ Error enriching article: $e');

      final errorEnrichment = EnrichedArticle(
        articleId: articleId,
        sourceUrl: sourceUrl,
        success: false,
        error: e.toString(),
      );

      _cache[articleId] = errorEnrichment;
      _loading[articleId] = false;
      notifyListeners();
      return errorEnrichment;
    }
  }

  /// Load enriched article from local cache
  Future<EnrichedArticle?> _loadFromCache(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('enriched_article_$articleId');

      if (cachedJson != null) {
        final data = json.decode(cachedJson);
        return EnrichedArticle.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      log('⚠️ Error loading enriched article from cache: $e');
    }
    return null;
  }

  /// Save enriched article to local cache
  Future<void> _saveToCache(String articleId, EnrichedArticle enriched) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'enriched_article_$articleId',
        json.encode(enriched.toJson()),
      );
      log('💾 Saved enriched article to cache: $articleId');
    } catch (e) {
      log('⚠️ Error saving enriched article to cache: $e');
    }
  }

  /// Clear cache for a specific article
  Future<void> clearArticleCache(String articleId) async {
    _cache.remove(articleId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('enriched_article_$articleId');
      notifyListeners();
    } catch (e) {
      log('⚠️ Error clearing article cache: $e');
    }
  }

  /// Clear all cached enriched articles
  Future<void> clearAllCache() async {
    _cache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('enriched_article_')) {
          await prefs.remove(key);
        }
      }
      notifyListeners();
      log('🧹 Cleared all enriched article cache');
    } catch (e) {
      log('⚠️ Error clearing all cache: $e');
    }
  }

  /// Pre-fetch and cache article enrichment (background task)
  Future<void> prefetchArticle(String articleId, String sourceUrl) async {
    // Don't block, just fire and forget
    enrichArticle(articleId, sourceUrl).catchError((e) {
      log('⚠️ Prefetch failed for $articleId: $e');
      return EnrichedArticle(
        articleId: articleId,
        sourceUrl: sourceUrl,
        success: false,
        error: e.toString(),
      );
    });
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedArticles': _cache.length,
      'currentlyEnriching': _loading.values.where((v) => v).length,
      'successfulEnrichments': _cache.values.where((v) => v.success).length,
      'failedEnrichments': _cache.values.where((v) => !v.success).length,
    };
  }

  /// Generate AI summary for article text (premium feature)
  Future<AISummary?> _generateAISummary(String articleId, String fullText) async {
    try {
      log('🤖 Generating AI summary for: $articleId');

      final response = await _api.post(
        'articles/ai-summary',
        body: {
          'articleId': articleId,
          'fullText': fullText,
        },
        timeout: const Duration(seconds: 15),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final summary = AISummary.fromJson(data);
          log('✅ AI summary generated for: $articleId');
          return summary;
        }
      }

      log('⚠️ Failed to generate AI summary for: $articleId');
      return null;
    } catch (e) {
      log('⚠️ Error generating AI summary: $e');
      return null;
    }
  }
}
