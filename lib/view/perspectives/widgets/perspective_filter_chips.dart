import 'package:flutter/material.dart';
import 'package:the_news/view/widgets/pill_tab.dart';
import 'package:the_news/model/story_cluster_model.dart';

/// Filter chips for selecting story categories
class PerspectiveFilterChips extends StatelessWidget {
  const PerspectiveFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final StoryCategory? selectedCategory;
  final Function(StoryCategory?) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PillTab(
              label: 'All',
              selected: selectedCategory == null,
              onTap: () => onCategorySelected(null),
            ),
          ),
          // Category chips
          ...StoryCategory.values.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PillTab(
                label: category.label,
                selected: isSelected,
                onTap: () => onCategorySelected(isSelected ? null : category),
              ),
            );
          }),
        ],
      ),
    );
  }
}
