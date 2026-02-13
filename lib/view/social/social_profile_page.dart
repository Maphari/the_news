import 'package:flutter/material.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/view/social/user_profile_page.dart';

/// Deprecated wrapper kept for backward compatibility.
/// Social profile and "My Space" now share a single screen.
class SocialProfilePage extends StatelessWidget {
  const SocialProfilePage({super.key, required this.user});

  final RegisterLoginUserSuccessModel user;

  @override
  Widget build(BuildContext context) {
    return UserProfilePage(userId: user.userId);
  }
}
