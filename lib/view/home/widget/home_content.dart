import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/home_feed_service.dart';
import 'package:the_news/view/social/add_to_list_helper.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';
import 'package:the_news/view/main_scaffold/main_scaffold.dart';
import 'package:the_news/view/home/widget/category_tabs.dart';
import 'package:the_news/controller/home_controller.dart';
import 'package:the_news/view/home/widget/news_card_stack.dart';
import 'package:the_news/view/home/widget/view_toggle_button.dart';
import 'package:intl/intl.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({
    super.key,
    required this.user,
    required this.viewMode,
  });

  final RegisterLoginUserSuccessModel user;
  final ViewMode viewMode;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final HomeFeedService _homeFeedService = HomeFeedService.instance;

  bool _isLoading = true;
  HomeFeedModel? _feed;
  String? _error;
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final model = await _homeFeedService.fetchHomeFeed(userId: widget.user.userId);
    if (!mounted) return;
    if (model == null) {
      setState(() {
        _isLoading = false;
        _error = 'Unable to load personalized feed';
      });
      return;
    }
    setState(() {
      _isLoading = false;
      _feed = model;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: _isLoading
          ? _buildLoadingView()
          : _feed == null
              ? _buildErrorView()
              : widget.viewMode == ViewMode.cardStack
                  ? _buildCardStackView(_feed!)
                  : _buildListView(_feed!),
    );
  }

  Widget _buildLoadingView() => ListView(
        padding: EdgeInsets.zero,
        children: const [
          SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );

  Widget _buildErrorView() => ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Center(child: Text(_error ?? 'No feed available', style: KAppTextStyles.bodyMedium)),
        ],
      );

  Widget _buildCardStackView(HomeFeedModel feed) {
    final stacked = <ArticleModel>[
      feed.hero,
      ...feed.focus,
      ...feed.recommended,
    ];
    final stackItems = stacked.isNotEmpty ? stacked : [feed.hero];
    final filtered = _filterCardArticles(stackItems);

    final media = MediaQuery.of(context);
    final remaining = media.size.height -
        media.padding.vertical -
        kToolbarHeight -
        48;
    final availableHeight = (remaining * 0.72).clamp(320.0, media.size.height - 80.0);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCategoryTabs(),
          const SizedBox(height: KDesignConstants.spacing12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing2),
            child: SizedBox(
              height: availableHeight,
              width: double.infinity,
              child: NewsCardStack(
                news: filtered,
                user: widget.user,
                cardHeight: availableHeight,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  List<ArticleModel> _filterCardArticles(List<ArticleModel> articles) {
    final category = categories[_selectedCategory];
    if (category == 'All') return List.of(articles);

    final normalized = category.toLowerCase();
    final filtered = articles.where((article) {
      return article.category.any(
        (cat) => cat.toLowerCase().contains(normalized),
      );
    }).toList();

    return filtered.isEmpty ? List.of(articles) : filtered;
  }

  Widget _buildListView(HomeFeedModel feed) {
    final focusArticles = feed.focus;
    final recommendedArticles = feed.recommended;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _HomeHeroCard(article: feed.hero, userId: widget.user.userId),
        const SizedBox(height: KDesignConstants.spacing16),
        _buildHomePulse(feed.timestamp),
        const SizedBox(height: KDesignConstants.spacing20),
        if (focusArticles.isNotEmpty)
          _HomeSection(
            title: 'Focus stories',
            child: SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: focusArticles.length,
                separatorBuilder: (_, __) => const SizedBox(width: KDesignConstants.spacing10),
                itemBuilder: (context, index) {
                  final article = focusArticles[index];
                  return _HomeFocusCard(article: article, userId: widget.user.userId);
                },
              ),
            ),
          ),
        if (feed.trendingTopics.isNotEmpty) ...[
          const SizedBox(height: KDesignConstants.spacing20),
          _buildTrendingTopicsSection(feed.trendingTopics),
        ],
        if (recommendedArticles.isNotEmpty) ...[
          const SizedBox(height: KDesignConstants.spacing20),
          _buildEditorSpotlightSection(recommendedArticles),
          const SizedBox(height: KDesignConstants.spacing20),
          _HomeSection(
            title: 'Recommended for you',
            child: Column(
              children: recommendedArticles
                  .map(
                    (article) => Padding(
                      padding: const EdgeInsets.only(bottom: KDesignConstants.spacing12),
                      child: _HomeRecommendedCard(article: article, userId: widget.user.userId),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: KDesignConstants.spacing20),
        _buildExploreCTA(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildHomePulse(DateTime timestamp) {
    final formatted = DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toLocal());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
        borderRadius: KBorderRadius.xl,
        border: Border.all(color: KAppColors.getOnBackground(context).withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_graph_outlined,
            size: 18,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Updated $formatted',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.75),
              ),
            ),
          ),
          Text(
            'Pull to refresh',
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return CategoryTabs(
      selectedCategory: _selectedCategory,
      onCategoryChanged: (index) {
        if (_selectedCategory == index) return;
        setState(() => _selectedCategory = index);
      },
    );
  }

  Widget _buildTrendingTopicsSection(List<HomeFeedTopic> topics) {
    return _HomeSection(
      title: 'Trending now',
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: topics
            .map((topic) => _TrendingTopicChip(topic: topic))
            .toList(),
      ),
    );
  }

  Widget _buildEditorSpotlightSection(List<ArticleModel> recommended) {
    final spotlight = recommended.take(2).toList();
    if (spotlight.isEmpty) return const SizedBox.shrink();
    return _HomeSection(
      title: 'Editor’s spotlight',
      child: Column(
        children: [
          for (var i = 0; i < spotlight.length; i++) ...[
            _EditorSpotlightTile(
              article: spotlight[i],
              userId: widget.user.userId,
            ),
            if (i < spotlight.length - 1) const SizedBox(height: KDesignConstants.spacing12),
          ],
        ],
      ),
    );
  }

  Widget _buildExploreCTA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need more control?',
          style: KAppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: KDesignConstants.spacing8),
        Text(
          'Explore curated topics, sort by briefings, and pull up stories without leaving the feed.',
          style: KAppTextStyles.bodySmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: KDesignConstants.spacing12),
        OutlinedButton.icon(
          onPressed: () => MainScaffold.of(context)?.openExploreWithQuery(''),
          icon: const Icon(Icons.explore_outlined),
          label: const Text('Open Explore'),
        ),
      ],
    );
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: KAppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: KDesignConstants.spacing12),
        child,
      ],
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({required this.article, required this.userId});

  final ArticleModel article;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppRoutes.navigateTo(context, AppRoutes.articleDetail, arguments: article),
      child: Container(
        constraints: const BoxConstraints(minHeight: 220),
        decoration: BoxDecoration(
          borderRadius: KBorderRadius.xl,
          color: KAppColors.getSurface(context),
          border: Border.all(color: KAppColors.getOnBackground(context).withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(KDesignConstants.radiusXl),
                  topRight: Radius.circular(KDesignConstants.radiusXl),
                ),
                child: SafeNetworkImage(article.imageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(KDesignConstants.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: KAppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: KDesignConstants.spacing8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(article.sourceName,
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            )),
                      ),
                      if (userId.isNotEmpty)
                        IconButton(
                          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              AddToListHelper.showPickerAndAdd(context, article),
                          icon: Icon(Icons.add_circle_outline_rounded,
                              color: KAppColors.getPrimary(context)),
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
}

class _HomeFocusCard extends StatelessWidget {
  const _HomeFocusCard({required this.article, required this.userId});

  final ArticleModel article;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppRoutes.navigateTo(context, AppRoutes.articleDetail, arguments: article),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(KDesignConstants.spacing12),
        decoration: BoxDecoration(
          borderRadius: KBorderRadius.lg,
          border: Border.all(color: KAppColors.getOnBackground(context).withValues(alpha: 0.12)),
          color: KAppColors.getSurface(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: KAppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: KDesignConstants.spacing8),
            Text(article.sourceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                )),
          ],
        ),
      ),
    );
  }
}

class _HomeRecommendedCard extends StatelessWidget {
  const _HomeRecommendedCard({required this.article, required this.userId});

  final ArticleModel article;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppRoutes.navigateTo(context, AppRoutes.articleDetail, arguments: article),
      child: Container(
        padding: const EdgeInsets.all(KDesignConstants.spacing12),
        decoration: BoxDecoration(
          borderRadius: KBorderRadius.xl,
          border: Border.all(color: KAppColors.getOnBackground(context).withValues(alpha: 0.12)),
          color: KAppColors.getSurface(context),
        ),
        child: Row(
          children: [
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: KBorderRadius.md,
                child: SafeNetworkImage(article.imageUrl!, width: 72, height: 72, fit: BoxFit.cover),
              ),
            const SizedBox(width: KDesignConstants.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: KAppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: KDesignConstants.spacing6),
                  Text(article.sourceName,
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      )),
                ],
              ),
            ),
            if (userId.isNotEmpty)
              IconButton(
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                padding: EdgeInsets.zero,
                onPressed: () => AddToListHelper.showPickerAndAdd(context, article),
                icon: Icon(Icons.add_circle_outline_rounded, color: KAppColors.getPrimary(context)),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrendingTopicChip extends StatelessWidget {
  const _TrendingTopicChip({required this.topic});

  final HomeFeedTopic topic;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        '${topic.topic} · ${topic.count}',
        style: KAppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
      ),
      backgroundColor: KAppColors.getSurface(context),
      onPressed: () => MainScaffold.of(context)?.openExploreWithQuery(topic.topic),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
    );
  }
}

class _EditorSpotlightTile extends StatelessWidget {
  const _EditorSpotlightTile({
    required this.article,
    required this.userId,
  });

  final ArticleModel article;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: KBorderRadius.lg,
      onTap: () => AppRoutes.navigateTo(context, AppRoutes.articleDetail, arguments: article),
      child: Container(
        padding: const EdgeInsets.all(KDesignConstants.spacing12),
        decoration: BoxDecoration(
          borderRadius: KBorderRadius.lg,
          border: Border.all(color: KAppColors.getOnBackground(context).withValues(alpha: 0.08)),
          color: KAppColors.getSurface(context),
        ),
        child: Row(
          children: [
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: KBorderRadius.md,
                child: SafeNetworkImage(article.imageUrl!, width: 56, height: 56, fit: BoxFit.cover),
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  borderRadius: KBorderRadius.md,
                ),
                child: const Icon(Icons.article_outlined, size: 28),
              ),
            const SizedBox(width: KDesignConstants.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: KDesignConstants.spacing4),
                  Text(
                    article.sourceName,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KDesignConstants.spacing4),
                  Text(
                    'Spotlight pick',
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.getPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (userId.isNotEmpty)
              IconButton(
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                padding: EdgeInsets.zero,
                onPressed: () => AddToListHelper.showPickerAndAdd(context, article),
                icon: Icon(Icons.add_circle_outline_rounded, color: KAppColors.getPrimary(context)),
              ),
          ],
        ),
      ),
    );
  }
}
