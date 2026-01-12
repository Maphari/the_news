import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//? Helper class to manage status bar appearance
class StatusBarHelper {
  //? Set status bar to light mode (white icons for dark backgrounds)
  static void setLightStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, //* White icons (Android)
        statusBarBrightness: Brightness.dark,      //* Dark background (iOS)
      ),
    );
  }

  //? Set status bar to dark mode (black icons for light backgrounds)
  static void setDarkStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, //* Black icons (Android)
        statusBarBrightness: Brightness.light,    //* Light background (iOS)
      ),
    );
  }

  //? Automatically set status bar based on background color
  static void setAutoStatusBar(Color backgroundColor) {
    final isLightBackground = backgroundColor.computeLuminance() > 0.5;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isLightBackground 
            ? Brightness.dark   //* Dark icons for light background
            : Brightness.light, //* Light icons for dark background
        statusBarBrightness: isLightBackground
            ? Brightness.light  //* Light background (iOS)
            : Brightness.dark,  //* Dark background (iOS)
      ),
    );
  }

  //? Widget wrapper to set status bar for specific screens
  static Widget wrapWithStatusBar({
    required Widget child,
    required Color backgroundColor,
  }) {
    final isLightBackground = backgroundColor.computeLuminance() > 0.5;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isLightBackground
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: isLightBackground
            ? Brightness.light
            : Brightness.dark,
      ),
      child: child,
    );
  }
}