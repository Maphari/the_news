import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/controller/home_controller.dart';
import 'package:the_news/routes/app_routes.dart';

class CategoryGridSection extends StatelessWidget {
  const CategoryGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryIcons = {
      'All': Icons.grid_view_rounded,
      'Politics': Icons.account_balance_outlined,
      'Business': Icons.business_center_outlined,
      'Technology': Icons.computer_outlined,
      'Sports': Icons.sports_soccer_outlined,
      'Environment': Icons.eco_outlined,
      'Health': Icons.favorite_outline,
      'Science': Icons.science_outlined,
      'Education': Icons.school_outlined,
      'Culture': Icons.theater_comedy_outlined,
    };

    final categoryColors = [
      KAppColors.primary,
      KAppColors.tertiary,
      KAppColors.secondary,
      const Color(0xFFFFC5C9),
      const Color(0xFFFFD4A3),
      const Color(0xFFC5D9FF),
      const Color(0xFFFFB8B8),
      KAppColors.primary,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      KAppColors.tertiary.withValues(alpha: 0.2),
                      KAppColors.primary.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.category_outlined,
                  color: KAppColors.tertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Browse by Category',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: categories.length > 8 ? 8 : categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = categoryColors[index % categoryColors.length];
              final icon = categoryIcons[category] ?? Icons.article_outlined;
              return _CategoryCard(
                title: category,
                icon: icon,
                color: color,
                onTap: () {
                  AppRoutes.navigateTo(
                    context,
                    AppRoutes.categoryDetail,
                    arguments: {
                      'category': category,
                      'color': color,
                      'icon': icon,
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.25),
                color.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
