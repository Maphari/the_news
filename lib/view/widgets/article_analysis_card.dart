import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/ai_analysis_service.dart';

/// Widget to display AI analysis results for an article
class ArticleAnalysisCard extends StatelessWidget {
  const ArticleAnalysisCard({
    super.key,
    required this.analysis,
  });

  final ArticleAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: KAppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: KAppColors.getPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Credibility Score
            _buildCredibilitySection(context),
            const Divider(height: 24),

            // Fact Check Rating
            _buildFactCheckSection(context),
            const Divider(height: 24),

            // Sentiment & Bias
            Row(
              children: [
                Expanded(child: _buildSentimentSection(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildBiasSection(context)),
              ],
            ),

            // Red Flags
            if (analysis.hasRedFlags) ...[
              const Divider(height: 24),
              _buildRedFlagsSection(context),
            ],

            // Key Claims
            if (analysis.keyClaims.isNotEmpty) ...[
              const Divider(height: 24),
              _buildKeyClaimsSection(context),
            ],

            // Credibility Signals
            if (analysis.credibilitySignals.isNotEmpty) ...[
              const Divider(height: 24),
              _buildCredibilitySignalsSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCredibilitySection(BuildContext context) {
    final score = analysis.credibilityScore;
    final color = score >= 70
        ? Colors.green
        : score >= 40
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Credibility',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: KAppColors.getOnBackground(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFactCheckSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.fact_check,
              size: 16,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              'Fact-Check Rating',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KAppColors.getOnBackground(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final isFilled = index < analysis.factCheckRating;
            return Icon(
              isFilled ? Icons.star : Icons.star_border,
              color: isFilled ? Colors.amber : Colors.grey,
              size: 24,
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          analysis.factCheckExplanation,
          style: TextStyle(
            fontSize: 13,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSentimentSection(BuildContext context) {
    final color = analysis.sentiment == 'positive'
        ? Colors.green
        : analysis.sentiment == 'negative'
            ? Colors.red
            : Colors.grey;

    final icon = analysis.sentiment == 'positive'
        ? Icons.sentiment_satisfied
        : analysis.sentiment == 'negative'
            ? Icons.sentiment_dissatisfied
            : Icons.sentiment_neutral;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sentiment',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: KAppColors.getOnBackground(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              analysis.sentiment.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBiasSection(BuildContext context) {
    final color = analysis.biasDirection == 'left'
        ? Colors.blue
        : analysis.biasDirection == 'right'
            ? Colors.red
            : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bias',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: KAppColors.getOnBackground(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '${analysis.biasDirection.toUpperCase()} (${analysis.biasStrength})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRedFlagsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.red,
            ),
            const SizedBox(width: 6),
            Text(
              'Red Flags',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...analysis.redFlags.map((flag) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      flag,
                      style: TextStyle(
                        fontSize: 13,
                        color: KAppColors.getOnBackground(context)
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildKeyClaimsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.checklist_rtl,
              size: 16,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              'Key Claims',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KAppColors.getOnBackground(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...analysis.keyClaims.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: KAppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: KAppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: KAppColors.getOnBackground(context)
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCredibilitySignalsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.verified,
              size: 16,
              color: Colors.green,
            ),
            const SizedBox(width: 6),
            Text(
              'Credibility Signals',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KAppColors.getOnBackground(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: analysis.credibilitySignals.map((signal) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Text(
                signal,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
