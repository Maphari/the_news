import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/podcast_model.dart';
import 'package:the_news/service/podcast_service.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';
import 'package:the_news/utils/contrast_check.dart';

class PodcastCard extends StatelessWidget {
  const PodcastCard({
    super.key,
    required this.podcast,
    required this.onTap,
    this.compact = false,
  });

  final Podcast podcast;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildCompactCard(BuildContext context) {
    final category =
        podcast.categories.isNotEmpty ? podcast.categories.first : null;
    final overlayScrim = KAppColors.imageScrim.withValues(alpha: 0.65);
    debugCheckContrast(
      foreground: KAppColors.onImage,
      background: overlayScrim,
      contextLabel: 'Podcast card overlay',
      minRatio: 3.0,
    );
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Podcast artwork
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: KBorderRadius.lg,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (podcast.imageUrl != null)
                  SafeNetworkImage(
                    podcast.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                  )
                else
                  _buildPlaceholder(context),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        KAppColors.imageScrim.withValues(alpha: 0.05),
                        overlayScrim,
                      ],
                    ),
                  ),
                ),
                if (category != null && category.isNotEmpty)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: KAppColors.imageScrim.withValues(alpha: 0.5),
                        borderRadius: KBorderRadius.full,
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.onImage,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Row(
                    children: [
                      if (podcast.rating != null) ...[
                        Icon(Icons.star, size: 14, color: KAppColors.yellow),
                        const SizedBox(width: 4),
                        Text(
                          podcast.rating!.toStringAsFixed(1),
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: KAppColors.onImage.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (podcast.totalEpisodes > 0)
                        Text(
                          '${podcast.totalEpisodes} eps',
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: KAppColors.onImage.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          // Title
          Text(
            podcast.title,
            style: KAppTextStyles.labelMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    final isSaved = PodcastService.instance.isPodcastSaved(podcast.id);
    final category =
        podcast.categories.isNotEmpty ? podcast.categories.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: KDesignConstants.paddingMd,
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
          borderRadius: KBorderRadius.xl,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Podcast artwork
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                borderRadius: KBorderRadius.lg,
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (podcast.imageUrl != null)
                    SafeNetworkImage(
                      podcast.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                    )
                  else
                    _buildPlaceholder(context),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          KAppColors.imageScrim.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: KDesignConstants.spacing12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    podcast.title,
                    style: KAppTextStyles.titleMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KDesignConstants.spacing4),
                  Text(
                    podcast.publisher,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: KDesignConstants.spacing12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
                      borderRadius: KBorderRadius.md,
                      border: Border.all(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (category != null && category.isNotEmpty) ...[
                          Text(
                            category.toUpperCase(),
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: KAppColors.getPrimary(context),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing8),
                        ],
                        if (podcast.totalEpisodes > 0) ...[
                          Icon(
                            Icons.podcasts,
                            size: 14,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: KDesignConstants.spacing4),
                          Text(
                            '${podcast.totalEpisodes} eps',
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        if (podcast.rating != null) ...[
                          const SizedBox(width: KDesignConstants.spacing12),
                          Icon(
                            Icons.star,
                            size: 14,
                            color: KAppColors.yellow,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            podcast.rating!.toStringAsFixed(1),
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Save button
            InkWell(
              onTap: () {
                if (isSaved) {
                  PodcastService.instance.unsavePodcast(podcast.id);
                } else {
                  PodcastService.instance.savePodcast(podcast);
                }
              },
              borderRadius: KBorderRadius.lg,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSaved
                      ? KAppColors.getPrimary(context).withValues(alpha: 0.15)
                      : KAppColors.getOnBackground(context).withValues(alpha: 0.06),
                  borderRadius: KBorderRadius.lg,
                ),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved
                      ? KAppColors.getPrimary(context)
                      : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.podcasts,
        size: compact ? 40 : 32,
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
      ),
    );
  }
}
