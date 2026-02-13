import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/offline_reading_service.dart';

/// Button widget for downloading articles for offline reading
class OfflineDownloadButton extends StatefulWidget {
  const OfflineDownloadButton({
    super.key,
    required this.article,
    this.size = 40,
    this.iconSize = 20,
  });

  final ArticleModel article;
  final double size;
  final double iconSize;

  @override
  State<OfflineDownloadButton> createState() => _OfflineDownloadButtonState();
}

class _OfflineDownloadButtonState extends State<OfflineDownloadButton> {
  final OfflineReadingService _offlineService = OfflineReadingService.instance;
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _offlineService,
      builder: (context, _) {
        final isCached = _offlineService.isArticleCached(widget.article.articleId);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isDownloading ? null : () => _handleDownloadToggle(isCached),
            borderRadius: BorderRadius.circular(widget.size / 2),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: isCached
                    ? KAppColors.success.withValues(alpha: 0.2)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCached
                      ? KAppColors.success
                      : KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: _isDownloading
                    ? SizedBox(
                        width: widget.iconSize,
                        height: widget.iconSize,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: KAppColors.success,
                        ),
                      )
                    : Icon(
                        isCached ? Icons.offline_pin : Icons.download_outlined,
                        size: widget.iconSize,
                        color: isCached
                            ? KAppColors.success
                            : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDownloadToggle(bool isCached) async {
    if (isCached) {
      // Remove from offline storage
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove from Offline'),
          content: const Text('Remove this article from offline storage?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _offlineService.removeFromQueue(widget.article.articleId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from offline storage'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Add to offline storage
      setState(() => _isDownloading = true);

      final success = await _offlineService.addToQueue(widget.article);

      setState(() => _isDownloading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Downloaded for offline reading'
                  : 'Failed to download. Storage limit reached.',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: success ? KAppColors.success : KAppColors.error,
          ),
        );
      }
    }
  }
}
