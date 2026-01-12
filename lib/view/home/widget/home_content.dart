import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/controller/home_controller.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/calm_mode_service.dart';
import 'package:the_news/service/content_intensity_service.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/service/disliked_articles_service.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/service/location_service.dart';
import 'package:the_news/view/home/breaking_news_page.dart';
import 'package:the_news/view/home/widget/news_card_stack.dart';
import 'package:the_news/view/home/widget/compact_article_list.dart';
import 'package:the_news/view/home/widget/category_tabs.dart';
import 'package:the_news/view/home/widget/breaking_news_card.dart';
import 'package:the_news/view/home/widget/view_toggle_button.dart';
import 'package:intl/intl.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.viewMode,
    required this.user,
  });

  final int selectedCategory;
  final ValueChanged<int> onCategoryChanged;
  final ViewMode viewMode;
  final RegisterLoginUserSuccessModel user;

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM').format(date);
  }

  List<ArticleModel> get filteredNews {
    final calmMode = CalmModeService.instance;
    final intensityFilter = ContentIntensityService.instance;
    final newsProvider = NewsProviderService.instance;
    final dislikedArticles = DislikedArticlesService.instance;
    final followedPublishers = FollowedPublishersService.instance;
    final location = LocationService.instance;

    // First filter by category from news provider (API or database)
    List<ArticleModel> articles;
    if (selectedCategory == 0) {
      articles = newsProvider.articles;
    } else {
      String categoryName = categories[selectedCategory].toLowerCase();
      articles = newsProvider.getArticlesByCategory(categoryName);
    }

    // Filter out disliked articles
    articles = articles
        .where(
          (article) => !dislikedArticles.isArticleDisliked(article.articleId),
        )
        .toList();

    // Apply Calm Mode filter
    articles = calmMode.filterArticles(articles);

    // Apply intensity filter
    articles = intensityFilter.filterArticles(articles);

    // Sort by followed publishers (prioritize articles from followed publishers)
    if (followedPublishers.followedPublisherNames.isNotEmpty) {
      articles.sort((a, b) {
        final aIsFollowed = followedPublishers.isPublisherFollowed(
          a.sourceName,
        );
        final bIsFollowed = followedPublishers.isPublisherFollowed(
          b.sourceName,
        );

        if (aIsFollowed && !bIsFollowed) return -1;
        if (!aIsFollowed && bIsFollowed) return 1;

        // Both followed or both not followed - maintain original order
        return 0;
      });
    }

    // Apply location-based filtering if user has country preferences
    if (location.preferredCountries.isNotEmpty) {
      // Prioritize articles from preferred countries
      articles.sort((a, b) {
        // Check if article has country info (you may need to add this field to ArticleModel)
        // For now, we'll check if the source name or content contains country keywords
        final aMatchesCountry = location.preferredCountries.any(
          (country) =>
              a.sourceName.toLowerCase().contains(country.toLowerCase()) ||
              a.description.toLowerCase().contains(country.toLowerCase()),
        );
        final bMatchesCountry = location.preferredCountries.any(
          (country) =>
              b.sourceName.toLowerCase().contains(country.toLowerCase()) ||
              b.description.toLowerCase().contains(country.toLowerCase()),
        );

        if (aMatchesCountry && !bMatchesCountry) return -1;
        if (!aMatchesCountry && bMatchesCountry) return 1;

        return 0;
      });
    }

    return articles;
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = NewsProviderService.instance;
    final news = filteredNews;
    final isLoading = newsProvider.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Tabs - Content navigation
        CategoryTabs(
          selectedCategory: selectedCategory,
          onCategoryChanged: onCategoryChanged,
        ),
        const SizedBox(height: 8),
        // 5. Main Content - Articles
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: isLoading
                ? _buildLoadingState()
                : news.isEmpty
                ? _buildEmptyState()
                : viewMode == ViewMode.cardStack
                ? NewsCardStack(
                    key: ValueKey('cardstack_$selectedCategory'),
                    news: news,
                    user: user,
                  )
                : news.length > 1
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        // Breaking News Section Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Breaking News',
                                    style: KAppTextStyles.headlineMedium
                                        .copyWith(
                                          color: KAppColors.getOnBackground(
                                            context,
                                          ),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 24,
                                        ),
                                  ),
                                  Text(
                                    _formatDate(DateTime.now()),
                                    style: KAppTextStyles.bodyMedium.copyWith(
                                      color: KAppColors.getOnBackground(
                                        context,
                                      ).withAlpha(128),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BreakingNewsPage(articles: news),
                                    ),
                                  );
                                },
                                child: Text(
                                  'See all',
                                  style: KAppTextStyles.labelLarge.copyWith(
                                    color: KAppColors.getPrimary(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Featured Breaking News Card
                        BreakingNewsCard(article: news.first),
                        const SizedBox(height: 8),
                        // Article List (skip first article as it's shown in breaking news)
                        CompactArticleList(
                          key: ValueKey('list_$selectedCategory'),
                          articles: news.sublist(1),
                        ),
                      ],
                    ),
                  )
                : CompactArticleList(
                    key: ValueKey('list_$selectedCategory'),
                    articles: news,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Builder(
      builder: (context) => Center(
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
                    KAppColors.getTertiary(context),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Loading your news...",
                style: TextStyle(
                  color: KAppColors.getOnBackground(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Fetching the latest stories for you",
                style: TextStyle(
                  color: KAppColors.getOnBackground(
                    context,
                  ).withValues(alpha: 0.6),
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
    return Builder(
      builder: (context) => Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        KAppColors.getTertiary(context).withValues(alpha: 0.15),
                        KAppColors.getTertiary(context).withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KAppColors.getTertiary(
                        context,
                      ).withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.spa_outlined,
                    color: KAppColors.getTertiary(context),
                    size: 72,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Taking a mindful break",
                  style: TextStyle(
                    color: KAppColors.getOnBackground(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "No articles found in ${categories[selectedCategory]}",
                  style: TextStyle(
                    color: KAppColors.getOnBackground(
                      context,
                    ).withValues(alpha: 0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Try exploring other categories or\ncheck back later for fresh content",
                  style: TextStyle(
                    color: KAppColors.getOnBackground(
                      context,
                    ).withValues(alpha: 0.5),
                    fontSize: 13,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
