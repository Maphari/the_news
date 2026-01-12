import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class EmptySavedState extends StatelessWidget {
  const EmptySavedState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Bookmark Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: KAppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: KAppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark_border_rounded,
                    size: 48,
                    color: KAppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Title
            Text(
              'No Saved Articles',
              style: KAppTextStyles.headlineSmall.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Start bookmarking articles you want\nto read later. They\'ll appear here.',
              textAlign: TextAlign.center,
              style: KAppTextStyles.bodyLarge.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // CTA Button
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to explore or home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KAppColors.primary,
                foregroundColor: KAppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.explore_outlined),
              label: Text(
                'Explore Articles',
                style: KAppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}