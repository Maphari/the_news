import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_news/constant/app_theme.dart';
import 'package:the_news/view/home/widget/category_tabs.dart';
import 'package:the_news/view/saved/widgets/saved_filter_chips.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpGolden(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(360, 120),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('home category tabs golden', (tester) async {
    await pumpGolden(
      tester,
      CategoryTabs(
        selectedCategory: 0,
        onCategoryChanged: (_) {},
      ),
    );

    await expectLater(
      find.byType(CategoryTabs),
      matchesGoldenFile('goldens/home_tabs.png'),
    );
  });

  testWidgets('saved filter tabs golden', (tester) async {
    await pumpGolden(
      tester,
      SavedFilterChips(
        categories: const ['All', 'Technology', 'Business', 'Sports'],
        selectedCategory: 'All',
        onCategorySelected: (_) {},
      ),
    );

    await expectLater(
      find.byType(SavedFilterChips),
      matchesGoldenFile('goldens/saved_tabs.png'),
    );
  });
}
