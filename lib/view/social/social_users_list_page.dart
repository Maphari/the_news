import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/utils/image_utils.dart';
import 'package:the_news/view/social/user_profile_view_page.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';

enum SocialUsersListMode { following, recommended }

class SocialUsersListPage extends StatefulWidget {
  const SocialUsersListPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentUser,
    required this.sourceUserId,
    required this.mode,
  });

  final String title;
  final String subtitle;
  final RegisterLoginUserSuccessModel currentUser;
  final String sourceUserId;
  final SocialUsersListMode mode;

  @override
  State<SocialUsersListPage> createState() => _SocialUsersListPageState();
}

class _SocialUsersListPageState extends State<SocialUsersListPage> {
  static const int _pageSize = 20;

  final SocialFeaturesBackendService _socialService =
      SocialFeaturesBackendService.instance;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _processingUserIds = <String>{};

  List<UserProfile> _users = [];
  String? _nextCursor;
  bool _hasMore = true;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  bool get _allowFollowAction => widget.mode == SocialUsersListMode.recommended;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refreshList();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isInitialLoading) return;
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  Future<void> _refreshList() async {
    setState(() {
      _users = [];
      _nextCursor = null;
      _hasMore = true;
      _isInitialLoading = true;
      _error = null;
    });
    await _loadMore();
    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final page = widget.mode == SocialUsersListMode.following
          ? await _socialService.getFollowingPaginated(
              widget.sourceUserId,
              limit: _pageSize,
              cursor: _nextCursor,
            )
          : await _socialService.getRecommendedUsersPaginated(
              widget.sourceUserId,
              limit: _pageSize,
              cursor: _nextCursor,
            );

      if (!mounted) return;

      final existingIds = _users.map((u) => u.userId).toSet();
      final newUsers = page.users
          .where((u) => !existingIds.contains(u.userId))
          .toList();

      setState(() {
        _users = [..._users, ...newUsers];
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore && page.nextCursor != null;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _followUser(String userId) async {
    if (_processingUserIds.contains(userId)) return;
    setState(() => _processingUserIds.add(userId));

    try {
      await _socialService.followUser(userId);
      if (!mounted) return;
      setState(() => _users.removeWhere((u) => u.userId == userId));

      if (_users.length < _pageSize && _hasMore) {
        await _loadMore();
      }
    } finally {
      if (mounted) {
        setState(() => _processingUserIds.remove(userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = KAppColors.getBackground(context);
    final onBackground = KAppColors.getOnBackground(context);

    return Scaffold(
      backgroundColor: background,
      appBar: KAppBar(
        title: Text(
          widget.title,
          style: KAppTextStyles.titleLarge.copyWith(
            color: onBackground,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: background,
        elevation: 0,
        leading: AppBackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Padding(
            padding: KDesignConstants.paddingHorizontalMd,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.subtitle,
                style: KAppTextStyles.bodySmall.copyWith(
                  color: onBackground.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Could not load users',
                          style: KAppTextStyles.bodyMedium.copyWith(
                            color: onBackground.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: KDesignConstants.spacing8),
                        FilledButton(
                          onPressed: _refreshList,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshList,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: KDesignConstants.paddingMd,
                      itemCount: _users.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _users.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final user = _users[index];
                        final isCurrentUser =
                            user.userId == widget.currentUser.userId;
                        final isProcessing = _processingUserIds.contains(
                          user.userId,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: KDesignConstants.spacing10,
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileViewPage(
                                    currentUser: widget.currentUser,
                                    profileUserId: user.userId,
                                  ),
                                ),
                              );
                            },
                            borderRadius: KBorderRadius.lg,
                            child: Container(
                              padding: KDesignConstants.paddingMd,
                              decoration: BoxDecoration(
                                color: onBackground.withValues(alpha: 0.04),
                                borderRadius: KBorderRadius.lg,
                                border: Border.all(
                                  color: onBackground.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: KAppColors.getPrimary(
                                      context,
                                    ).withValues(alpha: 0.16),
                                    backgroundImage: resolveImageProvider(
                                      user.avatarUrl,
                                    ),
                                    child:
                                        (user.avatarUrl == null ||
                                            user.avatarUrl!.isEmpty)
                                        ? Icon(
                                            Icons.person,
                                            color: KAppColors.getPrimary(
                                              context,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(
                                    width: KDesignConstants.spacing12,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName.isNotEmpty
                                              ? user.displayName
                                              : user.username,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: KAppTextStyles.bodyMedium
                                              .copyWith(
                                                color: onBackground,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '@${user.username}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: KAppTextStyles.labelSmall
                                              .copyWith(
                                                color: onBackground.withValues(
                                                  alpha: 0.64,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_allowFollowAction && !isCurrentUser)
                                    FilledButton(
                                      onPressed: isProcessing
                                          ? null
                                          : () => _followUser(user.userId),
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size(88, 40),
                                      ),
                                      child: Text(
                                        isProcessing ? '...' : 'Follow',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
