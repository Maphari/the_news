import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/explore_service.dart';
import 'package:the_news/view/social/add_to_list_helper.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class TopStoriesSection extends StatefulWidget {
  const TopStoriesSection({
    super.key,
    this.showHeader = true,
    this.userId,
    this.preloadedStories,
  });

  final bool showHeader;
  final String? userId;
  final List<ArticleModel>? preloadedStories;

  @override
  State<TopStoriesSection> createState() => _TopStoriesSectionState();
}

class _TopStoriesSectionState extends State<TopStoriesSection> {
  final ExploreService _exploreService = ExploreService.instance;
  final PageController _pageController = PageController(viewportFraction: 0.9);

  List<ArticleModel> _stories = const [];
  bool _isLoading = true;
  int _currentPage = 0;
  double _pageValue = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_handlePageScroll);
    final preloaded = widget.preloadedStories;
    if (preloaded != null) {
      _stories = preloaded;
      _isLoading = false;
      _startAutoPlay();
    } else {
      _loadTopStories();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.removeListener(_handlePageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageScroll() {
    final page = _pageController.page ?? _currentPage.toDouble();
    if ((page - _pageValue).abs() < 0.001 || !mounted) return;
    setState(() {
      _pageValue = page;
    });
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_stories.length <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % _stories.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  Future<void> _loadTopStories() async {
    final stories = await _exploreService.getTopStories(
      userId: widget.userId,
      limit: 5,
    );

    if (!mounted) return;
    setState(() {
      _stories = stories;
      _isLoading = false;
      _currentPage = 0;
      _pageValue = 0;
    });
    _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: KDesignConstants.paddingHorizontalMd,
        child: Container(
          height: 340,
          decoration: BoxDecoration(
            color: KAppColors.getSurface(context),
            borderRadius: KBorderRadius.xl,
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.12),
            ),
          ),
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(
              KAppColors.getPrimary(context),
            ),
          ),
        ),
      );
    }

    if (_stories.isEmpty) {
      return Padding(
        padding: KDesignConstants.paddingHorizontalMd,
        child: Container(
          padding: KDesignConstants.cardPadding,
          decoration: BoxDecoration(
            color: KAppColors.getSurface(context),
            borderRadius: KBorderRadius.xl,
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            'Top stories are updating. Please check again.',
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.68),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: KDesignConstants.paddingHorizontalMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader)
            Padding(
              padding: const EdgeInsets.only(bottom: KDesignConstants.spacing8),
              child: Text(
                'Top Stories',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Listener(
            onPointerDown: (_) => _stopAutoPlay(),
            onPointerUp: (_) => _startAutoPlay(),
            onPointerCancel: (_) => _startAutoPlay(),
            child: SizedBox(
              height: 340,
              child: PageView.builder(
                controller: _pageController,
                padEnds: false,
                itemCount: _stories.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final delta = (index - _pageValue).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(right: KDesignConstants.spacing8),
                    child: _TopStoryCarouselCard(
                      article: _stories[index],
                      rank: index + 1,
                      userId: widget.userId,
                      parallaxDelta: delta,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_stories.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: isActive
                      ? KAppColors.getPrimary(context)
                      : KAppColors.getOnBackground(context).withValues(alpha: 0.25),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TopStoryCarouselCard extends StatelessWidget {
  const _TopStoryCarouselCard({
    required this.article,
    required this.rank,
    required this.parallaxDelta,
    this.userId,
  });

  final ArticleModel article;
  final int rank;
  final String? userId;
  final double parallaxDelta;

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final shift = math.max(-1.0, math.min(1.0, parallaxDelta)) * 12;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: KBorderRadius.xl,
        onTap: () {
          AppRoutes.navigateTo(
            context,
            AppRoutes.articleDetail,
            arguments: article,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: KAppColors.getSurface(context),
            borderRadius: KBorderRadius.xl,
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(KDesignConstants.radiusXl),
                  topRight: Radius.circular(KDesignConstants.radiusXl),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 170,
                      child: Transform.translate(
                        offset: Offset(shift, 0),
                        child: article.imageUrl != null
                            ? SafeNetworkImage(
                                article.imageUrl!,
                                width: double.infinity,
                                height: 170,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: double.infinity,
                                height: 170,
                                color: KAppColors.getPrimary(context)
                                    .withValues(alpha: 0.12),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.article_outlined,
                                  size: 40,
                                  color: KAppColors.getPrimary(context),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: KAppColors.getBackground(context)
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#$rank',
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: KDesignConstants.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: KAppTextStyles.titleMedium.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: KDesignConstants.spacing6),
                      Text(
                        article.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context)
                              .withValues(alpha: 0.65),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${article.sourceName} • ${_getTimeAgo(article.pubDate)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KAppTextStyles.bodySmall.copyWith(
                                color: KAppColors.getOnBackground(context)
                                    .withValues(alpha: 0.58),
                              ),
                            ),
                          ),
                          if (userId != null && userId!.isNotEmpty)
                            IconButton(
                              constraints: const BoxConstraints.tightFor(
                                width: 32,
                                height: 32,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: 'Add to list',
                              onPressed: () =>
                                  AddToListHelper.showPickerAndAdd(context, article),
                              icon: Icon(
                                Icons.add_circle_outline_rounded,
                                size: 20,
                                color: KAppColors.getPrimary(context),
                              ),
                            )
                          else
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: KAppColors.getOnBackground(context)
                                  .withValues(alpha: 0.5),
                            ),
                        ],
                      ),
                    ],
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
