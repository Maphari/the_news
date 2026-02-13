import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/podcast_model.dart';
import 'package:intl/intl.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/service/podcast_service.dart';
import 'package:the_news/service/podcast_player_service.dart';
import 'package:the_news/view/podcasts/podcast_detail_page.dart';
import 'package:the_news/view/podcasts/widgets/mini_player.dart';
import 'package:the_news/view/podcasts/widgets/podcast_card.dart';
import 'package:the_news/view/widgets/shimmer_loading.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class PodcastPublisherPage extends StatefulWidget {
  const PodcastPublisherPage({
    super.key,
    required this.publisherName,
    this.publisherImageUrl,
  });

  final String publisherName;
  final String? publisherImageUrl;

  @override
  State<PodcastPublisherPage> createState() => _PodcastPublisherPageState();
}

class _PodcastPublisherPageState extends State<PodcastPublisherPage> {
  final PodcastService _podcastService = PodcastService.instance;
  final PodcastPlayerService _playerService = PodcastPlayerService.instance;
  final FollowedPublishersService _followedService =
      FollowedPublishersService.instance;
  final AuthService _authService = AuthService.instance;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<Podcast> _podcasts = [];
  List<_EpisodePreview> _latestEpisodes = [];
  bool _isLoadingEpisodes = false;
  String? _currentUserId;
  bool _isFollowingPublisher = false;
  bool _isTogglingFollow = false;
  int? _followCount;
  String? _publisherDescription;

  @override
  void initState() {
    super.initState();
    _playerService.addListener(_onPlayerUpdate);
    _followedService.addListener(_onFollowedPublishersChanged);
    _loadUserData();
    _loadFollowCount();
    _loadPublisherPodcasts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _playerService.removeListener(_onPlayerUpdate);
    _followedService.removeListener(_onFollowedPublishersChanged);
    super.dispose();
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  void _onFollowedPublishersChanged() {
    if (!mounted) return;
    setState(() {
      _isFollowingPublisher =
          _followedService.isPublisherFollowed(widget.publisherName);
    });
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _currentUserId = userData?['id'] as String? ?? userData?['userId'] as String?;
    });
    final userId = _currentUserId;
    if (userId != null && userId.isNotEmpty) {
      await _followedService.loadFollowedPublishers(userId);
      if (mounted) {
        setState(() {
          _isFollowingPublisher =
              _followedService.isPublisherFollowed(widget.publisherName);
        });
      }
    }
  }

  Future<void> _loadFollowCount() async {
    final count = await _followedService.fetchPublisherFollowCount(
      widget.publisherName,
    );
    if (mounted && count != null) {
      setState(() => _followCount = count);
    }
  }

  Future<void> _loadPublisherPodcasts() async {
    setState(() => _isLoading = true);
    final results = await _podcastService.searchPodcasts(
      query: widget.publisherName,
      limit: 50,
    );

    final filtered = results.where((podcast) {
      return podcast.publisher.toLowerCase() == widget.publisherName.toLowerCase();
    }).toList();

    setState(() {
      _podcasts = filtered.isNotEmpty ? filtered : results;
      _isLoading = false;
      _publisherDescription = _extractPublisherDescription(_podcasts);
    });

    _loadLatestEpisodes();
  }

  Future<void> _toggleFollow() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty || _isTogglingFollow) {
      if (mounted && (userId == null || userId.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log in to follow publishers')),
        );
      }
      return;
    }

    setState(() => _isTogglingFollow = true);
    final success = await _followedService.toggleFollow(
      userId,
      widget.publisherName,
    );
    if (mounted) {
      setState(() {
        _isTogglingFollow = false;
        if (success) {
          _isFollowingPublisher =
              _followedService.isPublisherFollowed(widget.publisherName);
        }
      });
    }
  }

  Future<void> _loadLatestEpisodes() async {
    if (_isLoadingEpisodes || _podcasts.isEmpty) return;
    setState(() => _isLoadingEpisodes = true);
    final previews = <_EpisodePreview>[];

    for (final podcast in _podcasts.take(6)) {
      final episodes = await _podcastService.getPodcastEpisodes(podcast.id, limit: 1);
      if (episodes.isNotEmpty && episodes.first.audioUrl.isNotEmpty) {
        previews.add(_EpisodePreview(episode: episodes.first, podcast: podcast));
      }
    }

    previews.sort((a, b) => b.episode.publishedDate.compareTo(a.episode.publishedDate));
    if (mounted) {
      setState(() {
        _latestEpisodes = previews;
        _isLoadingEpisodes = false;
      });
    }
  }

  Future<void> _playEpisode(_EpisodePreview preview) async {
    final success = await _playerService.playEpisode(
      preview.episode,
      podcast: preview.podcast,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to play episode')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topShows = _getTopShows();
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: KAppColors.getBackground(context),
                surfaceTintColor: Colors.transparent,
                expandedHeight: 200,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                KAppColors.getPrimary(context).withValues(alpha: 0.12),
                                KAppColors.getBackground(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (widget.publisherImageUrl?.isNotEmpty ?? false)
                        SafeNetworkImage(
                          widget.publisherImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color:
                                KAppColors.getOnBackground(context).withValues(alpha: 0.06),
                          ),
                        )
                      else
                        Container(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              KAppColors.imageScrim.withValues(alpha: 0.4),
                              KAppColors.getBackground(context),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.publisherName,
                            style: KAppTextStyles.headlineMedium.copyWith(
                              color: KAppColors.onImage,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if ((_publisherDescription ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _publisherDescription!,
                              style: KAppTextStyles.bodySmall.copyWith(
                                color: KAppColors.onImage.withValues(alpha: 0.8),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Publisher',
                                style: KAppTextStyles.labelMedium.copyWith(
                                  color: KAppColors.onImage.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_followCount != null)
                                Text(
                                  '${_formatCount(_followCount!)} followers',
                                  style: KAppTextStyles.labelMedium.copyWith(
                                    color: KAppColors.onImage.withValues(alpha: 0.7),
                                  ),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: KDesignConstants.paddingMd,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_podcasts.length} podcasts',
                          style: KAppTextStyles.bodyMedium.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      if (_currentUserId != null && _currentUserId!.isNotEmpty)
                        _buildFollowButton(),
                      IconButton(
                        onPressed: _loadPublisherPodcasts,
                        icon: const Icon(Icons.refresh),
                        color: KAppColors.getPrimary(context),
                      ),
                    ],
                  ),
                ),
              ),
              if (topShows.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Top Shows',
                      style: KAppTextStyles.titleLarge.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 230,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: KDesignConstants.paddingHorizontalMd,
                      itemCount: topShows.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: KDesignConstants.spacing16),
                      itemBuilder: (context, index) {
                        final podcast = topShows[index];
                        return SizedBox(
                          width: 170,
                          child: PodcastCard(
                            podcast: podcast,
                            compact: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PodcastDetailPage(podcast: podcast),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
              if (_latestEpisodes.isNotEmpty || _isLoadingEpisodes) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Latest Episodes',
                      style: KAppTextStyles.titleLarge.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 230,
                    child: _isLoadingEpisodes && _latestEpisodes.isEmpty
                        ? const _LatestEpisodesSkeleton()
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: KDesignConstants.paddingHorizontalMd,
                            itemCount: _latestEpisodes.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: KDesignConstants.spacing12),
                            itemBuilder: (context, index) {
                              final preview = _latestEpisodes[index];
                              return _PublisherEpisodeCard(
                                preview: preview,
                                onTap: () => _playEpisode(preview),
                              );
                            },
                          ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_podcasts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No podcasts found',
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: KDesignConstants.paddingMd,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final podcast = _podcasts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: KDesignConstants.spacing12),
                          child: PodcastCard(
                            podcast: podcast,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PodcastDetailPage(podcast: podcast),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: _podcasts.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: _playerService.hasEpisode ? 100 : 24),
              ),
            ],
          ),
          if (_playerService.hasEpisode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: const MiniPlayer(),
            ),
        ],
      ),
    );
  }

  List<Podcast> _getTopShows() {
    if (_podcasts.isEmpty) return [];
    final shows = List<Podcast>.from(_podcasts);
    shows.sort((a, b) {
      final ratingDiff = (b.rating ?? 0).compareTo(a.rating ?? 0);
      if (ratingDiff != 0) return ratingDiff;
      return b.totalEpisodes.compareTo(a.totalEpisodes);
    });
    return shows.take(10).toList();
  }

  String? _extractPublisherDescription(List<Podcast> podcasts) {
    for (final podcast in podcasts) {
      final desc = podcast.description.trim();
      if (desc.isNotEmpty) return desc;
    }
    return null;
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildFollowButton() {
    final isFollowing = _isFollowingPublisher;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        key: ValueKey(isFollowing),
        onPressed: _isTogglingFollow ? null : _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing
              ? KAppColors.getOnBackground(context).withValues(alpha: 0.1)
              : KAppColors.getPrimary(context),
          foregroundColor: isFollowing
              ? KAppColors.getOnBackground(context)
              : KAppColors.getOnPrimary(context),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: KBorderRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isFollowing ? Icons.check : Icons.add, size: 18),
            const SizedBox(width: 6),
            Text(
              isFollowing ? 'Following' : 'Follow',
              style: KAppTextStyles.labelMedium.copyWith(
                color: isFollowing
                    ? KAppColors.getOnBackground(context)
                    : KAppColors.getOnPrimary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodePreview {
  final Episode episode;
  final Podcast podcast;

  _EpisodePreview({required this.episode, required this.podcast});
}

class _PublisherEpisodeCard extends StatelessWidget {
  const _PublisherEpisodeCard({
    required this.preview,
    required this.onTap,
  });

  final _EpisodePreview preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = preview.episode.imageUrl ?? preview.podcast.imageUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              SafeNetworkImage(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                  child: Center(
                    child: Icon(
                      Icons.podcasts,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                    ),
                  ),
                ),
              )
            else
              Container(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                child: Center(
                  child: Icon(
                    Icons.podcasts,
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      KAppColors.imageScrim.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview.podcast.title,
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.onImage.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          preview.episode.title,
                          style: KAppTextStyles.bodyMedium.copyWith(
                            color: KAppColors.onImage,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: KAppColors.imageScrim.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: KAppColors.onImage,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: KAppColors.onImage.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatEpisodeMeta(preview.episode),
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: KAppColors.onImage.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEpisodeMeta(Episode episode) {
    final durationSeconds = episode.durationSeconds;
    final minutes = (durationSeconds / 60).round();
    final date = episode.publishedDate;
    final now = DateTime.now();
    final dayDiff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    final timeLabel = DateFormat('h:mm a').format(date);
    String dayLabel;
    if (dayDiff == 0) {
      dayLabel = 'Today';
    } else if (dayDiff == 1) {
      dayLabel = 'Yesterday';
    } else {
      dayLabel = DateFormat('MMM d').format(date);
    }
    final durationLabel = minutes > 0 ? '${minutes}m' : '--';
    return '$dayLabel • $timeLabel • $durationLabel';
  }
}

class _LatestEpisodesSkeleton extends StatelessWidget {
  const _LatestEpisodesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: KDesignConstants.paddingHorizontalMd,
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: KDesignConstants.spacing16),
      itemBuilder: (_, __) => const _LatestEpisodesSkeletonCard(),
    );
  }
}

class _LatestEpisodesSkeletonCard extends StatelessWidget {
  const _LatestEpisodesSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                borderRadius: KBorderRadius.md,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                      borderRadius: KBorderRadius.md,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                      borderRadius: KBorderRadius.md,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                      borderRadius: KBorderRadius.md,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 10,
                    width: 100,
                    decoration: BoxDecoration(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                      borderRadius: KBorderRadius.md,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
