import 'package:the_news/constant/theme/default_theme.dart';
import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/service/mood_tracking_service.dart';
import 'package:the_news/utils/haptic_service.dart';

class MoodCheckInDialog extends StatefulWidget {
  const MoodCheckInDialog({
    super.key,
    required this.isPreReading,
    this.articleTitle,
  });

  final bool isPreReading;
  final String? articleTitle;

  @override
  State<MoodCheckInDialog> createState() => _MoodCheckInDialogState();

  // Show pre-reading mood check-in
  static Future<Map<String, dynamic>?> showPreReading(
    BuildContext context, {
    String? articleTitle,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MoodCheckInDialog(
        isPreReading: true,
        articleTitle: articleTitle,
      ),
    );
  }

  // Show post-reading mood check-in
  static Future<Map<String, dynamic>?> showPostReading(
    BuildContext context,
  ) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MoodCheckInDialog(
        isPreReading: false,
      ),
    );
  }
}

class _MoodCheckInDialogState extends State<MoodCheckInDialog> {
  String? _selectedMood;
  int _intensity = 5;

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
                widget.isPreReading
                    ? Icons.favorite_outline
                    : Icons.psychology_outlined,
                color: KAppColors.getPrimary(context),
                size: 32,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing20),

            // Title
            Text(
              widget.isPreReading
                  ? 'How are you feeling?'
                  : 'How do you feel now?',
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
              widget.isPreReading
                  ? 'Take a moment to check in with yourself'
                  : 'Reflect on how this article affected you',
              style: TextStyle(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            if (widget.articleTitle != null && widget.isPreReading) ...[
              const SizedBox(height: KDesignConstants.spacing12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
                  borderRadius: KBorderRadius.md,
                  border: Border.all(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.articleTitle!,
                  style: TextStyle(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: KDesignConstants.spacing24),

            // Mood grid
            _buildMoodGrid(),

            if (_selectedMood != null) ...[
              const SizedBox(height: KDesignConstants.spacing24),
              _buildIntensitySlider(),
            ],

            const SizedBox(height: KDesignConstants.spacing24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    label: 'Skip',
                    isPrimary: false,
                    onPressed: () {
                      Navigator.of(context).pop(null);
                    },
                  ),
                ),
                const SizedBox(width: KDesignConstants.spacing12),
                Expanded(
                  child: _buildButton(
                    label: 'Continue',
                    isPrimary: true,
                    isEnabled: _selectedMood != null,
                    onPressed: _selectedMood != null
                        ? () {
                            HapticService.success();
                            Navigator.of(context).pop({
                              'mood': _selectedMood,
                              'intensity': _intensity,
                            });
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: MoodOptions.options.length,
      itemBuilder: (context, index) {
        final mood = MoodOptions.options[index];
        final isSelected = _selectedMood == mood.value;

        return GestureDetector(
          onTap: () {
            HapticService.selection();
            setState(() {
              _selectedMood = mood.value;
            });
          },
          child: Container(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mood.emoji,
                  style: TextStyle(
                    fontSize: isSelected ? 26 : 22,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    mood.label,
                    style: TextStyle(
                      color: isSelected
                          ? KAppColors.getOnBackground(context)
                          : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntensitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Intensity',
              style: TextStyle(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                borderRadius: KBorderRadius.md,
                border: Border.all(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '$_intensity/10',
                style: TextStyle(
                  color: KAppColors.getOnBackground(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: KDesignConstants.spacing12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: KAppColors.getPrimary(context),
            inactiveTrackColor: KAppColors.darkOnBackground.withValues(alpha: 0.1),
            thumbColor: KAppColors.getPrimary(context),
            overlayColor: KAppColors.getPrimary(context).withValues(alpha: 0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                _intensity = value.round();
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mild',
              style: TextStyle(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            Text(
              'Intense',
              style: TextStyle(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required bool isPrimary,
    bool isEnabled = true,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: KBorderRadius.lg,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isPrimary && isEnabled
                ? null
                : null,
            color: isPrimary && isEnabled
                ? KAppColors.getPrimary(context)
                : KAppColors.getOnBackground(context).withValues(alpha: 0.08),
            borderRadius: KBorderRadius.lg,
            border: Border.all(
              color: isPrimary && isEnabled
                  ? KAppColors.getPrimary(context).withValues(alpha: 0.7)
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isEnabled
                  ? (isPrimary ? KAppColors.getOnPrimary(context) : KAppColors.getOnBackground(context))
                  : KAppColors.getOnBackground(context).withValues(alpha: 0.5),
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
