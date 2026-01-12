import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/model/reading_list_model.dart';
import 'package:the_news/model/activity_feed_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';
import 'package:the_news/view/social/reading_lists_page.dart';
import 'package:the_news/view/social/user_search_page.dart';
import 'package:the_news/view/social/social_profile_page.dart';
import 'package:the_news/view/social/followers_following_page.dart';
import 'package:the_news/view/social/user_profile_view_page.dart';

class SocialHubPage extends StatefulWidget {
  const SocialHubPage({super.key, required this.user});

   final RegisterLoginUserSuccessModel user;

  @override
  State<SocialHubPage> createState() => _SocialHubPageState();
}

class _SocialHubPageState extends State<SocialHubPage> {
  final SocialFeaturesBackendService _socialService = SocialFeaturesBackendService.instance;

  UserProfile? _currentProfile;
  List<ReadingList> _recentLists = [];
  List<ActivityFeedItem> _recentActivity = [];
  List<UserProfile> _followers = [];
  List<UserProfile> _following = [];
  bool _isLoading = true;

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
      // Get or create user profile
      final profile = await _getOrCreateProfile();

      if (profile != null) {
        final lists = await _socialService.getUserReadingLists(profile.userId);
        final activity = await _socialService.getActivityFeed(limit: 10);
        final followers = await _socialService.getFollowers(profile.userId);
        final following = await _socialService.getFollowing(profile.userId);

        if (mounted) {
          setState(() {
            _currentProfile = profile;
            _recentLists = lists.take(3).toList();
            _recentActivity = activity.where((a) => a.userId == profile.userId).take(5).toList();
            _followers = followers;
            _following = following;
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

  Future<UserProfile?> _getOrCreateProfile() async {
    // Try to get existing profile
    UserProfile? profile = await _socialService.getCurrentUserProfile();

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

      final userId = userData['id'] as String;
      final email = userData['email'] as String? ?? '';
      final name = userData['name'] as String? ?? email.split('@').first;

      // Create new profile
      final newProfile = UserProfile(
        userId: userId,
        username: name.toLowerCase().replaceAll(' ', '_'),
        displayName: name,
        bio: 'News enthusiast',
        avatarUrl: userData['photoURL'] as String?,
        joinedDate: DateTime.now(),
        followersCount: 0,
        followingCount: 0,
        articlesReadCount: 0,
        collectionsCount: 0,
        stats: const {
          'articlesRead': 0,
          'listsCreated': 0,
          'listsShared': 0,
        },
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

    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: screenBackgroundColor,
      child: Scaffold(
        backgroundColor: screenBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: KAppColors.getPrimary(context),
            child: CustomScrollView(
              slivers: [
                // Header
                const SliverToBoxAdapter(
                  child: HomeHeader(
                    title: 'Social',
                    subtitle: 'Connect with readers and share collections',
                    showActions: false,
                  ),
                ),

                if (_isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else ...[
                // Profile Stats
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            KAppColors.getPrimary(context).withValues(alpha: 0.1),
                            KAppColors.getPrimary(context).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: KAppColors.getPrimary(context),
                                child: Text(
                                  _currentProfile?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                                  style: KAppTextStyles.headlineMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentProfile?.displayName ?? 'User',
                                      style: KAppTextStyles.titleLarge.copyWith(
                                        color: KAppColors.getOnBackground(context),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '@${_currentProfile?.username ?? 'username'}',
                                      style: KAppTextStyles.bodyMedium.copyWith(
                                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SocialProfilePage(user: widget.user),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.arrow_forward_ios,
                                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn(
                                '${_currentProfile?.articlesReadCount ?? 0}',
                                'Articles Read',
                                onTap: null,
                              ),
                              _buildStatColumn(
                                '${_followers.length}',
                                'Followers',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FollowersFollowingPage(
                                        currentUser: widget.user,
                                        userId: widget.user.userId,
                                        listType: FollowListType.followers,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildStatColumn(
                                '${_following.length}',
                                'Following',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FollowersFollowingPage(
                                        currentUser: widget.user,
                                        userId: widget.user.userId,
                                        listType: FollowListType.following,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildStatColumn(
                                '${_currentProfile?.collectionsCount ?? 0}',
                                'Lists',
                                onTap: null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: KAppTextStyles.titleSmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.library_books,
                                label: 'Reading Lists',
                                color: KAppColors.blue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ReadingListsPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.people,
                                label: 'Find Users',
                                color: KAppColors.green,
                                onTap: _showSearchUsers,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Recent Lists
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Reading Lists',
                          style: KAppTextStyles.titleSmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReadingListsPage(),
                              ),
                            );
                          },
                          child: Text('View All'),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_recentLists.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No reading lists yet. Create your first one!',
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
                      (context, index) => _buildListTile(_recentLists[index]),
                      childCount: _recentLists.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Recent Activity
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                if (_recentActivity.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No activity yet. Start reading and creating lists!',
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
                      (context, index) => _buildActivityItem(_recentActivity[index]),
                      childCount: _recentActivity.length,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, {VoidCallback? onTap}) {
    final column = Column(
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

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: column,
        ),
      );
    }

    return column;
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
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

  void _showSearchUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserSearchPage(currentUser: widget.user),
      ),
    );
  }

  void _showFollowersList(BuildContext context, List<UserProfile> users, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KAppColors.getBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            if (users.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No $title yet',
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
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
                          style: const TextStyle(
                            color: Colors.white,
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
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
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
                        );
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
}
