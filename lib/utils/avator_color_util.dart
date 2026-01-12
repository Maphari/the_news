import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

Color getAvatarColor(int index) {
    // Using theme colors for fallback avatars
    final colors = [
      KAppColors.primary,
      KAppColors.secondary,
      KAppColors.tertiary,
      const Color(0xFFB8E0D2),
      const Color(0xFFFFD6E8),
      const Color(0xFFE0C3FC),
    ];
    return colors[index % colors.length];
  }