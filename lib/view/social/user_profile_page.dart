import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/model/reading_list_model.dart';
import 'package:the_news/model/activity_feed_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final SocialFeaturesBackendService _socialService = SocialFeaturesBackendService.instance;
  final AuthService _authService = AuthService();

  UserProfile? _userProfile;
  List<ReadingList> _userLists = [];
  List<ActivityFeedItem> _userActivity = [];
  List<UserProfile> _followers = [];
  List<UserProfile> _following = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if viewing current user's profile
      final currentUser = await _authService.getCurrentUser();
      final currentUserId = currentUser?['id'] as String?;
      _isCurrentUser = currentUserId == widget.userId;

      // Load user profile
      final profile = await _socialService.getUserProfile(widget.userId);

      if (profile != null) {
        // Load user's data
        final lists = await _socialService.getUserReadingLists(widget.userId);
        final followers = await _socialService.getFollowers(widget.userId);
        final following = await _socialService.getFollowing(widget.userId);

        // Load activity feed
        final allActivity = await _socialService.getActivityFeed(limit: 50);
        final userActivity = allActivity.where((a) => a.userId == widget.userId).take(10).toList();

        // Check follow status
        bool isFollowing = false;
        if (!_isCurrentUser && currentUserId != null) {
          isFollowing = await _socialService.isFollowing(widget.userId);
        }

        if (mounted) {
          setState(() {
            _userProfile = profile;
            _userLists = lists.where((l) => l.isPublic || _isCurrentUser).toList();
            _followers = followers;
            _following = following;
            _userActivity = userActivity;
            _isFollowing = isFollowing;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    try {
      if (_isFollowing) {
        await _socialService.unfollowUser(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unfollowed @${_userProfile?.username ?? 'user'}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await _socialService.followUser(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Following @${_userProfile?.username ?? 'user'}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      // Reload data to update counts
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color screenBackgroundColor = KAppColors.getBackground(context);

    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: screenBackgroundColor,
      child: Scaffold(
        backgroundColor: screenBackgroundColor,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _userProfile == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'User not found',
                          style: KAppTextStyles.titleLarge.copyWith(
                            color: KAppColors.getOnBackground(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // App Bar
                      SliverAppBar(
                        expandedHeight: 200,
                        floating: true,
                        snap: true,
                        backgroundColor: KAppColors.getPrimary(context),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  KAppColors.getPrimary(context),
                                  KAppColors.getPrimary(context).withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                            child: SafeArea(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 40),
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 47,
                                      backgroundColor: KAppColors.getPrimary(context).withValues(alpha: 0.8),
                                      child: Text(
                                        _userProfile!.displayName.substring(0, 1).toUpperCase(),
                                        style: KAppTextStyles.displaySmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Profile Info
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                _userProfile!.displayName,
                                style: KAppTextStyles.headlineSmall.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${_userProfile!.username}',
                                style: KAppTextStyles.bodyMedium.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                ),
                              ),
                              if (_userProfile!.bio != null && _userProfile!.bio!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _userProfile!.bio!,
                                  style: KAppTextStyles.bodyMedium.copyWith(
                                    color: KAppColors.getOnBackground(context),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Joined ${_formatDate(_userProfile!.joinedDate)}',
                                    style: KAppTextStyles.bodySmall.copyWith(
                                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Stats Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn(
                                    '${_userProfile!.articlesReadCount}',
                                    'Articles',
                                  ),
                                  _buildStatColumn(
                                    '${_followers.length}',
                                    'Followers',
                                  ),
                                  _buildStatColumn(
                                    '${_following.length}',
                                    'Following',
                                  ),
                                  _buildStatColumn(
                                    '${_userLists.length}',
                                    'Lists',
                                  ),
                                ],
                              ),

                              // Follow Button
                              if (!_isCurrentUser) ...[
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _toggleFollow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isFollowing
                                          ? KAppColors.getOnBackground(context).withValues(alpha: 0.1)
                                          : KAppColors.getPrimary(context),
                                      foregroundColor: _isFollowing
                                          ? KAppColors.getOnBackground(context)
                                          : Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: _isFollowing
                                            ? BorderSide(
                                                color: KAppColors.getOnBackground(context)
                                                    .withValues(alpha: 0.2),
                                              )
                                            : BorderSide.none,
                                      ),
                                      elevation: _isFollowing ? 0 : 2,
                                    ),
                                    child: Text(
                                      _isFollowing ? 'Following' : 'Follow',
                                      style: KAppTextStyles.titleSmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Reading Lists Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Text(
                            'Reading Lists',
                            style: KAppTextStyles.titleSmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      if (_userLists.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No public reading lists',
                                style: KAppTextStyles.bodyMedium.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildListTile(_userLists[index]),
                            childCount: _userLists.length,
                          ),
                        ),

                      // Recent Activity Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Text(
                            'Recent Activity',
                            style: KAppTextStyles.titleSmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      if (_userActivity.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No recent activity',
                                style: KAppTextStyles.bodyMedium.copyWith(
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildActivityItem(_userActivity[index]),
                            childCount: _userActivity.length,
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: KAppTextStyles.titleLarge.copyWith(
            color: KAppColors.getPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: KAppTextStyles.labelSmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(ReadingList list) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
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
            const SizedBox(width: 12),
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
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (list.isPublic)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Public',
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: KAppColors.getPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(ActivityFeedItem activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _getActivityIcon(activity.activityType),
              color: _getActivityColor(activity.activityType),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getActivityText(activity),
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getTimeAgo(activity.timestamp),
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
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
      case ActivityType.commentArticle:
        return 'Commented on an article';
      case ActivityType.likeArticle:
        return 'Liked an article';
    }
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
