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

enum SwipeDirection { left, right, up }

class NewsCardStack extends StatefulWidget {
  const NewsCardStack({
    super.key,
    required this.news,
    required this.user,
    this.cardHeight,
  });

  final List<ArticleModel> news;
  final RegisterLoginUserSuccessModel user;
  final double? cardHeight;

  @override
  State<NewsCardStack> createState() => _NewsCardStackState();
}

class _NewsCardStackState extends State<NewsCardStack>
    with SingleTickerProviderStateMixin {
  int currentCardIndex = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  Offset _dragOffset = Offset.zero;
  double _dragRotation = 0.0;
  bool _isAnimating = false;
  Size _stackSize = Size.zero;

  final DislikedArticlesService _dislikedArticlesService = DislikedArticlesService.instance;
  final SavedArticlesService _savedArticlesService = SavedArticlesService.instance;
  final EngagementService _engagementService = EngagementService.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_animationController);
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.0)
        .animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _performSwipe(SwipeDirection direction, Size size) {
    if (_isAnimating || currentCardIndex >= widget.news.length) return;

    final article = widget.news[currentCardIndex];
    Offset targetOffset;
    double targetRotation;
    Color feedbackColor;
    IconData feedbackIcon;
    String feedbackMessage;

    switch (direction) {
      case SwipeDirection.left:
        HapticService.error();
        _dislikedArticlesService.dislikeArticle(widget.user.userId, article.articleId);
        feedbackMessage = 'Article hidden';
        feedbackIcon = Icons.thumb_down;
        feedbackColor = const Color(0xFFEF4444);
        targetOffset = Offset(-size.width * 1.3, -size.height * 0.2);
        targetRotation = -0.35;
        break;
      case SwipeDirection.right:
        HapticService.success();
        _savedArticlesService.saveArticle(
          widget.user.userId,
          article.articleId,
          article: article,
        );
        feedbackMessage = 'Saved!';
        feedbackIcon = Icons.bookmark;
        feedbackColor = const Color(0xFF10B981);
        targetOffset = Offset(size.width * 1.4, size.height * 0.2);
        targetRotation = 0.35;
        break;
      case SwipeDirection.up:
        HapticService.light();
        _savedArticlesService.saveArticle(
          widget.user.userId,
          article.articleId,
          article: article,
        );
        feedbackMessage = 'Saved for later!';
        feedbackIcon = Icons.schedule;
        feedbackColor = const Color(0xFF3B82F6);
        targetOffset = Offset(0, -size.height * 1.1);
        targetRotation = 0.0;
        break;
    }

    _showFeedback(feedbackMessage, feedbackIcon, feedbackColor);

    _slideAnimation = Tween<Offset>(begin: _dragOffset, end: targetOffset).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _rotationAnimation = Tween<double>(begin: _dragRotation, end: targetRotation).
        animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );

    setState(() {
      _isAnimating = true;
    });

    _animationController.forward().then((_) {
      setState(() {
        currentCardIndex++;
        _isAnimating = false;
        _dragOffset = Offset.zero;
        _dragRotation = 0.0;
      });
      _animationController.reset();
    });
  }

  void _resetCard() {
    if (_isAnimating) return;

    _slideAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );
    _rotationAnimation = Tween<double>(begin: _dragRotation, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    setState(() {
      _isAnimating = true;
    });

    _animationController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
          _dragOffset = Offset.zero;
          _dragRotation = 0.0;
        });
      }
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

      await _engagementService.shareArticle(
        widget.user.userId,
        article.articleId,
      );
    } catch (_) {
      // ignore
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragOffset += details.delta;
      _dragRotation = (_dragOffset.dx / (_stackSize.width > 0 ? _stackSize.width : 360)) * 0.2;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset.dx.abs() < 1 && details.velocity.pixelsPerSecond.distance < 100) {
      _resetCard();
      return;
    }

    final size = Size(
      _stackSize.width > 0 ? _stackSize.width : MediaQuery.of(context).size.width,
      _stackSize.height > 0 ? _stackSize.height : MediaQuery.of(context).size.height * 0.6,
    );

    if (_dragOffset.dx < -160 || details.velocity.pixelsPerSecond.dx < -900) {
      _performSwipe(SwipeDirection.left, size);
    } else if (_dragOffset.dx > 160 || details.velocity.pixelsPerSecond.dx > 900) {
      _performSwipe(SwipeDirection.right, size);
    } else if (_dragOffset.dy < -160 || details.velocity.pixelsPerSecond.dy < -900) {
      _performSwipe(SwipeDirection.up, size);
    } else {
      _resetCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.news.isEmpty) {
      return _buildEmptyState();
    }

    if (currentCardIndex >= widget.news.length) {
      return _buildCompletedState();
    }

    return LayoutBuilder(builder: (context, constraints) {
      _stackSize = Size(constraints.maxWidth, constraints.maxHeight);
      final cardHeight = widget.cardHeight ?? (_stackSize.height.isFinite && _stackSize.height > 0
          ? _stackSize.height
          : MediaQuery.of(context).size.height * 0.6);

      return Stack(
        children: [
          GestureDetector(
            onPanUpdate: _handleDragUpdate,
            onPanEnd: _handleDragEnd,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (currentCardIndex < widget.news.length - 1)
                  _buildTiltedCard(currentCardIndex + 1, cardHeight),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final offset = _isAnimating ? _slideAnimation.value : _dragOffset;
                      final rotation = _isAnimating ? _rotationAnimation.value : _dragRotation;
                      return Transform.translate(
                        offset: offset,
                        child: Transform.rotate(
                          angle: rotation,
                          child: child,
                        ),
                      );
                    },
                    child: FeaturedNewsCard(
                      article: widget.news[currentCardIndex],
                      user: widget.user,
                      cardIndex: currentCardIndex,
                      showActionButtons: false,
                      height: cardHeight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: _buildActionButtons(),
          ),
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: _buildProgressDots(),
          ),
        ],
      );
    });
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionCircle(
          icon: Icons.close,
          color: const Color(0xFFEF4444),
          onPressed: currentCardIndex < widget.news.length
              ? () => _performSwipe(SwipeDirection.left, _stackSize)
              : null,
        ),
        const SizedBox(width: 12),
        _buildActionCircle(
          icon: Icons.comment_outlined,
          color: const Color(0xFF8B5CF6),
          onPressed: currentCardIndex < widget.news.length ? _handleComment : null,
        ),
        const SizedBox(width: 12),
        _buildActionCircle(
          icon: Icons.schedule,
          color: const Color(0xFF3B82F6),
          onPressed: currentCardIndex < widget.news.length
              ? () => _performSwipe(SwipeDirection.up, _stackSize)
              : null,
        ),
        const SizedBox(width: 12),
        _buildActionCircle(
          icon: Icons.share_outlined,
          color: const Color(0xFFF59E0B),
          onPressed: currentCardIndex < widget.news.length ? _handleShare : null,
        ),
        const SizedBox(width: 12),
        _buildActionCircle(
          icon: Icons.favorite,
          color: const Color(0xFF10B981),
          onPressed: currentCardIndex < widget.news.length
              ? () => _performSwipe(SwipeDirection.right, _stackSize)
              : null,
        ),
      ],
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 55,
        height: 55,
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
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildProgressDots() {
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
              width: isActive ? 20 : 8,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.black.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.25),
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

  Widget _buildTiltedCard(int index, double cardHeight) {
    return Transform.scale(
      scale: 0.95,
      child: Transform.translate(
        offset: const Offset(0, 10),
        child: Opacity(
          opacity: 0.4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FeaturedNewsCard(
              article: widget.news[index],
              isBackground: true,
              user: widget.user,
              cardIndex: index,
              showActionButtons: false,
              height: cardHeight,
            ),
          ),
        ),
      ),
    );
  }
}
