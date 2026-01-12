import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

enum ViewMode { cardStack, compactList }

class ViewToggleButton extends StatelessWidget {
  const ViewToggleButton({
    super.key,
    required this.currentMode,
    required this.onToggle,
  });

  final ViewMode currentMode;
  final ValueChanged<ViewMode> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            icon: Icons.layers_outlined,
            mode: ViewMode.cardStack,
            tooltip: 'Swipe Cards',
          ),
          const SizedBox(width: 4),
          _buildToggleOption(
            icon: Icons.view_list_outlined,
            mode: ViewMode.compactList,
            tooltip: 'List View',
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required ViewMode mode,
    required String tooltip,
  }) {
    return Builder(
      builder: (context) {
        final isSelected = currentMode == mode;

        return Tooltip(
          message: tooltip,
          child: GestureDetector(
            onTap: () => onToggle(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? KAppColors.getPrimary(context).withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? KAppColors.getPrimary(context) : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              ),
            ),
          ),
        );
      }
    );
  }
}
