import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/reading_tracker_service.dart';
import 'package:the_news/service/calm_mode_service.dart';

class ReadingLimitBanner extends StatefulWidget {
  const ReadingLimitBanner({super.key});

  @override
  State<ReadingLimitBanner> createState() => _ReadingLimitBannerState();
}

class _ReadingLimitBannerState extends State<ReadingLimitBanner> {
  final ReadingTrackerService _tracker = ReadingTrackerService.instance;
  final CalmModeService _calmMode = CalmModeService.instance;

  double _limitPercentage = 0.0;
  int _remainingMinutes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLimitStatus();
  }

  Future<void> _loadLimitStatus() async {
    await _calmMode.initialize();
    final limit = _calmMode.dailyReadingLimit;
    final percentage = await _tracker.getDailyLimitPercentage(limit);
    final remaining = await _tracker.getRemainingReadingTime(limit);

    if (mounted) {
      setState(() {
        _limitPercentage = percentage;
        _remainingMinutes = remaining ~/ 60;
        _isLoading = false;
      });
    }
  }

  Color _getBannerColor() {
    if (_limitPercentage < 50) {
      return const Color(0xFF4CAF50); // Green - healthy
    } else if (_limitPercentage < 80) {
      return const Color(0xFFFFA726); // Orange - warning
    } else {
      return const Color(0xFFEF5350); // Red - limit approaching/reached
    }
  }

  IconData _getBannerIcon() {
    if (_limitPercentage < 50) {
      return Icons.check_circle_outline;
    } else if (_limitPercentage < 80) {
      return Icons.access_time;
    } else {
      return Icons.warning_amber_outlined;
    }
  }

  String _getBannerMessage() {
    if (_limitPercentage >= 100) {
      return 'Daily reading limit reached';
    } else if (_limitPercentage >= 80) {
      return '$_remainingMinutes min remaining today';
    } else if (_limitPercentage >= 50) {
      return '$_remainingMinutes min left - you\'re doing great!';
    } else {
      return 'Plenty of time left today';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if loading or no limit reached warning needed
    if (_isLoading || _limitPercentage < 50) {
      return const SizedBox.shrink();
    }

    final color = _getBannerColor();

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getBannerIcon(),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getBannerMessage(),
                  style: KAppTextStyles.bodyMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _limitPercentage / 100,
                    backgroundColor: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_limitPercentage.toStringAsFixed(0)}% of daily limit',
                  style: KAppTextStyles.labelSmall.copyWith(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                    fontSize: 10,
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
