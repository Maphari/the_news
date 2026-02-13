import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/podcast_model.dart';
import 'package:the_news/service/podcast_service.dart';
import 'package:the_news/service/podcast_player_service.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class EpisodeCard extends StatelessWidget {
  const EpisodeCard({
    super.key,
    required this.episode,
    required this.podcast,
    required this.onPlay,
  });

  final Episode episode;
  final Podcast podcast;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final playerService = PodcastPlayerService.instance;
    final podcastService = PodcastService.instance;
    final isCurrentlyPlaying = playerService.currentEpisode?.id == episode.id;
    final progress = podcastService.getProgress(episode.id);

    return GestureDetector(
      onTap: onPlay,
      child: Container(
        padding: KDesignConstants.paddingMd,
        decoration: BoxDecoration(
          color: isCurrentlyPlaying
              ? KAppColors.getPrimary(context).withValues(alpha: 0.1)
              : KAppColors.getOnBackground(context).withValues(alpha: 0.03),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: isCurrentlyPlaying
                ? KAppColors.getPrimary(context).withValues(alpha: 0.3)
                : KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Episode artwork
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: KBorderRadius.md,
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Image
                      episode.imageUrl != null || episode.podcastImageUrl != null
                          ? SafeNetworkImage(
                              episode.imageUrl ?? episode.podcastImageUrl ?? podcast.imageUrl ?? '',
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                            )
                          : _buildPlaceholder(context),
                      // Play overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: KAppColors.imageScrim.withValues(alpha: 0.3),
                          ),
                          child: Center(
                            child: Icon(
                              isCurrentlyPlaying && playerService.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: KAppColors.onImage,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                // Episode info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.title,
                        style: KAppTextStyles.titleSmall.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: KDesignConstants.spacing4),
                      Row(
                        children: [
                          Text(
                            timeago.format(episode.publishedDate),
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: KDesignConstants.spacing8),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            episode.formattedDuration,
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Description
            if (episode.description.isNotEmpty) ...[
              const SizedBox(height: KDesignConstants.spacing12),
              Text(
                _stripHtmlTags(episode.description),
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Progress bar (if in progress)
            if (progress != null && !progress.completed && progress.progressPercent > 0) ...[
              const SizedBox(height: KDesignConstants.spacing12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: KBorderRadius.full,
                      child: LinearProgressIndicator(
                        value: progress.progressPercent,
                        backgroundColor: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          KAppColors.getPrimary(context),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: KDesignConstants.spacing8),
                  Text(
                    _formatRemainingTime(progress),
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.getPrimary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.podcasts,
        size: 24,
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
      ),
    );
  }

  String _stripHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }

  String _formatRemainingTime(ListeningProgress progress) {
    final remaining = progress.totalSeconds - progress.progressSeconds;
    final minutes = remaining ~/ 60;
    if (minutes < 60) {
      return '${minutes}m left';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m left';
  }
}
