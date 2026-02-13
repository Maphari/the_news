import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Lightweight contrast check utility for debug builds.
///
/// Usage:
/// debugCheckContrast(
///   foreground: Theme.of(context).colorScheme.onPrimary,
///   background: Theme.of(context).colorScheme.primary,
///   contextLabel: 'Primary button label',
/// );
void debugCheckContrast({
  required Color foreground,
  required Color background,
  required String contextLabel,
  double minRatio = 4.5,
}) {
  if (!kDebugMode) return;
  final ratio = contrastRatio(foreground, background);
  if (ratio < minRatio) {
    debugPrint(
      '⚠️ Low contrast ($ratio) in $contextLabel. '
      'Foreground: ${_colorHex(foreground)}, Background: ${_colorHex(background)}',
    );
  }
}

/// Returns WCAG contrast ratio between two colors.
double contrastRatio(Color a, Color b) {
  final l1 = _relativeLuminance(a);
  final l2 = _relativeLuminance(b);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return ((lighter + 0.05) / (darker + 0.05));
}

// WCAG relative luminance (sRGB)
double _relativeLuminance(Color color) {
  double convert(int channel) {
    final c = channel / 255.0;
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = convert(color.red);
  final g = convert(color.green);
  final b = convert(color.blue);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

String _colorHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}
