import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/story_cluster_model.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/service/story_clustering_service.dart';
import 'package:the_news/view/perspectives/widgets/bias_indicator_widget.dart';
import 'package:the_news/view/perspectives/widgets/perspective_article_card.dart';
import 'package:the_news/view/article_details/article_detail_page.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/widgets/pill_tab.dart';
import 'package:the_news/service/experience_service.dart';
import 'package:the_news/service/enhanced_ai_service.dart';

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
  final ExperienceService _experienceService = ExperienceService.instance;
  final EnhancedAIService _enhancedAiService = EnhancedAIService.instance;
  PerspectiveComparison? _comparison;
  List<ExperiencePerspective> _backendPerspectives = const [];
  String? _aiBiasSummary;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _createComparison();
    _loadBackendPerspectiveSnapshot();
  }

  void _createComparison() {
    _comparison = _clusteringService.createPerspectiveComparison(widget.cluster);
    setState(() {});
  }

  Future<void> _loadBackendPerspectiveSnapshot() async {
    final articleId = widget.cluster.latestArticle.articleId;
    if (articleId.isEmpty) return;
    final perspectives = await _experienceService.fetchPerspectives(articleId);
    String? aiSummary;
    try {
      final bias = await _enhancedAiService.detectBias(widget.cluster.latestArticle);
      aiSummary = bias.summary;
    } catch (_) {
      aiSummary = null;
    }
    if (!mounted) return;
    setState(() {
      _backendPerspectives = perspectives;
      _aiBiasSummary = aiSummary;
    });
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
              const AppBackButton(),
              const SizedBox(width: KDesignConstants.spacing12),
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
                    const SizedBox(height: KDesignConstants.spacing8),
                    Text(
                      widget.cluster.storyTitle,
                      style: KAppTextStyles.titleMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: KDesignConstants.spacing4),
                    Text(
                      '${widget.cluster.articleCount} articles from different sources',
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Perspective labels are estimated from source reputations.',
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
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
    const tabHeight = KDesignConstants.tabHeight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: SizedBox(
        height: tabHeight,
        child: Row(
          children: [
            _buildTab('Compare', 0, icon: Icons.compare_arrows, height: tabHeight),
            const SizedBox(width: KDesignConstants.spacing8),
            _buildTab('All Articles', 1, icon: Icons.library_books_outlined, height: tabHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    String label,
    int index, {
    required IconData icon,
    required double height,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: PillTabContainer(
        selected: isSelected,
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        borderRadius: KBorderRadius.lg,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? KAppColors.getOnPrimary(context)
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
            const SizedBox(width: KDesignConstants.spacing8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: KAppTextStyles.labelLarge.copyWith(
                color: isSelected
                    ? KAppColors.getOnPrimary(context)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
          const SizedBox(height: KDesignConstants.spacing24),

          // Common points
          if (_comparison!.commonPoints.isNotEmpty) ...[
            _buildSectionHeader('Common Points', Icons.check_circle_outline),
            const SizedBox(height: KDesignConstants.spacing12),
            ..._comparison!.commonPoints.map((point) => _buildPointCard(
              point,
              const Color(0xFF4CAF50),
            )),
            const SizedBox(height: KDesignConstants.spacing24),
          ],

          // Divergent points
          if (_comparison!.divergentPoints.isNotEmpty) ...[
            _buildSectionHeader('Divergent Points', Icons.alt_route),
            const SizedBox(height: KDesignConstants.spacing12),
            ..._comparison!.divergentPoints.map((point) => _buildPointCard(
              point,
              const Color(0xFFFF9800),
            )),
            const SizedBox(height: KDesignConstants.spacing24),
          ],

          if (_backendPerspectives.isNotEmpty) ...[
            _buildSectionHeader('Backend Perspective Snapshot', Icons.hub_outlined),
            const SizedBox(height: KDesignConstants.spacing12),
            if (_aiBiasSummary != null && _aiBiasSummary!.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: KDesignConstants.spacing10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.08),
                  borderRadius: KBorderRadius.md,
                  border: Border.all(
                    color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _aiBiasSummary!,
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
            ..._backendPerspectives.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: KDesignConstants.spacing10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
                  borderRadius: KBorderRadius.lg,
                  border: Border.all(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: KAppTextStyles.bodyMedium.copyWith(
                              color: KAppColors.getOnBackground(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.sourceName,
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.biasDirection,
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: KAppColors.getPrimary(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          item.sentiment,
                          style: KAppTextStyles.labelSmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing24),
          ],

          // Perspective articles
          _buildSectionHeader('Different Perspectives', Icons.auto_awesome),
          const SizedBox(height: KDesignConstants.spacing16),

          // Left perspective
          _buildPerspectiveSection(
            'Left Perspective',
            _comparison!.leftPerspective,
            BiasIndicator.leftLeaning,
          ),
          const SizedBox(height: KDesignConstants.spacing16),

          // Center perspective
          _buildPerspectiveSection(
            'Center Perspective',
            _comparison!.centerPerspective,
            BiasIndicator.center,
          ),
          const SizedBox(height: KDesignConstants.spacing16),

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
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: KDesignConstants.paddingMd,
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
          const SizedBox(width: KDesignConstants.spacing16),
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
                const SizedBox(height: KDesignConstants.spacing4),
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
        const SizedBox(width: KDesignConstants.spacing12),
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
        padding: KDesignConstants.paddingMd,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: KBorderRadius.md,
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
            const SizedBox(width: KDesignConstants.spacing12),
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
            const SizedBox(width: KDesignConstants.spacing12),
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
        const SizedBox(height: KDesignConstants.spacing12),
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
              const SizedBox(height: KDesignConstants.spacing8),
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
            const SizedBox(height: KDesignConstants.spacing16),
            Text(
              'Not enough perspectives',
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing8),
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
