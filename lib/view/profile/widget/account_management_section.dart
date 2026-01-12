import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/theme_service.dart';
import 'package:the_news/service/subscription_service.dart';
import 'package:the_news/routes/app_routes.dart';
import 'package:the_news/view/settings/language_settings_page.dart';
import 'package:the_news/view/settings/reading_preferences_page.dart';
import 'package:the_news/view/subscription/subscription_paywall_page.dart';

class AccountManagementSection extends StatefulWidget {
  const AccountManagementSection({super.key});

  @override
  State<AccountManagementSection> createState() => _AccountManagementSectionState();
}

class _AccountManagementSectionState extends State<AccountManagementSection> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isPremium = false;
  final ThemeService _themeService = ThemeService.instance;
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final userData = await authService.getCurrentUser();
    final subscription = await _subscriptionService.getCurrentSubscription();
    if (mounted) {
      setState(() {
        _userData = userData;
        _isPremium = subscription?.isActive ?? false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        padding: const EdgeInsets.all(18),
        child: const Center(
          child: CircularProgressIndicator(color: KAppColors.primary),
        ),
      );
    }

    // Get user data safely
    final userName = _userData?['name'] ?? _userData?['email']?.toString().split('@').first ?? 'User';
    final userEmail = _userData?['email'] ?? 'No email';
    final userAvatar = _userData?['photoURL'] as String?;

    return Column(
      children: [
        // User Profile Header Card
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KAppColors.primary.withValues(alpha: 0.1),
                KAppColors.secondary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: KAppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: userAvatar == null
                      ? LinearGradient(
                          colors: [KAppColors.getPrimary(context), KAppColors.getSecondary(context)],
                        )
                      : null,
                  image: userAvatar != null
                      ? DecorationImage(
                          image: NetworkImage(userAvatar),
                          fit: BoxFit.cover,
                        )
                      : null,
                  border: Border.all(
                    color: KAppColors.getPrimary(context).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: userAvatar == null
                    ? Center(
                        child: Text(
                          userName[0].toUpperCase(),
                          style: KAppTextStyles.headlineMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: KAppTextStyles.titleLarge.copyWith(
                        color: KAppColors.getOnBackground(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: KAppTextStyles.bodyMedium.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Settings Icon (visual only, actions are in tiles below)
              // Container(
              //   padding: const EdgeInsets.all(8),
              //   decoration: BoxDecoration(
              //     color: KAppColors.getPrimary(context).withValues(alpha: 0.15),
              //     shape: BoxShape.circle,
              //   ),
              //   child: Icon(
              //     Icons.settings_outlined,
              //     color: KAppColors.getPrimary(context),
              //     size: 24,
              //   ),
              // ),
            ],
          ),
        ),

        // Manage Subscription / Upgrade to Premium Tile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: () async {
              if (_isPremium) {
                AppRoutes.navigateTo(context, AppRoutes.subscriptionSettings);
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPaywallPage(),
                  ),
                );
                _loadUserData();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: KAppColors.getPrimary(context).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.workspace_premium,
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
                          _isPremium ? 'Manage Subscription' : 'Upgrade to Premium',
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isPremium ? 'View your subscription details' : 'Unlock all premium features',
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
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
          ),
        ),

        // Theme Toggle Tile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: const Color(0xFFFFA726),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: KAppTextStyles.titleMedium.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _themeService.isDarkMode ? 'Dark mode' : 'Light mode',
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _themeService.isDarkMode,
                  onChanged: (value) {
                    if (value) {
                      _themeService.setDarkMode();
                    } else {
                      _themeService.setLightMode();
                    }
                  },
                  activeTrackColor: KAppColors.getPrimary(context),
                ),
              ],
            ),
          ),
        ),

        // Language Tile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LanguageSettingsPage()),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.language,
                      color: Color(0xFF9C27B0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Language',
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose your preferred language',
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
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
          ),
        ),

        // Reading Preferences Tile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReadingPreferencesPage()),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.text_fields,
                      color: Color(0xFF00BCD4),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reading Preferences',
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Customize your reading experience',
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
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
          ),
        ),

        // Edit Profile Tile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: () => _showComingSoonDialog(context, 'Edit Profile'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF607D8B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF607D8B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Profile',
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Update your personal information',
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
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
          ),
        ),

        // Change Password Tile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: () => _showComingSoonDialog(context, 'Change Password'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF795548).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF795548),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Password',
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Update your account password',
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
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
          ),
        ),

        // Download My Data Tile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: () => _showComingSoonDialog(context, 'Download My Data'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF009688).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.download_outlined,
                      color: Color(0xFF009688),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Download My Data',
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Export your account information',
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
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
          ),
        ),

        // Sign Out Tile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: () => _handleSignOut(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign Out',
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Log out of your account',
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: Colors.red.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.red.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authService = AuthService();
      await authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
