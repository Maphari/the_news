import 'dart:developer';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/ai_service.dart';

/// Service for advanced AI analysis of news articles
/// Provides fact-checking, bias detection, sentiment analysis, and claim extraction
class AIAnalysisService {
  static final instance = AIAnalysisService._init();
  AIAnalysisService._init();

  final AIService _aiService = AIService.instance;
  final Map<String, ArticleAnalysis> _analysisCache = {};

  /// Analyze an article for fact-checking, bias, sentiment, and key claims
  Future<ArticleAnalysis> analyzeArticle(ArticleModel article) async {
    // Check cache first
    if (_analysisCache.containsKey(article.articleId)) {
      return _analysisCache[article.articleId]!;
    }

    if (!_aiService.isConfigured) {
      return _fallbackAnalysis(article);
    }

    try {
      // Use the dedicated analyzeArticle method with custom comprehensive analysis prompt
      final customPrompt = '''
Analyze this news article comprehensively and provide a detailed analysis in JSON format.

Title: ${article.title}
Source: ${article.sourceName}
Content: ${article.description}
${article.content.isNotEmpty ? 'Full Text: ${article.content}' : ''}

Provide analysis in the following JSON format:
{
  "factCheckRating": <number 1-5, where 5 is highly credible>,
  "factCheckExplanation": "explanation of credibility assessment",
  "sentiment": "positive|neutral|negative",
  "sentimentScore": <number -1.0 to 1.0>,
  "biasDirection": "left|center-left|center|center-right|right",
  "biasStrength": "strong|moderate|weak|none",
  "keyClaims": ["list of 3-5 key factual claims"],
  "credibilitySignals": ["positive signals about credibility"],
  "redFlags": ["concerns or warning signs if any"]
}''';

      final result = await _aiService.analyzeArticle(
        article: article,
        analysisType: 'comprehensive',
        customPrompt: customPrompt,
        maxTokens: 500,
        returnJson: true,
      );

      if (result['success'] == true && result['data'] != null) {
        final analysisData = result['data'] as Map<String, dynamic>;

        final analysis = ArticleAnalysis(
          articleId: article.articleId,
          factCheckRating: analysisData['factCheckRating'] ?? 3,
          factCheckExplanation: analysisData['factCheckExplanation'] ?? 'No explanation available',
          sentiment: analysisData['sentiment'] ?? 'neutral',
          sentimentScore: (analysisData['sentimentScore'] ?? 0.0).toDouble(),
          biasDirection: analysisData['biasDirection'] ?? 'center',
          biasStrength: analysisData['biasStrength'] ?? 'weak',
          keyClaims: List<String>.from(analysisData['keyClaims'] ?? []),
          credibilitySignals: List<String>.from(analysisData['credibilitySignals'] ?? []),
          redFlags: List<String>.from(analysisData['redFlags'] ?? []),
          analyzedAt: DateTime.now(),
        );

        _analysisCache[article.articleId] = analysis;
        return analysis;
      } else {
        // If AI analysis failed, use fallback
        log('⚠️ AI analysis returned error: ${result['error']}');
        return _fallbackAnalysis(article);
      }
    } catch (e) {
      log('⚠️ AI analysis failed: $e');
      return _fallbackAnalysis(article);
    }
  }

  /// Fallback analysis when AI is not configured
  ArticleAnalysis _fallbackAnalysis(ArticleModel article) {
    return ArticleAnalysis(
      articleId: article.articleId,
      factCheckRating: 3,
      factCheckExplanation: 'AI analysis not available. Enable AI in settings for detailed fact-checking.',
      sentiment: article.sentiment,
      sentimentScore: 0.0,
      biasDirection: 'center',
      biasStrength: 'weak',
      keyClaims: ['Enable AI analysis to see key claims'],
      credibilitySignals: ['Source: ${article.sourceName}'],
      redFlags: [],
      analyzedAt: DateTime.now(),
    );
  }

  /// Clear analysis cache
  void clearCache() {
    _analysisCache.clear();
  }

  /// Get cached analysis if available
  ArticleAnalysis? getCachedAnalysis(String articleId) {
    return _analysisCache[articleId];
  }
}

/// Model for article analysis results
class ArticleAnalysis {
  final String articleId;
  final int factCheckRating; // 1-5
  final String factCheckExplanation;
  final String sentiment; // positive, negative, neutral
  final double sentimentScore; // -1.0 to 1.0
  final String biasDirection; // left, center, right
  final String biasStrength; // weak, moderate, strong
  final List<String> keyClaims;
  final List<String> credibilitySignals;
  final List<String> redFlags;
  final DateTime analyzedAt;

  const ArticleAnalysis({
    required this.articleId,
    required this.factCheckRating,
    required this.factCheckExplanation,
    required this.sentiment,
    required this.sentimentScore,
    required this.biasDirection,
    required this.biasStrength,
    required this.keyClaims,
    required this.credibilitySignals,
    required this.redFlags,
    required this.analyzedAt,
  });

  /// Get color for fact-check rating
  String get ratingColor {
    if (factCheckRating >= 4) return 'green';
    if (factCheckRating >= 3) return 'yellow';
    return 'red';
  }

  /// Get bias color
  String get biasColor {
    if (biasDirection == 'left') return 'blue';
    if (biasDirection == 'right') return 'red';
    return 'gray';
  }

  /// Check if article has red flags
  bool get hasRedFlags => redFlags.isNotEmpty;

  /// Get overall credibility score (0-100)
  int get credibilityScore {
    int score = factCheckRating * 20; // Base score from rating

    // Adjust for red flags
    score -= redFlags.length * 10;

    // Adjust for credibility signals
    score += credibilitySignals.length * 5;

    return score.clamp(0, 100);
  }
}
