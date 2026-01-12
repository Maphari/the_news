import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:the_news/constant/theme/default_theme.dart';
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
    _showSwipeHint('Article saved!', Icons.bookmark, const Color(0xFF10B981));

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
    _showSwipeHint('Article hidden', Icons.thumb_down, const Color(0xFFEF4444));

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
    _showSwipeHint('Saved for later!', Icons.schedule, const Color(0xFF3B82F6));

    setState(() => _currentIndex = index + 1);
  }

  void _showSwipeHint(String message, IconData icon, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
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

        // Swipe action buttons (for manual control)
        Positioned(
          bottom: 140,
          left: 0,
          right: 0,
          child: _buildActionButtons(),
        ),

        // Swipe hint overlay
        Positioned(
          bottom: 40,
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
          color: const Color(0xFFEF4444),
          onPressed: () {
            if (_currentIndex < widget.articles.length) {
              _swiperController.swipeLeft();
              _handleSwipeLeft(_currentIndex);
            }
          },
        ),
        const SizedBox(width: 20),

        // Read later button (swipe up)
        _buildActionButton(
          icon: Icons.schedule,
          color: const Color(0xFF3B82F6),
          onPressed: () {
            if (_currentIndex < widget.articles.length) {
              _swiperController.swipeUp();
              _handleSwipeUp(_currentIndex);
            }
          },
        ),
        const SizedBox(width: 20),

        // Save button (swipe right)
        _buildActionButton(
          icon: Icons.favorite,
          color: const Color(0xFF10B981),
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
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  bool _unswipe() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      HapticService.light();
      return true;
    }
    return false;
  }

  void _onEnd() {
    if (!mounted) return;

    // All articles swiped
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'All caught up! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: KAppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSwipeHints() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Swipe Gestures',
            style: KAppTextStyles.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHintItem(
                icon: Icons.arrow_forward,
                label: 'Save',
                color: const Color(0xFF10B981),
              ),
              _buildHintItem(
                icon: Icons.arrow_back,
                label: 'Hide',
                color: const Color(0xFFEF4444),
              ),
              _buildHintItem(
                icon: Icons.arrow_upward,
                label: 'Later',
                color: const Color(0xFF3B82F6),
              ),
              _buildHintItem(
                icon: Icons.touch_app,
                label: 'Read',
                color: Colors.white,
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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: KAppTextStyles.labelSmall.copyWith(
            color: color.withValues(alpha: 0.9),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
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
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          Text(
            '${_currentIndex + 1} / ${widget.articles.length}',
            style: KAppTextStyles.labelMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: KAppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'All caught up!',
              style: KAppTextStyles.headlineMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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
