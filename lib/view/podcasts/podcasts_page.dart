import 'dart:async';
import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/podcast_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/podcast_service.dart';
import 'package:the_news/service/podcast_player_service.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/service/calm_mode_service.dart';
import 'package:the_news/view/podcasts/podcast_detail_page.dart';
import 'package:the_news/view/podcasts/podcast_publisher_page.dart';
import 'package:the_news/view/podcasts/widgets/podcast_card.dart';
import 'package:the_news/view/podcasts/widgets/mini_player.dart';
import 'package:the_news/view/widgets/pill_tab.dart';
import 'package:the_news/view/widgets/shimmer_loading.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';
import 'package:the_news/view/podcasts/podcast_category_page.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:the_news/view/widgets/network_image_with_fallback.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class PodcastsPage extends StatefulWidget {
  const PodcastsPage({super.key, required this.user});

  final RegisterLoginUserSuccessModel user;

  @override
  State<PodcastsPage> createState() => _PodcastsPageState();
}

class _PodcastsPageState extends State<PodcastsPage> with TickerProviderStateMixin {
  final PodcastService _podcastService = PodcastService.instance;
  final PodcastPlayerService _playerService = PodcastPlayerService.instance;
  final FollowedPublishersService _followedService =
      FollowedPublishersService.instance;
  final CalmModeService _calmMode = CalmModeService.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final PageController _heroController;

  String _selectedCategory = 'All';
  List<Podcast> _searchResults = [];
  bool _isSearching = false;
  bool _showSearch = false;
  int _heroIndex = 0;
  bool _isLoadingLatestEpisodes = false;
  List<_EpisodePreview> _latestEpisodes = [];
  List<String> _latestEpisodeSources = [];
  bool _isLoadingSearchEpisodes = false;
  List<_EpisodePreview> _latestSearchEpisodes = [];
  bool _isLoadingRecentlyPlayed = false;
  List<Podcast> _recentlyPlayed = [];
  bool _isLoadingRecommendations = false;
  List<Podcast> _personalizedRecommendations = [];
  List<Podcast> _freshPicksCache = [];
  String _freshPicksKey = '';
  List<Podcast> _editorsPicksCache = [];
  String _editorsPicksKey = '';
  bool _isBootstrapping = true;
  String? _initialLoadError;
  Timer? _searchDebounce;
  String _lastTrendingSignature = '';
  String _lastProgressSignature = '';
  
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  static const Map<String, IconData> _categoryIcons = {
    'all': Icons.explore,
    'news': Icons.newspaper,
    'politics': Icons.account_balance,
    'business': Icons.business_center,
    'technology': Icons.computer,
    'science': Icons.science,
    'health': Icons.health_and_safety,
    'sports': Icons.sports_soccer,
    'entertainment': Icons.movie,
    'world': Icons.public,
    'top': Icons.trending_up,
  };

  @override
  void initState() {
    super.initState();
    _loadPodcasts();
    _podcastService.addListener(_onServiceUpdate);
    _playerService.addListener(_onPlayerUpdate);
    _followedService.addListener(_onServiceUpdate);
    _calmMode.addListener(_onServiceUpdate);
    _heroController = PageController(viewportFraction: 0.88);
    
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _heroController.dispose();
    _fabController.dispose();
    _podcastService.removeListener(_onServiceUpdate);
    _playerService.removeListener(_onPlayerUpdate);
    _followedService.removeListener(_onServiceUpdate);
    _calmMode.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final trendingSignature = _podcastService.trendingPodcasts
          .map((podcast) => podcast.id)
          .join('|');
      if (trendingSignature != _lastTrendingSignature) {
        _lastTrendingSignature = trendingSignature;
        _loadLatestEpisodes();
      }

      final progressSignature = _podcastService
          .getRecentProgress(limit: 8)
          .map((item) => '${item.podcastId}:${item.episodeId}:${item.progressSeconds}')
          .join('|');
      if (progressSignature != _lastProgressSignature) {
        _lastProgressSignature = progressSignature;
        _loadRecentlyPlayed();
      }

      final maxIndex = _podcastService.trendingPodcasts.isEmpty
          ? 0
          : _podcastService.trendingPodcasts.length - 1;
      if (_heroIndex > maxIndex) {
        _heroIndex = 0;
        if (_heroController.hasClients) {
          _heroController.jumpToPage(0);
        }
      }
      setState(() {});
    });
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPodcasts() async {
    if (mounted) {
      setState(() {
        _isBootstrapping = true;
        _initialLoadError = null;
      });
    }

    try {
      await _podcastService.initialize();
      await Future.wait([
        _loadLatestEpisodes(),
        _loadRecentlyPlayed(),
        _loadRecommendations(),
      ]);
    } catch (e) {
      _initialLoadError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isBootstrapping = false);
      }
    }
  }

  Future<void> _refreshPodcasts() async {
    _freshPicksCache = [];
    _freshPicksKey = '';
    _editorsPicksCache = [];
    _editorsPicksKey = '';
    await _podcastService.initialize(forceRefresh: true);
    await Future.wait([
      _loadLatestEpisodes(),
      _loadRecentlyPlayed(),
      _loadRecommendations(forceRefresh: true),
    ]);
  }

  Future<void> _loadLatestEpisodes() async {
    if (_isLoadingLatestEpisodes) return;
    final trending = _podcastService.trendingPodcasts;
    if (trending.isEmpty) return;

    final sourceIds = trending.take(6).map((p) => p.id).toList();
    if (_latestEpisodeSources.join('|') == sourceIds.join('|') && _latestEpisodes.isNotEmpty) {
      return;
    }

    setState(() => _isLoadingLatestEpisodes = true);
    _latestEpisodeSources = sourceIds;

    final previews = <_EpisodePreview>[];
    for (final podcast in trending.take(6)) {
      final episodes = await _podcastService.getPodcastEpisodes(podcast.id, limit: 1);
      if (episodes.isNotEmpty && episodes.first.audioUrl.isNotEmpty) {
        previews.add(_EpisodePreview(episode: episodes.first, podcast: podcast));
      }
    }

    previews.sort((a, b) => b.episode.publishedDate.compareTo(a.episode.publishedDate));

    if (mounted) {
      setState(() {
        _latestEpisodes = previews;
        _isLoadingLatestEpisodes = false;
      });
    }
  }

  Future<void> _loadRecentlyPlayed() async {
    if (_isLoadingRecentlyPlayed) return;
    final progress = _podcastService.getRecentProgress(limit: 8);
    if (progress.isEmpty) {
      if (mounted) setState(() => _recentlyPlayed = []);
      return;
    }

    setState(() => _isLoadingRecentlyPlayed = true);
    final podcasts = <Podcast>[];
    for (final item in progress) {
      final podcast = await _podcastService.getPodcastById(item.podcastId);
      if (podcast != null && !podcasts.any((p) => p.id == podcast.id)) {
        podcasts.add(podcast);
      }
    }
    if (!mounted) return;
    setState(() {
      _recentlyPlayed = podcasts;
      _isLoadingRecentlyPlayed = false;
    });
  }

  Future<void> _loadRecommendations({bool forceRefresh = false}) async {
    if (_isLoadingRecommendations) return;
    setState(() => _isLoadingRecommendations = true);
    final recommendations = await _podcastService.getRecommendations(
      limit: 12,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    setState(() {
      _personalizedRecommendations = recommendations;
      _isLoadingRecommendations = false;
    });
  }

  Future<void> _search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _latestSearchEpisodes = [];
        _isLoadingSearchEpisodes = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    if (normalized.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _latestSearchEpisodes = [];
        _isLoadingSearchEpisodes = false;
      });
      return;
    }

    final results = await _podcastService.searchPodcasts(
      query: normalized,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });

    _loadLatestEpisodesForSearch(results);
  }

  void _scheduleSearch(String query) {
    _searchDebounce?.cancel();
    final normalized = query.trim();
    if (normalized.isEmpty) {
      _search('');
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _search(normalized);
    });
  }

  Future<void> _loadLatestEpisodesForSearch(List<Podcast> podcasts) async {
    if (_isLoadingSearchEpisodes) return;
    if (podcasts.isEmpty) return;

    setState(() => _isLoadingSearchEpisodes = true);
    final previews = <_EpisodePreview>[];

    for (final podcast in podcasts.take(6)) {
      final episodes = await _podcastService.getPodcastEpisodes(podcast.id, limit: 1);
      if (episodes.isNotEmpty && episodes.first.audioUrl.isNotEmpty) {
        previews.add(_EpisodePreview(episode: episodes.first, podcast: podcast));
      }
    }

    previews.sort((a, b) => b.episode.publishedDate.compareTo(a.episode.publishedDate));

    if (mounted) {
      setState(() {
        _latestSearchEpisodes = previews;
        _isLoadingSearchEpisodes = false;
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

  List<Map<String, dynamic>> _getCategories() {
    final categories = PodcastService.categoryToGenres.keys
        .map((key) => _titleCase(key))
        .toList();
    categories.sort();
    final all = ['All', ...categories];

    return all
        .map((name) => {
              'name': name,
              'icon': _categoryIcons[name.toLowerCase()] ?? Icons.podcasts,
            })
        .toList();
  }

  String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  double _bottomNavInset(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return 72 + safeBottom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      body: Stack(
        children: [
          RefreshIndicator.adaptive(
            onRefresh: _refreshPodcasts,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
              MeasuredPinnedHeaderSliver(
                height: HomeHeader.estimatedHeight(
                  title: 'Podcasts',
                  subtitle: 'Discover shows, creators, and episodes',
                  subtitleMaxLines: 1,
                ),
                child: HomeHeader(
                  title: 'Podcasts',
                  subtitle: 'Discover shows, creators, and episodes',
                  showActions: true,
                  subtitleMaxLines: 1,
                  useSafeArea: true,
                  viewToggle: IconButton(
                    icon: Icon(
                      _showSearch ? Icons.close : Icons.search,
                      color: KAppColors.getOnBackground(context),
                    ),
                    onPressed: () {
                      setState(() => _showSearch = !_showSearch);
                      if (!_showSearch) {
                        _searchDebounce?.cancel();
                        _searchController.clear();
                        _search('');
                      }
                    },
                  ),
                ),
              ),

              // Search Bar (Toggle)
              if (_showSearch)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KDesignConstants.spacing16,
                      KDesignConstants.spacing8,
                      KDesignConstants.spacing16,
                      KDesignConstants.spacing12,
                    ),
                    child: Hero(
                      tag: 'podcast_search',
                      child: Material(
                        color: Colors.transparent,
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (value) => _scheduleSearch(value),
                          style: KAppTextStyles.bodyMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search podcasts, hosts, topics...',
                            hintStyle: KAppTextStyles.bodyMedium.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: KAppColors.getPrimary(context),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                                    ),
                                    onPressed: () {
                                      _searchDebounce?.cancel();
                                      _searchController.clear();
                                      _search('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: KBorderRadius.lg,
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: KBorderRadius.lg,
                              borderSide: BorderSide(
                                color: KAppColors.getPrimary(context),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: KDesignConstants.spacing16,
                              vertical: KDesignConstants.spacing16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Sticky Category Tabs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KDesignConstants.spacing16,
                    KDesignConstants.spacing12,
                    KDesignConstants.spacing16,
                    0,
                  ),
                  child: SizedBox(
                    height: KDesignConstants.tabHeight,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: _getCategories().length,
                      itemBuilder: (context, index) {
                        final category = _getCategories()[index];
                        final isSelected = category['name'] == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: KDesignConstants.spacing8),
                          child: PillTab(
                            label: category['name'] as String,
                            icon: category['icon'] as IconData,
                            selected: isSelected,
                            onTap: () {
                              setState(() => _selectedCategory = category['name'] as String);
                              if (_searchController.text.isNotEmpty) {
                                _scheduleSearch(_searchController.text);
                              } else {
                                _podcastService.loadTrendingPodcasts(
                                  category: _selectedCategory == 'All'
                                      ? null
                                      : _selectedCategory,
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing16)),

              // Content
              if (_searchController.text.isNotEmpty)
                _buildSearchResults()
              else
                ..._buildMainContent(),

              // Bottom padding for mini player
              SliverToBoxAdapter(
                child: SizedBox(
                  height: (_playerService.hasEpisode ? 100 : 20) + _bottomNavInset(context),
                ),
              ),
            ],
            ),
          ),

          // Mini Player
          if (_playerService.hasEpisode)
            Positioned(
              left: 0,
              right: 0,
              bottom: _bottomNavInset(context),
              child: const MiniPlayer(),
            ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_searchController.text.isNotEmpty) return null;
    
    return ScaleTransition(
      scale: _fabAnimation,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: (_playerService.hasEpisode ? 56 : 0),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            setState(() => _showSearch = true);
          },
          backgroundColor: KAppColors.getPrimary(context),
          icon: Icon(Icons.search, color: KAppColors.getOnPrimary(context)),
          label: Text(
            'Find Podcasts',
            style: TextStyle(
              color: KAppColors.getOnPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: KAppColors.getPrimary(context),
              ),
              const SizedBox(height: KDesignConstants.spacing16),
              Text(
                'Searching podcasts...',
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: KDesignConstants.paddingLg,
                decoration: BoxDecoration(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off,
                  size: 64,
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing24),
              Text(
                'No podcasts found',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing8),
              Text(
                'Try different keywords or categories',
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final latestSearchEpisodes = _latestSearchEpisodes
        .where((preview) => preview.podcast.title.toLowerCase().contains(_searchController.text.toLowerCase())
            || preview.episode.title.toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList();

    final showSearchSkeleton = _isLoadingSearchEpisodes && latestSearchEpisodes.isEmpty;

    return SliverList(
      delegate: SliverChildListDelegate(
        [
          if (latestSearchEpisodes.isNotEmpty || showSearchSkeleton) ...[
            _buildSearchSectionHeader('Latest Episodes', Icons.fiber_new),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: KDesignConstants.paddingHorizontalMd,
                itemCount: showSearchSkeleton ? 3 : latestSearchEpisodes.length,
                separatorBuilder: (_, __) => const SizedBox(width: KDesignConstants.spacing16),
                itemBuilder: (context, index) {
                  if (showSearchSkeleton) {
                    return const _LatestEpisodeSkeleton();
                  }

                  final preview = latestSearchEpisodes[index];
                  final isPlaying = _playerService.currentEpisode?.id == preview.episode.id;
                  return _LatestEpisodeCard(
                    preview: preview,
                    onTap: () => _playEpisode(preview),
                    isPlaying: isPlaying,
                  );
                },
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing16),
          ],
          Padding(
            padding: KDesignConstants.paddingMd,
            child: Column(
              children: _searchResults.map((podcast) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: KDesignConstants.spacing12),
                  child: PodcastCard(
                    podcast: podcast,
                    onTap: () => _navigateToPodcastDetail(podcast),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMainContent() {
    final rawTrending = _podcastService.trendingPodcasts;
    final trending = _calmMode.isCalmModeEnabled
        ? _filterCalmPodcasts(rawTrending)
        : rawTrending;
    final topRated = _getTopRatedPodcasts(trending);
    final freshPicks = _getFreshPicks(trending);
    final editorsPicks = _getEditorsPicks(trending);
    final followedLatest = _getLatestFromFollowed();
    final focusMix = _buildFocusMix();
    final topics = _getTopTopics(trending);
    final publishers = _getTopPublishers(trending);
    final personalized = _personalizedRecommendations;
    final hasCoreContent = trending.isNotEmpty ||
        topRated.isNotEmpty ||
        freshPicks.isNotEmpty ||
        editorsPicks.isNotEmpty ||
        followedLatest.isNotEmpty ||
        topics.isNotEmpty ||
        publishers.isNotEmpty ||
        personalized.isNotEmpty ||
        _latestEpisodes.isNotEmpty ||
        _recentlyPlayed.isNotEmpty ||
        _playerService.hasEpisode;

    if (_isBootstrapping && trending.isEmpty) {
      return [
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing8)),
        SliverToBoxAdapter(
          child: Padding(
            padding: KDesignConstants.paddingHorizontalMd,
            child: Column(
              children: List.generate(
                5,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: KDesignConstants.spacing12),
                  child: ShimmerLoading(
                    child: Container(
                      height: 104,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                        borderRadius: KBorderRadius.xl,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ];
    }

    final effectiveError = _initialLoadError ?? _podcastService.error;
    if (effectiveError != null && !hasCoreContent) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: KDesignConstants.paddingXl,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: KDesignConstants.paddingLg,
                    decoration: BoxDecoration(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing24),
                  Text(
                    'Unable to load podcasts',
                    style: KAppTextStyles.titleLarge.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing8),
                  Text(
                    'Pull to refresh or try again.',
                    textAlign: TextAlign.center,
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing24),
                  ElevatedButton.icon(
                    onPressed: _refreshPodcasts,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KAppColors.getPrimary(context),
                      foregroundColor: KAppColors.getOnPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    if (!hasCoreContent) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: KDesignConstants.paddingXl,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: KDesignConstants.paddingLg,
                    decoration: BoxDecoration(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.podcasts,
                      size: 64,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing24),
                  Text(
                    'No podcasts yet',
                    style: KAppTextStyles.titleLarge.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing8),
                  Text(
                    'Try searching for a show or check back soon.',
                    textAlign: TextAlign.center,
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _showSearch = true),
                    icon: const Icon(Icons.search),
                    label: const Text('Search Podcasts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KAppColors.getPrimary(context),
                      foregroundColor: KAppColors.getOnPrimary(context),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    if (trending.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: KDesignConstants.paddingXl,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: KDesignConstants.paddingLg,
                    decoration: BoxDecoration(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.podcasts,
                      size: 64,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing24),
                  Text(
                    'No podcasts available',
                    style: KAppTextStyles.titleLarge.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing8),
                  Text(
                    'Try searching for your favorite podcasts',
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _showSearch = true),
                    icon: const Icon(Icons.search),
                    label: const Text('Search Podcasts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KAppColors.getPrimary(context),
                      foregroundColor: KAppColors.getOnPrimary(context),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return [
      _buildHeroCarousel(trending),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      if (freshPicks.isNotEmpty) ...[
        _buildSectionHeader(
          'New Releases',
          Icons.fiber_new,
          subtitle: 'Fresh episodes and rising shows',
          actionLabel: 'See all',
        ),
        _buildPodcastRail(freshPicks),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ],
      _buildSectionHeader(
        'Top Charts',
        Icons.leaderboard_outlined,
        subtitle: 'Most-listened podcasts right now',
        actionLabel: 'See all',
      ),
      _buildPodcastRail(trending),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      if (editorsPicks.isNotEmpty) ...[
        _buildSectionHeader(
          'New & Noteworthy',
          Icons.workspace_premium_outlined,
          subtitle: 'Editorial picks with strong engagement',
          actionLabel: 'See all',
        ),
        _buildPodcastRail(editorsPicks),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ],
      if (editorsPicks.isNotEmpty || freshPicks.isNotEmpty) ...[
        _buildSectionHeader(
          'Recommended For You',
          Icons.recommend,
          subtitle: 'Curated based on your listening patterns',
          actionLabel: 'See all',
        ),
        _buildPodcastRail(editorsPicks.isNotEmpty ? editorsPicks : freshPicks),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ],
      if (personalized.isNotEmpty || _isLoadingRecommendations) ...[
        _buildSectionHeader(
          'For You',
          Icons.auto_awesome,
          subtitle: 'Personalized suggestions from the backend',
          actionLabel: 'See all',
        ),
        _isLoadingRecommendations
            ? const SliverToBoxAdapter(
                child: Padding(
                  padding: KDesignConstants.paddingMd,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : _buildPodcastRail(personalized),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ],
      _buildSectionHeader(
        'Trending by ${_selectedCategory == 'All' ? 'Category' : _selectedCategory}',
        Icons.trending_up,
        subtitle: 'Live category momentum',
        actionLabel: 'See all',
      ),
      _buildPodcastRail(trending),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      if (topRated.isNotEmpty) ...[
        _buildSectionHeader(
          'Top Podcasts',
          Icons.star,
          subtitle: 'Highest quality based on ratings',
          actionLabel: 'See all',
        ),
        _buildPodcastRail(topRated),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ],
      _buildSectionHeader(
        'Browse Categories',
        Icons.category_outlined,
        subtitle: 'Jump into a topic quickly',
        actionLabel: 'See all',
      ),
      _buildCategoryBoxes(),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      if (topics.isNotEmpty) ...[
        _buildSectionHeader(
          'Topics',
          Icons.tag,
          subtitle: 'Popular tags across shows',
          actionLabel: 'See all',
        ),
        _buildTopicBoxes(topics),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ],
      if (publishers.isNotEmpty) ...[
        _buildSectionHeader(
          'Publishers',
          Icons.account_circle,
          subtitle: 'Producers with the most active catalogs',
          actionLabel: 'See all',
        ),
        _buildPublisherRail(
          _calmMode.isCalmModeEnabled ? _filterCalmPublishers(publishers) : publishers,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ],
      if (followedLatest.isNotEmpty) ...[
        _buildSectionHeader(
          'From Your Follows',
          Icons.favorite_border,
          subtitle: 'Latest drops from publishers you follow',
          actionLabel: 'See all',
        ),
        _buildLatestEpisodesRail(episodes: followedLatest),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ] else if (_followedService.followedPublisherNames.isNotEmpty) ...[
        _buildSectionHeader(
          'From Your Follows',
          Icons.favorite_border,
          subtitle: 'Latest drops from publishers you follow',
        ),
        _buildEmptySectionCard(
          icon: Icons.favorite_border,
          title: 'No recent episodes yet',
          subtitle: 'We will show the latest episodes from publishers you follow here.',
        ),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ] else ...[
        _buildSectionHeader(
          'From Your Follows',
          Icons.favorite_border,
          subtitle: 'Latest drops from publishers you follow',
        ),
        _buildEmptySectionCard(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Follow publishers to personalize',
          subtitle: 'Follow your favorite publishers to get their latest episodes here.',
        ),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ],
      if (focusMix.isNotEmpty) ...[
        _buildSectionHeader(
          'Focus Mix',
          Icons.spa_outlined,
          subtitle: 'A calm 15-20 minute sequence',
        ),
        _buildLatestEpisodesRail(episodes: focusMix),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ],
      if (_latestEpisodes.isNotEmpty || _isLoadingLatestEpisodes) ...[
        _buildSectionHeader(
          'Recently Added Episodes',
          Icons.schedule,
          subtitle: 'Newest episodes from your feed sources',
          actionLabel: 'See all',
        ),
        _buildLatestEpisodesRail(
          episodes: _calmMode.isCalmModeEnabled
              ? _latestEpisodes.where((preview) => !_isCalmExcludedEpisode(preview)).toList()
              : _latestEpisodes,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ],
      if (_recentlyPlayed.isNotEmpty || _isLoadingRecentlyPlayed) ...[
        _buildSectionHeader(
          'Recently Played',
          Icons.history,
          subtitle: 'Resume podcasts you started recently',
        ),
        _isLoadingRecentlyPlayed
            ? const SliverToBoxAdapter(
                child: Padding(
                  padding: KDesignConstants.paddingMd,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : _buildPodcastRail(_recentlyPlayed),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ] else ...[
        _buildSectionHeader(
          'Recently Played',
          Icons.history,
          subtitle: 'Resume podcasts you started recently',
        ),
        _buildEmptySectionCard(
          icon: Icons.headphones_outlined,
          title: 'No listening history yet',
          subtitle: 'Play an episode to build your listening history.',
        ),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ],
      if (_playerService.hasEpisode) ...[
      _buildSectionHeader(
          'Continue Listening',
          Icons.play_circle_outline,
          subtitle: 'Pick up exactly where you left off',
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: KDesignConstants.paddingHorizontalMd,
            child: _buildContinueListeningCard(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing4)),
    ];
  }

  List<Podcast> _getTopRatedPodcasts(List<Podcast> podcasts) {
    final rated = podcasts.where((p) => p.rating != null).toList();
    rated.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return rated.take(12).toList();
  }

  String _dailySeedKey(String label) {
    final day = DateFormat('yyyyMMdd').format(DateTime.now());
    final userId = widget.user.userId;
    return '$label-$day-$userId';
  }

  List<Podcast> _seededShuffle(List<Podcast> podcasts, String seedKey) {
    final seed = seedKey.hashCode;
    final random = Random(seed);
    final list = List<Podcast>.from(podcasts);
    for (int i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return list;
  }

  List<Podcast> _getFreshPicks(List<Podcast> podcasts) {
    final key = '${_dailySeedKey('fresh')}|${podcasts.map((p) => p.id).join('|')}';
    if (_freshPicksKey == key && _freshPicksCache.isNotEmpty) {
      return _freshPicksCache;
    }

    final picks = _seededShuffle(podcasts, _dailySeedKey('fresh'));
    _freshPicksCache = picks.take(12).toList();
    _freshPicksKey = key;
    return _freshPicksCache;
  }

  List<Podcast> _getEditorsPicks(List<Podcast> podcasts) {
    final key = '${_dailySeedKey('editors')}|${podcasts.map((p) => p.id).join('|')}';
    if (_editorsPicksKey == key && _editorsPicksCache.isNotEmpty) {
      return _editorsPicksCache;
    }

    final picks = podcasts.where((p) => p.rating != null && p.totalEpisodes >= 50).toList();
    picks.sort((a, b) {
      final ratingDiff = (b.rating ?? 0).compareTo(a.rating ?? 0);
      if (ratingDiff != 0) return ratingDiff;
      return b.totalEpisodes.compareTo(a.totalEpisodes);
    });

    final fallback = podcasts.where((p) => p.totalEpisodes >= 30).toList();
    fallback.sort((a, b) => b.totalEpisodes.compareTo(a.totalEpisodes));
    final combined = (picks + fallback).toSet().toList();
    final shuffled = _seededShuffle(combined, _dailySeedKey('editors'));
    _editorsPicksCache = shuffled.take(12).toList();
    _editorsPicksKey = key;
    return _editorsPicksCache;
  }

  List<_EpisodePreview> _getLatestFromFollowed() {
    final followed = _followedService.followedPublisherNames;
    if (followed.isEmpty) return [];
    final previews = _latestEpisodes.where((preview) {
      if (!followed.contains(preview.podcast.publisher)) return false;
      if (_calmMode.isCalmModeEnabled && _isCalmExcludedEpisode(preview)) {
        return false;
      }
      return true;
    }).toList();
    return previews.take(8).toList();
  }

  List<_EpisodePreview> _buildFocusMix() {
    const minSeconds = 900;
    const maxSeconds = 1200;
    final followed = _followedService.followedPublisherNames;
    List<_EpisodePreview> candidates = _latestEpisodes
        .where((preview) => preview.episode.durationSeconds > 0)
        .where((preview) {
          if (followed.isNotEmpty &&
              !followed.contains(preview.podcast.publisher)) {
            return false;
          }
          if (_calmMode.isCalmModeEnabled && _isCalmExcludedEpisode(preview)) {
            return false;
          }
          return true;
        })
        .toList();

    if (candidates.isEmpty) {
      candidates = _latestEpisodes
          .where((preview) => preview.episode.durationSeconds > 0)
          .where((preview) {
            if (_calmMode.isCalmModeEnabled && _isCalmExcludedEpisode(preview)) {
              return false;
            }
            return true;
          })
          .toList();
    }
    if (candidates.isEmpty) return [];

    candidates.sort(
      (a, b) => a.episode.publishedDate.compareTo(b.episode.publishedDate),
    );

    final mix = <_EpisodePreview>[];
    int total = 0;
    for (final preview in candidates) {
      final duration = preview.episode.durationSeconds;
      if (total + duration > maxSeconds && mix.isNotEmpty) continue;
      mix.add(preview);
      total += duration;
      if (total >= minSeconds) break;
    }
    return mix.take(6).toList();
  }

  bool _isCalmExcludedEpisode(_EpisodePreview preview) {
    final categories = preview.podcast.categories
        .map((c) => c.toLowerCase())
        .toList();
    final doomCategories = {
      'true crime',
      'crime',
      'war',
      'conflict',
      'violence',
      'politics',
      'breaking',
    };
    if (categories.any(doomCategories.contains)) return true;

    final combinedText =
        '${preview.podcast.title} ${preview.episode.title}'.toLowerCase();
    final doomKeywords = [
      'crisis',
      'disaster',
      'catastrophe',
      'tragedy',
      'death',
      'killed',
      'murder',
      'attack',
      'war',
      'violence',
      'crash',
      'collapse',
      'destruction',
      'terror',
      'panic',
      'fear',
      'threat',
      'danger',
      'warning',
      'emergency',
      'outbreak',
      'epidemic',
      'pandemic',
    ];
    for (final keyword in doomKeywords) {
      if (combinedText.contains(keyword)) return true;
    }
    return false;
  }

  List<Podcast> _filterCalmPodcasts(List<Podcast> podcasts) {
    final doomCategories = {
      'true crime',
      'crime',
      'war',
      'conflict',
      'violence',
      'politics',
      'breaking',
    };
    final doomKeywords = [
      'crisis',
      'disaster',
      'catastrophe',
      'tragedy',
      'death',
      'killed',
      'murder',
      'attack',
      'war',
      'violence',
      'crash',
      'collapse',
      'destruction',
      'terror',
      'panic',
      'fear',
      'threat',
      'danger',
      'warning',
      'emergency',
      'outbreak',
      'epidemic',
      'pandemic',
    ];

    return podcasts.where((podcast) {
      final categories = podcast.categories.map((c) => c.toLowerCase()).toList();
      if (categories.any(doomCategories.contains)) return false;
      final combinedText =
          '${podcast.title} ${podcast.description}'.toLowerCase();
      for (final keyword in doomKeywords) {
        if (combinedText.contains(keyword)) return false;
      }
      return true;
    }).toList();
  }

  List<_PublisherInfo> _filterCalmPublishers(List<_PublisherInfo> publishers) {
    if (!_calmMode.isCalmModeEnabled) return publishers;
    final doomKeywords = [
      'crime',
      'war',
      'violence',
      'breaking',
      'politics',
    ];
    return publishers.where((publisher) {
      final name = publisher.name.toLowerCase();
      return !doomKeywords.any(name.contains);
    }).toList();
  }

  List<String> _getTopTopics(List<Podcast> podcasts) {
    final counts = <String, int>{};
    for (final podcast in podcasts) {
      for (final category in podcast.categories) {
        if (category.trim().isEmpty) continue;
        final key = category.trim();
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).take(12).toList();
  }

  List<_PublisherInfo> _getTopPublishers(List<Podcast> podcasts) {
    final publisherMap = <String, _PublisherInfo>{};
    for (final podcast in podcasts) {
      final name = podcast.publisher.trim();
      if (name.isEmpty) continue;
      if (!publisherMap.containsKey(name)) {
        publisherMap[name] = _PublisherInfo(
          name: name,
          imageUrl: podcast.imageUrl,
          count: 1,
        );
      } else {
        final existing = publisherMap[name]!;
        publisherMap[name] = _PublisherInfo(
          name: existing.name,
          imageUrl: existing.imageUrl ?? podcast.imageUrl,
          count: existing.count + 1,
        );
      }
    }
    final publishers = publisherMap.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return publishers.take(12).toList();
  }

  Widget _buildHeroCarousel(List<Podcast> podcasts) {
    final heroItems = podcasts.take(5).toList();
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 272,
        child: Column(
          children: [
            SizedBox(
              height: 232,
              child: PageView.builder(
                controller: _heroController,
                itemCount: heroItems.length,
                onPageChanged: (index) => setState(() => _heroIndex = index),
                itemBuilder: (context, index) {
                  final podcast = heroItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: KDesignConstants.spacing12),
                    child: GestureDetector(
                      onTap: () => _navigateToPodcastDetail(podcast),
                      child: ClipRRect(
                        borderRadius: KBorderRadius.xl,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (podcast.imageUrl?.isNotEmpty ?? false)
                              SafeNetworkImage(
                                podcast.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                                  child: Icon(
                                    Icons.podcasts,
                                    size: 64,
                                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                                  ),
                                ),
                              )
                            else
                              Container(
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                                child: Icon(
                                  Icons.podcasts,
                                  size: 64,
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    KAppColors.imageScrim.withValues(alpha: 0.65),
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
                                  if (podcast.publisher.isNotEmpty)
                                    Text(
                                      podcast.publisher,
                                      style: KAppTextStyles.labelMedium.copyWith(
                                        color: KAppColors.onImage.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: KDesignConstants.spacing4),
                                  Text(
                                    podcast.title,
                                    style: KAppTextStyles.titleLarge.copyWith(
                                      color: KAppColors.onImage,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: KDesignConstants.spacing8),
                                  Row(
                                    children: [
                                      if (podcast.categories.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: KAppColors.imageScrim.withValues(alpha: 0.2),
                                            borderRadius: KBorderRadius.full,
                                          ),
                                          child: Text(
                                            podcast.categories.first,
                                            style: KAppTextStyles.labelSmall.copyWith(
                                              color: KAppColors.onImage,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: KAppColors.imageScrim.withValues(alpha: 0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          color: KAppColors.onImage,
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
                  );
                },
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(heroItems.length, (index) {
                final isActive = index == _heroIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: isActive ? 18 : 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? KAppColors.getPrimary(context)
                        : KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                    borderRadius: KBorderRadius.full,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodcastRail(List<Podcast> podcasts) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 224,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: KDesignConstants.paddingHorizontalMd,
          itemCount: podcasts.length,
          itemBuilder: (context, index) {
            final podcast = podcasts[index];
            return Padding(
              padding: const EdgeInsets.only(right: KDesignConstants.spacing16),
              child: SizedBox(
                width: 170,
                child: PodcastCard(
                  podcast: podcast,
                  compact: true,
                  onTap: () => _navigateToPodcastDetail(podcast),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptySectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: KDesignConstants.paddingMd,
        child: Container(
          padding: KDesignConstants.paddingLg,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
                  borderRadius: KBorderRadius.md,
                ),
                child: Icon(
                  icon,
                  color: KAppColors.getPrimary(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestEpisodesRail({List<_EpisodePreview>? episodes}) {
    final list = episodes ?? _latestEpisodes;
    if (_isLoadingLatestEpisodes && _latestEpisodes.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: KDesignConstants.paddingMd,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 224,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: KDesignConstants.paddingHorizontalMd,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: KDesignConstants.spacing12),
          itemBuilder: (context, index) {
            final preview = list[index];
            final isPlaying = _playerService.currentEpisode?.id == preview.episode.id;
            return _LatestEpisodeCard(
              preview: preview,
              onTap: () => _playEpisode(preview),
              isPlaying: isPlaying,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryBoxes() {
    final categories = _getCategories();
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: KDesignConstants.paddingHorizontalMd,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: KDesignConstants.spacing8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final color = _boxColor(category['name'] as String);
            return _CategoryBox(
              label: category['name'] as String,
              icon: category['icon'] as IconData,
              color: color,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PodcastCategoryPage(
                      title: category['name'] as String,
                      category: category['name'] as String,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopicBoxes(List<String> topics) {
    final visible = topics.take(12).toList();
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: KDesignConstants.paddingHorizontalMd,
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(width: KDesignConstants.spacing8),
          itemBuilder: (context, index) {
            final topic = visible[index];
            final color = _boxColor(topic);
            return _CategoryBox(
              label: topic,
              icon: Icons.tag,
              color: color,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PodcastCategoryPage(
                      title: topic,
                      category: topic,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _boxColor(String key) {
    final palette = [
      KAppColors.getPrimary(context),
      KAppColors.getSecondary(context),
      KAppColors.getTertiary(context),
      KAppColors.cyan,
      KAppColors.orange,
      KAppColors.pink,
      KAppColors.green,
      KAppColors.purple,
      KAppColors.yellow,
      KAppColors.red,
    ];
    final index = key.hashCode.abs() % palette.length;
    return palette[index];
  }





  Widget _buildPublisherRail(List<_PublisherInfo> publishers) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: KDesignConstants.paddingHorizontalMd,
          itemCount: publishers.length,
          separatorBuilder: (_, __) => const SizedBox(width: KDesignConstants.spacing16),
          itemBuilder: (context, index) {
            final publisher = publishers[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PodcastPublisherPage(
                      publisherName: publisher.name,
                      publisherImageUrl: publisher.imageUrl,
                    ),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  (publisher.imageUrl?.isNotEmpty ?? false)
                      ? SafeNetworkImage(
                          publisher.imageUrl,
                          width: 56,
                          height: 56,
                          isCircular: true,
                          contentType: ImageContentType.podcast,
                        )
                      : CircleAvatar(
                          radius: 28,
                          backgroundColor: KAppColors.getPrimary(context).withValues(alpha: 0.15),
                          child: Text(
                            publisher.name.characters.first.toUpperCase(),
                            style: KAppTextStyles.titleMedium.copyWith(
                              color: KAppColors.getPrimary(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  const SizedBox(height: KDesignConstants.spacing8),
                  SizedBox(
                    width: 90,
                    child: Text(
                      publisher.name,
                      style: KAppTextStyles.labelMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KDesignConstants.spacing16,
          KDesignConstants.spacing10,
          KDesignConstants.spacing16,
          KDesignConstants.spacing6,
         ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
                    borderRadius: KBorderRadius.md,
                  ),
                  child: Icon(
                    icon,
                    color: KAppColors.getPrimary(context),
                    size: 15,
                  ),
                ),
                const SizedBox(width: KDesignConstants.spacing10),
                Expanded(
                  child: Text(
                    title,
                    style: KAppTextStyles.titleMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (actionLabel != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      actionLabel,
                      style: KAppTextStyles.labelMedium.copyWith(
                        color: KAppColors.getPrimary(context).withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            if (subtitle != null && subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const SizedBox(width: 36),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.58),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Divider(
              thickness: 1,
              height: 1,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KDesignConstants.spacing16,
        KDesignConstants.spacing8,
        KDesignConstants.spacing16,
        KDesignConstants.spacing12,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
              borderRadius: KBorderRadius.md,
            ),
            child: Icon(
              icon,
              color: KAppColors.getPrimary(context),
              size: 18,
            ),
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: Text(
              title,
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueListeningCard() {
    final episode = _playerService.currentEpisode;
    final podcast = _playerService.currentPodcast;
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KAppColors.getPrimary(context).withValues(alpha: 0.1),
            KAppColors.getPrimary(context).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_filled,
            size: 48,
            color: KAppColors.getPrimary(context),
          ),
          const SizedBox(width: KDesignConstants.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode?.title ?? 'Resume Playback',
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: KDesignConstants.spacing4),
                Text(
                  podcast?.title ?? 'Continue where you left off',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPodcastDetail(Podcast podcast) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PodcastDetailPage(podcast: podcast),
      ),
    );
  }
}



class _EpisodePreview {
  final Episode episode;
  final Podcast podcast;

  _EpisodePreview({
    required this.episode,
    required this.podcast,
  });
}

class _LatestEpisodeCard extends StatelessWidget {
  const _LatestEpisodeCard({
    required this.preview,
    required this.onTap,
    required this.isPlaying,
  });

  final _EpisodePreview preview;
  final VoidCallback onTap;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final podcast = preview.podcast;
    final episode = preview.episode;
    final imageUrl = episode.imageUrl ?? podcast.imageUrl;

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
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                    podcast.title,
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
                          episode.title,
                          style: KAppTextStyles.bodyMedium.copyWith(
                            color: KAppColors.onImage,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isPlaying)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: KAppColors.success.withValues(alpha: 0.2),
                            borderRadius: KBorderRadius.full,
                          ),
                          child: Text(
                            'NOW',
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: KAppColors.success,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        )
                      else
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
                          _formatEpisodeMeta(episode),
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

class _LatestEpisodeSkeleton extends StatelessWidget {
  const _LatestEpisodeSkeleton();

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

class _PublisherInfo {
  final String name;
  final String? imageUrl;
  final int count;

  _PublisherInfo({
    required this.name,
    required this.imageUrl,
    required this.count,
  });
}

class _CategoryBox extends StatelessWidget {
  const _CategoryBox({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: 0.16);
    final border = color.withValues(alpha: 0.35);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: KBorderRadius.lg,
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(
            horizontal: KDesignConstants.spacing12,
            vertical: KDesignConstants.spacing12,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: KBorderRadius.lg,
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  borderRadius: KBorderRadius.md,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing8),
              Text(
                label,
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}
