import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/service/social_sharing_service.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/engagement_service.dart';
import 'package:the_news/service/saved_articles_service.dart';

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
        article: widget.article,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleShare() async {
    await SocialSharingService.instance.showShareDialog(context, widget.article);
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = _engagementService.isArticleLiked(widget.article.articleId);
    final isSaved = _savedArticlesService.isArticleSaved(widget.article.articleId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionButton(
            icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
            isActive: isLiked,
            isLoading: _isLiking,
            onTap: _handleLike,
            buttonColor: widget.buttonColor,
          ),
          const SizedBox(width: KDesignConstants.spacing8),
          _ActionButton(
            icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
            isActive: isSaved,
            isLoading: _isSaving,
            onTap: _handleSave,
            buttonColor: widget.buttonColor,
          ),
          const SizedBox(width: KDesignConstants.spacing8),
          _ActionButton(
            icon: Icons.share_outlined,
            onTap: _handleShare,
            buttonColor: widget.buttonColor,
          ),
        ],
      ),
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
  });

  final IconData icon;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;
  final Color? buttonColor;

  @override
  Widget build(BuildContext context) {
    final baseColor = buttonColor ?? Colors.brown;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black.withOpacity(0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      Colors.black.withOpacity(0.5),
                    ),
                  ),
                )
              : Icon(
                  icon,
                  color: const Color(0xFF764C14),
                  size: 22,
                ),
        ),
      ),
    );
  }
}
