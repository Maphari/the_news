import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/service/news_api_service.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/view/article_details/article_detail_page.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class PublisherProfilePage extends StatefulWidget {
  const PublisherProfilePage({
    super.key,
    required this.publisherName,
    this.publisherIcon,
    required this.user,
  });

  final String publisherName;
  final String? publisherIcon;
  final RegisterLoginUserSuccessModel user;

  @override
  State<PublisherProfilePage> createState() => _PublisherProfilePageState();
}

class _PublisherProfilePageState extends State<PublisherProfilePage> {
  final NewsApiService _newsApiService = NewsApiService.instance;
  final ApiClient _api = ApiClient.instance;
  final FollowedPublishersService _followedPublishersService = FollowedPublishersService.instance;

  List<ArticleModel> _publisherArticles = [];
  bool _isLoading = true;
  bool _isFollowLoading = false;
  int _articleCount = 0;

  @override
  void initState() {
    super.initState();
    StatusBarHelper.setLightStatusBar();
    _loadPublisherArticles();
    _followedPublishersService.addListener(_onFollowedPublishersChanged);
  }

  @override
  void dispose() {
    _followedPublishersService.removeListener(_onFollowedPublishersChanged);
    super.dispose();
  }

  void _onFollowedPublishersChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPublisherArticles() async {
    setState(() => _isLoading = true);

    try {
      final dbFuture = _fetchPublisherArticlesFromDb(widget.publisherName);
      final apiFuture = _fetchPublisherArticlesFromApi(widget.publisherName);
      final results = await Future.wait([dbFuture, apiFuture]);

      final dbArticles = results[0];
      final apiArticles = results[1];

      final merged = _mergeArticlesKeepingNewest(dbArticles, apiArticles);

      setState(() {
        _publisherArticles = merged;
        _articleCount = merged.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading articles: $e')),
        );
      }
    }
  }

  Future<List<ArticleModel>> _fetchPublisherArticlesFromDb(
    String publisherName,
  ) async {
    try {
      final response = await _api.get(
        'articles',
        queryParams: {
          'sourceName': publisherName,
          'limit': '150',
          'offset': '0',
        },
        timeout: const Duration(seconds: 20),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true && data['articles'] is List) {
          final List<dynamic> list = data['articles'] as List<dynamic>;
          return list
              .map((json) => ArticleModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      // Fallback handled by caller merge path.
    }
    return <ArticleModel>[];
  }

  Future<List<ArticleModel>> _fetchPublisherArticlesFromApi(
    String publisherName,
  ) async {
    try {
      final allArticles = await _newsApiService.fetchNews(useCache: false);
      return allArticles
          .where(
            (article) => article.sourceName.toLowerCase() ==
                publisherName.toLowerCase(),
          )
          .toList();
    } catch (_) {
      return <ArticleModel>[];
    }
  }

  List<ArticleModel> _mergeArticlesKeepingNewest(
    List<ArticleModel> dbArticles,
    List<ArticleModel> apiArticles,
  ) {
    final byKey = <String, ArticleModel>{};

    String normalizeTitle(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    String dedupeKey(ArticleModel article) {
      if (article.articleId.isNotEmpty) return 'id:${article.articleId}';
      if (article.link.isNotEmpty) return 'link:${article.link}';
      return 'title:${normalizeTitle(article.title)}';
    }

    for (final article in [...dbArticles, ...apiArticles]) {
      final key = dedupeKey(article);
      final current = byKey[key];
      if (current == null || article.pubDate.isAfter(current.pubDate)) {
        byKey[key] = article;
      }
    }

    final merged = byKey.values.toList()
      ..sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return merged;
  }

  Future<void> _handleFollowToggle() async {
    setState(() => _isFollowLoading = true);

    await _followedPublishersService.toggleFollow(
      widget.user.userId,
      widget.publisherName,
    );

    if (mounted) {
      setState(() => _isFollowLoading = false);
    }
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  void _navigateToArticle(ArticleModel article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(
          article: article,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFollowed = _followedPublishersService.isPublisherFollowed(widget.publisherName);

    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: KAppColors.getBackground(context),
      child: Scaffold(
        backgroundColor: KAppColors.getBackground(context),
        body: CustomScrollView(
          slivers: [
            // App Bar with Publisher Info
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              floating: false,
              backgroundColor: KAppColors.getPrimary(context),
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: AppBackButton(
                onPressed: () => Navigator.pop(context),
                backgroundColor: KAppColors.getBackground(context).withValues(alpha: 0.8),
                iconColor: KAppColors.darkOnBackground,
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        KAppColors.getPrimary(context),
                        KAppColors.getPrimary(context).withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 50),
                        // Publisher Avatar
                        widget.publisherIcon != null && widget.publisherIcon!.isNotEmpty
                            ? CircleAvatar(
                                radius: 50,
                                backgroundColor: KAppColors.darkOnBackground,
                                child: ClipOval(
                                  child: SafeNetworkImage(
                                    widget.publisherIcon!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Text(
                                        _getInitials(widget.publisherName),
                                        style: KAppTextStyles.displayMedium.copyWith(
                                          color: KAppColors.getPrimary(context),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                radius: 50,
                                backgroundColor: KAppColors.darkOnBackground,
                                child: Text(
                                  _getInitials(widget.publisherName),
                                  style: KAppTextStyles.displayMedium.copyWith(
                                    color: KAppColors.getPrimary(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        const SizedBox(height: KDesignConstants.spacing12),
                        // Publisher Name
                        Padding(
                          padding: KDesignConstants.paddingHorizontalLg,
                          child: Text(
                            widget.publisherName,
                            style: KAppTextStyles.displaySmall.copyWith(
                              color: KAppColors.darkOnBackground,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: KDesignConstants.spacing8),
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatItem(
                              _isLoading ? '-' : _articleCount.toString(),
                              'Articles',
                            ),
                            Container(
                              height: 30,
                              width: 1,
                              color: KAppColors.darkOnBackground.withValues(alpha: 0.3),
                              margin: KDesignConstants.paddingHorizontalLg,
                            ),
                            _buildStatItem(
                              isFollowed ? 'Following' : 'Follow',
                              'Status',
                            ),
                          ],
                        ),
                        const SizedBox(height: KDesignConstants.spacing16),
                        // Follow Button
                        _isFollowLoading
                            ? const SizedBox(
                                width: 160,
                                height: 44,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: KAppColors.darkOnBackground,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: _handleFollowToggle,
                                icon: Icon(
                                  isFollowed ? Icons.check : Icons.add,
                                  size: 20,
                                ),
                                label: Text(
                                  isFollowed ? 'Following' : 'Follow',
                                  style: KAppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFollowed
                                      ? KAppColors.darkOnBackground.withValues(alpha: 0.2)
                                      : KAppColors.darkOnBackground,
                                  foregroundColor: isFollowed
                                      ? KAppColors.darkOnBackground
                                      : KAppColors.getPrimary(context),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: const StadiumBorder(),
                                  elevation: isFollowed ? 0 : 2,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Articles List
            _isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: KAppColors.getPrimary(context),
                      ),
                    ),
                  )
                : _publisherArticles.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 64,
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: KDesignConstants.spacing16),
                              Text(
                                'No articles found',
                                style: KAppTextStyles.titleLarge.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                ),
                              ),
                              const SizedBox(height: KDesignConstants.spacing8),
                              Text(
                                'This publisher hasn\'t published any articles yet',
                                style: KAppTextStyles.bodyMedium.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: KDesignConstants.paddingMd,
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'Latest Articles',
                                    style: KAppTextStyles.titleLarge.copyWith(
                                      color: KAppColors.getOnBackground(context),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }

                              final article = _publisherArticles[index - 1];
                              return _buildArticleCard(article);
                            },
                            childCount: _publisherArticles.length + 1,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: KAppTextStyles.titleLarge.copyWith(
            color: KAppColors.darkOnBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: KAppTextStyles.bodySmall.copyWith(
            color: KAppColors.darkOnBackground.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildArticleCard(ArticleModel article) {
    return GestureDetector(
      onTap: () => _navigateToArticle(article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article Image
            if (article.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SafeNetworkImage(
                  article.imageUrl!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                      ),
                    );
                  },
                ),
              ),

            // Article Info
            Expanded(
              child: Padding(
                padding: KDesignConstants.paddingSm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: KAppTextStyles.titleSmall.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: KDesignConstants.spacing8),
                    Text(
                      article.description,
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: KDesignConstants.spacing8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: KDesignConstants.spacing4),
                        Text(
                          _formatDate(article.pubDate),
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                          ),
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
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
