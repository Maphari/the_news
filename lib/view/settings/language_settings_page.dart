import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/service/localization_service.dart';
import 'package:the_news/service/auth_service.dart';

/// Page for selecting app language
class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  String _selectedLanguage = 'en';
  final LocalizationService _localizationService = LocalizationService.instance;
  final AuthService _authService = AuthService();
  String? _userId;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'es', 'name': 'Spanish', 'nativeName': 'Español'},
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
    {'code': 'de', 'name': 'German', 'nativeName': 'Deutsch'},
    {'code': 'zh', 'name': 'Chinese', 'nativeName': '中文'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
    {'code': 'pt', 'name': 'Portuguese', 'nativeName': 'Português'},
    {'code': 'ru', 'name': 'Russian', 'nativeName': 'Русский'},
    {'code': 'ja', 'name': 'Japanese', 'nativeName': '日本語'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final userData = await _authService.getCurrentUser();
    _userId = userData?['id'] as String? ?? userData?['userId'] as String?;

    setState(() {
      _selectedLanguage = _localizationService.currentLocale.languageCode;
    });
  }

  Future<void> _saveLanguage(String languageCode) async {
    await _localizationService.changeLocale(
      Locale(languageCode),
      userId: _userId,
    );
    setState(() {
      _selectedLanguage = languageCode;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Language changed. Restart app to apply changes.'),
          backgroundColor: KAppColors.getPrimary(context),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: KAppBar(
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(
          'Language',
          style: KAppTextStyles.titleLarge.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: KDesignConstants.paddingMd,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  KAppColors.getPrimary(context).withValues(alpha: 0.1),
                  KAppColors.getPrimary(context).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: KBorderRadius.md,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.language,
                  color: KAppColors.getPrimary(context),
                  size: 32,
                ),
                const SizedBox(width: KDesignConstants.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Your Language',
                        style: KAppTextStyles.titleMedium.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: KDesignConstants.spacing4),
                      Text(
                        'Choose your preferred language for the app interface',
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing24),
          Container(
            decoration: BoxDecoration(
              color: KAppColors.getBackground(context),
              borderRadius: KBorderRadius.lg,
              border: Border.all(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: _languages.asMap().entries.map((entry) {
                final index = entry.key;
                final language = entry.value;
                final isSelected = _selectedLanguage == language['code'];

                return Column(
                  children: [
                    if (index > 0)
                      Divider(
                        height: 1,
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                      ),
                    ListTile(
                      onTap: () => _saveLanguage(language['code']!),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? KAppColors.getPrimary(context).withValues(alpha: 0.2)
                              : KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            language['code']!.toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? KAppColors.getPrimary(context)
                                  : KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        language['nativeName']!,
                        style: KAppTextStyles.bodyLarge.copyWith(
                          color: KAppColors.getOnBackground(context),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        language['name']!,
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: KAppColors.getPrimary(context),
                            )
                          : Icon(
                              Icons.circle_outlined,
                              color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                            ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: KDesignConstants.spacing24),
          Container(
            padding: KDesignConstants.paddingMd,
            decoration: BoxDecoration(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
              borderRadius: KBorderRadius.md,
              border: Border.all(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                Expanded(
                  child: Text(
                    'You may need to restart the app for language changes to take full effect.',
                    style: KAppTextStyles.bodySmall.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
