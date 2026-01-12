import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_news/view/widgets/offline_download_button.dart';
import 'package:the_news/model/news_article_model.dart';

void main() {
  group('OfflineDownloadButton', () {
    late ArticleModel testArticle;

    setUp(() {
      testArticle = ArticleModel(
        articleId: 'test-1',
        link: 'https://example.com',
        title: 'Test Article',
        description: 'Test Description',
        content: 'Test Content',
        keywords: ['test'],
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
    });

    testWidgets('should render with download icon when not cached',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineDownloadButton(article: testArticle),
          ),
        ),
      );

      // Should find download icon
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });

    testWidgets('should have circular shape', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineDownloadButton(article: testArticle),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(OfflineDownloadButton),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('should use custom size', (WidgetTester tester) async {
      const customSize = 50.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineDownloadButton(
              article: testArticle,
              size: customSize,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(OfflineDownloadButton),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.constraints?.maxWidth, customSize);
      expect(container.constraints?.maxHeight, customSize);
    });
  });
}
