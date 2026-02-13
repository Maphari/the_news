import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/offline_reading_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/experience_service.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/view/article_details/article_detail_page.dart';

/// Page for managing offline reading queue
class OfflineReadingPage extends StatefulWidget {
  const OfflineReadingPage({super.key});

  @override
  State<OfflineReadingPage> createState() => _OfflineReadingPageState();
}

class _OfflineReadingPageState extends State<OfflineReadingPage> {
  final OfflineReadingService _offlineService = OfflineReadingService.instance;
  final AuthService _authService = AuthService.instance;
  final ExperienceService _experienceService = ExperienceService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<ArticleModel> _filteredArticles = [];
  bool _isSearching = false;
  bool _isCloudSyncing = false;
  int _manifestArticleCount = 0;

  @override
  void initState() {
    super.initState();
    _loadManifestCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      _filteredArticles = _offlineService.searchOfflineArticles(query);
    });
  }

  Future<void> _loadManifestCount() async {
    final user = await _authService.getCurrentUser();
    final userId = (user?['id'] ?? user?['userId'])?.toString();
    if (userId == null || userId.isEmpty) return;
    final ids = await _experienceService.fetchOfflineManifestArticleIds(userId);
    if (!mounted) return;
    setState(() {
      _manifestArticleCount = ids.length;
    });
  }

  Future<void> _syncCloudManifest() async {
    final user = await _authService.getCurrentUser();
    final userId = (user?['id'] ?? user?['userId'])?.toString();
    if (userId == null || userId.isEmpty) return;

    setState(() => _isCloudSyncing = true);
    final queued = await _experienceService.syncOfflineManifest(userId);
    if (!mounted) return;
    setState(() => _isCloudSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          queued > 0
              ? 'Synced $queued articles from cloud manifest'
              : 'Cloud manifest is already in sync',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: KAppBar(
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          'Offline Reading',
          style: KAppTextStyles.titleLarge.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showSettings,
            icon: Icon(
              Icons.settings_outlined,
              color: KAppColors.getOnBackground(context),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _offlineService,
        builder: (context, _) {
          return Column(
            children: [
              _buildStorageIndicator(),
              if (_offlineService.isDownloading) _buildDownloadProgress(),
              _buildSearchBar(),
              Expanded(
                child: _offlineService.cachedArticles.isEmpty
                    ? _buildEmptyState()
                    : _buildArticleList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDownloadProgress() {
    final progress = _offlineService.downloadProgress;
    final downloaded = _offlineService.downloadedCount;
    final total = _offlineService.totalToDownload;

    return Container(
      padding: KDesignConstants.paddingMd,
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(KAppColors.getPrimary(context)),
                    ),
                  ),
                  const SizedBox(width: KDesignConstants.spacing12),
                  Text(
                    'Downloading articles...',
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  _offlineService.cancelDownload();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: KAppColors.getPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(KAppColors.getPrimary(context)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing8),
          Text(
            '$downloaded of $total articles downloaded (${(progress * 100).toStringAsFixed(0)}%)',
            style: KAppTextStyles.labelSmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageIndicator() {
    return FutureBuilder<double>(
      future: _offlineService.getStorageSizeMB(),
      builder: (context, snapshot) {
        final usedMB = snapshot.data ?? 0.0;
        final maxMB = _offlineService.maxStorageMB;
        final percentage = (usedMB / maxMB).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: KAppColors.getBackground(context),
            border: Border(
              bottom: BorderSide(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storage,
                        size: 20,
                        color: KAppColors.getPrimary(context),
                      ),
                      const SizedBox(width: KDesignConstants.spacing8),
                      Text(
                        'Storage',
                        style: KAppTextStyles.titleSmall.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${usedMB.toStringAsFixed(1)} / $maxMB MB',
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KDesignConstants.spacing10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _manifestArticleCount > 0
                          ? 'Cloud manifest: $_manifestArticleCount articles'
                          : 'Cloud manifest unavailable',
                      style: KAppTextStyles.labelSmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isCloudSyncing ? null : _syncCloudManifest,
                    icon: _isCloudSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text('Sync cloud'),
                  ),
                ],
              ),
              const SizedBox(height: KDesignConstants.spacing12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    percentage > 0.9
                        ? KAppColors.error
                        : percentage > 0.7
                            ? KAppColors.warning
                            : KAppColors.getPrimary(context),
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing8),
              Text(
                '${_offlineService.cachedArticleCount} articles cached',
                style: KAppTextStyles.labelSmall.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: KAppColors.getBackground(context),
        border: Border(
          bottom: BorderSide(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: KAppTextStyles.bodyMedium.copyWith(
          color: KAppColors.getOnBackground(context),
        ),
        decoration: InputDecoration(
          hintText: 'Search offline articles...',
          hintStyle: KAppTextStyles.bodyMedium.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: Icon(
                    Icons.clear,
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                )
              : null,
          filled: true,
          fillColor: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: KBorderRadius.md,
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildArticleList() {
    final articles = _isSearching
        ? _filteredArticles
        : _offlineService.cachedArticles.values.toList();

    if (_isSearching && articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
              ),
              const SizedBox(height: KDesignConstants.spacing24),
              Text(
                'No Results Found',
                style: KAppTextStyles.titleLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing12),
              Text(
                'Try different keywords or clear the search',
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
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: KAppColors.getBackground(context),
            borderRadius: KBorderRadius.md,
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailPage(article: article),
                ),
              );
            },
            borderRadius: KBorderRadius.md,
            child: Padding(
              padding: KDesignConstants.paddingMd,
              child: Row(
                children: [
                  // Offline indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: KAppColors.success.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.offline_pin,
                      color: KAppColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: KDesignConstants.spacing16),

                  // Article info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: KAppTextStyles.bodyMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: KDesignConstants.spacing4),
                        Text(
                          article.sourceName,
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete button
                  IconButton(
                    onPressed: () => _removeArticle(article.articleId),
                    icon: Icon(
                      Icons.delete_outline,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 80,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: KDesignConstants.spacing24),
            Text(
              'No Offline Articles',
              style: KAppTextStyles.titleLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            Text(
              'Download articles for offline reading by tapping the download icon on any article.',
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

  Future<void> _removeArticle(String articleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Article'),
        content: const Text('Are you sure you want to remove this article from offline storage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _offlineService.removeFromQueue(articleId);
    }
  }

  Future<void> _showSettings() async {
    await showDialog(
      context: context,
      builder: (context) => _OfflineSettingsDialog(offlineService: _offlineService),
    );
  }
}

class _OfflineSettingsDialog extends StatefulWidget {
  const _OfflineSettingsDialog({required this.offlineService});

  final OfflineReadingService offlineService;

  @override
  State<_OfflineSettingsDialog> createState() => _OfflineSettingsDialogState();
}

class _OfflineSettingsDialogState extends State<_OfflineSettingsDialog> {
  late bool _autoDownloadOnWiFi;
  late int _maxStorageMB;

  @override
  void initState() {
    super.initState();
    _autoDownloadOnWiFi = widget.offlineService.autoDownloadOnWiFi;
    _maxStorageMB = widget.offlineService.maxStorageMB;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Offline Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Auto-download on WiFi'),
            subtitle: const Text('Automatically download queued articles when connected to WiFi'),
            value: _autoDownloadOnWiFi,
            onChanged: (value) {
              setState(() {
                _autoDownloadOnWiFi = value;
              });
            },
          ),
          const SizedBox(height: KDesignConstants.spacing16),
          ListTile(
            title: const Text('Max Storage'),
            subtitle: Text('$_maxStorageMB MB'),
          ),
          Slider(
            value: _maxStorageMB.toDouble(),
            min: 100,
            max: 2000,
            divisions: 19,
            label: '$_maxStorageMB MB',
            onChanged: (value) {
              setState(() {
                _maxStorageMB = value.toInt();
              });
            },
          ),
          const SizedBox(height: KDesignConstants.spacing16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Cache'),
                    content: const Text('This will remove all offline articles. Continue?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await widget.offlineService.clearAllCache();
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Clear All Cache'),
              style: OutlinedButton.styleFrom(
                foregroundColor: KAppColors.error,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await widget.offlineService.updateSettings(
              autoDownloadOnWiFi: _autoDownloadOnWiFi,
              maxStorageMB: _maxStorageMB,
            );
            if (mounted) {
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
