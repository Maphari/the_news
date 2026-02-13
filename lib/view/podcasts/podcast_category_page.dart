import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/podcast_model.dart';
import 'package:the_news/service/podcast_service.dart';
import 'package:the_news/view/podcasts/widgets/podcast_card.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';

class PodcastCategoryPage extends StatefulWidget {
  const PodcastCategoryPage({
    super.key,
    required this.title,
    required this.category,
  });

  final String title;
  final String category;

  @override
  State<PodcastCategoryPage> createState() => _PodcastCategoryPageState();
}

class _PodcastCategoryPageState extends State<PodcastCategoryPage> {
  final PodcastService _podcastService = PodcastService.instance;
  bool _isLoading = true;
  List<Podcast> _podcasts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _podcastService.searchPodcasts(
        query: '',
        category: widget.category == 'All' ? null : widget.category,
      );
      if (!mounted) return;
      setState(() {
        _podcasts = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: KAppBar(
        title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    'Could not load podcasts.',
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(KDesignConstants.spacing16),
                  itemBuilder: (context, index) {
                    final podcast = _podcasts[index];
                    return PodcastCard(
                      podcast: podcast,
                      onTap: () {
                        // Parent page handles navigation in PodcastCard itself
                      },
                    );
                  },
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: KDesignConstants.spacing12),
                  itemCount: _podcasts.length,
                ),
    );
  }
}
