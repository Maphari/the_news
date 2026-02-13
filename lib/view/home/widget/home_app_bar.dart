import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showActions = false,
    this.bottom = 12,
    this.viewToggle,
    this.leading,
    this.footer,
    this.useSafeArea = true,
    this.titleStyle,
    this.subtitleStyle,
    this.footerSpacing = KDesignConstants.spacing12,
    this.subtitleMaxLines = 2,
  });

  final String title;
  final String? subtitle;
  final double bottom;
  final bool showActions;
  final Widget? viewToggle;
  final Widget? leading;
  final Widget? footer;
  final bool useSafeArea;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double footerSpacing;
  final int subtitleMaxLines;

  static double estimatedHeight({
    String? title,
    String? subtitle,
    double bottom = 12,
    double footerHeight = 0,
    double footerSpacing = KDesignConstants.spacing12,
    int subtitleMaxLines = 1,
  }) {
    final hasTitle = (title ?? '').replaceAll(RegExp(r'\\s+'), '').isNotEmpty;
    final hasSubtitle = subtitle != null && subtitle.trim().isNotEmpty;
    final subtitleLines = hasSubtitle
        ? (subtitleMaxLines < 1 ? 1 : subtitleMaxLines)
        : 0;

    const double topPadding = 12;
    const double titleLineHeight = 36;
    const double subtitleLineHeight = 20;

    double height = topPadding + bottom;

    if (!hasTitle && !hasSubtitle) {
      height = 56;
    } else {
      if (hasTitle) {
        height += titleLineHeight;
      }
      if (hasSubtitle) {
        height += (hasTitle ? _titleSpacing : 0) +
            (subtitleLineHeight * subtitleLines);
      }
    }

    if (footerHeight > 0) {
      height += footerSpacing + footerHeight;
    }

    return height + 2;
  }

  static const double _titleSpacing = 6.0;

  @override
  Widget build(BuildContext context) {
    final leftPadding = leading != null ? 0.0 : 16.0;
    final hasTitle = title.replaceAll(RegExp(r'\\s+'), '').isNotEmpty;
    final content = Container(
      padding: EdgeInsets.fromLTRB(leftPadding, 12, 16, bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and optional actions in same row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading icon (hamburger menu)
              if (leading != null) leading!,
              if (leading != null) const SizedBox(width: KDesignConstants.spacing12),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTitle) ...[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle ??
                            KAppTextStyles.headlineMedium.copyWith(
                              color: KAppColors.getOnBackground(context),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      if (hasTitle)
                        const SizedBox(height: _titleSpacing),
                      Text(
                        subtitle!,
                        maxLines: subtitleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle ??
                            KAppTextStyles.bodyMedium.copyWith(
                              color: KAppColors.getOnBackground(context)
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              // View toggle on same row as title (only for home page)
              if (showActions && viewToggle != null) ...[
                const SizedBox(width: KDesignConstants.spacing12),
                viewToggle!,
              ],
            ],
          ),
          if (footer != null) ...[
            SizedBox(height: footerSpacing),
            footer!,
          ],
        ],
      ),
    );

    if (!useSafeArea) return content;
    return SafeArea(
      bottom: false,
      child: content,
    );
  }
}

class PinnedHeaderSliver extends StatelessWidget {
  const PinnedHeaderSliver({
    super.key,
    required this.child,
    required this.height,
    this.includeSafeArea = true,
  });

  final Widget child;
  final double height;
  final bool includeSafeArea;

  @override
  Widget build(BuildContext context) {
    final safeTop = includeSafeArea ? MediaQuery.of(context).padding.top : 0.0;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedHeaderDelegate(
        height: height + safeTop,
        child: child,
      ),
    );
  }
}

class MeasuredPinnedHeaderSliver extends StatefulWidget {
  const MeasuredPinnedHeaderSliver({
    super.key,
    required this.child,
    required this.height,
    this.includeSafeArea = true,
  });

  final Widget child;
  final double height;
  final bool includeSafeArea;

  @override
  State<MeasuredPinnedHeaderSliver> createState() => _MeasuredPinnedHeaderSliverState();
}

class _MeasuredPinnedHeaderSliverState extends State<MeasuredPinnedHeaderSliver> {
  late double _measuredHeight;

  @override
  void initState() {
    super.initState();
    _measuredHeight = widget.height;
  }

  @override
  void didUpdateWidget(MeasuredPinnedHeaderSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.height != oldWidget.height && _measuredHeight == oldWidget.height) {
      _measuredHeight = widget.height;
    }
  }

  void _handleSizeChanged(Size size) {
    if (!mounted) return;
    if (size.height <= 0) return;
    if ((size.height - _measuredHeight).abs() < 0.5) return;
    setState(() => _measuredHeight = size.height);
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = widget.includeSafeArea ? MediaQuery.of(context).padding.top : 0.0;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedHeaderDelegate(
        height: _measuredHeight + safeTop,
        child: MeasureSize(
          onChange: _handleSizeChanged,
          child: widget.child,
        ),
      ),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / height).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (progress > 0)
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 16 * progress,
                sigmaY: 16 * progress,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: KAppColors.getBackground(context)
                      .withValues(alpha: 0.85 * progress),
                  border: Border(
                    bottom: BorderSide(
                      color: KAppColors.getOnBackground(context)
                          .withValues(alpha: 0.06 * progress),
                    ),
                  ),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }

  @override
  bool shouldRebuild(_PinnedHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

typedef _OnWidgetSizeChange = void Function(Size size);

class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({
    super.key,
    required this.onChange,
    required Widget child,
  }) : super(child: child);

  final _OnWidgetSizeChange onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderMeasureSize renderObject) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  _OnWidgetSizeChange onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? size;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
  }
}
