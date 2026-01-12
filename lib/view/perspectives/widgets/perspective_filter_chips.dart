import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
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
            child: FilterChip(
              label: Text('All'),
              selected: selectedCategory == null,
              onSelected: (selected) {
                onCategorySelected(null);
              },
              selectedColor: KAppColors.getPrimary(context).withValues(alpha: 0.2),
              checkmarkColor: KAppColors.getPrimary(context),
              labelStyle: KAppTextStyles.labelMedium.copyWith(
                color: selectedCategory == null
                    ? KAppColors.getPrimary(context)
                    : KAppColors.getOnBackground(context),
                fontWeight: selectedCategory == null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              backgroundColor: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
              side: BorderSide(
                color: selectedCategory == null
                    ? KAppColors.getPrimary(context)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.1),
              ),
            ),
          ),
          // Category chips
          ...StoryCategory.values.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category.label),
                selected: isSelected,
                onSelected: (selected) {
                  onCategorySelected(selected ? category : null);
                },
                selectedColor: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                checkmarkColor: KAppColors.getPrimary(context),
                labelStyle: KAppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? KAppColors.getPrimary(context)
                      : KAppColors.getOnBackground(context),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                side: BorderSide(
                  color: isSelected
                      ? KAppColors.getPrimary(context)
                      : KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
