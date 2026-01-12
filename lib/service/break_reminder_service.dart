import 'dart:async';
import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/utils/haptic_service.dart';

class BreakReminderService {
  static final BreakReminderService instance = BreakReminderService._init();

  Timer? _timer;
  DateTime? _sessionStartTime;
  int _continuousReadingSeconds = 0;

  // Configurable thresholds (in seconds)
  static const int firstReminderThreshold = 900; // 15 minutes
  static const int secondReminderThreshold = 1200; // 20 minutes
  static const int urgentReminderThreshold = 1800; // 30 minutes

  bool _hasShownFirstReminder = false;
  bool _hasShownSecondReminder = false;
  bool _hasShownUrgentReminder = false;

  Function(BreakReminderLevel)? _onReminderTriggered;

  BreakReminderService._init();

  // Start tracking continuous reading time
  void startTracking({Function(BreakReminderLevel)? onReminderTriggered}) {
    _sessionStartTime = DateTime.now();
    _continuousReadingSeconds = 0;
    _hasShownFirstReminder = false;
    _hasShownSecondReminder = false;
    _hasShownUrgentReminder = false;
    _onReminderTriggered = onReminderTriggered;

    // Update every 60 seconds
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _updateReadingTime();
    });
  }

  void _updateReadingTime() {
    if (_sessionStartTime == null) return;

    _continuousReadingSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;

    // Check thresholds and trigger reminders
    if (_continuousReadingSeconds >= urgentReminderThreshold && !_hasShownUrgentReminder) {
      _hasShownUrgentReminder = true;
      HapticService.notification();
      _onReminderTriggered?.call(BreakReminderLevel.urgent);
    } else if (_continuousReadingSeconds >= secondReminderThreshold && !_hasShownSecondReminder) {
      _hasShownSecondReminder = true;
      HapticService.notification();
      _onReminderTriggered?.call(BreakReminderLevel.strong);
    } else if (_continuousReadingSeconds >= firstReminderThreshold && !_hasShownFirstReminder) {
      _hasShownFirstReminder = true;
      HapticService.light();
      _onReminderTriggered?.call(BreakReminderLevel.gentle);
    }
  }

  // Reset the timer (e.g., when user takes a break)
  void resetTimer() {
    _sessionStartTime = DateTime.now();
    _continuousReadingSeconds = 0;
    _hasShownFirstReminder = false;
    _hasShownSecondReminder = false;
    _hasShownUrgentReminder = false;
  }

  // Stop tracking
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _sessionStartTime = null;
    _continuousReadingSeconds = 0;
    _hasShownFirstReminder = false;
    _hasShownSecondReminder = false;
    _hasShownUrgentReminder = false;
    _onReminderTriggered = null;
  }

  // Get current continuous reading time in seconds
  int get continuousReadingSeconds => _continuousReadingSeconds;

  // Get current continuous reading time in minutes
  int get continuousReadingMinutes => (_continuousReadingSeconds / 60).round();

  // Check if currently tracking
  bool get isTracking => _timer != null && _sessionStartTime != null;

  // Get time until next reminder (in seconds)
  int getTimeUntilNextReminder() {
    if (!isTracking) return 0;

    if (!_hasShownFirstReminder) {
      return firstReminderThreshold - _continuousReadingSeconds;
    } else if (!_hasShownSecondReminder) {
      return secondReminderThreshold - _continuousReadingSeconds;
    } else if (!_hasShownUrgentReminder) {
      return urgentReminderThreshold - _continuousReadingSeconds;
    }

    return 0;
  }

  // Format time for display
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes == 0) {
      return '${remainingSeconds}s';
    } else if (remainingSeconds == 0) {
      return '${minutes}m';
    } else {
      return '${minutes}m ${remainingSeconds}s';
    }
  }
}

enum BreakReminderLevel {
  gentle,   // 15 minutes
  strong,   // 20 minutes
  urgent,   // 30 minutes
}

// Break reminder dialog widget
class BreakReminderDialog extends StatelessWidget {
  const BreakReminderDialog({
    super.key,
    required this.level,
    required this.readingMinutes,
  });

  final BreakReminderLevel level;
  final int readingMinutes;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getGradientColor1().withValues(alpha: 0.95),
              _getGradientColor2().withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getBorderColor().withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getIconColor().withValues(alpha: 0.3),
                    _getIconColor().withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getIconColor().withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                _getIcon(),
                color: _getIconColor(),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _getTitle(),
              style: TextStyle(
                color: KAppColors.getOnBackground(context),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Reading time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'Reading for $readingMinutes minutes',
                style: TextStyle(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              _getMessage(),
              style: TextStyle(
                color: KAppColors.getOnBackground(context).withValues(alpha: 0.8),
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    context,
                    label: 'Take a Break',
                    isPrimary: true,
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton(
                    context,
                    label: 'Continue',
                    isPrimary: false,
                    onPressed: () {
                      Navigator.of(context).pop(false);
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

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isPrimary
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: isPrimary ? 0.3 : 0.2),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: KAppColors.getOnBackground(context),
              fontSize: 15,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (level) {
      case BreakReminderLevel.gentle:
        return 'Time for a mindful pause?';
      case BreakReminderLevel.strong:
        return 'Consider taking a break';
      case BreakReminderLevel.urgent:
        return 'Please take a break';
    }
  }

  String _getMessage() {
    switch (level) {
      case BreakReminderLevel.gentle:
        return 'You\'ve been reading for a while. Taking short breaks helps maintain focus and wellbeing.';
      case BreakReminderLevel.strong:
        return 'Extended reading can be draining. A quick break will help you stay balanced and focused.';
      case BreakReminderLevel.urgent:
        return 'You\'ve been reading for quite some time. Your mental wellbeing matters. Please take a break.';
    }
  }

  IconData _getIcon() {
    switch (level) {
      case BreakReminderLevel.gentle:
        return Icons.self_improvement_outlined;
      case BreakReminderLevel.strong:
        return Icons.schedule_outlined;
      case BreakReminderLevel.urgent:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getIconColor() {
    switch (level) {
      case BreakReminderLevel.gentle:
        return const Color(0xFF4CAF50); // Green
      case BreakReminderLevel.strong:
        return const Color(0xFFFFC107); // Amber
      case BreakReminderLevel.urgent:
        return const Color(0xFFFF6B6B); // Red
    }
  }

  Color _getGradientColor1() {
    switch (level) {
      case BreakReminderLevel.gentle:
        return const Color(0xFF1A1A1A);
      case BreakReminderLevel.strong:
        return const Color(0xFF2A2419);
      case BreakReminderLevel.urgent:
        return const Color(0xFF2A1A1A);
    }
  }

  Color _getGradientColor2() {
    switch (level) {
      case BreakReminderLevel.gentle:
        return const Color(0xFF1A2A1A);
      case BreakReminderLevel.strong:
        return const Color(0xFF2A2419);
      case BreakReminderLevel.urgent:
        return const Color(0xFF3A1A1A);
    }
  }

  Color _getBorderColor() {
    return _getIconColor();
  }

  // Show the dialog
  static Future<bool?> show(
    BuildContext context, {
    required BreakReminderLevel level,
    required int readingMinutes,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BreakReminderDialog(
        level: level,
        readingMinutes: readingMinutes,
      ),
    );
  }
}
