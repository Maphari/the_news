import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:video_player/video_player.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class ArticleMediaSection extends StatefulWidget {
  const ArticleMediaSection({
    super.key,
    required this.imageUrl,
    this.videoUrl,
    required this.isLiked,
    required this.isBookmarked,
    required this.onLikePressed,
    required this.onBookmarkPressed,
    required this.onSharePressed,
  });

  final String imageUrl;
  final String? videoUrl;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback onLikePressed;
  final VoidCallback onBookmarkPressed;
  final VoidCallback onSharePressed;

  @override
  State<ArticleMediaSection> createState() => _ArticleMediaSectionState();
}

class _ArticleMediaSectionState extends State<ArticleMediaSection> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl!),
      );
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      // Video initialization failed - will show image fallback
      debugPrint('Video initialization failed: $e');
    }
  }

  void _togglePlayPause() {
    if (_videoController == null || !_isVideoInitialized) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: KBorderRadius.xxl,
      child: Stack(
        children: [
          // Media (Image or Video)
          AspectRatio(
            aspectRatio: 16 / 10,
            child: widget.videoUrl != null && widget.videoUrl!.isNotEmpty
                ? _buildVideoPlayer()
                : _buildImage(),
          ),

          // Action buttons overlay
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              children: [
                _buildActionButton(
                  icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                  onPressed: widget.onLikePressed,
                  isActive: widget.isLiked,
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                _buildActionButton(
                  icon: widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  onPressed: widget.onBookmarkPressed,
                  isActive: widget.isBookmarked,
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                _buildActionButton(
                  icon: Icons.share,
                  onPressed: widget.onSharePressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return widget.imageUrl.isNotEmpty
        ? SafeNetworkImage(
            widget.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                child: Center(
                  child: Icon(Icons.image, size: 64, color: KAppColors.darkOnBackground.withValues(alpha: 0.54)),
                ),
              );
            },
          )
        : Container(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
            child: Center(
              child: Icon(Icons.image, size: 64, color: KAppColors.darkOnBackground.withValues(alpha: 0.54)),
            ),
          );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        color: KAppColors.darkBackground,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player or thumbnail
            if (_isVideoInitialized && _videoController != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            else if (widget.imageUrl.isNotEmpty)
              SafeNetworkImage(
                widget.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            else
              Container(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.9),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // Dark overlay when not playing
            if (!_isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: KAppColors.imageScrim.withValues(alpha: 0.3),
                ),
              ),

            // Play/Pause button
            if (_isVideoInitialized)
              AnimatedOpacity(
                opacity: _isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: KAppColors.onImage,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 48,
                    color: KAppColors.imageScrim,
                  ),
                ),
              )
            else
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(KAppColors.onImage),
              ),

            // VIDEO badge
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: KAppColors.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.videocam, color: KAppColors.onImage, size: 16),
                    const SizedBox(width: KDesignConstants.spacing4),
                    const Text(
                      'VIDEO',
                      style: TextStyle(
                        color: KAppColors.onImage,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Video progress indicator
            if (_isVideoInitialized && _videoController != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder(
                  valueListenable: _videoController!,
                  builder: (context, VideoPlayerValue value, child) {
                    if (!value.isInitialized) return const SizedBox.shrink();

                    final position = value.position.inMilliseconds.toDouble();
                    final duration = value.duration.inMilliseconds.toDouble();
                    final progress = duration > 0 ? position / duration : 0.0;

                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: KAppColors.onImage.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(KAppColors.error),
                      minHeight: 3,
                    );
                  },
                ),
              ),
          ],
        ),
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
          border: Border.all(
            color: KAppColors.onImage.withValues(alpha: 0.2),
          ),
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
