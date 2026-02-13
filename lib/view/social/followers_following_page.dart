import 'package:flutter/material.dart';
import 'package:the_news/view/social/user_profile_page.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/utils/image_utils.dart';
import 'package:the_news/view/widgets/app_back_button.dart';

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
      appBar: KAppBar(
        title: Text(
          title,
          style: KAppTextStyles.headlineSmall.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: AppBackButton(onPressed: () => Navigator.pop(context),),
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
            valueColor: AlwaysStoppedAnimation(KAppColors.getPrimary(context)),
          ),
          const SizedBox(height: KDesignConstants.spacing16),
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
        padding: KDesignConstants.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: KDesignConstants.spacing16),
            Text(
              'Error loading users',
              style: KAppTextStyles.headlineSmall.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing24),
            ElevatedButton(
              onPressed: _loadUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: KAppColors.getPrimary(context),
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: KDesignConstants.spacing32,
                  vertical: KDesignConstants.spacing12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: KBorderRadius.md,
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
        padding: KDesignConstants.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: KDesignConstants.spacing16),
            Text(
              'No $title',
              style: KAppTextStyles.headlineMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing8),
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
      color: KAppColors.getPrimary(context),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: KDesignConstants.spacing16,
          vertical: KDesignConstants.spacing8,
        ),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final isCurrentUser = user.userId == widget.currentUser.userId;

          return Card(
            margin: const EdgeInsets.only(bottom: KDesignConstants.spacing12),
            color: KAppColors.getSurface(context),
            shape: RoundedRectangleBorder(
              borderRadius: KBorderRadius.md,
              side: BorderSide(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: KDesignConstants.spacing16,
                vertical: KDesignConstants.spacing8,
              ),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                backgroundImage: resolveImageProvider(user.avatarUrl),
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                        style: KAppTextStyles.headlineSmall.copyWith(
                          color: KAppColors.getPrimary(context),
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
                  const SizedBox(height: KDesignConstants.spacing4),
                  Text(
                    '@${user.username}',
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                    ),
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: KDesignConstants.spacing4),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: KDesignConstants.spacing12,
                        vertical: KDesignConstants.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                        borderRadius: KBorderRadius.sm,
                      ),
                      child: Text(
                        'You',
                        style: TextStyle(
                          color: KAppColors.getPrimary(context),
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
                          builder: (context) => UserProfilePage(
                            userId: user.userId,
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
