import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/highlight_model.dart';
import 'package:the_news/service/notes_highlights_service.dart';

/// Widget that allows text selection and highlighting
class HighlightableTextWidget extends StatefulWidget {
  const HighlightableTextWidget({
    super.key,
    required this.text,
    required this.articleId,
    required this.articleTitle,
    this.textStyle,
  });

  final String text;
  final String articleId;
  final String articleTitle;
  final TextStyle? textStyle;

  @override
  State<HighlightableTextWidget> createState() => _HighlightableTextWidgetState();
}

class _HighlightableTextWidgetState extends State<HighlightableTextWidget> {
  final NotesHighlightsService _highlightService = NotesHighlightsService.instance;

  @override
  void initState() {
    super.initState();
    _highlightService.addListener(_onHighlightsChanged);
  }

  @override
  void dispose() {
    _highlightService.removeListener(_onHighlightsChanged);
    super.dispose();
  }

  void _onHighlightsChanged() {
    if (mounted) setState(() {});
  }

  void _handleTextSelection(BuildContext context, String selectedText, int start, int end) {
    if (selectedText.trim().isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _HighlightColorPicker(
        selectedText: selectedText,
        onColorSelected: (color, note) async {
          final highlight = HighlightModel(
            highlightId: DateTime.now().millisecondsSinceEpoch.toString(),
            articleId: widget.articleId,
            articleTitle: widget.articleTitle,
            highlightedText: selectedText,
            startIndex: start,
            endIndex: end,
            color: color,
            createdAt: DateTime.now(),
            note: note,
          );

          await _highlightService.addHighlight(highlight);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Highlighted in ${color.label}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final highlights = _highlightService.getHighlightsForArticle(widget.articleId);

    return SelectableText.rich(
      TextSpan(
        children: _buildTextSpansWithHighlights(widget.text, highlights),
      ),
      style: widget.textStyle,
      onSelectionChanged: (selection, cause) {
        if (selection.isCollapsed || selection.start == selection.end) return;

        final selectedText = widget.text.substring(selection.start, selection.end);
        _handleTextSelection(context, selectedText, selection.start, selection.end);
      },
    );
  }

  List<TextSpan> _buildTextSpansWithHighlights(String text, List<HighlightModel> highlights) {
    if (highlights.isEmpty) {
      return [TextSpan(text: text, style: widget.textStyle)];
    }

    // Sort highlights by start index
    final sortedHighlights = List<HighlightModel>.from(highlights)
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    final spans = <TextSpan>[];
    int currentIndex = 0;

    for (final highlight in sortedHighlights) {
      // Add text before highlight
      if (currentIndex < highlight.startIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, highlight.startIndex),
          style: widget.textStyle,
        ));
      }

      // Add highlighted text
      spans.add(TextSpan(
        text: text.substring(highlight.startIndex, highlight.endIndex),
        style: widget.textStyle?.copyWith(
          backgroundColor: Color(highlight.color.value).withValues(alpha: 0.3),
          color: KAppColors.getOnBackground(context),
        ),
      ));

      currentIndex = highlight.endIndex;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: widget.textStyle,
      ));
    }

    return spans;
  }
}

/// Color picker bottom sheet for selecting highlight color
class _HighlightColorPicker extends StatefulWidget {
  const _HighlightColorPicker({
    required this.selectedText,
    required this.onColorSelected,
  });

  final String selectedText;
  final Function(HighlightColor color, String? note) onColorSelected;

  @override
  State<_HighlightColorPicker> createState() => _HighlightColorPickerState();
}

class _HighlightColorPickerState extends State<_HighlightColorPicker> {
  final TextEditingController _noteController = TextEditingController();
  bool _showNoteField = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KAppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Selected text preview
          Text(
            'Highlight',
            style: KAppTextStyles.titleMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.selectedText.length > 100
                  ? '${widget.selectedText.substring(0, 100)}...'
                  : widget.selectedText,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 24),

          // Color selection
          Text(
            'Choose color',
            style: KAppTextStyles.labelMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: HighlightColor.values.map((color) {
              return InkWell(
                onTap: () {
                  final note = _showNoteField && _noteController.text.isNotEmpty
                      ? _noteController.text
                      : null;
                  widget.onColorSelected(color, note);
                },
                child: Container(
                  width: (MediaQuery.of(context).size.width - 96) / 3,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(color.value).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(color.value).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(color.value),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        color.label,
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        color.description,
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Add note toggle
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showNoteField = !_showNoteField;
              });
            },
            icon: Icon(
              _showNoteField ? Icons.remove_circle_outline : Icons.add_circle_outline,
              size: 20,
            ),
            label: Text(_showNoteField ? 'Remove note' : 'Add note'),
          ),

          // Note field
          if (_showNoteField) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Add your thoughts...',
                filled: true,
                fillColor: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
