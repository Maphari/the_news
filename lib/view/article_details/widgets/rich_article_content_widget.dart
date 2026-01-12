import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/enriched_article_model.dart';
import 'package:the_news/service/reading_preferences_service.dart';
import 'package:the_news/view/widgets/highlightable_text_widget.dart';

/// Rich article content widget that displays structured content with embedded images
/// Provides a magazine-like reading experience with proper formatting
class RichArticleContentWidget extends StatelessWidget {
  const RichArticleContentWidget({
    super.key,
    required this.structuredContent,
    required this.articleId,
    required this.articleTitle,
  });

  final List<ContentBlock> structuredContent;
  final String articleId;
  final String articleTitle;

  @override
  Widget build(BuildContext context) {
    final prefsService = ReadingPreferencesService.instance;

    return ListenableBuilder(
      listenable: prefsService,
      builder: (context, _) {
        final scaleFactor = prefsService.getTextScaleFactor();
        final lineHeight = prefsService.getLineHeight();
        final fontFamily = prefsService.getFontFamily();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: structuredContent.map((block) {
            return _buildContentBlock(
              context,
              block,
              scaleFactor,
              lineHeight,
              fontFamily ?? 'System',
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildContentBlock(
    BuildContext context,
    ContentBlock block,
    double scaleFactor,
    double lineHeight,
    String fontFamily,
  ) {
    switch (block.type) {
      case ContentBlockType.heading:
        return _buildHeading(context, block, scaleFactor, fontFamily);

      case ContentBlockType.subheading:
        return _buildSubheading(context, block, scaleFactor, fontFamily);

      case ContentBlockType.paragraph:
        return _buildParagraph(
          context,
          block,
          scaleFactor,
          lineHeight,
          fontFamily,
        );

      case ContentBlockType.image:
        return _buildImage(context, block);
    }
  }

  Widget _buildHeading(
    BuildContext context,
    ContentBlock block,
    double scaleFactor,
    String fontFamily,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Text(
        block.content,
        style: KAppTextStyles.headlineMedium.copyWith(
          color: KAppColors.getOnBackground(context),
          fontSize: 28 * scaleFactor,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildSubheading(
    BuildContext context,
    ContentBlock block,
    double scaleFactor,
    String fontFamily,
  ) {
    final level = block.level ?? 2;
    final fontSize = level == 2
        ? 24.0
        : level == 3
            ? 20.0
            : 18.0;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        block.content,
        style: KAppTextStyles.titleLarge.copyWith(
          color: KAppColors.getOnBackground(context),
          fontSize: fontSize * scaleFactor,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildParagraph(
    BuildContext context,
    ContentBlock block,
    double scaleFactor,
    double lineHeight,
    String fontFamily,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: HighlightableTextWidget(
        text: block.content,
        articleId: articleId,
        articleTitle: articleTitle,
        textStyle: KAppTextStyles.bodyLarge.copyWith(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.9),
          height: lineHeight,
          fontSize: 16 * scaleFactor,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ContentBlock block) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              block.content,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 250,
                  color: Colors.grey.withValues(alpha: 0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey.withValues(alpha: 0.5),
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image unavailable',
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (block.caption != null && block.caption!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              block.caption!,
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (block.alt != null && block.alt!.isNotEmpty && (block.caption == null || block.caption!.isEmpty)) ...[
            const SizedBox(height: 8),
            Text(
              block.alt!,
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
