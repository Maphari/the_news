import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/comments_service.dart';
import 'package:the_news/service/realtime_comments_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:the_news/view/widgets/app_back_button.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({
    super.key,
    required this.article,
    required this.user,
  });

  final ArticleModel article;
  final RegisterLoginUserSuccessModel user;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final CommentsService _commentsService = CommentsService.instance;
  final RealtimeCommentsService _realtimeCommentsService = RealtimeCommentsService.instance;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _replyToCommentId;
  String? _replyToUserName;
  bool _realtimeFailed = false;
  bool _useRealtime = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _commentsService.addListener(_onCommentsChanged);
    _realtimeCommentsService.addListener(_onRealtimeStatusChanged);
    _useRealtime = _realtimeCommentsService.isEnabled;
    // Start real-time listener for automatic comment updates
    _startRealtimeIfEnabled();
  }

  @override
  void dispose() {
    _commentsService.removeListener(_onCommentsChanged);
    _realtimeCommentsService.removeListener(_onRealtimeStatusChanged);
    _commentController.dispose();
    _commentFocusNode.dispose();
    // Stop real-time listener when leaving comments page
    _realtimeCommentsService.stopListeningToArticle(widget.article.articleId);
    super.dispose();
  }

  void _onCommentsChanged() {
    if (mounted) {
      // Use cached comments from real-time updates
      final cachedComments = _commentsService.getCachedComments(widget.article.articleId);
      if (cachedComments != null) {
        setState(() {
          _comments = cachedComments;
        });
      }
    }
  }

  void _onRealtimeStatusChanged() {
    if (!mounted) return;
    if (_useRealtime != _realtimeCommentsService.isEnabled) {
      setState(() {
        _useRealtime = _realtimeCommentsService.isEnabled;
        _realtimeFailed = false;
      });
      if (_useRealtime) {
        _startRealtimeIfEnabled();
      } else {
        _realtimeCommentsService.stopListeningToArticle(widget.article.articleId);
      }
      return;
    }
    if (_realtimeFailed) return;
    final error = _realtimeCommentsService.getError(widget.article.articleId);
    if (error != null) {
      _realtimeFailed = true;
      _useRealtime = false;
      _loadComments(force: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Real-time comments unavailable. Showing latest from server.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startRealtimeIfEnabled() {
    if (_useRealtime && _realtimeCommentsService.isEnabled) {
      _realtimeCommentsService.listenToArticleComments(
        widget.article.articleId,
        userId: widget.user.userId,
      );
    }
  }

  void _toggleRealtime() {
    final nextValue = !_realtimeCommentsService.isEnabled;
    _realtimeCommentsService.setEnabled(nextValue);
    if (nextValue) {
      _startRealtimeIfEnabled();
      _loadComments(force: true);
    } else {
      _realtimeCommentsService.stopListeningToArticle(widget.article.articleId);
    }
  }

  Future<void> _loadComments({bool force = false}) async {
    setState(() => _isLoading = true);
    if (force) {
      _commentsService.clearCache();
    }
    final comments = await _commentsService.getComments(
      widget.article.articleId,
      userId: widget.user.userId,
    );
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final success = await _commentsService.addComment(
      articleId: widget.article.articleId,
      userId: widget.user.userId,
      userName: widget.user.name,
      text: text,
      parentCommentId: _replyToCommentId,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (success) {
        _commentController.clear();
        _replyToCommentId = null;
        _replyToUserName = null;
        _commentFocusNode.unfocus();
        _loadComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment')),
        );
      }
    }
  }

  void _replyToComment(CommentModel comment) {
    setState(() {
      _replyToCommentId = comment.id;
      _replyToUserName = comment.userName;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUserName = null;
    });
  }

  List<CommentModel> get _topLevelComments {
    return _comments.where((c) => c.isTopLevel).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      resizeToAvoidBottomInset: true,
      appBar: KAppBar(
        title: Text(
          'Comments',
          style: KAppTextStyles.headlineSmall.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            height: 1,
          ),
        ),
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: AppBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: _useRealtime ? 'Live updates on' : 'Live updates off',
            icon: Icon(
              _useRealtime ? Icons.wifi_tethering : Icons.wifi_tethering_off,
              color: _useRealtime
                  ? KAppColors.getPrimary(context)
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
            onPressed: _toggleRealtime,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderCard(),
          if (!_useRealtime)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
                  borderRadius: KBorderRadius.md,
                  border: Border.all(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sync_disabled,
                      size: 18,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: KDesignConstants.spacing8),
                    Expanded(
                      child: Text(
                        'Live updates off. Pull to refresh for latest.',
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleRealtime,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          // Comments list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadComments(force: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          itemCount: _topLevelComments.length,
                          itemBuilder: (context, index) {
                            final comment = _topLevelComments[index];
                            final replies = comment.getReplies(_comments);
                            return _CommentItem(
                              comment: comment,
                              replies: replies,
                              currentUserId: widget.user.userId,
                              onReply: () => _replyToComment(comment),
                              onDelete: () async {
                                final success = await _commentsService.deleteComment(
                                  commentId: comment.id,
                                  userId: widget.user.userId,
                                  articleId: widget.article.articleId,
                                );
                                if (success) _loadComments();
                              },
                              onLike: () async {
                                if (comment.isLiked) {
                                  await _commentsService.unlikeComment(
                                    comment.id,
                                    widget.user.userId,
                                    widget.article.articleId,
                                  );
                                } else {
                                  await _commentsService.likeComment(
                                    comment.id,
                                    widget.user.userId,
                                    widget.article.articleId,
                                  );
                                }
                                _loadComments();
                              },
                            );
                          },
                        ),
                      ),
          ),

          // Reply indicator
          if (_replyToCommentId != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
                borderRadius: KBorderRadius.xl,
                border: Border.all(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: KAppColors.getPrimary(context)),
                  const SizedBox(width: KDesignConstants.spacing8),
                  Expanded(
                    child: Text(
                      'Replying to $_replyToUserName',
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getPrimary(context),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: KAppColors.getPrimary(context)),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Comment input
          Container(
            decoration: BoxDecoration(
              color: KAppColors.getBackground(context),
              // boxShadow: [
              //   BoxShadow(
              //     color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
              //     blurRadius: 4,
              //     offset: const Offset(0, -2),
              //   ),
              // ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Share your perspective...',
                      hintStyle: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: KBorderRadius.xxl,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: KDesignConstants.spacing8),
                _isSubmitting
                    ? SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KAppColors.getPrimary(context),
                            ),
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: _submitComment,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        color: KAppColors.getOnPrimary(context),
                        iconSize: 20,
                        style: IconButton.styleFrom(
                          backgroundColor: KAppColors.getPrimary(context),
                          padding: const EdgeInsets.all(14),
                          shape: const CircleBorder(),
                        ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KAppColors.getPrimary(context).withValues(alpha: 0.12),
            KAppColors.getSecondary(context).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_outlined,
              color: KAppColors.getPrimary(context),
            ),
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: KDesignConstants.spacing4),
                Text(
                  '${_comments.length} replies',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: KDesignConstants.paddingLg,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      KAppColors.getPrimary(context).withValues(alpha: 0.12),
                      KAppColors.getSecondary(context).withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 56,
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing20),
              Text(
                'Start the conversation',
                style: KAppTextStyles.titleMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing8),
              Text(
                'Share a thought or ask a question about this story.',
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({
    required this.comment,
    required this.replies,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
    required this.onLike,
    this.isReply = false,
  });

  final CommentModel comment;
  final List<CommentModel> replies;
  final String currentUserId;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onLike;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    final isOwnComment = comment.userId == currentUserId;

    return Container(
      margin: EdgeInsets.only(
        left: isReply ? 28 : 0,
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                child: Text(
                  comment.userName.substring(0, 1).toUpperCase(),
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and time
                    Wrap(
                      spacing: KDesignConstants.spacing8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            comment.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KAppTextStyles.titleSmall.copyWith(
                              color: KAppColors.getOnBackground(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
                            borderRadius: KBorderRadius.lg,
                          ),
                          child: Text(
                            timeago.format(comment.createdAt),
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KDesignConstants.spacing4),

                    // Comment text
                    Text(
                      comment.text,
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                      ),
                    ),
                    const SizedBox(height: KDesignConstants.spacing8),

                    // Actions
                    Row(
                      children: [
                        // Like button
                        InkWell(
                          onTap: onLike,
                          borderRadius: KBorderRadius.lg,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: comment.isLiked
                                  ? KAppColors.getPrimary(context).withValues(alpha: 0.12)
                                  : KAppColors.getOnBackground(context).withValues(alpha: 0.04),
                              borderRadius: KBorderRadius.lg,
                              border: Border.all(
                                color: comment.isLiked
                                    ? KAppColors.getPrimary(context).withValues(alpha: 0.2)
                                    : KAppColors.getOnBackground(context).withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  comment.isLiked
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_outlined,
                                  size: 16,
                                  color: comment.isLiked
                                      ? KAppColors.getPrimary(context)
                                      : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                ),
                                if (comment.likeCount > 0) ...[
                                  const SizedBox(width: KDesignConstants.spacing4),
                                  Text(
                                    '${comment.likeCount}',
                                    style: KAppTextStyles.bodySmall.copyWith(
                                      color: comment.isLiked
                                          ? KAppColors.getPrimary(context)
                                          : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: KDesignConstants.spacing16),

                        // Reply button
                        if (!isReply)
                          InkWell(
                            onTap: onReply,
                            borderRadius: KBorderRadius.lg,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
                                borderRadius: KBorderRadius.lg,
                                border: Border.all(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.reply,
                                    size: 16,
                                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: KDesignConstants.spacing4),
                                  Text(
                                    'Reply',
                                    style: KAppTextStyles.bodySmall.copyWith(
                                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const Spacer(),

                        // Delete button (only for own comments)
                        if (isOwnComment)
                          InkWell(
                            onTap: onDelete,
                            borderRadius: KBorderRadius.lg,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF5350).withValues(alpha: 0.12),
                                borderRadius: KBorderRadius.lg,
                                border: Border.all(
                                  color: const Color(0xFFEF5350).withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Color(0xFFEF5350),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Replies
          if (replies.isNotEmpty) ...[
            const SizedBox(height: KDesignConstants.spacing8),
            ...replies.map((reply) => _CommentItem(
                  comment: reply,
                  replies: const [],
                  currentUserId: currentUserId,
                  onReply: () {},
                  onDelete: onDelete,
                  onLike: onLike,
                  isReply: true,
                )),
          ],
        ],
      ),
    );
  }
}
