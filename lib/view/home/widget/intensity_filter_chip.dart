import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/content_intensity_service.dart';
import 'package:the_news/view/widgets/intensity_filter_dialog.dart';

class IntensityFilterChip extends StatefulWidget {
  const IntensityFilterChip({super.key});

  @override
  State<IntensityFilterChip> createState() => _IntensityFilterChipState();
}

class _IntensityFilterChipState extends State<IntensityFilterChip> {
  final ContentIntensityService _intensityService = ContentIntensityService.instance;

  @override
  Widget build(BuildContext context) {
    final currentLevel = _intensityService.currentFilter;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () async {
          final result = await IntensityFilterDialog.show(
            context,
            currentLevel: currentLevel,
          );

          if (result != null && mounted) {
            setState(() {
              _intensityService.setFilter(result);
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KAppColors.primary.withValues(alpha: 0.15),
                KAppColors.tertiary.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: KAppColors.primary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      KAppColors.primary.withValues(alpha: 0.3),
                      KAppColors.tertiary.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currentLevel.icon,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Intensity: ${currentLevel.label}',
                          style: KAppTextStyles.labelMedium.copyWith(
                            color: KAppColors.getOnBackground(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.tune,
                          color: KAppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                    if (currentLevel != IntensityLevel.all) ...[
                      const SizedBox(height: 2),
                      Text(
                        _intensityService.getWellnessRecommendation(currentLevel),
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
