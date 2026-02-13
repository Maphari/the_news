import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/view/home/home_page.dart';
import 'package:the_news/view/explore/explore_page.dart';
import 'package:the_news/view/podcasts/podcasts_page.dart';
import 'package:the_news/view/profile/profile_page.dart';
import 'package:the_news/view/saved/saved_page.dart';
import 'package:the_news/view/social/social_hub_page.dart';
import 'package:the_news/view/perspectives/multi_perspective_page.dart';
import 'package:the_news/view/digest/daily_digest_page.dart';
import 'package:the_news/view/home/widget/calm_mode_toggle.dart';
import 'package:the_news/view/home/widget/view_toggle_button.dart';

abstract class MainScaffoldController {
  void openExploreWithQuery(String query);
}

/// Main scaffold with bottom navigation and drawer
/// Bottom nav: Home, Explore, Saved (primary actions)
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, required this.user, this.initialIndex = 0});

  final RegisterLoginUserSuccessModel user;
  final int initialIndex;

  static MainScaffoldController? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainScaffoldState>();

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    implements MainScaffoldController {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<ViewMode> _viewModeNotifier =
      ValueNotifier<ViewMode>(ViewMode.cardStack);
  final ValueNotifier<String?> _exploreSearchNotifier =
      ValueNotifier<String?>(null);

  // Page indices
  static const int _homeIndex = 0;
  static const int _exploreIndex = 1;
  static const int _podcastsIndex = 2;
  static const int _socialIndex = 3;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      HomePage(
        user: widget.user,
        onProfileTap: () => _openProfilePage(),
        viewModeNotifier: _viewModeNotifier,
      ),
      ExplorePage(
        user: widget.user,
        searchQueryNotifier: _exploreSearchNotifier,
      ),
      PodcastsPage(user: widget.user),
      SocialHubPage(user: widget.user),
    ];
  }

  @override
  void dispose() {
    _viewModeNotifier.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // void _navigateToDrawerPage(int index) {
  //   Navigator.pop(context); // Close drawer
  //   if (index == _currentIndex) return;
  //   setState(() {
  //     _currentIndex = index;
  //   });
  // }

  void _openSavedPage() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedPage(user: widget.user),
      ),
    );
  }

  void _openProfilePage() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(user: widget.user),
      ),
    );
  }

  @override
  void openExploreWithQuery(String query) {
    _exploreSearchNotifier.value = query;
    _onBottomNavTap(_exploreIndex);
  }

  Widget _buildSavedEntry(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KDesignConstants.radiusLg),
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
        border: Border.all(color: KAppColors.getOnBackground(context).withValues(alpha: 0.08)),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.bookmark, size: 20, color: KAppColors.getOnBackground(context)),
        ),
        title: Text(
          'Saved articles',
          style: KAppTextStyles.bodyMedium.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Your curated bookmarks',
          style: KAppTextStyles.bodySmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: KAppColors.getOnBackground(context).withValues(alpha: 0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing12, vertical: KDesignConstants.spacing4),
        onTap: _openSavedPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: false,
        onDrawerChanged: (_) {},
        body: IndexedStack(index: _currentIndex, children: _pages),
        drawer: _buildDrawer(context, isDark),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    return Drawer(
      backgroundColor: KAppColors.getBackground(context),
      child: Column(
        children: [
          _buildDrawerHeader(context, isDark),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: KDesignConstants.spacing8,
                vertical: KDesignConstants.spacing12,
              ),
              children: [
              //   _buildDrawerSection('Browse'),
              //   const SizedBox(height: KDesignConstants.spacing8),
              // _buildDrawerItem(
              //   context,
              //   icon: Icons.home_outlined,
              //   selectedIcon: Icons.home_rounded,
              //   label: 'Home',
              //   index: _homeIndex,
              // ),
              //   const SizedBox(height: KDesignConstants.spacing8),
              //   _buildDrawerItem(
              //     context,
              //     icon: Icons.explore_outlined,
              //     selectedIcon: Icons.explore_rounded,
              //     label: 'Explore',
              //     index: _exploreIndex,
              //   ),
              //   const SizedBox(height: KDesignConstants.spacing8),
              //   _buildDrawerItem(
              //     context,
              //     icon: Icons.podcasts_outlined,
              //     selectedIcon: Icons.podcasts,
              //     label: 'Podcasts',
              //     index: _podcastsIndex,
              //   ),
              //   const SizedBox(height: KDesignConstants.spacing8),
              //   _buildDrawerItem(
              //     context,
              //     icon: Icons.people_outline,
              //     selectedIcon: Icons.people,
              //     label: 'Social',
              //     index: _socialIndex,
              //   ),

                // const SizedBox(height: KDesignConstants.spacing16),
                // Divider(
                //   color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                // ),
                const SizedBox(height: KDesignConstants.spacing12),

                _buildDrawerSection('Library'),
                const SizedBox(height: KDesignConstants.spacing8),
                _buildSavedEntry(context),

                const SizedBox(height: KDesignConstants.spacing16),
                Divider(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                ),
                const SizedBox(height: KDesignConstants.spacing12),

                _buildDrawerSection('Discover'),
                const SizedBox(height: KDesignConstants.spacing8),
                _buildFeatureItem(
                  context,
                  icon: Icons.summarize_outlined,
                  label: 'Daily Digest',
                  subtitle: 'Personalized summary',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DailyDigestPage(userId: widget.user.userId),
                      ),
                    );
                  },
                ),
                const SizedBox(height: KDesignConstants.spacing4),
                _buildFeatureItem(
                  context,
                  icon: Icons.auto_awesome,
                  label: 'Perspectives',
                  subtitle: 'Diverse Perspectives',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MultiPerspectivePage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: KDesignConstants.spacing16),
                Divider(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                ),
                const SizedBox(height: KDesignConstants.spacing12),

                _buildDrawerSection('Preferences'),
                const SizedBox(height: KDesignConstants.spacing8),
                _buildCalmModeToggle(),
                const SizedBox(height: KDesignConstants.spacing8),
                _buildHomeControls(),
              ],
            ),
          ),

          ],
        ),
      );
    }

  Widget _buildDrawerHeader(BuildContext context, bool isDark) {
    final displayName = widget.user.name.isNotEmpty ? widget.user.name : 'User';
    final email = widget.user.email;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: KAppColors.getSurface(context),
        border: Border(
          bottom: BorderSide(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KDesignConstants.spacing16,
            KDesignConstants.spacing16,
            KDesignConstants.spacing16,
            KDesignConstants.spacing16,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: KAppColors.getPrimary(context).withValues(alpha: 0.12),
                child: Text(
                  initial,
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KAppTextStyles.titleMedium.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: KAppColors.getOnBackground(context)),
                onPressed: () => Navigator.pop(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KDesignConstants.spacing16,
      ),
      child: Text(
        title,
        style: KAppTextStyles.labelSmall.copyWith(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // Widget _buildDrawerItem(
  //   BuildContext context, {
  //   required IconData icon,
  //   required IconData selectedIcon,
  //   required String label,
  //   String? subtitle,
  //   required int index,
  // }) {
  //   final isSelected = _currentIndex == index;

  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing8),
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(KDesignConstants.radiusLg),
  //       color: isSelected
  //           ? KAppColors.getPrimary(context).withValues(alpha: 0.08)
  //           : Colors.transparent,
  //       border: Border.all(
  //         color: isSelected
  //             ? KAppColors.getPrimary(context).withValues(alpha: 0.25)
  //             : Colors.transparent,
  //         width: 1,
  //       ),
  //     ),
  //     child: ListTile(
  //       leading: Container(
  //         width: 36,
  //         height: 36,
  //         alignment: Alignment.center,
  //         decoration: BoxDecoration(
  //           color: isSelected
  //               ? KAppColors.getPrimary(context).withValues(alpha: 0.12)
  //               : KAppColors.getOnBackground(context).withValues(alpha: 0.06),
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: Icon(
  //           isSelected ? selectedIcon : icon,
  //           size: 20,
  //           color: isSelected
  //               ? KAppColors.getPrimary(context)
  //               : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
  //         ),
  //       ),
  //       title: Text(
  //         label,
  //         style: KAppTextStyles.bodyMedium.copyWith(
  //           color: isSelected
  //               ? KAppColors.getPrimary(context)
  //               : KAppColors.getOnBackground(context),
  //           fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
  //         ),
  //       ),
  //       subtitle: subtitle != null && subtitle.trim().isNotEmpty
  //           ? Text(
  //               subtitle,
  //               style: KAppTextStyles.bodySmall.copyWith(
  //                 color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
  //               ),
  //             )
  //           : null,
  //       trailing: Icon(
  //         Icons.chevron_right,
  //         size: 18,
  //         color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
  //       ),
  //       contentPadding:  EdgeInsets.symmetric(
  //         horizontal: KDesignConstants.spacing12,
  //         vertical: KDesignConstants.spacing2,
  //       ),
  //       onTap: () => _navigateToDrawerPage(index),
  //     ),
  //   );
  // }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KDesignConstants.radiusLg),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
          ),
        ),
        title: Text(
          label,
          style: KAppTextStyles.bodyMedium.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: KAppTextStyles.bodySmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 18,
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KDesignConstants.spacing12,
          vertical: KDesignConstants.spacing2,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCalmModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KDesignConstants.radiusLg),
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.spa_outlined,
            size: 20,
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
          ),
        ),
        title: Text(
          'Calm Mode',
          style: KAppTextStyles.bodyMedium.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Mindful news experience',
          style: KAppTextStyles.bodySmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
          ),
        ),
        trailing: CalmModeToggle(
          onToggle: () {
            setState(() {});
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KDesignConstants.spacing12,
          vertical: KDesignConstants.spacing2,
        ),
      ),
    );
  }

  Widget _buildHomeControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: KDesignConstants.spacing8),
      padding: const EdgeInsets.symmetric(
        horizontal: KDesignConstants.spacing12,
        vertical: KDesignConstants.spacing8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KDesignConstants.radiusLg),
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ValueListenableBuilder<ViewMode>(
                  valueListenable: _viewModeNotifier,
                  builder: (context, mode, _) {
                    return ViewToggleButton(
                      currentMode: mode,
                      onToggle: (value) => _viewModeNotifier.value = value,
                      width: constraints.maxWidth,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Profile footer removed; profile is accessed from the header.

  Widget _buildBottomNav(BuildContext context) {
    final bottomNavIndex = (_currentIndex <= _socialIndex) ? _currentIndex : -1;
    final items = [
      _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, index: _homeIndex),
      _NavItem(label: 'Explore', icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, index: _exploreIndex),
      _NavItem(label: 'Podcasts', icon: Icons.podcasts_outlined, activeIcon: Icons.podcasts, index: _podcastsIndex),
      _NavItem(label: 'Social', icon: Icons.people_outline, activeIcon: Icons.people, index: _socialIndex),
    ];

    return SafeArea(
      top: false,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: KAppColors.getBackground(context).withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                ...items.map((item) {
                  final isSelected = bottomNavIndex == item.index;
                  return Expanded(
                    child: InkWell(
                      onTap: () => _onBottomNavTap(item.index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? KAppColors.getPrimary(context)
                                  : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              item.label,
                              style: KAppTextStyles.labelSmall.copyWith(
                                fontSize: 11,
                                color: isSelected
                                    ? KAppColors.getPrimary(context)
                                    : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                Expanded(
                  child: InkWell(
                    onTap: _openDrawer,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.more_horiz,
                            size: 22,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'More',
                            style: KAppTextStyles.labelSmall.copyWith(
                              fontSize: 11,
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.index,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int index;
}
