import 'package:flutter_test/flutter_test.dart';
import 'package:the_news/service/ai_service.dart';

void main() {
  group('AIService', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService.instance;
    });

    test('should initialize with no provider by default', () {
      expect(aiService.currentProvider, AIProvider.none);
      expect(aiService.isConfigured, false);
    });

    test('should set provider correctly', () {
      aiService.setProvider(AIProvider.githubGpt4o);
      expect(aiService.currentProvider, AIProvider.githubGpt4o);
    });

    test('should calculate cost for GitHub models correctly', () {
      aiService.setProvider(AIProvider.githubGpt4o);
      final cost = aiService.estimateCost(100);
      expect(cost, 0.0); // GitHub models are free
    });

    test('should calculate cost for OpenAI correctly', () {
      aiService.setProvider(AIProvider.openai);
      final cost = aiService.estimateCost(10);
      expect(cost, 0.003); // 10 * 0.0003
    });

    test('should calculate cost for Gemini correctly', () {
      aiService.setProvider(AIProvider.gemini);
      final cost = aiService.estimateCost(10);
      expect(cost, 0.001); // 10 * 0.0001
    });

    test('should calculate cost for Claude correctly', () {
      aiService.setProvider(AIProvider.claude);
      final cost = aiService.estimateCost(10);
      expect(cost, 0.004); // 10 * 0.0004
    });

    test('should return zero cost when no provider is configured', () {
      aiService.setProvider(AIProvider.none);
      final cost = aiService.estimateCost(10);
      expect(cost, 0.0);
    });

    test('should clear cache', () {
      aiService.clearCache();
      expect(aiService.getCacheSize(), 0);
    });
  });

  group('AIProvider', () {
    test('should have all expected providers', () {
      expect(AIProvider.values.length, 8);
      expect(AIProvider.values.contains(AIProvider.githubGpt4o), true);
      expect(AIProvider.values.contains(AIProvider.githubDeepseek), true);
      expect(AIProvider.values.contains(AIProvider.githubLlama), true);
      expect(AIProvider.values.contains(AIProvider.githubGrok), true);
      expect(AIProvider.values.contains(AIProvider.openai), true);
      expect(AIProvider.values.contains(AIProvider.gemini), true);
      expect(AIProvider.values.contains(AIProvider.claude), true);
      expect(AIProvider.values.contains(AIProvider.none), true);
    });
  });
}
