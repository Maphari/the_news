import 'package:flutter/material.dart';
import 'package:the_news/l10n/app_localizations.dart';

/// Helper extension for easy localization access
extension LocalizationExtension on BuildContext {
  AppLocalizations? get loc => AppLocalizations.of(this);

  String translate(String key) {
    return loc?.translate(key) ?? key;
  }
}

/// Mixin for widgets that need localization
mixin LocalizationMixin {
  String t(BuildContext context, String key) {
    return context.translate(key);
  }
}
