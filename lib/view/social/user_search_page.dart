import 'package:flutter/material.dart';
import 'package:the_news/view/social/user_profile_page.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/utils/image_utils.dart';
import 'package:the_news/view/widgets/app_search_bar.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key, required this.currentUser});

  final RegisterLoginUserSuccessModel currentUser;

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final SocialFeaturesBackendService _socialService = SocialFeaturesBackendService.instance;
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();

  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final currentUser = await _authService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _currentUserId = currentUser?['id'] as String? ?? currentUser?['userId'] as String?;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = await _socialService.searchUsers(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: KAppBar(
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        title: Text(
          'Search Users',
          style: KAppTextStyles.headlineSmall.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: KDesignConstants.paddingMd,
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Search by username or name...',
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
            ),
          ),

          // Results
          Expanded(
            child: _isSearching
                ? _buildLoadingState()
                : !_hasSearched
                    ? _buildInitialState()
                    : _searchResults.isEmpty
                        ? _buildEmptyState()
                        : _buildResultsList(),
          ),
        ],
      ),
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
            'Searching...',
            style: KAppTextStyles.bodyMedium.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
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
            'Find Friends',
            style: KAppTextStyles.headlineMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing48),
            child: Text(
              'Search for users by username or display name to connect with them',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: KDesignConstants.spacing16),
          Text(
            'No users found',
            style: KAppTextStyles.headlineMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing48),
            child: Text(
              'Try a different search term',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: KDesignConstants.paddingHorizontalMd,
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final currentUserId = _currentUserId ?? widget.currentUser.userId;
        final isCurrentUser = user.userId == currentUserId;

        return Card(
          margin: const EdgeInsets.only(bottom: KDesignConstants.spacing12),
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: KBorderRadius.md,
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
    );
  }
}
