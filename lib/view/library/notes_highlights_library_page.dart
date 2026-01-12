import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/highlight_model.dart';
import 'package:the_news/service/notes_highlights_service.dart';

/// Library page for viewing all highlights and notes
class NotesHighlightsLibraryPage extends StatefulWidget {
  const NotesHighlightsLibraryPage({super.key});

  @override
  State<NotesHighlightsLibraryPage> createState() => _NotesHighlightsLibraryPageState();
}

class _NotesHighlightsLibraryPageState extends State<NotesHighlightsLibraryPage>
    with SingleTickerProviderStateMixin {
  final NotesHighlightsService _service = NotesHighlightsService.instance;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<HighlightModel> _filteredHighlights = [];
  List<NoteModel> _filteredNotes = [];
  HighlightColor? _selectedColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service.addListener(_onServiceChanged);
    _updateFilteredLists();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) {
      _updateFilteredLists();
    }
  }

  void _updateFilteredLists() {
    setState(() {
      final query = _searchController.text;

      if (_selectedColor != null) {
        _filteredHighlights = _service.getHighlightsByColor(_selectedColor!);
        if (query.isNotEmpty) {
          _filteredHighlights = _filteredHighlights.where((h) {
            return h.highlightedText.toLowerCase().contains(query.toLowerCase()) ||
                h.articleTitle.toLowerCase().contains(query.toLowerCase());
          }).toList();
        }
      } else {
        _filteredHighlights = query.isEmpty
            ? _service.allHighlights
            : _service.searchHighlights(query);
      }

      _filteredNotes = query.isEmpty
          ? _service.allNotes
          : _service.searchNotes(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: KAppColors.getOnBackground(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Library',
          style: KAppTextStyles.titleLarge.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: KAppColors.getOnBackground(context)),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export_text', child: Text('Export as Text')),
              const PopupMenuItem(value: 'export_json', child: Text('Export as JSON')),
              const PopupMenuItem(value: 'clear_all', child: Text('Clear All')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: KAppColors.getPrimary(context),
          unselectedLabelColor: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
          indicatorColor: KAppColors.getPrimary(context),
          tabs: [
            Tab(text: 'Highlights (${_service.totalHighlightsCount})'),
            Tab(text: 'Notes (${_service.totalNotesCount})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Color filter (only for highlights tab)
          if (_tabController.index == 0) _buildColorFilter(),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHighlightsList(),
                _buildNotesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _updateFilteredLists(),
        decoration: InputDecoration(
          hintText: 'Search highlights and notes...',
          prefixIcon: Icon(Icons.search, color: KAppColors.getOnBackground(context).withValues(alpha: 0.5)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: KAppColors.getOnBackground(context).withValues(alpha: 0.5)),
                  onPressed: () {
                    _searchController.clear();
                    _updateFilteredLists();
                  },
                )
              : null,
          filled: true,
          fillColor: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildColorFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildColorChip(null, 'All'),
          const SizedBox(width: 8),
          ...HighlightColor.values.map((color) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildColorChip(color, color.label),
          )),
        ],
      ),
    );
  }

  Widget _buildColorChip(HighlightColor? color, String label) {
    final isSelected = _selectedColor == color;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedColor = color;
          _updateFilteredLists();
        });
      },
      backgroundColor: color != null
          ? Color(color.value).withValues(alpha: 0.2)
          : KAppColors.getOnBackground(context).withValues(alpha: 0.05),
      selectedColor: color != null
          ? Color(color.value).withValues(alpha: 0.4)
          : KAppColors.getPrimary(context).withValues(alpha: 0.2),
      checkmarkColor: KAppColors.getOnBackground(context),
    );
  }

  Widget _buildHighlightsList() {
    if (_filteredHighlights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.highlight_off,
              size: 64,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No highlights yet',
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select text in articles to create highlights',
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredHighlights.length,
      itemBuilder: (context, index) {
        final highlight = _filteredHighlights[index];
        return _HighlightCard(
          highlight: highlight,
          onDelete: () => _service.deleteHighlight(highlight.articleId, highlight.highlightId),
        );
      },
    );
  }

  Widget _buildNotesList() {
    if (_filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add notes to save your thoughts on articles',
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return _NoteCard(
          note: note,
          onDelete: () => _service.deleteNote(note.articleId, note.noteId),
        );
      },
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'export_text':
        final text = _service.exportAsText();
        await Share.share(text, subject: 'My Highlights & Notes');
        break;
      case 'export_json':
        final json = _service.exportAsJson();
        await Clipboard.setData(ClipboardData(text: json));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('JSON copied to clipboard')),
          );
        }
        break;
      case 'clear_all':
        final messenger = ScaffoldMessenger.of(context);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear All?'),
            content: const Text('This will delete all your highlights and notes. This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear All', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await _service.clearAll();
          if (mounted) {
            messenger.showSnackBar(
              const SnackBar(content: Text('All highlights and notes cleared')),
            );
          }
        }
        break;
    }
  }
}

/// Card widget for displaying a highlight
class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.highlight,
    required this.onDelete,
  });

  final HighlightModel highlight;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Color(highlight.color.value).withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Color(highlight.color.value).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(highlight.color.value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    highlight.articleTitle,
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              highlight.highlightedText,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                height: 1.5,
              ),
            ),
            if (highlight.note != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        highlight.note!,
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(highlight.createdAt),
              style: KAppTextStyles.labelSmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Card widget for displaying a note
class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onDelete,
  });

  final NoteModel note;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.articleTitle,
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              note.content,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                height: 1.5,
              ),
            ),
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: note.tags.map((tag) => Chip(
                  label: Text(
                    tag,
                    style: KAppTextStyles.labelSmall.copyWith(
                      color: KAppColors.getPrimary(context),
                    ),
                  ),
                  backgroundColor: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(note.createdAt),
              style: KAppTextStyles.labelSmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
