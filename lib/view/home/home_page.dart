import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/home/widget/calm_mode_toggle.dart';
import 'package:the_news/view/home/widget/home_app_bar.dart';
import 'package:the_news/view/home/widget/home_content.dart';
import 'package:the_news/view/home/widget/view_toggle_button.dart';
import 'package:the_news/service/disliked_articles_service.dart';
import 'package:the_news/service/followed_publishers_service.dart';
import 'package:the_news/service/saved_articles_service.dart';
import 'package:the_news/service/location_service.dart';
import 'package:the_news/view/perspectives/multi_perspective_page.dart';
import 'package:the_news/view/digest/daily_digest_page.dart';
import 'package:the_news/view/profile/country_selection_page.dart';
import 'package:the_news/service/news_provider_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});

  final RegisterLoginUserSuccessModel user;

  @override
  State<HomePage> createState() => _HomePageState();

  /// Static method to create SpeedDial for HomePage
  static Widget createSpeedDial(
    BuildContext context,
    RegisterLoginUserSuccessModel user,
  ) {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      spacing: 3,
      childPadding: const EdgeInsets.all(5),
      spaceBetweenChildren: 4,
      direction: SpeedDialDirection.up,
      children: [
        SpeedDialChild(
          child: Icon(Icons.summarize, color: KAppColors.getPrimary(context)),
          label: 'Daily Digest',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DailyDigestPage(userId: user.userId),
            ),
          ),
        ),
        SpeedDialChild(
          child: Icon(
            Icons.auto_awesome,
            color: KAppColors.getPrimary(context),
          ),
          label: 'Multi-Perspective View',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MultiPerspectivePage(),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomePageState extends State<HomePage> {
  int selectedCategory = 0;
  ViewMode viewMode = ViewMode.cardStack; // Default to swipe cards view
  bool _showMenuOverlay = false;

  @override
  void initState() {
    super.initState();
    StatusBarHelper.setLightStatusBar();
    // Load user data when home page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DislikedArticlesService.instance.loadDislikedArticles(widget.user.userId);
      SavedArticlesService.instance.loadSavedArticles(widget.user.userId);
      FollowedPublishersService.instance.loadFollowedPublishers(
        widget.user.userId,
      );
    });
  }

  void _toggleMenuOverlay() {
    setState(() {
      _showMenuOverlay = !_showMenuOverlay;
    });
  }

  Widget _buildHomeHeader() {
    return HomeHeader(
      title: 'Home',
      subtitle: 'Stay informed with mindful news',
      showActions: true,
      bottom: 5,
      viewToggle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CalmModeToggle(
            onToggle: () {
              // Handle toggle if needed, e.g., refresh content
              setState(() {});
            },
          ),
          const SizedBox(width: 8),
          // Menu button
          GestureDetector(
            onTap: _toggleMenuOverlay,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(
                  color: KAppColors.getOnBackground(
                    context,
                  ).withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.widgets_rounded,
                color: KAppColors.getOnBackground(context),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOverlay() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _showMenuOverlay ? 0 : -MediaQuery.of(context).size.height,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: _toggleMenuOverlay,
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.only(left: 25, right: 25, top: 6, bottom: 24),
                  decoration: BoxDecoration(
                    color: KAppColors.getBackground(context),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // View Mode Section
                      _buildHeader(title: 'View Mode', context: context, showBottomSizedBox: true,),
                      Row(
                        children: [
                          Expanded(
                            child: _buildViewModeOption(
                              icon: Icons.view_carousel_outlined,
                              label: 'Cards',
                              isSelected: viewMode == ViewMode.cardStack,
                              onTap: () {
                                setState(() => viewMode = ViewMode.cardStack);
                                _toggleMenuOverlay();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildViewModeOption(
                              icon: Icons.view_list_outlined,
                              label: 'List',
                              isSelected: viewMode == ViewMode.compactList,
                              onTap: () {
                                setState(() => viewMode = ViewMode.compactList);
                                _toggleMenuOverlay();
                              },
                            ),
                          ),
                        ],
                      ),
                      _buildDevider(context: context),
                      _buildHeader(
                          title: 'Easy Access Features',
                          context: context,
                          showBottomSizedBox: true),
                      Row(
                        children: [
                          Expanded(
                            child: ListenableBuilder(
                              listenable: LocationService.instance,
                              builder: (context, _) {
                                final locationService =
                                    LocationService.instance;
                                final hasFilter = locationService
                                    .preferredCountries.isNotEmpty;
                                return _buildFeatureOption(
                                    icon: Icons.public,
                                    label: 'Filter',
                                    isSelected: hasFilter,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CountrySelectionPage(),
                                        ),
                                      );
                                      // Reload articles after returning from country selection
                                      await NewsProviderService.instance
                                          .loadArticles();
                                    });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Opacity(
                              opacity: 0.5,
                              child: _buildFeatureOption(
                                icon: Icons.person_search_outlined,
                                label: 'Coming Soon',
                                isSelected: false,
                                onTap: () {},
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildDevider(context: context),
                      // Features Section
                      _buildHeader(title: 'Features', context: context),
                      _buildMenuItem(
                        icon: Icons.auto_awesome,
                        title: 'Multi-Perspective View',
                        subtitle: 'See different perspectives',
                        onTap: () {
                          _toggleMenuOverlay();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MultiPerspectivePage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: Icons.summarize_outlined,
                        title: 'Daily Digest',
                        subtitle: 'Your personalized summary',
                        onTap: () {
                          _toggleMenuOverlay();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DailyDigestPage(userId: widget.user.userId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevider({
    required BuildContext context,
    double sizedboxHeight = 24,
    double sizedboxBottomHeight = 12,
    bool showBottomSizedBox = false
  }) {
    return Column(
      children: [
        SizedBox(height: sizedboxHeight),
        Divider(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
        if (showBottomSizedBox) 
          SizedBox(height: sizedboxBottomHeight),
      ],
    );
  }

  Widget _buildHeader({
    required String title,
    required BuildContext context,
    double boxSizedheight = 12,
    double fontSize = 12,
    double letterSpacing = 0.5,
     bool showBottomSizedBox = false
  }) {
    return Column(
      children: [
        SizedBox(height: boxSizedheight),
        // Features Section
        Text(
          title,
          style: KAppTextStyles.labelSmall.copyWith(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: letterSpacing,
          ),
        ),
        if (showBottomSizedBox)
          SizedBox(height: boxSizedheight),
      ],
    );
  }

  Widget _buildViewModeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? KAppColors.getPrimary(context).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? KAppColors.getPrimary(context)
                : KAppColors.getOnBackground(context).withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? KAppColors.getPrimary(context)
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: KAppTextStyles.labelSmall.copyWith(
                color: isSelected
                    ? KAppColors.getPrimary(context)
                    : KAppColors.getOnBackground(
                        context,
                      ).withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? KAppColors.getPrimary(context).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? KAppColors.getPrimary(context)
                : KAppColors.getOnBackground(context).withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? KAppColors.getPrimary(context)
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: KAppTextStyles.labelSmall.copyWith(
                color: isSelected
                    ? KAppColors.getPrimary(context)
                    : KAppColors.getOnBackground(
                        context,
                      ).withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
   }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: KAppColors.getPrimary(context),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KAppTextStyles.titleMedium.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(
                        context,
                      ).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    // Country emoji mapping
    const countryEmojis = {
      'United States': '🇺🇸',
      'United Kingdom': '🇬🇧',
      'Canada': '🇨🇦',
      'Australia': '🇦🇺',
      'Germany': '🇩🇪',
      'France': '🇫🇷',
      'Italy': '🇮🇹',
      'Spain': '🇪🇸',
      'Japan': '🇯🇵',
      'China': '🇨🇳',
      'India': '🇮🇳',
      'Brazil': '🇧🇷',
      'Mexico': '🇲🇽',
      'Russia': '🇷🇺',
      'South Korea': '🇰🇷',
      'Netherlands': '🇳🇱',
      'Switzerland': '🇨🇭',
      'Sweden': '🇸🇪',
      'Norway': '🇳🇴',
      'Denmark': '🇩🇰',
      'Finland': '🇫🇮',
      'Belgium': '🇧🇪',
      'Austria': '🇦🇹',
      'Poland': '🇵🇱',
      'Ireland': '🇮🇪',
      'Portugal': '🇵🇹',
      'Greece': '🇬🇷',
      'Turkey': '🇹🇷',
      'South Africa': '🇿🇦',
      'Nigeria': '🇳🇬',
      'Egypt': '🇪🇬',
      'Saudi Arabia': '🇸🇦',
      'UAE': '🇦🇪',
      'Israel': '🇮🇱',
      'Singapore': '🇸🇬',
      'Malaysia': '🇲🇾',
      'Thailand': '🇹🇭',
      'Indonesia': '🇮🇩',
      'Philippines': '🇵🇭',
      'Vietnam': '🇻🇳',
      'New Zealand': '🇳🇿',
      'Argentina': '🇦🇷',
      'Chile': '🇨🇱',
      'Colombia': '🇨🇴',
      'Peru': '🇵🇪',
    };

    return ListenableBuilder(
      listenable: LocationService.instance,
      builder: (context, _) {
        final locationService = LocationService.instance;
        if (locationService.preferredCountries.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: KAppColors.getPrimary(context).withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...locationService.preferredCountries.map((countryName) {
                final flag = countryEmojis[countryName] ?? '🌍';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: KAppColors.getPrimary(
                      context,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: KAppColors.getPrimary(
                        context,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        countryName,
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.getPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // Clear filter button
              GestureDetector(
                onTap: () async {
                  await locationService.clearLocationData();
                  await NewsProviderService.instance.loadArticles();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: KAppColors.getOnBackground(
                      context,
                    ).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: KAppColors.getOnBackground(
                        context,
                      ).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close,
                        size: 14,
                        color: KAppColors.getOnBackground(
                          context,
                        ).withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: KAppTextStyles.labelSmall.copyWith(
                          color: KAppColors.getOnBackground(
                            context,
                          ).withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: KAppColors.getBackground(context),
      child: Stack(
        children: [
          Container(
            color: KAppColors.getBackground(context),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHomeHeader(),
                  _buildFilterChips(),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: LocationService.instance,
                      builder: (context, _) {
                        return HomeContent(
                          selectedCategory: selectedCategory,
                          onCategoryChanged: (index) =>
                              setState(() => selectedCategory = index),
                          viewMode: viewMode,
                          user: widget.user,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showMenuOverlay) _buildMenuOverlay(),
        ],
      ),
    );
  }
}
