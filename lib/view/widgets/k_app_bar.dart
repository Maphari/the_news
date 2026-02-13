import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/view/widgets/app_back_button.dart';

class KAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.bottom,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool? centerTitle;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double? elevation;
  final double? scrolledUnderElevation;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final resolvedLeading = leading ??
        (automaticallyImplyLeading && Navigator.canPop(context)
            ? const AppBackButton()
            : null);
    final resolvedTitle = _resolveTitle(context);
    return AppBar(
      title: resolvedTitle,
      actions: actions,
      leading: resolvedLeading,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? KAppColors.getBackground(context),
      elevation: elevation ?? 0,
      scrolledUnderElevation: scrolledUnderElevation ?? 0,
      surfaceTintColor: Colors.transparent,
      bottom: bottom,
    );
  }

  Widget? _resolveTitle(BuildContext context) {
    if (title == null) return null;
    if (title is Text) {
      final text = title as Text;
      final baseStyle = KAppTextStyles.headlineSmall.copyWith(
        color: KAppColors.getOnBackground(context),
      );
      final merged = baseStyle.merge(text.style).copyWith(
            fontFamily: KAppTextStyles.headlineSmall.fontFamily,
            fontWeight: text.style?.fontWeight ?? baseStyle.fontWeight,
          );
      return Text(
        text.data ?? '',
        key: text.key,
        style: merged,
        maxLines: text.maxLines,
        overflow: text.overflow,
        textAlign: text.textAlign,
        softWrap: text.softWrap,
        textDirection: text.textDirection,
        locale: text.locale,
        strutStyle: text.strutStyle,
        textWidthBasis: text.textWidthBasis,
        textHeightBehavior: text.textHeightBehavior,
        semanticsLabel: text.semanticsLabel,
      );
    }
    return DefaultTextStyle.merge(
      style: KAppTextStyles.headlineSmall.copyWith(
        color: KAppColors.getOnBackground(context),
      ),
      child: title!,
    );
  }
}
