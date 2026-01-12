import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/reading_list_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/service/app_rating_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';

class ReadingListsPage extends StatefulWidget {
  const ReadingListsPage({super.key});

  @override
  State<ReadingListsPage> createState() => _ReadingListsPageState();
}

class _ReadingListsPageState extends State<ReadingListsPage> with SingleTickerProviderStateMixin {
  final SocialFeaturesBackendService _socialService = SocialFeaturesBackendService.instance;
  late TabController _tabController;

  List<ReadingList> _myLists = [];
  List<ReadingList> _publicLists = [];
  List<ReadingList> _collaborativeLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _socialService.getCurrentUserProfile();

      final myLists = await _socialService.getUserReadingLists(profile?.userId ?? '');
      final publicLists = await _socialService.getPublicReadingLists();
      final collaborativeLists = myLists.where((list) => list.isCollaborative && !list.isOwner(profile?.userId ?? '')).toList();

      setState(() {
        _myLists = myLists.where((list) => list.isOwner(profile?.userId ?? '')).toList();
        _publicLists = publicLists;
        _collaborativeLists = collaborativeLists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: KAppColors.getOnBackground(context),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TabBar(
                  controller: _tabController,
                  labelColor: KAppColors.getPrimary(context),
                  unselectedLabelColor: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  indicatorColor: KAppColors.getPrimary(context),
                  tabs: const [
                    Tab(text: 'My Lists'),
                    Tab(text: 'Discover'),
                    Tab(text: 'Collaborative'),
                  ],
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
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 80,
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'No Reading Lists Yet',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(20),
      itemCount: _myLists.length,
      itemBuilder: (context, index) => _buildListCard(_myLists[index]),
    );
  }

  Widget _buildPublicListsTab() {
    if (_publicLists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.public,
                size: 80,
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'No Public Lists Available',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
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

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _publicLists.length,
      itemBuilder: (context, index) => _buildListCard(_publicLists[index]),
    );
  }

  Widget _buildCollaborativeTab() {
    if (_collaborativeLists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'No Collaborative Lists',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(20),
      itemCount: _collaborativeLists.length,
      itemBuilder: (context, index) => _buildListCard(_collaborativeLists[index]),
    );
  }

  Widget _buildListCard(ReadingList list) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
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
                      const SizedBox(height: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getVisibilityColor(list.visibility).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getVisibilityIcon(list.visibility),
                      size: 14,
                      color: _getVisibilityColor(list.visibility),
                    ),
                    const SizedBox(width: 4),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.article_outlined,
                size: 16,
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '${list.articleCount} articles',
                style: KAppTextStyles.labelSmall.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 16),
              if (list.isCollaborative) ...[
                Icon(
                  Icons.people,
                  size: 16,
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${list.collaboratorCount + 1} collaborators',
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Text(
                'by ${list.ownerName}',
                style: KAppTextStyles.labelSmall.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
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
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Visibility',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<ListVisibility>(
              segments: const [
                ButtonSegment(
                  value: ListVisibility.public,
                  label: Text('Public'),
                  icon: Icon(Icons.public, size: 16),
                ),
                ButtonSegment(
                  value: ListVisibility.friendsOnly,
                  label: Text('Friends'),
                  icon: Icon(Icons.group, size: 16),
                ),
                ButtonSegment(
                  value: ListVisibility.private_,
                  label: Text('Private'),
                  icon: Icon(Icons.lock, size: 16),
                ),
              ],
              selected: {_visibility},
              onSelectionChanged: (Set<ListVisibility> newSelection) {
                setState(() {
                  _visibility = newSelection.first;
                });
              },
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
