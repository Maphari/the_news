import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'nav_icon.dart';

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Container(
        height: 70, 
        margin: EdgeInsets.symmetric(horizontal: KDesignConstants.spacing16, vertical: KDesignConstants.spacing8), 
        child: ClipRRect(
          borderRadius: KBorderRadius.full,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    KAppColors.getOnBackground(context).withValues(alpha: 0.15),
                    KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: KBorderRadius.full,
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  NavIcon(
                    outlinedIcon: Icons.home_outlined,
                    filledIcon: Icons.home_rounded,
                    index: 0,
                    selectedIndex: selectedIndex,
                    onTap: onIndexChanged,
                  ),
                  NavIcon(
                    outlinedIcon: Icons.explore_outlined,
                    filledIcon: Icons.explore,
                    index: 1,
                    selectedIndex: selectedIndex,
                    onTap: onIndexChanged,
                  ),
                  NavIcon(
                    outlinedIcon: Icons.bookmark_outline_rounded,
                    filledIcon: Icons.bookmark_rounded,
                    index: 2,
                    selectedIndex: selectedIndex,
                    onTap: onIndexChanged,
                  ),
                  NavIcon(
                    outlinedIcon: Icons.person_outline_rounded,
                    filledIcon: Icons.person_rounded,
                    index: 3,
                    selectedIndex: selectedIndex,
                    onTap: onIndexChanged,
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