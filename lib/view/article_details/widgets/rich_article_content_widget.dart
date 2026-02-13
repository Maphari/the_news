import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/enriched_article_model.dart';
import 'package:the_news/service/reading_preferences_service.dart';
import 'package:the_news/view/widgets/highlightable_text_widget.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

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

    if (structuredContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: prefsService,
      builder: (context, _) {
        final scaleFactor = prefsService.getTextScaleFactor();
        final lineHeight = prefsService.getLineHeight();
        final fontFamily = prefsService.getFontFamily();

        // Find the first paragraph for drop cap
        final firstParagraphIndex = structuredContent.indexWhere(
          (block) => block.type == ContentBlockType.paragraph,
        );

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: structuredContent.asMap().entries.map((entry) {
              final index = entry.key;
              final block = entry.value;
              final isFirstParagraph = index == firstParagraphIndex;

              return _buildContentBlock(
                context,
                block,
                scaleFactor,
                lineHeight,
                fontFamily ?? 'System',
                isFirstParagraph: isFirstParagraph,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildContentBlock(
    BuildContext context,
    ContentBlock block,
    double scaleFactor,
    double lineHeight,
    String fontFamily, {
    bool isFirstParagraph = false,
  }) {
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
          isFirstParagraph: isFirstParagraph,
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
    return Container(
      margin: const EdgeInsets.only(top: 32, bottom: 16),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
            width: 2,
          ),
        ),
      ),
      child: Text(
        block.content,
        style: TextStyle(
          fontSize: 26 * scaleFactor,
          fontWeight: FontWeight.w700,
          color: KAppColors.getOnBackground(context),
          fontFamily: fontFamily,
          height: 1.3,
          letterSpacing: -0.5,
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
    final fontSize = level == 2 ? 22.0 : level == 3 ? 19.0 : 17.0;

    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(
        block.content,
        style: TextStyle(
          fontSize: fontSize * scaleFactor,
          fontWeight: FontWeight.w600,
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.95),
          fontFamily: fontFamily,
          height: 1.35,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildParagraph(
    BuildContext context,
    ContentBlock block,
    double scaleFactor,
    double lineHeight,
    String fontFamily, {
    bool isFirstParagraph = false,
  }) {
    final text = block.content.trim();

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if it's a quote
    final isQuote = text.startsWith('"') ||
                    text.startsWith('"') ||
                    text.startsWith('\'');

    if (isQuote && text.length < 300) {
      return _buildQuote(context, text, scaleFactor, lineHeight, fontFamily);
    }

    // First paragraph with drop cap
    if (isFirstParagraph && text.length > 2) {
      return _buildDropCapParagraph(context, text, scaleFactor, lineHeight, fontFamily);
    }

    // Regular paragraph
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: HighlightableTextWidget(
        text: text,
        articleId: articleId,
        articleTitle: articleTitle,
        textStyle: _getBodyTextStyle(context, scaleFactor, lineHeight, fontFamily),
      ),
    );
  }

  Widget _buildDropCapParagraph(
    BuildContext context,
    String text,
    double scaleFactor,
    double lineHeight,
    String fontFamily,
  ) {
    final firstLetter = text[0].toUpperCase();
    final restOfText = text.substring(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drop cap letter
          Container(
            margin: const EdgeInsets.only(right: 12, top: 4),
            child: Text(
              firstLetter,
              style: TextStyle(
                fontSize: 56 * scaleFactor,
                fontWeight: FontWeight.w700,
                color: KAppColors.getPrimary(context),
                height: 0.85,
                fontFamily: fontFamily,
              ),
            ),
          ),
          // Rest of the paragraph
          Expanded(
            child: HighlightableTextWidget(
              text: restOfText,
              articleId: articleId,
              articleTitle: articleTitle,
              textStyle: _getBodyTextStyle(context, scaleFactor, lineHeight, fontFamily),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuote(
    BuildContext context,
    String text,
    double scaleFactor,
    double lineHeight,
    String fontFamily,
  ) {
    return Container(
      margin: KDesignConstants.paddingVerticalLg,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: KAppColors.getPrimary(context).withValues(alpha: 0.6),
            width: 3,
          ),
        ),
        color: KAppColors.getPrimary(context).withValues(alpha: 0.03),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: HighlightableTextWidget(
        text: text,
        articleId: articleId,
        articleTitle: articleTitle,
        textStyle: TextStyle(
          fontSize: 18 * scaleFactor,
          fontWeight: FontWeight.w500,
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.85),
          height: lineHeight + 0.1,
          fontStyle: FontStyle.italic,
          fontFamily: fontFamily,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ContentBlock block) {
    // Validate URL
    if (block.content.isEmpty || !block.content.startsWith('http')) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with rounded corners and shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: KBorderRadius.md,
              boxShadow: [
                BoxShadow(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: KBorderRadius.md,
              child: SafeNetworkImage(
                block.content,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                      borderRadius: KBorderRadius.md,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KAppColors.getPrimary(context),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                          const SizedBox(height: KDesignConstants.spacing12),
                          Text(
                            'Loading image...',
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                    borderRadius: KBorderRadius.md,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                        size: 40,
                      ),
                      const SizedBox(height: KDesignConstants.spacing8),
                      Text(
                        'Image unavailable',
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Caption
          if (block.caption != null && block.caption!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                block.caption!,
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.55),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ] else if (block.alt != null && block.alt!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                block.alt!,
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.55),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _getBodyTextStyle(
    BuildContext context,
    double scaleFactor,
    double lineHeight,
    String fontFamily,
  ) {
    return TextStyle(
      fontSize: 17 * scaleFactor,
      fontWeight: FontWeight.w400,
      color: KAppColors.getOnBackground(context).withValues(alpha: 0.87),
      height: lineHeight,
      fontFamily: fontFamily,
      letterSpacing: 0.15,
    );
  }
}
