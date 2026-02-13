import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/utils/reading_time_calculator.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';
import 'package:the_news/utils/contrast_check.dart';

/// Tinder-style swipeable card for articles
class ArticleSwipeCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback? onTap;

  const ArticleSwipeCard({
    super.key,
    required this.article,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final overlayScrim = KAppColors.imageScrim.withValues(alpha: 0.8);
    debugCheckContrast(
      foreground: KAppColors.onImage,
      background: overlayScrim,
      contextLabel: 'Swipe card overlay',
      minRatio: 3.0,
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: KBorderRadius.xl,
          boxShadow: KShadows.medium(context),
        ),
        child: ClipRRect(
          borderRadius: KBorderRadius.xl,
          child: Stack(
            children: [
              // Background Image
              _buildBackgroundImage(context: context),

              // Gradient Overlay
              _buildGradientOverlay(overlayScrim),

              // Content
              _buildContent(context, overlayScrim),

              // Tap hint badge
              Positioned(
                top: 16,
                right: 16,
                child: _buildTapHint(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImage({required BuildContext context}) {
    return Positioned.fill(
      child: article.imageUrl != null
          ? SafeNetworkImage(
              article.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: _getCategoryColor(context: context).withValues(alpha: 0.12),
                  child: Center(
                    child: Icon(
                      Icons.article_outlined,
                      size: 80,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: KAppColors.getSurface(context).withValues(alpha: 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            )
          : Container(
              color: _getCategoryColor(context: context).withValues(alpha: 0.12),
              child: Center(
                child: Icon(
                  Icons.article_outlined,
                  size: 80,
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                ),
              ),
            ),
    );
  }

  Widget _buildGradientOverlay(Color overlayScrim) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              overlayScrim.withValues(alpha: 0.4),
              overlayScrim,
            ],
            stops: const [0.3, 0.6, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color overlayScrim) {
    final readingTime = ReadingTimeCalculator.calculateReadingTime(article.content);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: KDesignConstants.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Badge
            _buildCategoryBadge(context: context),
            const SizedBox(height: KDesignConstants.spacing12),

            // Title
            Text(
              article.title,
              style: KAppTextStyles.headlineSmall.copyWith(
                color: KAppColors.onImage,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: KDesignConstants.spacing8),

            // Metadata Row
            Row(
              children: [
                // Source
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: overlayScrim.withValues(alpha: 0.35),
                    borderRadius: KBorderRadius.sm,
                    border: Border.all(
                      color: KAppColors.onImage.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (article.sourceIcon.isNotEmpty)
                          SafeNetworkImage(
                            article.sourceIcon,
                            width: 16,
                            height: 16,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.public,
                                size: 16,
                                color: KAppColors.onImage.withValues(alpha: 0.8),
                              );
                            },
                          ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            article.sourceName,
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: KAppColors.onImage.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: KDesignConstants.spacing8),

                // Reading Time
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: KAppColors.onImage.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: KDesignConstants.spacing4),
                    Text(
                      '$readingTime min',
                      style: KAppTextStyles.labelSmall.copyWith(
                        color: KAppColors.onImage.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: KDesignConstants.spacing8),

                // Sentiment Indicator
                _buildSentimentIndicator(),
              ],
            ),
            const SizedBox(height: KDesignConstants.spacing12),

            // Description (short preview)
            Text(
              article.description,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.onImage.withValues(alpha: 0.9),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: KDesignConstants.spacing8),

            // Read more hint
            Text(
              'Read more',
              style: KAppTextStyles.labelSmall.copyWith(
                color: KAppColors.onImage.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge({required BuildContext context}) {
    if (article.category.isEmpty) return const SizedBox.shrink();

    final category = article.category.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getCategoryColor(context: context),
        borderRadius: KBorderRadius.full,
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(context: context).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        category.toUpperCase(),
        style: KAppTextStyles.labelSmall.copyWith(
          color: KAppColors.getOnPrimary(context),
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildSentimentIndicator() {
    Color sentimentColor;
    IconData sentimentIcon;

    switch (article.sentiment.toLowerCase()) {
      case 'positive':
        sentimentColor = KAppColors.success;
        sentimentIcon = Icons.sentiment_satisfied;
        break;
      case 'negative':
        sentimentColor = KAppColors.error;
        sentimentIcon = Icons.sentiment_dissatisfied;
        break;
      default:
        sentimentColor = KAppColors.warning;
        sentimentIcon = Icons.sentiment_neutral;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: sentimentColor.withValues(alpha: 0.2),
        borderRadius: KBorderRadius.sm,
        border: Border.all(
          color: sentimentColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Icon(
        sentimentIcon,
        size: 18,
        color: sentimentColor,
      ),
    );
  }

  Widget _buildTapHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: KAppColors.imageScrim.withValues(alpha: 0.6),
        borderRadius: KBorderRadius.full,
        border: Border.all(
          color: KAppColors.onImage.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app,
            size: 14,
            color: KAppColors.onImage.withValues(alpha: 0.9),
          ),
          const SizedBox(width: KDesignConstants.spacing4),
          Text(
            'TAP',
            style: KAppTextStyles.labelSmall.copyWith(
              color: KAppColors.onImage.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor({required BuildContext context}) {
    if (article.category.isEmpty) return KAppColors.getPrimary(context);

    switch (article.category.first.toLowerCase()) {
      case 'top':
        return KAppColors.red;
      case 'politics':
        return KAppColors.blue;
      case 'business':
        return KAppColors.green;
      case 'technology':
        return KAppColors.purple;
      case 'sports':
        return KAppColors.orange;
      case 'environment':
        return KAppColors.cyan;
      case 'health':
        return KAppColors.pink;
      case 'crime':
        return KAppColors.orange;
      case 'entertainment':
        return KAppColors.yellow;
      case 'world':
        return KAppColors.blue;
      default:
        return KAppColors.getPrimary(context);
    }
  }
}
