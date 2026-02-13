import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/view/publisher/publisher_profile_page.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class AuthorRow extends StatefulWidget {
  const AuthorRow({
    super.key,
    required this.authorName,
    this.sourceIcon,
    this.avatarColor,
    this.user,
    this.textColor,
  });

  final String authorName;
  final String? sourceIcon;
  final Color? avatarColor;
  final RegisterLoginUserSuccessModel? user;
  final Color? textColor;

  @override
  State<AuthorRow> createState() => _AuthorRowState();
}

class _AuthorRowState extends State<AuthorRow> {
  final FollowedPublishersService _followedPublishersService = FollowedPublishersService.instance;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    // Listen to service changes to update UI reactively
    _followedPublishersService.addListener(_onFollowedPublishersChanged);
  }

  @override
  void dispose() {
    _followedPublishersService.removeListener(_onFollowedPublishersChanged);
    super.dispose();
  }

  void _onFollowedPublishersChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleFollowToggle() async {
    if (_isFollowing || widget.user == null) return;

    setState(() => _isFollowing = true);

    await _followedPublishersService.toggleFollow(
      widget.user!.userId,
      widget.authorName,
    );

    if (mounted) {
      setState(() => _isFollowing = false);
    }
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';

    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  void _navigateToPublisherPage() {
    if (widget.user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublisherProfilePage(
          publisherName: widget.authorName,
          publisherIcon: widget.sourceIcon,
          user: widget.user!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFollowed = _followedPublishersService.isPublisherFollowed(widget.authorName);

    return Row(
      children: [
        // Publisher avatar with image or initials - Clickable
        GestureDetector(
          onTap: _navigateToPublisherPage,
          child: widget.sourceIcon != null && widget.sourceIcon!.isNotEmpty
            ? CircleAvatar(
                backgroundColor: widget.avatarColor ?? KAppColors.getPrimary(context),
                radius: 20,
                child: ClipOval(
                  child: SafeNetworkImage(
                    widget.sourceIcon!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to initials on error
                      return Center(
                        child: Text(
                          _getInitials(widget.authorName),
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? KAppColors.darkBackground
                                : KAppColors.darkOnBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            : CircleAvatar(
                backgroundColor: widget.avatarColor ?? KAppColors.getPrimary(context),
                radius: 20,
                child: Text(
                  _getInitials(widget.authorName),
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? KAppColors.darkBackground
                        : KAppColors.darkOnBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        ),
        const SizedBox(width: KDesignConstants.spacing12),
        Expanded(
          child: GestureDetector(
            onTap: _navigateToPublisherPage,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Published by',
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: (widget.textColor ?? KAppColors.darkBackground).withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  widget.authorName,
                  style: KAppTextStyles.titleSmall.copyWith(
                    color: widget.textColor ?? KAppColors.darkBackground,
                    decoration: TextDecoration.underline,
                    decorationColor: (widget.textColor ?? KAppColors.darkBackground).withValues(alpha: 0.3),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        if (widget.user != null)
          _isFollowing
            ? SizedBox(
                width: 80,
                height: 32,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(widget.avatarColor ?? (widget.textColor ?? KAppColors.darkBackground)),
                    ),
                  ),
                ),
              )
            : Builder(
                builder: (context) => ElevatedButton(
                  onPressed: _handleFollowToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowed
                        ? (widget.textColor ?? KAppColors.darkBackground).withValues(alpha: 0.15)
                        : widget.avatarColor ?? (widget.textColor ?? KAppColors.darkBackground),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: Text(
                    isFollowed ? 'Following' : 'Follow',
                    style: KAppTextStyles.labelLarge.copyWith(
                      color: isFollowed ? (widget.textColor ?? KAppColors.darkBackground) : KAppColors.darkOnBackground,
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
