import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/service/disliked_articles_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';
import 'widgets/explore_search_bar.dart';
// import 'widgets/trending_topics_section.dart';
import 'widgets/popular_sources_section.dart';
import 'widgets/category_grid_section.dart';
import 'widgets/top_stories_section.dart';
import 'widgets/for_you_section.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key, required this.user});

   final RegisterLoginUserSuccessModel user;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color screenBackgroundColor = KAppColors.getBackground(context);
    final newsProvider = NewsProviderService.instance;
    final isLoading = newsProvider.isLoading;

    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: screenBackgroundColor,
      child: Container(
        color: screenBackgroundColor,
        child: SafeArea(
          bottom: false, //* Don't add bottom padding - MainScaffold has bottom nav
          child: CustomScrollView(
            slivers: [
              // Header with greeting
              SliverToBoxAdapter(
                child: HomeHeader(
                  title: 'Explore',
                  subtitle: 'Discover mindful news & stories',
                  showActions: false,
                  bottom: 5,
                ),
              ),
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ExploreSearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),

              // Show loading, search results, or explore content
              if (isLoading)
                _buildLoadingState()
              else if (_searchQuery.isNotEmpty)
                _buildSearchResults()
              else
                ..._buildExploreContent(),
            ],
          ),
      ),
      ),
    );
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
                "Loading explore content...",
                style: TextStyle(
                  color: KAppColors.getOnBackground(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Discovering stories for you",
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

  List<Widget> _buildExploreContent() {
    return [
      // Trending Topics
      // const SliverToBoxAdapter(child: TrendingTopicsSection()),
      // Bottom spacing
      const SliverToBoxAdapter(child: SizedBox(height: 10)),

      // Category Grid
      const SliverToBoxAdapter(child: CategoryGridSection()),

      // Popular Sources
      const SliverToBoxAdapter(child: PopularSourcesSection()),

      // Top Stories
      const SliverToBoxAdapter(child: TopStoriesSection()),

      // For You Section
      const SliverToBoxAdapter(child: ForYouSection()),

      // Bottom spacing
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ];
  }

  Widget _buildSearchResults() {
    final newsProvider = NewsProviderService.instance;
    final dislikedArticles = DislikedArticlesService.instance;
    final results = newsProvider.articles
        .where(
          (article) =>
              !dislikedArticles.isArticleDisliked(article.articleId) &&
              (article.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              article.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              )),
        )
        .toList();

    if (results.isEmpty) {
      return SliverFillRemaining(
        child: Center(
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
                    Icons.search_off_rounded,
                    size: 64,
                    color: KAppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No results found',
                  style: KAppTextStyles.titleLarge.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Try searching with different keywords\nor explore trending topics below',
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
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

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final article = results[index];
          return _SearchResultCard(article: article);
        }, childCount: results.length),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.article});

  final ArticleModel article;

  Color _getCategoryColor() {
    final category = article.category.toString().toLowerCase();
    switch (category) {
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.15),
          width: 1,
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (article.imageUrl != null)
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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
                              size: 28,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      if (article.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: categoryColor.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            article.category.first.toUpperCase(),
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: categoryColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
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
                      const SizedBox(height: 4),
                      Text(
                        article.sourceName,
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
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
