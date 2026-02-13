import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/view/comments/comments_page.dart';
import 'package:the_news/service/comments_service.dart';

class CommentSection extends StatelessWidget {
  CommentSection({
    super.key,
    required this.commentCount,
    required this.article,
    required this.user,
  });

  final int commentCount;
  final ArticleModel article;
  final RegisterLoginUserSuccessModel user;
  final CommentsService _commentsService = CommentsService.instance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.comment_outlined, color: KAppColors.getOnBackground(context).withValues(alpha: 0.7), size: 20),
                const SizedBox(width: KDesignConstants.spacing12),
                Text(
                  'Comments ($commentCount)',
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommentsPage(
                      article: article,
                      user: user,
                    ),
                  ),
                );
              },
              child: Text(
                'View All',
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: KDesignConstants.spacing16),
        if (commentCount == 0)
          _buildEmptyCommentsState(context)
        else
          _buildCommentsPreview(context),
        const SizedBox(height: KDesignConstants.spacing16),
        _buildCommentInput(context),
      ],
    );
  }

  Widget _buildEmptyCommentsState(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: KDesignConstants.paddingLg,
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.comment_outlined,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
              size: 48,
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            Text(
              'No comments yet',
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to share your thoughts',
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsPreview(BuildContext context) {
    return FutureBuilder<List<CommentModel>>(
      future: _commentsService.getComments(
        article.articleId,
        userId: user.userId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: KDesignConstants.paddingLg,
            decoration: BoxDecoration(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
              borderRadius: KBorderRadius.lg,
              border: Border.all(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      KAppColors.getPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                Text(
                  'Loading comments...',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        final comments = snapshot.data ?? [];
        if (comments.isEmpty) {
          return _buildEmptyCommentsState(context);
        }

        final preview = comments.take(2).toList();

        return Container(
          width: double.infinity,
          padding: KDesignConstants.paddingLg,
          decoration: BoxDecoration(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
            borderRadius: KBorderRadius.lg,
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Latest comments',
                style: KAppTextStyles.labelLarge.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing12),
              ...preview.map((comment) => Padding(
                    padding: const EdgeInsets.only(bottom: KDesignConstants.spacing12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: KAppColors.getPrimary(context).withValues(alpha: 0.15),
                          child: Text(
                            comment.userName.isNotEmpty
                                ? comment.userName[0].toUpperCase()
                                : 'U',
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: KAppColors.getPrimary(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: KDesignConstants.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.userName,
                                style: KAppTextStyles.bodySmall.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.text,
                                style: KAppTextStyles.bodySmall.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentsPage(
                        article: article,
                        user: user,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View all comments',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommentsPage(
              article: article,
              user: user,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: KAppColors.info,
              child: Icon(Icons.person, size: 16, color: KAppColors.getOnPrimary(context)),
            ),
            const SizedBox(width: KDesignConstants.spacing12),
            Expanded(
              child: Text(
                'Add a comment...',
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.54),
                ),
              ),
            ),
            Icon(Icons.send, color: KAppColors.getOnBackground(context).withValues(alpha: 0.54), size: 20),
          ],
        ),
      ),
    );
  }
}
