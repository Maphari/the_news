import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/service/disliked_articles_service.dart';
import 'package:the_news/service/article_recommendations_service.dart';
import 'package:the_news/service/calm_mode_service.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';
import 'package:the_news/view/social/add_to_list_helper.dart';

class ForYouSection extends StatefulWidget {
  const ForYouSection({
    super.key,
    this.showHeader = true,
    this.userId,
    this.preloadedArticles,
  });

  final bool showHeader;
  final String? userId;
  final List<ArticleModel>? preloadedArticles;

  @override
  State<ForYouSection> createState() => _ForYouSectionState();
}

class _ForYouSectionState extends State<ForYouSection> {
  final ArticleRecommendationsService _recommendations =
      ArticleRecommendationsService.instance;
  final NewsProviderService _newsProvider = NewsProviderService.instance;
  final DislikedArticlesService _dislikedArticles = DislikedArticlesService.instance;
  final CalmModeService _calmMode = CalmModeService.instance;

  List<ArticleModel> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedArticles != null) {
      _setArticlesFromPreloaded(widget.preloadedArticles!);
    } else {
      _loadRecommendations();
    }
  }

  void _setArticlesFromPreloaded(List<ArticleModel> preloaded) {
    _articles = preloaded
        .where((article) => !_dislikedArticles.isArticleDisliked(article.articleId))
        .toList();
    if (_calmMode.isCalmModeEnabled) {
      _articles = _calmMode.filterArticles(_articles);
    }
    _isLoading = false;
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    final userId = widget.userId;

    if (userId == null || userId.isEmpty) {
      _setFallbackArticles();
      return;
    }

    final remote = await _recommendations.getRecommendations(
      userId: userId,
      limit: 4,
    );

    if (remote.isNotEmpty) {
      setState(() {
        _articles = remote
            .where((article) =>
                !_dislikedArticles.isArticleDisliked(article.articleId))
            .toList();
        if (_calmMode.isCalmModeEnabled) {
          _articles = _calmMode.filterArticles(_articles);
        }
        _isLoading = false;
      });
      return;
    }

    _setFallbackArticles();
  }

  void _setFallbackArticles() {
    final fallback = _newsProvider.getRecentArticles(limit: 4)
        .where((article) => !_dislikedArticles.isArticleDisliked(article.articleId))
        .toList();
    setState(() {
      _articles = _calmMode.isCalmModeEnabled
          ? _calmMode.filterArticles(fallback)
          : fallback;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: KDesignConstants.paddingHorizontalMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            Row(
              children: [
                Icon(Icons.person, color: KAppColors.purple, size: 24),
                const SizedBox(width: KDesignConstants.spacing8),
                Text(
                  'For You',
                  style: KAppTextStyles.titleLarge.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KDesignConstants.spacing4),
            Text(
              'Based on your activity and interests',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing8),
          ],
          if (_isLoading)
            _buildLoadingState(context)
          else
            ..._articles.map((article) => _ForYouCard(
                  article: article,
                  userId: widget.userId,
                  onTap: () {
                    AppRoutes.navigateTo(
                      context,
                      AppRoutes.articleDetail,
                      arguments: article,
                    );
                  },
                )),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: KDesignConstants.cardPadding,
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                KAppColors.getPrimary(context),
              ),
            ),
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Text(
            'Personalizing your feed...',
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForYouCard extends StatelessWidget {
  const _ForYouCard({
    required this.article,
    required this.onTap,
    this.userId,
  });

  final ArticleModel article;
  final VoidCallback onTap;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: KDesignConstants.spacing12),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: KBorderRadius.xl,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(KDesignConstants.radiusXl),
                  topRight: Radius.circular(KDesignConstants.radiusXl),
                ),
                child: Stack(
                  children: [
                    SafeNetworkImage(
                      article.imageUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                          child: Center(
                            child: Icon(Icons.image, size: 48, color: KAppColors.getOnBackground(context).withValues(alpha: 0.54)),
                          ),
                        );
                      },
                    ),
                    // Category badge
                    if (article.category.isNotEmpty)
                      Positioned(
                        top: KDesignConstants.spacing12,
                        left: KDesignConstants.spacing12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KDesignConstants.spacing12,
                            vertical: KDesignConstants.spacing4,
                          ),
                          decoration: BoxDecoration(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            borderRadius: KBorderRadius.xl,
                          ),
                          child: Text(
                            article.category.first.toUpperCase(),
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: KAppColors.getOnBackground(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // Content
            Padding(
              padding: KDesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: KDesignConstants.spacing8),
                  Text(
                    article.description,
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KDesignConstants.spacing12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: KAppColors.blue,
                        child: const Icon(
                          Icons.person,
                          size: 12,
                          color: KAppColors.darkOnBackground,
                        ),
                      ),
                      const SizedBox(width: KDesignConstants.spacing8),
                      Expanded(
                        child: Text(
                          article.sourceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: KDesignConstants.spacing8),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.54),
                      ),
                      const SizedBox(width: KDesignConstants.spacing4),
                      Text(
                        _getTimeAgo(article.pubDate),
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.54),
                        ),
                      ),
                      if (userId != null && userId!.isNotEmpty) ...[
                        const SizedBox(width: KDesignConstants.spacing8),
                        IconButton(
                          constraints: const BoxConstraints.tightFor(
                            width: 28,
                            height: 28,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Add to list',
                          onPressed: () => AddToListHelper.showPickerAndAdd(
                            context,
                            article,
                          ),
                          icon: Icon(
                            Icons.library_add_outlined,
                            size: 18,
                            color: KAppColors.getPrimary(context),
                          ),
                        ),
                      ],
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
