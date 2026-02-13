import 'dart:async';

import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/explore_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/explore/popular_sources_page.dart';
import 'package:the_news/view/explore/widgets/category_grid_section.dart';
import 'package:the_news/view/explore/widgets/explore_search_bar.dart';
import 'package:the_news/view/explore/widgets/for_you_section.dart';
import 'package:the_news/view/explore/widgets/popular_sources_section.dart';
import 'package:the_news/view/explore/widgets/top_stories_section.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';
import 'package:the_news/view/social/add_to_list_helper.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';
import 'package:the_news/view/widgets/section_header.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({
    super.key,
    required this.user,
    this.searchQueryNotifier,
  });

  final RegisterLoginUserSuccessModel user;
  final ValueNotifier<String?>? searchQueryNotifier;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  final ExploreService _exploreService = ExploreService.instance;

  Timer? _searchDebounce;
  String _searchQuery = '';
  bool _isSearching = false;
  List<ArticleModel> _searchResults = const [];
  bool _isSectionsLoading = true;
  List<ArticleModel> _quickBriefs = const [];
  List<ExploreTopicModel> _trendingTopics = const [];
  List<ArticleModel> _topStories = const [];
  List<ArticleModel> _forYou = const [];
  List<PopularSourceModel> _popularSources = const [];

  @override
  void initState() {
    super.initState();
    _loadExploreSections();
    widget.searchQueryNotifier?.addListener(_handleExternalSearch);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    widget.searchQueryNotifier?.removeListener(_handleExternalSearch);
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final normalized = query.trim();
    setState(() {
      _searchQuery = normalized;
    });

    _searchDebounce?.cancel();
    if (normalized.length < 2) {
      setState(() {
        _isSearching = false;
        _searchResults = const [];
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() {
        _isSearching = true;
      });

      final results = await _exploreService.searchArticles(
        query: normalized,
        userId: widget.user.userId,
        limit: 20,
      );

      if (!mounted) return;
      if (_searchQuery != normalized) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  Future<void> _loadExploreSections() async {
    final payload = await _exploreService.getExploreSections(
      userId: widget.user.userId,
      briefsLimit: 8,
      topicsLimit: 10,
    );

    if (!mounted) return;
    setState(() {
      _quickBriefs = payload.quickBriefs;
      _trendingTopics = payload.trendingTopics;
      _topStories = payload.topStories;
      _forYou = payload.forYou;
      _popularSources = payload.popularSources;
      _isSectionsLoading = false;
    });
  }

  void _onTopicTap(String topic) {
    final normalized = topic.trim();
    if (normalized.isEmpty) return;

    _searchController.text = normalized;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: normalized.length),
    );
    _onSearchChanged(normalized);
  }

  void _handleExternalSearch() {
    final query = widget.searchQueryNotifier?.value;
    if (query == null || query.isEmpty) return;
    _searchController.text = query;
    _onSearchChanged(query);
    widget.searchQueryNotifier?.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final Color screenBackgroundColor = KAppColors.getBackground(context);

    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: screenBackgroundColor,
      child: Container(
        color: screenBackgroundColor,
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              MeasuredPinnedHeaderSliver(
                height: HomeHeader.estimatedHeight(
                  title: 'Explore',
                  subtitle: 'Discover stories tuned for clarity and context',
                  bottom: 8,
                  footerHeight: 56,
                  footerSpacing: KDesignConstants.spacing8,
                ),
                child: HomeHeader(
                  title: 'Explore',
                  subtitle: 'Discover stories tuned for clarity and context',
                  showActions: false,
                  bottom: 8,
                  useSafeArea: false,
                  footerSpacing: KDesignConstants.spacing8,
                  footer: SizedBox(
                    height: 56,
                    child: ExploreSearchBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
              ),
              if (_searchQuery.length >= 2)
                ..._buildSearchSlivers()
              else
                ..._buildExploreContent(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSearchSlivers() {
    if (_isSearching) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_searchResults.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 56,
                    color: KAppColors.getOnBackground(context)
                        .withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: KDesignConstants.spacing16),
                  Text(
                    'No matching stories',
                    style: KAppTextStyles.titleMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing8),
                  Text(
                    'Try another keyword, topic, or publisher name.',
                    textAlign: TextAlign.center,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context)
                          .withValues(alpha: 0.62),
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
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Text(
            '${_searchResults.length} results',
            style: KAppTextStyles.labelLarge.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.64),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final article = _searchResults[index];
            return _SearchResultCard(
              article: article,
              userId: widget.user.userId,
            );
          }, childCount: _searchResults.length),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 28)),
    ];
  }

  List<Widget> _buildExploreContent() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: KBorderRadius.xl,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  KAppColors.getPrimary(context).withValues(alpha: 0.14),
                  KAppColors.getTertiary(context).withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.24),
              ),
            ),
            child: Text(
              'Start with Top Stories, then refine your interests with categories and trusted sources.',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.82),
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing20)),
      _buildSectionHeader(
        title: 'Top Stories',
        icon: Icons.auto_awesome_outlined,
        iconColor: KAppColors.orange,
      ),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing10)),
      SliverToBoxAdapter(
        child: TopStoriesSection(
          showHeader: false,
          userId: widget.user.userId,
          preloadedStories: _topStories,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing24)),
      _buildSectionHeader(
        title: 'Quick Briefs',
        icon: Icons.flash_on_outlined,
        iconColor: KAppColors.getPrimary(context),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing10)),
      SliverToBoxAdapter(
        child: _QuickBriefsSection(
          isLoading: _isSectionsLoading,
          briefs: _quickBriefs,
          userId: widget.user.userId,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing24)),
      _buildSectionHeader(
        title: 'Trending Topics',
        icon: Icons.trending_up_rounded,
        iconColor: KAppColors.orange,
      ),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing10)),
      SliverToBoxAdapter(
        child: _TrendingTopicsSection(
          isLoading: _isSectionsLoading,
          topics: _trendingTopics,
          onTopicTap: _onTopicTap,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing24)),
      _buildSectionHeader(
        title: 'Browse Categories',
        icon: Icons.category_outlined,
        iconColor: KAppColors.getTertiary(context),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing10)),
      const CategoryGridSliver(maxItems: 6),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing24)),
      _buildSectionHeader(
        title: 'For You',
        icon: Icons.person,
        iconColor: KAppColors.purple,
      ),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing10)),
      SliverToBoxAdapter(
        child: ForYouSection(
          showHeader: false,
          userId: widget.user.userId,
          preloadedArticles: _forYou,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing24)),
      _buildSectionHeader(
        title: 'Popular Sources',
        icon: Icons.newspaper_outlined,
        iconColor: KAppColors.getSecondary(context),
        actionLabel: 'View All',
        onAction: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PopularSourcesPage(user: widget.user),
            ),
          );
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: KDesignConstants.spacing10)),
      SliverToBoxAdapter(
        child: PopularSourcesSection(
          user: widget.user,
          showHeader: false,
          preloadedSources: _popularSources,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
    ];
  }

  SliverToBoxAdapter _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color iconColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SliverToBoxAdapter(
      child: SectionHeader(
        title: title,
        icon: icon,
        iconColor: iconColor,
        actionLabel: actionLabel,
        onAction: onAction,
        showGradientIcon: true,
        padding: const EdgeInsets.symmetric(
          horizontal: KDesignConstants.spacing16,
          vertical: 0,
        ),
      ),
    );
  }
}

class _QuickBriefsSection extends StatelessWidget {
  const _QuickBriefsSection({
    required this.isLoading,
    required this.briefs,
    required this.userId,
  });

  final bool isLoading;
  final List<ArticleModel> briefs;
  final String userId;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (briefs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16),
        child: Text(
          'No quick briefs available right now.',
          style: KAppTextStyles.bodySmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.62),
          ),
        ),
      );
    }

    return SizedBox(
      height: 136,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16),
        scrollDirection: Axis.horizontal,
        itemCount: briefs.length,
        separatorBuilder: (_, _) => const SizedBox(width: KDesignConstants.spacing10),
        itemBuilder: (context, index) {
          final article = briefs[index];
          return GestureDetector(
            onTap: () {
              AppRoutes.navigateTo(
                context,
                AppRoutes.articleDetail,
                arguments: article,
              );
            },
            child: Container(
              width: 230,
              padding: const EdgeInsets.all(KDesignConstants.spacing12),
              decoration: BoxDecoration(
                color: KAppColors.getSurface(context),
                borderRadius: KBorderRadius.lg,
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                      SizedBox(
                        height: 32,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Text(
                                article.sourceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: KAppTextStyles.bodySmall.copyWith(
                                  color: KAppColors.getOnBackground(context)
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            if (userId.isNotEmpty)
                              IconButton(
                                constraints: const BoxConstraints.tightFor(
                                  width: 28,
                                  height: 28,
                                ),
                                padding: EdgeInsets.zero,
                                tooltip: 'Add to list',
                                onPressed: () =>
                                    AddToListHelper.showPickerAndAdd(context, article),
                                icon: Icon(
                                  Icons.library_add_outlined,
                                  size: 18,
                                  color: KAppColors.getPrimary(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrendingTopicsSection extends StatelessWidget {
  const _TrendingTopicsSection({
    required this.isLoading,
    required this.topics,
    required this.onTopicTap,
  });

  final bool isLoading;
  final List<ExploreTopicModel> topics;
  final ValueChanged<String> onTopicTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 54,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (topics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16),
        child: Text(
          'Topics are updating.',
          style: KAppTextStyles.bodySmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.62),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: topics.map((topic) {
          return ActionChip(
            onPressed: () => onTopicTap(topic.topic),
            label: Text(
              '${topic.topic} (${topic.count})',
              style: KAppTextStyles.labelMedium.copyWith(
                color: KAppColors.getOnBackground(context),
              ),
            ),
            avatar: Icon(
              Icons.search_rounded,
              size: 14,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
            backgroundColor: KAppColors.getSurface(context),
            side: BorderSide(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.12),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.article,
    this.userId,
  });

  final ArticleModel article;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: KDesignConstants.spacing10),
      decoration: BoxDecoration(
        color: KAppColors.getSurface(context),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppRoutes.navigateTo(
              context,
              AppRoutes.articleDetail,
              arguments: article,
            );
          },
          borderRadius: KBorderRadius.lg,
          child: Padding(
            padding: KDesignConstants.cardPaddingCompact,
            child: Row(
              children: [
                if (article.imageUrl != null)
                  ClipRRect(
                    borderRadius: KBorderRadius.md,
                    child: SafeNetworkImage(
                      article.imageUrl!,
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: KDesignConstants.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: KAppTextStyles.titleSmall.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: KDesignConstants.spacing6),
                      Text(
                        article.sourceName,
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context)
                              .withValues(alpha: 0.56),
                        ),
                      ),
                    ],
                  ),
                ),
                if (userId != null && userId!.isNotEmpty)
                  IconButton(
                    tooltip: 'Add to list',
                    onPressed: () => AddToListHelper.showPickerAndAdd(
                      context,
                      article,
                    ),
                    icon: Icon(
                      Icons.library_add_outlined,
                      color: KAppColors.getPrimary(context),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
