import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/explore_service.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/view/explore/popular_sources_page.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class PopularSourcesSection extends StatefulWidget {
  const PopularSourcesSection({
    super.key,
    required this.user,
    this.showHeader = true,
    this.preloadedSources,
  });

  final RegisterLoginUserSuccessModel user;
  final bool showHeader;
  final List<PopularSourceModel>? preloadedSources;

  @override
  State<PopularSourcesSection> createState() => _PopularSourcesSectionState();
}

class _PopularSourcesSectionState extends State<PopularSourcesSection> {
  final ExploreService _exploreService = ExploreService.instance;
  final FollowedPublishersService _followed = FollowedPublishersService.instance;

  List<PopularSourceModel> _sources = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final preloaded = widget.preloadedSources;
    if (preloaded != null) {
      _sources = preloaded;
      _isLoading = false;
      final userId = widget.user.userId;
      if (userId.isNotEmpty) {
        _followed.loadFollowedPublishers(userId);
      }
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final results = await _exploreService.getPopularSources(limit: 5);
    final userId = widget.user.userId;
    if (userId.isNotEmpty) {
      await _followed.loadFollowedPublishers(userId);
    }

    if (!mounted) return;
    setState(() {
      _sources = results;
      _isLoading = false;
    });
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: KDesignConstants.paddingHorizontalMd,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                KAppColors.getPrimary(context),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: KDesignConstants.paddingHorizontalMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Sources',
                  style: KAppTextStyles.titleLarge.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PopularSourcesPage(user: widget.user),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KDesignConstants.spacing8),
          ],
          if (_sources.isEmpty)
            Text(
              'No sources available at the moment.',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.64),
              ),
            )
          else
            ..._sources.map(
              (source) => _SourceCard(
                source: source,
                articleCountLabel: _formatCount(source.articleCount),
                userId: widget.user.userId,
              ),
            ),
          const SizedBox(height: KDesignConstants.spacing8),
        ],
      ),
    );
  }
}

class _SourceCard extends StatefulWidget {
  const _SourceCard({
    required this.source,
    required this.articleCountLabel,
    required this.userId,
  });

  final PopularSourceModel source;
  final String articleCountLabel;
  final String userId;

  @override
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard> {
  final FollowedPublishersService _followed = FollowedPublishersService.instance;
  bool _isMutating = false;

  @override
  Widget build(BuildContext context) {
    final isFollowing = _followed.isPublisherFollowed(widget.source.name);

    return Container(
      margin: const EdgeInsets.only(bottom: KDesignConstants.spacing8),
      padding: KDesignConstants.cardPaddingCompact,
      decoration: BoxDecoration(
        color: KAppColors.getSurface(context),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: KBorderRadius.md,
              border: Border.all(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
              ),
            ),
            child: ClipRRect(
              borderRadius: KBorderRadius.md,
              child: SafeNetworkImage(
                widget.source.iconUrl ?? '',
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 46,
                    height: 46,
                    color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
                    child: Icon(
                      Icons.newspaper_outlined,
                      color: KAppColors.getPrimary(context),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.source.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: KDesignConstants.spacing4),
                Text(
                  '${widget.articleCountLabel} stories',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: _isMutating || widget.userId.isEmpty
                ? null
                : () async {
                    setState(() => _isMutating = true);
                    await _followed.toggleFollow(widget.userId, widget.source.name);
                    if (!mounted) return;
                    setState(() => _isMutating = false);
                  },
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: KAppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
