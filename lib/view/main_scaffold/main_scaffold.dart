import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/view/home/home_page.dart';
import 'package:the_news/view/explore/explore_page.dart';
import 'package:the_news/view/saved/saved_page.dart';
import 'package:the_news/view/profile/profile_page.dart';
import 'package:the_news/view/social/social_hub_page.dart';

/// Main scaffold with persistent bottom navigation bar
/// Handles navigation between main app sections: Home, Explore, Saved, Profile
/// Uses IndexedStack for instant tab switching without animation
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, required this.user, this.initialIndex = 0});

  final RegisterLoginUserSuccessModel user;
  final int initialIndex;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      HomePage(user: widget.user),
      ExplorePage(user: widget.user),
      SocialHubPage(user: widget.user),
      SavedPage(user: widget.user),
      ProfilePage(user: widget.user),
    ];
  }

  void _onNavigationTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: AdaptiveScaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: AdaptiveBottomNavigationBar(
          selectedIndex: _currentIndex,
          onTap: _onNavigationTap,
          selectedItemColor: KAppColors.primary,
          unselectedItemColor: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
          useNativeBottomBar: true,
          items: const [
            AdaptiveNavigationDestination(
              icon: 'house',
              selectedIcon: 'house.fill',
              label: 'Home',
            ),
            AdaptiveNavigationDestination(
              icon: 'safari',
              selectedIcon: 'safari.fill',
              label: 'Explore',
            ),
            AdaptiveNavigationDestination(
              icon: 'flame',
              selectedIcon: 'flame.fill',
              label: 'Social',
            ),
            AdaptiveNavigationDestination(
              icon: 'bookmark',
              selectedIcon: 'bookmark.fill',
              label: 'Saved',
            ),
            AdaptiveNavigationDestination(
              icon: 'person',
              selectedIcon: 'person.fill',
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
