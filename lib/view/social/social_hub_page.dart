import 'package:flutter/material.dart'
    hide MeasuredPinnedHeaderSliver, PinnedHeaderSliver;
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/model/reading_list_model.dart';
import 'package:the_news/model/activity_feed_model.dart';
import 'package:the_news/model/network_highlight_model.dart';
import 'package:the_news/model/social_post_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/engagement_service.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/core/network/api_client.dart';
// import 'package:the_news/model/article_model.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';
import 'package:the_news/view/social/reading_lists_page.dart';
import 'package:the_news/view/social/user_search_page.dart';
import 'package:the_news/view/social/followers_following_page.dart';
import 'package:the_news/view/social/user_profile_view_page.dart';
import 'package:the_news/view/social/user_profile_page.dart';
import 'package:the_news/view/social/social_users_list_page.dart';
import 'package:the_news/view/social/followed_publishers_list_page.dart';
import 'package:the_news/view/social/network_highlights_page.dart';
import 'package:the_news/view/social/create_post_page.dart';
import 'package:the_news/view/social/reading_list_detail_page.dart';
import 'package:the_news/view/article_details/article_detail_page.dart';
import 'package:the_news/view/publisher/publisher_profile_page.dart';

class SocialHubPage extends StatefulWidget {
  const SocialHubPage({super.key, required this.user});

  final RegisterLoginUserSuccessModel user;

  @override
  State<SocialHubPage> createState() => _SocialHubPageState();
}

class _SocialHubPageState extends State<SocialHubPage> {
  final SocialFeaturesBackendService _socialService =
      SocialFeaturesBackendService.instance;
  final EngagementService _engagementService = EngagementService.instance;
  final ApiClient _api = ApiClient.instance;

  UserProfile? _currentProfile;
  List<ReadingList> _recentLists = [];
  List<ActivityFeedItem> _recentActivity = [];
  List<ActivityFeedItem> _sharedActivity = [];
  List<NetworkHighlight> _networkHighlights = [];
  List<SocialPost> _networkPosts = [];
  final Map<String, bool> _highlightLiked = <String, bool>{};
  final Map<String, int> _highlightLikeCounts = <String, int>{};
  final Map<String, int> _highlightCommentCounts = <String, int>{};
  final Set<String> _highlightLikeBusy = <String>{};
  List<UserProfile> _recommendedUsers = [];
  List<UserProfile> _followers = [];
  List<UserProfile> _following = [];
  Map<String, dynamic>? _mySpaceSummary;
  Map<String, dynamic>? _profileInsights;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMorePosts = false;
  bool _postsLoadFailed = false;
  bool _feedLoaded = false;
  bool _postsLoaded = false;
  bool _peopleLoaded = false;
  bool _mySpaceLoaded = false;
  int _activeTabIndex = 0;
  int _activeFeedFilter = 0;
  List<String> _followedPublishers = [];
  List<String> _followedTopics = [];
  bool _mindfulMode = false;
  static const int _mindfulFeedLimit = 10;
  static const int _inlinePeopleLimit = 10;
  static const int _inlinePublisherLimit = 10;
  String? _postsNextCursor;
  bool _postsHasMore = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final profile = await _ensureProfile(forceRefresh: showSpinner);
      if (profile == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      await _loadActiveTabData(profile: profile, force: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    final profile = await _ensureProfile(forceRefresh: true);
    if (profile == null || !mounted) return;
    setState(() => _isRefreshing = true);
    await _loadActiveTabData(profile: profile, force: true);
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<UserProfile?> _ensureProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentProfile != null) return _currentProfile;
    final profile = await _getOrCreateProfile(forceRefresh: forceRefresh);
    if (mounted && profile != null) {
      setState(() => _currentProfile = profile);
    }
    return profile;
  }

  Future<void> _loadActiveTabData({
    required UserProfile profile,
    required bool force,
  }) async {
    if (!mounted) return;
    switch (_activeTabIndex) {
      case 0:
      case 1:
        if (!force && _feedLoaded) break;
        await _loadFeedTabData(profile, forceRefresh: force);
        break;
      case 2:
        if (!force && _postsLoaded) break;
        await _loadPostsTabData(profile, forceRefresh: force);
        break;
      case 3:
        if (!force && _peopleLoaded) break;
        await _loadPeopleTabData(profile, forceRefresh: force);
        break;
      case 4:
        if (!force && _mySpaceLoaded) break;
        await _loadMySpaceTabData(profile, forceRefresh: force);
        break;
      default:
        break;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadFeedTabData(
    UserProfile profile, {
    bool forceRefresh = false,
  }) async {
    final summary = await _socialService.getFeedSummary(
      profile.userId,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    if (summary == null) {
      final activity = await _socialService.getActivityFeed(
        limit: 30,
        forceRefresh: forceRefresh,
      );
      final highlights = await _socialService.getNetworkHighlightsPaginated(
        limit: 20,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _recentActivity = activity.take(20).toList();
        _sharedActivity = activity
            .where((a) => a.activityType == ActivityType.shareArticle)
            .take(20)
            .toList();
        _networkHighlights = highlights.highlights;
        _feedLoaded = true;
      });
      return;
    }
    setState(() {
      _recentActivity = summary.recentActivity;
      _sharedActivity = summary.sharedActivity;
      _networkHighlights = summary.networkHighlights;
      _networkPosts = summary.previewPosts;
      _followedPublishers = summary.followedPublishers.take(_inlinePublisherLimit).toList();
      _followedTopics = summary.followedTopics.take(8).toList();
      _feedLoaded = true;
      _highlightLiked
        ..clear()
        ..addEntries(
          summary.networkHighlights.map((h) => MapEntry(h.dedupeKey, false)),
        );
      _highlightLikeCounts
        ..clear()
        ..addEntries(
          summary.networkHighlights.map((h) => MapEntry(h.dedupeKey, h.likeCount)),
        );
      _highlightCommentCounts
        ..clear()
        ..addEntries(
          summary.networkHighlights.map(
            (h) => MapEntry(h.dedupeKey, h.commentCount),
          ),
        );
    });
  }

  Future<void> _loadPostsTabData(
    UserProfile profile, {
    bool forceRefresh = false,
  }) async {
    final postsPage = await _socialService.getNetworkPostsPaginated(
      limit: 20,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    setState(() {
      _networkPosts = postsPage.posts;
      _postsNextCursor = postsPage.nextCursor;
      _postsHasMore = postsPage.hasMore && postsPage.nextCursor != null;
      _postsLoadFailed = postsPage.loadFailed;
      _isLoadingMorePosts = false;
      _postsLoaded = true;
    });
  }

  Future<void> _loadPeopleTabData(
    UserProfile profile, {
    bool forceRefresh = false,
  }) async {
    final summary = await _socialService.getPeopleSummary(
      profile.userId,
      limit: 10,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    if (summary != null) {
      setState(() {
        _followers = summary.followers;
        _following = summary.following;
        _recommendedUsers = summary.recommended;
        _peopleLoaded = true;
      });
      return;
    }

    final results = await Future.wait<List<UserProfile>>([
      _socialService
          .getFollowers(profile.userId, forceRefresh: forceRefresh)
          .catchError((_) => <UserProfile>[]),
      _socialService
          .getFollowing(profile.userId, forceRefresh: forceRefresh)
          .catchError((_) => <UserProfile>[]),
      _socialService
          .getRecommendedUsersPaginated(
            profile.userId,
            limit: 10,
            forceRefresh: forceRefresh,
          )
          .then((page) => page.users)
          .catchError((_) => <UserProfile>[]),
    ]);
    if (!mounted) return;
    setState(() {
      _followers = results[0];
      _following = results[1];
      _recommendedUsers = results[2];
      _peopleLoaded = true;
    });
  }

  Future<void> _loadMySpaceTabData(
    UserProfile profile, {
    bool forceRefresh = false,
  }) async {
    final currentUser = await AuthService().getCurrentUser();
    final publishersUserId =
        currentUser?['id'] as String? ??
        currentUser?['userId'] as String? ??
        profile.userId;
    final results = await Future.wait([
      _socialService
          .getUserReadingLists(profile.userId, forceRefresh: forceRefresh)
          .catchError((_) => <ReadingList>[]),
      _socialService
          .getMySpaceSummary(profile.userId, forceRefresh: forceRefresh)
          .catchError((_) => null),
      FollowedPublishersService.instance
          .getFollowedPublishersPaginated(
            publishersUserId,
            limit: _inlinePublisherLimit,
          )
          .catchError(
            (_) => const PaginatedPublishersPage(publishers: <String>[]),
          ),
    ]);
    if (!mounted) return;
    final lists = results[0] as List<ReadingList>;
    final summary = results[1] as Map<String, dynamic>?;
    final publishersPage = results[2] as PaginatedPublishersPage;
    setState(() {
      _recentLists = lists.take(3).toList();
      _mySpaceSummary = summary;
      _profileInsights =
          (summary?['insights'] as Map<String, dynamic>?) ?? _profileInsights;
      _followedPublishers = publishersPage.publishers;
      _mySpaceLoaded = true;
    });
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMorePosts || !_postsHasMore) return;
    setState(() => _isLoadingMorePosts = true);
    try {
      final page = await _socialService.getNetworkPostsPaginated(
        limit: 20,
        cursor: _postsNextCursor,
      );
      if (!mounted) return;
      if (page.loadFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load more posts right now')),
        );
        return;
      }
      final existingIds = _networkPosts.map((p) => p.id).toSet();
      final newPosts = page.posts
          .where((p) => !existingIds.contains(p.id))
          .toList();
      setState(() {
        _networkPosts = [..._networkPosts, ...newPosts];
        _postsNextCursor = page.nextCursor;
        _postsHasMore = page.hasMore && page.nextCursor != null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingMorePosts = false);
      }
    }
  }

  Future<UserProfile?> _getOrCreateProfile({bool forceRefresh = false}) async {
    // Try to get existing profile
    UserProfile? profile = await _socialService.getCurrentUserProfile(
      forceRefresh: forceRefresh,
    );

    // If profile doesn't exist, create it
    profile ??= await _createInitialProfile();

    return profile;
  }

  Future<UserProfile?> _createInitialProfile() async {
    try {
      // Get current user auth data
      final authService = AuthService();
      final userData = await authService.getCurrentUser();

      if (userData == null) return null;

      final userId = userData['id'] as String? ?? userData['userId'] as String;
      final email = userData['email'] as String? ?? '';
      final name = (userData['name'] as String?) ?? email.split('@').first;

      // Create new profile
      final newProfile = UserProfile(
        userId: userId,
        username: name.toLowerCase().replaceAll(' ', '_'),
        displayName: name,
        bio: userData['bio'] as String?,
        avatarUrl: userData['photoURL'] as String?,
        joinedDate: DateTime.now(),
        followersCount: 0,
        followingCount: 0,
        articlesReadCount: 0,
        collectionsCount: 0,
        stats: const {},
      );

      // Save to service
      await _socialService.updateUserProfile(newProfile);

      return newProfile;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color screenBackgroundColor = KAppColors.getBackground(context);
    final colorScheme = Theme.of(context).colorScheme;
    final profile = _currentProfile;
    final displayName = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : (widget.user.name.isNotEmpty ? widget.user.name : '—');
    final username = profile?.username.isNotEmpty == true
        ? '@${profile!.username}'
        : (widget.user.email.isNotEmpty
              ? '@${widget.user.email.split('@').first}'
              : '—');
    final bio = profile?.bio;
    final visibleFollowing = _following.take(_inlinePeopleLimit).toList();
    final visibleRecommended = _recommendedUsers
        .take(_inlinePeopleLimit)
        .toList();
    final visiblePublishers = _followedPublishers
        .take(_inlinePublisherLimit)
        .toList();
    final sourceUserId = _currentProfile?.userId ?? widget.user.userId;
    final followedUsersPosts = _networkPosts
        .where((post) => post.userId != sourceUserId)
        .toList();

    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: screenBackgroundColor,
      child: Scaffold(
        backgroundColor: screenBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: colorScheme.primary,
            child: CustomScrollView(
              slivers: [
                // Header
                MeasuredPinnedHeaderSliver(
                  height: HomeHeader.estimatedHeight(
                    title: 'Social',
                    subtitle: 'See what your network is reading',
                    footerHeight: 48,
                    footerSpacing: KDesignConstants.spacing12,
                  ),
                  child: HomeHeader(
                    title: 'Social',
                    subtitle: 'See what your network is reading',
                    showActions: true,
                    footerSpacing: KDesignConstants.spacing12,
                    footer: _buildFeedTabs(),
                    viewToggle: IconButton(
                      icon: const Icon(Icons.person_outline),
                      tooltip: 'My Space',
                      color: KAppColors.getOnBackground(
                        context,
                      ).withValues(alpha: 0.7),
                      onPressed: () async {
                        final currentUser = await AuthService()
                            .getCurrentUser();
                        final currentUserId =
                            currentUser?['id'] as String? ??
                            currentUser?['userId'] as String?;
                        final profileId =
                            _currentProfile?.userId ??
                            currentUserId ??
                            widget.user.userId;

                        if (!context.mounted) return;

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserProfilePage(userId: profileId),
                          ),
                        );
                        if (mounted) {
                          _loadData(showSpinner: false);
                        }
                      },
                    ),
                    useSafeArea: false,
                  ),
                ),

                if (_isLoading && !_isRefreshing)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(KDesignConstants.spacing40),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else ...[
                  const SliverToBoxAdapter(
                    child: SizedBox(height: KDesignConstants.spacing12),
                  ),
                  if (_activeTabIndex == 4) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingHorizontalMd,
                        child: _buildSectionHeader(
                          title: 'My Space',
                          subtitle: 'Your social control center',
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing12),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingHorizontalMd,
                        child: _buildProfileCard(
                          displayName: displayName,
                          username: username,
                          bio: bio,
                          colorScheme: colorScheme,
                          profileId: profile?.userId ?? widget.user.userId,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing16),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingHorizontalMd,
                        child: _buildMySpaceInsightsCard(),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing16),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingHorizontalMd,
                        child: _buildMySpaceHubActions(sourceUserId),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing24),
                    ),

                    // Reading Lists
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingHorizontalMd,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'My Reading Lists',
                              style: KAppTextStyles.titleSmall.copyWith(
                                color: KAppColors.getOnBackground(
                                  context,
                                ).withValues(alpha: 0.6),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ReadingListsPage(),
                                  ),
                                );
                                if (mounted) {
                                  _loadData(showSpinner: false);
                                }
                              },
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_recentLists.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingMd,
                          child: _buildEmptyCard(
                            icon: Icons.library_add_outlined,
                            title: 'No reading lists yet',
                            subtitle:
                                'Create your first list and share it with others.',
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildListTile(_recentLists[index]),
                          childCount: _recentLists.length,
                        ),
                      ),
                  ] else if (_activeTabIndex == 0) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingHorizontalMd,
                        child: _buildSectionHeader(
                          title: 'Your Feed',
                          subtitle: 'Stories and activity from your network',
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing12),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingHorizontalMd,
                        child: _buildFeedOverviewCard(),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing12),
                    ),
                    if (_recentActivity.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingHorizontalMd,
                          child: _buildSectionHeader(
                            title: 'Latest Activity',
                            subtitle: 'Prioritized by people you follow',
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing8),
                    ),
                    if (_recentActivity.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingHorizontalMd,
                          child: _buildFeedFilters(),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing12),
                    ),
                    if (_networkHighlights.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingHorizontalMd,
                          child: _buildSectionHeader(
                            title: 'Network Highlights',
                            subtitle: 'Most shared reads in your circle',
                            actionLabel: 'View more',
                            onActionTap: _openNetworkHighlights,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: KDesignConstants.spacing12),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 120,
                          child: ListView.separated(
                            padding: KDesignConstants.paddingHorizontalMd,
                            scrollDirection: Axis.horizontal,
                            itemCount: _networkHighlights.take(5).length,
                            itemBuilder: (context, index) =>
                                _buildNetworkHighlightMiniCard(
                                  _networkHighlights[index],
                                ),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: KDesignConstants.spacing12),
                      ),
                    ],
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingHorizontalMd,
                        child: _buildSectionHeader(
                          title: 'Network Posts',
                          subtitle: 'Fresh takes from people you follow',
                          actionLabel: followedUsersPosts.isNotEmpty
                              ? 'View more'
                              : null,
                          onActionTap: followedUsersPosts.isNotEmpty
                              ? _openPostsTab
                              : null,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing12),
                    ),
                    if (followedUsersPosts.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingHorizontalMd,
                          child: _buildEmptyCard(
                            icon: Icons.edit_note,
                            title: 'No network posts yet',
                            subtitle:
                                'Posts from people you follow will appear here.',
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 148,
                          child: ListView.separated(
                            padding: KDesignConstants.paddingHorizontalMd,
                            scrollDirection: Axis.horizontal,
                            itemCount: followedUsersPosts.take(5).length,
                            itemBuilder: (context, index) =>
                                _buildNetworkPostMiniCard(
                                  followedUsersPosts[index],
                                ),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing12),
                    ),
                    if (_filteredFeedItems().isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildActivityItem(_filteredFeedItems()[index]),
                          childCount: _filteredFeedItems().length,
                        ),
                      ),
                    if (_mindfulMode)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingMd,
                          child: _buildWellbeingCard(),
                        ),
                      ),
                  ] else if (_activeTabIndex == 0 && _recentActivity.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingMd,
                        child: _buildEmptyCard(
                          icon: Icons.newspaper_outlined,
                          title: 'No shared stories yet',
                          subtitle:
                              'Follow readers or share an article to kickstart your feed.',
                        ),
                      ),
                    )
                  else if (_activeTabIndex == 1 && _networkHighlights.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingMd,
                        child: _buildEmptyCard(
                          icon: Icons.ios_share_outlined,
                          title: 'No shared articles yet',
                          subtitle:
                              'When people you follow share a story, it will appear here.',
                        ),
                      ),
                    )
                  else if (_activeTabIndex == 1)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildNetworkHighlightListCard(
                          _networkHighlights[index],
                        ),
                        childCount: _networkHighlights.length,
                      ),
                    ),
                  if (_activeTabIndex == 2) ...[
                    if (_postsLoadFailed)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingMd,
                          child: _buildEmptyCard(
                            icon: Icons.error_outline,
                            title: 'Could not load posts',
                            subtitle:
                                'There was a loading issue. Pull to refresh or try again.',
                          ),
                        ),
                      )
                    else if (_networkPosts.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingMd,
                          child: _buildEmptyCard(
                            icon: Icons.edit_note,
                            title: 'No posts yet',
                            subtitle: 'Be first to post to your network.',
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildNetworkPostCard(_networkPosts[index]),
                          childCount: _networkPosts.length,
                        ),
                      ),
                    if (_postsHasMore || _isLoadingMorePosts)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: OutlinedButton(
                            onPressed: _isLoadingMorePosts
                                ? null
                                : _loadMorePosts,
                            child: _isLoadingMorePosts
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Load more posts'),
                          ),
                        ),
                      ),
                  ],
                  if (_activeTabIndex == 3) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingHorizontalMd,
                        child: _buildSectionHeader(
                          title: 'People',
                          subtitle: 'Find readers and grow your circle',
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing12),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingHorizontalMd,
                        child: _buildActionCard(
                          icon: Icons.search,
                          label: 'Search readers',
                          subtitle: 'Find people by name or username',
                          color: KAppColors.blue,
                          onTap: _showSearchUsers,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing16),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: KDesignConstants.paddingHorizontalMd,
                        child: _buildSectionHeader(
                          title: 'People You Follow',
                          subtitle: 'Quick access to your circle',
                          actionLabel: _following.length > _inlinePeopleLimit
                              ? 'View more'
                              : null,
                          onActionTap: _following.length > _inlinePeopleLimit
                              ? () => _openUsersList(
                                  title: 'People You Follow',
                                  subtitle: 'All readers in your circle',
                                  sourceUserId: sourceUserId,
                                  mode: SocialUsersListMode.following,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing12),
                    ),
                    if (_following.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingMd,
                          child: _buildEmptyCard(
                            icon: Icons.people_outline,
                            title: 'No one followed yet',
                            subtitle:
                                'Follow readers to see their shared stories.',
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 184,
                          child: ListView.separated(
                            padding: KDesignConstants.paddingHorizontalMd,
                            scrollDirection: Axis.horizontal,
                            itemCount: visibleFollowing.length,
                            itemBuilder: (context, index) =>
                                _buildPersonMiniCard(visibleFollowing[index]),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: KDesignConstants.spacing16),
                    ),
                    if (_recommendedUsers.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingMd,
                          child: _buildEmptyCard(
                            icon: Icons.group_outlined,
                            title: 'No recommendations yet',
                            subtitle:
                                'Check back after you follow a few readers.',
                          ),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingHorizontalMd,
                          child: _buildSectionHeader(
                            title: 'Recommended People',
                            subtitle: 'Readers with similar interests',
                            actionLabel: _recommendedUsers.isNotEmpty
                                ? 'View more'
                                : null,
                            onActionTap: _recommendedUsers.isNotEmpty
                                ? () => _openUsersList(
                                    title: 'Recommended People',
                                    subtitle: 'Readers you may want to follow',
                                    sourceUserId: sourceUserId,
                                    mode: SocialUsersListMode.recommended,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: KDesignConstants.spacing12),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 196,
                          child: ListView.separated(
                            padding: KDesignConstants.paddingHorizontalMd,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final user = visibleRecommended[index];
                              return _buildRecommendedUserCard(user);
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemCount: visibleRecommended.length,
                          ),
                        ),
                      ),
                    ],
                  ],

                  if (_activeTabIndex == 0 || _activeTabIndex == 1) ...[
                    ...[
                      const SliverToBoxAdapter(
                        child: SizedBox(height: KDesignConstants.spacing24),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingHorizontalMd,
                          child: _buildSectionHeader(
                            title: 'Followed Publishers',
                            subtitle: 'Latest from sources you trust',
                            actionLabel: 'View more',
                            onActionTap: () =>
                                _openPublishersList(sourceUserId),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: KDesignConstants.spacing12),
                      ),
                      SliverToBoxAdapter(
                        child: _followedPublishers.isEmpty
                            ? Padding(
                                padding: KDesignConstants.paddingHorizontalMd,
                                child: _buildEmptyCard(
                                  icon: Icons.public_outlined,
                                  title: 'No followed publishers yet',
                                  subtitle:
                                      'Follow news sources to see them here.',
                                ),
                              )
                            : SizedBox(
                                height: 160,
                                child: ListView.separated(
                                  padding: KDesignConstants.paddingHorizontalMd,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) =>
                                      _buildPublisherCard(
                                        visiblePublishers[index],
                                      ),
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemCount: visiblePublishers.length,
                                ),
                              ),
                      ),
                    ],
                    if (_followedTopics.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: SizedBox(height: KDesignConstants.spacing24),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: KDesignConstants.paddingHorizontalMd,
                          child: _buildSectionHeader(
                            title: 'Topics for You',
                            subtitle: 'Trending themes based on your reading',
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: KDesignConstants.spacing12),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 36,
                          child: ListView.separated(
                            padding: KDesignConstants.paddingHorizontalMd,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) =>
                                _buildTopicChip(_followedTopics[index]),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemCount: _followedTopics.length,
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SliverToBoxAdapter(
                    child: SizedBox(height: KDesignConstants.spacing24),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: KDesignConstants.spacing48),
                  ),
                ],
              ],
            ),
          ),
        ),
        floatingActionButton: _activeTabIndex == 2
            ? FloatingActionButton.extended(
                onPressed: _openCreatePostPage,
                icon: const Icon(Icons.edit),
                label: const Text('Create Post'),
              )
            : null,
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: KBorderRadius.lg,
      child: Container(
        padding: KDesignConstants.paddingMd,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: KBorderRadius.lg,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: KBorderRadius.md,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: KDesignConstants.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(
                        context,
                      ).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (actionLabel != null && onActionTap != null)
              TextButton(
                onPressed: onActionTap,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel,
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: KAppColors.getPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: KAppTextStyles.bodySmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Future<void> _openUsersList({
    required String title,
    required String subtitle,
    required String sourceUserId,
    required SocialUsersListMode mode,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SocialUsersListPage(
          title: title,
          subtitle: subtitle,
          currentUser: widget.user,
          sourceUserId: sourceUserId,
          mode: mode,
        ),
      ),
    );
    if (mounted) {
      _loadData(showSpinner: false);
    }
  }

  Future<void> _openPublishersList(String sourceUserId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowedPublishersListPage(
          userId: sourceUserId,
          currentUser: widget.user,
        ),
      ),
    );
    if (mounted) {
      _loadData(showSpinner: false);
    }
  }

  Future<void> _openNetworkHighlights() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NetworkHighlightsPage()),
    );
    if (mounted) {
      _loadData(showSpinner: false);
    }
  }

  void _openPostsTab() {
    if (!mounted) return;
    _onTabSelected(2);
  }

  Future<void> _onTabSelected(int tabIndex) async {
    if (!mounted) return;
    final needsLoad =
        (tabIndex == 0 || tabIndex == 1) ? !_feedLoaded : tabIndex == 2
        ? !_postsLoaded
        : tabIndex == 3
        ? !_peopleLoaded
        : !_mySpaceLoaded;

    setState(() {
      _activeTabIndex = tabIndex;
      if (needsLoad) {
        _isLoading = true;
      }
    });

    final profile = await _ensureProfile();
    if (profile == null) return;
    await _loadActiveTabData(profile: profile, force: false);
  }

  Future<void> _unfollowPublisherFromHub(String publisherName) async {
    final userId = _currentProfile?.userId ?? widget.user.userId;
    if (userId.isEmpty) return;
    final shouldUnfollow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unfollow Publisher'),
        content: Text('Unfollow $publisherName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );
    if (shouldUnfollow != true) return;

    final success = await FollowedPublishersService.instance.unfollowPublisher(
      userId,
      publisherName,
    );
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to unfollow publisher')),
      );
      return;
    }
    setState(() {
      _followedPublishers.remove(publisherName);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Unfollowed $publisherName')));
  }

  Widget _buildFeedOverviewCard() {
    final followingCount = _following.length;
    final sharedToday = _sharedActivity.take(8).length;
    final activityCount = _activeFeedFilter == 3
        ? _networkPosts.length
        : _filteredFeedItems().length;
    final onBackground = KAppColors.getOnBackground(context);

    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        borderRadius: KBorderRadius.lg,
        border: Border.all(color: onBackground.withValues(alpha: 0.08)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KAppColors.getPrimary(context).withValues(alpha: 0.11),
            onBackground.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network pulse',
            style: KAppTextStyles.labelSmall.copyWith(
              color: onBackground.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            followingCount == 0
                ? 'Follow readers to personalize this feed.'
                : '$sharedToday stories shared recently by your network.',
            style: KAppTextStyles.bodyMedium.copyWith(
              color: onBackground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFeedOverviewPill(
                icon: Icons.people_alt_outlined,
                label: '$followingCount following',
              ),
              const SizedBox(width: 8),
              _buildFeedOverviewPill(
                icon: Icons.dynamic_feed_outlined,
                label: '$activityCount feed items',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedOverviewPill({
    required IconData icon,
    required String label,
  }) {
    final onBackground = KAppColors.getOnBackground(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: onBackground.withValues(alpha: 0.06),
        borderRadius: KBorderRadius.xl,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: onBackground.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: KAppTextStyles.labelSmall.copyWith(
              color: onBackground.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMySpaceInsightsCard() {
    final onBackground = KAppColors.getOnBackground(context);
    final stats = (_profileInsights?['stats'] as Map<String, dynamic>?) ?? const {};
    final streak =
        (_profileInsights?['streak'] as Map<String, dynamic>?) ?? const {};
    final favorites =
        (_profileInsights?['favorites'] as Map<String, dynamic>?) ?? const {};
    final thisWeek = (stats['last7DaysCount'] as num?)?.toInt() ?? 0;
    final avgPerDay = (stats['averageArticlesPerDay'] as num?)?.toDouble() ?? 0;
    final currentStreak = (streak['currentDays'] as num?)?.toInt() ?? 0;
    final topicsRaw = (favorites['topics'] as List?) ?? const [];
    final publishersRaw = (favorites['publishers'] as List?) ?? const [];
    final topics = topicsRaw.whereType<String>().where((e) => e.isNotEmpty).take(3).toList();
    final publishers = publishersRaw
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();

    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.035),
        borderRadius: KBorderRadius.lg,
        border: Border.all(color: onBackground.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Snapshot',
            style: KAppTextStyles.bodyMedium.copyWith(
              color: onBackground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Read $thisWeek articles this week • ${avgPerDay.toStringAsFixed(1)} per day • $currentStreak-day streak',
            style: KAppTextStyles.bodySmall.copyWith(
              color: onBackground.withValues(alpha: 0.72),
            ),
          ),
          if (topics.isNotEmpty || publishers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...topics.map(
                  (topic) => _buildMySpacePill(
                    icon: Icons.local_offer_outlined,
                    label: topic,
                  ),
                ),
                ...publishers.map(
                  (publisher) => _buildMySpacePill(
                    icon: Icons.public_outlined,
                    label: publisher,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMySpacePill({required IconData icon, required String label}) {
    final onBackground = KAppColors.getOnBackground(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: onBackground.withValues(alpha: 0.06),
        borderRadius: KBorderRadius.xl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onBackground.withValues(alpha: 0.68)),
          const SizedBox(width: 6),
          Text(
            label,
            style: KAppTextStyles.labelSmall.copyWith(
              color: onBackground.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMySpaceHubActions(String sourceUserId) {
    final counts = (_mySpaceSummary?['counts'] as Map<String, dynamic>?) ?? const {};
    final postsCount = (counts['posts'] as num?)?.toInt() ?? _networkPosts.length;
    final sharedCount =
        (counts['networkHighlights'] as num?)?.toInt() ?? _networkHighlights.length;
    final followingCount = (counts['following'] as num?)?.toInt() ?? _following.length;
    final publishersCount = (counts['followedPublishers'] as num?)?.toInt() ?? _followedPublishers.length;
    final listsCount =
        (counts['readingLists'] as num?)?.toInt() ??
        (_currentProfile?.collectionsCount ?? _recentLists.length);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.9,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMySpaceActionCard(
          icon: Icons.edit_note,
          title: 'Posts',
          value: '$postsCount',
          subtitle: 'Write and manage',
          onTap: () => setState(() => _activeTabIndex = 2),
        ),
        _buildMySpaceActionCard(
          icon: Icons.auto_awesome_motion,
          title: 'Shared',
          value: '$sharedCount',
          subtitle: 'Network highlights',
          onTap: () => setState(() => _activeTabIndex = 1),
        ),
        _buildMySpaceActionCard(
          icon: Icons.people_alt_outlined,
          title: 'People',
          value: '$followingCount',
          subtitle: 'Your following list',
          onTap: () => setState(() => _activeTabIndex = 3),
        ),
        _buildMySpaceActionCard(
          icon: Icons.public_outlined,
          title: 'Publishers',
          value: '$publishersCount',
          subtitle: 'Sources you trust',
          onTap: () => _openPublishersList(sourceUserId),
        ),
        _buildMySpaceActionCard(
          icon: Icons.library_books_outlined,
          title: 'Lists',
          value: '$listsCount',
          subtitle: 'Curated reads',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReadingListsPage()),
            );
            if (mounted) _loadData(showSpinner: false);
          },
        ),
        _buildMySpaceActionCard(
          icon: Icons.person_outline,
          title: 'Profile',
          value: '@${_currentProfile?.username ?? 'reader'}',
          subtitle: 'Edit and preview',
          onTap: () async {
            final currentUser = await AuthService().getCurrentUser();
            final currentUserId =
                currentUser?['id'] as String? ??
                currentUser?['userId'] as String?;
            final profileId =
                _currentProfile?.userId ?? currentUserId ?? widget.user.userId;
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfilePage(userId: profileId),
              ),
            );
            if (mounted) _loadData(showSpinner: false);
          },
        ),
      ],
    );
  }

  Widget _buildMySpaceActionCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final onBackground = KAppColors.getOnBackground(context);
    return InkWell(
      onTap: onTap,
      borderRadius: KBorderRadius.lg,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: onBackground.withValues(alpha: 0.035),
          borderRadius: KBorderRadius.lg,
          border: Border.all(color: onBackground.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.14),
                borderRadius: KBorderRadius.md,
              ),
              child: Icon(
                icon,
                size: 18,
                color: KAppColors.getPrimary(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: onBackground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: onBackground.withValues(alpha: 0.76),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: onBackground.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
        borderRadius: KBorderRadius.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFeedTabButton(
              label: 'Feed',
              isActive: _activeTabIndex == 0,
              onTap: () => _onTabSelected(0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildFeedTabButton(
              label: 'Shared',
              isActive: _activeTabIndex == 1,
              onTap: () => _onTabSelected(1),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildFeedTabButton(
              label: 'Posts',
              isActive: _activeTabIndex == 2,
              onTap: () => _onTabSelected(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildFeedTabButton(
              label: 'People',
              isActive: _activeTabIndex == 3,
              onTap: () => _onTabSelected(3),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildFeedTabButton(
              label: 'My Space',
              isActive: _activeTabIndex == 4,
              onTap: () => _onTabSelected(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedUserCard(UserProfile user) {
    final displayName = user.displayName.isNotEmpty
        ? user.displayName
        : user.username;
    final username = user.username.isNotEmpty ? '@${user.username}' : '@reader';
    final latestShareTitle = _latestSharedTitleForUser(user.userId);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileViewPage(
              currentUser: widget.user,
              profileUserId: user.userId,
            ),
          ),
        );
      },
      borderRadius: KBorderRadius.lg,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildUserAvatar(user, size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KAppTextStyles.bodyMedium.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.getOnBackground(
                            context,
                          ).withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (latestShareTitle != null && latestShareTitle.isNotEmpty)
              Text(
                'Recently shared: $latestShareTitle',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(
                    context,
                  ).withValues(alpha: 0.84),
                ),
              )
            else
              Text(
                'Suggested based on similar reading activity',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(
                    context,
                  ).withValues(alpha: 0.72),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  try {
                    await _socialService.followUser(user.userId);
                    if (mounted) {
                      setState(() {
                        _recommendedUsers.removeWhere(
                          (u) => u.userId == user.userId,
                        );
                      });
                    }
                  } catch (_) {}
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text('Follow'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: KBorderRadius.md,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? KAppColors.getPrimary(context) : Colors.transparent,
          borderRadius: KBorderRadius.md,
        ),
        child: Center(
          child: Text(
            label,
            style: KAppTextStyles.labelSmall.copyWith(
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimary
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required String displayName,
    required String username,
    required String? bio,
    required ColorScheme colorScheme,
    required String profileId,
  }) {
    final counts = (_mySpaceSummary?['counts'] as Map<String, dynamic>?) ?? const {};
    final stats = (_profileInsights?['stats'] as Map<String, dynamic>?) ?? const {};
    final readCount =
        (stats['totalArticlesRead'] as num?)?.toInt() ??
        (_currentProfile?.articlesReadCount ?? 0);
    final followersCount =
        (counts['followers'] as num?)?.toInt() ?? _followers.length;
    final followingCount =
        (counts['following'] as num?)?.toInt() ?? _following.length;
    final listsCount =
        (counts['readingLists'] as num?)?.toInt() ??
        (_currentProfile?.collectionsCount ?? 0);

    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
        borderRadius: KBorderRadius.xl,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: KAppColors.getPrimary(context),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName.substring(0, 1).toUpperCase()
                      : '—',
                  style: KAppTextStyles.headlineMedium.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: KAppTextStyles.titleLarge.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: KDesignConstants.spacing4),
                    Text(
                      username,
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(
                          context,
                        ).withValues(alpha: 0.6),
                      ),
                    ),
                    if (bio != null && bio.trim().isNotEmpty) ...[
                      const SizedBox(height: KDesignConstants.spacing8),
                      Text(
                        bio,
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(
                            context,
                          ).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing4),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  value: '$readCount',
                  label: 'Read',
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing8),
              Expanded(
                child: _buildStatTile(
                  value: '$followersCount',
                  label: 'Followers',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowersFollowingPage(
                          currentUser: widget.user,
                          userId: profileId,
                          listType: FollowListType.followers,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) {
                        _loadData(showSpinner: false);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing8),
              Expanded(
                child: _buildStatTile(
                  value: '$followingCount',
                  label: 'Following',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowersFollowingPage(
                          currentUser: widget.user,
                          userId: profileId,
                          listType: FollowListType.following,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) {
                        _loadData(showSpinner: false);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing8),
              Expanded(
                child: _buildStatTile(
                  value: '$listsCount',
                  label: 'Lists',
                ),
              ),
            ],
          ),
          if (followersCount == 0 && followingCount == 0) ...[
            const SizedBox(height: KDesignConstants.spacing12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(
                  context,
                ).withValues(alpha: 0.04),
                borderRadius: KBorderRadius.md,
                border: Border.all(
                  color: KAppColors.getOnBackground(
                    context,
                  ).withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 18,
                    color: KAppColors.getOnBackground(
                      context,
                    ).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: KDesignConstants.spacing8),
                  Expanded(
                    child: Text(
                      'No followers yet. Find readers to connect with.',
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(
                          context,
                        ).withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UserSearchPage(currentUser: widget.user),
                        ),
                      );
                      if (mounted) {
                        _loadData(showSpinner: false);
                      }
                    },
                    child: const Text('Find'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    final tile = Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: KAppTextStyles.titleMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: KAppTextStyles.labelSmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return InkWell(onTap: onTap, borderRadius: KBorderRadius.lg, child: tile);
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
              borderRadius: KBorderRadius.md,
            ),
            child: Icon(icon, color: KAppColors.getPrimary(context)),
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(
                      context,
                    ).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(ReadingList list) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KDesignConstants.spacing16,
        vertical: KDesignConstants.spacing4,
      ),
      child: InkWell(
        borderRadius: KBorderRadius.md,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReadingListDetailPage(
                listId: list.id,
                initialList: list,
                currentUserId: _currentProfile?.userId ?? widget.user.userId,
              ),
            ),
          );
          if (!mounted) return;
          _loadData(showSpinner: false);
        },
        child: Container(
          padding: KDesignConstants.cardPaddingCompact,
          decoration: BoxDecoration(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
            borderRadius: KBorderRadius.md,
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.library_books,
                color: KAppColors.getPrimary(context),
                size: 20,
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${list.articleCount} articles',
                      style: KAppTextStyles.labelSmall.copyWith(
                        color: KAppColors.getOnBackground(
                          context,
                        ).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(ActivityFeedItem activity) {
    final isSharedArticle = activity.activityType == ActivityType.shareArticle;
    final username = activity.username.isNotEmpty
        ? activity.username
        : 'reader';
    final avatarLetter = username.substring(0, 1).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KDesignConstants.spacing16,
        vertical: KDesignConstants.spacing8,
      ),
      child: Container(
        padding: KDesignConstants.paddingMd,
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: KAppColors.getPrimary(context),
                  backgroundImage: activity.userAvatarUrl != null
                      ? NetworkImage(activity.userAvatarUrl!)
                      : null,
                  child: activity.userAvatarUrl == null
                      ? Text(
                          avatarLetter,
                          style: KAppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@$username',
                        style: KAppTextStyles.bodyMedium.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getActivityText(activity),
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(
                            context,
                          ).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _getTimeAgo(activity.timestamp),
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: KAppColors.getOnBackground(
                      context,
                    ).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            if (isSharedArticle) ...[
              const SizedBox(height: KDesignConstants.spacing12),
              InkWell(
                onTap: () => _openSharedArticle(activity),
                borderRadius: KBorderRadius.md,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KAppColors.getBackground(context),
                    borderRadius: KBorderRadius.md,
                    border: Border.all(
                      color: KAppColors.getOnBackground(
                        context,
                      ).withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activity.articleImageUrl != null &&
                          activity.articleImageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: KBorderRadius.sm,
                          child: Image.network(
                            activity.articleImageUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: KAppColors.getPrimary(
                              context,
                            ).withValues(alpha: 0.12),
                            borderRadius: KBorderRadius.sm,
                          ),
                          child: Icon(
                            Icons.newspaper,
                            color: KAppColors.getPrimary(context),
                          ),
                        ),
                      const SizedBox(width: KDesignConstants.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (activity.articleSourceName != null &&
                                activity.articleSourceName!.isNotEmpty)
                              Text(
                                activity.articleSourceName!,
                                style: KAppTextStyles.labelSmall.copyWith(
                                  color: KAppColors.getOnBackground(
                                    context,
                                  ).withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            Text(
                              activity.articleTitle ?? 'Shared article',
                              style: KAppTextStyles.bodyMedium.copyWith(
                                color: KAppColors.getOnBackground(context),
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (activity.articleDescription != null &&
                                activity.articleDescription!
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                activity.articleDescription!,
                                style: KAppTextStyles.bodySmall.copyWith(
                                  color: KAppColors.getOnBackground(
                                    context,
                                  ).withValues(alpha: 0.6),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: KAppColors.getOnBackground(
                          context,
                        ).withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.readArticle:
        return Icons.article;
      case ActivityType.createList:
        return Icons.library_add;
      case ActivityType.updateList:
        return Icons.edit;
      case ActivityType.addToList:
        return Icons.playlist_add;
      case ActivityType.followUser:
        return Icons.person_add;
      case ActivityType.shareList:
        return Icons.share;
      case ActivityType.shareArticle:
        return Icons.ios_share;
      case ActivityType.commentArticle:
        return Icons.comment;
      case ActivityType.likeArticle:
        return Icons.favorite;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.readArticle:
        return KAppColors.blue;
      case ActivityType.createList:
        return KAppColors.green;
      case ActivityType.updateList:
        return KAppColors.green;
      case ActivityType.addToList:
        return KAppColors.purple;
      case ActivityType.followUser:
        return KAppColors.orange;
      case ActivityType.shareList:
        return KAppColors.cyan;
      case ActivityType.shareArticle:
        return KAppColors.blue;
      case ActivityType.commentArticle:
        return KAppColors.red;
      case ActivityType.likeArticle:
        return KAppColors.pink;
    }
  }

  String _getActivityText(ActivityFeedItem activity) {
    switch (activity.activityType) {
      case ActivityType.readArticle:
        return 'Read "${activity.articleTitle ?? 'an article'}"';
      case ActivityType.createList:
        return 'Created list "${activity.listName ?? 'a list'}"';
      case ActivityType.updateList:
        return 'Updated list "${activity.listName ?? 'a list'}"';
      case ActivityType.addToList:
        return 'Added article to "${activity.listName ?? 'a list'}"';
      case ActivityType.followUser:
        return 'Followed @${activity.followedUsername ?? 'a user'}';
      case ActivityType.shareList:
        return 'Shared list "${activity.listName ?? 'a list'}"';
      case ActivityType.shareArticle:
        return 'Shared "${activity.articleTitle ?? 'an article'}"';
      case ActivityType.commentArticle:
        return 'Commented on an article';
      case ActivityType.likeArticle:
        return 'Liked an article';
    }
  }

  Future<ArticleModel?> _fetchArticleById(String articleId) async {
    try {
      final response = await _api.get(
        'articles/$articleId',
        timeout: const Duration(seconds: 15),
      );
      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        final articleJson = data['article'] as Map<String, dynamic>?;
        if (articleJson != null) {
          return ArticleModel.fromJson(articleJson);
        }
      }
    } catch (e) {
      // Ignore, handled by caller
    }
    return null;
  }

  Future<void> _openSharedArticle(ActivityFeedItem activity) async {
    final articleId = activity.articleId;
    if (articleId == null || articleId.isEmpty) return;

    final article = await _fetchArticleById(articleId);
    if (article == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this article right now')),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(article: article),
      ),
    );
  }

  int _getHighlightLikeCount(NetworkHighlight highlight) =>
      _highlightLikeCounts[highlight.dedupeKey] ?? highlight.likeCount;

  int _getHighlightCommentCount(NetworkHighlight highlight) =>
      _highlightCommentCounts[highlight.dedupeKey] ?? highlight.commentCount;

  bool _isHighlightLiked(NetworkHighlight highlight) =>
      _highlightLiked[highlight.dedupeKey] ?? false;

  Future<void> _openNetworkHighlightArticle(NetworkHighlight highlight) async {
    final articleId = highlight.articleId;
    if (articleId == null || articleId.isEmpty) return;
    final article = await _fetchArticleById(articleId);
    if (!mounted) return;
    if (article == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this article right now')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(article: article),
      ),
    );
  }

  Future<void> _toggleNetworkHighlightLike(NetworkHighlight highlight) async {
    final articleId = highlight.articleId;
    if (articleId == null || articleId.isEmpty) return;
    if (_highlightLikeBusy.contains(highlight.dedupeKey)) return;
    final userId = _currentProfile?.userId.isNotEmpty == true
        ? _currentProfile!.userId
        : widget.user.userId;
    if (userId.isEmpty) return;

    final wasLiked = _isHighlightLiked(highlight);
    final currentCount = _getHighlightLikeCount(highlight);
    setState(() {
      _highlightLikeBusy.add(highlight.dedupeKey);
      _highlightLiked[highlight.dedupeKey] = !wasLiked;
      _highlightLikeCounts[highlight.dedupeKey] = wasLiked
          ? (currentCount > 0 ? currentCount - 1 : 0)
          : currentCount + 1;
    });

    final success = await _engagementService.toggleLike(userId, articleId);
    if (!mounted) return;
    if (!success) {
      setState(() {
        _highlightLiked[highlight.dedupeKey] = wasLiked;
        _highlightLikeCounts[highlight.dedupeKey] = currentCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update like right now')),
      );
    }
    setState(() {
      _highlightLikeBusy.remove(highlight.dedupeKey);
    });
  }

  Future<void> _openNetworkHighlightComments(NetworkHighlight highlight) async {
    await _openNetworkHighlightArticle(highlight);
  }

  Future<void> _openCreatePostPage() async {
    final createdPost = await Navigator.push<SocialPost>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );
    if (!mounted || createdPost == null) return;
    setState(() {
      _networkPosts = [createdPost, ..._networkPosts];
      _activeTabIndex = 2;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post published.')));
  }

  Future<void> _togglePostLike(SocialPost post) async {
    final index = _networkPosts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;
    final current = _networkPosts[index];
    final nextLiked = !current.isLiked;
    final nextCount = nextLiked
        ? current.likeCount + 1
        : (current.likeCount > 0 ? current.likeCount - 1 : 0);
    setState(() {
      _networkPosts[index] = current.copyWith(
        isLiked: nextLiked,
        likeCount: nextCount,
      );
    });

    final success = nextLiked
        ? await _socialService.likeNetworkPost(post.id)
        : await _socialService.unlikeNetworkPost(post.id);
    if (!mounted) return;
    if (!success) {
      setState(() {
        _networkPosts[index] = current;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not update like')));
    }
  }

  Future<void> _commentOnPost(SocialPost post) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: controller,
          maxLength: 300,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write your comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) return;

    final success = await _socialService.commentOnNetworkPost(post.id, text);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not add comment')));
      return;
    }
    final index = _networkPosts.indexWhere((p) => p.id == post.id);
    if (index >= 0) {
      setState(() {
        final current = _networkPosts[index];
        _networkPosts[index] = current.copyWith(
          commentCount: current.commentCount + 1,
        );
      });
    }
  }

  Future<void> _openPostArticle(SocialPost post) async {
    final articleId = post.articleId;
    if (articleId != null && articleId.isNotEmpty) {
      final article = await _fetchArticleById(articleId);
      if (!mounted) return;
      if (article == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this article right now')),
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleDetailPage(article: article),
        ),
      );
      return;
    }

    final articleUrl = post.articleUrl?.trim();
    final uri = articleUrl != null ? Uri.tryParse(articleUrl) : null;
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this article right now')),
      );
      return;
    }

    final previewTitle = _effectiveArticleTitle(post);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleSourceWebViewPage(
          title: previewTitle == 'Open shared article'
              ? (_articleHostLabel(post.articleUrl) ?? 'Shared article')
              : previewTitle,
          url: uri.toString(),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _effectivePostHeading(SocialPost post) {
    final heading = post.heading?.trim();
    if (heading != null && heading.isNotEmpty) return heading;
    final articleTitle = post.articleTitle?.trim();
    if (articleTitle != null && articleTitle.isNotEmpty) return articleTitle;
    return '';
  }

  String _effectiveArticleTitle(SocialPost post) {
    final articleTitle = post.articleTitle?.trim();
    if (articleTitle != null && articleTitle.isNotEmpty) return articleTitle;
    return 'Open shared article';
  }

  String? _articleHostLabel(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final parsed = Uri.tryParse(rawUrl.trim());
    final host = parsed?.host.trim() ?? '';
    if (host.isEmpty) return null;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  bool _hasArticlePreview(SocialPost post) {
    return (post.articleId?.isNotEmpty == true) ||
        (post.articleTitle?.isNotEmpty == true) ||
        (post.articleImageUrl?.isNotEmpty == true) ||
        (post.articleUrl?.isNotEmpty == true);
  }

  void _showSearchUsers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserSearchPage(currentUser: widget.user),
      ),
    );
    if (mounted) {
      _loadData(showSpinner: false);
    }
  }

  void _showFollowersList(
    BuildContext context,
    List<UserProfile> users,
    String title,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KAppColors.getBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: KDesignConstants.paddingMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: KAppTextStyles.titleLarge.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: KAppColors.getOnBackground(context),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: KDesignConstants.spacing16),
            if (users.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No $title yet',
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(
                        context,
                      ).withValues(alpha: 0.6),
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: KAppColors.getPrimary(context),
                        child: Text(
                          user.displayName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.displayName,
                        style: KAppTextStyles.bodyMedium.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '@${user.username}',
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(
                            context,
                          ).withValues(alpha: 0.6),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileViewPage(
                              currentUser: widget.user,
                              profileUserId: user.userId,
                            ),
                          ),
                        ).then((_) {
                          if (mounted) {
                            _loadData(showSpinner: false);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(label: 'All', index: 0),
          const SizedBox(width: 8),
          _buildFilterChip(label: 'Lists', index: 1),
          const SizedBox(width: 8),
          _buildFilterChip(label: 'Shares', index: 2),
          const SizedBox(width: 12),
          _buildMindfulToggle(),
        ],
      ),
    );
  }

  Widget _buildMindfulToggle() {
    return InkWell(
      onTap: () => setState(() => _mindfulMode = !_mindfulMode),
      borderRadius: KBorderRadius.lg,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _mindfulMode
              ? KAppColors.getPrimary(context).withValues(alpha: 0.18)
              : KAppColors.getOnBackground(context).withValues(alpha: 0.04),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: _mindfulMode
                ? KAppColors.getPrimary(context).withValues(alpha: 0.4)
                : KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.self_improvement,
              size: 16,
              color: _mindfulMode
                  ? KAppColors.getPrimary(context)
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              'Mindful',
              style: KAppTextStyles.bodySmall.copyWith(
                color: _mindfulMode
                    ? KAppColors.getPrimary(context)
                    : KAppColors.getOnBackground(
                        context,
                      ).withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required int index}) {
    final isActive = _activeFeedFilter == index;
    return InkWell(
      onTap: () => setState(() => _activeFeedFilter = index),
      borderRadius: KBorderRadius.lg,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? KAppColors.getPrimary(context).withValues(alpha: 0.18)
              : KAppColors.getOnBackground(context).withValues(alpha: 0.04),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: isActive
                ? KAppColors.getPrimary(context).withValues(alpha: 0.4)
                : KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: KAppTextStyles.bodySmall.copyWith(
            color: isActive
                ? KAppColors.getPrimary(context)
                : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSharePromptCard() {
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context).withValues(alpha: 0.08),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KAppColors.getPrimary(context).withValues(alpha: 0.15),
              borderRadius: KBorderRadius.md,
            ),
            child: Icon(
              Icons.ios_share_outlined,
              color: KAppColors.getPrimary(context),
              size: 22,
            ),
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share with intention',
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a one-line takeaway so friends know why it matters.',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(
                      context,
                    ).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkPostCard(SocialPost post) {
    final onBackground = KAppColors.getOnBackground(context);
    final heading = _effectivePostHeading(post);
    final hasPreview = _hasArticlePreview(post);
    final articleHost = _articleHostLabel(post.articleUrl);
    final canOpenArticle =
        (post.articleId != null && post.articleId!.isNotEmpty) ||
        (post.articleUrl != null && post.articleUrl!.trim().isNotEmpty);
    final hasBody = post.text.trim().isNotEmpty;
    return Padding(
      padding: KDesignConstants.paddingHorizontalMd.copyWith(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          borderRadius: KBorderRadius.lg,
          color: KAppColors.getBackground(context).withValues(alpha: 0.78),
          border: Border.all(color: onBackground.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: onBackground.withValues(alpha: 0.015),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: KAppColors.getPrimary(
                    context,
                  ).withValues(alpha: 0.2),
                  backgroundImage:
                      post.userAvatarUrl != null &&
                          post.userAvatarUrl!.isNotEmpty
                      ? NetworkImage(post.userAvatarUrl!)
                      : null,
                  child:
                      post.userAvatarUrl == null || post.userAvatarUrl!.isEmpty
                      ? Text(
                          post.username.isNotEmpty
                              ? post.username.substring(0, 1).toUpperCase()
                              : 'R',
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${post.username}',
                        style: KAppTextStyles.bodyMedium.copyWith(
                          color: onBackground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getTimeAgo(post.createdAt),
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: onBackground.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (heading.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                heading,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: KAppTextStyles.titleSmall.copyWith(
                  color: onBackground,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ],
            if (hasBody) ...[
              const SizedBox(height: 10),
              Text(
                post.text.trim(),
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: onBackground.withValues(alpha: 0.88),
                  height: 1.45,
                ),
              ),
            ],
            if (hasPreview) ...[
              const SizedBox(height: 12),
              InkWell(
                borderRadius: KBorderRadius.md,
                onTap: canOpenArticle ? () => _openPostArticle(post) : null,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: onBackground.withValues(alpha: 0.05),
                    borderRadius: KBorderRadius.md,
                    border: Border.all(
                      color: onBackground.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (post.articleImageUrl != null &&
                          post.articleImageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: KBorderRadius.sm,
                          child: Image.network(
                            post.articleImageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: KAppColors.getPrimary(
                              context,
                            ).withValues(alpha: 0.14),
                            borderRadius: KBorderRadius.sm,
                          ),
                          child: Icon(
                            Icons.newspaper,
                            color: KAppColors.getPrimary(context),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              articleHost ?? 'Shared article',
                              style: KAppTextStyles.labelSmall.copyWith(
                                color: onBackground.withValues(alpha: 0.62),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _effectiveArticleTitle(post),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: KAppTextStyles.bodySmall.copyWith(
                                color: onBackground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        canOpenArticle ? Icons.chevron_right : Icons.link,
                        size: 18,
                        color: onBackground.withValues(alpha: 0.45),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Divider(height: 1, color: onBackground.withValues(alpha: 0.035)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPostActionButton(
                    icon: Icons.repeat,
                    color: onBackground.withValues(alpha: 0.72),
                    label:
                        'Share ${_engagementService.formatCount(post.shareCount)}',
                    onTap: null,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildPostActionButton(
                    icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked
                        ? Colors.redAccent
                        : onBackground.withValues(alpha: 0.72),
                    label:
                        'Like ${_engagementService.formatCount(post.likeCount)}',
                    onTap: () => _togglePostLike(post),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildPostActionButton(
                    icon: Icons.mode_comment_outlined,
                    color: onBackground.withValues(alpha: 0.72),
                    label:
                        'Comment ${_engagementService.formatCount(post.commentCount)}',
                    onTap: () => _commentOnPost(post),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostActionButton({
    required IconData icon,
    required Color color,
    required String label,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: KBorderRadius.sm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isEnabled ? 0.08 : 0.05),
          borderRadius: KBorderRadius.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: color.withValues(alpha: isEnabled ? 1 : 0.72),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KAppTextStyles.labelSmall.copyWith(
                  color: color.withValues(alpha: isEnabled ? 1 : 0.75),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedMiniCard(ActivityFeedItem activity) {
    return InkWell(
      onTap: () => _openSharedArticle(activity),
      borderRadius: KBorderRadius.md,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
          borderRadius: KBorderRadius.md,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
                borderRadius: KBorderRadius.sm,
              ),
              child:
                  activity.articleImageUrl != null &&
                      activity.articleImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: KBorderRadius.sm,
                      child: Image.network(
                        activity.articleImageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.newspaper,
                      color: KAppColors.getPrimary(context),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    activity.articleSourceName ?? 'Shared story',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.getOnBackground(
                        context,
                      ).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.articleTitle ?? 'Open article',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkPostMiniCard(SocialPost post) {
    final onBackground = KAppColors.getOnBackground(context);
    final heading = _effectivePostHeading(post);
    final hasBody = post.text.trim().isNotEmpty;
    final previewText = _effectiveArticleTitle(post);
    final hasPreview = _hasArticlePreview(post);
    return InkWell(
      onTap: _openPostsTab,
      borderRadius: KBorderRadius.md,
      child: Container(
        width: 262,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: onBackground.withValues(alpha: 0.045),
          borderRadius: KBorderRadius.md,
          border: Border.all(color: onBackground.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: KAppColors.getPrimary(
                    context,
                  ).withValues(alpha: 0.2),
                  backgroundImage:
                      post.userAvatarUrl != null &&
                          post.userAvatarUrl!.isNotEmpty
                      ? NetworkImage(post.userAvatarUrl!)
                      : null,
                  child:
                      post.userAvatarUrl == null || post.userAvatarUrl!.isEmpty
                      ? Text(
                          post.username.isNotEmpty
                              ? post.username.substring(0, 1).toUpperCase()
                              : 'R',
                          style: KAppTextStyles.labelSmall,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '@${post.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: onBackground.withValues(alpha: 0.76),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _getTimeAgo(post.createdAt),
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: onBackground.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heading.isNotEmpty) ...[
                  Text(
                    heading,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: onBackground,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ],
                if (hasBody) ...[
                  const SizedBox(height: 5),
                  Text(
                    post.text.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: onBackground.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                  ),
                ],
                if (hasPreview) ...[
                  const SizedBox(height: 6),
                  Text(
                    previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: onBackground.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: onBackground.withValues(alpha: 0.08),
                    borderRadius: KBorderRadius.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 14,
                        color: onBackground.withValues(alpha: 0.58),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _engagementService.formatCount(post.shareCount),
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: onBackground.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: onBackground.withValues(alpha: 0.08),
                    borderRadius: KBorderRadius.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: post.isLiked
                            ? Colors.redAccent
                            : onBackground.withValues(alpha: 0.58),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _engagementService.formatCount(post.likeCount),
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: onBackground.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: onBackground.withValues(alpha: 0.08),
                    borderRadius: KBorderRadius.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mode_comment_outlined,
                        size: 14,
                        color: onBackground.withValues(alpha: 0.58),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _engagementService.formatCount(post.commentCount),
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: onBackground.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkHighlightMiniCard(NetworkHighlight highlight) {
    final onBackground = KAppColors.getOnBackground(context);
    final sharersText = highlight.sharers.isEmpty
        ? 'From your network'
        : highlight.sharers.join(', ');
    return Container(
      width: 230,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onBackground.withValues(alpha: 0.04),
        borderRadius: KBorderRadius.md,
        border: Border.all(color: onBackground.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sharersText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KAppTextStyles.labelSmall.copyWith(
              color: onBackground.withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            highlight.articleTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KAppTextStyles.bodySmall.copyWith(
              color: onBackground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            highlight.articleSourceName ?? 'Source unavailable',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KAppTextStyles.labelSmall.copyWith(
              color: onBackground.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkHighlightListCard(NetworkHighlight highlight) {
    final onBackground = KAppColors.getOnBackground(context);
    final sharersText = highlight.sharers.isEmpty
        ? 'From your network'
        : highlight.sharers.join(', ');
    final isLiked = _isHighlightLiked(highlight);
    final likeCount = _getHighlightLikeCount(highlight);
    final commentCount = _getHighlightCommentCount(highlight);
    final canOpenArticle =
        highlight.articleId != null && highlight.articleId!.isNotEmpty;

    return Padding(
      padding: KDesignConstants.paddingHorizontalMd.copyWith(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: KBorderRadius.lg,
        child: InkWell(
          borderRadius: KBorderRadius.lg,
          onTap: canOpenArticle
              ? () => _openNetworkHighlightArticle(highlight)
              : null,
          child: Container(
            padding: KDesignConstants.paddingMd,
            decoration: BoxDecoration(
              borderRadius: KBorderRadius.lg,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  onBackground.withValues(alpha: 0.03),
                  onBackground.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(color: onBackground.withValues(alpha: 0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sharersText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: onBackground.withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                    if (canOpenArticle)
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: onBackground.withValues(alpha: 0.4),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (highlight.articleImageUrl != null &&
                        highlight.articleImageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: KBorderRadius.sm,
                        child: Image.network(
                          highlight.articleImageUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 64,
                        height: 72,
                        decoration: BoxDecoration(
                          color: KAppColors.getPrimary(
                            context,
                          ).withValues(alpha: 0.12),
                          borderRadius: KBorderRadius.sm,
                        ),
                        child: Icon(
                          Icons.newspaper,
                          color: KAppColors.getPrimary(context),
                        ),
                      ),
                    const SizedBox(width: KDesignConstants.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            highlight.articleSourceName ?? 'Source unavailable',
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: onBackground.withValues(alpha: 0.62),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            highlight.articleTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: KAppTextStyles.bodyMedium.copyWith(
                              color: onBackground,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          if (highlight.articleDescription != null &&
                              highlight.articleDescription!
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              highlight.articleDescription!,
                              style: KAppTextStyles.bodySmall.copyWith(
                                color: onBackground.withValues(alpha: 0.6),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildHighlightActionButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked
                          ? Colors.redAccent
                          : onBackground.withValues(alpha: 0.7),
                      label: _engagementService.formatCount(likeCount),
                      onTap: () => _toggleNetworkHighlightLike(highlight),
                    ),
                    const SizedBox(width: 8),
                    _buildHighlightActionButton(
                      icon: Icons.mode_comment_outlined,
                      color: onBackground.withValues(alpha: 0.7),
                      label: _engagementService.formatCount(commentCount),
                      onTap: () => _openNetworkHighlightComments(highlight),
                    ),
                    const SizedBox(width: 8),
                    _buildHighlightActionButton(
                      icon: Icons.repeat,
                      color: KAppColors.getPrimary(context),
                      label: _engagementService.formatCount(
                        highlight.shareCount,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: KBorderRadius.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: KAppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonMiniCard(UserProfile user) {
    final displayName = user.displayName.isNotEmpty
        ? user.displayName
        : user.username;
    final username = user.username.isNotEmpty ? '@${user.username}' : '@reader';
    final latestShareTitle = _latestSharedTitleForUser(user.userId);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileViewPage(
              currentUser: widget.user,
              profileUserId: user.userId,
            ),
          ),
        );
      },
      borderRadius: KBorderRadius.lg,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildUserAvatar(user, size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KAppTextStyles.bodyMedium.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.getOnBackground(
                            context,
                          ).withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (latestShareTitle != null && latestShareTitle.isNotEmpty)
              Text(
                'Recent share: $latestShareTitle',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(
                    context,
                  ).withValues(alpha: 0.78),
                ),
              )
            else
              Text(
                'Tap to view profile and recent activity',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(
                    context,
                  ).withValues(alpha: 0.7),
                ),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
                borderRadius: KBorderRadius.xl,
              ),
              child: Text(
                'Following',
                style: KAppTextStyles.labelSmall.copyWith(
                  color: KAppColors.getPrimary(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserProfile user, {double size = 40}) {
    final avatarUrl = (user.avatarUrl ?? '').trim();
    final hasAvatar = avatarUrl.isNotEmpty && avatarUrl.startsWith('http');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? Image.network(avatarUrl, fit: BoxFit.cover)
          : Icon(
              Icons.person,
              size: size * 0.55,
              color: KAppColors.getPrimary(context),
            ),
    );
  }

  List<ActivityFeedItem> _filteredFeedItems() {
    List<ActivityFeedItem> items;
    if (_activeFeedFilter == 0) {
      items = _recentActivity;
    } else if (_activeFeedFilter == 1) {
      items = _recentActivity
          .where(
            (a) =>
                a.activityType == ActivityType.createList ||
                a.activityType == ActivityType.updateList ||
                a.activityType == ActivityType.addToList ||
                a.activityType == ActivityType.shareList,
          )
          .toList();
    } else if (_activeFeedFilter == 2) {
      items = _recentActivity
          .where((a) => a.activityType == ActivityType.shareArticle)
          .toList();
    } else {
      items = _recentActivity;
    }

    if (_mindfulMode && items.length > _mindfulFeedLimit) {
      return items.take(_mindfulFeedLimit).toList();
    }
    return items;
  }

  Widget _buildTopicChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: KAppTextStyles.bodySmall.copyWith(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildWellbeingCard() {
    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context).withValues(alpha: 0.08),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KAppColors.getPrimary(context).withValues(alpha: 0.15),
              borderRadius: KBorderRadius.md,
            ),
            child: Icon(
              Icons.self_improvement,
              color: KAppColors.getPrimary(context),
              size: 24,
            ),
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pause and breathe',
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Take 10 seconds before you keep scrolling.',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(
                      context,
                    ).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _latestSharedTitleForUser(String userId) {
    for (final activity in _recentActivity) {
      if (activity.userId == userId &&
          activity.activityType == ActivityType.shareArticle &&
          (activity.articleTitle?.isNotEmpty ?? false)) {
        return activity.articleTitle;
      }
    }
    return null;
  }

  Widget _buildPublisherCard(String publisherName) {
    final currentUserId = _currentProfile?.userId;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.public,
                  color: KAppColors.getPrimary(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publisherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Following',
                      style: KAppTextStyles.labelSmall.copyWith(
                        color: KAppColors.getPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'See the latest stories from this source.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KAppTextStyles.bodySmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublisherProfilePage(
                          publisherName: publisherName,
                          user: widget.user,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    side: BorderSide(
                      color: KAppColors.getPrimary(
                        context,
                      ).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text('Latest'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Unfollow',
                onPressed: currentUserId == null
                    ? null
                    : () => _unfollowPublisherFromHub(publisherName),
                icon: Icon(
                  Icons.person_remove_outlined,
                  color: KAppColors.getOnBackground(
                    context,
                  ).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
