import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/reading_history_sync_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';

class ReadingHistoryPage extends StatefulWidget {
  const ReadingHistoryPage({super.key, required this.userId});

  final String userId;

  @override
  State<ReadingHistoryPage> createState() => _ReadingHistoryPageState();
}

class _ReadingHistoryPageState extends State<ReadingHistoryPage> {
  final ReadingHistorySyncService _historyService = ReadingHistorySyncService.instance;
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analytics = await _historyService.getAnalytics(widget.userId);
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncHistory() async {
    setState(() {
      _isSyncing = true;
    });

    final success = await _historyService.syncHistory(widget.userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'History synced successfully' : 'Sync failed'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (success) {
        _loadHistory();
      } else {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Reading History'),
        content: const Text('This will permanently delete all your reading history. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await _historyService.clearHistory(widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'History cleared' : 'Failed to clear history'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (success) {
          _loadHistory();
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
          child: CustomScrollView(
            slivers: [
              // Header with back button
              SliverToBoxAdapter(
                child: Padding(
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
                      Expanded(
                        child: Text(
                          'Reading History',
                          style: KAppTextStyles.headlineMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.sync,
                          color: KAppColors.getOnBackground(context),
                        ),
                        onPressed: _isSyncing ? null : _syncHistory,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: KAppColors.getOnBackground(context),
                        ),
                        onPressed: _clearHistory,
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: HomeHeader(
                  title: '',
                  subtitle: 'View your reading activity and statistics',
                  showActions: false,
                  bottom: 20,
                ),
              ),

              // Loading or Content
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_analytics == null)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 80,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Reading History',
                            style: KAppTextStyles.titleLarge.copyWith(
                              color: KAppColors.getOnBackground(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Start reading articles to build your history',
                            style: KAppTextStyles.bodyMedium.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                // Analytics Summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overview',
                          style: KAppTextStyles.titleSmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Articles',
                                '${_analytics!['totalArticlesRead']}',
                                Icons.article_outlined,
                                const Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Reading Time',
                                '${_analytics!['totalReadingTimeMinutes']} min',
                                Icons.schedule,
                                const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Last 7 Days',
                                '${_analytics!['last7DaysCount']}',
                                Icons.calendar_today,
                                const Color(0xFFFF9800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Last 30 Days',
                                '${_analytics!['last30DaysCount']}',
                                Icons.calendar_month,
                                const Color(0xFF9C27B0),
                              ),
                            ),
                          ],
                        ),

                        if (_analytics!['mostActiveDay'] != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: KAppColors.getPrimary(context).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  color: KAppColors.getPrimary(context),
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Most Active Day',
                                        style: KAppTextStyles.labelSmall.copyWith(
                                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_analytics!['mostActiveDay']}',
                                        style: KAppTextStyles.titleMedium.copyWith(
                                          color: KAppColors.getOnBackground(context),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${_analytics!['maxArticlesInDay']} articles read',
                                        style: KAppTextStyles.bodySmall.copyWith(
                                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Recent History
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'Recent Articles',
                      style: KAppTextStyles.titleSmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Article List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final history = _historyService.cachedHistory;
                      if (index >= history.length) return null;

                      final entry = history[index];
                      final timeAgo = _getTimeAgo(entry.readAt);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.articleTitle,
                                style: KAppTextStyles.bodyMedium.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeAgo,
                                    style: KAppTextStyles.labelSmall.copyWith(
                                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.timer,
                                    size: 14,
                                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(entry.readDuration / 60).round()} min',
                                    style: KAppTextStyles.labelSmall.copyWith(
                                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _historyService.cachedHistory.length,
                  ),
                ),

                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: KAppTextStyles.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: KAppTextStyles.labelSmall.copyWith(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
