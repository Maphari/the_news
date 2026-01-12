import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/social/user_profile_page.dart';

class SearchUsersPage extends StatefulWidget {
  const SearchUsersPage({super.key});

  @override
  State<SearchUsersPage> createState() => _SearchUsersPageState();
}

class _SearchUsersPageState extends State<SearchUsersPage> {
  final SocialFeaturesBackendService _socialService = SocialFeaturesBackendService.instance;
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<UserProfile> _searchResults = [];
  List<UserProfile> _allUsers = [];
  String? _currentUserId;
  bool _isLoading = false;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final userData = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUserId = userData?['id'] as String?;
      });
    }
  }

  Future<void> _loadAllUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Search with empty query to get all users
      final users = await _socialService.searchUsers('');

      // Filter out current user
      final filteredUsers = users.where((u) => u.userId != _currentUserId).toList();

      if (mounted) {
        setState(() {
          _allUsers = filteredUsers;
          _searchResults = filteredUsers;
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = _allUsers;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _socialService.searchUsers(query);

      // Filter out current user
      final filteredUsers = users.where((u) => u.userId != _currentUserId).toList();

      if (mounted) {
        setState(() {
          _searchResults = filteredUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching users: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleFollow(UserProfile user) async {
    try {
      final isFollowing = await _socialService.isFollowing(user.userId);

      if (isFollowing) {
        await _socialService.unfollowUser(user.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unfollowed @${user.username}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await _socialService.followUser(user.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Following @${user.username}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      // Refresh the list to update follow status
      setState(() {});
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
        appBar: AppBar(
          backgroundColor: screenBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: KAppColors.getOnBackground(context),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Find Users',
            style: KAppTextStyles.titleLarge.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _searchUsers,
                decoration: InputDecoration(
                  hintText: 'Search by username or name...',
                  hintStyle: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: KAppColors.getPrimary(context),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _searchUsers('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: KAppColors.getPrimary(context),
                      width: 2,
                    ),
                  ),
                ),
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                ),
              ),
            ),

            // Results
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isLoading && _searchController.text.isNotEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No users found'
                  : 'No results for "${_searchController.text}"',
              style: KAppTextStyles.bodyLarge.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Users you follow will appear here'
                  : 'Try a different search term',
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return FutureBuilder<bool>(
      future: _socialService.isFollowing(user.userId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(userId: user.userId),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: KAppColors.getPrimary(context),
                    child: Text(
                      user.displayName.substring(0, 1).toUpperCase(),
                      style: KAppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user.username}',
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          ),
                        ),
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.bio!,
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user.followersCount} followers',
                              style: KAppTextStyles.labelSmall.copyWith(
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.article,
                              size: 14,
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user.articlesReadCount} articles',
                              style: KAppTextStyles.labelSmall.copyWith(
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Follow Button
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _toggleFollow(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing
                          ? KAppColors.getOnBackground(context).withValues(alpha: 0.1)
                          : KAppColors.getPrimary(context),
                      foregroundColor: isFollowing
                          ? KAppColors.getOnBackground(context)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: isFollowing
                            ? BorderSide(
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                              )
                            : BorderSide.none,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: KAppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
