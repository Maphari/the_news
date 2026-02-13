import 'dart:async';
import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/saved_articles_service.dart';
import 'package:the_news/service/disliked_articles_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/widgets/pill_tab.dart';
import 'package:the_news/view/widgets/app_search_bar.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class SavedPage extends StatefulWidget {
  const SavedPage({super.key, required this.user});

  final RegisterLoginUserSuccessModel user;

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  String _selectedFilter = 'All';
  String _selectedSort = 'Recent';
  final SavedArticlesService _savedArticlesService = SavedArticlesService.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  final List<String> _filters = [
    'All',
    'Technology',
    'Business',
    'Sports',
    'Health',
  ];
  final List<String> _sortOptions = [
    'Recent',
    'Oldest',
    'Source',
  ];

  @override
  void initState() {
    super.initState();
    // Listen to service changes
    _savedArticlesService.addListener(_onSavedArticlesChanged);
    // Load saved articles when page is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestSavedArticles();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _savedArticlesService.removeListener(_onSavedArticlesChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSavedArticlesChanged() {
    if (mounted) {
      setState(() {
        // Rebuild when saved articles change
      });
    }
  }

  Future<void> _requestSavedArticles({bool forceRefresh = false}) async {
    await _savedArticlesService.loadSavedArticles(
      widget.user.userId,
      category: _selectedFilter == 'All' ? null : _selectedFilter,
      search: _searchQuery,
      sort: _selectedSort,
      forceRefresh: forceRefresh,
    );
  }

  void _scheduleSearch(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    setState(() => _searchQuery = query);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _requestSavedArticles();
    });
  }

  List<ArticleModel> _getSavedArticles() {
    final dislikedArticles = DislikedArticlesService.instance;

    // Backend returns already filtered/sorted results; only remove disliked locally.
    List<ArticleModel> savedArticles = _savedArticlesService.savedArticles;

    // Filter out disliked articles
    savedArticles = savedArticles
        .where((article) => !dislikedArticles.isArticleDisliked(article.articleId))
        .toList();

    return savedArticles;
  }

  Widget _buildLoadingState() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated circular progress indicator
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    KAppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing32),
              Text(
                "Loading saved articles...",
                style: TextStyle(
                  color: KAppColors.getOnBackground(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing12),
              Text(
                "Fetching your bookmarked stories",
                style: TextStyle(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _savedArticlesService.isLoading;
    final hasError = _savedArticlesService.error != null;
    final savedArticles = _getSavedArticles();

    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: KAppColors.getBackground(context),
      child: Material(
        color: KAppColors.getBackground(context),
        child: SafeArea(
          bottom: false, // Don't add bottom padding - MainScaffold has bottom nav
          child: CustomScrollView(
            slivers: [
              MeasuredPinnedHeaderSliver(
                height: HomeHeader.estimatedHeight(
                      title: 'Saved',
                      subtitle: isLoading
                          ? 'Loading your saved articles...'
                          : hasError
                              ? 'Using offline data'
                              : '${savedArticles.length} articles saved for later',
                      footerHeight: 56,
                    ),
                child: HomeHeader(
                  title: 'Saved',
                  subtitle: isLoading
                      ? 'Loading your saved articles...'
                      : hasError
                          ? 'Using offline data'
                          : '${savedArticles.length} articles saved for later',
                  useSafeArea: false,
                  footerSpacing: KDesignConstants.spacing8,
                  footer: SizedBox(
                    height: 56,
                    child: AppSearchBar(
                      controller: _searchController,
                      hintText: 'Search news',
                      showClear: true,
                      onChanged: _scheduleSearch,
                    ),
                  ),
                ),
              ),

              // Error Banner (when backend fails but we have cached data)
              if (hasError && savedArticles.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(KDesignConstants.spacing12),
                    decoration: BoxDecoration(
                      color: KAppColors.warning.withValues(alpha: 0.1),
                      borderRadius: KBorderRadius.md,
                      border: Border.all(
                        color: KAppColors.warning.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 20,
                          color: KAppColors.warning,
                        ),
                        const SizedBox(width: KDesignConstants.spacing12),
                        Expanded(
                          child: Text(
                            'Showing offline data. Pull to refresh when online.',
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: KAppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, size: 20, color: KAppColors.warning),
                          onPressed: () {
                            _requestSavedArticles(forceRefresh: true);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),

              // Filter Chips (hide when loading)
              if (!isLoading)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: KDesignConstants.tabHeight,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = filter == _selectedFilter;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: PillTabContainer(
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                              _requestSavedArticles();
                            },
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            borderRadius: KBorderRadius.xl,
                            child: Text(
                              filter,
                              style: KAppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? KAppColors.getOnPrimary(context)
                                    : KAppColors.getOnBackground(context).withValues(alpha: 0.65),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (!isLoading && savedArticles.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SavedSummaryCard(
                            title: 'Saved',
                            value: '${savedArticles.length}',
                            subtitle: savedArticles.isEmpty
                                ? 'No items'
                                : 'Last saved ${timeago.format(savedArticles.first.pubDate)}',
                          ),
                        ),
                        const SizedBox(width: KDesignConstants.spacing12),
                        Expanded(
                          child: _SavedSummaryCard(
                            title: 'Filters',
                            value: _selectedFilter,
                            subtitle: _selectedSort,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!isLoading && savedArticles.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          'Sort by',
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: KDesignConstants.spacing8),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            setState(() {
                              _selectedSort = value;
                            });
                            _requestSavedArticles();
                          },
                          itemBuilder: (context) {
                            return _sortOptions
                                .map(
                                  (option) => PopupMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  ),
                                )
                                .toList();
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: KDesignConstants.spacing12,
                              vertical: KDesignConstants.spacing8,
                            ),
                            decoration: BoxDecoration(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
                              borderRadius: KBorderRadius.md,
                              border: Border.all(
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedSort,
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),)
                      ],
                    ),
                  ),
                ),

              // Loading state, error state, empty state, or articles list
              if (isLoading)
                _buildLoadingState()
              else if (hasError && savedArticles.isEmpty)
                SliverFillRemaining(
                  child: _ErrorState(
                    error: _savedArticlesService.error!,
                    onRetry: () {
                      _requestSavedArticles(forceRefresh: true);
                    },
                  ),
                )
              else if (savedArticles.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(selectedFilter: _selectedFilter),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                    child: _SavedStackList(
                      articles: savedArticles,
                      onTap: (article) {
                        AppRoutes.navigateTo(
                          context,
                          AppRoutes.articleDetail,
                          arguments: article,
                        );
                      },
                      onRemove: (article) async {
                        final success = await _savedArticlesService.unsaveArticle(
                          widget.user.userId,
                          article.articleId,
                        );
                        if (success && mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedStackList extends StatelessWidget {
  const _SavedStackList({
    required this.articles,
    required this.onTap,
    required this.onRemove,
  });

  final List<ArticleModel> articles;
  final ValueChanged<ArticleModel> onTap;
  final ValueChanged<ArticleModel> onRemove;

  @override
  Widget build(BuildContext context) {
    final visible = articles.take(4).toList();
    final remaining = articles.length > visible.length
        ? articles.sublist(visible.length)
        : <ArticleModel>[];
    final height = 220 + (visible.length - 1) * 80;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Highlights',
          style: KAppTextStyles.titleMedium.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: KDesignConstants.spacing12),
        SizedBox(
          height: height.toDouble(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < visible.length; i++)
                _StackedCard(
                  article: visible[i],
                  depth: i,
                  onTap: () => onTap(visible[i]),
                  onRemove: () => onRemove(visible[i]),
                ),
            ],
          ),
        ),
        if (remaining.isNotEmpty) ...[
          const SizedBox(height: KDesignConstants.spacing24),
          Text(
            'More saved',
            style: KAppTextStyles.titleMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          ...remaining.map(
            (article) => _SavedListItem(
              article: article,
              onTap: () => onTap(article),
              onRemove: () => onRemove(article),
            ),
          ),
        ],
      ],
    );
  }
}

class _SavedSummaryCard extends StatelessWidget {
  const _SavedSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing6),
          Text(
            value,
            style: KAppTextStyles.titleLarge.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing4),
          Text(
            subtitle,
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StackedCard extends StatelessWidget {
  const _StackedCard({
    required this.article,
    required this.depth,
    required this.onTap,
    required this.onRemove,
  });

  final ArticleModel article;
  final int depth;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = [
      KAppColors.getSurface(context),
      KAppColors.getSecondary(context).withValues(alpha: 0.08),
      KAppColors.getPrimary(context).withValues(alpha: 0.08),
      KAppColors.getTertiary(context).withValues(alpha: 0.08),
    ];
    final bg = colors[depth % colors.length];
    final offset = 80.0 * depth;
    final tilt = depth == 0 ? 0.0 : (depth.isEven ? -0.03 : 0.03);

    return Positioned(
      top: offset,
      left: 0,
      right: 0,
      child: Transform.rotate(
        angle: tilt,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onRemove,
            borderRadius: KBorderRadius.xxl,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: KBorderRadius.xxl,
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (depth == 0)
                    Row(
                      children: [
                        const Spacer(),
                        InkWell(
                          onTap: onRemove,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: KAppColors.getOnBackground(context)
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.bookmark_remove_outlined,
                              size: 16,
                              color: KAppColors.getOnBackground(context)
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (depth == 0)
                    const SizedBox(height: KDesignConstants.spacing8),
                  Text(
                    article.title,
                    style: KAppTextStyles.titleLarge.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KDesignConstants.spacing8),
                  Text(
                    article.description,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KDesignConstants.spacing12),
                  Row(
                    children: [
                      Icon(
                        Icons.public,
                        size: 16,
                        color: KAppColors.getOnBackground(context)
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: KDesignConstants.spacing8),
                      Expanded(
                        child: Text(
                          article.sourceName,
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context)
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: KDesignConstants.spacing8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: KAppColors.getOnBackground(context)
                              .withValues(alpha: 0.06),
                          borderRadius: KBorderRadius.lg,
                        ),
                        child: Text(
                          timeago.format(article.pubDate),
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context)
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// _SavedArticleCard removed in favor of stacked cards design.

class _SavedListItem extends StatelessWidget {
  const _SavedListItem({
    required this.article,
    required this.onTap,
    required this.onRemove,
  });

  final ArticleModel article;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: KBorderRadius.lg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: KBorderRadius.md,
                  child: SafeNetworkImage(
                    article.imageUrl!,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                    borderRadius: KBorderRadius.md,
                  ),
                  child: Icon(
                    Icons.article_outlined,
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: KAppTextStyles.titleSmall.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.sourceName,
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context)
                            .withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: KAppColors.getOnBackground(context)
                        .withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark_remove_outlined,
                    size: 18,
                    color: KAppColors.getOnBackground(context)
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: KDesignConstants.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: KDesignConstants.paddingLg,
              decoration: BoxDecoration(
                color: KAppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: KAppColors.warning.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: KAppColors.warning.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing24),
            Text(
              'Unable to load saved articles',
              style: KAppTextStyles.titleLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            Text(
              'Check your internet connection and try again.\nYour articles are saved and will sync when you\'re back online.',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KDesignConstants.spacing24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KAppColors.getPrimary(context),
                foregroundColor: KAppColors.getOnPrimary(context),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: KBorderRadius.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.selectedFilter});

  final String selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: KDesignConstants.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: KDesignConstants.paddingLg,
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 64,
                color: KAppColors.getPrimary(context).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing24),
            Text(
              selectedFilter == 'All'
                  ? 'No saved articles yet'
                  : 'No $selectedFilter articles saved',
              style: KAppTextStyles.titleLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            Text(
              selectedFilter == 'All'
                  ? 'Start saving articles to read them later.\nTap the bookmark icon on any article.'
                  : 'You haven\'t saved any $selectedFilter articles yet.\nExplore and bookmark articles to see them here.',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
