import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/clickbait_detector_service.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class TogglableCompactArticleItem extends StatefulWidget {
  const TogglableCompactArticleItem({
    super.key,
    required this.article,
  });

  final ArticleModel article;

  @override
  _TogglableCompactArticleItemState createState() =>
      _TogglableCompactArticleItemState();
}

class _TogglableCompactArticleItemState extends State<TogglableCompactArticleItem> {
  void _navigateToArticleDetail(BuildContext context) {
    AppRoutes.navigateTo(
      context,
      AppRoutes.articleDetail,
      arguments: widget.article,
    );
  }

  String _getTimeAgo(DateTime publishDate) {
    final now = DateTime.now();
    final difference = now.difference(publishDate);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Color _getCategoryColor() {
    final category = widget.article.category.toString().toLowerCase();
    switch (category) {
      case 'technology':
        return KAppColors.getTertiary(context);
      case 'business':
        return KAppColors.getSecondary(context);
      case 'sports':
        return KAppColors.red;
      case 'entertainment':
        return KAppColors.orange;
      case 'science':
        return KAppColors.blue;
      case 'health':
        return KAppColors.pink;
      default:
        return KAppColors.getPrimary(context);
    }
  }

  Widget _buildCategoryPill(Color categoryColor) {
    if (widget.article.category.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: KShadows.low(context),
      ),
      child: Text(
        widget.article.category.first.toUpperCase(),
        style: KAppTextStyles.labelSmall.copyWith(
          color: KAppColors.onBackground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _getDisplayTitle() {
    final detector = ClickbaitDetectorService.instance;
    return detector.getNeutralTitle(widget.article.title, widget.article.description);
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(widget.article.pubDate);
    final categoryColor = _getCategoryColor();

    return InkWell(
      onTap: () => _navigateToArticleDetail(context),
      borderRadius: KBorderRadius.lg,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withAlpha(15),
            width: 1,
          ),
          boxShadow: KShadows.low(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Article thumbnail
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: KBorderRadius.md,
                    border: Border.all(
                      color: categoryColor.withAlpha(25),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: KBorderRadius.md,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.article.imageUrl != null)
                          SafeNetworkImage(
                            widget.article.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      categoryColor.withAlpha(10),
                                      categoryColor.withAlpha(5),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.article_outlined,
                                  color: categoryColor.withAlpha(40),
                                  size: 28,
                                ),
                              );
                            },
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  categoryColor.withAlpha(10),
                                  categoryColor.withAlpha(5),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.article_outlined,
                              color: categoryColor.withAlpha(40),
                              size: 28,
                            ),
                          ),
                        Positioned(
                          left: 6,
                          top: 6,
                          child: _buildCategoryPill(categoryColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Article content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title (rewritten if clickbait)
                      Text(
                        _getDisplayTitle(),
                        style: KAppTextStyles.titleMedium.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          fontSize: 14.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: KDesignConstants.spacing4),
                      // Bottom metadata row
                      Row(
                        children: [
                          // Source name
                          Flexible(
                            child: Text(
                              widget.article.sourceName,
                              style: KAppTextStyles.labelSmall.copyWith(
                                color:
                                    KAppColors.getOnBackground(context).withAlpha(128),
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Time ago
                          Text(
                            timeAgo,
                            style: KAppTextStyles.labelSmall.copyWith(
                              color:
                                  KAppColors.getOnBackground(context).withAlpha(102),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  color: KAppColors.getOnBackground(context).withAlpha(110),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
