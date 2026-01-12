import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/reading_preferences_service.dart';
import 'package:the_news/view/widgets/highlightable_text_widget.dart';

class ArticleContentSection extends StatelessWidget {
  const ArticleContentSection({
    super.key,
    required this.content,
    required this.articleId,
    required this.articleTitle,
  });

  final String content;
  final String articleId;
  final String articleTitle;

  @override
  Widget build(BuildContext context) {
    final prefsService = ReadingPreferencesService.instance;

    // Split content into paragraphs for better readability
    final paragraphs = content.split('\n').where((p) => p.trim().isNotEmpty).toList();

    return ListenableBuilder(
      listenable: prefsService,
      builder: (context, _) {
        final scaleFactor = prefsService.getTextScaleFactor();
        final lineHeight = prefsService.getLineHeight();
        final fontFamily = prefsService.getFontFamily();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...paragraphs.map((paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: HighlightableTextWidget(
                text: paragraph,
                articleId: articleId,
                articleTitle: articleTitle,
                textStyle: KAppTextStyles.bodyLarge.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.9),
                  height: lineHeight,
                  fontSize: 16 * scaleFactor,
                  fontFamily: fontFamily,
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}
