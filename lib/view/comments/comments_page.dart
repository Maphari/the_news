import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/comments_service.dart';
import 'package:the_news/service/realtime_comments_service.dart';
import 'package:timeago/timeago.dart' as timeago;

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

  @override
  void initState() {
    super.initState();
    _loadComments();
    _commentsService.addListener(_onCommentsChanged);
    // Start real-time listener for automatic comment updates
    _realtimeCommentsService.listenToArticleComments(
      widget.article.articleId,
      userId: widget.user.userId,
    );
  }

  @override
  void dispose() {
    _commentsService.removeListener(_onCommentsChanged);
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

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
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
      appBar: AppBar(
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: KAppColors.getOnBackground(context)),
          onPressed: () => Navigator.pop(context),
        ),
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
      ),
      body: Column(
        children: [
          // Comments list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 64,
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: KAppTextStyles.bodyLarge.copyWith(
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to comment!',
                              style: KAppTextStyles.bodyMedium.copyWith(
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadComments,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: KAppColors.getPrimary(context)),
                  const SizedBox(width: 8),
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
              boxShadow: [
                BoxShadow(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
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
                      hintText: 'Write a comment...',
                      hintStyle: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                        icon: const Icon(Icons.send),
                        color: KAppColors.getPrimary(context),
                        iconSize: 28,
                      ),
              ],
            ),
          ),
        ],
      ),
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
      padding: EdgeInsets.only(
        left: isReply ? 56 : 16,
        right: 16,
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: KAppColors.getOnBackground(context).withValues(alpha: 0.1)),
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
                radius: 18,
                backgroundColor: KAppColors.getPrimary(context),
                child: Text(
                  comment.userName.substring(0, 1).toUpperCase(),
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and time
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: KAppTextStyles.titleSmall.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(comment.createdAt),
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Comment text
                    Text(
                      comment.text,
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Actions
                    Row(
                      children: [
                        // Like button
                        InkWell(
                          onTap: onLike,
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
                                const SizedBox(width: 4),
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
                        const SizedBox(width: 16),

                        // Reply button
                        if (!isReply)
                          InkWell(
                            onTap: onReply,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.reply,
                                  size: 16,
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Reply',
                                  style: KAppTextStyles.bodySmall.copyWith(
                                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const Spacer(),

                        // Delete button (only for own comments)
                        if (isOwnComment)
                          InkWell(
                            onTap: onDelete,
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: const Color(0xFFEF5350),
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
            const SizedBox(height: 8),
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
