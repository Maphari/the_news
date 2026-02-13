import 'package:flutter/material.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/view/home/widget/togglable_compact_article_item.dart';

class BreakingNewsPage extends StatelessWidget {
  const BreakingNewsPage({super.key, required this.articles});

  final List<ArticleModel> articles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KAppBar(
        title: const Text('Breaking News'),
      ),
      body: ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          return TogglableCompactArticleItem(article: articles[index]);
        },
      ),
    );
  }
}
