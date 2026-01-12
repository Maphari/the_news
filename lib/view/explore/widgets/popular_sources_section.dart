import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/news_provider_service.dart';

class PopularSourcesSection extends StatelessWidget {
  const PopularSourcesSection({super.key});

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  List<Map<String, String>> _getPopularSources() {
    final newsProvider = NewsProviderService.instance;
    final articles = newsProvider.articles;

    // Count articles by source
    final sourceCounts = <String, Map<String, dynamic>>{};
    for (final article in articles) {
      final sourceName = article.sourceName;
      if (!sourceCounts.containsKey(sourceName)) {
        sourceCounts[sourceName] = {
          'count': 0,
          'icon': article.sourceIcon,
        };
      }
      sourceCounts[sourceName]!['count'] = (sourceCounts[sourceName]!['count'] as int) + 1;
    }

    // Convert to list and sort by count
    final sourceList = sourceCounts.entries.map((entry) {
      return {
        'name': entry.key,
        'articles': _formatCount(entry.value['count'] as int),
        'icon': entry.value['icon'] as String,
      };
    }).toList();

    sourceList.sort((a, b) {
      final countA = int.tryParse(a['articles']!.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final countB = int.tryParse(b['articles']!.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      return countB.compareTo(countA);
    });

    return sourceList.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final popularSources = _getPopularSources();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          KAppColors.secondary.withValues(alpha: 0.2),
                          KAppColors.tertiary.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.newspaper_outlined,
                      color: KAppColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Popular Sources',
                    style: KAppTextStyles.titleLarge.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...popularSources.map((source) => _SourceCard(
                name: source['name']!,
                articles: source['articles']!,
                iconUrl: source['icon']!,
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SourceCard extends StatefulWidget {
  const _SourceCard({
    required this.name,
    required this.articles,
    required this.iconUrl,
  });

  final String name;
  final String articles;
  final String iconUrl;

  @override
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard> {
  bool isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KAppColors.secondary.withValues(alpha: 0.08),
            KAppColors.tertiary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KAppColors.secondary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KAppColors.secondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.iconUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          KAppColors.secondary.withValues(alpha: 0.2),
                          KAppColors.tertiary.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.newspaper_outlined,
                      color: KAppColors.secondary,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.articles} articles',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                isFollowing = !isFollowing;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: isFollowing
                    ? null
                    : LinearGradient(
                        colors: [
                          KAppColors.primary.withValues(alpha: 0.3),
                          KAppColors.tertiary.withValues(alpha: 0.3),
                        ],
                      ),
                color: isFollowing ? KAppColors.getOnBackground(context).withValues(alpha: 0.05) : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFollowing
                      ? KAppColors.getOnBackground(context).withValues(alpha: 0.15)
                      : KAppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: KAppTextStyles.bodySmall.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
