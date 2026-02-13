import 'package:the_news/constant/theme/default_theme.dart';
import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/service/content_intensity_service.dart';
import 'package:the_news/utils/haptic_service.dart';

class IntensityFilterDialog extends StatefulWidget {
  const IntensityFilterDialog({
    super.key,
    required this.currentLevel,
  });

  final IntensityLevel currentLevel;

  @override
  State<IntensityFilterDialog> createState() => _IntensityFilterDialogState();

  // Show the dialog
  static Future<IntensityLevel?> show(
    BuildContext context, {
    required IntensityLevel currentLevel,
  }) {
    return showDialog<IntensityLevel>(
      context: context,
      builder: (context) => IntensityFilterDialog(
        currentLevel: currentLevel,
      ),
    );
  }
}

class _IntensityFilterDialogState extends State<IntensityFilterDialog> {
  late IntensityLevel _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.currentLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: KDesignConstants.paddingLg,
        decoration: BoxDecoration(
          color: KAppColors.getBackground(context),
          borderRadius: KBorderRadius.xxl,
          border: Border.all(
            color: KAppColors.getPrimary(context).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.tune_outlined,
                color: KAppColors.getPrimary(context),
                size: 32,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing20),

            // Title
            Text(
              'Content Intensity Filter',
              style: TextStyle(
                color: KAppColors.getOnBackground(context),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KDesignConstants.spacing8),

            // Subtitle
            Text(
              'Choose what emotional intensity feels right for you today',
              style: TextStyle(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KDesignConstants.spacing24),

            // Filter options
            _buildFilterOption(IntensityLevel.low),
            const SizedBox(height: KDesignConstants.spacing12),
            _buildFilterOption(IntensityLevel.medium),
            const SizedBox(height: KDesignConstants.spacing12),
            _buildFilterOption(IntensityLevel.high),
            const SizedBox(height: KDesignConstants.spacing12),
            _buildFilterOption(IntensityLevel.all),

            const SizedBox(height: KDesignConstants.spacing24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    label: 'Cancel',
                    isPrimary: false,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                Expanded(
                  child: _buildButton(
                    label: 'Apply',
                    isPrimary: true,
                    onPressed: () {
                      HapticService.success();
                      Navigator.of(context).pop(_selectedLevel);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(IntensityLevel level) {
    final isSelected = _selectedLevel == level;

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        setState(() {
          _selectedLevel = level;
        });
      },
      child: Container(
        padding: KDesignConstants.paddingMd,
        decoration: BoxDecoration(
          gradient: isSelected
              ? null
              : null,
          color: isSelected
              ? KAppColors.getPrimary(context).withValues(alpha: 0.2)
              : KAppColors.getOnBackground(context).withValues(alpha: 0.05),
          borderRadius: KBorderRadius.lg,
          border: Border.all(
            color: isSelected
                ? KAppColors.getPrimary(context).withValues(alpha: 0.5)
                : KAppColors.getOnBackground(context).withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon/Emoji
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: isSelected ? 0.15 : 0.08),
                borderRadius: KBorderRadius.md,
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  level.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: TextStyle(
                      color: KAppColors.getOnBackground(context),
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: KDesignConstants.spacing4),
                  Text(
                    level.description,
                    style: TextStyle(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: KAppColors.getPrimary(context),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: KBorderRadius.lg,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: null,
            color: isPrimary
                ? KAppColors.getPrimary(context)
                : KAppColors.getOnBackground(context).withValues(alpha: 0.08),
            borderRadius: KBorderRadius.lg,
            border: Border.all(
              color: isPrimary
                  ? KAppColors.getPrimary(context).withValues(alpha: 0.4)
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary
                  ? KAppColors.getOnPrimary(context)
                  : KAppColors.getOnBackground(context),
              fontSize: 15,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
