import 'package:flutter/material.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/view/social/user_search_page.dart';

/// Deprecated wrapper kept for compatibility.
/// Use UserSearchPage instead.
class SearchUsersPage extends StatelessWidget {
  const SearchUsersPage({super.key, required this.currentUser});

  final RegisterLoginUserSuccessModel currentUser;

  @override
  Widget build(BuildContext context) {
    return UserSearchPage(currentUser: currentUser);
  }
}
