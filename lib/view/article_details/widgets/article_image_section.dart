import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class ArticleImageSection extends StatelessWidget {
  const ArticleImageSection({
    super.key,
    required this.imageUrl,
    required this.isLiked,
    required this.isBookmarked,
    required this.onLikePressed,
    required this.onBookmarkPressed,
    required this.onSharePressed,
  });

  final String imageUrl;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback onLikePressed;
  final VoidCallback onBookmarkPressed;
  final VoidCallback onSharePressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: KBorderRadius.xxl,
      child: Stack(
        children: [
          // Image
          AspectRatio(
            aspectRatio: 16 / 10,
            child: imageUrl.isNotEmpty
                ? SafeNetworkImage(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                        child: const Icon(Icons.image, size: 64),
                      );
                    },
                  )
                : Container(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                    child: const Icon(Icons.image, size: 64),
                  ),
          ),

          // Action buttons overlay
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  onPressed: onLikePressed,
                  isActive: isLiked,
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                _buildActionButton(
                  icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  onPressed: onBookmarkPressed,
                  isActive: isBookmarked,
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                _buildActionButton(
                  icon: Icons.share,
                  onPressed: onSharePressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: KDesignConstants.paddingSm,
        decoration: BoxDecoration(
          color: KAppColors.imageScrim.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(
          icon,
          color: isActive ? KAppColors.error : KAppColors.onImage,
          size: 22,
        ),
      ),
    );
  }
}
