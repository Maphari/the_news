import 'package:flutter/material.dart';

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
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Image
          AspectRatio(
            aspectRatio: 16 / 10,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, size: 64),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade300,
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
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  onPressed: onBookmarkPressed,
                  isActive: isBookmarked,
                ),
                const SizedBox(width: 12),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.red : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
