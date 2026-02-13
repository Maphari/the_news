import 'package:the_news/constant/theme/default_theme.dart';
import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/service/stats_sharing_service.dart';

class ShareStatsButton extends StatelessWidget {
  const ShareStatsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showShareOptions(context),
        borderRadius: KBorderRadius.md,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: KAppColors.getPrimary(context),
            borderRadius: KBorderRadius.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.share,
                color: KAppColors.onImage,
                size: 20,
              ),
              const SizedBox(width: KDesignConstants.spacing8),
              Text(
                'Share Stats',
                style: KAppTextStyles.labelLarge.copyWith(
                  color: KAppColors.onImage,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ShareOptionsSheet(),
    );
  }
}

class ShareOptionsSheet extends StatelessWidget {
  const ShareOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final sharingService = StatsSharingService.instance;

    return Container(
      padding: KDesignConstants.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Your Progress',
            style: KAppTextStyles.headlineSmall.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Text(
            'Inspire others with your mindful reading journey',
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing24),

          // Today's Stats
          _ShareOption(
            icon: Icons.today,
            title: 'Today\'s Stats',
            description: 'Share your reading progress for today',
            onTap: () {
              Navigator.pop(context);
              sharingService.shareTodayStats(context);
            },
          ),
          const SizedBox(height: KDesignConstants.spacing12),

          // All Time Stats
          _ShareOption(
            icon: Icons.bar_chart,
            title: 'All-Time Stats',
            description: 'Share your complete reading journey',
            onTap: () {
              Navigator.pop(context);
              sharingService.shareTodayStats(context); // Will enhance this later
            },
          ),

          const SizedBox(height: KDesignConstants.spacing24),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: KBorderRadius.md,
        child: Container(
          padding: KDesignConstants.paddingMd,
          decoration: BoxDecoration(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
            borderRadius: KBorderRadius.md,
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: KAppColors.getPrimary(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: KAppTextStyles.titleMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
