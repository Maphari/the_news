import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/daily_digest_model.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Card displaying a daily digest
class DigestCard extends StatelessWidget {
  const DigestCard({
    super.key,
    required this.digest,
    required this.onTap,
    this.onDelete,
  });

  final DailyDigest digest;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(digest.generatedAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: KAppColors.getBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday
                ? KAppColors.getPrimary(context).withValues(alpha: 0.3)
                : KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            width: isToday ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isToday
                    ? KAppColors.getPrimary(context).withValues(alpha: 0.05)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.02),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: isToday
                        ? KAppColors.getPrimary(context)
                        : KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          digest.title,
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeago.format(digest.generatedAt),
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  Text(
                    digest.summary,
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Metadata
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildMetaChip(
                        context,
                        Icons.article_outlined,
                        '${digest.items.length} stories',
                      ),
                      _buildMetaChip(
                        context,
                        Icons.schedule_outlined,
                        '${digest.estimatedReadingMinutes} min read',
                      ),
                      if (digest.isRead)
                        _buildMetaChip(
                          context,
                          Icons.check_circle,
                          'Read',
                          color: const Color(0xFF4CAF50),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Read button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          digest.isRead ? 'Read again' : 'Read digest',
                          style: KAppTextStyles.labelMedium.copyWith(
                            color: KAppColors.getPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: KAppColors.getPrimary(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(
    BuildContext context,
    IconData icon,
    String label, {
    Color? color,
  }) {
    final chipColor = color ?? KAppColors.getOnBackground(context).withValues(alpha: 0.5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: chipColor,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: KAppTextStyles.bodySmall.copyWith(
            color: chipColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
