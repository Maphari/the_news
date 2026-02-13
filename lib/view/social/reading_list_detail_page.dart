import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/reading_list_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/view/article_details/article_detail_page.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class ReadingListDetailPage extends StatefulWidget {
  const ReadingListDetailPage({
    super.key,
    required this.listId,
    this.initialList,
    this.currentUserId,
  });

  final String listId;
  final ReadingList? initialList;
  final String? currentUserId;

  @override
  State<ReadingListDetailPage> createState() => _ReadingListDetailPageState();
}

class _ReadingListDetailPageState extends State<ReadingListDetailPage> {
  final SocialFeaturesBackendService _socialService =
      SocialFeaturesBackendService.instance;

  ReadingList? _list;
  List<ArticleModel> _articles = [];
  bool _isLoading = true;
  bool _isSavingOrder = false;

  bool get _canEdit {
    final list = _list;
    final userId = widget.currentUserId;
    if (list == null || userId == null || userId.isEmpty) return false;
    return list.canEdit(userId);
  }

  @override
  void initState() {
    super.initState();
    _list = widget.initialList;
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _socialService.getReadingListById(widget.listId);
      if (!mounted) return;

      if (list == null) {
        setState(() {
          _list = null;
          _articles = [];
          _isLoading = false;
        });
        return;
      }

      final articles = await _socialService.getArticlesByIds(list.articleIds);
      if (!mounted) return;

      setState(() {
        _list = list;
        _articles = articles;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeArticle(ArticleModel article) async {
    final list = _list;
    if (list == null || !_canEdit) return;
    try {
      await _socialService.removeArticleFromList(list.id, article.articleId);
      if (!mounted) return;
      setState(() {
        _articles.removeWhere((item) => item.articleId == article.articleId);
        _list = list.copyWith(
          articleIds: list.articleIds
              .where((id) => id != article.articleId)
              .toList(),
          updatedAt: DateTime.now(),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove article: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _persistOrder() async {
    final list = _list;
    if (list == null || !_canEdit) return;
    final orderedIds = _articles.map((article) => article.articleId).toList();
    setState(() => _isSavingOrder = true);
    try {
      await _socialService.reorderListArticles(list.id, orderedIds);
      if (!mounted) return;
      setState(() {
        _list = list.copyWith(articleIds: orderedIds, updatedAt: DateTime.now());
        _isSavingOrder = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save order: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;

    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list?.name ?? 'Reading List',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KAppTextStyles.titleLarge.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (list != null)
                          Text(
                            '${list.articleCount} articles',
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: KAppColors.getOnBackground(context)
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isSavingOrder)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            if (list?.description != null && list!.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    list.description!,
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context)
                          .withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_list == null) {
      return Center(
        child: Text(
          'This list is not available',
          style: KAppTextStyles.bodyMedium.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
          ),
        ),
      );
    }
    if (_articles.isEmpty) {
      return Center(
        child: Text(
          'No articles in this list yet',
          style: KAppTextStyles.bodyMedium.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
          ),
        ),
      );
    }

    if (_canEdit) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: _articles.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final moved = _articles.removeAt(oldIndex);
            _articles.insert(newIndex, moved);
          });
          _persistOrder();
        },
        itemBuilder: (context, index) {
          final article = _articles[index];
          return _buildArticleCard(article, index, key: ValueKey(article.articleId));
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: _articles.length,
      itemBuilder: (context, index) => _buildArticleCard(_articles[index], index),
    );
  }

  Widget _buildArticleCard(ArticleModel article, int index, {Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: KDesignConstants.spacing10),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ArticleDetailPage(article: article),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 86,
                  height: 72,
                  child: SafeNetworkImage(
                    article.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.sourceName,
                      style: KAppTextStyles.labelSmall.copyWith(
                        color: KAppColors.getOnBackground(context)
                            .withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              if (_canEdit) ...[
                IconButton(
                  tooltip: 'Remove',
                  onPressed: () => _removeArticle(article),
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: KAppColors.getOnBackground(context)
                        .withValues(alpha: 0.72),
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.drag_indicator,
                      color: KAppColors.getOnBackground(context)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
