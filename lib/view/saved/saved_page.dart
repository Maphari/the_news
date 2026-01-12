import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/saved_articles_service.dart';
import 'package:the_news/service/disliked_articles_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key, required this.user});

  final RegisterLoginUserSuccessModel user;

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  String _selectedFilter = 'All';
  final SavedArticlesService _savedArticlesService = SavedArticlesService.instance;

  final List<String> _filters = [
    'All',
    'Technology',
    'Business',
    'Sports',
    'Health',
  ];

  @override
  void initState() {
    super.initState();
    // Listen to service changes
    _savedArticlesService.addListener(_onSavedArticlesChanged);
    // Load saved articles when page is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _savedArticlesService.loadSavedArticles(widget.user.userId);
    });
  }

  @override
  void dispose() {
    _savedArticlesService.removeListener(_onSavedArticlesChanged);
    super.dispose();
  }

  void _onSavedArticlesChanged() {
    if (mounted) {
      setState(() {
        // Rebuild when saved articles change
      });
    }
  }

  List<ArticleModel> _getSavedArticles() {
    final dislikedArticles = DislikedArticlesService.instance;

    // Get saved articles from service (should include full article data from backend)
    List<ArticleModel> savedArticles = _savedArticlesService.savedArticles;

    // Filter out disliked articles
    savedArticles = savedArticles
        .where((article) => !dislikedArticles.isArticleDisliked(article.articleId))
        .toList();

    // Apply category filter if needed
    if (_selectedFilter != 'All') {
      savedArticles = savedArticles
          .where((article) => article.category
              .any((cat) => cat.toLowerCase() == _selectedFilter.toLowerCase()))
          .toList();
    }

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
                    const Color(0xFF4CAF50),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Loading saved articles...",
                style: TextStyle(
                  color: KAppColors.getOnBackground(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
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
      child: Container(
        color: KAppColors.getBackground(context),
        child: SafeArea(
          bottom: false, // Don't add bottom padding - MainScaffold has bottom nav
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: HomeHeader(
                  title: 'Saved',
                  subtitle: isLoading
                      ? 'Loading your saved articles...'
                      : hasError
                          ? 'Using offline data'
                          : '${savedArticles.length} articles saved for later',
                  showActions: false,
                  bottom: 5,
                ),
              ),

              // Error Banner (when backend fails but we have cached data)
              if (hasError && savedArticles.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 20,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Showing offline data. Pull to refresh when online.',
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, size: 20, color: Colors.orange),
                          onPressed: () {
                            _savedArticlesService.loadSavedArticles(widget.user.userId);
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
                    height: 46,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = filter == _selectedFilter;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          KAppColors.primary.withValues(alpha: 0.3),
                                          KAppColors.secondary.withValues(alpha: 0.3),
                                        ],
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? KAppColors.primary.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                filter,
                                style: KAppTextStyles.labelMedium.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.6),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
                      _savedArticlesService.loadSavedArticles(widget.user.userId);
                    },
                  ),
                )
              else if (savedArticles.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(selectedFilter: _selectedFilter),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _SavedArticleCard(
                          article: savedArticles[index],
                          onTap: () {
                            AppRoutes.navigateTo(
                              context,
                              AppRoutes.articleDetail,
                              arguments: savedArticles[index],
                            );
                          },
                          onRemove: () async {
                            // Unsave the article
                            final success = await _savedArticlesService.unsaveArticle(
                              widget.user.userId,
                              savedArticles[index].articleId,
                            );
                            if (success && mounted) {
                              setState(() {
                                // UI will update automatically when service notifies listeners
                              });
                            }
                          },
                        );
                      },
                      childCount: savedArticles.length,
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

class _SavedArticleCard extends StatelessWidget {
  const _SavedArticleCard({
    required this.article,
    required this.onTap,
    required this.onRemove,
  });

  final ArticleModel article;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  Color _getCategoryColor() {
    switch (article.category.toString().toLowerCase()) {
      case 'technology':
        return KAppColors.tertiary;
      case 'business':
        return KAppColors.secondary;
      case 'sports':
        return const Color(0xFFFFC5C9);
      case 'entertainment':
        return const Color(0xFFFFD4A3);
      case 'science':
        return const Color(0xFFC5D9FF);
      case 'health':
        return const Color(0xFFFFB8B8);
      default:
        return KAppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withValues(alpha: 0.08),
            categoryColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Article Image
                if (article.imageUrl != null)
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        article.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  categoryColor.withValues(alpha: 0.1),
                                  categoryColor.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.article_outlined,
                              color: categoryColor.withValues(alpha: 0.4),
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(width: 12),

                // Article Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: categoryColor.withValues(alpha: 0.25),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          article.category.toString(),
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        article.title,
                        style: KAppTextStyles.titleMedium.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Metadata Row
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              article.pubDateTZ,
                              style: KAppTextStyles.bodySmall.copyWith(
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Remove Button
                          InkWell(
                            onTap: onRemove,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.bookmark,
                                size: 16,
                                color: categoryColor,
                              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.withValues(alpha: 0.1),
                    Colors.red.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Colors.orange.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load saved articles',
              style: KAppTextStyles.titleLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Check your internet connection and try again.\nYour articles are saved and will sync when you\'re back online.',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KAppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    KAppColors.primary.withValues(alpha: 0.1),
                    KAppColors.tertiary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: KAppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 64,
                color: KAppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 12),
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
