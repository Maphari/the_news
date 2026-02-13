import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing accessibility features
class AccessibilityService extends ChangeNotifier {
  static final instance = AccessibilityService._init();
  AccessibilityService._init();

  // Settings keys
  static const String _largeTextKey = 'accessibility_large_text';
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _reducedMotionKey = 'accessibility_reduced_motion';
  static const String _screenReaderKey = 'accessibility_screen_reader';
  static const String _hapticFeedbackKey = 'accessibility_haptic_feedback';

  bool _largeTextEnabled = false;
  bool _highContrastEnabled = false;
  bool _reducedMotionEnabled = false;
  bool _screenReaderOptimized = false;
  bool _hapticFeedbackEnabled = true;

  bool get largeTextEnabled => _largeTextEnabled;
  bool get highContrastEnabled => _highContrastEnabled;
  bool get reducedMotionEnabled => _reducedMotionEnabled;
  bool get screenReaderOptimized => _screenReaderOptimized;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;

  /// Initialize accessibility settings
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _largeTextEnabled = prefs.getBool(_largeTextKey) ?? false;
    _highContrastEnabled = prefs.getBool(_highContrastKey) ?? false;
    _reducedMotionEnabled = prefs.getBool(_reducedMotionKey) ?? false;
    _screenReaderOptimized = prefs.getBool(_screenReaderKey) ?? false;
    _hapticFeedbackEnabled = prefs.getBool(_hapticFeedbackKey) ?? true;

    notifyListeners();
    log('♿ Accessibility Service initialized');
  }

  /// Toggle large text mode
  Future<void> setLargeText(bool enabled) async {
    _largeTextEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_largeTextKey, enabled);
    notifyListeners();
  }

  /// Toggle high contrast mode
  Future<void> setHighContrast(bool enabled) async {
    _highContrastEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, enabled);
    notifyListeners();
  }

  /// Toggle reduced motion
  Future<void> setReducedMotion(bool enabled) async {
    _reducedMotionEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reducedMotionKey, enabled);
    notifyListeners();
  }

  /// Toggle screen reader optimization
  Future<void> setScreenReaderOptimized(bool enabled) async {
    _screenReaderOptimized = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_screenReaderKey, enabled);
    notifyListeners();
  }

  /// Toggle haptic feedback
  Future<void> setHapticFeedback(bool enabled) async {
    _hapticFeedbackEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticFeedbackKey, enabled);
    notifyListeners();
  }

  /// Get text scale factor based on settings
  double getTextScaleFactor() {
    return _largeTextEnabled ? 1.3 : 1.0;
  }

  /// Get animation duration (reduced if motion is reduced)
  Duration getAnimationDuration(Duration defaultDuration) {
    return _reducedMotionEnabled
        ? Duration(milliseconds: defaultDuration.inMilliseconds ~/ 2)
        : defaultDuration;
  }

  /// Provide haptic feedback if enabled
  Future<void> provideHapticFeedback(
      [HapticFeedbackType type = HapticFeedbackType.selection]) async {
    if (!_hapticFeedbackEnabled) return;

    switch (type) {
      case HapticFeedbackType.selection:
        await HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.success:
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.error:
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Get semantic label for screen readers
  String getSemanticLabel(String text, {String? context}) {
    if (!_screenReaderOptimized) return text;

    // Add context for better screen reader experience
    if (context != null) {
      return '$context: $text';
    }

    return text;
  }

  /// Check if system accessibility features are enabled
  static Future<Map<String, bool>> getSystemAccessibilityFeatures() async {
    // Note: These are Flutter framework level checks
    // You may need platform-specific code for more detailed checks
    return {
      'boldText': WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.boldText,
      'largeText': false, // Would need platform channels
      'screenReader': false, // Would need platform channels
      'reduceMotion': false, // Would need platform channels
    };
  }
}

/// Types of haptic feedback
enum HapticFeedbackType {
  selection,
  light,
  medium,
  heavy,
  success,
  error,
}

/// Extension to wrap widgets with accessibility features
extension AccessibilityExtension on Widget {
  /// Wrap widget with semantic label
  Widget withSemantics({
    required String label,
    String? hint,
    bool? button,
    bool? header,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      header: header,
      child: this,
    );
  }

  /// Make widget focusable for keyboard navigation
  Widget focusable({
    FocusNode? focusNode,
    bool autofocus = false,
    ValueChanged<bool>? onFocusChange,
  }) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onFocusChange: onFocusChange,
      child: this,
    );
  }

  /// Add haptic feedback on tap
  Widget withHapticFeedback({
    HapticFeedbackType type = HapticFeedbackType.selection,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        AccessibilityService.instance.provideHapticFeedback(type);
        onTap?.call();
      },
      child: this,
    );
  }
}

/// Accessibility-aware text widget
class AccessibleText extends StatelessWidget {
  const AccessibleText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticLabel,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AccessibilityService.instance,
      builder: (context, _) {
        final textScaleFactor =
            AccessibilityService.instance.getTextScaleFactor();

        return Semantics(
          label: semanticLabel ?? data,
          child: Text(
            data,
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
        );
      },
    );
  }
}

/// Accessibility settings page
class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KAppBar(
        title: const Text('Accessibility'),
      ),
      body: ListenableBuilder(
        listenable: AccessibilityService.instance,
        builder: (context, _) {
          final service = AccessibilityService.instance;

          return ListView(
            children: [
              const Padding(
                padding: KDesignConstants.paddingMd,
                child: Text(
                  'Visual Accessibility',
                  style: KAppTextStyles.titleMedium,
                ),
              ),
              SwitchListTile(
                title: const Text('Large Text'),
                subtitle: const Text('Increase text size throughout the app'),
                value: service.largeTextEnabled,
                onChanged: (value) {
                  service.setLargeText(value);
                  service.provideHapticFeedback();
                },
              ),
              SwitchListTile(
                title: const Text('High Contrast'),
                subtitle: const Text('Improve visibility with higher contrast'),
                value: service.highContrastEnabled,
                onChanged: (value) {
                  service.setHighContrast(value);
                  service.provideHapticFeedback();
                },
              ),
              const Divider(),
              const Padding(
                padding: KDesignConstants.paddingMd,
                child: Text(
                  'Motion & Interaction',
                  style: KAppTextStyles.titleMedium,
                ),
              ),
              SwitchListTile(
                title: const Text('Reduce Motion'),
                subtitle: const Text('Minimize animations and transitions'),
                value: service.reducedMotionEnabled,
                onChanged: (value) {
                  service.setReducedMotion(value);
                  service.provideHapticFeedback();
                },
              ),
              SwitchListTile(
                title: const Text('Haptic Feedback'),
                subtitle: const Text('Vibrate on interactions'),
                value: service.hapticFeedbackEnabled,
                onChanged: (value) {
                  service.setHapticFeedback(value);
                },
              ),
              const Divider(),
              const Padding(
                padding: KDesignConstants.paddingMd,
                child: Text(
                  'Screen Reader',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Screen Reader Optimization'),
                subtitle: const Text(
                    'Optimize content for screen readers like VoiceOver and TalkBack'),
                value: service.screenReaderOptimized,
                onChanged: (value) {
                  service.setScreenReaderOptimized(value);
                  service.provideHapticFeedback();
                },
              ),
              Padding(
                padding: KDesignConstants.paddingMd,
                child: Text(
                  'When enabled, the app will provide more detailed descriptions and better navigation for screen reader users.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
