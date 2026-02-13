import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/podcast_model.dart';
import 'package:the_news/service/podcast_service.dart';
import 'package:the_news/service/podcast_player_service.dart';
import 'package:the_news/view/podcasts/widgets/episode_card.dart';
import 'package:the_news/view/podcasts/widgets/mini_player.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class PodcastDetailPage extends StatefulWidget {
  const PodcastDetailPage({super.key, required this.podcast});

  final Podcast podcast;

  @override
  State<PodcastDetailPage> createState() => _PodcastDetailPageState();
}

class _PodcastDetailPageState extends State<PodcastDetailPage> {
  final PodcastService _podcastService = PodcastService.instance;
  final PodcastPlayerService _playerService = PodcastPlayerService.instance;

  List<Episode> _episodes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _nextCursor;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
    _podcastService.addListener(_onServiceUpdate);
    _playerService.addListener(_onPlayerUpdate);
  }

  @override
  void dispose() {
    _podcastService.removeListener(_onServiceUpdate);
    _playerService.removeListener(_onPlayerUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadEpisodes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final page = await _podcastService.getPodcastEpisodesPage(widget.podcast.id);

    if (!mounted) return;
    setState(() {
      _episodes = page.episodes;
      _isLoading = false;
      _nextCursor = page.nextCursor;
      _hasMore = page.nextCursor != null;
    });
  }

  Future<void> _loadMoreEpisodes() async {
    if (_isLoadingMore || !_hasMore) return;

    if (!mounted) return;
    setState(() => _isLoadingMore = true);

    final page = await _podcastService.getPodcastEpisodesPage(
      widget.podcast.id,
      cursor: _nextCursor,
    );

    if (!mounted) return;
    setState(() {
      _episodes.addAll(page.episodes);
      _isLoadingMore = false;
      _nextCursor = page.nextCursor;
      _hasMore = page.nextCursor != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSaved = _podcastService.isPodcastSaved(widget.podcast.id);

    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar with podcast artwork
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: KAppColors.getBackground(context),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: const AppBackButton(),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: KDesignConstants.paddingSm,
                      decoration: BoxDecoration(
                        color: KAppColors.getBackground(context).withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved
                            ? KAppColors.getPrimary(context)
                            : KAppColors.getOnBackground(context),
                      ),
                    ),
                    onPressed: () {
                      if (isSaved) {
                        _podcastService.unsavePodcast(widget.podcast.id);
                      } else {
                        _podcastService.savePodcast(widget.podcast);
                      }
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background blur
                      if (widget.podcast.imageUrl != null)
                        SafeNetworkImage(
                          widget.podcast.imageUrl!,
                          fit: BoxFit.cover,
                          color: KAppColors.imageScrim.withValues(alpha: 0.5),
                          colorBlendMode: BlendMode.darken,
                          errorBuilder: (_, __, ___) => Container(
                            color: KAppColors.getPrimary(context).withValues(alpha: 0.3),
                          ),
                        ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              KAppColors.getBackground(context),
                            ],
                          ),
                        ),
                      ),
                      // Podcast info
                      Positioned(
                        left: KDesignConstants.spacing16,
                        right: KDesignConstants.spacing16,
                        bottom: KDesignConstants.spacing16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Artwork
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: KBorderRadius.lg,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: widget.podcast.imageUrl != null
                                  ? SafeNetworkImage(
                                      widget.podcast.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder(),
                            ),
                            const SizedBox(width: KDesignConstants.spacing16),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.podcast.title,
                                    style: KAppTextStyles.titleLarge.copyWith(
                                      color: KAppColors.getOnBackground(context),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: KDesignConstants.spacing4),
                                  Text(
                                    widget.podcast.publisher,
                                    style: KAppTextStyles.bodyMedium.copyWith(
                                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats row
              SliverToBoxAdapter(
                child: Padding(
                  padding: KDesignConstants.paddingMd,
                  child: Row(
                    children: [
                      if (widget.podcast.totalEpisodes > 0) ...[
                        _buildStat(
                          icon: Icons.podcasts,
                          value: '${widget.podcast.totalEpisodes}',
                          label: 'Episodes',
                        ),
                        const SizedBox(width: KDesignConstants.spacing24),
                      ],
                      if (widget.podcast.rating != null)
                        _buildStat(
                          icon: Icons.star,
                          iconColor: KAppColors.yellow,
                          value: widget.podcast.rating!.toStringAsFixed(1),
                          label: '${widget.podcast.ratingCount ?? 0} ratings',
                        ),
                    ],
                  ),
                ),
              ),

              // Description
              SliverToBoxAdapter(
                child: Padding(
                  padding: KDesignConstants.paddingHorizontalMd,
                  child: Text(
                    widget.podcast.description,
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Episodes header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KDesignConstants.spacing16,
                    KDesignConstants.spacing24,
                    KDesignConstants.spacing16,
                    KDesignConstants.spacing12,
                  ),
                  child: Text(
                    'Episodes',
                    style: KAppTextStyles.titleLarge.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Episodes list
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_episodes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.podcasts_outlined,
                            size: 56,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: KDesignConstants.spacing12),
                          Text(
                            'No episodes available',
                            style: KAppTextStyles.titleMedium.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: KDesignConstants.paddingHorizontalMd,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _episodes.length) {
                          // Load more indicator
                          if (_hasMore) {
                            _loadMoreEpisodes();
                            return const Padding(
                              padding: EdgeInsets.all(KDesignConstants.spacing16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return null;
                        }

                        final episode = _episodes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: KDesignConstants.spacing12),
                          child: EpisodeCard(
                            episode: episode,
                            podcast: widget.podcast,
                            onPlay: () => _playerService.playEpisode(
                              episode,
                              podcast: widget.podcast,
                            ),
                          ),
                        );
                      },
                      childCount: _episodes.length + (_hasMore ? 1 : 0),
                    ),
                  ),
                ),

              // Bottom padding for mini player
              SliverToBoxAdapter(
                child: SizedBox(height: _playerService.hasEpisode ? 100 : 20),
              ),
            ],
          ),

          // Mini Player
          if (_playerService.hasEpisode)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    Color? iconColor,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor ?? KAppColors.getOnBackground(context).withValues(alpha: 0.6),
        ),
        const SizedBox(width: KDesignConstants.spacing8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: KAppTextStyles.labelSmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          Icons.podcasts,
          size: 48,
          color: KAppColors.getPrimary(context),
        ),
      ),
    );
  }
}
