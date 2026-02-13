import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search...',
    this.showClear = true,
    this.trailing,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool showClear;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: KBorderRadius.lg,
      color: Colors.transparent,
      child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KDesignConstants.spacing16,
        vertical: KDesignConstants.spacing4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KAppColors.getPrimary(context).withValues(alpha: 0.08),
            KAppColors.getTertiary(context).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: KBorderRadius.lg,
        border: Border.all(
          color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: KAppColors.getPrimary(context).withValues(alpha: 0.7),
            size: 22,
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: KAppTextStyles.bodyLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
                  fontSize: 15,
                ),
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: KDesignConstants.spacing12,
                ),
              ),
            ),
          ),
          if (showClear && controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Container(
                padding: const EdgeInsets.all(KDesignConstants.spacing8),
                decoration: BoxDecoration(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: KAppColors.getPrimary(context),
                  size: 16,
                ),
              ),
            )
          else if (trailing != null)
            trailing!,
        ],
      ),
    ));
  }
}
