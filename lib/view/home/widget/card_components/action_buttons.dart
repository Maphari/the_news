import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/engagement_service.dart';
import 'package:the_news/service/saved_articles_service.dart';
import 'package:the_news/view/comments/comments_page.dart';

class ActionButtons extends StatefulWidget {
  const ActionButtons({
    super.key,
    required this.article,
    required this.user,
    this.buttonColor,
  });

  final ArticleModel article;
  final RegisterLoginUserSuccessModel user;
  final Color? buttonColor;

  @override
  State<ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons> {
  final EngagementService _engagementService = EngagementService.instance;
  final SavedArticlesService _savedArticlesService = SavedArticlesService.instance;

  bool _isLiking = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Listen to service changes to update UI reactively
    _engagementService.addListener(_onEngagementChanged);
    _savedArticlesService.addListener(_onSavedArticlesChanged);
  }

  @override
  void dispose() {
    _engagementService.removeListener(_onEngagementChanged);
    _savedArticlesService.removeListener(_onSavedArticlesChanged);
    super.dispose();
  }

  void _onEngagementChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _onSavedArticlesChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _handleLike() async {
    if (_isLiking) return;

    setState(() => _isLiking = true);

    final isLiked = _engagementService.isArticleLiked(widget.article.articleId);

    if (isLiked) {
      await _engagementService.unlikeArticle(
        widget.user.userId,
        widget.article.articleId,
      );
    } else {
      await _engagementService.likeArticle(
        widget.user.userId,
        widget.article.articleId,
      );
    }

    if (mounted) {
      setState(() => _isLiking = false);
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final isSaved = _savedArticlesService.isArticleSaved(widget.article.articleId);

    if (isSaved) {
      await _savedArticlesService.unsaveArticle(
        widget.user.userId,
        widget.article.articleId,
      );
    } else {
      await _savedArticlesService.saveArticle(
        widget.user.userId,
        widget.article.articleId,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleShare() async {
    try {
      await Share.share(
        '${widget.article.title}\n\n${widget.article.description}\n\nRead more: ${widget.article.link}',
        subject: widget.article.title,
      );
    } catch (e) {
      // Handle share error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = _engagementService.isArticleLiked(widget.article.articleId);
    final isSaved = _savedArticlesService.isArticleSaved(widget.article.articleId);

    // Get engagement counts
    final likeCount = _engagementService.getLikeCount(widget.article.articleId);
    final commentCount = _engagementService.getCommentCount(widget.article.articleId);
    final shareCount = _engagementService.getShareCount(widget.article.articleId);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _ActionButton(
          icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
          isActive: isLiked,
          isLoading: _isLiking,
          onTap: _handleLike,
          buttonColor: widget.buttonColor,
          count: likeCount,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.comment_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommentsPage(
                  article: widget.article,
                  user: widget.user,
                ),
              ),
            );
          },
          buttonColor: widget.buttonColor,
          count: commentCount,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.share_outlined,
          onTap: _handleShare,
          buttonColor: widget.buttonColor,
          count: shareCount,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
          isActive: isSaved,
          isLoading: _isSaving,
          onTap: _handleSave,
          buttonColor: widget.buttonColor,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.isActive = false,
    this.isLoading = false,
    required this.onTap,
    this.buttonColor,
    this.count,
  });

  final IconData icon;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;
  final Color? buttonColor;
  final int? count;

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = buttonColor ?? Colors.brown;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
            ? baseColor.withValues(alpha: 0.3)
            : baseColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(baseColor.withValues(alpha: 0.6)),
                  ),
                )
              : Icon(
                  icon,
                  color: isActive
                    ? baseColor.withValues(alpha: 0.9)
                    : baseColor.withValues(alpha: 0.6),
                  size: 20,
                ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count!),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive
                    ? baseColor.withValues(alpha: 0.9)
                    : baseColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}