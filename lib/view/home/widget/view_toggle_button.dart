import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';

enum ViewMode { cardStack, compactList }

class ViewToggleButton extends StatelessWidget {
  const ViewToggleButton({
    super.key,
    required this.currentMode,
    required this.onToggle,
    this.width = 260,
    this.height = 92,
    this.iconSize = 24,
  });

  final ViewMode currentMode;
  final ValueChanged<ViewMode> onToggle;
  final double width;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isCards = currentMode == ViewMode.cardStack;
    final borderRadius = BorderRadius.circular(KDesignConstants.radiusXl);
    final background = KAppColors.getOnBackground(context).withValues(alpha: 0.06);

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: borderRadius,
          border: Border.all(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildSegment(
              context: context,
              borderRadius: borderRadius,
              mode: ViewMode.cardStack,
              icon: Icons.layers_outlined,
              title: 'Card stack',
              hint: 'Immersive reading',
              isSelected: isCards,
            ),
            _buildSegment(
              context: context,
              borderRadius: borderRadius,
              mode: ViewMode.compactList,
              icon: Icons.view_list,
              title: 'List view',
              hint: 'Fast browsing',
              isSelected: !isCards,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required BorderRadius borderRadius,
    required ViewMode mode,
    required IconData icon,
    required String title,
    required String hint,
    required bool isSelected,
  }) {
    final primaryColor = KAppColors.getPrimary(context);
    final onPrimary = KAppColors.getOnPrimary(context);
    final neutralText = KAppColors.getOnBackground(context).withValues(alpha: 0.7);
    return Expanded(
      child: Semantics(
        button: true,
        label: title,
        hint: hint,
        selected: isSelected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            focusColor: primaryColor.withValues(alpha: 0.2),
            highlightColor: primaryColor.withValues(alpha: 0.12),
            onTap: isSelected ? null : () => onToggle(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                color: isSelected ? primaryColor.withValues(alpha: 0.15) : null,
                borderRadius: borderRadius,
                border: Border.all(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: isSelected ? 1.2 : 0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: iconSize,
                    color: isSelected ? onPrimary : neutralText,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? onPrimary : neutralText,
                    ),
                  ),
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? onPrimary.withValues(alpha: 0.85)
                          : neutralText.withValues(alpha: 0.75),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
