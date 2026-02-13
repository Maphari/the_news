import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/story_cluster_model.dart';
import 'package:the_news/service/story_clustering_service.dart';
import 'package:the_news/view/perspectives/widgets/story_cluster_card.dart';
import 'package:the_news/view/perspectives/widgets/perspective_filter_chips.dart';
import 'package:the_news/view/widgets/app_back_button.dart';

/// Page showing stories with multiple perspectives
class MultiPerspectivePage extends StatefulWidget {
  const MultiPerspectivePage({super.key});

  @override
  State<MultiPerspectivePage> createState() => _MultiPerspectivePageState();
}

class _MultiPerspectivePageState extends State<MultiPerspectivePage> {
  final StoryClusteringService _clusteringService = StoryClusteringService.instance;
  StoryCategory? _selectedCategory;
  bool _showOnlyMultiPerspective = true;

  @override
  void initState() {
    super.initState();
    _initializeClustering();
  }

  Future<void> _initializeClustering() async {
    if (_clusteringService.storyClusters.isEmpty) {
      await _clusteringService.initialize();
    }
  }

  List<StoryCluster> _getFilteredClusters() {
    List<StoryCluster> clusters;

    // Start with multi-perspective or all clusters
    if (_showOnlyMultiPerspective) {
      clusters = _clusteringService.multiPerspectiveClusters;
    } else {
      clusters = _clusteringService.recentClusters;
    }

    // Filter by category if selected
    if (_selectedCategory != null) {
      clusters = clusters.where((c) => c.category == _selectedCategory).toList();
    }

    return clusters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterSection(),
            Expanded(
              child: _buildClustersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
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
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perspectives',
                      style: KAppTextStyles.headlineMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 22
                      ),
                    ),
                    const SizedBox(height: KDesignConstants.spacing4),
                    Text(
                      'Compare how different sources cover the same story',
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  await _clusteringService.refresh();
                  if (mounted) setState(() {});
                },
                icon: Icon(
                  Icons.refresh,
                  color: KAppColors.getPrimary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Multi-perspective toggle
          Row(
            children: [
              Text(
                'Show only multi-perspective:',
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                ),
              ),
              const Spacer(),
              Switch(
                value: _showOnlyMultiPerspective,
                onChanged: (value) {
                  setState(() {
                    _showOnlyMultiPerspective = value;
                  });
                },
                activeTrackColor: KAppColors.getPrimary(context),
              ),
            ],
          ),
          const SizedBox(height: KDesignConstants.spacing12),

          // Category filters
          PerspectiveFilterChips(
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClustersList() {
    return ListenableBuilder(
      listenable: _clusteringService,
      builder: (context, _) {
        if (_clusteringService.isProcessing) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: KAppColors.getPrimary(context),
                ),
                const SizedBox(height: KDesignConstants.spacing16),
                Text(
                  'Analyzing articles...',
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        final clusters = _getFilteredClusters();

        if (clusters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 64,
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                ),
                const SizedBox(height: KDesignConstants.spacing16),
                Text(
                  _showOnlyMultiPerspective
                      ? 'No multi-perspective stories found'
                      : 'No story clusters found',
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: KDesignConstants.spacing8),
                Text(
                  'Try adjusting your filters or refresh',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _clusteringService.refresh();
          },
          color: KAppColors.getPrimary(context),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: clusters.length,
            itemBuilder: (context, index) {
              final cluster = clusters[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: StoryClusterCard(cluster: cluster),
              );
            },
          ),
        );
      },
    );
  }
}
