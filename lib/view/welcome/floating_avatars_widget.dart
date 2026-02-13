import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/data/avatar_data.dart';
import 'package:the_news/utils/avator_color_util.dart';
import 'package:the_news/view/widgets/safe_network_image.dart';

class FloatingAvatars extends StatefulWidget {
  const FloatingAvatars({super.key});

  @override
  State<FloatingAvatars> createState() => _FloatingAvatarsState();
}

class _FloatingAvatarsState extends State<FloatingAvatars>
    with TickerProviderStateMixin {
  //? List of animation controllers and animations for each avatar
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    //? Initialize animation controllers and animations for each avatar
    _controllers = List.generate(
      avatars.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 2000 + (index * 150)),
        vsync: this,
      )..repeat(reverse: true),
    );

    //? Create floating animations
    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: -8,
        end: 8,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();
  }

  @override
  void dispose() {
    //? Dispose all animation controllers
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    //? Stack avatars based on their relative positions
    return Stack(
      children: List.generate(avatars.length, (index) {
        final avatar = avatars[index];
        final left = size.width * avatar.left;
        final top = size.height * avatar.top;

        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Positioned(
              left: left - (avatar.size / 2), //? Center the avatar horizontally
              top: top + _animations[index].value, //? Apply floating effect
              child: Container(
                width: avatar.size,
                height: avatar.size,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KAppColors.darkOnBackground,
                  // border: Border.all(
                  //   color: KAppColors.getBackground(context).withValues(alpha: 0.3),
                  //   width: 2,
                  // ),
                  boxShadow: [
                    BoxShadow(
                      color: KAppColors.darkBackground.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: avatar.size,
                  height: avatar.size,
                  child: ClipOval(
                    child: Padding(
                      padding: EdgeInsets.all(avatar.size * 0.15),
                      child: SafeNetworkImage(
                        avatar.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to colored circle with brand initials
                          return Container(
                            color: getAvatarColor(index),
                            child: Center(
                              child: Text(
                                avatar.brandName,
                                style: KAppTextStyles.bodySmall.copyWith(
                                  color: KAppColors.getBackground(context),
                                  fontSize: avatar.size * 0.25,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: getAvatarColor(index).withValues(alpha: 0.3),
                            child: Center(
                              child: SizedBox(
                                width: avatar.size * 0.3,
                                height: avatar.size * 0.3,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    getAvatarColor(index),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
