import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/utils/image_utils.dart';

/// The type of content the image represents, used for selecting appropriate fallback icons.
enum ImageContentType {
  /// A news article image.
  article,

  /// A podcast cover image.
  podcast,

  /// A user avatar/profile picture.
  avatar,

  /// A news source/publisher logo.
  source,

  /// A generic image.
  generic,
}

/// A consistent network image widget with loading shimmer and error fallback.
///
/// Handles loading states, error states, and provides appropriate fallback
/// icons based on the content type.
///
/// ## Basic Usage:
/// ```dart
/// NetworkImageWithFallback(
///   imageUrl: article.imageUrl,
///   contentType: ImageContentType.article,
/// )
/// ```
///
/// ## With custom dimensions:
/// ```dart
/// NetworkImageWithFallback(
///   imageUrl: podcast.imageUrl,
///   contentType: ImageContentType.podcast,
///   width: 150,
///   height: 150,
///   borderRadius: KBorderRadius.lg,
/// )
/// ```
///
/// ## Avatar style:
/// ```dart
/// NetworkImageWithFallback(
///   imageUrl: user.avatarUrl,
///   contentType: ImageContentType.avatar,
///   width: 48,
///   height: 48,
///   isCircular: true,
/// )
/// ```
class NetworkImageWithFallback extends StatelessWidget {
  /// The URL of the image to load.
  final String? imageUrl;

  /// The type of content this image represents.
  final ImageContentType contentType;

  /// The width of the image container.
  final double? width;

  /// The height of the image container.
  final double? height;

  /// The border radius of the image.
  /// Defaults to [KBorderRadius.md] (12.0).
  final BorderRadius? borderRadius;

  /// Whether to display as a circle (for avatars).
  /// Overrides borderRadius when true.
  final bool isCircular;

  /// How the image should be fitted within its container.
  /// Defaults to [BoxFit.cover].
  final BoxFit fit;

  /// Optional color filter to apply to the image.
  final Color? color;

  /// Blend mode for the optional color filter.
  final BlendMode? colorBlendMode;

  /// Alignment for the underlying image.
  final AlignmentGeometry alignment;

  /// Filter quality for the image.
  final FilterQuality filterQuality;

  /// Optional custom loading builder.
  final ImageLoadingBuilder? loadingBuilder;

  /// Optional custom error builder.
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Custom fallback icon to display on error.
  /// If null, uses an appropriate icon based on contentType.
  final IconData? fallbackIcon;

  /// Custom background color for the fallback container.
  final Color? fallbackBackgroundColor;

  /// Custom icon color for the fallback.
  final Color? fallbackIconColor;

  /// The size of the fallback icon.
  /// If null, automatically calculated based on container size.
  final double? fallbackIconSize;

  /// Whether to show a shimmer loading effect.
  /// Defaults to true.
  final bool showShimmer;

  /// Creates a network image with fallback widget.
  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    this.contentType = ImageContentType.generic,
    this.width,
    this.height,
    this.borderRadius,
    this.isCircular = false,
    this.fit = BoxFit.cover,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.loadingBuilder,
    this.errorBuilder,
    this.fallbackIcon,
    this.fallbackBackgroundColor,
    this.fallbackIconColor,
    this.fallbackIconSize,
    this.showShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = isCircular
        ? BorderRadius.circular(999)
        : (borderRadius ?? KBorderRadius.md);

    // If no valid URL, show fallback immediately
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback(context, effectiveBorderRadius);
    }

    final imageProvider = resolveImageProvider(imageUrl);
    if (imageProvider == null) {
      return _buildFallback(context, effectiveBorderRadius);
    }

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: Container(
        width: width,
        height: height,
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
        child: Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          color: color,
          colorBlendMode: colorBlendMode,
          filterQuality: filterQuality,
          loadingBuilder: loadingBuilder ??
              (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                if (!showShimmer) {
                  return _buildLoadingIndicator(context);
                }
                return _buildShimmer(context, effectiveBorderRadius);
              },
          errorBuilder: errorBuilder ??
              (context, error, stackTrace) {
                return _buildFallback(context, effectiveBorderRadius);
              },
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context, BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
      ),
      child: _ShimmerEffect(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
      child: Center(
        child: SizedBox(
          width: _calculateIconSize() / 2,
          height: _calculateIconSize() / 2,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              KAppColors.getPrimary(context).withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, BorderRadius radius) {
    final iconColor = fallbackIconColor ??
        KAppColors.getOnBackground(context).withValues(alpha: 0.3);
    final bgColor = fallbackBackgroundColor ??
        KAppColors.getOnBackground(context).withValues(alpha: 0.08);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: bgColor,
      ),
      child: Center(
        child: Icon(
          fallbackIcon ?? _getIconForContentType(),
          size: fallbackIconSize ?? _calculateIconSize(),
          color: iconColor,
        ),
      ),
    );
  }

  IconData _getIconForContentType() {
    switch (contentType) {
      case ImageContentType.article:
        return Icons.article_outlined;
      case ImageContentType.podcast:
        return Icons.podcasts;
      case ImageContentType.avatar:
        return Icons.person;
      case ImageContentType.source:
        return Icons.newspaper_outlined;
      case ImageContentType.generic:
        return Icons.image_outlined;
    }
  }

  double _calculateIconSize() {
    if (fallbackIconSize != null) return fallbackIconSize!;

    // Calculate based on container size
    final minDimension = (width != null && height != null)
        ? (width! < height! ? width! : height!)
        : (width ?? height ?? 48);

    // Icon should be roughly 40-50% of container size
    return (minDimension * 0.45).clamp(16.0, 64.0);
  }
}

/// Internal shimmer effect widget
class _ShimmerEffect extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerEffect({
    required this.width,
    required this.height,
  });

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = KAppColors.getOnBackground(context).withValues(alpha: 0.08);
    final shimmerColor = KAppColors.getOnBackground(context).withValues(alpha: 0.15);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animation.value, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                baseColor,
                shimmerColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A pre-configured image widget for article thumbnails.
///
/// ## Usage:
/// ```dart
/// ArticleThumbnail(
///   imageUrl: article.imageUrl,
///   width: 120,
///   height: 80,
/// )
/// ```
class ArticleThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const ArticleThumbnail({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkImageWithFallback(
      imageUrl: imageUrl,
      contentType: ImageContentType.article,
      width: width,
      height: height,
      borderRadius: borderRadius ?? KBorderRadius.md,
      fit: fit,
    );
  }
}

/// A pre-configured image widget for podcast cover art.
///
/// ## Usage:
/// ```dart
/// PodcastCoverImage(
///   imageUrl: podcast.imageUrl,
///   size: 150,
/// )
/// ```
class PodcastCoverImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final BorderRadius? borderRadius;

  const PodcastCoverImage({
    super.key,
    required this.imageUrl,
    this.size = 80,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkImageWithFallback(
      imageUrl: imageUrl,
      contentType: ImageContentType.podcast,
      width: size,
      height: size,
      borderRadius: borderRadius ?? KBorderRadius.lg,
    );
  }
}

/// A pre-configured image widget for source/publisher logos.
///
/// ## Usage:
/// ```dart
/// SourceLogo(
///   imageUrl: article.sourceIcon,
///   size: 40,
/// )
/// ```
class SourceLogo extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool isCircular;

  const SourceLogo({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkImageWithFallback(
      imageUrl: imageUrl,
      contentType: ImageContentType.source,
      width: size,
      height: size,
      isCircular: isCircular,
      borderRadius: isCircular ? null : KBorderRadius.sm,
    );
  }
}

/// A pre-configured image widget for user avatars.
///
/// ## Usage:
/// ```dart
/// UserAvatar(
///   imageUrl: user.photoUrl,
///   size: 48,
/// )
/// ```
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkImageWithFallback(
      imageUrl: imageUrl,
      contentType: ImageContentType.avatar,
      width: size,
      height: size,
      isCircular: true,
    );
  }
}
