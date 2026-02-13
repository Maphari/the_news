import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/reading_list_model.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/service/app_rating_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';
import 'package:the_news/view/social/reading_list_detail_page.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/widgets/pill_tab.dart';

class ReadingListsPage extends StatefulWidget {
  const ReadingListsPage({super.key});

  @override
  State<ReadingListsPage> createState() => _ReadingListsPageState();
}

class _ReadingListsPageState extends State<ReadingListsPage> with SingleTickerProviderStateMixin {
  final SocialFeaturesBackendService _socialService = SocialFeaturesBackendService.instance;
  late TabController _tabController;
  final TextEditingController _discoverSearchController = TextEditingController();
  String _discoverQuery = '';
  String? _selectedDiscoverTag;
  String? _discoverCursor;
  bool _discoverHasMore = false;
  bool _isLoadingDiscoverMore = false;
  String? _currentUserId;
  List<String> _discoverTags = [];

  List<ReadingList> _myLists = [];
  List<ReadingList> _publicLists = [];
  List<ReadingList> _collaborativeLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 1 && _publicLists.isEmpty) {
        _loadDiscover(reset: true);
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _discoverSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _socialService.getCurrentUserProfile();
      _currentUserId = profile?.userId;

      final myLists = await _socialService.getUserReadingLists(profile?.userId ?? '');
      final collaborativeLists = myLists.where((list) => list.isCollaborative && !list.isOwner(profile?.userId ?? '')).toList();

      setState(() {
        _myLists = myLists.where((list) => list.isOwner(profile?.userId ?? '')).toList();
        _collaborativeLists = collaborativeLists;
        _isLoading = false;
      });

      await _loadDiscover(reset: true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDiscover({required bool reset}) async {
    if (reset) {
      setState(() {
        _discoverCursor = null;
      });
    } else if (_isLoadingDiscoverMore || !_discoverHasMore) {
      return;
    }

    setState(() {
      _isLoadingDiscoverMore = true;
    });

    try {
      final page = await _socialService.getPublicReadingListsPaginated(
        limit: 20,
        cursor: reset ? null : _discoverCursor,
        query: _discoverQuery,
        tag: _selectedDiscoverTag,
      );

      final merged = reset ? page.lists : [..._publicLists, ...page.lists];
      final tags = <String>{};
      for (final list in merged) {
        for (final tag in list.tags) {
          final clean = tag.trim();
          if (clean.isNotEmpty) tags.add(clean);
        }
      }

      if (!mounted) return;
      setState(() {
        _publicLists = merged;
        _discoverCursor = page.nextCursor;
        _discoverHasMore = page.hasMore;
        _discoverTags = tags.take(8).toList();
        _isLoadingDiscoverMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingDiscoverMore = false;
      });
    }
  }

  Future<void> _inviteCollaborator(ReadingList list) async {
    final ownerId = _currentUserId;
    if (ownerId == null || ownerId.isEmpty || !list.isOwner(ownerId)) return;

    final candidates = await _socialService.getFollowing(ownerId);
    if (!mounted) return;

    final selected = await showDialog<UserProfile>(
      context: context,
      builder: (context) => _CollaboratorPickerDialog(
        users: candidates.where((user) => !list.collaboratorIds.contains(user.userId)).toList(),
      ),
    );

    if (selected == null) return;

    try {
      await _socialService.addCollaboratorToList(
        listId: list.id,
        collaboratorId: selected.userId,
        ownerId: ownerId,
      );
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selected.displayName} added as collaborator'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add collaborator: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _createNewList() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateListDialog(),
    );

    if (result != null && mounted) {
      try {
        await _socialService.createReadingList(
          name: result['name'],
          description: result['description'],
          visibility: result['visibility'],
        );

        // Track list creation for rating prompt
        AppRatingService.instance.trackListCreated();

        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reading list created successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create list: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  KDesignConstants.spacing16,
                  KDesignConstants.spacing16,
                  KDesignConstants.spacing16,
                  0,
                ),
                child: Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: KDesignConstants.spacing8),
                    Text(
                      'Reading Lists',
                      style: KAppTextStyles.headlineMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              HomeHeader(
                title: '',
                subtitle: 'Organize and share your favorite articles',
                showActions: false,
                bottom: 12,
              ),

              // Tabs
              Padding(
                padding: KDesignConstants.paddingHorizontalMd,
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    final currentIndex = _tabController.index;
                    return Row(
                      children: [
                        Expanded(
                          child: PillTabContainer(
                            selected: currentIndex == 0,
                            onTap: () => _tabController.animateTo(0),
                            borderRadius: KBorderRadius.xl,
                            child: Text(
                              'My Lists',
                              textAlign: TextAlign.center,
                              style: KAppTextStyles.labelMedium.copyWith(
                                color: currentIndex == 0
                                    ? KAppColors.getOnPrimary(context)
                                    : KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.65),
                                fontWeight: currentIndex == 0
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: KDesignConstants.spacing8),
                        Expanded(
                          child: PillTabContainer(
                            selected: currentIndex == 1,
                            onTap: () => _tabController.animateTo(1),
                            borderRadius: KBorderRadius.xl,
                            child: Text(
                              'Discover',
                              textAlign: TextAlign.center,
                              style: KAppTextStyles.labelMedium.copyWith(
                                color: currentIndex == 1
                                    ? KAppColors.getOnPrimary(context)
                                    : KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.65),
                                fontWeight: currentIndex == 1
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: KDesignConstants.spacing8),
                        Expanded(
                          child: PillTabContainer(
                            selected: currentIndex == 2,
                            onTap: () => _tabController.animateTo(2),
                            borderRadius: KBorderRadius.xl,
                            child: Text(
                              'Collaborative',
                              textAlign: TextAlign.center,
                              style: KAppTextStyles.labelMedium.copyWith(
                                color: currentIndex == 2
                                    ? KAppColors.getOnPrimary(context)
                                    : KAppColors.getOnBackground(context)
                                        .withValues(alpha: 0.65),
                                fontWeight: currentIndex == 2
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMyListsTab(),
                          _buildPublicListsTab(),
                          _buildCollaborativeTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createNewList,
          backgroundColor: KAppColors.getPrimary(context),
          icon: const Icon(Icons.add),
          label: const Text('New List'),
        ),
      ),
    );
  }

  Widget _buildMyListsTab() {
    if (_myLists.isEmpty) {
      return Center(
        child: Padding(
          padding: KDesignConstants.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 80,
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
              ),
              const SizedBox(height: KDesignConstants.spacing24),
              Text(
                'No Reading Lists Yet',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing12),
              Text(
                'Create your first reading list to organize articles',
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

    return ListView.builder(
      padding: KDesignConstants.paddingLg,
      itemCount: _myLists.length,
      itemBuilder: (context, index) => _buildListCard(_myLists[index]),
    );
  }

  Widget _buildPublicListsTab() {
    if (_publicLists.isEmpty && !_isLoadingDiscoverMore) {
      return Center(
        child: Padding(
          padding: KDesignConstants.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.public,
                size: 80,
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
              ),
              const SizedBox(height: KDesignConstants.spacing24),
              Text(
                'No Public Lists Available',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing12),
              Text(
                'Public lists from other users will appear here',
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

    return ListView(
      padding: KDesignConstants.paddingLg,
      children: [
        TextField(
          controller: _discoverSearchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            setState(() => _discoverQuery = value.trim());
            _loadDiscover(reset: true);
          },
          decoration: InputDecoration(
            hintText: 'Search lists, creators, topics',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _discoverQuery.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _discoverSearchController.clear();
                      setState(() => _discoverQuery = '');
                      _loadDiscover(reset: true);
                    },
                    icon: const Icon(Icons.close),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        if (_discoverTags.isNotEmpty) ...[
          const SizedBox(height: KDesignConstants.spacing12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _discoverTags.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final String? tag = index == 0 ? null : _discoverTags[index - 1];
                final selected = tag == _selectedDiscoverTag;
                return FilterChip(
                  selected: selected,
                  label: Text(tag ?? 'All'),
                  onSelected: (_) {
                    setState(() => _selectedDiscoverTag = selected ? null : tag);
                    _loadDiscover(reset: true);
                  },
                );
              },
            ),
          ),
        ],
        const SizedBox(height: KDesignConstants.spacing12),
        ..._publicLists.map(_buildListCard),
        if (_isLoadingDiscoverMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_discoverHasMore && !_isLoadingDiscoverMore)
          Padding(
            padding: const EdgeInsets.only(top: KDesignConstants.spacing4),
            child: OutlinedButton(
              onPressed: () => _loadDiscover(reset: false),
              child: const Text('Load More'),
            ),
          ),
      ],
    );
  }

  Widget _buildCollaborativeTab() {
    if (_collaborativeLists.isEmpty) {
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
              const SizedBox(height: KDesignConstants.spacing24),
              Text(
                'No Collaborative Lists',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing12),
              Text(
                'Lists where you\'re a collaborator will appear here',
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

    return ListView.builder(
      padding: KDesignConstants.paddingLg,
      itemCount: _collaborativeLists.length,
      itemBuilder: (context, index) => _buildListCard(_collaborativeLists[index]),
    );
  }

  Widget _buildListCard(ReadingList list) {
    final isOwner = _currentUserId != null && list.isOwner(_currentUserId!);
    return InkWell(
      borderRadius: KBorderRadius.lg,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReadingListDetailPage(
              listId: list.id,
              initialList: list,
              currentUserId: _currentUserId,
            ),
          ),
        );
        if (!mounted) return;
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: KDesignConstants.spacing12),
        padding: KDesignConstants.cardPadding,
        decoration: BoxDecoration(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: KAppTextStyles.titleMedium.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (list.description != null && list.description!.isNotEmpty) ...[
                        const SizedBox(height: KDesignConstants.spacing4),
                        Text(
                          list.description!,
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KDesignConstants.spacing8,
                    vertical: KDesignConstants.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: _getVisibilityColor(list.visibility).withValues(alpha: 0.15),
                    borderRadius: KBorderRadius.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getVisibilityIcon(list.visibility),
                        size: 14,
                        color: _getVisibilityColor(list.visibility),
                      ),
                      const SizedBox(width: KDesignConstants.spacing4),
                      Text(
                        _getVisibilityLabel(list.visibility),
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: _getVisibilityColor(list.visibility),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            Row(
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 16,
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
                const SizedBox(width: KDesignConstants.spacing4),
                Text(
                  '${list.articleCount} articles',
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: KDesignConstants.spacing16),
                if (list.isCollaborative) ...[
                  Icon(
                    Icons.people,
                    size: 16,
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: KDesignConstants.spacing4),
                  Text(
                    '${list.collaboratorCount + 1} collaborators',
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: KDesignConstants.spacing16),
                ],
                Text(
                  'by ${list.ownerName}',
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            if (isOwner) ...[
              const SizedBox(height: KDesignConstants.spacing10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _inviteCollaborator(list),
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text('Add Collaborator'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getVisibilityIcon(ListVisibility visibility) {
    switch (visibility) {
      case ListVisibility.public:
        return Icons.public;
      case ListVisibility.private_:
        return Icons.lock;
      case ListVisibility.friendsOnly:
        return Icons.group;
    }
  }

  String _getVisibilityLabel(ListVisibility visibility) {
    switch (visibility) {
      case ListVisibility.public:
        return 'Public';
      case ListVisibility.private_:
        return 'Private';
      case ListVisibility.friendsOnly:
        return 'Friends';
    }
  }

  Color _getVisibilityColor(ListVisibility visibility) {
    switch (visibility) {
      case ListVisibility.public:
        return KAppColors.green;
      case ListVisibility.private_:
        return KAppColors.purple;
      case ListVisibility.friendsOnly:
        return KAppColors.blue;
    }
  }
}

class _CollaboratorPickerDialog extends StatefulWidget {
  const _CollaboratorPickerDialog({required this.users});

  final List<UserProfile> users;

  @override
  State<_CollaboratorPickerDialog> createState() => _CollaboratorPickerDialogState();
}

class _CollaboratorPickerDialogState extends State<_CollaboratorPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.users.where((user) {
      final q = _query.toLowerCase();
      if (q.isEmpty) return true;
      return user.displayName.toLowerCase().contains(q) || user.username.toLowerCase().contains(q);
    }).toList();

    return AlertDialog(
      title: const Text('Add Collaborator'),
      content: SizedBox(
        width: 360,
        height: 420,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search people you follow',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No matching users found'),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                      onTap: () => Navigator.pop(context, user),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _CreateListDialog extends StatefulWidget {
  @override
  State<_CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<_CreateListDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  ListVisibility _visibility = ListVisibility.public;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Reading List'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'List Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: KDesignConstants.spacing16),
            Text(
              'Visibility',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: KDesignConstants.spacing8),
            Column(
              children: [
                RadioListTile<ListVisibility>(
                  value: ListVisibility.public,
                  groupValue: _visibility,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _visibility = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Public'),
                  subtitle: const Text('Anyone can view this list'),
                  secondary: const Icon(Icons.public, size: 18),
                ),
                RadioListTile<ListVisibility>(
                  value: ListVisibility.friendsOnly,
                  groupValue: _visibility,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _visibility = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Friends'),
                  subtitle: const Text('Only followers can view'),
                  secondary: const Icon(Icons.group, size: 18),
                ),
                RadioListTile<ListVisibility>(
                  value: ListVisibility.private_,
                  groupValue: _visibility,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _visibility = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Private'),
                  subtitle: const Text('Only you can view'),
                  secondary: const Icon(Icons.lock, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a list name')),
              );
              return;
            }

            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'description': _descriptionController.text.trim(),
              'visibility': _visibility,
            });
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
