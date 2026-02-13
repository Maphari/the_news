import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/view/publisher/publisher_profile_page.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class PopularSourcesPage extends StatefulWidget {
  const PopularSourcesPage({super.key, required this.user});

  final RegisterLoginUserSuccessModel user;

  @override
  State<PopularSourcesPage> createState() => _PopularSourcesPageState();
}

class _PopularSourcesPageState extends State<PopularSourcesPage> {
  final FollowedPublishersService _followedService =
      FollowedPublishersService.instance;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _followedService.addListener(_onFollowedChanged);
  }

  @override
  void dispose() {
    _followedService.removeListener(_onFollowedChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFollowedChanged() {
    if (mounted) setState(() {});
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  List<_SourceItem> _getAllSources() {
    final newsProvider = NewsProviderService.instance;
    final articles = newsProvider.articles;
    final sourceCounts = <String, Map<String, dynamic>>{};

    for (final article in articles) {
      final sourceName = article.sourceName;
      if (sourceName.isEmpty ||
          sourceName.toLowerCase() == 'unknown' ||
          sourceName.toLowerCase() == 'null') {
        continue;
      }

      if (!sourceCounts.containsKey(sourceName)) {
        sourceCounts[sourceName] = {
          'count': 0,
          'icon': article.sourceIcon,
        };
      }
      sourceCounts[sourceName]!['count'] =
          (sourceCounts[sourceName]!['count'] as int) + 1;
    }

    final sourceList = sourceCounts.entries.map((entry) {
      final icon = entry.value['icon'] as String? ?? '';
      return _SourceItem(
        name: entry.key,
        articles: _formatCount(entry.value['count'] as int),
        iconUrl: icon,
      );
    }).toList();

    sourceList.sort((a, b) {
      final countA = int.tryParse(a.articles.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final countB = int.tryParse(b.articles.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      return countB.compareTo(countA);
    });

    if (_query.isEmpty) return sourceList;
    return sourceList
        .where((source) =>
            source.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  Future<void> _toggleFollow(String name) async {
    await _followedService.toggleFollow(widget.user.userId, name);
  }

  void _openSource(_SourceItem source) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublisherProfilePage(
          publisherName: source.name,
          publisherIcon: source.iconUrl.isEmpty ? null : source.iconUrl,
          user: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sources = _getAllSources();

    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: KAppBar(
        title: Text(
          'Popular Sources',
          style: KAppTextStyles.titleLarge.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: AppBackButton(onPressed: () => Navigator.pop(context),),
        ),
      body: Column(
        children: [
          Padding(
            padding: KDesignConstants.paddingHorizontalMd,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context),
              ),
              decoration: InputDecoration(
                hintText: 'Search sources',
                hintStyle: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: KBorderRadius.xl,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing12),
          Expanded(
            child: sources.isEmpty
                ? Center(
                    child: Text(
                      'No sources found',
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: sources.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final source = sources[index];
                      final isFollowed =
                          _followedService.isPublisherFollowed(source.name);

                      return InkWell(
                        onTap: () => _openSource(source),
                        borderRadius: KBorderRadius.xl,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
                            borderRadius: KBorderRadius.xl,
                            border: Border.all(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: KBorderRadius.md,
                                child: source.iconUrl.isNotEmpty
                                    ? SafeNetworkImage(
                                        source.iconUrl,
                                        width: 46,
                                        height: 46,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) {
                                          return _fallbackIcon(context);
                                        },
                                      )
                                    : _fallbackIcon(context),
                              ),
                              const SizedBox(width: KDesignConstants.spacing12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      source.name,
                                      style: KAppTextStyles.titleMedium.copyWith(
                                        color: KAppColors.getOnBackground(context),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${source.articles} articles',
                                      style: KAppTextStyles.bodySmall.copyWith(
                                        color: KAppColors.getOnBackground(context)
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: KDesignConstants.spacing8),
                              OutlinedButton(
                                onPressed: () => _toggleFollow(source.name),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isFollowed
                                      ? KAppColors.getOnBackground(context)
                                      : KAppColors.getPrimary(context),
                                  side: BorderSide(
                                    color: isFollowed
                                        ? KAppColors.getOnBackground(context).withValues(alpha: 0.2)
                                        : KAppColors.getPrimary(context).withValues(alpha: 0.6),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: KBorderRadius.lg,
                                  ),
                                ),
                                child: Text(isFollowed ? 'Following' : 'Follow'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: KAppColors.getPrimary(context).withValues(alpha: 0.12),
        borderRadius: KBorderRadius.md,
      ),
      child: Icon(
        Icons.newspaper_outlined,
        color: KAppColors.getPrimary(context),
      ),
    );
  }
}

class _SourceItem {
  const _SourceItem({
    required this.name,
    required this.articles,
    required this.iconUrl,
  });

  final String name;
  final String articles;
  final String iconUrl;
}
