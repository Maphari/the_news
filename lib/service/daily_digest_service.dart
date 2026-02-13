import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/utils/share_utils.dart';
import 'package:the_news/model/daily_digest_model.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/service/text_to_speech_service.dart';
import 'package:the_news/service/ai_service.dart';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/service/calm_mode_service.dart';
import 'package:the_news/service/content_intensity_service.dart';
import 'package:the_news/service/location_service.dart';

/// Service for generating and managing daily AI digests
class DailyDigestService extends ChangeNotifier {
  static final DailyDigestService instance = DailyDigestService._init();
  DailyDigestService._init();

  static const String _digestsKey = 'daily_digests';
  static const String _settingsKey = 'digest_settings';
  static const String _lastGeneratedKey = 'last_digest_generated';

  final NewsProviderService _newsProvider = NewsProviderService.instance;
  final FollowedPublishersService _followedService = FollowedPublishersService.instance;
  final TextToSpeechService _ttsService = TextToSpeechService.instance;
  final AIService _aiService = AIService.instance;
  final ApiClient _api = ApiClient.instance;

  List<DailyDigest> _digests = [];
  DigestSettings _settings = const DigestSettings();
  DateTime? _lastGenerated;
  bool _isGenerating = false;

  List<DailyDigest> get digests => _digests;
  DigestSettings get settings => _settings;
  DateTime? get lastGenerated => _lastGenerated;
  bool get isGenerating => _isGenerating;

  /// Get today's digest
  DailyDigest? get todayDigest {
    final today = DateTime.now();
    try {
      return _digests.firstWhere((digest) {
        final digestDate = digest.generatedAt;
        return digestDate.year == today.year &&
            digestDate.month == today.month &&
            digestDate.day == today.day;
      });
    } catch (e) {
      return null;
    }
  }

  /// Check if digest is available for today
  bool get hasTodayDigest => todayDigest != null;

  /// Initialize service
  Future<void> initialize() async {
    try {
      log('📰 Initializing daily digest service...');
      await _loadDigests();
      await _loadSettings();
      await _loadLastGenerated();
      notifyListeners();
      log('✅ Daily digest service initialized');
    } catch (e) {
      log('⚠️ Error initializing daily digest service: $e');
    }
  }

  /// Initialize and sync digests for a specific user
  Future<void> initializeForUser(String userId) async {
    await initialize();
    await _syncFromBackend(userId);
    notifyListeners();
  }

  Future<void> syncFromBackend(String userId) async {
    await _syncFromBackend(userId);
  }

  /// Load saved digests
  Future<void> _loadDigests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final digestsJson = prefs.getString(_digestsKey);

      if (digestsJson != null) {
        final List<dynamic> data = jsonDecode(digestsJson);
        _digests = data
            .map((json) => DailyDigest.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort by date, newest first
        _digests.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

        // Keep only last 30 days
        final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
        _digests = _digests
            .where((digest) => digest.generatedAt.isAfter(cutoffDate))
            .toList();
      }
    } catch (e) {
      log('⚠️ Error loading digests: $e');
    }
  }

  /// Save digests
  Future<void> _saveDigests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _digests.map((d) => d.toJson()).toList();
      await prefs.setString(_digestsKey, jsonEncode(data));
      log('💾 Digests saved');
    } catch (e) {
      log('⚠️ Error saving digests: $e');
    }
  }

  /// Load settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final data = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = DigestSettings.fromJson(data);
      }
    } catch (e) {
      log('⚠️ Error loading digest settings: $e');
    }
  }

  /// Save settings
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
      log('💾 Digest settings saved');
    } catch (e) {
      log('⚠️ Error saving digest settings: $e');
    }
  }

  /// Load last generated timestamp
  Future<void> _loadLastGenerated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastGeneratedKey);
      if (timestamp != null) {
        _lastGenerated = DateTime.parse(timestamp);
      }
    } catch (e) {
      log('⚠️ Error loading last generated timestamp: $e');
    }
  }

  /// Save last generated timestamp
  Future<void> _saveLastGenerated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastGenerated != null) {
        await prefs.setString(_lastGeneratedKey, _lastGenerated!.toIso8601String());
      }
    } catch (e) {
      log('⚠️ Error saving last generated timestamp: $e');
    }
  }

  /// Update settings
  Future<void> updateSettings(DigestSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _saveSettings();
    log('⚙️ Digest settings updated');
  }

  /// Generate a new daily digest
  Future<DailyDigest?> generateDigest(String userId) async {
    if (_isGenerating) {
      log('⚠️ Digest generation already in progress');
      return null;
    }

    _isGenerating = true;
    notifyListeners();

    try {
      log('🤖 Generating daily digest...');

      // Get articles
      var articles = _newsProvider.articles;
      if (articles.isEmpty) {
        log('⚠️ No articles available for digest');
        _isGenerating = false;
        notifyListeners();
        return null;
      }

      // Apply calm mode and intensity filters for wellbeing
      final calmMode = CalmModeService.instance;
      if (calmMode.isCalmModeEnabled) {
        articles = calmMode.filterArticles(articles);
      }
      articles = ContentIntensityService.instance.filterArticles(articles);

      if (articles.isEmpty) {
        log('⚠️ No eligible articles after filters');
        _isGenerating = false;
        notifyListeners();
        return null;
      }

      // Get user preferences
      final followedSources = _followedService.followedPublisherNames.toList();
      final preferredCategories = await _getPreferredCategories(articles);
      final locationService = LocationService.instance;

      // Create personalization
      final personalization = DigestPersonalization(
        followedSources: followedSources,
        preferredCategories: preferredCategories,
        categoryWeights: _calculateCategoryWeights(preferredCategories),
        userLocation: locationService.currentCountryCode ?? 'US',
        readingLevel: _settings.tone == DigestTone.concise ? 'quick' : 'standard',
        includeOpinions: !_settings.excludedCategories.contains('opinion'),
        includeInternational: !_settings.excludedCategories.contains('world'),
      );

      // Select top articles
      final selectedArticles = _selectTopArticles(
        articles,
        personalization,
        _settings.maxItems,
      );

      // Generate digest items
      final items = await _generateDigestItems(selectedArticles);

      // Generate title and summary
      final title = await _generateTitle(selectedArticles);
      final summary = _generateSummary(items);

      // Create digest
      final digest = DailyDigest(
        digestId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        generatedAt: DateTime.now(),
        title: title,
        summary: summary,
        items: items,
        sourceArticleIds: selectedArticles.map((a) => a.articleId).toList(),
        personalization: personalization,
        estimatedReadingMinutes: _calculateReadingTime(items),
        isRead: false,
      );

      // Save digest
      _digests.insert(0, digest);
      _lastGenerated = DateTime.now();

      await _saveDigests();
      await _saveLastGenerated();
      await _uploadDigest(digest);

      log('✅ Daily digest generated successfully');
      log('📊 ${items.length} items, ${digest.estimatedReadingMinutes} min read');

      _isGenerating = false;
      notifyListeners();

      return digest;
    } catch (e) {
      log('⚠️ Error generating digest: $e');
      _isGenerating = false;
      notifyListeners();
      return null;
    }
  }

  /// Get preferred categories based on reading history
  Future<List<String>> _getPreferredCategories(List<ArticleModel> articles) async {
    // Count category occurrences
    final categoryCount = <String, int>{};

    for (final article in articles.take(50)) {
      for (final category in article.category) {
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
    }

    // Get top 5 categories
    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(5).map((e) => e.key).toList();
  }

  /// Calculate category weights
  Map<String, double> _calculateCategoryWeights(List<String> categories) {
    final weights = <String, double>{};
    final baseWeight = 1.0 / categories.length;

    for (var i = 0; i < categories.length; i++) {
      // Higher weight for preferred categories
      weights[categories[i]] = baseWeight * (categories.length - i);
    }

    return weights;
  }

  /// Select top articles for digest
  List<ArticleModel> _selectTopArticles(
    List<ArticleModel> articles,
    DigestPersonalization personalization,
    int maxItems,
  ) {
    // Score each article
    final scoredArticles = articles.map((article) {
      double score = 0.0;

      // Followed source bonus
      if (personalization.followedSources.contains(article.sourceName)) {
        score += 10.0;
      }

      // Category match bonus
      for (final category in article.category) {
        if (personalization.categoryWeights.containsKey(category)) {
          score += personalization.categoryWeights[category]! * 5.0;
        }
      }

      // Recency bonus (last 24 hours)
      final age = DateTime.now().difference(article.pubDate).inHours;
      if (age <= 24) {
        score += 5.0 - (age / 24 * 5.0);
      }

      // Sentiment balance (prefer neutral or positive)
      if (article.sentiment == 'positive') score += 2.0;
      if (article.sentiment == 'neutral') score += 1.0;

      return _ScoredArticle(article: article, score: score);
    }).toList();

    // Sort by score and take top N
    scoredArticles.sort((a, b) => b.score.compareTo(a.score));

    // Diversify by category
    final selected = <ArticleModel>[];
    final usedCategories = <String>{};

    for (final scored in scoredArticles) {
      if (selected.length >= maxItems) break;

      // Try to get variety in categories
      final hasNewCategory = scored.article.category.any(
        (cat) => !usedCategories.contains(cat),
      );

      if (hasNewCategory || selected.length < maxItems ~/ 2) {
        selected.add(scored.article);
        usedCategories.addAll(scored.article.category);
      }
    }

    // Fill remaining slots if needed
    for (final scored in scoredArticles) {
      if (selected.length >= maxItems) break;
      if (!selected.contains(scored.article)) {
        selected.add(scored.article);
      }
    }

    return selected;
  }

  /// Generate digest items from articles
  Future<List<DigestItem>> _generateDigestItems(List<ArticleModel> articles) async {
    final items = <DigestItem>[];

    for (var index = 0; index < articles.length; index++) {
      final article = articles[index];

      // Determine item type
      final type = _determineItemType(article, index);

      // Generate key points with AI if available
      final keyPoints = await _aiService.generateKeyPoints(article, count: 3);

      // Generate "why it matters" with AI if available
      final whyItMatters = await _aiService.generateWhyItMatters(article);

      // Generate summary with AI if available
      final summary = await _aiService.generateSummary(article);

      items.add(DigestItem(
        itemId: 'item_${DateTime.now().millisecondsSinceEpoch}_$index',
        headline: article.title,
        summary: summary,
        category: article.category.isNotEmpty ? article.category.first : 'General',
        keyPoints: keyPoints,
        whyItMatters: whyItMatters,
        relatedArticleIds: [article.articleId],
        type: type,
        priority: index + 1,
      ));
    }

    return items;
  }

  /// Determine digest item type
  DigestItemType _determineItemType(ArticleModel article, int index) {
    // First item is usually most important
    if (index == 0) return DigestItemType.news;

    // Check if from followed source
    if (_followedService.followedPublisherNames.contains(article.sourceName)) {
      return DigestItemType.followed;
    }

    // Check categories
    if (article.category.contains('opinion')) return DigestItemType.opinion;
    if (article.category.contains('analysis')) return DigestItemType.analysis;

    // Recent articles are trending
    final age = DateTime.now().difference(article.pubDate).inHours;
    if (age <= 6) return DigestItemType.trending;

    return DigestItemType.news;
  }

  /// Extract key points from article
  // ignore: unused_element - Reserved for future AI summarization
  List<String> _extractKeyPoints(ArticleModel article) {
    // Split content into sentences
    final sentences = article.content
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();

    // Take up to 3 key sentences
    final keyPoints = <String>[];

    if (sentences.isNotEmpty) keyPoints.add(sentences.first);
    if (sentences.length > 2) keyPoints.add(sentences[sentences.length ~/ 2]);
    if (sentences.length > 1) keyPoints.add(sentences.last);

    return keyPoints.take(3).toList();
  }

  /// Generate item summary
  // ignore: unused_element - Reserved for future AI summarization
  String _generateItemSummary(ArticleModel article) {
    // Use first 150 characters of content or description
    final text = article.content.isNotEmpty
        ? article.content
        : article.description;

    if (text.length <= 150) return text;

    // Find last complete sentence within 150 chars
    final truncated = text.substring(0, 150);
    final lastPeriod = truncated.lastIndexOf('.');

    if (lastPeriod > 50) {
      return truncated.substring(0, lastPeriod + 1);
    }

    return '${truncated.trim()}...';
  }

  /// Generate "why it matters" explanation
  // ignore: unused_element - Reserved for future AI summarization
  String _generateWhyItMatters(ArticleModel article) {
    final category = article.category.isNotEmpty
        ? article.category.first
        : 'general news';

    final templates = [
      'This $category story is trending and affects current events.',
      'Key development in $category with potential broader implications.',
      'Important update in $category worth following.',
      'Significant $category news that may impact policy and decisions.',
      'This story connects to larger trends in $category.',
    ];

    // Simple hash to select template consistently
    final hash = article.articleId.hashCode.abs();
    return templates[hash % templates.length];
  }

  /// Generate digest title
  Future<String> _generateTitle(List<ArticleModel> articles) async {
    final now = DateTime.now();
    final hour = now.hour;

    String timeOfDay;
    if (hour < 12) {
      timeOfDay = 'morning';
    } else if (hour < 17) {
      timeOfDay = 'afternoon';
    } else {
      timeOfDay = 'evening';
    }

    // Try to generate AI title if available
    final aiTitle = await _aiService.generateDigestTitle(articles, timeOfDay);

    // Fallback to simple title
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final dayName = _getDayName(now.weekday);
    return aiTitle.isNotEmpty ? aiTitle : '$greeting - Your $dayName Digest';
  }

  /// Generate digest summary
  String _generateSummary(List<DigestItem> items) {
    final count = items.length;
    final categories = items.map((i) => i.category).toSet();

    return 'Your personalized digest with $count stories covering ${categories.length} topics. '
           'Stay informed in just ${_calculateReadingTime(items)} minutes.';
  }

  /// Calculate reading time
  int _calculateReadingTime(List<DigestItem> items) {
    const wordsPerMinute = 225;
    int totalWords = 0;

    for (final item in items) {
      totalWords += item.headline.split(' ').length;
      totalWords += item.summary.split(' ').length;
      totalWords += item.keyPoints.join(' ').split(' ').length;
    }

    return (totalWords / wordsPerMinute).ceil().clamp(1, 60);
  }

  /// Get day name
  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  /// Read digest aloud using TTS
  Future<void> readDigestAloud(DailyDigest digest) async {
    try {
      await _ttsService.initialize();

      // Prepare digest text for TTS
      final textToRead = StringBuffer();
      textToRead.writeln(digest.title);
      textToRead.writeln(digest.summary);
      textToRead.writeln();

      for (var i = 0; i < digest.items.length; i++) {
        final item = digest.items[i];
        textToRead.writeln('Story ${i + 1}. ${item.headline}');
        textToRead.writeln(item.summary);
        textToRead.writeln();
      }

      await _ttsService.speak(textToRead.toString());
      log('🎙️ Reading digest aloud');
    } catch (e) {
      log('⚠️ Error reading digest aloud: $e');
    }
  }

  /// Stop reading digest
  Future<void> stopReadingDigest() async {
    await _ttsService.stop();
  }

  /// Mark digest as read
  Future<void> markAsRead(String digestId) async {
    final index = _digests.indexWhere((d) => d.digestId == digestId);
    if (index == -1) return;

    _digests[index] = _digests[index].copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );

    notifyListeners();
    await _saveDigests();
    log('📖 Digest marked as read');
  }

  /// Delete digest
  Future<void> deleteDigest(String digestId, {String? userId}) async {
    _digests.removeWhere((d) => d.digestId == digestId);
    notifyListeners();
    await _saveDigests();
    if (userId != null && userId.isNotEmpty) {
      await deleteDigestRemote(userId: userId, digestId: digestId);
    }
    log('🗑️ Digest deleted');
  }

  /// Clear all digests
  Future<void> clearAllDigests() async {
    _digests.clear();
    _lastGenerated = null;
    notifyListeners();
    await _saveDigests();
    await _saveLastGenerated();
    log('🗑️ All digests cleared');
  }

  Future<void> deleteDigestRemote({
    required String userId,
    required String digestId,
  }) async {
    try {
      await _api.delete(
        'digests/$userId/$digestId',
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      log('⚠️ Error deleting digest on backend: $e');
    }
  }

  Future<void> _uploadDigest(DailyDigest digest) async {
    try {
      final response = await _api.post(
        'digests',
        body: digest.toJson(),
        timeout: const Duration(seconds: 12),
      );
      if (_api.isSuccess(response)) {
        log('✅ Digest synced to backend');
      } else {
        log('⚠️ Digest sync failed: ${_api.getErrorMessage(response)}');
      }
    } catch (e) {
      log('⚠️ Error syncing digest: $e');
    }
  }

  Future<void> _syncFromBackend(String userId) async {
    try {
      final response = await _api.get(
        'digests/$userId',
        timeout: const Duration(seconds: 12),
      );
      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final List<dynamic> items = data['digests'] ?? [];
          final remoteDigests = items
              .map((json) => DailyDigest.fromJson(json as Map<String, dynamic>))
              .toList();
          if (remoteDigests.isNotEmpty) {
            _digests = _mergeRemoteDigests(remoteDigests, _digests);
            await _saveDigests();
          }
        }
      }
    } catch (e) {
      log('⚠️ Error syncing digests from backend: $e');
    }
    notifyListeners();
  }

  List<DailyDigest> _mergeRemoteDigests(
    List<DailyDigest> remote,
    List<DailyDigest> local,
  ) {
    final map = <String, DailyDigest>{};
    for (final digest in local) {
      map[digest.digestId] = digest;
    }
    for (final digest in remote) {
      map[digest.digestId] = digest;
    }
    final merged = map.values.toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return merged;
  }

  /// Share digest
  Future<void> shareDigest(BuildContext context, DailyDigest digest) async {
    try {
      final shareText = StringBuffer();
      shareText.writeln('📰 ${digest.title}');
      shareText.writeln();
      shareText.writeln(digest.summary);
      shareText.writeln();
      shareText.writeln('📚 ${digest.items.length} stories:');
      shareText.writeln();

      for (var i = 0; i < digest.items.length; i++) {
        final item = digest.items[i];
        shareText.writeln('${i + 1}. ${item.headline}');
        shareText.writeln('   ${item.summary}');
        shareText.writeln();
      }

      shareText.writeln('Generated by The News App');

      await ShareUtils.shareText(
        context,
        shareText.toString(),
        subject: digest.title,
      );

      log('📤 Digest shared');
    } catch (e) {
      log('⚠️ Error sharing digest: $e');
    }
  }

  // Advanced Scheduling Methods

  /// Check if digest should be generated now based on schedule settings
  bool shouldGenerateDigestNow() {
    if (hasTodayDigest && !_settings.autoGenerateOnWake) {
      return false; // Already have today's digest
    }

    final now = DateTime.now();

    // Check if in quiet hours
    if (_isInQuietHours(now)) {
      log('🔇 In quiet hours, skipping digest generation');
      return false;
    }

    // Check if should skip weekends
    if (_settings.skipWeekends && _isWeekend(now)) {
      log('📅 Skipping weekend digest');
      return false;
    }

    // Check if today is in scheduled days (if specified)
    if (_settings.scheduledDays.isNotEmpty) {
      final dayOfWeek = now.weekday; // 1=Monday, 7=Sunday
      if (!_settings.scheduledDays.contains(dayOfWeek)) {
        log('📅 Not a scheduled day');
        return false;
      }
    }

    // Check based on frequency
    switch (_settings.frequency) {
      case DigestFrequency.daily:
        return !hasTodayDigest;

      case DigestFrequency.twiceDaily:
        if (hasTodayDigest && _lastGenerated != null) {
          // Check if enough time has passed for second digest
          final hoursSinceLastst = now.difference(_lastGenerated!).inHours;
          return hoursSinceLastst >= 6; // At least 6 hours between digests
        }
        return true;

      case DigestFrequency.weekdays:
        return !_isWeekend(now) && !hasTodayDigest;

      case DigestFrequency.weekly:
        if (_lastGenerated == null) return true;
        final daysSinceLastGenerated = now.difference(_lastGenerated!).inDays;
        return daysSinceLastGenerated >= 7;
    }
  }

  /// Check if currently in quiet hours
  bool _isInQuietHours(DateTime time) {
    final hour = time.hour;
    final start = _settings.quietHoursStart;
    final end = _settings.quietHoursEnd;

    if (start < end) {
      // Normal case: quiet hours within same day (e.g., 22-7)
      return hour >= start && hour < end;
    } else {
      // Quiet hours span midnight (e.g., 22-7 means 10 PM to 7 AM)
      return hour >= start || hour < end;
    }
  }

  /// Check if date is weekend
  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Get next scheduled digest time
  DateTime? getNextScheduledTime() {
    final now = DateTime.now();
    final preferredTime = _settings.preferredTime;

    // Start with today's preferred time
    var nextTime = DateTime(
      now.year,
      now.month,
      now.day,
      preferredTime.hour,
      preferredTime.minute,
    );

    // If time has passed today, move to next eligible day
    if (nextTime.isBefore(now) || nextTime.isAtSameMomentAs(now)) {
      nextTime = nextTime.add(const Duration(days: 1));
    }

    // Skip weekends if needed
    while (_settings.skipWeekends && _isWeekend(nextTime)) {
      nextTime = nextTime.add(const Duration(days: 1));
    }

    // Check scheduled days
    while (_settings.scheduledDays.isNotEmpty &&
        !_settings.scheduledDays.contains(nextTime.weekday)) {
      nextTime = nextTime.add(const Duration(days: 1));
    }

    // Adjust for quiet hours
    if (_isInQuietHours(nextTime)) {
      nextTime = DateTime(
        nextTime.year,
        nextTime.month,
        nextTime.day,
        _settings.quietHoursEnd,
        0,
      );
    }

    return nextTime;
  }

  /// Get optimal time based on user's reading patterns (adaptive scheduling)
  Future<TimeOfDay?> getAdaptiveScheduleTime() async {
    if (!_settings.adaptiveScheduling) {
      return _settings.preferredTime;
    }

    // This would analyze when user typically reads digests
    // For now, return preferred time
    // In a real implementation, you would:
    // 1. Track when user opens/reads digests
    // 2. Find most common time window
    // 3. Adjust schedule accordingly

    return _settings.preferredTime;
  }

  /// Check if it's time for secondary digest (for twice daily)
  bool isTimeForSecondaryDigest() {
    if (_settings.frequency != DigestFrequency.twiceDaily) {
      return false;
    }

    if (_settings.secondaryTime == null) {
      return false; // No secondary time set
    }

    final now = DateTime.now();
    final secondaryTime = _settings.secondaryTime!;

    // Check if current time is close to secondary time (within 30 minutes)
    final targetTime = DateTime(
      now.year,
      now.month,
      now.day,
      secondaryTime.hour,
      secondaryTime.minute,
    );

    final diff = now.difference(targetTime).abs().inMinutes;
    return diff <= 30;
  }

  /// Schedule next digest generation
  Future<void> scheduleNextDigest() async {
    final nextTime = getNextScheduledTime();
    if (nextTime == null) return;

    log('📅 Next digest scheduled for: $nextTime');
    // In a real app, you would use WorkManager or similar to schedule background task
    // For now, just log the schedule
  }
}

/// Helper class for article scoring
class _ScoredArticle {
  final ArticleModel article;
  final double score;

  _ScoredArticle({required this.article, required this.score});
}
