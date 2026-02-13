import 'package:flutter/material.dart';
import 'package:the_news/view/widgets/app_search_bar.dart';

class ExploreSearchBar extends StatelessWidget {
  const ExploreSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSearchBar(
      controller: controller,
      onChanged: onChanged,
      hintText: 'Search articles, topics, sources...',
    );
  }
}
