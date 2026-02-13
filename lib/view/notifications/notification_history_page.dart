import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../service/auth_service.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

/// Notification History Page - Displays user's notification history
/// Uses ApiClient for all network requests following clean architecture
class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  State<NotificationHistoryPage> createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  final AuthService _authService = AuthService();
  final _api = ApiClient.instance;

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotificationHistory();
  }

  Future<void> _loadNotificationHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await _authService.getCurrentUser();
      final userId = userData?['id'] as String? ?? userData?['userId'] as String?;

      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final response = await _api.get(
        'notifications/history/$userId',
        requiresAuth: true,
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(
            data['notifications'] ?? [],
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = _api.getErrorMessage(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final response = await _api.patch(
        'notifications/history/$notificationId/read',
        body: {},
        requiresAuth: true,
        timeout: const Duration(seconds: 10),
      );

      if (_api.isSuccess(response)) {
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n['id'] == notificationId,
          );
          if (index != -1) {
            _notifications[index]['read'] = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as read: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final response = await _api.delete(
        'notifications/history/$notificationId',
        requiresAuth: true,
        timeout: const Duration(seconds: 10),
      );

      if (_api.isSuccess(response)) {
        setState(() {
          _notifications.removeWhere((n) => n['id'] == notificationId);
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: KAppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userData = await _authService.getCurrentUser();
      final userId = userData?['id'] as String? ?? userData?['userId'] as String?;

      if (userId == null) return;

      final response = await _api.delete(
        'notifications/history/user/$userId',
        requiresAuth: true,
        timeout: const Duration(seconds: 10),
      );

      if (_api.isSuccess(response)) {
        setState(() {
          _notifications.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications cleared')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear: ${e.toString()}')),
        );
      }
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding:KDesignConstants.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getNotificationIcon(notification['type']),
                  const SizedBox(width: KDesignConstants.spacing12),
                  Expanded(
                    child: Text(
                      notification['title'] ?? 'Notification',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: KDesignConstants.spacing16),
              if (notification['imageUrl'] != null) ...[
                ClipRRect(
                  borderRadius: KBorderRadius.md,
                  child: SafeNetworkImage(
                    notification['imageUrl'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: KDesignConstants.spacing16),
              ],
              Text(
                notification['body'] ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: KDesignConstants.spacing16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: KDesignConstants.spacing4),
                  Text(
                    timeago.format(DateTime.parse(notification['timestamp'])),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KDesignConstants.spacing24),
              Row(
                children: [
                  if (notification['read'] == false)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _markAsRead(notification['id']);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.done),
                        label: const Text('Mark as Read'),
                      ),
                    ),
                  if (notification['read'] == false) const SizedBox(width: KDesignConstants.spacing8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        _deleteNotification(notification['id']);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline),
                      style: FilledButton.styleFrom(
                        backgroundColor: KAppColors.error,
                      ),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Icon _getNotificationIcon(String? type) {
    switch (type) {
      case 'breaking_news':
        return const Icon(Icons.campaign, color: KAppColors.error, size: 28);
      case 'daily_digest':
        return const Icon(Icons.article, color: KAppColors.info, size: 28);
      case 'publisher_update':
        return const Icon(Icons.newspaper, color: KAppColors.success, size: 28);
      case 'comment_reply':
        return const Icon(Icons.comment, color: KAppColors.warning, size: 28);
      default:
        return Icon(Icons.notifications, color: KAppColors.getOnBackground(context).withValues(alpha: 0.5), size: 28);
    }
  }

  String _getNotificationTypeName(String? type) {
    switch (type) {
      case 'breaking_news':
        return 'Breaking News';
      case 'daily_digest':
        return 'Daily Digest';
      case 'publisher_update':
        return 'Publisher Update';
      case 'comment_reply':
        return 'Comment Reply';
      default:
        return 'Notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color screenBackgroundColor = KAppColors.getBackground(context);
    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: screenBackgroundColor,
      child: Scaffold(
        backgroundColor: screenBackgroundColor,
        appBar: KAppBar(
          centerTitle: false,
          title: const Text('Notification History'),
          actions: [
            if (_notifications.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: _clearAllNotifications,
                tooltip: 'Clear all',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: KDesignConstants.spacing16),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: KDesignConstants.spacing16),
                    FilledButton.icon(
                      onPressed: _loadNotificationHistory,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: KDesignConstants.spacing16),
                    Text(
                      'No notifications yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: KDesignConstants.spacing8),
                    Text(
                      'You\'ll see your notifications here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadNotificationHistory,
                child: ListView.builder(
                  itemCount: _notifications.length,
                  padding: KDesignConstants.paddingMd,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final isRead = notification['read'] == true;
      
                    return Dismissible(
                      key: Key(notification['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: KAppColors.error,
                          borderRadius: KBorderRadius.md,
                        ),
                        child: const Icon(Icons.delete, color: KAppColors.onImage),
                      ),
                      onDismissed: (direction) {
                        _deleteNotification(notification['id']);
                      },
                      child: Card(
                        color: isRead
                            ? null
                            : Theme.of(
                                context,
                              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        child: InkWell(
                          onTap: () {
                            if (!isRead) {
                              _markAsRead(notification['id']);
                            }
                            _showNotificationDetails(notification);
                          },
                          borderRadius: KBorderRadius.md,
                          child: Padding(
                            padding: KDesignConstants.paddingMd,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _getNotificationIcon(notification['type']),
                                const SizedBox(width: KDesignConstants.spacing16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification['title'] ??
                                                  'Notification',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: isRead
                                                        ? FontWeight.normal
                                                        : FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: KDesignConstants.spacing4),
                                      Text(
                                        notification['body'] ?? '',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: KDesignConstants.spacing8),
                                      Row(
                                        children: [
                                          Text(
                                            _getNotificationTypeName(
                                              notification['type'],
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(width: KDesignConstants.spacing8),
                                          const Text('•'),
                                          const SizedBox(width: KDesignConstants.spacing8),
                                          Text(
                                            timeago.format(
                                              DateTime.parse(
                                                notification['timestamp'],
                                              ),
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
