import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';

class ArticleSentimentCard extends StatelessWidget {
  const ArticleSentimentCard({
    super.key,
    required this.sentiment,
    required this.sentimentStats,
  });

  final String sentiment;
  final SentimentStats sentimentStats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSentimentIcon(),
                color: _getSentimentColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Sentiment Analysis',
                style: KAppTextStyles.titleMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSentimentBar('Positive', sentimentStats.positive, Colors.green, context),
          const SizedBox(height: 12),
          _buildSentimentBar('Neutral', sentimentStats.neutral, Colors.grey, context),
          const SizedBox(height: 12),
          _buildSentimentBar('Negative', sentimentStats.negative, Colors.red, context),
        ],
      ),
    );
  }

  IconData _getSentimentIcon() {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Icons.sentiment_very_satisfied;
      case 'negative':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getSentimentColor() {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSentimentBar(String label, double percentage, Color color, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
