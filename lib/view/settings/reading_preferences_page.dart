import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/reading_preferences_model.dart';
import 'package:the_news/service/reading_preferences_service.dart';

/// Reading preferences customization page
class ReadingPreferencesPage extends StatefulWidget {
  const ReadingPreferencesPage({super.key});

  @override
  State<ReadingPreferencesPage> createState() => _ReadingPreferencesPageState();
}

class _ReadingPreferencesPageState extends State<ReadingPreferencesPage> {
  final ReadingPreferencesService _prefsService = ReadingPreferencesService.instance;

  @override
  void initState() {
    super.initState();
    _prefsService.addListener(_onPreferencesChanged);
  }

  @override
  void dispose() {
    _prefsService.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void _onPreferencesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: KAppColors.getOnBackground(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reading Preferences',
          style: KAppTextStyles.titleLarge.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await _prefsService.resetToDefaults();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Reset to defaults')),
                );
              }
            },
            child: Text(
              'Reset',
              style: KAppTextStyles.labelLarge.copyWith(
                color: KAppColors.getPrimary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Preview card
          _buildPreviewCard(),
          const SizedBox(height: 32),

          // Font Size
          _buildSectionHeader('Font Size', Icons.format_size),
          const SizedBox(height: 16),
          _buildFontSizeSelector(),
          const SizedBox(height: 32),

          // Font Family
          _buildSectionHeader('Font Family', Icons.font_download),
          const SizedBox(height: 16),
          _buildFontFamilySelector(),
          const SizedBox(height: 32),

          // Line Spacing
          _buildSectionHeader('Line Spacing', Icons.format_line_spacing),
          const SizedBox(height: 16),
          _buildLineSpacingSelector(),
          const SizedBox(height: 32),

          // Reading Theme
          _buildSectionHeader('Reading Theme', Icons.palette_outlined),
          const SizedBox(height: 16),
          _buildReadingThemeSelector(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final prefs = _prefsService.preferences;
    final scaleFactor = _prefsService.getTextScaleFactor();
    final lineHeight = _prefsService.getLineHeight();
    final fontFamily = _prefsService.getFontFamily();

    // Get theme colors
    Color bgColor = KAppColors.getBackground(context);
    Color textColor = KAppColors.getOnBackground(context);

    if (prefs.readingTheme.isCustomTheme) {
      bgColor = Color(prefs.readingTheme.backgroundColor!);
      textColor = Color(prefs.readingTheme.textColor!);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: KAppTextStyles.labelSmall.copyWith(
              color: textColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The Future of News',
            style: TextStyle(
              fontSize: 24 * scaleFactor,
              height: lineHeight,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is how your articles will look with your current settings. Adjust the font size, family, and spacing to find what works best for you.',
            style: TextStyle(
              fontSize: 16 * scaleFactor,
              height: lineHeight,
              color: textColor.withValues(alpha: 0.8),
              fontFamily: fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: KAppColors.getPrimary(context),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: KAppTextStyles.titleMedium.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: FontSize.values.map((size) {
        final isSelected = _prefsService.fontSize == size;
        return InkWell(
          onTap: () => _prefsService.setFontSize(size),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? KAppColors.getPrimary(context)
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? KAppColors.getPrimary(context)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  size.icon,
                  style: TextStyle(
                    fontSize: size.size,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : KAppColors.getOnBackground(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  size.label,
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: isSelected
                        ? Colors.white
                        : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFontFamilySelector() {
    return Column(
      children: FontFamily.values.map((family) {
        final isSelected = _prefsService.fontFamily == family;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _prefsService.setFontFamily(family),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? KAppColors.getPrimary(context).withValues(alpha: 0.1)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? KAppColors.getPrimary(context)
                      : KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: KAppColors.getPrimary(context),
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                      size: 20,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          family.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: KAppColors.getOnBackground(context),
                            fontFamily: family.value,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          family.description,
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineSpacingSelector() {
    return Column(
      children: LineSpacing.values.map((spacing) {
        final isSelected = _prefsService.lineSpacing == spacing;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _prefsService.setLineSpacing(spacing),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? KAppColors.getPrimary(context).withValues(alpha: 0.1)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? KAppColors.getPrimary(context)
                      : KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: KAppColors.getPrimary(context),
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.3),
                      size: 20,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spacing.label,
                          style: KAppTextStyles.titleSmall.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          spacing.description,
                          style: KAppTextStyles.bodySmall.copyWith(
                            color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReadingThemeSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ReadingTheme.values.map((theme) {
        final isSelected = _prefsService.readingTheme == theme;

        // Get theme colors for preview
        Color bgColor = theme.isCustomTheme
            ? Color(theme.backgroundColor!)
            : KAppColors.getBackground(context);
        Color textColor = theme.isCustomTheme
            ? Color(theme.textColor!)
            : KAppColors.getOnBackground(context);

        return InkWell(
          onTap: () => _prefsService.setReadingTheme(theme),
          child: Container(
            width: (MediaQuery.of(context).size.width - 72) / 2,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? KAppColors.getPrimary(context)
                    : KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                width: isSelected ? 3 : 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Aa',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: KAppColors.getPrimary(context),
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  theme.label,
                  style: KAppTextStyles.labelMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
