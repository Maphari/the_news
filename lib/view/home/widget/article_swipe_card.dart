import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/utils/reading_time_calculator.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background Image
              _buildBackgroundImage(),

              // Gradient Overlay
              _buildGradientOverlay(),

              // Content
              _buildContent(context),

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

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: article.imageUrl != null
          ? Image.network(
              article.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getCategoryColor().withValues(alpha: 0.3),
                        _getCategoryColor().withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.article_outlined,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.withValues(alpha: 0.2),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCategoryColor().withValues(alpha: 0.3),
                    _getCategoryColor().withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.article_outlined,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.9),
            ],
            stops: const [0.3, 0.6, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final readingTime = ReadingTimeCalculator.calculateReadingTime(article.content);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Badge
            _buildCategoryBadge(),
            const SizedBox(height: 12),

            // Title
            Text(
              article.title,
              style: KAppTextStyles.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              article.description,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Metadata Row
            Row(
              children: [
                // Source
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (article.sourceIcon.isNotEmpty)
                          Image.network(
                            article.sourceIcon,
                            width: 16,
                            height: 16,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.public,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.8),
                              );
                            },
                          ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            article.sourceName,
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
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
                const SizedBox(width: 8),

                // Reading Time
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$readingTime min',
                      style: KAppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),

                // Sentiment Indicator
                _buildSentimentIndicator(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    if (article.category.isEmpty) return const SizedBox.shrink();

    final category = article.category.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getCategoryColor(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor().withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        category.toUpperCase(),
        style: KAppTextStyles.labelSmall.copyWith(
          color: Colors.white,
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
        sentimentColor = const Color(0xFF10B981);
        sentimentIcon = Icons.sentiment_satisfied;
        break;
      case 'negative':
        sentimentColor = const Color(0xFFEF4444);
        sentimentIcon = Icons.sentiment_dissatisfied;
        break;
      default:
        sentimentColor = const Color(0xFFF59E0B);
        sentimentIcon = Icons.sentiment_neutral;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: sentimentColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
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
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app,
            size: 14,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            'TAP TO READ',
            style: KAppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    if (article.category.isEmpty) return KAppColors.primary;

    switch (article.category.first.toLowerCase()) {
      case 'top':
        return Colors.red;
      case 'politics':
        return Colors.blue;
      case 'business':
        return Colors.green;
      case 'technology':
        return Colors.purple;
      case 'sports':
        return Colors.orange;
      case 'environment':
        return Colors.teal;
      case 'health':
        return Colors.pink;
      case 'crime':
        return Colors.deepOrange;
      case 'entertainment':
        return Colors.amber;
      case 'world':
        return Colors.indigo;
      default:
        return KAppColors.primary;
    }
  }
}
