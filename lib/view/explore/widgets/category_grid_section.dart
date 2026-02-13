import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/controller/home_controller.dart';
import 'package:the_news/routes/app_routes.dart';

class CategoryGridSection extends StatelessWidget {
  const CategoryGridSection({super.key, this.showHeader = true});

  final bool showHeader;

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
      KAppColors.getPrimary(context),
      KAppColors.getTertiary(context),
      KAppColors.getSecondary(context),
      KAppColors.pink,
      KAppColors.orange,
      KAppColors.cyan,
      KAppColors.red,
      KAppColors.yellow,
      KAppColors.green,
      KAppColors.purple,
    ];

    return Padding(
      padding: KDesignConstants.paddingHorizontalMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                Container(
                  padding: KDesignConstants.paddingSm,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        KAppColors.getTertiary(context).withValues(alpha: 0.2),
                        KAppColors.getPrimary(context).withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: KBorderRadius.md,
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    color: KAppColors.getTertiary(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                Text(
                  'Browse by Category',
                  style: KAppTextStyles.titleLarge.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KDesignConstants.spacing8),
          ],
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              crossAxisSpacing: KDesignConstants.spacing8,
              mainAxisSpacing: KDesignConstants.spacing4,
            ),
            itemCount: categories.length > 6 ? 6 : categories.length,
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
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class CategoryGridSliver extends StatelessWidget {
  const CategoryGridSliver({super.key, this.maxItems = 6});

  final int maxItems;

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
      KAppColors.getPrimary(context),
      KAppColors.getTertiary(context),
      KAppColors.getSecondary(context),
      KAppColors.pink,
      KAppColors.orange,
      KAppColors.cyan,
      KAppColors.red,
      KAppColors.yellow,
      KAppColors.green,
      KAppColors.purple,
    ];

    return SliverPadding(
      padding: KDesignConstants.paddingHorizontalMd,
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.8,
          crossAxisSpacing: KDesignConstants.spacing12,
          mainAxisSpacing: KDesignConstants.spacing12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
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
          childCount: categories.length > maxItems ? maxItems : categories.length,
        ),
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
        borderRadius: KBorderRadius.xl,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.28),
                color.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: KBorderRadius.xl,
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: KBorderRadius.lg,
                    border: Border.all(
                      color: color.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                Expanded(
                  child: Text(
                    title.length > 8 ? '${title.substring(0, 8)}…' : title,
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: KDesignConstants.spacing8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: KAppColors.getOnBackground(context)
                      .withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
