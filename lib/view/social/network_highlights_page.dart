import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/network_highlight_model.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/engagement_service.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/view/article_details/article_detail_page.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';

class NetworkHighlightsPage extends StatefulWidget {
  const NetworkHighlightsPage({super.key});

  @override
  State<NetworkHighlightsPage> createState() => _NetworkHighlightsPageState();
}

class _NetworkHighlightsPageState extends State<NetworkHighlightsPage> {
  static const int _pageSize = 20;
  final SocialFeaturesBackendService _service =
      SocialFeaturesBackendService.instance;
  final EngagementService _engagementService = EngagementService.instance;
  final ApiClient _api = ApiClient.instance;
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  final List<NetworkHighlight> _highlights = [];
  final Map<String, bool> _liked = <String, bool>{};
  final Map<String, int> _likeCounts = <String, int>{};
  final Map<String, int> _commentCounts = <String, int>{};
  final Set<String> _busyLiking = <String>{};
  String? _userId;
  String? _nextCursor;
  bool _hasMore = true;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        !_hasMore ||
        _isLoadingMore ||
        _isInitialLoading) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    final user = await _authService.getCurrentUser();
    _userId = user?['id'] as String? ?? user?['userId'] as String?;
    setState(() {
      _highlights.clear();
      _liked.clear();
      _likeCounts.clear();
      _commentCounts.clear();
      _nextCursor = null;
      _hasMore = true;
      _isInitialLoading = true;
    });
    await _loadMore();
    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _service.getNetworkHighlightsPaginated(
        limit: _pageSize,
        cursor: _nextCursor,
      );
      if (!mounted) return;
      final existing = _highlights.map((h) => h.dedupeKey).toSet();
      final newItems = page.highlights
          .where((h) => !existing.contains(h.dedupeKey))
          .toList();
      setState(() {
        _highlights.addAll(newItems);
        for (final highlight in newItems) {
          _liked[highlight.dedupeKey] = false;
          _likeCounts[highlight.dedupeKey] = highlight.likeCount;
          _commentCounts[highlight.dedupeKey] = highlight.commentCount;
        }
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore && page.nextCursor != null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onBackground = KAppColors.getOnBackground(context);
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: KAppBar(
        title: Text(
          'Network Highlights',
          style: KAppTextStyles.titleLarge.copyWith(
            color: onBackground,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: AppBackButton(onPressed: () => Navigator.pop(context)),
        elevation: 0,
        backgroundColor: KAppColors.getBackground(context),
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: KDesignConstants.paddingMd,
                itemCount: _highlights.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _highlights.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: KDesignConstants.spacing12,
                    ),
                    child: _buildHighlightCard(_highlights[index]),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildHighlightCard(NetworkHighlight item) {
    final onBackground = KAppColors.getOnBackground(context);
    final sharersPreview = item.sharers.isEmpty
        ? 'From your network'
        : item.sharers.join(', ');
    final isLiked = _liked[item.dedupeKey] ?? false;
    final likeCount = _likeCounts[item.dedupeKey] ?? item.likeCount;
    final commentCount = _commentCounts[item.dedupeKey] ?? item.commentCount;
    final canOpenArticle = item.articleId != null && item.articleId!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: KBorderRadius.lg,
      child: InkWell(
        borderRadius: KBorderRadius.lg,
        onTap: canOpenArticle ? () => _openArticle(item) : null,
        child: Container(
          padding: KDesignConstants.paddingMd,
          decoration: BoxDecoration(
            borderRadius: KBorderRadius.lg,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                onBackground.withValues(alpha: 0.03),
                onBackground.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(color: onBackground.withValues(alpha: 0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sharersPreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KAppTextStyles.labelSmall.copyWith(
                        color: onBackground.withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                  if (canOpenArticle)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: onBackground.withValues(alpha: 0.4),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.articleImageUrl != null && item.articleImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: KBorderRadius.sm,
                      child: Image.network(
                        item.articleImageUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 64,
                      height: 72,
                      decoration: BoxDecoration(
                        color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
                        borderRadius: KBorderRadius.sm,
                      ),
                      child: Icon(
                        Icons.newspaper,
                        color: KAppColors.getPrimary(context),
                      ),
                    ),
                  const SizedBox(width: KDesignConstants.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.articleSourceName ?? 'Source unavailable',
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: onBackground.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.articleTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: KAppTextStyles.bodyMedium.copyWith(
                            color: onBackground,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        if (item.articleDescription != null &&
                            item.articleDescription!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.articleDescription!,
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: onBackground.withValues(alpha: 0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked
                        ? Colors.redAccent
                        : onBackground.withValues(alpha: 0.7),
                    label: _engagementService.formatCount(likeCount),
                    onTap: () => _toggleLike(item),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.mode_comment_outlined,
                    color: onBackground.withValues(alpha: 0.7),
                    label: _engagementService.formatCount(commentCount),
                    onTap: () => _openComments(item),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.repeat,
                    color: KAppColors.getPrimary(context),
                    label: _engagementService.formatCount(item.shareCount),
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: KBorderRadius.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: KAppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<ArticleModel?> _fetchArticleById(String articleId) async {
    try {
      final response = await _api.get(
        'articles/$articleId',
        timeout: const Duration(seconds: 15),
      );
      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        final articleJson = data['article'] as Map<String, dynamic>?;
        if (articleJson != null) {
          return ArticleModel.fromJson(articleJson);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _openArticle(NetworkHighlight highlight) async {
    final articleId = highlight.articleId;
    if (articleId == null || articleId.isEmpty) return;
    final article = await _fetchArticleById(articleId);
    if (!mounted) return;
    if (article == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this article right now')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ArticleDetailPage(article: article)),
    );
  }

  Future<void> _openComments(NetworkHighlight highlight) async {
    await _openArticle(highlight);
  }

  Future<void> _toggleLike(NetworkHighlight highlight) async {
    final articleId = highlight.articleId;
    final userId = _userId;
    if (articleId == null || articleId.isEmpty || userId == null || userId.isEmpty) {
      return;
    }
    if (_busyLiking.contains(highlight.dedupeKey)) return;
    final wasLiked = _liked[highlight.dedupeKey] ?? false;
    final beforeCount = _likeCounts[highlight.dedupeKey] ?? highlight.likeCount;
    setState(() {
      _busyLiking.add(highlight.dedupeKey);
      _liked[highlight.dedupeKey] = !wasLiked;
      _likeCounts[highlight.dedupeKey] = wasLiked
          ? (beforeCount > 0 ? beforeCount - 1 : 0)
          : beforeCount + 1;
    });
    final ok = await _engagementService.toggleLike(userId, articleId);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _liked[highlight.dedupeKey] = wasLiked;
        _likeCounts[highlight.dedupeKey] = beforeCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update like right now')),
      );
    }
    setState(() => _busyLiking.remove(highlight.dedupeKey));
  }
}
