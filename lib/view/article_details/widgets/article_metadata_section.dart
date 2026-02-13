import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/view/publisher/publisher_profile_page.dart';

class ArticleMetadataSection extends StatelessWidget {
  const ArticleMetadataSection({
    super.key,
    required this.article,
    this.userId,
  });

  final ArticleModel article;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: KAppColors.getOnBackground(context).withValues(alpha: 0.7), size: 20),
              const SizedBox(width: KDesignConstants.spacing12),
              Text(
                'Article Information',
                style: KAppTextStyles.titleMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing16),
          _buildSourceRow(context),
          const SizedBox(height: KDesignConstants.spacing12),
          _buildMetadataRow('Category', article.category.join(', '), context),
          const SizedBox(height: KDesignConstants.spacing12),
          _buildMetadataRow('Country', article.country.join(', '), context),
          const SizedBox(height: KDesignConstants.spacing12),
          _buildMetadataRow('Language', article.language.toUpperCase(), context),
          const SizedBox(height: KDesignConstants.spacing12),
          _buildMetadataRow('Published', _formatDate(article.pubDate), context),
          if (article.aiOrg != null) ...[
            const SizedBox(height: KDesignConstants.spacing12),
            _buildMetadataRow('Organization', article.aiOrg!, context),
          ],
          const SizedBox(height: KDesignConstants.spacing12),
          _buildMetadataRow('Source Priority', article.sourcePriority.toString(), context),
        ],
      ),
    );
  }

  Widget _buildSourceRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            'Source',
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.54),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              if (userId == null) return;

              // Get user data from auth service
              final authService = AuthService();
              final userData = await authService.getCurrentUser();

              if (userData != null && context.mounted) {
                final user = RegisterLoginUserSuccessModel(
                  userId: userData['id'] ?? userData['userId'] ?? userId!,
                  email: userData['email'] ?? '',
                  name: userData['name'] ?? '',
                  token: '', // Not needed for navigation
                  createdAt: userData['createdAt']?.toString() ?? '',
                  updatedAt: userData['updatedAt']?.toString() ?? '',
                  lastLogin: userData['lastLogin']?.toString() ?? '',
                  message: '',
                  success: true,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublisherProfilePage(
                      publisherName: article.sourceName,
                      publisherIcon: article.sourceIcon,
                      user: user,
                    ),
                  ),
                );
              }
            },
            child: Text(
              article.sourceName,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getPrimary(context),
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.54),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
