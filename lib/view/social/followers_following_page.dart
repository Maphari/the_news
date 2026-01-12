import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/view/social/user_profile_view_page.dart';

enum FollowListType { followers, following }

class FollowersFollowingPage extends StatefulWidget {
  const FollowersFollowingPage({
    super.key,
    required this.currentUser,
    required this.userId,
    required this.listType,
  });

  final RegisterLoginUserSuccessModel currentUser;
  final String userId;
  final FollowListType listType;

  @override
  State<FollowersFollowingPage> createState() => _FollowersFollowingPageState();
}

class _FollowersFollowingPageState extends State<FollowersFollowingPage> {
  final SocialFeaturesBackendService _socialService = SocialFeaturesBackendService.instance;

  List<UserProfile> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = widget.listType == FollowListType.followers
          ? await _socialService.getFollowers(widget.userId)
          : await _socialService.getFollowing(widget.userId);

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.listType == FollowListType.followers ? 'Followers' : 'Following';

    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: KAppColors.getOnBackground(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: KAppTextStyles.headlineSmall.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _users.isEmpty
                  ? _buildEmptyState(title)
                  : _buildUsersList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(KAppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading users',
              style: KAppTextStyles.headlineSmall.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: KAppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No $title',
              style: KAppTextStyles.headlineMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.listType == FollowListType.followers
                  ? 'Nobody is following this user yet'
                  : 'This user is not following anyone yet',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: KAppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final isCurrentUser = user.userId == widget.currentUser.userId;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: KAppColors.secondary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: KAppColors.primary.withValues(alpha: 0.2),
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                        style: KAppTextStyles.headlineSmall.copyWith(
                          color: KAppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(
                user.displayName,
                style: KAppTextStyles.bodyLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                    ),
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio!,
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing: isCurrentUser
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: KAppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'You',
                        style: TextStyle(
                          color: KAppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                    ),
              onTap: isCurrentUser
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileViewPage(
                            currentUser: widget.currentUser,
                            profileUserId: user.userId,
                          ),
                        ),
                      );
                    },
            ),
          );
        },
      ),
    );
  }
}
