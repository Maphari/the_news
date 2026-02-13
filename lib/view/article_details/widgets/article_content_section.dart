import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/reading_preferences_service.dart';
import 'package:the_news/view/widgets/highlightable_text_widget.dart';

/// Enhanced article content section with improved typography and readability
/// Provides a clean, magazine-like reading experience
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
    final paragraphs = content
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p.trim())
        .toList();

    if (paragraphs.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: prefsService,
      builder: (context, _) {
        final scaleFactor = prefsService.getTextScaleFactor();
        final lineHeight = prefsService.getLineHeight();
        final fontFamily = prefsService.getFontFamily();

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First paragraph with drop cap effect
              if (paragraphs.isNotEmpty)
                _buildFirstParagraph(
                  context,
                  paragraphs.first,
                  scaleFactor,
                  lineHeight,
                  fontFamily,
                ),

              // Rest of the paragraphs
              ...paragraphs.skip(1).map(
                (paragraph) => _buildParagraph(
                  context,
                  paragraph,
                  scaleFactor,
                  lineHeight,
                  fontFamily,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFirstParagraph(
    BuildContext context,
    String paragraph,
    double scaleFactor,
    double lineHeight,
    String? fontFamily,
  ) {
    if (paragraph.length < 2) {
      return _buildParagraph(context, paragraph, scaleFactor, lineHeight, fontFamily);
    }

    final firstLetter = paragraph[0].toUpperCase();
    final restOfParagraph = paragraph.substring(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 2),
            child: Text(
              firstLetter,
              style: TextStyle(
                fontSize: 56 * scaleFactor,
                fontWeight: FontWeight.w700,
                color: KAppColors.getPrimary(context),
                height: 0.9,
                fontFamily: fontFamily,
              ),
            ),
          ),
          Expanded(
            child: HighlightableTextWidget(
              text: restOfParagraph,
              articleId: articleId,
              articleTitle: articleTitle,
              textStyle:
                  _getBodyTextStyle(context, scaleFactor, lineHeight, fontFamily),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildParagraph(
    BuildContext context,
    String paragraph,
    double scaleFactor,
    double lineHeight,
    String? fontFamily,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: HighlightableTextWidget(
        text: paragraph,
        articleId: articleId,
        articleTitle: articleTitle,
        textStyle: _getBodyTextStyle(context, scaleFactor, lineHeight, fontFamily),
      ),
    );
  }

  TextStyle _getBodyTextStyle(
    BuildContext context,
    double scaleFactor,
    double lineHeight,
    String? fontFamily,
  ) {
    return TextStyle(
      fontSize: 17.5 * scaleFactor,
      fontWeight: FontWeight.w400,
      color: KAppColors.getOnBackground(context).withValues(alpha: 0.86),
      height: lineHeight + 0.35,
      fontFamily: fontFamily,
      letterSpacing: 0.12,
    );
  }
}
