import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/view/social/user_profile_view_page.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key, required this.currentUser});

  final RegisterLoginUserSuccessModel currentUser;

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final SocialFeaturesBackendService _socialService = SocialFeaturesBackendService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

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
      appBar: AppBar(
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
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by username or name...',
                prefixIcon: Icon(
                  Icons.search,
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: KAppColors.secondary.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: KAppColors.primary, width: 2),
                ),
              ),
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
            valueColor: AlwaysStoppedAnimation(KAppColors.primary),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Text(
            'Find Friends',
            style: KAppTextStyles.headlineMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
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
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: KAppTextStyles.headlineMedium.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
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
    );
  }
}
