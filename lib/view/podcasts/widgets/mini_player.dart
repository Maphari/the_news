import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/service/podcast_player_service.dart';
import 'package:the_news/view/podcasts/episode_player_page.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final PodcastPlayerService _playerService = PodcastPlayerService.instance;

  @override
  void initState() {
    super.initState();
    _playerService.addListener(_onPlayerUpdate);
  }

  @override
  void dispose() {
    _playerService.removeListener(_onPlayerUpdate);
    super.dispose();
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final episode = _playerService.currentEpisode;
    if (episode == null) return const SizedBox.shrink();

    return Dismissible(
      key: ValueKey('mini_player_${episode.id}'),
      direction: DismissDirection.down,
      confirmDismiss: (_) async {
        await _playerService.stop();
        return true;
      },
      background: Container(
        color: KAppColors.getSurface(context),
        alignment: Alignment.center,
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
          size: 32,
        ),
      ),
      child: GestureDetector(
        onTap: () => _openFullPlayer(context),
        child: Container(
          decoration: BoxDecoration(
            color: KAppColors.getSurface(context),
            boxShadow: [
              BoxShadow(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: _playerService.progress,
                  backgroundColor: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    KAppColors.getPrimary(context),
                  ),
                  minHeight: 2,
                ),
                // Player content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KDesignConstants.spacing12,
                    vertical: KDesignConstants.spacing8,
                  ),
                  child: Row(
                    children: [
                      // Episode artwork
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: KBorderRadius.sm,
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: episode.imageUrl != null || episode.podcastImageUrl != null
                            ? SafeNetworkImage(
                                episode.imageUrl ?? episode.podcastImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                      const SizedBox(width: KDesignConstants.spacing12),
                      // Episode info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              episode.title,
                              style: KAppTextStyles.labelMedium.copyWith(
                                color: KAppColors.getOnBackground(context),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              episode.podcastTitle,
                              style: KAppTextStyles.labelSmall.copyWith(
                                color:
                                    KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Play/Pause button
                          IconButton(
                            icon: Icon(
                              _playerService.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: KAppColors.getOnBackground(context),
                              size: 32,
                            ),
                            onPressed: _playerService.togglePlayPause,
                          ),
                          // Close button
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              size: 20,
                            ),
                            onPressed: _playerService.stop,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.podcasts,
        size: 24,
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
      ),
    );
  }

  void _openFullPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EpisodePlayerPage(),
      ),
    );
  }
}
