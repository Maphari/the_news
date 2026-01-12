import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/controller/home_controller.dart';

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
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final isSelected = selectedCategory == index;
          return GestureDetector(
            onTap: () {
              if (selectedCategory == index) return;
              onCategoryChanged(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? KAppColors.getPrimary(context)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(25),
                border: isSelected
                    ? Border.all(
                        color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                        width: 1,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: isSelected
                        ? Colors.black
                        : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
