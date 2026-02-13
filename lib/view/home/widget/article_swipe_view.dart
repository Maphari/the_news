import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/saved_articles_service.dart';
import 'package:the_news/service/disliked_articles_service.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/utils/haptic_service.dart';
import 'article_swipe_card.dart';

/// Tinder-style swipeable article view
class ArticleSwipeView extends StatefulWidget {
  final List<ArticleModel> articles;
  final RegisterLoginUserSuccessModel user;

  const ArticleSwipeView({
    super.key,
    required this.articles,
    required this.user,
  });

  @override
  State<ArticleSwipeView> createState() => _ArticleSwipeViewState();
}

class _ArticleSwipeViewState extends State<ArticleSwipeView> {
  final AppinioSwiperController _swiperController = AppinioSwiperController();
  final SavedArticlesService _savedArticlesService = SavedArticlesService.instance;
  final DislikedArticlesService _dislikedArticlesService = DislikedArticlesService.instance;

  int _currentIndex = 0;

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  void _handleSwipeRight(int index) {
    if (index >= widget.articles.length) return;
    final article = widget.articles[index];

    // Swipe right: Save article
    HapticService.success();
    _savedArticlesService.saveArticle(
      widget.user.userId,
      article.articleId,
      article: article,
    );
    _showSwipeHint('Article saved!', Icons.bookmark, KAppColors.success);

    setState(() => _currentIndex = index + 1);
  }

  void _handleSwipeLeft(int index) {
    if (index >= widget.articles.length) return;
    final article = widget.articles[index];

    // Swipe left: Dislike article
    HapticService.error();
    _dislikedArticlesService.dislikeArticle(
      widget.user.userId,
      article.articleId,
    );
    _showSwipeHint('Article hidden', Icons.thumb_down, KAppColors.error);

    setState(() => _currentIndex = index + 1);
  }

  void _handleSwipeUp(int index) {
    if (index >= widget.articles.length) return;
    final article = widget.articles[index];

    // Swipe up: Read later (same as save)
    HapticService.light();
    _savedArticlesService.saveArticle(
      widget.user.userId,
      article.articleId,
      article: article,
    );
    _showSwipeHint('Saved for later!', Icons.schedule, KAppColors.info);

    setState(() => _currentIndex = index + 1);
  }

  void _showSwipeHint(String message, IconData icon, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: KAppColors.getOnPrimary(context), size: 20),
            const SizedBox(width: KDesignConstants.spacing12),
            Text(
              message,
              style: TextStyle(
                color: KAppColors.getOnPrimary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: KBorderRadius.md,
        ),
        margin: KDesignConstants.paddingMd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // Swiper
        AppinioSwiper(
          controller: _swiperController,
          cardCount: widget.articles.length,
          backgroundCardCount: 2,
          backgroundCardScale: 0.96,
          backgroundCardOffset: const Offset(0, 16),
          maxAngle: 12,
          threshold: 80,
          cardBuilder: (BuildContext context, int index) {
            return ArticleSwipeCard(
              article: widget.articles[index],
              onTap: () {
                // Tap to open article details
                HapticService.light();
                AppRoutes.navigateTo(
                  context,
                  AppRoutes.articleDetail,
                  arguments: widget.articles[index],
                );
              },
            );
          },
          onSwipeEnd: (int previousIndex, int? currentIndex, SwiperActivity activity) {
            // Handle swipe based on activity
            // We'll handle it through action buttons
          },
          onEnd: _onEnd,
          swipeOptions: const SwipeOptions.all(),
        ),

        // Swipe feedback (like/dislike/save)
        Positioned.fill(
          child: IgnorePointer(
            child: _buildSwipeFeedback(),
          ),
        ),

        // Swipe action buttons (for manual control)
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: _buildActionButtons(),
        ),

        // Swipe hint overlay
        // Swipe hint overlay (lighter)
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: _buildSwipeHints(),
        ),

        // Progress indicator
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: _buildProgressIndicator(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Dislike button (swipe left)
        _buildActionButton(
          icon: Icons.close,
          color: KAppColors.error,
          onPressed: () {
            if (_currentIndex < widget.articles.length) {
              _swiperController.swipeLeft();
              _handleSwipeLeft(_currentIndex);
            }
          },
        ),
        const SizedBox(width: KDesignConstants.spacing20),

        // Read later button (swipe up)
        _buildActionButton(
          icon: Icons.schedule,
          color: KAppColors.info,
          onPressed: () {
            if (_currentIndex < widget.articles.length) {
              _swiperController.swipeUp();
              _handleSwipeUp(_currentIndex);
            }
          },
        ),
        const SizedBox(width: KDesignConstants.spacing20),

        // Save button (swipe right)
        _buildActionButton(
          icon: Icons.favorite,
          color: KAppColors.success,
          onPressed: () {
            if (_currentIndex < widget.articles.length) {
              _swiperController.swipeRight();
              _handleSwipeRight(_currentIndex);
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: KShadows.low(context),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }

  // bool _unswipe() {
  //   if (_currentIndex > 0) {
  //     setState(() => _currentIndex--);
  //     HapticService.light();
  //     return true;
  //   }
  //   return false;
  // }

  void _onEnd() {
    if (!mounted) return;

    // All articles swiped
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: KAppColors.getOnPrimary(context)),
            const SizedBox(width: KDesignConstants.spacing12),
            Text(
              'All caught up! 🎉',
              style: TextStyle(
                color: KAppColors.getOnPrimary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: KAppColors.getPrimary(context),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: KBorderRadius.md,
        ),
      ),
    );
  }

  Widget _buildSwipeHints() {
    return Container(
      margin: KDesignConstants.paddingHorizontalLg,
      padding: KDesignConstants.paddingSm,
      decoration: BoxDecoration(
        color: KAppColors.getBackground(context).withValues(alpha: 0.7),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Swipe Gestures',
            style: KAppTextStyles.titleSmall.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHintItem(
                icon: Icons.arrow_forward,
                label: 'Save',
                color: KAppColors.success,
              ),
              _buildHintItem(
                icon: Icons.arrow_back,
                label: 'Hide',
                color: KAppColors.error,
              ),
              _buildHintItem(
                icon: Icons.arrow_upward,
                label: 'Later',
                color: KAppColors.info,
              ),
              _buildHintItem(
                icon: Icons.touch_app,
                label: 'Read',
                color: KAppColors.getOnBackground(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHintItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: KDesignConstants.spacing4),
        Text(
          label,
          style: KAppTextStyles.labelSmall.copyWith(
            color: color.withValues(alpha: 0.9),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: KDesignConstants.paddingHorizontalLg,
      padding: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing8),
      decoration: BoxDecoration(
        color: KAppColors.getBackground(context).withValues(alpha: 0.85),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.layers,
            size: 16,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.9),
          ),
          const SizedBox(width: KDesignConstants.spacing8),
          Text(
            '${_currentIndex + 1} / ${widget.articles.length}',
            style: KAppTextStyles.labelMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeFeedback() {
    return AnimatedBuilder(
      animation: _swiperController,
      builder: (context, child) {
        final position = _swiperController.position;
        if (position == null) return const SizedBox.shrink();

        final dx = position.offset.dx;
        final dy = position.offset.dy;
        final threshold = 80.0;
        final likeOpacity = (dx / threshold).clamp(0.0, 1.0);
        final dislikeOpacity = (-dx / threshold).clamp(0.0, 1.0);
        final saveOpacity = (-dy / threshold).clamp(0.0, 1.0);

        return Stack(
          children: [
            Positioned(
              top: 40,
              left: 28,
              child: _buildSwipeBadge(
                label: 'LIKE',
                icon: Icons.favorite,
                color: KAppColors.success,
                opacity: likeOpacity,
              ),
            ),
            Positioned(
              top: 40,
              right: 28,
              child: _buildSwipeBadge(
                label: 'NOPE',
                icon: Icons.close,
                color: KAppColors.error,
                opacity: dislikeOpacity,
              ),
            ),
            Positioned(
              top: 32,
              left: 0,
              right: 0,
              child: Center(
                child: _buildSwipeBadge(
                  label: 'SAVE',
                  icon: Icons.schedule,
                  color: KAppColors.info,
                  opacity: saveOpacity,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwipeBadge({
    required String label,
    required IconData icon,
    required Color color,
    required double opacity,
  }) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: KBorderRadius.full,
          border: Border.all(color: color.withValues(alpha: 0.9), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: KAppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: KDesignConstants.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: KAppColors.getPrimary(context).withValues(alpha: 0.5),
            ),
            const SizedBox(height: KDesignConstants.spacing24),
            Text(
              'All caught up!',
              style: KAppTextStyles.headlineMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            Text(
              'No more articles to swipe through.\nCheck back later for fresh content!',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
