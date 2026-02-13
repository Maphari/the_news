import 'package:flutter/material.dart';
import 'package:the_news/view/widgets/network_image_with_fallback.dart';

/// Drop-in replacement for Image.network with consistent fallback handling.
class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool isCircular;
  final ImageContentType contentType;
  final AlignmentGeometry alignment;
  final Color? color;
  final BlendMode? colorBlendMode;
  final bool showShimmer;
  final FilterQuality filterQuality;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  const SafeNetworkImage(
    this.imageUrl, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircular = false,
    this.contentType = ImageContentType.generic,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode,
    this.showShimmer = true,
    this.filterQuality = FilterQuality.medium,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkImageWithFallback(
      imageUrl: imageUrl,
      contentType: contentType,
      width: width,
      height: height,
      borderRadius: borderRadius,
      isCircular: isCircular,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      showShimmer: showShimmer,
      filterQuality: filterQuality,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
