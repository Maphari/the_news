import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/reading_list_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/service/auth_service.dart';

class AddToListHelper {
  static Future<void> showPickerAndAdd(
    BuildContext context,
    ArticleModel article,
  ) async {
    final social = SocialFeaturesBackendService.instance;
    final auth = AuthService();
    final user = await auth.getCurrentUser();
    final userId = user?['id'] as String? ?? user?['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to use reading lists'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final lists = await social.getUserReadingLists(userId);
    if (!context.mounted) return;

    if (lists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a reading list first in Social > My Space > Reading Lists'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedList = await showModalBottomSheet<ReadingList>(
      context: context,
      backgroundColor: KAppColors.getBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KAppColors.getOnBackground(sheetContext).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add to reading list',
                    style: KAppTextStyles.titleMedium.copyWith(
                      color: KAppColors.getOnBackground(sheetContext),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: lists.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final list = lists[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: KAppColors.getOnBackground(sheetContext).withValues(alpha: 0.1),
                          ),
                        ),
                        title: Text(list.name),
                        subtitle: Text('${list.articleCount} articles'),
                        trailing: const Icon(Icons.add),
                        onTap: () => Navigator.pop(sheetContext, list),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedList == null) return;
    try {
      await social.addArticleToList(selectedList.id, article.articleId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to "${selectedList.name}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add to list: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
