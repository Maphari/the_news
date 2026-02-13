import 'package:flutter/material.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/view/social/user_profile_page.dart';

/// Deprecated wrapper kept for compatibility.
/// Use UserProfilePage for all profiles.
class UserProfileViewPage extends StatelessWidget {
  const UserProfileViewPage({
    super.key,
    required this.currentUser,
    required this.profileUserId,
  });

  final RegisterLoginUserSuccessModel currentUser;
  final String profileUserId;

  @override
  Widget build(BuildContext context) {
    return UserProfilePage(userId: profileUserId);
  }
}
