import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/reading_tracker_service.dart';
import 'package:the_news/service/break_reminder_service.dart';
import 'package:the_news/service/mood_tracking_service.dart';
import 'package:the_news/service/engagement_service.dart';
import 'package:the_news/service/saved_articles_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/app_rating_service.dart';
import 'package:the_news/service/article_enrichment_service.dart';
import 'package:the_news/service/dialog_frequency_service.dart';
import 'package:the_news/model/enriched_article_model.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/utils/reading_time_calculator.dart';
import 'package:the_news/view/article_details/widgets/article_media_section.dart';
import 'package:the_news/view/widgets/mood_checkin_dialog.dart';
import 'package:the_news/view/widgets/audio_player_widget.dart';
import 'package:the_news/view/settings/reading_preferences_page.dart';
import 'package:the_news/view/library/notes_highlights_library_page.dart';
import 'widgets/article_header.dart';
import 'widgets/article_meta_info.dart';
import 'widgets/article_content_section.dart';
import 'widgets/rich_article_content_widget.dart';
import 'widgets/article_tags_section.dart';
import 'widgets/article_sentiment_card.dart';
import 'widgets/article_metadata_section.dart';
import 'widgets/related_articles_section.dart';
import 'widgets/comment_section.dart';
import 'widgets/ai_summary_section.dart';

class ArticleDetailPage extends StatefulWidget {
  const ArticleDetailPage({super.key, required this.article});

  final ArticleModel article;

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  bool isBookmarked = false;
  bool isLiked = false;
  int likeCount = 0;
  int commentCount = 0;
  int shareCount = 0;
  String? _userId;
  RegisterLoginUserSuccessModel? _currentUser;

  final ReadingTrackerService _tracker = ReadingTrackerService.instance;
  final BreakReminderService _breakReminder = BreakReminderService.instance;
  final MoodTrackingService _moodTracker = MoodTrackingService.instance;
  final EngagementService _engagementService = EngagementService.instance;
  final SavedArticlesService _savedArticlesService = SavedArticlesService.instance;
  final ArticleEnrichmentService _enrichmentService = ArticleEnrichmentService.instance;
  final DialogFrequencyService _dialogFrequencyService = DialogFrequencyService.instance;
  final ScrollController _scrollController = ScrollController();
  double _maxScrollExtent = 0.0;
  int? _moodEntryId;
  EnrichedArticle? _enrichedArticle;
  bool _isEnriching = false;

  @override
  void initState() {
    super.initState();
    StatusBarHelper.setDarkStatusBar();
    _setupScrollListener();
    _loadUserData();
    _loadEngagementData();
    _enrichArticleContent();

    // Show pre-reading mood check-in, then start tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPreReadingMoodCheckIn();
    });
  }

  /// Enrich article content by fetching full text from source URL
  Future<void> _enrichArticleContent() async {
    setState(() => _isEnriching = true);

    try {
      final enriched = await _enrichmentService.enrichArticle(
        widget.article.articleId,
        widget.article.link, // Use the source URL
      );

      if (mounted) {
        setState(() {
          _enrichedArticle = enriched;
          _isEnriching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEnriching = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final userData = await authService.getCurrentUser();
    if (userData != null && mounted) {
      setState(() {
        _userId = userData['id'] ?? '';
        _currentUser = RegisterLoginUserSuccessModel(
          token: '',
          userId: userData['id'] ?? '',
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          message: '',
          success: true,
          createdAt: userData['createdAt'] ?? '',
          updatedAt: userData['updatedAt'] ?? '',
          lastLogin: userData['lastLogin'] ?? '',
        );
      });
    }
  }

  Future<void> _loadEngagementData() async {
    setState(() {
    });

    // Load engagement from backend
    final engagement = await _engagementService.getEngagement(
      widget.article.articleId,
      userId: _userId,
    );

    // Check if article is saved
    final isSaved = _savedArticlesService.isArticleSaved(widget.article.articleId);

    if (mounted) {
      setState(() {
        if (engagement != null) {
          likeCount = engagement.likeCount;
          commentCount = engagement.commentCount;
          shareCount = engagement.shareCount;
          isLiked = engagement.isLiked;
        }
        isBookmarked = isSaved;
      });
    }
  }

  void _startReadingTracking() async {
    await _tracker.startReadingSession(widget.article);
  }

  void _startBreakReminder() {
    _breakReminder.startTracking(
      onReminderTriggered: (level) {
        _showBreakReminderDialog(level);
      },
    );
  }

  void _showPreReadingMoodCheckIn() async {
    // Check if we should show the dialog (max 2 times per day)
    final shouldShowDialog = await _dialogFrequencyService.shouldShowMoodCheckInDialog();

    if (shouldShowDialog && mounted) {
      final result = await MoodCheckInDialog.showPreReading(
        context,
        articleTitle: widget.article.title,
      );

      // Track that the dialog was shown
      await _dialogFrequencyService.trackMoodCheckInDialogShown();

      if (result != null) {
        // Save pre-reading mood
        _moodEntryId = await _moodTracker.savePreReadingMood(
          articleId: widget.article.articleId,
          mood: result['mood'],
          intensity: result['intensity'],
        );
      }
    }

    // Start tracking regardless of whether dialog was shown
    _startReadingTracking();
    _startBreakReminder();
  }

  void _showPostReadingMoodCheckIn() async {
    final result = await MoodCheckInDialog.showPostReading(context);

    if (result != null && _moodEntryId != null) {
      // Save post-reading mood
      await _moodTracker.savePostReadingMood(
        entryId: _moodEntryId!,
        mood: result['mood'],
        intensity: result['intensity'],
      );
    }
  }

  void _showBreakReminderDialog(BreakReminderLevel level) async {
    final shouldBreak = await BreakReminderDialog.show(
      context,
      level: level,
      readingMinutes: _breakReminder.continuousReadingMinutes,
    );

    if (shouldBreak == true) {
      // User chose to take a break, show post-reading mood check-in
      _showPostReadingMoodCheckIn();

      // Then navigate back
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // User chose to continue, reset timer for next reminder
      _breakReminder.resetTimer();
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final currentScroll = _scrollController.offset;
        final maxScroll = _scrollController.position.maxScrollExtent;

        if (maxScroll > _maxScrollExtent) {
          _maxScrollExtent = maxScroll;
        }

        if (_maxScrollExtent > 0) {
          final scrollPercent = ((currentScroll / _maxScrollExtent) * 100).clamp(0, 100).toInt();
          _tracker.updateScrollDepth(scrollPercent);
        }
      }
    });
  }


  @override
  void dispose() {
    _tracker.endReadingSession();
    _breakReminder.stopTracking();
    _scrollController.dispose();
    StatusBarHelper.setLightStatusBar();

    // Track article read for rating prompt
    AppRatingService.instance.trackArticleRead();

    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // Show post-reading mood check-in when user exits
    _showPostReadingMoodCheckIn();
    return true;
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'Updated ${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return 'Updated ${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return 'Updated ${difference.inDays} days ago';
    } else {
      return 'Updated ${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: StatusBarHelper.wrapWithStatusBar(
        backgroundColor: KAppColors.getBackground(context),
        child: Scaffold(
          backgroundColor: KAppColors.getBackground(context),
          body: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Back button header with share
              SliverToBoxAdapter(
                child: ArticleHeader(
                  onBackPressed: () => Navigator.pop(context),
                  onSharePressed: () async {
                    if (_userId == null) return;

                    await _engagementService.shareArticle(
                      _userId!,
                      widget.article.articleId,
                    );

                    setState(() => shareCount++);
                    _tracker.markAsShared();
                  },
                  onPreferencesPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReadingPreferencesPage(),
                      ),
                    );
                  },
                  onLibraryPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotesHighlightsLibraryPage(),
                      ),
                    );
                  },
                ),
              ),

              // Article content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badges
                      if (widget.article.category.isNotEmpty)
                        _buildCategoryBadges(),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        widget.article.title,
                        style: KAppTextStyles.displaySmall.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontSize: 32,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time stamp, reading time, and source
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _getTimeAgo(widget.article.pubDate),
                            style: KAppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '•',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: Colors.white70,
                          ),
                          Text(
                            ReadingTimeCalculator.calculateReadingTime(widget.article.content),
                            style: KAppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '•',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            widget.article.sourceName,
                            style: KAppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Engagement stats
                      _buildEngagementStats(),
                      const SizedBox(height: 24),

                      // Author info
                      ArticleMetaInfo(
                        authorName: widget.article.sourceName,
                        sourceIcon: widget.article.sourceIcon,
                        onFollowPressed: () {
                          // Handle follow action
                        },
                      ),
                      const SizedBox(height: 24),

                      // Audio player for text-to-speech
                      AudioPlayerWidget(article: widget.article),
                      const SizedBox(height: 24),

                      // Featured image/video with action buttons
                      ArticleMediaSection(
                        imageUrl: widget.article.imageUrl ?? '',
                        videoUrl: widget.article.videoUrl,
                        isLiked: isLiked,
                        isBookmarked: isBookmarked,
                        onLikePressed: () async {
                          if (_userId == null) return;

                          final success = await _engagementService.toggleLike(
                            _userId!,
                            widget.article.articleId,
                          );

                          if (success) {
                            setState(() {
                              isLiked = !isLiked;
                              likeCount += isLiked ? 1 : -1;
                            });
                          }
                        },
                        onBookmarkPressed: () async {
                          if (_userId == null) return;

                          final success = await _savedArticlesService.toggleSaveArticle(
                            _userId!,
                            widget.article.articleId,
                          );

                          if (success) {
                            setState(() => isBookmarked = !isBookmarked);
                            _tracker.markAsBookmarked(isBookmarked);
                          }
                        },
                        onSharePressed: () async {
                          if (_userId == null) return;

                          await _engagementService.shareArticle(
                            _userId!,
                            widget.article.articleId,
                          );

                          setState(() => shareCount++);
                          _tracker.markAsShared();
                        },
                      ),
                      const SizedBox(height: 24),

                      // AI Summary (if available and not an API limitation message)
                      if (widget.article.aiSummary.isNotEmpty &&
                          !widget.article.aiSummary.toUpperCase().contains('ONLY AVAILABLE') &&
                          !widget.article.aiSummary.toUpperCase().contains('PAID PLAN')) ...[
                        _buildAISummary(),
                        const SizedBox(height: 24),
                      ],

                      // Description/excerpt
                      Text(
                        widget.article.description,
                        style: KAppTextStyles.bodyLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.6,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Full article content (enriched or original)
                      if (_shouldShowContent())
                        // Use rich content if structured content is available
                        (_enrichedArticle != null && _enrichedArticle!.structuredContent.isNotEmpty)
                            ? RichArticleContentWidget(
                                structuredContent: _enrichedArticle!.structuredContent,
                                articleId: widget.article.articleId,
                                articleTitle: widget.article.title,
                              )
                            : ArticleContentSection(
                                content: _getArticleContent(),
                                articleId: widget.article.articleId,
                                articleTitle: widget.article.title,
                              )
                      else
                        // Break out of padding for full-width loading message
                        Transform.translate(
                          offset: const Offset(-24, 0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildContentLoadingMessage(),
                          ),
                        ),
                      const SizedBox(height: 32),

                      // Videos from enriched content
                      if (_enrichedArticle?.hasVideos == true) ...[
                        _buildEnrichedVideos(),
                        const SizedBox(height: 32),
                      ],

                      // AI Summary Section (Premium Feature)
                      AISummarySection(
                        enrichedArticle: _enrichedArticle,
                        isLoading: _isEnriching,
                      ),
                      const SizedBox(height: 24),

                      // Sentiment Analysis
                      ArticleSentimentCard(
                        sentiment: widget.article.sentiment,
                        sentimentStats: widget.article.sentimentStats,
                      ),
                      const SizedBox(height: 24),

                      // Tags and AI Tags (only show if not API limitation message)
                      if (_shouldShowTags())
                        ArticleTagsSection(
                          keywords: widget.article.keywords,
                          aiTags: widget.article.aiTag,
                          aiRegion: widget.article.aiRegion,
                        ),
                      const SizedBox(height: 32),

                      // Article metadata
                      ArticleMetadataSection(
                        article: widget.article,
                        userId: _userId,
                      ),
                      const SizedBox(height: 32),

                      // Comments section - break out of padding for full width
                      if (_currentUser != null)
                        Transform.translate(
                          offset: const Offset(-24, 0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: CommentSection(
                              commentCount: commentCount,
                              article: widget.article,
                              user: _currentUser!,
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),

                      // Related articles
                      RelatedArticlesSection(
                        currentArticle: widget.article,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCategoryBadges() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.article.category.take(3).map((category) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getCategoryColor(category),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            category.toUpperCase(),
            style: KAppTextStyles.labelSmall.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'top':
        return Colors.red;
      case 'politics':
        return Colors.blue;
      case 'business':
        return Colors.green;
      case 'technology':
        return Colors.purple;
      case 'sports':
        return Colors.orange;
      case 'environment':
        return Colors.teal;
      case 'health':
        return Colors.pink;
      case 'crime':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEngagementStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.favorite, likeCount, 'Likes'),
          Container(
            height: 30,
            width: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          _buildStatItem(Icons.comment, commentCount, 'Comments'),
          Container(
            height: 30,
            width: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          _buildStatItem(Icons.share, shareCount, 'Shares'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: KAppTextStyles.titleMedium.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: KAppTextStyles.bodySmall.copyWith(
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildAISummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.2),
            Colors.purple.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.blue.shade300,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Summary',
                style: KAppTextStyles.titleMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.article.aiSummary,
            style: KAppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrichedImages() {
    if (_enrichedArticle?.images.isEmpty ?? true) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Article Images',
          style: KAppTextStyles.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _enrichedArticle!.images.length,
            itemBuilder: (context, index) {
              final imageUrl = _enrichedArticle!.images[index];
              return Container(
                width: 300,
                margin: EdgeInsets.only(right: index < _enrichedArticle!.images.length - 1 ? 16 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.withValues(alpha: 0.2),
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.withValues(alpha: 0.2),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnrichedVideos() {
    if (_enrichedArticle?.videos.isEmpty ?? true) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.play_circle_outline,
              color: KAppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Videos (${_enrichedArticle!.videos.length})',
              style: KAppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._enrichedArticle!.videos.map((video) => _buildVideoCard(video)),
      ],
    );
  }

  Widget _buildVideoCard(VideoEmbed video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KAppColors.primary.withValues(alpha: 0.1),
            KAppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KAppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KAppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  video.type.name.toUpperCase(),
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: KAppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.play_circle_filled,
                color: KAppColors.primary,
                size: 32,
              ),
            ],
          ),
          if (video.title != null) ...[
            const SizedBox(height: 12),
            Text(
              video.title!,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            video.url,
            style: KAppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Video player support coming soon',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Check if we should show article content
  bool _shouldShowContent() {
    // If enriched content is available (structured or plain text), always show it
    if (_enrichedArticle != null) {
      if (_enrichedArticle!.structuredContent.isNotEmpty || _enrichedArticle!.hasContent) {
        return true;
      }
    }

    // Check if the API content is the "paid plans" message
    final apiContent = widget.article.content.toUpperCase();
    if (apiContent.contains('ONLY AVAILABLE') || apiContent.contains('PAID PLAN')) {
      // Content not available from API, wait for enrichment
      return false;
    }

    // API content is valid
    return true;
  }

  /// Check if tags/keywords contain API limitation messages
  bool _shouldShowTags() {
    // Check if any keyword or tag contains API limitation message
    final allTags = [
      ...widget.article.keywords,
      ...widget.article.aiTag,
      ...widget.article.aiRegion,
    ];

    for (final tag in allTags) {
      final tagUpper = tag.toUpperCase();
      if (tagUpper.contains('ONLY AVAILABLE') || tagUpper.contains('PAID PLAN')) {
        return false;
      }
    }

    return true;
  }

  /// Get the article content to display
  String _getArticleContent() {
    // Prefer enriched content if available
    if (_enrichedArticle?.hasContent == true) {
      return _enrichedArticle!.content!;
    }

    // Fall back to API content
    return widget.article.content;
  }

  /// Show a loading message while content is being fetched
  Widget _buildContentLoadingMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KAppColors.primary.withValues(alpha: 0.05),
            KAppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KAppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (_isEnriching) ...[
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 16),
            Text(
              'Fetching full article content...',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'re scraping the original source for you',
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Icon(
              Icons.article_outlined,
              size: 48,
              color: KAppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Full article content is being loaded',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Our news API has limited content in the free tier.\nWe\'re fetching the full article from the source for you!',
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}