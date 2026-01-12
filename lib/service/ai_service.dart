import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:the_news/service/premium_features_service.dart';

/// AI provider options
enum AIProvider {
  githubGpt4o, // GitHub Models - GPT-4o-mini (Free)
  githubDeepseek, // GitHub Models - DeepSeek (Free)
  githubLlama, // GitHub Models - Llama 3.1 (Free)
  githubGrok, // GitHub Models - Grok (Free)
  openai, // Direct OpenAI API (Paid)
  gemini, // Google Gemini API (Paid/Free tier)
  claude, // Anthropic Claude (Paid)
  none, // Fallback to algorithm
}

/// Service for AI-powered content generation
class AIService {
  static final AIService instance = AIService._init();
  AIService._init();

  // Premium features service for access control
  final _premiumService = PremiumFeaturesService.instance;

  // API keys - should be loaded from environment variables
  String? _githubToken; // GitHub Personal Access Token for GitHub Models
  String? _openaiApiKey;
  String? _geminiApiKey;
  String? _claudeApiKey;

  AIProvider _currentProvider = AIProvider.none;

  // Cache for AI responses
  final Map<String, _CachedResponse> _cache = {};
  static const int _cacheExpiryDays = 7; // ignore: unused_field - Reserved for cache cleanup logic

  // Provider health tracking
  final Map<AIProvider, _ProviderHealth> _providerHealth = {};
  bool _autoSelectEnabled = true; // Can be toggled by user

  // Getters
  AIProvider get currentProvider => _currentProvider;
  bool get isConfigured => _getApiKey() != null;
  bool get autoSelectEnabled => _autoSelectEnabled;
  // ignore: library_private_types_in_public_api
  Map<AIProvider, _ProviderHealth> get providerHealth => _providerHealth;

  /// Initialize AI service with API keys
  Future<void> initialize({AIProvider? defaultProvider}) async {
    await dotenv.load();

    // GitHub token can be used for all GitHub Models
    _githubToken = dotenv.env['GITHUB_PAT_KEY'] ?? ''; // Reusing OPENAI_AI_KEY for GitHub PAT
    _openaiApiKey = dotenv.env['OPENAI_DIRECT_KEY'] ?? ''; // Separate key for direct OpenAI
    _geminiApiKey = dotenv.env['GEMINI_AI_KEY'] ?? '';
    _claudeApiKey = dotenv.env['CLAUDE_AI_KEY'] ?? '';

    // Initialize health tracking for all providers
    _initializeProviderHealth();

    if (defaultProvider != null) {
      _currentProvider = defaultProvider;
      _autoSelectEnabled = false;
    } else if (_autoSelectEnabled) {
      // Auto-select best available provider
      _currentProvider = _selectBestProvider();
    } else {
      // Fallback to first available provider (prefer free GitHub Models)
      if (_githubToken != null && _githubToken!.isNotEmpty) {
        _currentProvider = AIProvider.githubGpt4o; // Default to GPT-4o-mini (free)
      } else if (_openaiApiKey != null && _openaiApiKey!.isNotEmpty) {
        _currentProvider = AIProvider.openai;
      } else if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
        _currentProvider = AIProvider.gemini;
      } else if (_claudeApiKey != null && _claudeApiKey!.isNotEmpty) {
        _currentProvider = AIProvider.claude;
      } else {
        _currentProvider = AIProvider.none;
      }
    }

    // Load cache from persistent storage
    await _loadCacheFromStorage();

    log('🤖 AI Service initialized with provider: $_currentProvider');
    log('💾 Loaded ${_cache.length} cached responses');
    log('🎯 Auto-selection: ${_autoSelectEnabled ? "enabled" : "disabled"}');
  }

  /// Initialize health tracking for all providers
  void _initializeProviderHealth() {
    for (final provider in AIProvider.values) {
      if (provider != AIProvider.none) {
        _providerHealth[provider] = _ProviderHealth();
      }
    }
  }

  /// Select best provider based on health scores
  AIProvider _selectBestProvider() {
    final availableProviders = <AIProvider>[];

    // GitHub Models (Free) - prioritize these
    if (_githubToken != null && _githubToken!.isNotEmpty) {
      availableProviders.add(AIProvider.githubGpt4o);
      availableProviders.add(AIProvider.githubDeepseek);
      availableProviders.add(AIProvider.githubLlama);
      availableProviders.add(AIProvider.githubGrok);
    }

    // Paid APIs
    if (_openaiApiKey != null && _openaiApiKey!.isNotEmpty) {
      availableProviders.add(AIProvider.openai);
    }
    if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
      availableProviders.add(AIProvider.gemini);
    }
    if (_claudeApiKey != null && _claudeApiKey!.isNotEmpty) {
      availableProviders.add(AIProvider.claude);
    }

    if (availableProviders.isEmpty) {
      return AIProvider.none;
    }

    // If no health data yet, prefer free GitHub Models
    if (_providerHealth.values.every((h) => h.successCount == 0 && h.errorCount == 0)) {
      // Prefer GPT-4o-mini (most capable free model)
      if (availableProviders.contains(AIProvider.githubGpt4o)) return AIProvider.githubGpt4o;
      if (availableProviders.contains(AIProvider.githubDeepseek)) return AIProvider.githubDeepseek;
      if (availableProviders.contains(AIProvider.githubLlama)) return AIProvider.githubLlama;
      if (availableProviders.contains(AIProvider.githubGrok)) return AIProvider.githubGrok;
      if (availableProviders.contains(AIProvider.gemini)) return AIProvider.gemini;
      if (availableProviders.contains(AIProvider.openai)) return AIProvider.openai;
      if (availableProviders.contains(AIProvider.claude)) return AIProvider.claude;
    }

    // Select provider with best health score
    AIProvider? bestProvider;
    double bestScore = -1;

    for (final provider in availableProviders) {
      final health = _providerHealth[provider];
      if (health != null && health.isHealthy) {
        final score = health.healthScore;
        if (score > bestScore) {
          bestScore = score;
          bestProvider = provider;
        }
      }
    }

    // If no healthy provider found, use first available
    return bestProvider ?? availableProviders.first;
  }

  /// Enable or disable auto-selection
  void setAutoSelection(bool enabled) {
    _autoSelectEnabled = enabled;
    if (enabled) {
      final newProvider = _selectBestProvider();
      if (newProvider != _currentProvider) {
        _currentProvider = newProvider;
        log('🔄 Auto-switched to provider: $newProvider');
      }
    }
  }

  /// Manually reset provider health stats
  void resetProviderHealth(AIProvider provider) {
    _providerHealth[provider]?.reset();
    log('🔄 Reset health stats for: $provider');
  }

  /// Reset all provider health stats
  void resetAllProviderHealth() {
    for (final health in _providerHealth.values) {
      health.reset();
    }
    log('🔄 Reset all provider health stats');
  }

  /// Set active AI provider
  void setProvider(AIProvider provider) {
    _currentProvider = provider;
    log('🤖 AI provider changed to: $provider');
  }

  /// Get API key for current provider
  String? _getApiKey() {
    switch (_currentProvider) {
      case AIProvider.githubGpt4o:
      case AIProvider.githubDeepseek:
      case AIProvider.githubLlama:
      case AIProvider.githubGrok:
        return _githubToken;
      case AIProvider.openai:
        return _openaiApiKey;
      case AIProvider.gemini:
        return _geminiApiKey;
      case AIProvider.claude:
        return _claudeApiKey;
      case AIProvider.none:
        return null;
    }
  }

  String _getCacheKey(String prompt) {
    return prompt.hashCode.toString();
  }

  Future<String?> _getFromCache(String prompt) async {
    final key = _getCacheKey(prompt);
    final cached = _cache[key];

    if (cached != null && !cached.isExpired) {
      log('💾 Using cached AI response');
      return cached.response;
    }

    return null;
  }

  Future<void> _saveToCache(String prompt, String response) async {
    final key = _getCacheKey(prompt);
    _cache[key] = _CachedResponse(response, DateTime.now());

    // Persist to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ai_cache_$key',
      jsonEncode({
        'response': response,
        'cachedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// Generate article summary using AI
  /// Premium feature: Free tier has daily limits
  Future<String> generateSummary(ArticleModel article) async {
    // Check if user can use AI (premium check)
    final canUseAI = await _premiumService.canUseAI();
    if (!canUseAI) {
      log('⚠️ AI request limit reached for free tier');
      return _extractSimpleSummary(article);
    }

    if (_currentProvider == AIProvider.none || !isConfigured) {
      // Fallback to simple extraction
      return _extractSimpleSummary(article);
    }

    try {
      final prompt =
          '''
        Summarize this news article in 2-3 concise sentences. Focus on the key facts and main points.

        Title: ${article.title}
        Content: ${article.description}

        Summary:''';

      final response = await _callAI(prompt, maxTokens: 150);

      // Track AI usage for free tier limits
      await _premiumService.trackAiUsage();

      return response.trim();
    } catch (e) {
      log('⚠️ Error generating summary with AI: $e');
      return _extractSimpleSummary(article);
    }
  }

  /// Analyze article with custom AI prompts
  /// Supports various analysis types: bias detection, fact-checking, tone analysis, etc.
  /// Premium feature: Free tier has daily limits
  Future<Map<String, dynamic>> analyzeArticle({
    required ArticleModel article,
    required String analysisType,
    String? customPrompt,
    int maxTokens = 300,
    bool returnJson = false,
  }) async {
    // Check if user can use AI (premium check)
    final canUseAI = await _premiumService.canUseAI();
    if (!canUseAI) {
      log('⚠️ AI request limit reached for free tier');
      return {
        'success': false,
        'error': 'AI usage limit reached. Please upgrade to premium.',
      };
    }

    if (_currentProvider == AIProvider.none || !isConfigured) {
      return {
        'success': false,
        'error': 'AI service not configured',
      };
    }

    try {
      // Build prompt based on analysis type or use custom prompt
      final String prompt = customPrompt ?? _buildAnalysisPrompt(article, analysisType);

      // Add JSON format request if needed
      final String finalPrompt = returnJson
          ? '$prompt\n\nRespond ONLY with valid JSON format.'
          : prompt;

      // Check cache first
      final cacheKey = _getCacheKey('analyze_${analysisType}_${article.title}');
      if (_cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
        log('✅ Returning cached analysis for: $analysisType');
        final cachedResponse = _cache[cacheKey]!.response;

        if (returnJson) {
          try {
            return {
              'success': true,
              'data': jsonDecode(cachedResponse),
              'cached': true,
            };
          } catch (e) {
            log('⚠️ Error parsing cached JSON: $e');
          }
        }

        return {
          'success': true,
          'result': cachedResponse,
          'cached': true,
        };
      }

      // Call AI
      final response = await _callAI(finalPrompt, maxTokens: maxTokens);

      // Track AI usage
      await _premiumService.trackAiUsage();

      // Cache the response
      await _saveToCache('analyze_${analysisType}_${article.title}', response);

      // Parse JSON if requested
      if (returnJson) {
        try {
          // Clean the response to extract JSON
          String cleanedResponse = response.trim();

          // Remove markdown code blocks if present
          if (cleanedResponse.startsWith('```')) {
            cleanedResponse = cleanedResponse
                .replaceFirst(RegExp(r'^```(json)?\n?'), '')
                .replaceFirst(RegExp(r'\n?```$'), '');
          }

          final parsedData = jsonDecode(cleanedResponse);
          return {
            'success': true,
            'data': parsedData,
            'cached': false,
          };
        } catch (e) {
          log('⚠️ Error parsing JSON response: $e');
          return {
            'success': false,
            'error': 'Failed to parse AI response as JSON',
            'rawResponse': response,
          };
        }
      }

      return {
        'success': true,
        'result': response.trim(),
        'cached': false,
      };
    } catch (e) {
      log('⚠️ Error analyzing article: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Build analysis prompt based on analysis type
  String _buildAnalysisPrompt(ArticleModel article, String analysisType) {
    final articleContext = '''
Title: ${article.title}
Source: ${article.sourceName}
Content: ${article.description}
${'Full Text: ${article.content}'}
''';

    switch (analysisType.toLowerCase()) {
      case 'bias':
        return '''Analyze the political and editorial bias in this news article.

$articleContext

Provide analysis in the following JSON format:
{
  "bias_rating": "left|center-left|center|center-right|right|unknown",
  "confidence": "high|medium|low",
  "indicators": ["list of bias indicators found"],
  "summary": "brief explanation"
}''';

      case 'fact_check':
        return '''Analyze this article for factual claims and their verifiability.

$articleContext

Provide analysis in the following JSON format:
{
  "factual_claims": ["list of major factual claims"],
  "verifiable": "high|medium|low",
  "concerns": ["list of any concerns or unverified claims"],
  "summary": "brief assessment"
}''';

      case 'tone':
        return '''Analyze the tone and emotional framing of this article.

$articleContext

Provide analysis in the following JSON format:
{
  "tone": "neutral|positive|negative|mixed",
  "emotional_language": ["examples of emotional or loaded language"],
  "objectivity": "high|medium|low",
  "summary": "brief explanation"
}''';

      case 'key_points':
        return '''Extract the key points and main arguments from this article.

$articleContext

Provide analysis in the following JSON format:
{
  "main_topic": "primary subject",
  "key_points": ["3-5 main points"],
  "conclusion": "article's main conclusion or takeaway"
}''';

      case 'credibility':
        return '''Assess the credibility and quality of this news article.

$articleContext

Provide analysis in the following JSON format:
{
  "credibility_score": "high|medium|low",
  "strengths": ["credibility strengths"],
  "weaknesses": ["credibility concerns"],
  "sources_cited": "yes|no|unclear",
  "summary": "overall assessment"
}''';

      default:
        return '''Analyze this news article and provide insights.

$articleContext

Analysis:''';
    }
  }

  /// Load cache from persistent storage
  Future<void> _loadCacheFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('ai_cache_'));

      for (final key in keys) {
        final cacheData = prefs.getString(key);
        if (cacheData != null) {
          try {
            final json = jsonDecode(cacheData) as Map<String, dynamic>;
            final response = json['response'] as String;
            final cachedAt = DateTime.parse(json['cachedAt'] as String);

            final cacheKey = key.replaceFirst('ai_cache_', '');
            final cachedResponse = _CachedResponse(response, cachedAt);

            // Only load if not expired
            if (!cachedResponse.isExpired) {
              _cache[cacheKey] = cachedResponse;
            } else {
              // Remove expired cache entry
              await prefs.remove(key);
            }
          } catch (e) {
            log('⚠️ Error parsing cached response: $e');
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      log('⚠️ Error loading cache from storage: $e');
    }
  }

  /// Clear all cached AI responses
  Future<void> clearCache() async {
    _cache.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('ai_cache_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
    log('🗑️ AI cache cleared');
  }

  /// Get current cache size
  int getCacheSize() => _cache.length;

  /// Generate key points using AI
  /// Premium feature: Free tier has daily limits
  Future<List<String>> generateKeyPoints(
    ArticleModel article, {
    int count = 3,
  }) async {
    // Check premium access
    final canUseAI = await _premiumService.canUseAI();
    if (!canUseAI) {
      return _extractSimpleKeyPoints(article, count);
    }

    if (_currentProvider == AIProvider.none || !isConfigured) {
      return _extractSimpleKeyPoints(article, count);
    }

    try {
      final prompt =
          '''
            Extract $count key points from this news article. Each point should be one sentence.

            Title: ${article.title}
            Content: ${article.description}

            Format as numbered list:''';

      final response = await _callAI(prompt, maxTokens: 200);

      // Track usage
      await _premiumService.trackAiUsage();

      // Parse numbered list
      final points = response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.replaceFirst(RegExp(r'^\d+\.?\s*'), '').trim())
          .where((line) => line.isNotEmpty)
          .take(count)
          .toList();

      return points.isNotEmpty
          ? points
          : _extractSimpleKeyPoints(article, count);
    } catch (e) {
      log('⚠️ Error generating key points with AI: $e');
      return _extractSimpleKeyPoints(article, count);
    }
  }

  /// Generate "why it matters" explanation using AI
  Future<String> generateWhyItMatters(ArticleModel article) async {
    if (_currentProvider == AIProvider.none || !isConfigured) {
      return _generateSimpleWhyItMatters(article);
    }

    try {
      final prompt =
          '''
        Explain in 1-2 sentences why this news story matters to readers. Focus on impact and significance.

        Title: ${article.title}
        Content: ${article.description}

        Why it matters:''';

      final response = await _callAI(prompt, maxTokens: 100);
      return response.trim();
    } catch (e) {
      log('⚠️ Error generating "why it matters" with AI: $e');
      return _generateSimpleWhyItMatters(article);
    }
  }

  /// Generate digest title using AI
  Future<String> generateDigestTitle(
    List<ArticleModel> articles,
    String timeOfDay,
  ) async {
    if (_currentProvider == AIProvider.none || !isConfigured) {
      return _generateSimpleDigestTitle(timeOfDay);
    }

    try {
      final topicsPreview = articles.take(3).map((a) => a.title).join('; ');

      final prompt =
          '''
        Create a catchy, concise title for a news digest. The title should be engaging and reference the time of day.

        Time: $timeOfDay
        Top stories: $topicsPreview

        Title:''';

      final response = await _callAI(prompt, maxTokens: 50);
      return response.trim();
    } catch (e) {
      log('⚠️ Error generating digest title with AI: $e');
      return _generateSimpleDigestTitle(timeOfDay);
    }
  }

  /// Call AI provider with health tracking and failover
  Future<String> _callAI(String prompt, {int maxTokens = 200}) async {
    // Check cache first
    final cached = await _getFromCache(prompt);
    if (cached != null) return cached;

    // Try current provider first
    final startTime = DateTime.now();

    try {
      final response = await _callProviderWithTracking(_currentProvider, prompt, maxTokens, startTime);

      // Save to cache
      await _saveToCache(prompt, response);

      return response;
    } catch (e) {
      log('⚠️ Error with provider $_currentProvider: $e');

      // If auto-selection is enabled, try failover to another provider
      if (_autoSelectEnabled) {
        return await _attemptFailover(prompt, maxTokens);
      }

      rethrow;
    }
  }

  /// Call provider with health tracking
  Future<String> _callProviderWithTracking(
    AIProvider provider,
    String prompt,
    int maxTokens,
    DateTime startTime,
  ) async {
    try {
      String response;

      switch (provider) {
        case AIProvider.githubGpt4o:
          response = await _callGitHubModel(prompt, maxTokens, 'gpt-4o-mini');
          break;
        case AIProvider.githubDeepseek:
          response = await _callGitHubModel(prompt, maxTokens, 'deepseek-coder');
          break;
        case AIProvider.githubLlama:
          response = await _callGitHubModel(prompt, maxTokens, 'meta-llama-3.1-8b-instruct');
          break;
        case AIProvider.githubGrok:
          response = await _callGitHubModel(prompt, maxTokens, 'grok-beta');
          break;
        case AIProvider.openai:
          response = await _callOpenAI(prompt, maxTokens);
          break;
        case AIProvider.gemini:
          response = await _callGemini(prompt, maxTokens);
          break;
        case AIProvider.claude:
          response = await _callClaude(prompt, maxTokens);
          break;
        case AIProvider.none:
          throw Exception('No AI provider configured');
      }

      // Record success
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      _providerHealth[provider]?.recordSuccess(responseTime);

      log('✅ Provider $provider responded in ${responseTime}ms');

      return response;
    } catch (e) {
      // Record error
      _providerHealth[provider]?.recordError(e.toString());
      rethrow;
    }
  }

  /// Attempt failover to alternative provider
  Future<String> _attemptFailover(String prompt, int maxTokens) async {
    log('🔄 Attempting failover to alternative provider...');

    final alternativeProvider = _selectBestProvider();

    if (alternativeProvider == _currentProvider || alternativeProvider == AIProvider.none) {
      log('❌ No alternative provider available');
      throw Exception('All AI providers failed');
    }

    log('🔄 Failing over to: $alternativeProvider');
    final previousProvider = _currentProvider;
    _currentProvider = alternativeProvider;

    try {
      final startTime = DateTime.now();
      final response = await _callProviderWithTracking(alternativeProvider, prompt, maxTokens, startTime);

      // Save to cache
      await _saveToCache(prompt, response);

      log('✅ Failover successful to $alternativeProvider');
      return response;
    } catch (e) {
      log('❌ Failover failed: $e');
      _currentProvider = previousProvider; // Restore previous provider
      rethrow;
    }
  }

  /// Call GitHub Models API (Free)
  Future<String> _callGitHubModel(String prompt, int maxTokens, String modelName) async {
    final token = _githubToken;
    if (token == null || token.isEmpty) {
      throw Exception('GitHub token not configured');
    }

    final url = Uri.parse('https://models.inference.ai.azure.com/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'model': modelName,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': maxTokens,
      'temperature': 0.7,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub Models API error: ${response.statusCode} - ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  /// Call OpenAI API
  Future<String> _callOpenAI(String prompt, int maxTokens) async {
    final apiKey = _openaiApiKey;
    if (apiKey == null) throw Exception('OpenAI API key not configured');

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-4o-mini', // Cost-effective model
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': maxTokens,
      'temperature': 0.7,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI API error: ${response.statusCode} - ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  /// Call Google Gemini API
  Future<String> _callGemini(String prompt, int maxTokens) async {
    final apiKey = _geminiApiKey;
    if (apiKey == null) throw Exception('Gemini API key not configured');

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {'maxOutputTokens': maxTokens, 'temperature': 0.7},
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error: ${response.statusCode} - ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  /// Call Anthropic Claude API
  Future<String> _callClaude(String prompt, int maxTokens) async {
    final apiKey = _claudeApiKey;
    if (apiKey == null) throw Exception('Claude API key not configured');

    final url = Uri.parse('https://api.anthropic.com/v1/messages');
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    };

    final body = jsonEncode({
      'model': 'claude-3-5-haiku-20241022', // Cost-effective model
      'max_tokens': maxTokens,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception(
        'Claude API error: ${response.statusCode} - ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    return data['content'][0]['text'] as String;
  }

  // Fallback methods (algorithm-based)

  String _extractSimpleSummary(ArticleModel article) {
    // Simple extraction from description
    final sentences = article.description.split(RegExp(r'[.!?]\s+'));
    return '${sentences.take(2).join('. ')}.';
  }

  List<String> _extractSimpleKeyPoints(ArticleModel article, int count) {
    final sentences = article.description.split(RegExp(r'[.!?]\s+'));
    return sentences
        .where((s) => s.trim().isNotEmpty)
        .take(count)
        .map((s) => s.trim())
        .toList();
  }

  String _generateSimpleWhyItMatters(ArticleModel article) {
    final category = article.category.isNotEmpty
        ? article.category.first
        : 'this topic';
    return 'This story provides important updates on $category that may affect current events and public discourse.';
  }

  String _generateSimpleDigestTitle(String timeOfDay) {
    final greetings = {
      'morning': 'Your Morning Briefing',
      'afternoon': 'Afternoon News Update',
      'evening': 'Evening News Digest',
    };
    return greetings[timeOfDay.toLowerCase()] ?? 'Your Daily News Digest';
  }

  /// Get cost estimate for digest generation
  double estimateCost(int articleCount) {
    switch (_currentProvider) {
      case AIProvider.githubGpt4o:
      case AIProvider.githubDeepseek:
      case AIProvider.githubLlama:
      case AIProvider.githubGrok:
        // GitHub Models: FREE (no cost!)
        return 0.0;
      case AIProvider.openai:
        // GPT-4o-mini: ~$0.00015 per 1K input tokens, ~$0.0006 per 1K output tokens
        // Estimate: ~500 input + 200 output tokens per article
        return articleCount * 0.0003; // ~$0.0003 per article
      case AIProvider.gemini:
        // Gemini 1.5 Flash: Free tier available, then ~$0.000125 per 1K tokens
        return articleCount * 0.0001;
      case AIProvider.claude:
        // Claude 3.5 Haiku: ~$0.00025 per 1K input, ~$0.00125 per 1K output
        return articleCount * 0.0004;
      case AIProvider.none:
        return 0.0;
    }
  }
}

class _CachedResponse {
  final String response;
  final DateTime cachedAt;

  _CachedResponse(this.response, this.cachedAt);

  bool get isExpired {
    return DateTime.now().difference(cachedAt).inDays > 7;
  }
}

/// Provider health tracking
class _ProviderHealth {
  int successCount = 0;
  int errorCount = 0;
  double totalResponseTimeMs = 0;
  DateTime? lastError;
  String? lastErrorMessage;

  double get successRate {
    final total = successCount + errorCount;
    return total > 0 ? successCount / total : 0.0;
  }

  double get averageResponseTimeMs {
    return successCount > 0 ? totalResponseTimeMs / successCount : 0.0;
  }

  double get healthScore {
    // Calculate health score: 70% success rate + 30% response time factor
    final successWeight = successRate * 0.7;

    // Response time factor: faster is better (normalize to 0-1 scale)
    // Assume 5000ms is very slow (0 score), 500ms is fast (1 score)
    final responseTimeFactor = averageResponseTimeMs > 0
        ? (1 - (averageResponseTimeMs / 5000).clamp(0, 1)) * 0.3
        : 0.0;

    return successWeight + responseTimeFactor;
  }

  bool get isHealthy {
    // Consider healthy if success rate > 70% and no recent errors (within 5 minutes)
    if (successRate < 0.7) return false;

    if (lastError != null) {
      final timeSinceError = DateTime.now().difference(lastError!);
      if (timeSinceError.inMinutes < 5) return false;
    }

    return true;
  }

  void recordSuccess(int responseTimeMs) {
    successCount++;
    totalResponseTimeMs += responseTimeMs;
  }

  void recordError(String error) {
    errorCount++;
    lastError = DateTime.now();
    lastErrorMessage = error;
  }

  void reset() {
    successCount = 0;
    errorCount = 0;
    totalResponseTimeMs = 0;
    lastError = null;
    lastErrorMessage = null;
  }
}
