import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:flutter/material.dart';

class NavIcon extends StatelessWidget {
  const NavIcon({
    super.key,
    required this.outlinedIcon,
    required this.filledIcon,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  final IconData outlinedIcon;
  final IconData filledIcon;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  bool get isSelected => selectedIndex == index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 28 : 28,
          vertical: isSelected ? 14 : 14,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    KAppColors.darkOnBackground,
                    KAppColors.darkOnBackground.withValues(alpha: 0.9),
                  ],
                )
              : null,
          borderRadius: KBorderRadius.full,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          isSelected ? filledIcon : outlinedIcon,
          color: isSelected
              ? KAppColors.darkBackground
              : KAppColors.darkOnBackground.withValues(alpha: 0.6),
          size: 24,
        ),
      ),
    );
  }
}