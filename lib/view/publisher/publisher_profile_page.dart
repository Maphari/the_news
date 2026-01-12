import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/news_api_service.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/view/article_details/article_detail_page.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';

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
      // Get all articles and filter by publisher
      final allArticles = await _newsApiService.fetchNews(useCache: true);
      final publisherArticles = allArticles
          .where((article) => article.sourceName == widget.publisherName)
          .toList();

      // Sort by date (newest first)
      publisherArticles.sort((a, b) => b.pubDate.compareTo(a.pubDate));

      setState(() {
        _publisherArticles = publisherArticles;
        _articleCount = publisherArticles.length;
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
              floating: true,
              snap: true,
              backgroundColor: KAppColors.getPrimary(context),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
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
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child: Image.network(
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
                                backgroundColor: Colors.white,
                                child: Text(
                                  _getInitials(widget.publisherName),
                                  style: KAppTextStyles.displayMedium.copyWith(
                                    color: KAppColors.getPrimary(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        const SizedBox(height: 12),
                        // Publisher Name
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            widget.publisherName,
                            style: KAppTextStyles.displaySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              color: Colors.white.withValues(alpha: 0.3),
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            _buildStatItem(
                              isFollowed ? 'Following' : 'Follow',
                              'Status',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Follow Button
                        _isFollowLoading
                            ? const SizedBox(
                                width: 160,
                                height: 44,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
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
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white,
                                  foregroundColor: isFollowed
                                      ? Colors.white
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
                              const SizedBox(height: 16),
                              Text(
                                'No articles found',
                                style: KAppTextStyles.titleLarge.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                ),
                              ),
                              const SizedBox(height: 8),
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
                        padding: const EdgeInsets.all(16),
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
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: KAppTextStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
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
          borderRadius: BorderRadius.circular(16),
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
                child: Image.network(
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
                padding: const EdgeInsets.all(12),
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
                    const SizedBox(height: 8),
                    Text(
                      article.description,
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
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
