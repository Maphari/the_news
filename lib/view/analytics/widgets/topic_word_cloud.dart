import 'dart:math';
import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';

/// Word cloud visualization for trending topics
class TopicWordCloud extends StatelessWidget {
  const TopicWordCloud({
    super.key,
    required this.topics,
    this.maxWords = 30,
  });

  /// Map of topic to frequency
  final Map<String, int> topics;

  /// Maximum number of words to display
  final int maxWords;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(KDesignConstants.spacing32),
          child: Text('No topic data available'),
        ),
      );
    }

    // Sort by frequency and take top N
    final sortedTopics = topics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final displayTopics =
        sortedTopics.take(min(maxWords, sortedTopics.length)).toList();

    final maxFreq = displayTopics.first.value;
    final minFreq = displayTopics.last.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: KDesignConstants.cardPadding,
          child: Text(
            'Trending Topics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: KAppColors.getOnBackground(context),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: KDesignConstants.cardPadding,
          child: Wrap(
            spacing: KDesignConstants.spacing12,
            runSpacing: KDesignConstants.spacing12,
            alignment: WrapAlignment.center,
            children: displayTopics.map((entry) {
              final normalized = _normalize(
                entry.value.toDouble(),
                minFreq.toDouble(),
                maxFreq.toDouble(),
              );
              return _WordChip(
                word: entry.key,
                frequency: entry.value,
                normalized: normalized,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  double _normalize(double value, double min, double max) {
    if (max == min) return 1.0;
    return (value - min) / (max - min);
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({
    required this.word,
    required this.frequency,
    required this.normalized,
  });

  final String word;
  final int frequency;
  final double normalized;

  @override
  Widget build(BuildContext context) {
    // Font size from 12 to 32
    final fontSize = 12.0 + (normalized * 20.0);

    // Opacity from 0.5 to 1.0
    final opacity = 0.5 + (normalized * 0.5);

    // Color variation
    final color = _getColorForWord(word, context).withValues(alpha: opacity);

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$word: $frequency articles'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: KBorderRadius.xl,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: KDesignConstants.spacing8 + (normalized * KDesignConstants.spacing8),
          vertical: KDesignConstants.spacing4 + (normalized * KDesignConstants.spacing4),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          word,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Color _getColorForWord(String word, BuildContext context) {
    // Generate consistent color based on word hash
    final hash = word.hashCode.abs();
    final colors = [
      KAppColors.getPrimary(context),
      KAppColors.blue,
      KAppColors.purple,
      KAppColors.orange,
      KAppColors.cyan,
      KAppColors.pink,
      KAppColors.getTertiary(context),
      KAppColors.getSecondary(context),
    ];

    return colors[hash % colors.length];
  }
}

/// Alternative grid-based word cloud layout
class GridWordCloud extends StatelessWidget {
  const GridWordCloud({
    super.key,
    required this.topics,
  });

  final Map<String, int> topics;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return const Center(child: Text('No topics available'));
    }

    final sortedTopics = topics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: KDesignConstants.cardPadding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: KDesignConstants.spacing12,
        mainAxisSpacing: KDesignConstants.spacing12,
        childAspectRatio: 2,
      ),
      itemCount: min(15, sortedTopics.length),
      itemBuilder: (context, index) {
        final entry = sortedTopics[index];
        return _TopicCard(
          topic: entry.key,
          count: entry.value,
          rank: index + 1,
        );
      },
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.count,
    required this.rank,
  });

  final String topic;
  final int count;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;

    return Container(
      padding: KDesignConstants.cardPaddingCompact,
      decoration: BoxDecoration(
        gradient: isTop3
            ? LinearGradient(
                colors: [
                  KAppColors.getPrimary(context).withValues(alpha: 0.2),
                  KAppColors.getPrimary(context).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isTop3
            ? null
            : KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: KBorderRadius.md,
        border: Border.all(
          color: isTop3
              ? KAppColors.getPrimary(context).withValues(alpha: 0.3)
              : KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isTop3)
            Icon(
              Icons.trending_up,
              size: 16,
              color: KAppColors.getPrimary(context),
            ),
          const SizedBox(height: KDesignConstants.spacing4),
          Text(
            topic,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
              color: isTop3
                  ? KAppColors.getPrimary(context)
                  : KAppColors.getOnBackground(context),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
