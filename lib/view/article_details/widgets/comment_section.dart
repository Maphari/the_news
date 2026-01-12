import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/view/comments/comments_page.dart';

class CommentSection extends StatelessWidget {
  const CommentSection({
    super.key,
    required this.commentCount,
    required this.article,
    required this.user,
  });

  final int commentCount;
  final ArticleModel article;
  final RegisterLoginUserSuccessModel user;

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
                const SizedBox(width: 12),
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
                  color: Colors.blue.shade300,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (commentCount == 0) _buildEmptyCommentsState(context) else _buildComingSoonMessage(context),
        const SizedBox(height: 16),
        _buildCommentInput(context),
      ],
    );
  }

  Widget _buildEmptyCommentsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 12),
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
    );
  }

  Widget _buildComingSoonMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade300,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Comments feature coming soon! Stay tuned for updates.',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
              backgroundColor: Colors.blue.shade300,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 12),
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