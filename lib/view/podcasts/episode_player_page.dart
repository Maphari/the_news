import 'package:flutter/material.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/service/podcast_player_service.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class EpisodePlayerPage extends StatefulWidget {
  const EpisodePlayerPage({super.key});

  @override
  State<EpisodePlayerPage> createState() => _EpisodePlayerPageState();
}

class _EpisodePlayerPageState extends State<EpisodePlayerPage> {
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
    final podcast = _playerService.currentPodcast;

    if (episode == null) {
      return Scaffold(
        backgroundColor: KAppColors.getBackground(context),
        appBar: KAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'No episode playing',
            style: KAppTextStyles.titleMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KDesignConstants.spacing8,
                vertical: KDesignConstants.spacing8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: KAppColors.getOnBackground(context),
                      size: 32,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Now Playing',
                    style: KAppTextStyles.labelMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: KAppColors.getOnBackground(context),
                    ),
                    onPressed: () => _showOptionsMenu(context),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: KDesignConstants.paddingHorizontalLg,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Artwork
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: KBorderRadius.xl,
                        boxShadow: [
                          BoxShadow(
                            color: KAppColors.getPrimary(context).withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: episode.imageUrl != null ||
                              episode.podcastImageUrl != null ||
                              podcast?.imageUrl != null
                          ? SafeNetworkImage(
                              episode.imageUrl ??
                                  episode.podcastImageUrl ??
                                  podcast?.imageUrl ??
                                  '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),

                    const SizedBox(height: KDesignConstants.spacing32),

                    // Episode title
                    Text(
                      episode.title,
                      style: KAppTextStyles.titleLarge.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: KDesignConstants.spacing8),

                    // Podcast title
                    Text(
                      episode.podcastTitle,
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: KDesignConstants.spacing32),

                    // Progress slider
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: KAppColors.getPrimary(context),
                            inactiveTrackColor: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                            thumbColor: KAppColors.getPrimary(context),
                            overlayColor: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _playerService.progress.clamp(0.0, 1.0),
                            onChanged: (value) {
                              final newPosition = Duration(
                                milliseconds: (value * _playerService.duration.inMilliseconds).round(),
                              );
                              _playerService.seek(newPosition);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _playerService.positionString,
                                style: KAppTextStyles.labelSmall.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                                ),
                              ),
                              Text(
                                _playerService.remainingString,
                                style: KAppTextStyles.labelSmall.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: KDesignConstants.spacing24),

                    // Playback controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Speed button
                        TextButton(
                          onPressed: _playerService.cycleSpeed,
                          child: Text(
                            '${_playerService.playbackSpeed}x',
                            style: KAppTextStyles.labelMedium.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(width: KDesignConstants.spacing16),

                        // Rewind button
                        IconButton(
                          icon: Icon(
                            Icons.replay_10,
                            color: KAppColors.getOnBackground(context),
                            size: 36,
                          ),
                          onPressed: _playerService.seekBackward,
                        ),

                        const SizedBox(width: KDesignConstants.spacing16),

                        // Play/Pause button
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: KAppColors.getPrimary(context),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _playerService.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: KAppColors.getOnPrimary(context),
                              size: 40,
                            ),
                            onPressed: _playerService.togglePlayPause,
                          ),
                        ),

                        const SizedBox(width: KDesignConstants.spacing16),

                        // Forward button
                        IconButton(
                          icon: Icon(
                            Icons.forward_30,
                            color: KAppColors.getOnBackground(context),
                            size: 36,
                          ),
                          onPressed: _playerService.seekForward,
                        ),

                        const SizedBox(width: KDesignConstants.spacing16),

                        // Sleep timer button
                        IconButton(
                          icon: Icon(
                            _playerService.sleepTimerRemaining != null
                                ? Icons.bedtime
                                : Icons.bedtime_outlined,
                            color: _playerService.sleepTimerRemaining != null
                                ? KAppColors.getPrimary(context)
                                : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                          ),
                          onPressed: () => _showSleepTimerDialog(context),
                        ),
                      ],
                    ),

                    // Sleep timer indicator
                    if (_playerService.sleepTimerRemaining != null) ...[
                      const SizedBox(height: KDesignConstants.spacing16),
                      Text(
                        'Sleep in ${_formatDuration(_playerService.sleepTimerRemaining!)}',
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.getPrimary(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          Icons.podcasts,
          size: 80,
          color: KAppColors.getPrimary(context),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KAppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Episode'),
              onTap: () {
                Navigator.pop(context);
                // Share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Save Episode'),
              onTap: () {
                Navigator.pop(context);
                // Save functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Episode Info'),
              onTap: () {
                Navigator.pop(context);
                // Show episode info
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KAppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(KDesignConstants.spacing16),
              child: Text(
                'Sleep Timer',
                style: KAppTextStyles.titleMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_playerService.sleepTimerRemaining != null)
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancel Timer'),
                onTap: () {
                  _playerService.cancelSleepTimer();
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('5 minutes'),
              onTap: () {
                _playerService.setSleepTimer(const Duration(minutes: 5));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('15 minutes'),
              onTap: () {
                _playerService.setSleepTimer(const Duration(minutes: 15));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('30 minutes'),
              onTap: () {
                _playerService.setSleepTimer(const Duration(minutes: 30));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('1 hour'),
              onTap: () {
                _playerService.setSleepTimer(const Duration(hours: 1));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
