import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/daily_digest_service.dart';
import 'package:the_news/view/digest/widgets/digest_card.dart';
import 'package:the_news/view/digest/widgets/digest_empty_state.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/digest/digest_reader_page.dart';
import 'package:the_news/view/digest/digest_settings_page.dart';

/// Page showing daily news digests
class DailyDigestPage extends StatefulWidget {
  const DailyDigestPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<DailyDigestPage> createState() => _DailyDigestPageState();
}

class _DailyDigestPageState extends State<DailyDigestPage> {
  final DailyDigestService _digestService = DailyDigestService.instance;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_digestService.digests.isEmpty) {
      await _digestService.initializeForUser(widget.userId);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _generateDigest() async {
    final digest = await _digestService.generateDigest(widget.userId);
    if (digest != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DigestReaderPage(digest: digest),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
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
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Digest',
                  style: KAppTextStyles.headlineMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 22
                  ),
                ),
                const SizedBox(height: KDesignConstants.spacing4),
                Text(
                  'AI-powered personalized news summaries',
                  style: KAppTextStyles.bodySmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DigestSettingsPage(),
                ),
              );
            },
            icon: Icon(
              Icons.settings_outlined,
              color: KAppColors.getPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListenableBuilder(
      listenable: _digestService,
      builder: (context, _) {
        if (_digestService.isGenerating) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: KAppColors.getPrimary(context),
                ),
                const SizedBox(height: KDesignConstants.spacing16),
                Text(
                  'Generating your digest...',
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        final digests = _digestService.digests;

        if (digests.isEmpty) {
          return DigestEmptyState(
            onGenerate: _generateDigest,
          );
        }

        return RefreshIndicator(
          onRefresh: () => _digestService.syncFromBackend(widget.userId),
          color: KAppColors.getPrimary(context),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: digests.length,
            itemBuilder: (context, index) {
              final digest = digests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DigestCard(
                  digest: digest,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DigestReaderPage(digest: digest),
                      ),
                    );
                  },
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Digest?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _digestService.deleteDigest(
                        digest.digestId,
                        userId: widget.userId,
                      );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget? _buildFab() {
    return ListenableBuilder(
      listenable: _digestService,
      builder: (context, _) {
        if (_digestService.isGenerating) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: _generateDigest,
          backgroundColor: KAppColors.getPrimary(context),
          icon: const Icon(Icons.auto_awesome, color: KAppColors.darkOnBackground),
          label: Text(
            _digestService.hasTodayDigest ? 'Regenerate' : 'Generate Today',
            style: const TextStyle(color: KAppColors.darkOnBackground, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
