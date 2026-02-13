import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/location_service.dart';
import 'package:the_news/service/news_api_service.dart';
import 'package:the_news/service/news_provider_service.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/user_preferences_sync_service.dart';
import 'package:the_news/utils/statusbar_helper_utils.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/widgets/app_search_bar.dart';

/// Page for selecting preferred countries for news
class CountrySelectionPage extends StatefulWidget {
  const CountrySelectionPage({super.key});

  @override
  State<CountrySelectionPage> createState() => _CountrySelectionPageState();
}

class _CountrySelectionPageState extends State<CountrySelectionPage> {
  final LocationService _locationService = LocationService.instance;
  final AuthService _authService = AuthService();
  final UserPreferencesSyncService _preferencesSync = UserPreferencesSyncService.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserAndSync();
  }

  Future<void> _loadUserAndSync() async {
    final userData = await _authService.getCurrentUser();
    final userId = userData?['id'] as String? ?? userData?['userId'] as String?;
    if (userId == null) return;

    _userId = userId;
    await _preferencesSync.forceSyncFromRemote(userId);
    await _locationService.reloadPreferences();
    if (mounted) {
      setState(() {});
    }
  }

  // Comprehensive list of countries
  static const List<Map<String, String>> _countries = [
    {'name': 'United States', 'code': 'US', 'emoji': '🇺🇸'},
    {'name': 'United Kingdom', 'code': 'GB', 'emoji': '🇬🇧'},
    {'name': 'Canada', 'code': 'CA', 'emoji': '🇨🇦'},
    {'name': 'Australia', 'code': 'AU', 'emoji': '🇦🇺'},
    {'name': 'Germany', 'code': 'DE', 'emoji': '🇩🇪'},
    {'name': 'France', 'code': 'FR', 'emoji': '🇫🇷'},
    {'name': 'Italy', 'code': 'IT', 'emoji': '🇮🇹'},
    {'name': 'Spain', 'code': 'ES', 'emoji': '🇪🇸'},
    {'name': 'Japan', 'code': 'JP', 'emoji': '🇯🇵'},
    {'name': 'China', 'code': 'CN', 'emoji': '🇨🇳'},
    {'name': 'India', 'code': 'IN', 'emoji': '🇮🇳'},
    {'name': 'Brazil', 'code': 'BR', 'emoji': '🇧🇷'},
    {'name': 'Mexico', 'code': 'MX', 'emoji': '🇲🇽'},
    {'name': 'Russia', 'code': 'RU', 'emoji': '🇷🇺'},
    {'name': 'South Korea', 'code': 'KR', 'emoji': '🇰🇷'},
    {'name': 'Netherlands', 'code': 'NL', 'emoji': '🇳🇱'},
    {'name': 'Switzerland', 'code': 'CH', 'emoji': '🇨🇭'},
    {'name': 'Sweden', 'code': 'SE', 'emoji': '🇸🇪'},
    {'name': 'Norway', 'code': 'NO', 'emoji': '🇳🇴'},
    {'name': 'Denmark', 'code': 'DK', 'emoji': '🇩🇰'},
    {'name': 'Finland', 'code': 'FI', 'emoji': '🇫🇮'},
    {'name': 'Belgium', 'code': 'BE', 'emoji': '🇧🇪'},
    {'name': 'Austria', 'code': 'AT', 'emoji': '🇦🇹'},
    {'name': 'Poland', 'code': 'PL', 'emoji': '🇵🇱'},
    {'name': 'Ireland', 'code': 'IE', 'emoji': '🇮🇪'},
    {'name': 'Portugal', 'code': 'PT', 'emoji': '🇵🇹'},
    {'name': 'Greece', 'code': 'GR', 'emoji': '🇬🇷'},
    {'name': 'Turkey', 'code': 'TR', 'emoji': '🇹🇷'},
    {'name': 'South Africa', 'code': 'ZA', 'emoji': '🇿🇦'},
    {'name': 'Nigeria', 'code': 'NG', 'emoji': '🇳🇬'},
    {'name': 'Egypt', 'code': 'EG', 'emoji': '🇪🇬'},
    {'name': 'Saudi Arabia', 'code': 'SA', 'emoji': '🇸🇦'},
    {'name': 'UAE', 'code': 'AE', 'emoji': '🇦🇪'},
    {'name': 'Israel', 'code': 'IL', 'emoji': '🇮🇱'},
    {'name': 'Singapore', 'code': 'SG', 'emoji': '🇸🇬'},
    {'name': 'Malaysia', 'code': 'MY', 'emoji': '🇲🇾'},
    {'name': 'Thailand', 'code': 'TH', 'emoji': '🇹🇭'},
    {'name': 'Indonesia', 'code': 'ID', 'emoji': '🇮🇩'},
    {'name': 'Philippines', 'code': 'PH', 'emoji': '🇵🇭'},
    {'name': 'Vietnam', 'code': 'VN', 'emoji': '🇻🇳'},
    {'name': 'New Zealand', 'code': 'NZ', 'emoji': '🇳🇿'},
    {'name': 'Argentina', 'code': 'AR', 'emoji': '🇦🇷'},
    {'name': 'Chile', 'code': 'CL', 'emoji': '🇨🇱'},
    {'name': 'Colombia', 'code': 'CO', 'emoji': '🇨🇴'},
    {'name': 'Peru', 'code': 'PE', 'emoji': '🇵🇪'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredCountries {
    if (_searchQuery.isEmpty) return _countries;
    return _countries.where((country) {
      return country['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          country['code']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _detectLocation() async {
    final success = await _locationService.detectCurrentLocation();
    if (!mounted) return;

    if (success) {
      await _syncPreferences();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.location_on, color: KAppColors.getOnPrimary(context)),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: Text(
                  'Location detected: ${_locationService.currentCountry}',
                  style: TextStyle(
                    color: KAppColors.getOnPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: KAppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: KBorderRadius.md,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: KAppColors.getOnPrimary(context)),
              const SizedBox(width: KDesignConstants.spacing12),
              Expanded(
                child: Text(
                  _locationService.error ?? 'Failed to detect location',
                  style: TextStyle(
                    color: KAppColors.getOnPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: KAppColors.error,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: KBorderRadius.md,
          ),
          action: SnackBarAction(
            label: 'Settings',
            textColor: KAppColors.getOnPrimary(context),
            onPressed: () => _locationService.openAppSettings(),
          ),
        ),
      );
    }
  }

  Future<void> _toggleCountry(String countryName) async {
    if (_locationService.isCountryPreferred(countryName)) {
      await _locationService.removePreferredCountry(countryName);
    } else {
      await _locationService.addPreferredCountry(countryName);
    }
    await _syncPreferences();
    // Refresh feeds with new country filter and avoid stale cache.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updating news feed...'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
    await NewsApiService.instance.clearCache();
    await NewsProviderService.instance.refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('News feed updated'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _syncPreferences() async {
    if (_userId == null) return;
    await _preferencesSync.updatePreference(
      _userId!,
      'preferredCountries',
      _locationService.preferredCountries,
    );
    if (_locationService.currentCountry != null) {
      await _preferencesSync.updatePreference(
        _userId!,
        'currentCountry',
        _locationService.currentCountry!,
      );
    }
    if (_locationService.currentCountryCode != null) {
      await _preferencesSync.updatePreference(
        _userId!,
        'currentCountryCode',
        _locationService.currentCountryCode!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarHelper.wrapWithStatusBar(
      backgroundColor: KAppColors.getBackground(context),
      child: Scaffold(
        backgroundColor: KAppColors.getBackground(context),
        appBar: KAppBar(
          title: Text(
            'Country Preferences',
            style: KAppTextStyles.titleLarge.copyWith(
              color: KAppColors.getOnBackground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: KAppColors.getBackground(context),
          elevation: 0,
          leading: AppBackButton(onPressed: () => Navigator.pop(context),),
            ),
          
        body: Column(
          children: [
            // Location Detection Card
            Container(
              margin: KDesignConstants.paddingMd,
              padding: KDesignConstants.paddingMd,
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.08),
                borderRadius: KBorderRadius.lg,
                border: Border.all(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.my_location,
                          color: KAppColors.getPrimary(context),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: KDesignConstants.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto-Detect Location',
                              style: KAppTextStyles.titleMedium.copyWith(
                                color: KAppColors.getOnBackground(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _locationService.hasLocation
                                  ? 'Current: ${_locationService.currentCountry}'
                                  : 'Get news from your location',
                              style: KAppTextStyles.bodySmall.copyWith(
                                color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KDesignConstants.spacing12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _locationService.isLoading ? null : _detectLocation,
                      icon: _locationService.isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  KAppColors.getOnPrimary(context),
                                ),
                              ),
                            )
                          : const Icon(Icons.location_searching),
                      label: Text(
                        _locationService.isLoading ? 'Detecting...' : 'Detect My Location',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KAppColors.getPrimary(context),
                        foregroundColor: KAppColors.getOnPrimary(context),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: KBorderRadius.md,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: KDesignConstants.paddingHorizontalMd,
              child: AppSearchBar(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                hintText: 'Search countries...',
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing16),

            // Selected Countries Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Selected Countries',
                    style: KAppTextStyles.titleSmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: KAppColors.getPrimary(context).withValues(alpha: 0.1),
                      borderRadius: KBorderRadius.md,
                    ),
                    child: Text(
                      '${_locationService.preferredCountries.length}',
                      style: KAppTextStyles.labelMedium.copyWith(
                        color: KAppColors.getPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing12),

            // Countries List
            Expanded(
              child: ListenableBuilder(
                listenable: _locationService,
                builder: (context, child) {
                  final filteredCountries = _filteredCountries;

                  if (filteredCountries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: KDesignConstants.spacing16),
                          Text(
                            'No countries found',
                            style: KAppTextStyles.titleMedium.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      final countryName = country['name']!;
                      final countryCode = country['code']!;
                      final countryEmoji = country['emoji']!;
                      final isSelected = _locationService.isCountryPreferred(countryName);
                      final isCurrentLocation = _locationService.currentCountry == countryName;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? KAppColors.getPrimary(context).withValues(alpha: 0.1)
                              : KAppColors.getOnBackground(context).withValues(alpha: 0.03),
                          borderRadius: KBorderRadius.md,
                          border: Border.all(
                            color: isSelected
                                ? KAppColors.getPrimary(context).withValues(alpha: 0.3)
                                : KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                          ),
                        ),
                        child: ListTile(
                          leading: Text(
                            countryEmoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          title: Row(
                            children: [
                              Text(
                                countryName,
                                style: KAppTextStyles.titleMedium.copyWith(
                                  color: KAppColors.getOnBackground(context),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                              if (isCurrentLocation) ...[
                                const SizedBox(width: KDesignConstants.spacing8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: KAppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 10,
                                        color: KAppColors.success,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Current',
                                        style: KAppTextStyles.labelSmall.copyWith(
                                          color: KAppColors.success,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            countryCode,
                            style: KAppTextStyles.bodySmall.copyWith(
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                            ),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (value) => _toggleCountry(countryName),
                            activeColor: KAppColors.getPrimary(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onTap: () => _toggleCountry(countryName),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
