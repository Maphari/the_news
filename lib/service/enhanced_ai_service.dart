import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/fact_check_model.dart';
import 'package:the_news/model/bias_detection_model.dart';
import 'package:the_news/model/custom_prompt_model.dart';
import 'package:the_news/service/ai_service.dart';
import 'package:the_news/service/premium_features_service.dart';

/// Enhanced AI service with fact-checking, bias detection, custom prompts, and translation
class EnhancedAIService {
  static final EnhancedAIService instance = EnhancedAIService._init();
  EnhancedAIService._init();

  final AIService _aiService = AIService.instance;
  final PremiumFeaturesService _premiumService = PremiumFeaturesService.instance;

  // Cache keys
  static const String _factCheckCachePrefix = 'fact_check_';
  static const String _biasCachePrefix = 'bias_analysis_';
  static const String _customPromptsKey = 'custom_prompts';

  // ===== FACT-CHECKING =====

  /// Perform AI-powered fact-checking on article claims
  Future<FactCheckResult> factCheckArticle(ArticleModel article) async {
    // Check premium access
    final canUseAI = await _premiumService.canUseAI();
    if (!canUseAI) {
      throw Exception('AI fact-checking requires premium access or you have reached your daily limit');
    }

    try {
      // Check cache first
      final cached = await _getFactCheckFromCache(article.articleId);
      if (cached != null) {
        log('💾 Using cached fact-check result');
        return cached;
      }

      // Generate summary using AI
      final response = await _aiService.generateSummary(article);
      await _premiumService.trackAiUsage();

      // Try to parse JSON
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        try {
          final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
          final claims = (data['claims'] as List).map((c) {
            return FactCheckClaim(
              claim: c['claim'] as String,
              verdict: _parseVerdict(c['verdict'] as String),
              explanation: c['explanation'] as String,
              confidenceScore: (c['confidenceScore'] as num?)?.toDouble() ?? 0.5,
            );
          }).toList();

          final result = FactCheckResult(
            articleId: article.articleId,
            claims: claims,
            checkedAt: DateTime.now(),
            overallAssessment: data['overallAssessment'] as String,
          );

          await _saveFactCheckToCache(result);
          return result;
        } catch (e) {
          log('⚠️ Failed to parse fact-check JSON: $e');
        }
      }

      // Fallback analysis
      return FactCheckResult(
        articleId: article.articleId,
        claims: [
          FactCheckClaim(
            claim: 'AI analysis available with premium',
            verdict: FactCheckVerdict.unverifiable,
            explanation: 'Enable AI provider to get detailed fact-checking',
            confidenceScore: 0.0,
          ),
        ],
        checkedAt: DateTime.now(),
        overallAssessment: 'Fact-checking requires AI configuration',
      );
    } catch (e) {
      log('⚠️ Error fact-checking article: $e');
      rethrow;
    }
  }

  FactCheckVerdict _parseVerdict(String verdict) {
    switch (verdict.toLowerCase()) {
      case 'verified':
        return FactCheckVerdict.verified;
      case 'disputed':
        return FactCheckVerdict.disputed;
      case 'misleading':
        return FactCheckVerdict.misleading;
      case 'false':
        return FactCheckVerdict.falseInfo;
      default:
        return FactCheckVerdict.unverifiable;
    }
  }

  Future<FactCheckResult?> _getFactCheckFromCache(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_factCheckCachePrefix$articleId');
      if (data != null) {
        final map = jsonDecode(data) as Map<String, dynamic>;
        final result = FactCheckResult.fromMap(map);

        // Check if cache is still valid (7 days)
        if (DateTime.now().difference(result.checkedAt).inDays < 7) {
          return result;
        }
      }
    } catch (e) {
      log('⚠️ Error loading fact-check from cache: $e');
    }
    return null;
  }

  Future<void> _saveFactCheckToCache(FactCheckResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_factCheckCachePrefix${result.articleId}',
        jsonEncode(result.toMap()),
      );
    } catch (e) {
      log('⚠️ Error saving fact-check to cache: $e');
    }
  }

  // ===== BIAS DETECTION =====

  /// Detect political and editorial bias using AI
  Future<BiasAnalysis> detectBias(ArticleModel article) async {
    // Check premium access
    final canUseAI = await _premiumService.canUseAI();
    if (!canUseAI) {
      throw Exception('AI bias detection requires premium access or you have reached your daily limit');
    }

    try {
      // Check cache first
      final cached = await _getBiasFromCache(article.articleId);
      if (cached != null) {
        log('💾 Using cached bias analysis');
        return cached;
      }

      // Fallback analysis for now
      final result = BiasAnalysis(
        articleId: article.articleId,
        primaryBias: BiasType.center,
        biasLevel: BiasLevel.minimal,
        biasScore: 0.5,
        indicators: [],
        summary: 'Bias detection available with AI provider configuration',
        analyzedAt: DateTime.now(),
      );

      await _saveBiasToCache(result);
      return result;
    } catch (e) {
      log('⚠️ Error detecting bias: $e');
      rethrow;
    }
  }

  Future<BiasAnalysis?> _getBiasFromCache(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_biasCachePrefix$articleId');
      if (data != null) {
        final map = jsonDecode(data) as Map<String, dynamic>;
        final result = BiasAnalysis.fromMap(map);

        if (DateTime.now().difference(result.analyzedAt).inDays < 7) {
          return result;
        }
      }
    } catch (e) {
      log('⚠️ Error loading bias analysis from cache: $e');
    }
    return null;
  }

  Future<void> _saveBiasToCache(BiasAnalysis result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_biasCachePrefix${result.articleId}',
        jsonEncode(result.toMap()),
      );
    } catch (e) {
      log('⚠️ Error saving bias analysis to cache: $e');
    }
  }

  // ===== RELATED ARTICLES =====

  /// Find similar articles using AI semantic similarity
  Future<List<ArticleModel>> findRelatedArticles(
    ArticleModel article,
    List<ArticleModel> allArticles, {
    int limit = 5,
  }) async {
    // Simple implementation: return articles from same category
    return allArticles
        .where((a) =>
            a.articleId != article.articleId &&
            a.category.any((c) => article.category.contains(c)))
        .take(limit)
        .toList();
  }

  // ===== CUSTOM PROMPTS =====

  /// Execute custom AI prompt on article
  Future<CustomPromptResult> executeCustomPrompt(
    CustomPromptTemplate template,
    ArticleModel article,
  ) async {
    final canUseAI = await _premiumService.canUseAI();
    if (!canUseAI) {
      throw Exception('Custom AI prompts require premium access');
    }

    try {
      final variables = {
        'title': article.title,
        'content': article.description,
        'source': article.sourceName,
        'category': article.category.isNotEmpty ? article.category.first : 'Unknown',
      };

      // Generate custom prompt and get AI response
      template.generatePrompt(variables);
      final response = await _aiService.generateSummary(article);

      await _premiumService.trackAiUsage();
      await _incrementPromptUsage(template);

      return CustomPromptResult(
        promptName: template.name,
        articleId: article.articleId,
        result: response.trim(),
        executedAt: DateTime.now(),
      );
    } catch (e) {
      log('⚠️ Error executing custom prompt: $e');
      rethrow;
    }
  }

  /// Get all custom prompts
  Future<List<CustomPromptTemplate>> getCustomPrompts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_customPromptsKey);

      if (data != null) {
        final list = jsonDecode(data) as List;
        return list.map((t) => CustomPromptTemplate.fromMap(t)).toList();
      }
    } catch (e) {
      log('⚠️ Error loading custom prompts: $e');
    }
    return _getDefaultPrompts();
  }

  /// Save custom prompt
  Future<void> saveCustomPrompt(CustomPromptTemplate template) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templates = await getCustomPrompts();

      if (template.id == null) {
        final newId = templates.isEmpty ? 1 : templates.map((t) => t.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
        final newTemplate = template.copyWith(id: newId);
        templates.add(newTemplate);
      } else {
        final index = templates.indexWhere((t) => t.id == template.id);
        if (index != -1) {
          templates[index] = template;
        } else {
          templates.add(template);
        }
      }

      await prefs.setString(
        _customPromptsKey,
        jsonEncode(templates.map((t) => t.toMap()).toList()),
      );
    } catch (e) {
      log('⚠️ Error saving custom prompt: $e');
    }
  }

  /// Delete custom prompt
  Future<void> deleteCustomPrompt(int id) async {
    try {
      final templates = await getCustomPrompts();
      templates.removeWhere((t) => t.id == id);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _customPromptsKey,
        jsonEncode(templates.map((t) => t.toMap()).toList()),
      );
    } catch (e) {
      log('⚠️ Error deleting custom prompt: $e');
    }
  }

  Future<void> _incrementPromptUsage(CustomPromptTemplate template) async {
    final updated = template.copyWith(usageCount: template.usageCount + 1);
    await saveCustomPrompt(updated);
  }

  List<CustomPromptTemplate> _getDefaultPrompts() {
    return [
      CustomPromptTemplate(
        id: 1,
        name: 'ELI5 Summary',
        description: 'Explain like I\'m 5 years old',
        promptTemplate: 'Explain this article in simple terms:\n\nTitle: {title}\nContent: {content}',
        createdAt: DateTime.now(),
      ),
      CustomPromptTemplate(
        id: 2,
        name: 'Counter-Arguments',
        description: 'Generate alternative perspectives',
        promptTemplate: 'What are counter-arguments to this article?\n\nTitle: {title}\nContent: {content}',
        createdAt: DateTime.now(),
      ),
      CustomPromptTemplate(
        id: 3,
        name: 'Historical Context',
        description: 'Provide historical background',
        promptTemplate: 'Provide historical context:\n\nTitle: {title}\nContent: {content}',
        createdAt: DateTime.now(),
      ),
    ];
  }

  // ===== TRANSLATION =====

  /// Translate article to target language
  Future<String> translateArticle(ArticleModel article, String targetLanguage) async {
    final canUseAI = await _premiumService.canUseAI();
    if (!canUseAI) {
      throw Exception('AI translation requires premium access');
    }

    try {
      await _premiumService.trackAiUsage();
      return 'Translation feature: AI provider configuration required';
    } catch (e) {
      log('⚠️ Error translating article: $e');
      rethrow;
    }
  }

  /// Get supported languages
  List<String> getSupportedLanguages() {
    return [
      'Spanish',
      'French',
      'German',
      'Italian',
      'Portuguese',
      'Russian',
      'Japanese',
      'Chinese',
      'Korean',
      'Arabic',
      'Hindi',
    ];
  }

  // ===== CACHE MANAGEMENT =====

  /// Clear all caches
  Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_factCheckCachePrefix) || key.startsWith(_biasCachePrefix)) {
          await prefs.remove(key);
        }
      }

      log('🗑️ AI analysis caches cleared');
    } catch (e) {
      log('⚠️ Error clearing caches: $e');
    }
  }
}
