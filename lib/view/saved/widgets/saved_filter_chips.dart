import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/view/widgets/pill_tab.dart';

class SavedFilterChips extends StatelessWidget {
  const SavedFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: KDesignConstants.tabHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: KDesignConstants.paddingHorizontalLg,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _FilterChip(
              label: category,
              isSelected: isSelected,
              onTap: () => onCategorySelected(category),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PillTabContainer(
      selected: isSelected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      borderRadius: KBorderRadius.xxl,
      child: Text(
        label,
        style: KAppTextStyles.labelLarge.copyWith(
          color: isSelected
              ? KAppColors.getOnPrimary(context)
              : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
