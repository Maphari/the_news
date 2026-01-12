import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/story_cluster_model.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/story_clustering_service.dart';
import 'package:the_news/view/perspectives/widgets/bias_indicator_widget.dart';
import 'package:the_news/view/perspectives/widgets/perspective_article_card.dart';
import 'package:the_news/view/article_details/article_detail_page.dart';

/// Page showing side-by-side comparison of different perspectives
class PerspectiveComparisonPage extends StatefulWidget {
  const PerspectiveComparisonPage({
    super.key,
    required this.cluster,
  });

  final StoryCluster cluster;

  @override
  State<PerspectiveComparisonPage> createState() => _PerspectiveComparisonPageState();
}

class _PerspectiveComparisonPageState extends State<PerspectiveComparisonPage> {
  final StoryClusteringService _clusteringService = StoryClusteringService.instance;
  PerspectiveComparison? _comparison;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _createComparison();
  }

  void _createComparison() {
    _comparison = _clusteringService.createPerspectiveComparison(widget.cluster);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_comparison != null) ...[
              _buildTabBar(),
              Expanded(
                child: _selectedTab == 0
                    ? _buildComparisonView()
                    : _buildAllArticlesView(),
              ),
            ] else ...[
              Expanded(
                child: _buildNoComparisonView(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: KAppColors.getOnBackground(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.cluster.category.label,
                            style: KAppTextStyles.labelSmall.copyWith(
                              color: KAppColors.getPrimary(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.cluster.storyTitle,
                      style: KAppTextStyles.titleMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.cluster.articleCount} articles from different sources',
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTab('Compare', 0),
          const SizedBox(width: 12),
          _buildTab('All Articles', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? KAppColors.getPrimary(context)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: KAppTextStyles.labelLarge.copyWith(
              color: isSelected
                  ? KAppColors.getPrimary(context)
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonView() {
    if (_comparison == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diversity score card
          _buildDiversityCard(),
          const SizedBox(height: 24),

          // Common points
          if (_comparison!.commonPoints.isNotEmpty) ...[
            _buildSectionHeader('Common Points', Icons.check_circle_outline),
            const SizedBox(height: 12),
            ..._comparison!.commonPoints.map((point) => _buildPointCard(
              point,
              const Color(0xFF4CAF50),
            )),
            const SizedBox(height: 24),
          ],

          // Divergent points
          if (_comparison!.divergentPoints.isNotEmpty) ...[
            _buildSectionHeader('Divergent Points', Icons.alt_route),
            const SizedBox(height: 12),
            ..._comparison!.divergentPoints.map((point) => _buildPointCard(
              point,
              const Color(0xFFFF9800),
            )),
            const SizedBox(height: 24),
          ],

          // Perspective articles
          _buildSectionHeader('Different Perspectives', Icons.auto_awesome),
          const SizedBox(height: 16),

          // Left perspective
          _buildPerspectiveSection(
            'Left Perspective',
            _comparison!.leftPerspective,
            BiasIndicator.leftLeaning,
          ),
          const SizedBox(height: 16),

          // Center perspective
          _buildPerspectiveSection(
            'Center Perspective',
            _comparison!.centerPerspective,
            BiasIndicator.center,
          ),
          const SizedBox(height: 16),

          // Right perspective
          _buildPerspectiveSection(
            'Right Perspective',
            _comparison!.rightPerspective,
            BiasIndicator.rightLeaning,
          ),
        ],
      ),
    );
  }

  Widget _buildDiversityCard() {
    final score = _comparison!.diversityScore;
    final percentage = (score * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KAppColors.getPrimary(context).withValues(alpha: 0.1),
            KAppColors.getPrimary(context).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bubble_chart,
              color: KAppColors.getPrimary(context),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perspective Diversity',
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage% - ${_getDiversityLabel(score)}',
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.getPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDiversityLabel(double score) {
    if (score >= 0.7) return 'Highly diverse perspectives';
    if (score >= 0.4) return 'Moderately diverse perspectives';
    return 'Limited diversity';
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: KAppColors.getPrimary(context),
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: KAppTextStyles.titleMedium.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPointCard(String point, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                point,
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerspectiveSection(
    String title,
    ArticleModel article,
    BiasIndicator bias,
  ) {
    final credibility = SourceCredibility.getForSource(article.sourceName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: Color(bias.colorValue),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: KAppTextStyles.titleSmall.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            BiasIndicatorWidget(bias: credibility.bias),
          ],
        ),
        const SizedBox(height: 12),
        PerspectiveArticleCard(
          article: article,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleDetailPage(article: article),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAllArticlesView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.cluster.articles.length,
      itemBuilder: (context, index) {
        final article = widget.cluster.articles[index];
        final credibility = SourceCredibility.getForSource(article.sourceName);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      article.sourceName,
                      style: KAppTextStyles.labelMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  BiasIndicatorWidget(bias: credibility.bias),
                ],
              ),
              const SizedBox(height: 8),
              PerspectiveArticleCard(
                article: article,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleDetailPage(article: article),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoComparisonView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Not enough perspectives',
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This story needs articles from different bias perspectives to create a comparison.',
              textAlign: TextAlign.center,
              style: KAppTextStyles.bodySmall.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
