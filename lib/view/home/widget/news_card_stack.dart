import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/disliked_articles_service.dart';
import 'package:the_news/service/saved_articles_service.dart';
import 'package:the_news/service/engagement_service.dart';
import 'package:the_news/utils/haptic_service.dart';
import 'package:the_news/view/comments/comments_page.dart';
import 'featured_news_card.dart';

class NewsCardStack extends StatefulWidget {
  const NewsCardStack({
    super.key,
    required this.news,
    required this.user,
  });

  final List<ArticleModel> news;
  final RegisterLoginUserSuccessModel user;

  @override
  State<NewsCardStack> createState() => _NewsCardStackState();
}

class _NewsCardStackState extends State<NewsCardStack>
    with SingleTickerProviderStateMixin {
  int currentCardIndex = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isMovingForward = true;
  bool _isAnimating = false;
  final DislikedArticlesService _dislikedArticlesService = DislikedArticlesService.instance;
  final SavedArticlesService _savedArticlesService = SavedArticlesService.instance;
  final EngagementService _engagementService = EngagementService.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _swipeLeft() {
    if (_isAnimating || currentCardIndex >= widget.news.length - 1) return;

    // Get the article being swiped
    final article = widget.news[currentCardIndex];

    // Dislike the article
    HapticService.error();
    _dislikedArticlesService.dislikeArticle(widget.user.userId, article.articleId);
    _showFeedback('Article hidden', Icons.thumb_down, const Color(0xFFEF4444));

    setState(() {
      _isAnimating = true;
      _isMovingForward = true;
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1.5, -0.2),
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOutCubic,
        ),
      );
    });

    _animationController.forward().then((_) {
      setState(() {
        currentCardIndex++;
        _isAnimating = false;
      });
      _animationController.reset();
    });
  }

  void _swipeRight() {
    if (_isAnimating || currentCardIndex >= widget.news.length - 1) return;

    // Get the article being swiped
    final article = widget.news[currentCardIndex];

    // Save the article
    HapticService.success();
    _savedArticlesService.saveArticle(
      widget.user.userId,
      article.articleId,
      article: article,
    );
    _showFeedback('Article saved!', Icons.bookmark, const Color(0xFF10B981));

    setState(() {
      _isAnimating = true;
      _isMovingForward = true;
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(1.5, 0.2),
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOutCubic,
        ),
      );
    });

    _animationController.forward().then((_) {
      setState(() {
        currentCardIndex++;
        _isAnimating = false;
      });
      _animationController.reset();
    });
  }

  void _swipeUp() {
    if (_isAnimating || currentCardIndex >= widget.news.length - 1) return;

    // Get the article being swiped
    final article = widget.news[currentCardIndex];

    // Save for later
    HapticService.light();
    _savedArticlesService.saveArticle(
      widget.user.userId,
      article.articleId,
      article: article,
    );
    _showFeedback('Saved for later!', Icons.schedule, const Color(0xFF3B82F6));

    setState(() {
      _isAnimating = true;
      _isMovingForward = true;
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -1.5),
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOutCubic,
        ),
      );
    });

    _animationController.forward().then((_) {
      setState(() {
        currentCardIndex++;
        _isAnimating = false;
      });
      _animationController.reset();
    });
  }

  void _handleComment() {
    if (_isAnimating || currentCardIndex >= widget.news.length) return;

    final article = widget.news[currentCardIndex];
    HapticService.light();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(
          article: article,
          user: widget.user,
        ),
      ),
    );
  }

  Future<void> _handleShare() async {
    if (_isAnimating || currentCardIndex >= widget.news.length) return;

    final article = widget.news[currentCardIndex];
    HapticService.light();

    try {
      await Share.share(
        '${article.title}\n\n${article.description}\n\nRead more: ${article.link}',
        subject: article.title,
      );

      // Track share engagement
      await _engagementService.shareArticle(
        widget.user.userId,
        article.articleId,
      );
    } catch (e) {
      // Handle share error silently
    }
  }

  void _showFeedback(String message, IconData icon, Color color) {
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
    if (widget.news.isEmpty) {
      return _buildEmptyState();
    }

    if (currentCardIndex >= widget.news.length) {
      return _buildCompletedState();
    }

    return Stack(
      children: [
        // Main card stack with gesture detection
        GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! < -500) _swipeLeft();
            if (details.primaryVelocity! > 500) _swipeRight();
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < -500) _swipeUp();
          },
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (currentCardIndex < widget.news.length - 1)
                _buildTiltedCard(currentCardIndex + 1),
              if (currentCardIndex < widget.news.length)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isAnimating
                      ? SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _isMovingForward
                                ? Tween<double>(begin: 1.0, end: 0.0)
                                    .animate(_animationController)
                                : Tween<double>(begin: 0.0, end: 1.0)
                                    .animate(_animationController),
                            child: FeaturedNewsCard(
                              article: widget.news[_isMovingForward
                                  ? currentCardIndex
                                  : currentCardIndex - 1],
                              user: widget.user,
                              cardIndex: _isMovingForward
                                  ? currentCardIndex
                                  : currentCardIndex - 1,
                              showActionButtons: false, // Hide action buttons in swipe mode
                            ),
                          ),
                        )
                      : FeaturedNewsCard(
                          article: widget.news[currentCardIndex],
                          user: widget.user,
                          cardIndex: currentCardIndex,
                          showActionButtons: false, // Hide action buttons in swipe mode
                        ),
                ),
            ],
          ),
        ),

        // Action buttons
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: _buildActionButtons(),
        ),

        // Progress dots
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: _buildProgressDots(),
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
          size: 55,
          onPressed: currentCardIndex < widget.news.length ? _swipeLeft : null,
        ),
        const SizedBox(width: 12),

        // Comment button
        _buildActionButton(
          icon: Icons.comment_outlined,
          color: const Color(0xFF8B5CF6),
          size: 50,
          onPressed: currentCardIndex < widget.news.length ? _handleComment : null,
        ),
        const SizedBox(width: 12),

        // Read later button (swipe up)
        _buildActionButton(
          icon: Icons.schedule,
          color: const Color(0xFF3B82F6),
          size: 50,
          onPressed: currentCardIndex < widget.news.length ? _swipeUp : null,
        ),
        const SizedBox(width: 12),

        // Share button
        _buildActionButton(
          icon: Icons.share_outlined,
          color: const Color(0xFFF59E0B),
          size: 50,
          onPressed: currentCardIndex < widget.news.length ? _handleShare : null,
        ),
        const SizedBox(width: 12),

        // Save button (swipe right)
        _buildActionButton(
          icon: Icons.favorite,
          color: const Color(0xFF10B981),
          size: 55,
          onPressed: currentCardIndex < widget.news.length ? _swipeRight : null,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onPressed != null ? color : color.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.45,
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    // Show max 9 dots, with current one highlighted
    final int maxDots = 9;
    final int totalArticles = widget.news.length;
    final int visibleDots = totalArticles > maxDots ? maxDots : totalArticles;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(visibleDots, (index) {
            final bool isActive = index == currentCardIndex;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.black.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
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
              'No articles available',
              style: KAppTextStyles.headlineMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for fresh content!',
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

  Widget _buildCompletedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 80,
              color: KAppColors.primary,
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
              'You\'ve swiped through all articles.\nCheck back later for more news!',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiltedCard(int index) {
    return Transform.scale(
      scale: 0.95, // Make background card slightly smaller
      child: Transform.translate(
        offset: const Offset(0, 10), // Push it down slightly
        child: Opacity(
          opacity: 0.5, // Make it semi-transparent
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FeaturedNewsCard(
              article: widget.news[index],
              isBackground: true,
              user: widget.user,
              cardIndex: index,
              showActionButtons: false, // Hide action buttons in swipe mode
            ),
          ),
        ),
      ),
    );
  }
}