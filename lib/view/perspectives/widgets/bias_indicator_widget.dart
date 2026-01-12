import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/story_cluster_model.dart';

/// Widget displaying bias indicator badge
class BiasIndicatorWidget extends StatelessWidget {
  const BiasIndicatorWidget({
    super.key,
    required this.bias,
    this.showLabel = true,
    this.compact = false,
  });

  final BiasIndicator bias;
  final bool showLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color(bias.colorValue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(bias.colorValue).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color(bias.colorValue),
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              bias.label,
              style: KAppTextStyles.labelSmall.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Tooltip(
      message: bias.label,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Color(bias.colorValue),
          shape: BoxShape.circle,
          border: Border.all(
            color: KAppColors.getBackground(context),
            width: 2,
          ),
        ),
      ),
    );
  }
}
