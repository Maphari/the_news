import 'package:flutter/services.dart';

class HapticService {
  static final HapticService instance = HapticService._init();

  HapticService._init();

  // Light impact - for subtle interactions like taps
  static void light() {
    HapticFeedback.lightImpact();
  }

  // Medium impact - for confirmations and selections
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  // Heavy impact - for important actions
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  // Selection click - for scrolling through options
  static void selection() {
    HapticFeedback.selectionClick();
  }

  // Vibrate - for notifications and alerts
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  // Error pattern - for validation errors
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  // Success pattern - for successful actions
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  // Notification pattern - for alerts
  static Future<void> notification() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }
}
