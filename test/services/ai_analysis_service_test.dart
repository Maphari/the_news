import 'package:flutter_test/flutter_test.dart';
import 'package:the_news/service/ai_analysis_service.dart';
import 'package:the_news/model/news_article_model.dart';

void main() {
  group('AIAnalysisService', () {
    late AIAnalysisService analysisService;

    setUp(() {
      analysisService = AIAnalysisService.instance;
    });

    test('should return fallback analysis when AI is not configured', () async {
      final mockArticle = _createMockArticle();

      final analysis = await analysisService.analyzeArticle(mockArticle);

      expect(analysis.articleId, mockArticle.articleId);
      expect(analysis.factCheckRating, 3); // Default fallback rating
      expect(analysis.sentiment, mockArticle.sentiment);
      expect(analysis.biasDirection, 'center');
    });

    test('should cache analysis results', () async {
      final mockArticle = _createMockArticle();

      // First call - generates analysis
      final analysis1 = await analysisService.analyzeArticle(mockArticle);

      // Second call - should return cached
      final analysis2 = await analysisService.analyzeArticle(mockArticle);

      expect(analysis1.articleId, analysis2.articleId);
      expect(analysis1.analyzedAt, analysis2.analyzedAt); // Same timestamp = cached
    });

    test('should clear cache', () {
      analysisService.clearCache();

      final mockArticle = _createMockArticle();
      final cached = analysisService.getCachedAnalysis(mockArticle.articleId);

      expect(cached, null);
    });

    test('should retrieve cached analysis', () async {
      final mockArticle = _createMockArticle();

      await analysisService.analyzeArticle(mockArticle);
      final cached = analysisService.getCachedAnalysis(mockArticle.articleId);

      expect(cached, isNotNull);
      expect(cached!.articleId, mockArticle.articleId);
    });
  });

  group('ArticleAnalysis', () {
    test('should calculate credibility score correctly', () {
      final analysis = ArticleAnalysis(
        articleId: 'test-1',
        factCheckRating: 5,
        factCheckExplanation: 'Test',
        sentiment: 'neutral',
        sentimentScore: 0.0,
        biasDirection: 'center',
        biasStrength: 'weak',
        keyClaims: ['Claim 1', 'Claim 2'],
        credibilitySignals: ['Signal 1', 'Signal 2'],
        redFlags: [],
        analyzedAt: DateTime.now(),
      );

      // 5 * 20 (base) + 2 * 5 (signals) = 110, clamped to 100
      expect(analysis.credibilityScore, 100);
    });

    test('should reduce score for red flags', () {
      final analysis = ArticleAnalysis(
        articleId: 'test-1',
        factCheckRating: 4,
        factCheckExplanation: 'Test',
        sentiment: 'neutral',
        sentimentScore: 0.0,
        biasDirection: 'center',
        biasStrength: 'weak',
        keyClaims: [],
        credibilitySignals: [],
        redFlags: ['Flag 1', 'Flag 2'],
        analyzedAt: DateTime.now(),
      );

      // 4 * 20 - 2 * 10 = 60
      expect(analysis.credibilityScore, 60);
    });

    test('should identify articles with red flags', () {
      final analysisWithFlags = ArticleAnalysis(
        articleId: 'test-1',
        factCheckRating: 3,
        factCheckExplanation: 'Test',
        sentiment: 'neutral',
        sentimentScore: 0.0,
        biasDirection: 'center',
        biasStrength: 'weak',
        keyClaims: [],
        credibilitySignals: [],
        redFlags: ['Flag 1'],
        analyzedAt: DateTime.now(),
      );

      final analysisWithoutFlags = ArticleAnalysis(
        articleId: 'test-2',
        factCheckRating: 3,
        factCheckExplanation: 'Test',
        sentiment: 'neutral',
        sentimentScore: 0.0,
        biasDirection: 'center',
        biasStrength: 'weak',
        keyClaims: [],
        credibilitySignals: [],
        redFlags: [],
        analyzedAt: DateTime.now(),
      );

      expect(analysisWithFlags.hasRedFlags, true);
      expect(analysisWithoutFlags.hasRedFlags, false);
    });

    test('should return correct rating color', () {
      final highRating = ArticleAnalysis(
        articleId: 'test-1',
        factCheckRating: 5,
        factCheckExplanation: 'Test',
        sentiment: 'neutral',
        sentimentScore: 0.0,
        biasDirection: 'center',
        biasStrength: 'weak',
        keyClaims: [],
        credibilitySignals: [],
        redFlags: [],
        analyzedAt: DateTime.now(),
      );

      final mediumRating = ArticleAnalysis(
        articleId: 'test-2',
        factCheckRating: 3,
        factCheckExplanation: 'Test',
        sentiment: 'neutral',
        sentimentScore: 0.0,
        biasDirection: 'center',
        biasStrength: 'weak',
        keyClaims: [],
        credibilitySignals: [],
        redFlags: [],
        analyzedAt: DateTime.now(),
      );

      final lowRating = ArticleAnalysis(
        articleId: 'test-3',
        factCheckRating: 1,
        factCheckExplanation: 'Test',
        sentiment: 'neutral',
        sentimentScore: 0.0,
        biasDirection: 'center',
        biasStrength: 'weak',
        keyClaims: [],
        credibilitySignals: [],
        redFlags: [],
        analyzedAt: DateTime.now(),
      );

      expect(highRating.ratingColor, 'green');
      expect(mediumRating.ratingColor, 'yellow');
      expect(lowRating.ratingColor, 'red');
    });

    test('should return correct bias color', () {
      final leftBias = ArticleAnalysis(
        articleId: 'test-1',
        factCheckRating: 3,
        factCheckExplanation: 'Test',
        sentiment: 'neutral',
        sentimentScore: 0.0,
        biasDirection: 'left',
        biasStrength: 'weak',
        keyClaims: [],
        credibilitySignals: [],
        redFlags: [],
        analyzedAt: DateTime.now(),
      );

      final rightBias = ArticleAnalysis(
        articleId: 'test-2',
        factCheckRating: 3,
        factCheckExplanation: 'Test',
        sentiment: 'neutral',
        sentimentScore: 0.0,
        biasDirection: 'right',
        biasStrength: 'weak',
        keyClaims: [],
        credibilitySignals: [],
        redFlags: [],
        analyzedAt: DateTime.now(),
      );

      final centerBias = ArticleAnalysis(
        articleId: 'test-3',
        factCheckRating: 3,
        factCheckExplanation: 'Test',
        sentiment: 'neutral',
        sentimentScore: 0.0,
        biasDirection: 'center',
        biasStrength: 'weak',
        keyClaims: [],
        credibilitySignals: [],
        redFlags: [],
        analyzedAt: DateTime.now(),
      );

      expect(leftBias.biasColor, 'blue');
      expect(rightBias.biasColor, 'red');
      expect(centerBias.biasColor, 'gray');
    });
  });
}

ArticleModel _createMockArticle() {
  return ArticleModel(
    articleId: 'test-article-1',
    link: 'https://example.com/article',
    title: 'Test Article',
    description: 'Test description',
    content: 'Test content',
    keywords: ['test', 'article'],
    creator: ['Test Author'],
    language: 'en',
    country: ['us'],
    category: ['technology'],
    datatype: 'article',
    pubDate: DateTime.now(),
    pubDateTZ: 'UTC',
    imageUrl: null,
    videoUrl: null,
    sourceId: 'test-source',
    sourceName: 'Test Source',
    sourcePriority: 1,
    sourceUrl: 'https://example.com',
    sourceIcon: 'https://example.com/icon.png',
    sentiment: 'neutral',
    sentimentStats: SentimentStats(
      positive: 0.3,
      negative: 0.2,
      neutral: 0.5,
    ),
    aiTag: [],
    aiRegion: [],
    aiOrg: null,
    aiSummary: 'Test summary',
    duplicate: false,
  );
}
