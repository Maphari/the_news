import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';

//? A reusable widget that displays the app logo within a styled container.
class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key, 
    required this.width,
    required this.height,
    required this.logosize,
  });

  final double width;
  final double height;
  final double logosize;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: KAppColors.getBackground(context),
        borderRadius: KBorderRadius.xl,
      ),
      child: Icon(Icons.article_rounded, size: logosize, color: KAppColors.getSurface(context)),
    );
  }
}
