import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class SavedHeader extends StatelessWidget {
  const SavedHeader({
    super.key,
    required this.isGridView,
    required this.onViewToggle,
    required this.savedCount,
  });

  final bool isGridView;
  final VoidCallback onViewToggle;
  final int savedCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved',
                      style: KAppTextStyles.headlineLarge.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: KDesignConstants.spacing4),
                    Text(
                      '$savedCount articles saved',
                      style: KAppTextStyles.bodyLarge.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.search,
                    onTap: () {
                      // Handle search
                    },
                  ),
                  const SizedBox(width: KDesignConstants.spacing8),
                  _ActionButton(
                    icon: isGridView ? Icons.view_list : Icons.grid_view,
                    onTap: onViewToggle,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: KBorderRadius.md,
      child: Container(
        padding: KDesignConstants.paddingSm,
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: KBorderRadius.md,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          color: KAppColors.getOnBackground(context),
          size: 20,
        ),
      ),
    );
  }
}
