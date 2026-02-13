import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/controller/home_controller.dart';
import 'package:the_news/view/widgets/pill_tab.dart';

class CategoryTabs extends StatelessWidget {
  const CategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final int selectedCategory;
  final ValueChanged<int> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: KDesignConstants.tabHeight,
      margin: EdgeInsets.symmetric(vertical: KDesignConstants.spacing8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: KDesignConstants.paddingHorizontalMd,
        itemBuilder: (context, index) {
          final isSelected = selectedCategory == index;
          return Padding(
            padding: EdgeInsets.only(right: KDesignConstants.spacing8),
            child: PillTabContainer(
              selected: isSelected,
              onTap: () {
                if (selectedCategory == index) return;
                onCategoryChanged(index);
              },
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: KBorderRadius.xl,
              child: Text(
                categories[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KAppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? KAppColors.getOnPrimary(context)
                      : KAppColors.getOnBackground(context).withValues(alpha: 0.65),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
