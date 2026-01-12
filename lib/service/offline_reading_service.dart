import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Service for managing offline reading queue
class OfflineReadingService extends ChangeNotifier {
  static final OfflineReadingService instance = OfflineReadingService._init();
  OfflineReadingService._init();

  static const String _queueKey = 'offline_queue';
  static const String _settingsKey = 'offline_settings'; // ignore: unused_field - Reserved for future settings

  List<String> _queuedArticleIds = [];
  final Map<String, ArticleModel> _cachedArticles = {};
  final Map<String, String> _cachedImages = {};
  final Map<String, bool> _syncStatus = {}; // Track sync status for each article
  final Map<String, bool> _readStatus = {}; // Track read status offline

  // Background download tracking
  final Map<String, double> _downloadProgress = {}; // articleId -> progress (0-1)
  bool _isDownloading = false;
  int _downloadedCount = 0;
  int _totalToDownload = 0;

  bool _autoDownloadOnWiFi = true;
  int _maxStorageMB = 500;

  // Getters
  List<String> get queuedArticleIds => _queuedArticleIds;
  Map<String, ArticleModel> get cachedArticles => _cachedArticles;
  bool get autoDownloadOnWiFi => _autoDownloadOnWiFi;
  int get maxStorageMB => _maxStorageMB;
  bool get isDownloading => _isDownloading;
  int get downloadedCount => _downloadedCount;
  int get totalToDownload => _totalToDownload;
  double get downloadProgress => _totalToDownload > 0 ? _downloadedCount / _totalToDownload : 0.0;
  Map<String, double> get articleDownloadProgress => _downloadProgress;

  /// Check if article is cached for offline reading
  bool isArticleCached(String articleId) {
    return _cachedArticles.containsKey(articleId);
  }

  /// Get cached article count
  int get cachedArticleCount => _cachedArticles.length;

  /// Initialize service
  Future<void> initialize() async {
    try {
      log('📥 Initializing offline reading service...');
      await _loadQueue();
      await _loadSettings();
      await _loadCachedArticles();
      log('✅ Offline reading service initialized');
    } catch (e) {
      log('⚠️ Error initializing offline reading service: $e');
    }
  }

  /// Load queue from storage
  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson != null) {
        final List<dynamic> data = jsonDecode(queueJson);
        _queuedArticleIds = data.cast<String>();
      }
    } catch (e) {
      log('⚠️ Error loading queue: $e');
    }
  }

  /// Save queue to storage
  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_queueKey, jsonEncode(_queuedArticleIds));
    } catch (e) {
      log('⚠️ Error saving queue: $e');
    }
  }

  /// Load settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoDownloadOnWiFi = prefs.getBool('offline_auto_wifi') ?? true;
      _maxStorageMB = prefs.getInt('offline_max_storage') ?? 500;
    } catch (e) {
      log('⚠️ Error loading settings: $e');
    }
  }

  /// Update settings
  Future<void> updateSettings({
    bool? autoDownloadOnWiFi,
    int? maxStorageMB,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (autoDownloadOnWiFi != null) {
        _autoDownloadOnWiFi = autoDownloadOnWiFi;
        await prefs.setBool('offline_auto_wifi', autoDownloadOnWiFi);
      }

      if (maxStorageMB != null) {
        _maxStorageMB = maxStorageMB;
        await prefs.setInt('offline_max_storage', maxStorageMB);
      }

      notifyListeners();
    } catch (e) {
      log('⚠️ Error updating settings: $e');
    }
  }

  /// Load cached articles from disk
  Future<void> _loadCachedArticles() async {
    try {
      final dir = await _getCacheDirectory();
      final articlesDir = Directory('${dir.path}/articles');

      if (await articlesDir.exists()) {
        final files = articlesDir.listSync();

        for (final file in files) {
          if (file is File && file.path.endsWith('.json')) {
            try {
              final content = await file.readAsString();
              final json = jsonDecode(content);
              final article = ArticleModel.fromJson(json);
              _cachedArticles[article.articleId] = article;
            } catch (e) {
              log('⚠️ Error loading cached article: $e');
            }
          }
        }
      }

      log('📦 Loaded ${_cachedArticles.length} cached articles');
    } catch (e) {
      log('⚠️ Error loading cached articles: $e');
    }
  }

  /// Add article to offline queue
  Future<bool> addToQueue(ArticleModel article) async {
    try {
      if (_queuedArticleIds.contains(article.articleId)) {
        log('⚠️ Article already in queue');
        return false;
      }

      // Check storage limit
      final currentSize = await _calculateStorageSize();
      if (currentSize >= _maxStorageMB * 1024 * 1024) {
        log('⚠️ Storage limit reached');
        return false;
      }

      _queuedArticleIds.add(article.articleId);
      await _saveQueue();

      // Download article and images
      await _cacheArticle(article);

      notifyListeners();
      log('✅ Article added to offline queue: ${article.title}');
      return true;
    } catch (e) {
      log('⚠️ Error adding to queue: $e');
      return false;
    }
  }

  /// Remove article from queue
  Future<void> removeFromQueue(String articleId) async {
    try {
      _queuedArticleIds.remove(articleId);
      await _saveQueue();

      // Delete cached files
      await _deleteCachedArticle(articleId);

      _cachedArticles.remove(articleId);
      _cachedImages.remove(articleId);

      notifyListeners();
      log('✅ Article removed from offline queue');
    } catch (e) {
      log('⚠️ Error removing from queue: $e');
    }
  }

  /// Cache article data
  Future<void> _cacheArticle(ArticleModel article) async {
    try {
      final dir = await _getCacheDirectory();
      final articlesDir = Directory('${dir.path}/articles');

      if (!await articlesDir.exists()) {
        await articlesDir.create(recursive: true);
      }

      // Create article map manually
      final articleMap = {
        'article_id': article.articleId,
        'link': article.link,
        'title': article.title,
        'description': article.description,
        'content': article.content,
        'pub_date': article.pubDate.toIso8601String(),
        'image_url': article.imageUrl,
        'source_name': article.sourceName,
        'source_id': article.sourceId,
        'category': article.category,
        'keywords': article.keywords,
      };

      // Save article JSON
      final articleFile = File('${articlesDir.path}/${article.articleId}.json');
      await articleFile.writeAsString(jsonEncode(articleMap));

      _cachedArticles[article.articleId] = article;

      // Download and cache image if available
      if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
        await _cacheImage(article.articleId, article.imageUrl!);
      }

      log('💾 Article cached: ${article.title}');
    } catch (e) {
      log('⚠️ Error caching article: $e');
    }
  }

  /// Cache article image
  Future<void> _cacheImage(String articleId, String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        // Compress image
        final compressed = await FlutterImageCompress.compressWithList(
          response.bodyBytes,
          quality: 85,
          format: CompressFormat.webp,
        );

        final dir = await _getCacheDirectory();
        final imagesDir = Directory('${dir.path}/images');
        await imagesDir.create(recursive: true);

        final imageFile = File('${imagesDir.path}/$articleId.webp');
        await imageFile.writeAsBytes(compressed);

        _cachedImages[articleId] = imageFile.path;
      }
    } catch (e) {
      log('⚠️ Error caching image: $e');
    }
  }

  /// Delete cached article
  Future<void> _deleteCachedArticle(String articleId) async {
    try {
      final dir = await _getCacheDirectory();

      // Delete article JSON
      final articleFile = File('${dir.path}/articles/$articleId.json');
      if (await articleFile.exists()) {
        await articleFile.delete();
      }

      // Delete image
      final imagesDir = Directory('${dir.path}/images');
      if (await imagesDir.exists()) {
        final files = imagesDir.listSync();
        for (final file in files) {
          if (file.path.contains(articleId)) {
            await file.delete();
          }
        }
      }

      log('🗑️ Cached article deleted: $articleId');
    } catch (e) {
      log('⚠️ Error deleting cached article: $e');
    }
  }

  /// Get cached image path
  String? getCachedImagePath(String articleId) {
    return _cachedImages[articleId];
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      final dir = await _getCacheDirectory();

      // Delete articles directory
      final articlesDir = Directory('${dir.path}/articles');
      if (await articlesDir.exists()) {
        await articlesDir.delete(recursive: true);
      }

      // Delete images directory
      final imagesDir = Directory('${dir.path}/images');
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }

      _queuedArticleIds.clear();
      _cachedArticles.clear();
      _cachedImages.clear();

      await _saveQueue();

      notifyListeners();
      log('🗑️ All cache cleared');
    } catch (e) {
      log('⚠️ Error clearing cache: $e');
    }
  }

  /// Calculate current storage size
  Future<int> _calculateStorageSize() async {
    try {
      final dir = await _getCacheDirectory();
      int totalSize = 0;

      if (await dir.exists()) {
        final files = dir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      return totalSize;
    } catch (e) {
      log('⚠️ Error calculating storage size: $e');
      return 0;
    }
  }

  /// Get storage size in MB
  Future<double> getStorageSizeMB() async {
    final bytes = await _calculateStorageSize();
    return bytes / (1024 * 1024);
  }

  /// Get cache directory
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/offline_cache');
  }

  /// Download multiple articles in background with progress tracking
  Future<void> downloadArticles(List<ArticleModel> articles, {
    Function(int downloaded, int total)? onProgress,
    bool skipExisting = true,
  }) async {
    if (_isDownloading) {
      log('⚠️ Download already in progress');
      return;
    }

    try {
      _isDownloading = true;
      _downloadedCount = 0;
      _totalToDownload = skipExisting
          ? articles.where((a) => !isArticleCached(a.articleId)).length
          : articles.length;

      if (_totalToDownload == 0) {
        log('✅ All articles already cached');
        _isDownloading = false;
        return;
      }

      log('📥 Starting background download of $_totalToDownload articles...');
      notifyListeners();

      for (final article in articles) {
        if (skipExisting && isArticleCached(article.articleId)) {
          continue;
        }

        try {
          // Update individual article progress
          _downloadProgress[article.articleId] = 0.0;
          notifyListeners();

          // Download article
          await _cacheArticleWithProgress(article);

          _downloadedCount++;
          _downloadProgress[article.articleId] = 1.0;

          // Callback for progress updates
          onProgress?.call(_downloadedCount, _totalToDownload);
          notifyListeners();

          log('✅ Downloaded ${article.title} ($_downloadedCount/$_totalToDownload)');
        } catch (e) {
          log('⚠️ Error downloading article ${article.title}: $e');
          _downloadProgress[article.articleId] = -1.0; // Mark as failed
        }
      }

      log('✅ Background download complete: $_downloadedCount/$_totalToDownload articles');
    } catch (e) {
      log('⚠️ Error in background download: $e');
    } finally {
      _isDownloading = false;
      _downloadProgress.clear();
      notifyListeners();
    }
  }

  /// Cache article with progress tracking
  Future<void> _cacheArticleWithProgress(ArticleModel article) async {
    try {
      final dir = await _getCacheDirectory();
      final articlesDir = Directory('${dir.path}/articles');

      if (!await articlesDir.exists()) {
        await articlesDir.create(recursive: true);
      }

      // Update progress: 0.3 after directory setup
      _downloadProgress[article.articleId] = 0.3;
      notifyListeners();

      // Create article map manually
      final articleMap = {
        'article_id': article.articleId,
        'link': article.link,
        'title': article.title,
        'description': article.description,
        'content': article.content,
        'pub_date': article.pubDate.toIso8601String(),
        'image_url': article.imageUrl,
        'source_name': article.sourceName,
        'source_id': article.sourceId,
        'category': article.category,
        'keywords': article.keywords,
      };

      // Save article JSON
      final articleFile = File('${articlesDir.path}/${article.articleId}.json');
      await articleFile.writeAsString(jsonEncode(articleMap));

      // Update progress: 0.6 after article saved
      _downloadProgress[article.articleId] = 0.6;
      notifyListeners();

      _cachedArticles[article.articleId] = article;

      // Add to queue if not already there
      if (!_queuedArticleIds.contains(article.articleId)) {
        _queuedArticleIds.add(article.articleId);
        await _saveQueue();
      }

      // Download and cache image if available
      if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
        await _cacheImage(article.articleId, article.imageUrl!);
      }

      // Update progress: 1.0 complete
      _downloadProgress[article.articleId] = 1.0;
      notifyListeners();

      log('💾 Article cached with progress tracking: ${article.title}');
    } catch (e) {
      log('⚠️ Error caching article with progress: $e');
      rethrow;
    }
  }

  /// Cancel ongoing download
  void cancelDownload() {
    if (_isDownloading) {
      _isDownloading = false;
      _downloadProgress.clear();
      notifyListeners();
      log('🛑 Download cancelled');
    }
  }

  /// Download articles from specific category
  Future<void> downloadArticlesByCategory(
    List<ArticleModel> allArticles,
    String category, {
    int? limit,
  }) async {
    final filtered = allArticles
        .where((a) => a.category.contains(category))
        .take(limit ?? allArticles.length)
        .toList();

    await downloadArticles(filtered);
  }

  /// Download top articles based on a criteria
  Future<void> downloadTopArticles(
    List<ArticleModel> articles, {
    int limit = 10,
  }) async {
    final topArticles = articles.take(limit).toList();
    await downloadArticles(topArticles);
  }

  /// Schedule periodic background downloads (to be called by background task)
  Future<void> performScheduledDownload(List<ArticleModel> articles) async {
    // Check if WiFi is required and available
    if (_autoDownloadOnWiFi) {
      // In a real app, check WiFi connectivity here
      // For now, proceed with download
      log('📡 Performing scheduled background download...');
      await downloadArticles(articles, skipExisting: true);
    }
  }

  /// Mark article as read offline
  Future<void> markAsRead(String articleId) async {
    try {
      _readStatus[articleId] = true;
      _syncStatus[articleId] = false; // Needs sync
      notifyListeners();
      log('📖 Article marked as read offline: $articleId');
    } catch (e) {
      log('⚠️ Error marking article as read: $e');
    }
  }

  /// Sync read status when online
  Future<void> syncReadStatus() async {
    try {
      final unsynced = _readStatus.entries
          .where((entry) => entry.value && _syncStatus[entry.key] != true)
          .toList();

      if (unsynced.isEmpty) {
        log('✅ All articles synced');
        return;
      }

      log('🔄 Syncing ${unsynced.length} read articles...');

      for (final entry in unsynced) {
        final articleId = entry.key;
        // Here you would call your analytics service or backend API
        // For now, just mark as synced
        _syncStatus[articleId] = true;
      }

      notifyListeners();
      log('✅ Synced ${unsynced.length} articles');
    } catch (e) {
      log('⚠️ Error syncing read status: $e');
    }
  }

  /// Search cached articles offline
  List<ArticleModel> searchOfflineArticles(String query) {
    try {
      if (query.trim().isEmpty) {
        return _cachedArticles.values.toList();
      }

      final lowerQuery = query.toLowerCase();

      return _cachedArticles.values.where((article) {
        return article.title.toLowerCase().contains(lowerQuery) ||
            article.description.toLowerCase().contains(lowerQuery) ||
            article.content.toLowerCase().contains(lowerQuery) ||
            article.category.any((cat) => cat.toLowerCase().contains(lowerQuery)) ||
            article.sourceName.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      log('⚠️ Error searching offline articles: $e');
      return [];
    }
  }

  /// Auto-cleanup old cached articles
  Future<void> cleanupOldArticles({int daysToKeep = 30}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
      final toRemove = <String>[];

      for (final entry in _cachedArticles.entries) {
        if (entry.value.pubDate.isBefore(cutoff)) {
          toRemove.add(entry.key);
        }
      }

      if (toRemove.isEmpty) {
        log('✅ No old articles to cleanup');
        return;
      }

      log('🗑️ Cleaning up ${toRemove.length} old articles...');

      for (final articleId in toRemove) {
        await removeFromQueue(articleId);
      }

      log('✅ Cleanup complete: removed ${toRemove.length} articles');
    } catch (e) {
      log('⚠️ Error cleaning up old articles: $e');
    }
  }

  /// Get articles by date range
  List<ArticleModel> getArticlesByDateRange(DateTime start, DateTime end) {
    return _cachedArticles.values.where((article) {
      return article.pubDate.isAfter(start) && article.pubDate.isBefore(end);
    }).toList();
  }

  /// Get articles by category
  List<ArticleModel> getArticlesByCategory(String category) {
    return _cachedArticles.values.where((article) {
      return article.category.contains(category);
    }).toList();
  }

  /// Get articles by source
  List<ArticleModel> getArticlesBySource(String sourceName) {
    return _cachedArticles.values.where((article) {
      return article.sourceName == sourceName;
    }).toList();
  }

  /// Check if needs sync
  bool needsSync() {
    return _readStatus.entries.any((entry) =>
      entry.value && _syncStatus[entry.key] != true
    );
  }

  /// Get unsynced count
  int getUnsyncedCount() {
    return _readStatus.entries
        .where((entry) => entry.value && _syncStatus[entry.key] != true)
        .length;
  }
}
