import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/view/widgets/show_message_widget.dart';

class UserProfileViewPage extends StatefulWidget {
  const UserProfileViewPage({
    super.key,
    required this.currentUser,
    required this.profileUserId,
  });

  final RegisterLoginUserSuccessModel currentUser;
  final String profileUserId;

  @override
  State<UserProfileViewPage> createState() => _UserProfileViewPageState();
}

class _UserProfileViewPageState extends State<UserProfileViewPage> {
  final SocialFeaturesBackendService _socialService = SocialFeaturesBackendService.instance;

  UserProfile? _profile;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _socialService.getUserProfile(widget.profileUserId);
      final following = await _socialService.isFollowing(widget.profileUserId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isFollowing = following;
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

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;

    setState(() => _isFollowLoading = true);

    try {
      if (_isFollowing) {
        await _socialService.unfollowUser(widget.profileUserId);
        if (mounted) {
          successMessage(context: context, message: 'Unfollowed ${_profile?.displayName}');
        }
      } else {
        await _socialService.followUser(widget.profileUserId);
        if (mounted) {
          successMessage(context: context, message: 'Following ${_profile?.displayName}');
        }
      }

      // Reload profile to get updated follower count
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        errorMessage(context: context, message: 'Failed to update follow status');
      }
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: _profile != null
            ? Text(
                '@${_profile!.username}',
                style: KAppTextStyles.bodyLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _profile == null
                  ? _buildNoProfileState()
                  : _buildProfileContent(),
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
            'Loading profile...',
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
              'Error loading profile',
              style: KAppTextStyles.headlineSmall.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfile,
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

  Widget _buildNoProfileState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile not found',
              style: KAppTextStyles.headlineSmall.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final profile = _profile!;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: KAppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Cover Image
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    KAppColors.primary.withValues(alpha: 0.3),
                    KAppColors.primary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Profile Section
            Transform.translate(
              offset: const Offset(0, -50),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: KAppColors.getBackground(context),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: KAppColors.primary.withValues(alpha: 0.2),
                      backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                          ? Text(
                              profile.displayName.isNotEmpty
                                  ? profile.displayName[0].toUpperCase()
                                  : 'U',
                              style: KAppTextStyles.displaySmall.copyWith(
                                color: KAppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Display Name
                  Text(
                    profile.displayName,
                    style: KAppTextStyles.headlineMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Username
                  Text(
                    '@${profile.username}',
                    style: KAppTextStyles.bodyLarge.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bio
                  if (profile.bio != null && profile.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        profile.bio!,
                        style: KAppTextStyles.bodyMedium.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Articles',
                          profile.articlesReadCount.toString(),
                        ),
                        _buildStatItem(
                          'Followers',
                          profile.followersCount.toString(),
                        ),
                        _buildStatItem(
                          'Following',
                          profile.followingCount.toString(),
                        ),
                        _buildStatItem(
                          'Lists',
                          profile.collectionsCount.toString(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Follow/Unfollow Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isFollowLoading ? null : _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing
                              ? KAppColors.secondary
                              : KAppColors.primary,
                          foregroundColor: _isFollowing
                              ? KAppColors.getOnBackground(context)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: _isFollowing
                                ? BorderSide(
                                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        child: _isFollowLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    _isFollowing
                                        ? KAppColors.getOnBackground(context)
                                        : Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _isFollowing ? 'Following' : 'Follow',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Joined Date
                  Text(
                    'Joined ${_formatDate(profile.joinedDate)}',
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: KAppTextStyles.headlineSmall.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: KAppTextStyles.bodySmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
