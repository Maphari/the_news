import 'dart:async';
import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/reading_tracker_service.dart';
import 'package:the_news/service/reading_history_sync_service.dart';
import 'package:the_news/service/break_reminder_service.dart';
import 'package:the_news/service/mood_tracking_service.dart';
import 'package:the_news/service/engagement_service.dart';
import 'package:the_news/service/saved_articles_service.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/app_rating_service.dart';
import 'package:the_news/service/dialog_frequency_service.dart';
import 'package:the_news/service/social_sharing_service.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/model/reading_list_model.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/utils/reading_time_calculator.dart';
import 'package:the_news/view/widgets/mood_checkin_dialog.dart';
import 'package:the_news/view/widgets/audio_player_widget.dart';
import 'package:the_news/view/settings/reading_preferences_page.dart';
import 'package:the_news/view/library/notes_highlights_library_page.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'widgets/article_meta_info.dart';
import 'widgets/article_content_section.dart';
import 'widgets/article_tags_section.dart';
import 'widgets/article_sentiment_card.dart';
import 'widgets/article_metadata_section.dart';
import 'widgets/related_articles_section.dart';
import 'widgets/comment_section.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

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
  final SavedArticlesService _savedArticlesService =
      SavedArticlesService.instance;
  final FollowedPublishersService _followedPublishersService =
      FollowedPublishersService.instance;
  final DialogFrequencyService _dialogFrequencyService =
      DialogFrequencyService.instance;
  final SocialFeaturesBackendService _socialFeaturesService =
      SocialFeaturesBackendService.instance;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsKey = GlobalKey();
  double _maxScrollExtent = 0.0;
  int? _moodEntryId;
  bool _isFollowingPublisher = false;
  bool _isTogglingFollow = false;
  Timer? _readTimer;
  bool _hasTrackedRead = false;

  @override
  void initState() {
    super.initState();
    StatusBarHelper.setDarkStatusBar();
    _setupScrollListener();
    _loadUserData();
    _loadEngagementData();
    _engagementService.addListener(_onEngagementChanged);
    _savedArticlesService.addListener(_onSavedArticlesChanged);
    _followedPublishersService.addListener(_onFollowedPublishersChanged);

    // Show pre-reading mood check-in, then start tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPreReadingMoodCheckIn();
    });
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final userData = await authService.getCurrentUser();
    if (userData != null && mounted) {
      final userId = userData['id'] ?? userData['userId'] ?? '';
      setState(() {
        _userId = userId;
        _currentUser = RegisterLoginUserSuccessModel(
          token: '',
          userId: userId,
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          message: '',
          success: true,
          createdAt: userData['createdAt'] ?? '',
          updatedAt: userData['updatedAt'] ?? '',
          lastLogin: userData['lastLogin'] ?? '',
        );
      });
      await _followedPublishersService.loadFollowedPublishers(userId);
      _syncFollowState();
      await _loadEngagementData();
      _trackReadIfNeeded(force: false);
    }
  }

  Future<void> _loadEngagementData() async {
    setState(() {});

    // Load engagement from backend
    final engagement = await _engagementService.getEngagement(
      widget.article.articleId,
      userId: _userId,
    );

    // Check if article is saved
    final isSaved = _savedArticlesService.isArticleSaved(
      widget.article.articleId,
    );

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

  void _onEngagementChanged() {
    final engagement = _engagementService.getCachedEngagement(
      widget.article.articleId,
    );
    if (engagement == null || !mounted) return;

    setState(() {
      likeCount = engagement.likeCount;
      commentCount = engagement.commentCount;
      shareCount = engagement.shareCount;
      isLiked = engagement.isLiked;
    });
  }

  void _onSavedArticlesChanged() {
    if (!mounted) return;
    final saved = _savedArticlesService.isArticleSaved(
      widget.article.articleId,
    );
    if (saved != isBookmarked) {
      setState(() => isBookmarked = saved);
    }
  }

  void _onFollowedPublishersChanged() {
    if (!mounted) return;
    _syncFollowState();
  }

  void _syncFollowState() {
    final isFollowed = _followedPublishersService.isPublisherFollowed(
      widget.article.sourceName,
    );
    if (_isFollowingPublisher != isFollowed && mounted) {
      setState(() => _isFollowingPublisher = isFollowed);
    }
  }

  Future<void> _toggleFollowPublisher() async {
    if (_isTogglingFollow || _currentUser == null) return;

    setState(() => _isTogglingFollow = true);
    await _followedPublishersService.toggleFollow(
      _currentUser!.userId,
      widget.article.sourceName,
    );
    if (mounted) {
      setState(() => _isTogglingFollow = false);
    }
  }

  void _startReadingTracking() async {
    await _tracker.startReadingSession(widget.article);
    _scheduleReadTracking();
  }

  void _scheduleReadTracking() {
    _readTimer?.cancel();
    _readTimer = Timer(const Duration(seconds: 3), () {
      _trackReadIfNeeded(force: false);
    });
  }

  Future<void> _trackReadIfNeeded({required bool force}) async {
    if (_hasTrackedRead) return;
    final userId = _userId;
    final session = _tracker.currentSession;
    if (userId == null) return;

    final durationSeconds = _tracker.getCurrentSessionDuration();
    if (!force && durationSeconds < 3) return;

    final safeDuration = durationSeconds <= 0 ? 1 : durationSeconds;
    _hasTrackedRead = true;
    final articleId = session?.articleId ?? widget.article.articleId;
    final articleTitle = session?.articleTitle ?? widget.article.title;
    await ReadingHistorySyncService.instance.trackArticleRead(
      userId: userId,
      articleId: articleId,
      articleTitle: articleTitle,
      readDuration: safeDuration,
    );
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
    final shouldShowDialog = await _dialogFrequencyService
        .shouldShowMoodCheckInDialog();

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
          final scrollPercent = ((currentScroll / _maxScrollExtent) * 100)
              .clamp(0, 100)
              .toInt();
          _tracker.updateScrollDepth(scrollPercent);
        }
      }
    });
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    _trackReadIfNeeded(force: true);

    _tracker.endReadingSession();
    _breakReminder.stopTracking();
    _engagementService.removeListener(_onEngagementChanged);
    _savedArticlesService.removeListener(_onSavedArticlesChanged);
    _followedPublishersService.removeListener(_onFollowedPublishersChanged);
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
    final contentText = _resolveArticleContent();
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
          bottomNavigationBar: _buildBottomActionBar(),
          body: SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Pinned header with back button and actions
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  backgroundColor: KAppColors.getBackground(context),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 64,
                  flexibleSpace: _buildTopBar(),
                ),

                // Article content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: KDesignConstants.paddingHorizontalLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.article.duplicate)
                          _buildDuplicateBanner(),
                        if (widget.article.duplicate)
                          const SizedBox(height: KDesignConstants.spacing12),

                        // Hero media
                        _buildHeroMedia(),
                        const SizedBox(height: KDesignConstants.spacing16),

                        _buildByline(widget.article.creator),
                        const SizedBox(height: KDesignConstants.spacing8),

                        // Title
                        Text(
                          widget.article.title,
                          style: KAppTextStyles.displaySmall.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontSize: 28,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: KDesignConstants.spacing8),

                        _buildInlineMeta(
                          category: widget.article.category.isNotEmpty
                              ? widget.article.category.first
                              : '',
                          timeAgo: _getTimeAgo(widget.article.pubDate),
                          readingTime: ReadingTimeCalculator
                              .calculateReadingTime(contentText),
                        ),
                        const SizedBox(height: KDesignConstants.spacing12),

                        _buildTopActionRow(),
                        const SizedBox(height: KDesignConstants.spacing20),

                        _buildSourceActions(),
                        const SizedBox(height: KDesignConstants.spacing24),

                        // Overview
                        _buildOverviewCard(widget.article.description),
                        const SizedBox(height: KDesignConstants.spacing24),

                        // Full article content (API only)
                        SizedBox(
                          width: double.infinity,
                          child: ArticleContentSection(
                            content: contentText,
                            articleId: widget.article.articleId,
                            articleTitle: widget.article.title,
                          ),
                        ),
                        const SizedBox(height: KDesignConstants.spacing32),

                        // Author info
                        ArticleMetaInfo(
                          authorName: widget.article.sourceName,
                          sourceIcon: widget.article.sourceIcon,
                          isFollowing: _isFollowingPublisher,
                          isLoading: _isTogglingFollow,
                          onFollowPressed: _toggleFollowPublisher,
                        ),
                        const SizedBox(height: KDesignConstants.spacing24),

                        // Audio player for text-to-speech
                        AudioPlayerWidget(article: widget.article),
                        const SizedBox(height: KDesignConstants.spacing24),

                        // AI Summary (if available and not an API limitation message)
                        if (widget.article.aiSummary.isNotEmpty &&
                            !widget.article.aiSummary.toUpperCase().contains(
                              'ONLY AVAILABLE',
                            ) &&
                            !widget.article.aiSummary.toUpperCase().contains(
                              'PAID PLAN',
                            )) ...[
                          _buildAISummary(),
                          const SizedBox(height: KDesignConstants.spacing24),
                        ],

                        // Sentiment Analysis
                        ArticleSentimentCard(
                          sentiment: widget.article.sentiment,
                          sentimentStats: widget.article.sentimentStats,
                        ),
                        const SizedBox(height: KDesignConstants.spacing24),

                        // Tags and AI Tags (only show if not API limitation message)
                        if (_shouldShowTags())
                          ArticleTagsSection(
                            keywords: widget.article.keywords,
                            aiTags: widget.article.aiTag,
                            aiRegion: widget.article.aiRegion,
                          ),
                        const SizedBox(height: KDesignConstants.spacing32),

                        // Article metadata
                        ArticleMetadataSection(
                          article: widget.article,
                          userId: _userId,
                        ),
                        const SizedBox(height: KDesignConstants.spacing32),

                        // Comments section - full width
                        if (_currentUser != null)
                          SizedBox(
                            key: _commentsKey,
                            width: double.infinity,
                            child: CommentSection(
                              commentCount: commentCount,
                              article: widget.article,
                              user: _currentUser!,
                            ),
                          ),
                        const SizedBox(height: KDesignConstants.spacing32),

                        // Related articles
                        RelatedArticlesSection(currentArticle: widget.article),
                        const SizedBox(height: KDesignConstants.spacing40),
                        const SizedBox(height: 80),
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
            borderRadius: KBorderRadius.xl,
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

  Widget _buildTopBar() {
    final sourceName = widget.article.sourceName.isNotEmpty
        ? widget.article.sourceName
        : 'Source';
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            AppBackButton(
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.article.sourceIcon.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SafeNetworkImage(
                        widget.article.sourceIcon,
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.public,
                        size: 14,
                        color: KAppColors.getOnBackground(context)
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      sourceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KAppTextStyles.titleSmall.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: _showMoreMenu,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: KAppColors.getOnBackground(context)
                      .withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.more_vert,
                  color: KAppColors.getOnBackground(context)
                      .withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMoreMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: KAppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetItem(
                  icon: Icons.ios_share,
                  label: 'Share',
                  onTap: () async {
                    Navigator.pop(context);
                    await _handleShare();
                  },
                ),
                _buildSheetItem(
                  icon: Icons.text_fields_rounded,
                  label: 'Reading Preferences',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReadingPreferencesPage(),
                      ),
                    );
                  },
                ),
                _buildSheetItem(
                  icon: Icons.bookmark_outline,
                  label: 'Notes & Highlights',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotesHighlightsLibraryPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              KAppColors.getOnBackground(context).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
        ),
      ),
      title: Text(
        label,
        style: KAppTextStyles.bodyMedium.copyWith(
          color: KAppColors.getOnBackground(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _handleLikeToggle() async {
    if (_userId == null) return;
    final success = await _engagementService.toggleLike(
      _userId!,
      widget.article.articleId,
    );
    if (success && mounted) {
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });
    }
  }

  Future<void> _handleSaveToggle() async {
    if (_userId == null) return;
    final success = await _savedArticlesService.toggleSaveArticle(
      _userId!,
      widget.article.articleId,
      article: widget.article,
    );
    if (success && mounted) {
      setState(() => isBookmarked = !isBookmarked);
      _tracker.markAsBookmarked(isBookmarked);
    }
  }

  Future<void> _handleShare() async {
    if (_userId == null) return;
    final previousCount = shareCount;
    await SocialSharingService.instance.showShareDialog(context, widget.article);
    final engagement = await _engagementService.getEngagement(
      widget.article.articleId,
      userId: _userId,
    );
    if (!mounted) return;
    if (engagement != null) {
      setState(() => shareCount = engagement.shareCount);
      if (engagement.shareCount > previousCount) {
        _tracker.markAsShared();
      }
    }
  }

  Future<void> _handleAddToList() async {
    if (_userId == null || _userId!.isEmpty) return;
    final lists = await _socialFeaturesService.getUserReadingLists(_userId!);
    if (!mounted) return;

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
      isScrollControlled: true,
      backgroundColor: KAppColors.getBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add to reading list',
                    style: KAppTextStyles.titleMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
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
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                          ),
                        ),
                        title: Text(list.name),
                        subtitle: Text('${list.articleCount} articles'),
                        trailing: const Icon(Icons.add),
                        onTap: () => Navigator.pop(context, list),
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
      await _socialFeaturesService.addArticleToList(selectedList.id, widget.article.articleId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to "${selectedList.name}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add to list: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToComments() {
    final context = _commentsKey.currentContext;
    if (context == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero).dy;
    _scrollController.animateTo(
      _scrollController.offset + offset - 120,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildTopActionRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTopActionChip(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: _handleShare,
          ),
        ),
        const SizedBox(width: KDesignConstants.spacing12),
        Expanded(
          child: _buildTopActionChip(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: isLiked ? 'Like' : 'Like',
            isActive: isLiked,
            onTap: _handleLikeToggle,
          ),
        ),
        const SizedBox(width: KDesignConstants.spacing12),
        Expanded(
          child: _buildTopActionChip(
            icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            label: isBookmarked ? 'Save' : 'Save',
            isActive: isBookmarked,
            onTap: _handleSaveToggle,
          ),
        ),
        const SizedBox(width: KDesignConstants.spacing12),
        Expanded(
          child: _buildTopActionChip(
            icon: Icons.library_add_outlined,
            label: 'List',
            onTap: _handleAddToList,
          ),
        ),
      ],
    );
  }

  Widget _buildTopActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final color = isActive
        ? KAppColors.getPrimary(context)
        : KAppColors.getOnBackground(context).withValues(alpha: 0.7);
    final borderColor = isActive
        ? KAppColors.getPrimary(context).withValues(alpha: 0.4)
        : KAppColors.getOnBackground(context).withValues(alpha: 0.15);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 70;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: KAppTextStyles.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final hasLink = widget.article.link.isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: KAppColors.getBackground(context),
          border: Border(
            top: BorderSide(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBottomActionItem(
              icon: Icons.share_outlined,
              label: _formatCount(shareCount),
              onTap: _handleShare,
            ),
            _buildBottomActionItem(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              label: _formatCount(likeCount),
              isActive: isLiked,
              onTap: _handleLikeToggle,
            ),
            _buildBottomActionItem(
              icon: Icons.comment_outlined,
              label: _formatCount(commentCount),
              onTap: _scrollToComments,
            ),
            _buildBottomActionItem(
              icon: Icons.refresh,
              label: 'Open',
              onTap: hasLink
                  ? () => _openWebView(
                        title: widget.article.sourceName,
                        url: widget.article.link,
                      )
                  : () {},
            ),
            _buildBottomActionItem(
              icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              label: isBookmarked ? 'Saved' : 'Save',
              isActive: isBookmarked,
              onTap: _handleSaveToggle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final color = isActive
        ? KAppColors.getPrimary(context)
        : KAppColors.getOnBackground(context).withValues(alpha: 0.75);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: KAppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int value) {
    if (value >= 1000) {
      final k = (value / 1000).toStringAsFixed(1);
      return '${k}k';
    }
    return value.toString();
  }

  Widget _buildInlineMeta({
    required String category,
    required String timeAgo,
    required String readingTime,
  }) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (category.isNotEmpty)
                Text(
                  category,
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (category.isNotEmpty) _buildDot(),
              Text(
                timeAgo,
                style: KAppTextStyles.bodySmall.copyWith(
                  color:
                      KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.favorite,
              size: 14,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              '$likeCount liked',
              style: KAppTextStyles.bodySmall.copyWith(
                color:
                    KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _buildDot(),
        const SizedBox(width: 8),
        Text(
          readingTime,
          style: KAppTextStyles.bodySmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'top':
        return KAppColors.red;
      case 'politics':
        return KAppColors.blue;
      case 'business':
        return KAppColors.green;
      case 'technology':
        return KAppColors.purple;
      case 'sports':
        return KAppColors.orange;
      case 'environment':
        return KAppColors.cyan;
      case 'health':
        return KAppColors.pink;
      case 'crime':
        return KAppColors.orange;
      default:
        return KAppColors.yellow;
    }
  }

  Widget _buildEngagementStats() {
    return Container(
      padding: KDesignConstants.paddingLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KAppColors.getPrimary(context).withValues(alpha: 0.12),
            KAppColors.getSecondary(context).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.favorite, likeCount, 'Likes'),
          Container(
            height: 30,
            width: 1,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
          ),
          _buildStatItem(Icons.comment, commentCount, 'Comments'),
          Container(
            height: 30,
            width: 1,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
          ),
          _buildStatItem(Icons.share, shareCount, 'Shares'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
          size: 20,
        ),
        const SizedBox(height: KDesignConstants.spacing4),
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
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
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
            KAppColors.getPrimary(context).withValues(alpha: 0.16),
            KAppColors.getTertiary(context).withValues(alpha: 0.12),
          ],
        ),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: KDesignConstants.paddingSm,
                decoration: BoxDecoration(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: KAppColors.getPrimary(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Text(
                'AI Summary',
                style: KAppTextStyles.titleMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Text(
            widget.article.aiSummary,
            style: KAppTextStyles.bodyLarge.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.9),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
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
      if (tagUpper.contains('ONLY AVAILABLE') ||
          tagUpper.contains('PAID PLAN')) {
        return false;
      }
    }

    return true;
  }

  /// Get the article content to display (API only)
  String _resolveArticleContent() {
    final apiContent = widget.article.content;
    if (apiContent.isNotEmpty &&
        !apiContent.toUpperCase().contains('ONLY AVAILABLE') &&
        !apiContent.toUpperCase().contains('PAID PLAN')) {
      return apiContent;
    }

    // Last resort - use description
    return widget.article.description;
  }

  Widget _buildOverviewCard(String description) {
    return Container(
      padding: KDesignConstants.paddingLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KAppColors.getPrimary(context).withValues(alpha: 0.14),
            KAppColors.getSecondary(context).withValues(alpha: 0.06),
          ],
        ),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: KAppTextStyles.titleMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Text(
            description,
            style: KAppTextStyles.bodyLarge.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.88),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChips({
    required String timeAgo,
    required String readingTime,
    required String sourceName,
    required String timezone,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildMetaChip(Icons.access_time, timeAgo),
        _buildMetaChip(Icons.menu_book_outlined, readingTime),
        _buildMetaChip(Icons.public, sourceName),
        if (timezone.isNotEmpty)
          _buildMetaChip(Icons.schedule, timezone),
      ],
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.75),
          ),
          const SizedBox(width: KDesignConstants.spacing8),
          Text(
            label,
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMedia() {
    final imageUrl = widget.article.imageUrl ?? '';
    return ClipRRect(
      borderRadius: KBorderRadius.xxl,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: imageUrl.isNotEmpty
            ? SafeNetworkImage(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildHeroFallback();
                },
              )
            : _buildHeroFallback(),
      ),
    );
  }

  Widget _buildByline(List<String> creators) {
    final byline = creators.isNotEmpty ? creators.join(', ') : 'Staff';
    final source = widget.article.sourceName.isNotEmpty
        ? widget.article.sourceName
        : 'Source';
    return Row(
      children: [
        Icon(
          Icons.edit_outlined,
          size: 16,
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
        ),
        const SizedBox(width: KDesignConstants.spacing8),
        Expanded(
          child: Text(
            'By $byline  •  For $source',
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocaleChips({
    required String language,
    required List<String> countries,
    required String datatype,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (datatype.isNotEmpty)
          _buildToneChip(
            Icons.auto_stories_outlined,
            datatype.toUpperCase(),
          ),
        if (language.isNotEmpty)
          _buildToneChip(
            Icons.translate,
            language.toUpperCase(),
          ),
        ...countries.map(
          (country) => _buildToneChip(
            Icons.flag_outlined,
            country.toUpperCase(),
          ),
        ),
      ],
    );
  }

  Widget _buildToneChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: KAppColors.getPrimary(context),
          ),
          const SizedBox(width: KDesignConstants.spacing8),
          Text(
            label,
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceActions() {
    final hasLink = widget.article.link.isNotEmpty;
    final hasSource = widget.article.sourceUrl.isNotEmpty;
    final hasVideo = widget.article.videoUrl != null &&
        widget.article.videoUrl!.isNotEmpty;

    if (!hasLink && !hasSource && !hasVideo) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (hasLink || hasSource)
          Row(
            children: [
              if (hasLink)
                Expanded(
                  child: _buildActionPill(
                    icon: Icons.open_in_new,
                    label: 'Read Original',
                    onPressed: () => _openWebView(
                      title: widget.article.sourceName,
                      url: widget.article.link,
                    ),
                  ),
                ),
              if (hasLink && hasSource)
                const SizedBox(width: KDesignConstants.spacing12),
              if (hasSource)
                Expanded(
                  child: _buildActionPill(
                    icon: Icons.public,
                    label: 'Publisher',
                    onPressed: () => _openWebView(
                      title: widget.article.sourceName,
                      url: widget.article.sourceUrl,
                    ),
                  ),
                ),
            ],
          ),
        if (hasVideo && (hasLink || hasSource))
          const SizedBox(height: KDesignConstants.spacing12),
        if (hasVideo)
          Row(
            children: [
              Expanded(
                child: _buildActionPill(
                  icon: Icons.play_circle_outline,
                  label: 'Watch Clip',
                  onPressed: () => _openWebView(
                    title: widget.article.title,
                    url: widget.article.videoUrl!,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDuplicateBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: KAppColors.warning.withValues(alpha: 0.15),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: KAppColors.warning),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: Text(
              'Similar article detected in your feed.',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KAppColors.getPrimary(context).withValues(alpha: 0.35),
            KAppColors.getSecondary(context).withValues(alpha: 0.25),
            KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_outlined,
          size: 64,
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    final accent = isActive
        ? KAppColors.getPrimary(context)
        : KAppColors.getOnBackground(context).withValues(alpha: 0.9);
    return InkWell(
      onTap: onPressed,
      borderRadius: KBorderRadius.xl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          borderRadius: KBorderRadius.xl,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: KDesignConstants.spacing8),
            Text(
              label,
              style: KAppTextStyles.bodySmall.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openWebView({required String title, required String url}) {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid link'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArticleSourceWebViewPage(
          title: title,
          url: uri.toString(),
        ),
      ),
    );
  }
}

class ArticleSourceWebViewPage extends StatefulWidget {
  const ArticleSourceWebViewPage({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  State<ArticleSourceWebViewPage> createState() =>
      _ArticleSourceWebViewPageState();
}

class _ArticleSourceWebViewPageState extends State<ArticleSourceWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading page: ${error.description}'),
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
