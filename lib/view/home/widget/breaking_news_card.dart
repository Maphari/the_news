import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/article_access_service.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class BreakingNewsCard extends StatelessWidget {
  const BreakingNewsCard({
    super.key,
    required this.article,
  });

  final ArticleModel article;

  Future<void> _navigateToArticleDetail(BuildContext context) async {
    await ArticleAccessService.instance.navigateToArticle(context, article);
  }

  String _getTimeAgo(DateTime publishDate) {
    final now = DateTime.now();
    final difference = now.difference(publishDate);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(article.pubDate);

    return GestureDetector(
      onTap: () => _navigateToArticleDetail(context),
      child: Container(
        height: 280,
        margin: const EdgeInsets.fromLTRB(KDesignConstants.spacing16, KDesignConstants.spacing8, KDesignConstants.spacing16, KDesignConstants.spacing16),
        decoration: BoxDecoration(
          borderRadius: KBorderRadius.xl,
        ),
        child: ClipRRect(
          borderRadius: KBorderRadius.xl,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              if (article.imageUrl != null)
                SafeNetworkImage(
                  article.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                      ),
                    );
                  },
                )
              else
                Container(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.article_outlined,
                    size: 48,
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                  ),
                ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      KAppColors.darkBackground.withValues(alpha: 0.3),
                      KAppColors.darkBackground.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: KDesignConstants.paddingMd,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source and Time
                    Row(
                      children: [
                        // Source logo/icon
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: article.sourceIcon.isNotEmpty ? KAppColors.darkOnBackground : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: article.sourceIcon.isNotEmpty
                              ? ClipOval(
                                  child: SafeNetworkImage(
                                    article.sourceIcon,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.red,
                                        child: const Icon(
                                          Icons.article,
                                          color: KAppColors.darkOnBackground,
                                          size: 14,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.article,
                                  color: KAppColors.darkOnBackground,
                                  size: 14,
                                ),
                        ),
                        Text(
                          article.sourceName,
                          style: KAppTextStyles.labelMedium.copyWith(
                            color: KAppColors.darkOnBackground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: KDesignConstants.spacing8),
                        Text(
                          '• $timeAgo',
                          style: KAppTextStyles.labelMedium.copyWith(
                            color: KAppColors.darkOnBackground.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KDesignConstants.spacing12),

                    // Title
                    Text(
                      article.title,
                      style: KAppTextStyles.headlineSmall.copyWith(
                        color: KAppColors.darkOnBackground,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: KDesignConstants.spacing8),

                    // Description
                    Text(
                      article.description,
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.darkOnBackground.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
