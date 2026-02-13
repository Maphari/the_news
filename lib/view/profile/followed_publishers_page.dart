import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/widgets/app_back_button.dart';

/// Page showing all followed publishers
class FollowedPublishersPage extends StatefulWidget {
  const FollowedPublishersPage({super.key});

  @override
  State<FollowedPublishersPage> createState() => _FollowedPublishersPageState();
}

class _FollowedPublishersPageState extends State<FollowedPublishersPage> {
  final FollowedPublishersService _followedService = FollowedPublishersService.instance;
  final AuthService _authService = AuthService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userData = await _authService.getCurrentUser();
    if (userData != null && mounted) {
      setState(() {
        _userId = userData['id'] as String? ?? userData['userId'] as String?;
      });
    }
  }

  Future<void> _unfollowPublisher(String publisherName) async {
    if (_userId == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfollow Publisher'),
        content: Text('Are you sure you want to unfollow $publisherName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _followedService.unfollowPublisher(_userId!, publisherName);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: KAppColors.darkOnBackground),
                const SizedBox(width: KDesignConstants.spacing12),
                Expanded(
                  child: Text(
                    'Unfollowed $publisherName',
                    style: const TextStyle(
                      color: KAppColors.darkOnBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: KBorderRadius.md,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: KAppColors.darkOnBackground),
                const SizedBox(width: KDesignConstants.spacing12),
                const Expanded(
                  child: Text(
                    'Failed to unfollow publisher',
                    style: TextStyle(
                      color: KAppColors.darkOnBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: KBorderRadius.md,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: KAppColors.getBackground(context),
      child: Scaffold(
        backgroundColor: KAppColors.getBackground(context),
        appBar: KAppBar(
          title: Text(
            'Followed Publishers',
            style: KAppTextStyles.titleLarge.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: KAppColors.getBackground(context),
          elevation: 0,
          leading: AppBackButton(onPressed: () => Navigator.pop(context),),
            ),
          
        body: ListenableBuilder(
          listenable: _followedService,
          builder: (context, child) {
            if (_followedService.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        KAppColors.getPrimary(context),
                      ),
                    ),
                    const SizedBox(height: KDesignConstants.spacing16),
                    Text(
                      'Loading publishers...',
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (_followedService.followedPublisherNames.isEmpty) {
              return Center(
                child: Padding(
                  padding: KDesignConstants.paddingXl,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.rss_feed,
                          size: 48,
                          color: KAppColors.getPrimary(context).withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: KDesignConstants.spacing24),
                      Text(
                        'No Followed Publishers',
                        style: KAppTextStyles.headlineSmall.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: KDesignConstants.spacing12),
                      Text(
                        'Follow publishers from article cards\nto see their news prioritized in your feed',
                        style: KAppTextStyles.bodyMedium.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: KDesignConstants.spacing32),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KAppColors.getPrimary(context),
                          foregroundColor: KAppColors.darkOnBackground,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: KBorderRadius.md,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final publishers = _followedService.followedPublisherNames.toList()..sort();

            return Column(
              children: [
                // Summary Card
                Container(
                  margin: KDesignConstants.paddingMd,
                  padding: KDesignConstants.paddingMd,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        KAppColors.getPrimary(context).withValues(alpha: 0.1),
                        KAppColors.getPrimary(context).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: KBorderRadius.lg,
                    border: Border.all(
                      color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                          borderRadius: KBorderRadius.md,
                        ),
                        child: Icon(
                          Icons.bookmarks,
                          color: KAppColors.getPrimary(context),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: KDesignConstants.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${publishers.length} Publisher${publishers.length == 1 ? '' : 's'}',
                              style: KAppTextStyles.titleLarge.copyWith(
                                color: KAppColors.getOnBackground(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: KDesignConstants.spacing4),
                            Text(
                              'Articles from these publishers appear first',
                              style: KAppTextStyles.bodySmall.copyWith(
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Publishers List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: publishers.length,
                    itemBuilder: (context, index) {
                      final publisher = publishers[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                          borderRadius: KBorderRadius.md,
                          border: Border.all(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.article,
                              color: KAppColors.getPrimary(context),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            publisher,
                            style: KAppTextStyles.titleMedium.copyWith(
                              color: KAppColors.getOnBackground(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Followed publisher',
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.person_remove,
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            ),
                            onPressed: () => _unfollowPublisher(publisher),
                            tooltip: 'Unfollow',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
