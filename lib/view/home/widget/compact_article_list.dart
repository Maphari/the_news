import 'package:flutter/material.dart';
import 'package:the_news/model/news_article_model.dart';
import 'togglable_compact_article_item.dart';

class CompactArticleList extends StatelessWidget {
  const CompactArticleList({
    super.key,
    required this.articles,
  });

  final List<ArticleModel> articles;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        return TogglableCompactArticleItem(article: articles[index]);
      },
    );
  }
}
