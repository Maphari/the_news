import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_news/utils/share_utils.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/engagement_service.dart';
import 'package:the_news/service/auth_service.dart';

/// Service for social sharing and community features
class SocialSharingService {
  static final instance = SocialSharingService._init();
  SocialSharingService._init();

  final EngagementService _engagementService = EngagementService.instance;
  final AuthService _authService = AuthService();

  /// Share an article via system share sheet
  Future<void> shareArticle(
    ArticleModel article, {
    String? customText,
    BuildContext? context,
  }) async {
    try {
      final text = customText ?? _generateShareText(article);

      if (context != null) {
        await ShareUtils.shareText(context, text, subject: article.title);
      } else {
        await ShareUtils.shareTextWithoutContext(text, subject: article.title);
      }

      log('📤 Article shared: ${article.title}');
    } catch (e) {
      log('⚠️ Error sharing article: $e');
      rethrow;
    }
  }

  /// Share an article with a specific highlight/quote
  Future<void> shareQuote({
    required ArticleModel article,
    required String quote,
    String? note,
    BuildContext? context,
  }) async {
    try {
      final text = _generateQuoteShareText(article, quote, note);

      if (context != null) {
        await ShareUtils.shareText(context, text, subject: 'Quote from ${article.title}');
      } else {
        await ShareUtils.shareTextWithoutContext(
          text,
          subject: 'Quote from ${article.title}',
        );
      }

      log('💬 Quote shared from: ${article.title}');
    } catch (e) {
      log('⚠️ Error sharing quote: $e');
      rethrow;
    }
  }

  /// Share article with image (if available)
  Future<void> shareWithImage({
    required ArticleModel article,
    String? imagePath,
    BuildContext? context,
  }) async {
    try {
      if (imagePath != null) {
        if (context != null) {
          await ShareUtils.shareFiles(
            context,
            [XFile(imagePath)],
            text: _generateShareText(article),
          );
        } else {
          await ShareUtils.shareFilesWithoutContext(
            [XFile(imagePath)],
            text: _generateShareText(article),
          );
        }
      } else {
        await shareArticle(article, context: context);
      }

      log('📷 Article with image shared: ${article.title}');
    } catch (e) {
      log('⚠️ Error sharing with image: $e');
      rethrow;
    }
  }

  /// Share to specific platform (requires platform-specific implementation)
  Future<void> shareToPlatform({
    required ArticleModel article,
    required SocialPlatform platform,
    BuildContext? context,
  }) async {
    // This would require platform-specific deep linking
    // For now, use system share and let user choose
    await shareArticle(
      article,
      customText: _generatePlatformSpecificText(article, platform),
      context: context,
    );
  }

  /// Record a share (and optionally publish to feed)
  Future<bool> recordShareActivity(
    ArticleModel article, {
    String platform = 'system',
    bool shareToFeed = true,
    BuildContext? context,
  }) async {
    try {
      final userData = await _authService.getCurrentUser();
      final userId = userData?['id'] as String? ?? userData?['userId'] as String?;
      if (userId == null) return false;
      final result = await _engagementService.shareArticleWithResult(
        userId,
        article.articleId,
        platform: platform,
        shareToFeed: shareToFeed,
      );
      if (result.success) return true;
      if (result.alreadyShared && context != null && context.mounted) {
        final shouldReshare = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Already Shared'),
            content: const Text(
              'You already shared this article. Do you want to share it again?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Share Again'),
              ),
            ],
          ),
        );
        if (shouldReshare == true) {
          final reshareResult = await _engagementService.shareArticleWithResult(
            userId,
            article.articleId,
            platform: platform,
            shareToFeed: shareToFeed,
            forceReshare: true,
          );
          return reshareResult.success;
        }
        return false;
      }
      return false;
    } catch (e) {
      log('⚠️ Error recording share activity: $e');
      return false;
    }
  }

  /// Generate share text for article
  String _generateShareText(ArticleModel article) {
    final categories = article.category.isNotEmpty
        ? article.category.map((c) => '#${c.replaceAll(' ', '')}').join(' ')
        : '#News';

    return '''
${article.title}

${article.description}

Source: ${article.sourceName}
${article.link}

$categories
''';
  }

  /// Generate share text for quote
  String _generateQuoteShareText(
    ArticleModel article,
    String quote,
    String? note,
  ) {
    final noteText = note != null ? '\n\n💭 $note' : '';

    return '''
"$quote"

From: ${article.title}
Source: ${article.sourceName}$noteText

${article.link}
''';
  }

  /// Generate platform-specific share text
  String _generatePlatformSpecificText(
    ArticleModel article,
    SocialPlatform platform,
  ) {
    switch (platform) {
      case SocialPlatform.twitter:
        // Twitter has character limit
        return '${article.title.substring(0, article.title.length > 200 ? 200 : article.title.length)}...\n\n${article.link}';

      case SocialPlatform.facebook:
      case SocialPlatform.linkedin:
        return _generateShareText(article);

      case SocialPlatform.whatsapp:
        return '📰 ${article.title}\n\n${article.description}\n\n${article.link}';

      case SocialPlatform.email:
        return _generateShareText(article);
    }
  }

  /// Show share dialog with options
  Future<void> showShareDialog(
    BuildContext context,
    ArticleModel article,
  ) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => ShareDialog(
        article: article,
        parentContext: context,
      ),
    );
  }
}

/// Social platforms enum
enum SocialPlatform { twitter, facebook, linkedin, whatsapp, email }

/// Share dialog widget
class ShareDialog extends StatefulWidget {
  const ShareDialog({
    super.key,
    required this.article,
    required this.parentContext,
  });

  final ArticleModel article;
  final BuildContext parentContext;

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  bool _shareToFeed = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Share Article',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Share to feed toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Share to feed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Switch(
                  value: _shareToFeed,
                  onChanged: (value) {
                    setState(() => _shareToFeed = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Share options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareButton(
                  icon: Icons.share,
                  label: 'System',
                  onTap: () async {
                    Navigator.pop(context);
                    final canShare = await SocialSharingService.instance
                        .recordShareActivity(
                      widget.article,
                      platform: 'system',
                      shareToFeed: _shareToFeed,
                      context: widget.parentContext,
                    );
                    if (canShare) {
                      if (!widget.parentContext.mounted) return;
                      await SocialSharingService.instance
                          .shareArticle(
                            widget.article,
                            context: widget.parentContext,
                          );
                    }
                  },
                ),
                _ShareButton(
                  icon: Icons.link,
                  label: 'Copy Link',
                  onTap: () {
                    Navigator.pop(context);
                    // Copy to clipboard implementation
                  },
                ),
                _ShareButton(
                  icon: Icons.email,
                  label: 'Email',
                  onTap: () async {
                    Navigator.pop(context);
                    final canShare = await SocialSharingService.instance
                        .recordShareActivity(
                      widget.article,
                      platform: 'email',
                      shareToFeed: _shareToFeed,
                      context: widget.parentContext,
                    );
                    if (canShare) {
                      if (!widget.parentContext.mounted) return;
                      await SocialSharingService.instance.shareToPlatform(
                        article: widget.article,
                        platform: SocialPlatform.email,
                        context: widget.parentContext,
                      );
                    }
                  },
                ),
                _ShareButton(
                  icon: Icons.chat,
                  label: 'Message',
                  onTap: () async {
                    Navigator.pop(context);
                    final canShare = await SocialSharingService.instance
                        .recordShareActivity(
                      widget.article,
                      platform: 'whatsapp',
                      shareToFeed: _shareToFeed,
                      context: widget.parentContext,
                    );
                    if (canShare) {
                      if (!widget.parentContext.mounted) return;
                      await SocialSharingService.instance.shareToPlatform(
                        article: widget.article,
                        platform: SocialPlatform.whatsapp,
                        context: widget.parentContext,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Custom share with note
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showCustomShareDialog(widget.parentContext);
              },
              icon: const Icon(Icons.edit_note),
              label: const Text('Add Note and Share'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomShareDialog(article: widget.article),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// Dialog for custom share with note
class CustomShareDialog extends StatefulWidget {
  const CustomShareDialog({super.key, required this.article});

  final ArticleModel article;

  @override
  State<CustomShareDialog> createState() => _CustomShareDialogState();
}

class _CustomShareDialogState extends State<CustomShareDialog> {
  final _noteController = TextEditingController();
  bool _shareToFeed = true;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Your Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Why are you sharing this?',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 280,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Share to feed',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: _shareToFeed,
                onChanged: (value) {
                  setState(() => _shareToFeed = value);
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final customText =
                '''
${widget.article.title}

💭 ${_noteController.text}

${widget.article.link}
''';
            Navigator.pop(context);
            final canShare = await SocialSharingService.instance
                .recordShareActivity(
              widget.article,
              platform: 'custom',
              shareToFeed: _shareToFeed,
              context: context.mounted ? context : null,
            );
            if (canShare) {
              await SocialSharingService.instance.shareArticle(
                widget.article,
                customText: customText,
                context: context.mounted ? context : null,
              );
            }
          },
          child: const Text('Share'),
        ),
      ],
    );
  }
}

/// Model for user highlight/annotation
class ArticleHighlight {
  final String id;
  final String articleId;
  final String userId;
  final String userName;
  final String selectedText;
  final String? note;
  final DateTime createdAt;
  final int likes;
  final bool isPublic;

  const ArticleHighlight({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.userName,
    required this.selectedText,
    this.note,
    required this.createdAt,
    this.likes = 0,
    this.isPublic = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'article_id': articleId,
      'user_id': userId,
      'user_name': userName,
      'selected_text': selectedText,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'likes': likes,
      'is_public': isPublic,
    };
  }

  factory ArticleHighlight.fromJson(Map<String, dynamic> json) {
    return ArticleHighlight(
      id: json['id'],
      articleId: json['article_id'],
      userId: json['user_id'],
      userName: json['user_name'],
      selectedText: json['selected_text'],
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      likes: json['likes'] ?? 0,
      isPublic: json['is_public'] ?? false,
    );
  }
}
