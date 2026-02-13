import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/view/publisher/publisher_profile_page.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';

class FollowedPublishersListPage extends StatefulWidget {
  const FollowedPublishersListPage({
    super.key,
    required this.userId,
    required this.currentUser,
  });

  final String userId;
  final RegisterLoginUserSuccessModel currentUser;

  @override
  State<FollowedPublishersListPage> createState() =>
      _FollowedPublishersListPageState();
}

class _FollowedPublishersListPageState
    extends State<FollowedPublishersListPage> {
  static const int _pageSize = 20;
  final FollowedPublishersService _service = FollowedPublishersService.instance;
  final ScrollController _scrollController = ScrollController();

  List<String> _publishers = [];
  String? _nextCursor;
  bool _hasMore = true;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  bool get _canManageFollows => widget.userId == widget.currentUser.userId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _publishers = [];
      _nextCursor = null;
      _hasMore = true;
      _error = null;
      _isInitialLoading = true;
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
      final page = await _service.getFollowedPublishersPaginated(
        widget.userId,
        limit: _pageSize,
        cursor: _nextCursor,
      );
      if (!mounted) return;
      final existing = _publishers.toSet();
      final nextItems = page.publishers
          .where((p) => !existing.contains(p))
          .toList();
      setState(() {
        _publishers = [..._publishers, ...nextItems];
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

  Future<void> _unfollowPublisher(String publisherName) async {
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

    final success = await _service.unfollowPublisher(widget.userId, publisherName);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to unfollow publisher')),
      );
      return;
    }
    setState(() {
      _publishers.remove(publisherName);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unfollowed $publisherName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onBackground = KAppColors.getOnBackground(context);
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: KAppBar(
        title: Text(
          'Followed Publishers',
          style: KAppTextStyles.titleLarge.copyWith(
            color: onBackground,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: AppBackButton(onPressed: () => Navigator.pop(context)),
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _publishers.isEmpty
          ? Center(
              child: FilledButton(
                onPressed: _refresh,
                child: const Text('Retry'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: KDesignConstants.paddingMd,
                itemCount: _publishers.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _publishers.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final publisherName = _publishers[index];
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: KDesignConstants.spacing10,
                    ),
                    child: InkWell(
                      borderRadius: KBorderRadius.lg,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublisherProfilePage(
                              publisherName: publisherName,
                              user: widget.currentUser,
                            ),
                          ),
                        );
                      },
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: KAppColors.getPrimary(
                                  context,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.public,
                                color: KAppColors.getPrimary(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                publisherName,
                                style: KAppTextStyles.bodyMedium.copyWith(
                                  color: onBackground,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (_canManageFollows)
                              IconButton(
                                tooltip: 'Unfollow',
                                onPressed: () => _unfollowPublisher(publisherName),
                                icon: Icon(
                                  Icons.person_remove_outlined,
                                  color: onBackground.withValues(alpha: 0.65),
                                ),
                              ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: onBackground.withValues(alpha: 0.45),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
