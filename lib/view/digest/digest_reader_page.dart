import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/daily_digest_model.dart';
import 'package:the_news/service/daily_digest_service.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/view/article_details/article_detail_page.dart';
import 'package:the_news/view/widgets/app_back_button.dart';

/// Page for reading a daily digest
class DigestReaderPage extends StatefulWidget {
  const DigestReaderPage({
    super.key,
    required this.digest,
  });

  final DailyDigest digest;

  @override
  State<DigestReaderPage> createState() => _DigestReaderPageState();
}

class _DigestReaderPageState extends State<DigestReaderPage> {
  final DailyDigestService _digestService = DailyDigestService.instance;
  final NewsProviderService _newsProvider = NewsProviderService.instance;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Mark as read when opened
    if (!widget.digest.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _digestService.markAsRead(widget.digest.digestId);
      });
    }
  }

  @override
  void dispose() {
    _digestService.stopReadingDigest();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _digestService.stopReadingDigest();
      setState(() => _isPlaying = false);
    } else {
      await _digestService.readDigestAloud(widget.digest);
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDigestHeader(),
                    const SizedBox(height: KDesignConstants.spacing24),
                    _buildDigestItems(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KAppColors.getBackground(context),
        border: Border(
          bottom: BorderSide(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: Text(
              widget.digest.title,
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Share button
          IconButton(
            onPressed: () => _digestService.shareDigest(context, widget.digest),
            icon: Icon(
              Icons.share_outlined,
              color: KAppColors.getOnBackground(context),
            ),
            tooltip: 'Share Digest',
          ),
          // Audio play button
          IconButton(
            onPressed: _toggleAudio,
            icon: Icon(
              _isPlaying ? Icons.stop_circle : Icons.play_circle_filled,
              color: KAppColors.getPrimary(context),
              size: 32,
            ),
            tooltip: _isPlaying ? 'Stop Audio' : 'Listen to Digest',
          ),
        ],
      ),
    );
  }

  Widget _buildDigestHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context).withValues(alpha: 0.08),
        borderRadius: KBorderRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: KAppColors.getPrimary(context),
                size: 24,
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Text(
                'Your Daily Digest',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Text(
            widget.digest.summary,
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigestItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.digest.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _buildDigestItem(item, index + 1),
        );
      }).toList(),
    );
  }

  Widget _buildDigestItem(DigestItem item, int number) {
    return Container(
      decoration: BoxDecoration(
        color: KAppColors.getBackground(context),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: KDesignConstants.paddingMd,
            decoration: BoxDecoration(
              color: _getItemTypeColor(item.type).withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getItemTypeColor(item.type).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color: _getItemTypeColor(item.type),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type.label,
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: _getItemTypeColor(item.type),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.category,
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: KDesignConstants.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline
                Text(
                  item.headline,
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: KDesignConstants.spacing12),

                // Summary
                Text(
                  item.summary,
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: KDesignConstants.spacing16),

                // Key points
                if (item.keyPoints.isNotEmpty) ...[
                  Text(
                    'Key Points:',
                    style: KAppTextStyles.labelMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing8),
                  ...item.keyPoints.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: KAppColors.getPrimary(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: KDesignConstants.spacing12),
                        Expanded(
                          child: Text(
                            point,
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: KDesignConstants.spacing16),
                ],

                // Why it matters
                Container(
                  padding: KDesignConstants.paddingSm,
                  decoration: BoxDecoration(
                    color: KAppColors.getPrimary(context).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: KAppColors.getPrimary(context),
                      ),
                      const SizedBox(width: KDesignConstants.spacing8),
                      Expanded(
                        child: Text(
                          item.whyItMatters,
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KDesignConstants.spacing12),

                // Read full article button
                TextButton.icon(
                  onPressed: () => _openFullArticle(item),
                  icon: Icon(
                    Icons.article_outlined,
                    size: 16,
                    color: KAppColors.getPrimary(context),
                  ),
                  label: Text(
                    'Read full article',
                    style: TextStyle(
                      color: KAppColors.getPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getItemTypeColor(DigestItemType type) {
    switch (type) {
      case DigestItemType.news:
        return KAppColors.info;
      case DigestItemType.trending:
        return KAppColors.warning;
      case DigestItemType.analysis:
        return KAppColors.purple;
      case DigestItemType.opinion:
        return KAppColors.pink;
      case DigestItemType.local:
        return KAppColors.success;
      case DigestItemType.followed:
        return KAppColors.cyan;
    }
  }

  void _openFullArticle(DigestItem item) {
    if (item.relatedArticleIds.isEmpty) return;

    final articleId = item.relatedArticleIds.first;
    final article = _newsProvider.articles.firstWhere(
      (a) => a.articleId == articleId,
      orElse: () => _newsProvider.articles.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(article: article),
      ),
    );
  }
}
