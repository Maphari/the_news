import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/service/disliked_articles_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';

class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({
    super.key,
    required this.category,
    required this.categoryColor,
    required this.categoryIcon,
  });

  final String category;
  final Color categoryColor;
  final IconData categoryIcon;

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  @override
  Widget build(BuildContext context) {
    final newsProvider = NewsProviderService.instance;
    final dislikedArticles = DislikedArticlesService.instance;
    final isLoading = newsProvider.isLoading;

    // Get articles for this category
    List<ArticleModel> categoryArticles = widget.category.toLowerCase() == 'all'
        ? newsProvider.articles
        : newsProvider.getArticlesByCategory(widget.category.toLowerCase());

    // Filter out disliked articles
    categoryArticles = categoryArticles
        .where((article) => !dislikedArticles.isArticleDisliked(article.articleId))
        .toList();

    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: KAppColors.getBackground(context),
      child: Scaffold(
        backgroundColor: KAppColors.getBackground(context),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header with back button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Back button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Category icon and title
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.categoryColor.withValues(alpha: 0.2),
                                    widget.categoryColor.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: widget.categoryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(
                                widget.categoryIcon,
                                color: widget.categoryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.category,
                                    style: KAppTextStyles.titleLarge.copyWith(
                                      color: KAppColors.getOnBackground(context),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    isLoading
                                        ? 'Loading articles...'
                                        : '${categoryArticles.length} articles',
                                    style: KAppTextStyles.bodySmall.copyWith(
                                      color: Colors.white.withValues(alpha: 0.6),
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

              // Loading state, empty state, or articles
              if (isLoading)
                _buildLoadingState()
              else if (categoryArticles.isEmpty)
                _buildEmptyState()
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _CategoryArticleCard(
                          article: categoryArticles[index],
                          categoryColor: widget.categoryColor,
                          onTap: () {
                            AppRoutes.navigateTo(
                              context,
                              AppRoutes.articleDetail,
                              arguments: categoryArticles[index],
                            );
                          },
                        );
                      },
                      childCount: categoryArticles.length,
                    ),
                  ),
                ),
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
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.categoryColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Loading ${widget.category.toLowerCase()} news...",
                style: TextStyle(
                  color: KAppColors.getOnBackground(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Finding the latest stories",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
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

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.categoryColor.withValues(alpha: 0.15),
                      widget.categoryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.categoryColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  widget.categoryIcon,
                  color: widget.categoryColor,
                  size: 72,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "No ${widget.category.toLowerCase()} articles",
                style: TextStyle(
                  color: KAppColors.getOnBackground(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "We couldn't find any articles in this category.\nTry exploring other categories or check back later.",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryArticleCard extends StatelessWidget {
  const _CategoryArticleCard({
    required this.article,
    required this.categoryColor,
    required this.onTap,
  });

  final ArticleModel article;
  final Color categoryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (article.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: categoryColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Title
                Text(
                  article.title,
                  style: KAppTextStyles.titleLarge.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  article.description,
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Metadata row
                Row(
                  children: [
                    // Source
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.source_outlined,
                            size: 14,
                            color: categoryColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              article.sourceName,
                              style: KAppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Time
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTimeAgo(article.pubDate),
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
